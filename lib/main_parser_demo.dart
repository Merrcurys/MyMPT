import 'package:flutter/material.dart';
import 'package:my_mpt/data/services/mpt_parser_service.dart';
import 'package:my_mpt/data/repositories/mpt_repository.dart';
import 'package:my_mpt/domain/entities/specialty.dart';
import 'package:my_mpt/data/models/tab_info.dart';
import 'package:my_mpt/data/models/week_info.dart';
import 'package:my_mpt/data/models/group_info.dart';

void main() {
  runApp(const ParserDemoApp());
}

class ParserDemoApp extends StatelessWidget {
  const ParserDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Демонстрация парсера MPT',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const ParserDemoScreen(),
    );
  }
}

class ParserDemoScreen extends StatefulWidget {
  const ParserDemoScreen({super.key});

  @override
  State<ParserDemoScreen> createState() => _ParserDemoScreenState();
}

class _ParserDemoScreenState extends State<ParserDemoScreen> {
  final MptParserService _parser = MptParserService();
  final MptRepository _repository = MptRepository();
  List<dynamic> _results = [];
  WeekInfo? _weekInfo;
  List<GroupInfo> _groups = [];
  String? _selectedSpecialty;
  bool _isLoading = false;
  String _status = 'Готово';

  Future<void> _parseWebsite() async {
    setState(() {
      _isLoading = true;
      _status = 'Парсинг сайта...';
      _results = [];
    });

    try {
      final tabs = await _parser.parseTabList();
      setState(() {
        _results = tabs;
        _status = 'Найдено ${tabs.length} вкладок';
      });
    } catch (e) {
      setState(() {
        _status = 'Ошибка: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getSpecialties() async {
    setState(() {
      _isLoading = true;
      _status = 'Получение специальностей...';
      _results = [];
    });

    try {
      final specialties = await _repository.getSpecialties();
      setState(() {
        _results = specialties;
        _status = 'Получено ${specialties.length} специальностей';
      });
    } catch (e) {
      setState(() {
        _status = 'Ошибка: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getWeekInfo() async {
    setState(() {
      _isLoading = true;
      _status = 'Получение информации о неделе...';
      _results = [];
    });

    try {
      final weekInfo = await _parser.parseWeekInfo();
      setState(() {
        _weekInfo = weekInfo;
        _status = 'Информация о неделе получена';
      });
    } catch (e) {
      setState(() {
        _status = 'Ошибка: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getGroupsBySpecialty(String specialtyCode) async {
    setState(() {
      _isLoading = true;
      _status = 'Получение групп для специальности...';
      _results = [];
      _selectedSpecialty = specialtyCode;
    });

    try {
      // Используем оптимизированный метод парсера, который фильтрует группы на стороне сервера
      final groups = await _parser.parseGroups(specialtyCode);

      setState(() {
        _groups = groups;
        _status =
            'Получено ${groups.length} групп для специальности $specialtyCode';
      });
    } catch (e) {
      setState(() {
        _status = 'Ошибка: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Демонстрация парсера MPT'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _status,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _parseWebsite,
                  child: const Text('Парсить сайт'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _isLoading ? null : _getSpecialties,
                  child: const Text('Специальности'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _isLoading ? null : _getWeekInfo,
                  child: const Text('Неделя'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Expanded(
                child: Column(
                  children: [
                    // Отображаем информацию о неделе, если она есть
                    if (_weekInfo != null) ...[
                      Card(
                        child: ListTile(
                          title: const Text(
                            'Информация о неделе',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Тип недели: ${_weekInfo!.weekType}'),
                              Text('Дата: ${_weekInfo!.date}'),
                              Text('День: ${_weekInfo!.day}'),
                            ],
                          ),
                        ),
                      ),
                      const Divider(),
                    ],
                    // Отображаем список результатов
                    Expanded(
                      child: Column(
                        children: [
                          // Если есть выбранные группы, отображаем их
                          if (_selectedSpecialty != null &&
                              _groups.isNotEmpty) ...[
                            const Text(
                              'Группы:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            Expanded(
                              child: ListView.builder(
                                itemCount: _groups.length,
                                itemBuilder: (context, index) {
                                  final group = _groups[index];
                                  return Card(
                                    child: ListTile(
                                      title: Text(group.code),
                                      subtitle: Text('${group.specialtyCode}'),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ] else
                            // Иначе отображаем обычные результаты
                            Expanded(
                              child: ListView.builder(
                                itemCount: _results.length,
                                itemBuilder: (context, index) {
                                  final item = _results[index];
                                  if (item is TabInfo) {
                                    return Card(
                                      child: ListTile(
                                        title: Text(
                                          item.name.isNotEmpty
                                              ? item.name
                                              : 'Без названия',
                                        ),
                                        // Убираем subtitle с техническими данными
                                      ),
                                    );
                                  } else if (item is Specialty) {
                                    return Card(
                                      child: ListTile(
                                        title: Text(item.name),
                                        // Убираем subtitle с кодом специальности
                                      ),
                                    );
                                  }
                                  return const SizedBox();
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
