import 'package:flutter/material.dart';
import 'package:my_mpt/data/repositories/specialty_repository.dart';
import 'package:my_mpt/data/repositories/group_repository.dart';
import 'package:my_mpt/data/models/group.dart';
import 'package:my_mpt/data/models/specialty.dart' as data_model;
import 'package:my_mpt/domain/repositories/specialty_repository_interface.dart';
import 'package:my_mpt/domain/repositories/group_repository_interface.dart';
import 'package:my_mpt/core/services/fcm_firestore_service.dart';
import 'package:my_mpt/core/services/preload_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Экран приветствия и настройки приложения
///
/// Этот экран отображается при первом запуске приложения и позволяет
/// пользователю выбрать свою специальность и группу
class WelcomeScreen extends StatefulWidget {
  /// Обратный вызов при завершении настройки
  final VoidCallback onSetupComplete;

  const WelcomeScreen({super.key, required this.onSetupComplete});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

/// Состояние экрана приветствия
class _WelcomeScreenState extends State<WelcomeScreen> {
  /// Сервис предзагрузки данных
  final PreloadService _preloadService = PreloadService();

  /// Список специальностей
  List<data_model.Specialty> _specialties = [];

  /// Список групп
  List<Group> _groups = [];

  /// Выбранная специальность
  data_model.Specialty? _selectedSpecialty;

  /// Выбранная группа
  Group? _selectedGroup;

  /// Флаг загрузки специальностей
  bool _isLoading = false;

  /// Флаг загрузки групп
  bool _isGroupsLoading = false;

  /// Текущая страница (0: приветствие, 1: выбор специальности, 2: выбор группы)
  int _currentPage = 0;

  /// Ключ для хранения выбранной группы в настройках
  static const _selectedSpecialtyKey = 'selected_specialty';
  static const _selectedGroupKey = 'selected_group';
  static const _firstLaunchKey = 'first_launch';

  late SpecialtyRepositoryInterface _specialtyRepository;
  late GroupRepositoryInterface _groupRepository;

  @override
  void initState() {
    super.initState();
    _specialtyRepository = SpecialtyRepository();
    _groupRepository = GroupRepository();
    // Предзагружаем все данные при первом запуске
    _preloadAllData();
  }

  /// Предзагружает все специальности и группы в фоновом режиме
  Future<void> _preloadAllData() async {
    // Запускаем предзагрузку в фоне, не блокируя UI
    _preloadService.preloadAllData();
  }

