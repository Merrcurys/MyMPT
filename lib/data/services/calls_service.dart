import 'package:my_mpt/data/models/call.dart';

/// Service for providing calls data
class CallsService {
  static final List<Call> _callsData = [
    Call(
      period: '1',
      startTime: '08:30',
      endTime: '10:00',
      description: 'Перемена 10 минут',
    ),
    Call(
      period: '2',
      startTime: '10:10',
      endTime: '11:40',
      description: 'Перемена 20 минут',
    ),
    Call(
      period: '3',
      startTime: '12:00',
      endTime: '13:30',
      description: 'Перемена 20 минут',
    ),
    Call(
      period: '4',
      startTime: '13:50',
      endTime: '15:20',
      description: 'Перемена 10 минут',
    ),
    Call(
      period: '5',
      startTime: '15:30',
      endTime: '17:00',
      description: 'Перемена 5 минут',
    ),
    Call(
      period: '6',
      startTime: '17:05',
      endTime: '18:35',
      description: 'Перемена 5 минут',
    ),
    Call(
      period: '7',
      startTime: '18:40',
      endTime: '20:10',
      description: 'Конец учебного дня',
    ),
  ];

  /// Get all calls data
  static List<Call> getCalls() {
    return List<Call>.from(_callsData);
  }

  /// Get break duration between two lesson times
  static String getBreakDuration(String lessonEndTime, String nextLessonStartTime) {
    try {
      // Parse times
      final endParts = lessonEndTime.split(':');
      final startParts = nextLessonStartTime.split(':');
      
      final endHour = int.parse(endParts[0]);
      final endMinute = int.parse(endParts[1]);
      final startHour = int.parse(startParts[0]);
      final startMinute = int.parse(startParts[1]);
      
      // Calculate difference in minutes
      final endTotalMinutes = endHour * 60 + endMinute;
      final startTotalMinutes = startHour * 60 + startMinute;
      final breakMinutes = startTotalMinutes - endTotalMinutes;
      
      // Format duration string
      if (breakMinutes < 0) return '0 минут';
      if (breakMinutes < 60) return '$breakMinutes минут';
      
      final hours = breakMinutes ~/ 60;
      final minutes = breakMinutes % 60;
      
      if (minutes == 0) {
        return '$hours ${hours == 1 ? 'час' : 'часа'}';
      } else {
        return '$hours ${hours == 1 ? 'час' : 'часа'} $minutes минут';
      }
    } catch (e) {
      // Return default if parsing fails
      return '20 минут';
    }
  }
}