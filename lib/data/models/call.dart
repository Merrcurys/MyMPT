class Call {
  final String period;
  final String startTime;
  final String endTime;
  final String description;

  Call({
    required this.period,
    required this.startTime,
    required this.endTime,
    required this.description,
  });

  factory Call.fromJson(Map<String, dynamic> json) {
    return Call(
      period: json['period'] as String,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      description: json['description'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'period': period,
      'startTime': startTime,
      'endTime': endTime,
      'description': description,
    };
  }
}