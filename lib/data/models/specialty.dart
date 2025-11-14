class Specialty {
  final String code;
  final String name;

  Specialty({required this.code, required this.name});

  factory Specialty.fromJson(Map<String, dynamic> json) {
    return Specialty(
      code: json['code'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Specialty &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() {
    return 'Specialty{code: $code, name: $name}';
  }
}