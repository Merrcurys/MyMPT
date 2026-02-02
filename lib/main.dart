import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_mpt/core/services/background_task.dart';
import 'package:my_mpt/core/services/notification_service.dart';
import 'package:my_mpt/core/services/rustore_update_ui.dart';

import 'package:my_mpt/presentation/screens/calls_screen.dart';
import 'package:my_mpt/presentation/screens/overview_screen.dart';
import 'package:my_mpt/presentation/screens/schedule_screen.dart';
import 'package:my_mpt/presentation/widgets/overview/page_indicator.dart';
import 'package:my_mpt/presentation/screens/settings_screen.dart';
import 'package:my_mpt/presentation/screens/welcome_screen.dart';

Future<void> main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    final notificationService = NotificationService();
    await notificationService.initialize();

    await initializeBackgroundTasks();

    runApp(const MyApp());
  }, (e, st) {
    // debugPrint('Uncaught: $e');
    // debugPrintStack(stackTrace: st);
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Мой МПТ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFF000000),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF8C00),
          secondary: Color(0xFFFFA500),
          tertiary: Color(0xFFFFB347),
          surface: Color(0xFF121212),
        ),
        textTheme: ThemeData.dark().textTheme.apply(
              bodyColor: Colors.white,
              displayColor: Colors.white,
            ),
        appBarTheme: const AppBarTheme(
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        navigationBarTheme: NavigationBarThemeData(
          indicatorColor: const Color(0x33FFFFFF),
          height: 80,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          elevation: 0,
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(
              color: states.contains(WidgetState.selected) ? Colors.white : Colors.white70,
            ),
          ),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontSize: 11,
              fontWeight: states.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w500,
              letterSpacing: 0.1,
              color: states.contains(WidgetState.selected) ? Colors.white : Colors.white60,
            ),
          ),
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  bool _isFirstLaunch = true;
  bool _isLoading = true;
  bool _updateChecked = false;

  /// 5 страниц: Сегодня, Завтра, Неделя, Звонки, Настройки — единый свайп между всеми.
  late final List<Widget> _screens = <Widget>[
    OverviewScreen(forcedPage: 0),
    OverviewScreen(forcedPage: 1),
    const ScheduleScreen(),
    const CallsScreen(),
    const SettingsScreen(),
  ];

  final List<_NavItemData> _navItems = const [
    _NavItemData(icon: Icons.flash_on_outlined, label: 'Обзор'),
    _NavItemData(icon: Icons.view_week_outlined, label: 'Неделя'),
    _NavItemData(icon: Icons.notifications_none_outlined, label: 'Звонки'),
    _NavItemData(icon: Icons.settings_outlined, label: 'Настройки'),
  ];

  late final PageController _rootController = PageController(initialPage: _currentIndex);

  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  @override
  void dispose() {
    _rootController.dispose();
    super.dispose();
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('first_launch') ?? true;

    if (!mounted) return;
    setState(() {
      _isFirstLaunch = isFirstLaunch;
      _isLoading = false;
    });
  }

  Future<void> _onSetupComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('first_launch', false);

    if (!mounted) return;
    setState(() {
      _isFirstLaunch = false;
    });
  }

  void _animateRootTo(int index) {
    if (index < 0 || index >= _screens.length) return;
    if (index == _currentIndex) return;

    setState(() => _currentIndex = index);

    if (!_rootController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (!_rootController.hasClients) return;
        _rootController.animateToPage(
          index,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        );
      });
      return;
    }

    _rootController.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_isFirstLaunch) {
      return WelcomeScreen(
        onSetupComplete: () {
          _onSetupComplete();
        },
      );
    }

    if (!_updateChecked) {
      _updateChecked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        RuStoreUpdateUi.checkAndRunDeferredUpdate();
      });
    }

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          PageView(
            controller: _rootController,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            children: _screens,
          ),
          if (_currentIndex == 0 || _currentIndex == 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 115,
              child: IgnorePointer(
                child: PageIndicator(currentPageIndex: _currentIndex),
              ),
            ),
        ],
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: NavigationBar(
          selectedIndex: _currentIndex <= 1 ? 0 : _currentIndex - 1,
          onDestinationSelected: (index) {
            if (index == 0) _animateRootTo(0);
            else _animateRootTo(index + 1);
          },
          surfaceTintColor: Colors.transparent,
          destinations: [
            for (final item in _navItems)
              NavigationDestination(icon: Icon(item.icon), label: item.label),
          ],
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final String label;

  const _NavItemData({required this.icon, required this.label});
}
