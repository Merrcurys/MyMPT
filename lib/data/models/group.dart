class Group {
  final String code;
  final String specialtyCode;

  Group({required this.code, required this.specialtyCode});

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      code: json['code'] as String,
      specialtyCode: json['specialtyCode'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'specialtyCode': specialtyCode,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Group &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() {
    return 'Group{code: $code, specialtyCode: $specialtyCode}';
  }
}