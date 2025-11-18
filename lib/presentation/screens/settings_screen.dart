import 'package:flutter/material.dart';
import 'package:my_mpt/domain/entities/specialty.dart';
import 'package:my_mpt/domain/entities/group.dart';
import 'package:my_mpt/domain/usecases/get_specialties_usecase.dart';
import 'package:my_mpt/domain/usecases/get_groups_by_specialty_usecase.dart';
import 'package:my_mpt/domain/repositories/specialty_repository_interface.dart';
import 'package:my_mpt/data/repositories/mpt_repository.dart' as repo_impl;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _backgroundColor = Color(0xFF000000);
  static const List<Color> _headerGradient = [
    Color(0xFF333333),
    Color(0xFF111111),
  ];

  late SpecialtyRepositoryInterface _repository;
  late GetSpecialtiesUseCase _getSpecialtiesUseCase;
  late GetGroupsBySpecialtyUseCase _getGroupsBySpecialtyUseCase;
  List<Specialty> _specialties = [];
  List<Group> _groups = [];
  Specialty? _selectedSpecialty;
  Group? _selectedGroup;
  String? _selectedSpecialtyCode;
  bool _isLoading = false;
  StateSetter? _modalStateSetter;

  static const String _selectedGroupKey = 'selected_group';
  static const String _selectedSpecialtyKey = 'selected_specialty';

  @override
  void initState() {
    super.initState();
    _repository = repo_impl.MptRepository();
    _getSpecialtiesUseCase = GetSpecialtiesUseCase(_repository);
    _getGroupsBySpecialtyUseCase = GetGroupsBySpecialtyUseCase(_repository);
    _loadSpecialties();
    _loadSelectedPreferences();
  }

  Future<void> _loadSpecialties() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final specialties = await _getSpecialtiesUseCase();
      setState(() {
        _specialties = specialties;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Handle error appropriately
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка загрузки специальностей')),
      );
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

      setState(() {
        if (selectedGroupCode != null && selectedGroupCode.isNotEmpty) {
          // Здесь можно загрузить информацию о группе, если это необходимо
          // Пока просто устанавливаем состояние
          _selectedGroup = Group(code: selectedGroupCode, specialtyCode: '');
        }

        if (selectedSpecialtyCode != null && selectedSpecialtyCode.isNotEmpty) {
          _selectedSpecialtyCode = selectedSpecialtyCode;

          if (selectedSpecialtyName != null &&
              selectedSpecialtyName.isNotEmpty) {
            _selectedSpecialty = Specialty(
              code: selectedSpecialtyCode,
              name: selectedSpecialtyName,
            );
          } else if (_specialties.isNotEmpty) {
            final selectedSpecialty = _specialties.firstWhere(
              (specialty) => specialty.code == selectedSpecialtyCode,
              orElse: () => Specialty(code: '', name: ''),
            );

            if (selectedSpecialty.code.isNotEmpty) {
              _selectedSpecialty = selectedSpecialty;
            }
          }
        }
      });
    } catch (e) {
      print('DEBUG: Ошибка загрузки выбранных настроек: $e');
    }
  }

  Future<void> _loadGroups(String specialtyCode) async {
    print('DEBUG: Начинаем загрузку групп для специальности: $specialtyCode');
    print('DEBUG: Длина кода специальности: ${specialtyCode.length}');
    print('DEBUG: Код специальности в байтах: ${specialtyCode.codeUnits}');
    print('DEBUG: Начинается с #: ${specialtyCode.startsWith('#')}');
    print('DEBUG: Тип кода специальности: ${specialtyCode.runtimeType}');
    setState(() {
      _isLoading = true;
      _groups = [];
      _selectedGroup = null;
    });

    try {
      final groups = await _getGroupsBySpecialtyUseCase(specialtyCode);
      print('DEBUG: Получено групп: ${groups.length}');
      setState(() {
        _groups = groups;
        _isLoading = false;
      });

      // Обновляем состояние модального окна, если оно открыто
      _modalStateSetter?.call(() {});

      // Show message if no groups found
      if (groups.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Для выбранной специальности группы не найдены'),
          ),
        );
      } else {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Загружено ${groups.length} групп')),
        );
      }

      // Force refresh the UI
      setState(() {});
    } catch (e) {
      print('DEBUG: Ошибка загрузки групп: $e');
      setState(() {
        _isLoading = false;
      });
      // Handle error appropriately
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка загрузки групп: $e')));
    }
  }

  void _onSpecialtySelected(Specialty specialty) async {
    print(
      'DEBUG: Выбрана специальность: ${specialty.code} - ${specialty.name}',
    );
    setState(() {
      _selectedSpecialty = specialty;
      _selectedSpecialtyCode = specialty.code; // Also store the code
      _selectedGroup = null;
    });

    // Сохраняем выбранную специальность в настройки
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_selectedSpecialtyKey, specialty.code);
      // Also save the specialty name for immediate display
      await prefs.setString('${_selectedSpecialtyKey}_name', specialty.name);
    } catch (e) {
      print('DEBUG: Ошибка сохранения выбранной специальности: $e');
    }

    _loadGroups(specialty.code);
  }

  void _onGroupSelected(Group group) async {
    setState(() {
      _selectedGroup = group;
    });

    // Сохраняем выбранную группу в настройки
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_selectedGroupKey, group.code);
    } catch (e) {
      print('DEBUG: Ошибка сохранения выбранной группы: $e');
    }

    // Show confirmation
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Выбрана группа: ${group.code}')));
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
              const _SettingsHeader(),
              const SizedBox(height: 28),
              const _Section(title: 'Учебная группа'),
              const SizedBox(height: 14),
              _SettingsCard(
                title: 'Выберите свою специальность',
                subtitle:
                    _selectedSpecialty?.name ?? 'Специальность не выбрана',
                icon: Icons.book_outlined,
                onTap: _showSpecialtySelector,
              ),
              const SizedBox(height: 14),
              _SettingsCard(
                title: 'Выберите свою группу',
                subtitle: _selectedGroup?.code ?? 'Группа не выбрана',
                icon: Icons.school_outlined,
                onTap: _selectedSpecialty != null ? _showGroupSelector : null,
              ),
              const SizedBox(height: 28),
              const _Section(title: 'Расписание'),
              const SizedBox(height: 14),
              _SettingsCard(
                title: 'Обновить расписание',
                subtitle: 'Последнее обновление: сегодня в 08:30',
                icon: Icons.refresh,
              ),
              const SizedBox(height: 28),
              const _Section(title: 'Обратная связь'),
              const SizedBox(height: 14),
              _SettingsCard(
                title: 'Связаться с разработчиком',
                subtitle: 'Сообщить об ошибке или предложить улучшение',
                icon: Icons.chat_outlined,
                onTap: _openSupportLink,
              ),
              const SizedBox(height: 28),
              const _Section(title: 'Дополнительно'),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: _showAboutDialog,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const ListTile(
                    leading: Icon(Icons.info_outline, color: Color(0xFFFF8C00)),
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
          content: const Text(
            'Приложение создано студентами группы П50-1-22',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Закрыть',
                style: TextStyle(color: Color(0xFFFF8C00)),
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось открыть ссылку поддержки')),
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
                  color: Colors.white.withOpacity(0.3),
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
                        child: CircularProgressIndicator(
                          color: Color(0xFFFF8C00),
                        ),
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
            // Сохраняем StateSetter для обновления состояния модального окна
            _modalStateSetter = setModalState;

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
                      color: Colors.white.withOpacity(0.3),
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
                              color: Color(0xFFFF8C00),
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

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 26),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [Color(0xFF333333), Color(0xFF111111)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Настройки',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Персонализируйте расписание и связь с техникумом',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;

  const _Section({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  const _SettingsCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFFF8C00).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: const Color(0xFFFF8C00)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                ],
              ),
            ),
            Icon(
              onTap != null ? Icons.arrow_forward_ios : null,
              size: 16,
              color: Colors.white54,
            ),
          ],
        ),
      ),
    );
  }
}
