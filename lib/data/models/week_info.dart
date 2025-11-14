/// Data class to hold week information extracted from the MPT website
class WeekInfo {
  final String weekType;
  final String date;
  final String day;
  
  WeekInfo({
    required this.weekType,
    required this.date,
    required this.day,
  });
  
  @override
  String toString() {
    return 'WeekInfo(weekType: $weekType, date: $date, day: $day)';
  }
  
  Map<String, dynamic> toJson() {
    return {
      'weekType': weekType,
      'date': date,
      'day': day,
    };
  }
}