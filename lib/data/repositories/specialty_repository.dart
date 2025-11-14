import 'package:flutter/foundation.dart';
import '../models/specialty.dart';
import '../models/group.dart';
import '../services/mock_api_service.dart';

class SpecialtyRepository {
  final MockApiService _apiService = MockApiService();

  /// Get all specialties
  Future<List<Specialty>> getSpecialties() async {
    try {
      return await _apiService.getSpecialties();
    } catch (e) {
      // In a real app, we would handle errors appropriately
      debugPrint('Error fetching specialties: $e');
      return [];
    }
  }

  /// Get groups by specialty code
  Future<List<Group>> getGroupsBySpecialty(String specialtyCode) async {
    try {
      return await _apiService.getGroupsBySpecialty(specialtyCode);
    } catch (e) {
      // In a real app, we would handle errors appropriately
      debugPrint('Error fetching groups for specialty $specialtyCode: $e');
      return [];
    }
  }
}