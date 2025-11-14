import 'package:flutter/material.dart';
import '../../data/models/specialty.dart';
import '../../data/models/group.dart';
import '../../data/repositories/specialty_repository.dart';

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

  late SpecialtyRepository _repository;
  List<Specialty> _specialties = [];
  List<Group> _groups = [];
  Specialty? _selectedSpecialty;
  Group? _selectedGroup;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _repository = SpecialtyRepository();
    _loadSpecialties();
  }

  Future<void> _loadSpecialties() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final specialties = await _repository.getSpecialties();
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

  Future<void> _loadGroups(String specialtyCode) async {
    setState(() {
      _isLoading = true;
      _groups = [];
      _selectedGroup = null;
    });
    
    try {
      final groups = await _repository.getGroupsBySpecialty(specialtyCode);
      setState(() {
        _groups = groups;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Handle error appropriately
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка загрузки групп')),
      );
    }
  }

  void _onSpecialtySelected(Specialty specialty) {
    setState(() {
      _selectedSpecialty = specialty;
      _selectedGroup = null;
    });
    _loadGroups(specialty.code);
  }

  void _onGroupSelected(Group group) {
    setState(() {
      _selectedGroup = group;
    });
    
    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Выбрана группа: ${group.code}')),
    );
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
                subtitle: _selectedSpecialty?.name ?? 'Специальность не выбрана',
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
              ),
              const SizedBox(height: 28),
              const _Section(title: 'Дополнительно'),
              const SizedBox(height: 14),
              Container(
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
            ],
          ),
        ),
      ),
    );
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
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF8C00)))
                    : ListView.builder(
                        itemCount: _specialties.length,
                        itemBuilder: (context, index) {
                          final specialty = _specialties[index];
                          return ListTile(
                            title: Text(
                              specialty.name,
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              specialty.code,
                              style: const TextStyle(color: Colors.white70),
                            ),
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
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF8C00)))
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
          colors: [
            Color(0xFF333333),
            Color(0xFF111111),
          ],
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