  /// Загрузка списка специальностей
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка загрузки специальностей')),
        );
      }
    }
  }

  /// Загрузка списка групп по коду специальности
  ///
  /// Параметры:
  /// - [specialtyCode]: Код специальности
  Future<void> _loadGroups(String specialtyCode) async {
    setState(() {
      _isGroupsLoading = true;
      _groups = [];
    });

    try {
      final groups = await _groupRepository.getGroupsBySpecialty(specialtyCode);
      // Не выполняем дополнительную сортировку, так как группы уже отсортированы в репозитории
      // Порядок сортировки: сначала по специальности, затем по году (новые года выше), затем по номеру группы
      final sortedGroups = List<Group>.from(groups);

      setState(() {
        _groups = sortedGroups;
        _isGroupsLoading = false;

        // Проверяем, была ли ранее выбрана группа
        if (_selectedGroup != null) {
          final previouslySelected = sortedGroups.firstWhere(
            (group) => group.code == _selectedGroup!.code,
            orElse: () => Group(code: '', specialtyCode: '', specialtyName: ''),
          );

          if (previouslySelected.code.isNotEmpty) {
            _selectedGroup = previouslySelected;
          } else {
            _selectedGroup = null;
          }
        }
      });
    } catch (e) {
      setState(() {
        _isGroupsLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ошибка загрузки групп')));
      }
    }
  }

  /// Сохранение выбранной специальности и группы и переход к основному приложению
  Future<void> _saveSelectionAndProceed() async {
    if (_selectedSpecialty == null || _selectedGroup == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Пожалуйста, выберите специальность и группу'),
          ),
        );
      }
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_selectedSpecialtyKey, _selectedSpecialty!.code);
      await prefs.setString(
        '${_selectedSpecialtyKey}_name',
        _selectedSpecialty!.name,
      );
      await prefs.setString(_selectedGroupKey, _selectedGroup!.code);
      await prefs.setBool(_firstLaunchKey, false);
      try {
        await FcmFirestoreService().syncTokenWithGroup();
      } catch (_) {}

      if (mounted) {
        widget.onSetupComplete();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка сохранения настроек')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Container(
        color: const Color(0xFF000000),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: _buildPageContent(),
          ),
        ),
      ),
    );
  }

  /// Создание содержимого страницы в зависимости от текущего состояния
  ///
  /// Возвращает:
  /// - Widget: Виджет содержимого страницы
  Widget _buildPageContent() {
    switch (_currentPage) {
      case 0:
        return _buildWelcomePage();
      case 1:
        return _buildSpecialtySelectionPage();
      case 2:
        return _buildGroupSelectionPage();
      default:
        return _buildWelcomePage();
    }
  }

  /// Создание страницы приветствия
  ///
  /// Возвращает:
  /// - Widget: Виджет страницы приветствия
  Widget _buildWelcomePage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Логотип или иконка (можно заменить на реальный логотип)
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.school, size: 60, color: Colors.black),
            ),
          ),
          const SizedBox(height: 40),
          const Text(
            'Добро пожаловать в',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w300,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            '"Мой МПТ"',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          const Text(
            'Мы рады, что вы выбрали именно этот техникум для обучения. Мы разработали это приложение, чтобы вам было более комфортно смотреть расписание.',
            style: TextStyle(fontSize: 16, color: Colors.white70, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 50),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _currentPage = 1;
                });
                _loadSpecialties();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 5,
              ),
              child: const Text(
                'Отлично',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Создание страницы выбора специальности
  ///
  /// Возвращает:
  /// - Widget: Виджет страницы выбора специальности
  Widget _buildSpecialtySelectionPage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Выберите свою специальность',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),
        Container(
          height: 50, // Уменьшена высота контейнера
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white24),
          ),
          child: _isLoading
              ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  ),
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<data_model.Specialty>(
                    value: _selectedSpecialty,
                    hint: const Text(
                      'Выберите специальность',
                      style: TextStyle(color: Colors.white70),
                    ),
                    items: _specialties.map((data_model.Specialty specialty) {
                      return DropdownMenuItem<data_model.Specialty>(
                        value: specialty,
                        child: Text(
                          specialty.name,
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }).toList(),
                    onChanged: (data_model.Specialty? newValue) {
                      setState(() {
                        _selectedSpecialty = newValue;
                      });
                    },
                    isExpanded: true,
                    dropdownColor: const Color(0xFF111111),
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: Colors.white,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _selectedSpecialty != null
                ? () {
                    setState(() {
                      _currentPage = 2;
                    });
                    _loadGroups(_selectedSpecialty!.code);
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 5,
              disabledBackgroundColor: Colors.white.withValues(alpha: 0.5),
              disabledForegroundColor: Colors.black.withValues(alpha: 0.5),
            ),
            child: const Text(
              'Продолжить',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        TextButton(
          onPressed: () {
            setState(() {
              _currentPage = 0;
            });
          },
          style: ButtonStyle(
            overlayColor: WidgetStateProperty.all<Color>(Colors.white30),
          ),
          child: const Text(
            'Назад',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ),
      ],
    );
  }

  /// Создание страницы выбора группы
  ///
  /// Возвращает:
  /// - Widget: Виджет страницы выбора группы
  Widget _buildGroupSelectionPage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Выберите свою группу',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white24),
          ),
          child: _isGroupsLoading
              ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  ),
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<Group>(
                    value: _selectedGroup,
                    hint: const Text(
                      'Выберите группу',
                      style: TextStyle(color: Colors.white70),
                    ),
                    items: _groups.map((Group group) {
                      return DropdownMenuItem<Group>(
                        value: group,
                        child: Text(
                          group.code,
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }).toList(),
                    onChanged: (Group? newValue) {
                      setState(() {
                        _selectedGroup = newValue;
                      });
                    },
                    isExpanded: true,
                    dropdownColor: const Color(0xFF111111),
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: Colors.white,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Поменять группу можно в настройках',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _selectedGroup != null ? _saveSelectionAndProceed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 5,
              disabledBackgroundColor: Colors.white.withValues(alpha: 0.5),
              disabledForegroundColor: Colors.black.withValues(alpha: 0.5),
            ),
            child: const Text(
              'Готово',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        TextButton(
          onPressed: () {
            setState(() {
              _currentPage = 1;
            });
          },
          style: ButtonStyle(
            overlayColor: WidgetStateProperty.all<Color>(Colors.white30),
          ),
          child: const Text(
            'Назад',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ),
      ],
    );
  }
}
