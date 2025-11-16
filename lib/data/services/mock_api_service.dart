import 'dart:async';
import '../models/specialty.dart';
import '../models/group.dart';

class MockApiService {
  static const int _networkDelay = 500;

  final List<Specialty> _specialties = [
    Specialty(code: '09.02.07', name: 'Информационные системы и программирование'),
    Specialty(code: '10.02.01', name: 'Правоохранительная деятельность'),
    Specialty(code: '13.02.11', name: 'Техническая эксплуатация и обслуживание электрического и электромеханического оборудования'),
    Specialty(code: '15.02.10', name: 'Монтаж и техническая эксплуатация промышленного оборудования'),
    Specialty(code: '20.02.01', name: 'Комплексное применение в области профессиональной деятельности'),
  ];

  final List<Group> _groups = [
    Group(code: 'П50-1-22', specialtyCode: '09.02.07'),
    Group(code: 'П50-2-22', specialtyCode: '09.02.07'),
    Group(code: 'П50-3-22', specialtyCode: '09.02.07'),
    Group(code: 'П51-1-22', specialtyCode: '10.02.01'),
    Group(code: 'П51-2-22', specialtyCode: '10.02.01'),
    Group(code: 'П52-1-22', specialtyCode: '13.02.11'),
    Group(code: 'П52-2-22', specialtyCode: '13.02.11'),
    Group(code: 'П53-1-22', specialtyCode: '15.02.10'),
    Group(code: 'П54-1-22', specialtyCode: '20.02.01'),
  ];

  Future<List<Specialty>> getSpecialties() async {
    await Future.delayed(Duration(milliseconds: _networkDelay));
    return _specialties;
  }

  Future<List<Group>> getGroupsBySpecialty(String specialtyCode) async {
    await Future.delayed(Duration(milliseconds: _networkDelay));
    return _groups.where((group) => group.specialtyCode == specialtyCode).toList();
  }

  Future<List<Group>> getAllGroups() async {
    await Future.delayed(Duration(milliseconds: _networkDelay));
    return _groups;
  }
}