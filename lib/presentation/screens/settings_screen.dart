import 'package:flutter/material.dart';
import 'package:my_mpt/data/models/group.dart';
import 'package:my_mpt/data/models/specialty.dart' as data_model;
import 'package:my_mpt/domain/repositories/specialty_repository_interface.dart';
import 'package:my_mpt/domain/repositories/group_repository_interface.dart';
import 'package:my_mpt/data/repositories/specialty_repository.dart';
import 'package:my_mpt/data/repositories/group_repository.dart';
import 'package:my_mpt/presentation/widgets/settings/error_notification.dart';
import 'package:my_mpt/presentation/widgets/settings/info_notification.dart';
import 'package:my_mpt/presentation/widgets/settings/section.dart';
import 'package:my_mpt/presentation/widgets/settings/settings_card.dart';
import 'package:my_mpt/presentation/widgets/settings/settings_header.dart';
import 'package:my_mpt/presentation/widgets/settings/success_notification.dart';
import 'package:my_mpt/data/repositories/schedule_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _backgroundColor = Color(0xFF000000);

  late SpecialtyRepositoryInterface _specialtyRepository;
  late GroupRepositoryInterface _groupRepository;
  late ScheduleRepository _repository;

  List<data_model.Specialty> _specialties = [];
  List<Group> _groups = [];
  data_model.Specialty? _selectedSpecialty;
  Group? _selectedGroup;
  bool _isLoading = false;
  bool _isRefreshing = false;
  DateTime? _lastUpdate;

  static const String _selectedGroupKey = 'selected_group';
  static const String _selectedSpecialtyKey = 'selected_specialty';

  @override
  void initState() {
    super.initState();
    _specialtyRepository = SpecialtyRepository();
    _groupRepository = GroupRepository();
    _repository = ScheduleRepository();
    _loadSpecialties();
    _loadSelectedPreferences();
  }

  Future<void> _loadSpecialties() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final specialties = await _specialtyRepository.getSpecialties();
      // Преобразуем доменные сущности в модели данных
      final dataSpecialties = specialties
          .map((s) => data_model.Specialty(code: s.code, name: s.name))
          .toList();

      setState(() {
        _specialties = dataSpecialties.cast<data_model.Specialty>();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        showErrorNotification(
          context,
          'Ошибка загрузки',
          'Не удалось загрузить специальности',
          Icons.error_outline,
        );
      }
    }
  }

  Future<void> _loadSelectedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final selectedGroupCode = prefs.getString(_selectedGroupKey);
      final selectedSpecialtyCode = prefs.getString(_selectedSpecialtyKey);
      final selectedSpecialtyName = prefs.getString(
        '${_selectedSpecialtyKey}_name',
      );

      // Загружаем время последнего обновления
      final lastUpdateMillis = prefs.getString('last_schedule_update');
      if (lastUpdateMillis != null && lastUpdateMillis.isNotEmpty) {
        try {
          if (RegExp(r'^\d+$').hasMatch(lastUpdateMillis)) {
            _lastUpdate = DateTime.fromMillisecondsSinceEpoch(
              int.parse(lastUpdateMillis),
            );
          } else {}
        } catch (e) {
          // Игнорируем ошибку парсинга даты
        }
      }

      setState(() {
        if (selectedGroupCode != null && selectedGroupCode.isNotEmpty) {
          // Устанавливаем выбранную группу
          _selectedGroup = Group(
            code: selectedGroupCode,
            specialtyCode: selectedSpecialtyCode ?? '',
            specialtyName: selectedSpecialtyName ?? '',
          );
        }

        if (selectedSpecialtyCode != null && selectedSpecialtyCode.isNotEmpty) {
          if (selectedSpecialtyName != null &&
              selectedSpecialtyName.isNotEmpty) {
            _selectedSpecialty = data_model.Specialty(
              code: selectedSpecialtyCode,
              name: selectedSpecialtyName,
            );
          } else if (_specialties.isNotEmpty) {
            final selectedSpecialty = _specialties.firstWhere(
              (specialty) => specialty.code == selectedSpecialtyCode,
              orElse: () => data_model.Specialty(code: '', name: ''),
            );

            if (selectedSpecialty.code.isNotEmpty) {
              _selectedSpecialty = selectedSpecialty;
            }
          }

          // Загружаем группы для выбранной специальности
          if (_selectedSpecialty != null &&
              _selectedSpecialty!.code.isNotEmpty) {
            // Добавляем небольшую задержку для корректной инициализации
            Future.delayed(const Duration(milliseconds: 100), () {
              _loadGroups(_selectedSpecialty!.code);
            });
          }
        }
      });
    } catch (e) {
      // Игнорируем ошибки при загрузке предпочтений
    }
  }

  /// Получает текст для отображения времени последнего обновления
  String _getLastUpdateText() {
    if (_lastUpdate == null) {
      return 'Расписание еще не обновлялось';
    }

    final now = DateTime.now();
    final difference = now.difference(_lastUpdate!);

    if (difference.inDays > 0) {
      return 'Последнее обновление: ${_lastUpdate!.day}.${_lastUpdate!.month.toString().padLeft(2, '0')} в ${_lastUpdate!.hour.toString().padLeft(2, '0')}:${_lastUpdate!.minute.toString().padLeft(2, '0')}';
    } else if (difference.inHours > 0) {
      return 'Последнее обновление: ${difference.inHours} ${_getHoursText(difference.inHours)} назад';
    } else if (difference.inMinutes > 0) {
      return 'Последнее обновление: ${difference.inMinutes} ${_getMinutesText(difference.inMinutes)} назад';
    } else {
      return 'Последнее обновление: только что';
    }
  }

  /// Возвращает правильное склонение слова "час" в зависимости от числа
  String _getHoursText(int hours) {
    if (hours % 10 == 1 && hours % 100 != 11) {
      return 'час';
    } else if (hours % 10 >= 2 &&
        hours % 10 <= 4 &&
        (hours % 100 < 10 || hours % 100 >= 20)) {
      return 'часа';
    } else {
      return 'часов';
    }
  }

  /// Возвращает правильное склонение слова "минута" в зависимости от числа
  String _getMinutesText(int minutes) {
    if (minutes % 10 == 1 && minutes % 100 != 11) {
      return 'минуту';
    } else if (minutes % 10 >= 2 &&
        minutes % 10 <= 4 &&
        (minutes % 100 < 10 || minutes % 100 >= 20)) {
      return 'минуты';
    } else {
      return 'минут';
    }
  }

  /// Обновляет расписание
  Future<void> _refreshSchedule() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      // Проверяем, выбрана ли группа
      final prefs = await SharedPreferences.getInstance();
      final selectedGroupCode = prefs.getString(_selectedGroupKey);

      if (selectedGroupCode == null || selectedGroupCode.isEmpty) {
        if (mounted) {
          showInfoNotification(
            context,
            'Выберите группу',
            'Сначала выберите специальность и группу',
            Icons.info_outline,
          );
        }
        setState(() {
          _isRefreshing = false;
        });
        return;
      }

      // Обновляем расписание через новый репозиторий
      await _repository.refreshAllData();

      // Сохраняем время обновления
      final now = DateTime.now();
      await prefs.setString(
        'last_schedule_update',
        now.millisecondsSinceEpoch.toString(),
      );

      setState(() {
        _lastUpdate = now;
        _isRefreshing = false;
      });

      if (mounted) {
        showSuccessNotification(
          context,
          'Расписание обновлено',
          'Данные успешно загружены',
          Icons.check_circle_outline,
        );
      }
    } catch (e) {
      setState(() {
        _isRefreshing = false;
      });

      if (mounted) {
        showErrorNotification(
          context,
          'Ошибка обновления',
          'Не удалось обновить расписание',
          Icons.error_outline,
        );
      }
    }
  }

  Future<void> _loadGroups(String specialtyCode) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final groups = await _groupRepository.getGroupsBySpecialty(specialtyCode);
      // Не выполняем дополнительную сортировку, так как группы уже отсортированы в репозитории
      // Порядок сортировки: сначала по специальности, затем по году (новые года выше), затем по номеру группы
      final sortedGroups = List<Group>.from(groups);

      // Загружаем выбранную группу, если она была сохранена
      Group? selectedGroup;
      if (_selectedGroup != null) {
        // Проверяем, существует ли выбранная группа в новом списке
        selectedGroup = sortedGroups.firstWhere(
          (group) => group.code == _selectedGroup!.code,
          orElse: () => Group(code: '', specialtyCode: '', specialtyName: ''),
        );

        // Если группа не найдена, сбрасываем выбор
        if (selectedGroup.code.isEmpty) {
          selectedGroup = null;
        }
      } else {
        // Проверяем, есть ли сохраненная группа в настройках
        final prefs = await SharedPreferences.getInstance();
        final savedGroupCode = prefs.getString(_selectedGroupKey);
        if (savedGroupCode != null && savedGroupCode.isNotEmpty) {
          selectedGroup = sortedGroups.firstWhere(
            (group) => group.code == savedGroupCode,
            orElse: () => Group(code: '', specialtyCode: '', specialtyName: ''),
          );

          // Если группа не найдена, сбрасываем выбор
          if (selectedGroup.code.isEmpty) {
            selectedGroup = null;
          }
        }
      }

      setState(() {
        _groups = sortedGroups;
        _isLoading = false;
        // Обновляем выбранную группу только если она существует в новом списке
        if (selectedGroup != null) {
          _selectedGroup = selectedGroup;
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        showErrorNotification(
          context,
          'Ошибка загрузки',
          'Не удалось загрузить группы',
          Icons.error_outline,
        );
      }
    }
  }

  Future<void> _onSpecialtySelected(data_model.Specialty specialty) async {
    setState(() {
      _selectedSpecialty = specialty;
      _groups = [];
      _selectedGroup = null;
    });

    // Сохраняем выбранную специальность в настройках
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedSpecialtyKey, specialty.code);
    await prefs.setString('${_selectedSpecialtyKey}_name', specialty.name);
    await _loadGroups(specialty.code);
  }

  void _onGroupSelected(Group group) async {
    setState(() {
      _selectedGroup = group;
    });

    try {
      // Сохраняем выбранную группу в настройках
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_selectedGroupKey, group.code);
      await prefs.setString(_selectedSpecialtyKey, group.specialtyCode);
      await prefs.setString(
        '${_selectedSpecialtyKey}_name',
        group.specialtyName,
      );

      // Обновляем расписание для новой группы
      try {
        await _repository.refreshAllData();

        // Сохраняем время обновления
        final now = DateTime.now();
        await prefs.setString(
          'last_schedule_update',
          now.millisecondsSinceEpoch.toString(),
        );

        setState(() {
          _lastUpdate = now;
        });

        // Отправляем уведомление об обновлении данных всем слушателям
        _repository.dataUpdatedNotifier.value =
            !_repository.dataUpdatedNotifier.value;

        if (mounted) {
          showSuccessNotification(
            context,
            'Группа выбрана',
            'Выбрана группа ${group.code}. Расписание обновлено.',
            Icons.check_circle_outline,
          );
        }
      } catch (e) {
        if (mounted) {
          showErrorNotification(
            context,
            'Группа выбрана',
            'Выбрана группа ${group.code}, но произошла ошибка при обновлении расписания.',
            Icons.warning,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showErrorNotification(
          context,
          'Ошибка',
          'Произошла ошибка при выборе группы.',
          Icons.error_outline,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SettingsHeader(),
              const SizedBox(height: 28),
              const Section(title: 'Учебная группа'),
              const SizedBox(height: 14),
              SettingsCard(
                title: 'Выберите свою специальность',
                subtitle:
                    _selectedSpecialty?.name ?? 'Специальность не выбрана',
                icon: Icons.book_outlined,
                onTap: _showSpecialtySelector,
              ),
              const SizedBox(height: 14),
              SettingsCard(
                title: 'Выберите свою группу',
                subtitle: _selectedGroup?.code ?? 'Группа не выбрана',
                icon: Icons.school_outlined,
                onTap: _selectedSpecialty != null ? _showGroupSelector : null,
              ),
              const SizedBox(height: 28),
              const Section(title: 'Расписание'),
              const SizedBox(height: 14),
              SettingsCard(
                title: 'Обновить расписание',
                subtitle: _getLastUpdateText(),
                icon: Icons.refresh,
                onTap: _refreshSchedule,
                isRefreshing: _isRefreshing,
              ),
              const SizedBox(height: 28),
              const Section(title: 'Обратная связь'),
              const SizedBox(height: 14),
              SettingsCard(
                title: 'Связаться с разработчиком',
                subtitle: 'Сообщить об ошибке или предложить улучшение',
                icon: Icons.chat_outlined,
                onTap: _openSupportLink,
              ),
              const SizedBox(height: 28),
              const Section(title: 'Дополнительно'),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: _showAboutDialog,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const ListTile(
                    leading: Icon(Icons.info_outline, color: Colors.white),
                    title: Text(
                      'О приложении',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.white54,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111111),
          title: const Text(
            'О приложении',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Мой МПТ - Мобильное приложение для студентов Московского приборостроительного техникума, позволяющее просматривать расписание занятий, звонки и другую полезную информацию.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Разработчики:',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Студенты группы П50-1-22:',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Себежко Александр Андреевич',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Симернин Матвей Александрович',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Версия: 0.1.4',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              child: const Text(
                'Закрыть',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Открывает ссылку поддержки в Telegram
  Future<void> _openSupportLink() async {
    final Uri supportUri = Uri.parse('https://telegram.me/MptSupportBot');
    if (!await launchUrl(supportUri)) {
      // Показываем сообщение об ошибке, если не удалось открыть ссылку
      if (mounted) {
        showErrorNotification(
          context,
          'Ошибка',
          'Не удалось открыть ссылку поддержки',
          Icons.error_outline,
        );
      }
    }
  }

  void _showSpecialtySelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: const BoxDecoration(
            color: Color(0xFF111111),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.all(16),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Выберите специальность',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : ListView.builder(
                        itemCount: _specialties.length,
                        itemBuilder: (context, index) {
                          final specialty = _specialties[index];
                          return ListTile(
                            title: Text(
                              specialty.name,
                              style: const TextStyle(color: Colors.white),
                            ),
                            // Убираем subtitle с кодом специальности
                            onTap: () {
                              Navigator.pop(context);
                              _onSpecialtySelected(specialty);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showGroupSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.6,
              decoration: const BoxDecoration(
                color: Color(0xFF111111),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.all(16),
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Выберите группу',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                        : _groups.isEmpty
                        ? const Center(
                            child: Text(
                              'Группы не найдены',
                              style: TextStyle(color: Colors.white70),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _groups.length,
                            itemBuilder: (context, index) {
                              final group = _groups[index];
                              return ListTile(
                                title: Text(
                                  group.code,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  _onGroupSelected(group);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
