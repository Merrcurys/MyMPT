/**
 * Сервис проверки замен МПТ для запуска на VPS (Docker).
 * Раз в час парсит https://mpt.ru/izmeneniya-v-raspisanii/,
 * сравнивает с последним состоянием (файл на диске), отправляет FCM.
 * Читает токены из Firestore (Firebase Admin SDK).
 */

const admin = require("firebase-admin");
const axios = require("axios");
const cheerio = require("cheerio");
const cron = require("node-cron");
const fs = require("fs");
const path = require("path");

const REPLACEMENTS_URL = "https://mpt.ru/izmeneniya-v-raspisanii/";
const FCM_TOKENS_COLLECTION = "fcm_tokens";

const STATE_FILE =
  process.env.STATE_FILE ||
  path.join(process.env.DATA_DIR || "./data", "last_replacements.json");
const CREDENTIALS_PATH =
  process.env.GOOGLE_APPLICATION_CREDENTIALS ||
  path.join(__dirname, "firebase-service-account.json");

function ensureDataDir() {
  const dir = path.dirname(STATE_FILE);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
}

function loadLastState() {
  ensureDataDir();
  try {
    const raw = fs.readFileSync(STATE_FILE, "utf8");
    return JSON.parse(raw);
  } catch (e) {
    if (e.code === "ENOENT") return {};
    throw e;
  }
}

function saveLastState(state) {
  ensureDataDir();
  fs.writeFileSync(STATE_FILE, JSON.stringify(state, null, 2), "utf8");
}

function normalizeGroupCode(input) {
  if (!input || typeof input !== "string") return "";
  let s = input
    .replace(/—/g, "-")
    .replace(/–/g, "-")
    .replace(/−/g, "-")
    .trim()
    .toUpperCase();
  s = s.replace(/\s+/g, " ").replace(/\s*-\s*/g, "-");
  return s;
}

function splitGroupCodes(raw) {
  if (!raw || typeof raw !== "string") return [];
  const parts = raw.replace(/\n/g, " ").split(/[,/;]/);
  const seen = new Set();
  const out = [];
  for (const p of parts) {
    const v = normalizeGroupCode(p);
    if (!v || seen.has(v)) continue;
    seen.add(v);
    out.push(v);
  }
  return out;
}

function captionMatchesGroup(captionText, groupCode) {
  const normalized = normalizeGroupCode(captionText);
  const normalizedGroup = normalizeGroupCode(groupCode);
  if (!normalizedGroup) return false;
  if (normalized.includes(normalizedGroup)) return true;
  const candidates = splitGroupCodes(groupCode);
  return candidates.some((c) => c && normalized.includes(c));
}

function getDateStrings() {
  const now = new Date();
  const today = [
    String(now.getDate()).padStart(2, "0"),
    String(now.getMonth() + 1).padStart(2, "0"),
    now.getFullYear(),
  ].join(".");
  const tomorrow = new Date(now.getTime() + 24 * 60 * 60 * 1000);
  const tomorrowStr = [
    String(tomorrow.getDate()).padStart(2, "0"),
    String(tomorrow.getMonth() + 1).padStart(2, "0"),
    tomorrow.getFullYear(),
  ].join(".");
  return { today: today, tomorrow: tomorrowStr };
}

function parseReplacementsByGroup(html) {
  const $ = cheerio.load(html);
  const result = new Map();
  const { today, tomorrow } = getDateStrings();
  const dateRegExp = /(\d{2}\.\d{2}\.\d{4})/;

  $("h4").each((_, el) => {
    const text = $(el).text().trim();
    if (!text.startsWith("Замены на")) return;
    const match = text.match(dateRegExp);
    if (!match) return;
    const currentDate = match[1];
    if (currentDate !== today && currentDate !== tomorrow) return;

    let next = $(el).next();
    while (next.length) {
      const tag = next.prop("tagName") && next.prop("tagName").toLowerCase();
      const nextText = next.text().trim();
      if (tag === "h4" && nextText.startsWith("Замены на")) break;

      let table = null;
      if (tag === "div" && next.hasClass("table-responsive")) {
        table = next.find("table.table").first();
      } else if (tag === "table" && next.hasClass("table")) {
        table = next;
      }

      if (table && table.length) {
        const caption = table.find("caption");
        if (caption.length) {
          const captionText = caption.text().trim();
          const rows = [];
          table.find("tbody tr, tr").each((_, row) => {
            const cells = $(row).find("td");
            if (cells.length !== 4) return;
            rows.push({
              lessonNumber: $(cells[0]).text().trim(),
              replaceFrom: $(cells[1]).text().trim(),
              replaceTo: $(cells[2]).text().trim(),
              updatedAt: $(cells[3]).text().trim(),
              changeDate: currentDate,
            });
          });
          if (!result.has(captionText)) result.set(captionText, []);
          result.get(captionText).push(...rows);
        }
      }
      next = next.next();
    }
  });

  return result;
}

