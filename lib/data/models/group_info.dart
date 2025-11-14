/// Data class to hold group information extracted from the MPT website
class GroupInfo {
  final String code;
  final String specialtyCode;
  final String specialtyName;
  
  GroupInfo({
    required this.code,
    required this.specialtyCode,
    required this.specialtyName,
  });
  
  @override
  String toString() {
    return 'GroupInfo(code: $code, specialtyCode: $specialtyCode, specialtyName: $specialtyName)';
  }
  
  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'specialtyCode': specialtyCode,
      'specialtyName': specialtyName,
    };
  }
}