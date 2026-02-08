import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';

/// Виджет заголовка экрана "Сегодня"
class TodayHeader extends StatelessWidget {
  final String dateLabel;
  final int lessonsCount; // сейчас не используется в UI, оставляем как было
  final List<Color> gradient;
  final String pageTitle;
  final String weekType;

  /// 0..1: 0 — полностью раскрыт, 1 — полностью компактный
  final double collapseT;

  const TodayHeader({
    super.key,
    required this.dateLabel,
    required this.lessonsCount,
    required this.gradient,
    required this.pageTitle,
    required this.weekType,
    this.collapseT = 0.0,
  });

  Widget _weekChip(double t) {
    final padH = lerpDouble(14, 12, t)!;
    final padV = lerpDouble(6, 5, t)!;
    final fontSize = lerpDouble(13, 12, t)!;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Text(
        weekType,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
          color: Colors.white,
          height: 1.05,
        ),
      ),
    );
  }

  Widget _expandedLayout(double t) {
    final titleSize = lerpDouble(28, 22, t)!;
    final dateSize = lerpDouble(16, 14, t)!;
    final gap = lerpDouble(18, 10, t)!;

    return Column(
      key: const ValueKey('expanded'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _weekChip(t),
        SizedBox(height: gap),
        Text(
          pageTitle,
          style: TextStyle(
            fontSize: titleSize,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          dateLabel,
          style: TextStyle(
            fontSize: dateSize,
            color: Colors.white70,
            height: 1.05,
          ),
        ),
      ],
    );
  }

  Widget _compactLayout(double t) {
    // Компакт: чип слева, справа — (pageTitle + dateLabel) как 2 строки,
    // а если не влезло по ширине — уезжает вправо через горизонтальный скролл.
    final titleSize = lerpDouble(20, 18, t)!;
    final dateSize = lerpDouble(14, 13, t)!;

    return Row(
      key: const ValueKey('compact'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _weekChip(t),
        const SizedBox(width: 12),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pageTitle,
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateLabel,
                  style: TextStyle(
                    fontSize: dateSize,
                    color: Colors.white70,
                    height: 1.05,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = collapseT.clamp(0.0, 1.0);

    // Важно: чтобы не было "размытия" — не кроссфейдим два одинаковых текста одновременно.
    // Переключаемся в одной точке, а красивую анимацию даёт AnimatedSwitcher. [file:243]
    final compact = t >= 0.58;

    final marginTop = lerpDouble(16, 8, t)!;
    final radius = lerpDouble(32, 22, t)!;

    final padH = lerpDouble(24, 16, t)!;
    final padTop = lerpDouble(28, 12, t)!;
    final padBottom = lerpDouble(24, 12, t)!;

    return Container(
      margin: EdgeInsets.fromLTRB(16, marginTop, 16, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: lerpDouble(0.45, 0.25, t)!),
            blurRadius: lerpDouble(30, 18, t)!,
            offset: Offset(0, lerpDouble(18, 10, t)!),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(padH, padTop, padH, padBottom),
        child: ClipRect(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, anim) {
              final slide = Tween<Offset>(
                begin: const Offset(0, 0.08),
                end: Offset.zero,
              ).animate(anim);
              return FadeTransition(
                opacity: anim,
                child: SlideTransition(position: slide, child: child),
              );
            },
            child: compact ? _compactLayout(t) : _expandedLayout(t),
          ),
        ),
      ),
    );
  }
}