function getReplacementsForGroup(parsedByCaption, groupCode) {
  const list = [];
  for (const [caption, replacements] of parsedByCaption) {
    if (captionMatchesGroup(caption, groupCode)) list.push(...replacements);
  }
  return list;
}

function replacementHash(r) {
  return `${r.lessonNumber}_${r.replaceFrom}_${r.replaceTo}_${r.changeDate}_${r.updatedAt}`;
}

function hasNewReplacements(current, lastHashes) {
  if (!lastHashes || lastHashes.length === 0) return current.length > 0;
  const currentSet = new Set(current.map(replacementHash));
  for (const h of lastHashes) {
    if (!currentSet.has(h)) return true;
  }
  return current.length > lastHashes.length;
}

function groupDocId(groupCode) {
  return String(groupCode).replace(/\//g, "_").trim() || "_empty";
}

async function runCheck() {
  const db = admin.firestore();
  const messaging = admin.messaging();
  const state = loadLastState();

  let html;
  try {
    const res = await axios.get(REPLACEMENTS_URL, {
      timeout: 15000,
      responseType: "text",
      headers: { "User-Agent": "MymptReplacementService/1.0" },
    });
    html = res.data;
  } catch (e) {
    console.error("[runCheck] Fetch failed:", e.message);
    return;
  }

  const parsedByCaption = parseReplacementsByGroup(html);
  if (parsedByCaption.size === 0) {
    console.log("[runCheck] No replacement blocks for today/tomorrow.");
    return;
  }

  const tokensSnap = await db.collection(FCM_TOKENS_COLLECTION).get();
  const tokensByGroup = new Map();
  for (const doc of tokensSnap.docs) {
    const data = doc.data();
    const token = data.token;
    const groupCode = (data.groupCode || "").trim();
    if (!token || !groupCode) continue;
    if (!tokensByGroup.has(groupCode)) tokensByGroup.set(groupCode, []);
    tokensByGroup.get(groupCode).push({ token, docRef: doc.ref });
  }

  for (const [groupCode, tokens] of tokensByGroup) {
    const replacements = getReplacementsForGroup(parsedByCaption, groupCode);
    const key = groupDocId(groupCode);
    const lastHashes = state[key] && state[key].hashes ? state[key].hashes : [];

    if (!hasNewReplacements(replacements, lastHashes)) continue;

    const title =
      replacements.length === 1
        ? "Новая замена в расписании"
        : "Новые замены в расписании";
    const first = replacements[0];
    const body =
      replacements.length === 1
        ? `${first.changeDate}: Пара ${first.lessonNumber}: ${first.replaceFrom} → ${first.replaceTo}`
        : `Обнаружено новых замен: ${replacements.length}`;

    for (const { token, docRef } of tokens) {
      try {
        await messaging.send({
          token,
          notification: { title, body },
          android: { priority: "high" },
        });
      } catch (sendErr) {
        if (
          sendErr.code === "messaging/invalid-registration-token" ||
          sendErr.code === "messaging/registration-token-not-registered"
        ) {
          try {
            await docRef.delete();
          } catch (_) {}
        }
        console.warn("[runCheck] FCM send failed:", docRef.id, sendErr.message);
      }
    }

    state[key] = {
      groupCode,
      hashes: replacements.map(replacementHash),
      updatedAt: new Date().toISOString(),
    };
  }

  saveLastState(state);
  console.log("[runCheck] Done.");
}

function main() {
  if (!fs.existsSync(CREDENTIALS_PATH)) {
    console.error(
      "Firebase service account not found. Set GOOGLE_APPLICATION_CREDENTIALS or place firebase-service-account.json in the app directory."
    );
    process.exit(1);
  }

  const key = JSON.parse(fs.readFileSync(CREDENTIALS_PATH, "utf8"));
  admin.initializeApp({ credential: admin.credential.cert(key) });

  const runEveryHour = process.env.CRON_SCHEDULE || "0 * * * *";
  console.log("Scheduling check with cron:", runEveryHour);

  if (process.env.RUN_ONCE === "1") {
    runCheck()
      .then(() => process.exit(0))
      .catch((e) => {
        console.error(e);
        process.exit(1);
      });
    return;
  }

  runCheck().catch((e) => console.error("[runCheck]", e));
  cron.schedule(runEveryHour, () => {
    runCheck().catch((e) => console.error("[runCheck]", e));
  });
}

main();
