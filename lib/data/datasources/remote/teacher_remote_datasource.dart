import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:my_mpt/data/models/teacher.dart';
import 'package:my_mpt/data/parsers/teacher_parser.dart';

List<Map<String, dynamic>> _parseTeacherIsolate(Map<String, dynamic> message) {
  final html = message['html'] as String? ?? '';
  final parsed = TeacherParser().parse(html);
  return parsed.map((t) => t.toJson()).toList();
}

class TeacherRemoteDatasource {
  TeacherRemoteDatasource({
    http.Client? client,
    this.baseUrl = 'https://mpt.ru/raspisanie/',
    this.cacheTtl = const Duration(hours: 48),
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;
  final Duration cacheTtl;

  String? _cachedHtml;
  DateTime? _lastFetch;

  Future<List<Teacher>> fetchTeachers({bool forceRefresh = false}) async {
    try {
      final html = await _fetchSchedulePage(forceRefresh: forceRefresh);
      final decoded = await compute(_parseTeacherIsolate, {'html': html});
      
      return decoded.map((json) => Teacher(teacherName: json['teacherName'])).toList();
    } catch (error) {
      throw Exception('Error fetching teachers: $error');
    }
  }

  Future<String> _fetchSchedulePage({bool forceRefresh = false}) async {
    final isCacheValid = _cachedHtml != null &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < cacheTtl;

    if (!forceRefresh && isCacheValid) {
      return _cachedHtml!;
    }

    final response = await _client.get(Uri.parse(baseUrl)).timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw const HttpException('Timeout'),
    );

    if (response.statusCode != HttpStatus.ok) {
      throw HttpException('Error: ${response.statusCode}');
    }

    final freshHtml = utf8.decode(response.bodyBytes);
    _cachedHtml = freshHtml;
    _lastFetch = DateTime.now();
    return freshHtml;
  }
}