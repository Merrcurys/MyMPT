import 'dart:async';
import 'package:my_mpt/data/repositories/replacement_repository.dart';
import 'package:my_mpt/core/services/notification_service.dart';
import 'package:my_mpt/domain/entities/replacement.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackgroundReplacementChecker {
  static const Duration _checkInterval = Duration(minutes: 30); // Check every 30 minutes to reduce resource usage
  Timer? _timer;
  Timer? _dailyReminderTimer;
  
  // Key to store the date of the last daily reminder
  static const String _lastDailyReminderDateKey = 'last_daily_reminder_date';

  void startChecking() {
    // Start periodic checking for new replacements
    _timer = Timer.periodic(_checkInterval, (_) {
      _checkForNewReplacements();
    });
    
    // Set up daily reminder at 21:00
    _setupDailyReminder();
  }

  void stopChecking() {
    _timer?.cancel();
    _dailyReminderTimer?.cancel();
    _timer = null;
    _dailyReminderTimer = null;
  }

  Future<void> _checkForNewReplacements() async {
    try {
      final replacementRepository = ReplacementRepository();
      await replacementRepository.getScheduleChanges();
    } catch (e) {
      // Handle error silently or log it
      print('Error checking for new replacements: $e');
    }
  }
  
  void _setupDailyReminder() {
    // Calculate time until next 21:00
    DateTime now = DateTime.now();
    DateTime nextNinePM = DateTime(now.year, now.month, now.day, 21, 0, 0);
    
    // If it's already past 21:00 today, schedule for tomorrow
    if (now.hour >= 21) {
      nextNinePM = nextNinePM.add(Duration(days: 1));
    }
    
    Duration timeUntilNext = nextNinePM.difference(now);
    
    // Schedule the first reminder
    _dailyReminderTimer = Timer(timeUntilNext, () {
      _sendDailyReminder();
      
      // Set up recurring daily reminder
      _dailyReminderTimer = Timer.periodic(Duration(days: 1), (_) {
        _sendDailyReminder();
      });
    });
  }
  
  Future<void> _sendDailyReminder() async {
    try {
      // Check if we already sent a reminder today
      final prefs = await SharedPreferences.getInstance();
      final lastReminderDateString = prefs.getString(_lastDailyReminderDateKey);
      
      DateTime today = DateTime.now();
      String todayString = "${today.year}-${today.month}-${today.day}";
      
      if (lastReminderDateString == todayString) {
        // Already sent reminder today
        return;
      }
      
      // Update the last reminder date
      await prefs.setString(_lastDailyReminderDateKey, todayString);
      
      // Get tomorrow's date for filtering replacements
      DateTime tomorrow = today.add(Duration(days: 1));
      String tomorrowDateString = "${tomorrow.day.toString().padLeft(2, '0')}.${tomorrow.month.toString().padLeft(2, '0')}.${tomorrow.year}";
      
      // Get replacements and filter for tomorrow
      final replacementRepository = ReplacementRepository();
      final allReplacements = await replacementRepository.getScheduleChanges();
      
      // Filter for tomorrow's replacements
      final tomorrowReplacements = allReplacements.where((replacement) {
        return replacement.changeDate == tomorrowDateString;
      }).toList();
      
      // Show reminder notification
      await NotificationService().showTomorrowReplacementsReminder(tomorrowReplacements.length);
      
    } catch (e) {
      print('Error sending daily reminder: $e');
    }
  }
}