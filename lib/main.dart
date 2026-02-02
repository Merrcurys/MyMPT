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

  static const double _minDragDistance = 50.0;
  static const double _minVelocity = 400.0;
  double _dragDx = 0.0;

  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
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

  void _goToPage(int index) {
    if (index < 0 || index >= _screens.length) return;
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  void _onHorizontalDragStart(DragStartDetails _) => _dragDx = 0.0;
  void _onHorizontalDragUpdate(DragUpdateDetails d) => _dragDx += d.delta.dx;
  void _onHorizontalDragEnd(DragEndDetails d) {
    final v = d.velocity.pixelsPerSecond.dx;
    final byDistance = _dragDx.abs() >= _minDragDistance;
    final byVelocity = v.abs() >= _minVelocity;
    if (!byDistance && !byVelocity) return;
    final toRight = byDistance ? (_dragDx > 0) : (v > 0);
    if (toRight && _currentIndex > 0) _goToPage(_currentIndex - 1);
    else if (!toRight && _currentIndex < _screens.length - 1) _goToPage(_currentIndex + 1);
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
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragStart: _onHorizontalDragStart,
            onHorizontalDragUpdate: _onHorizontalDragUpdate,
            onHorizontalDragEnd: _onHorizontalDragEnd,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: child,
              ),
              child: KeyedSubtree(
                key: ValueKey<int>(_currentIndex),
                child: _screens[_currentIndex],
              ),
            ),
          ),
          if (_currentIndex == 0 || _currentIndex == 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.of(context).padding.bottom + 80 + 10,
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
            if (index == 0) _goToPage(0);
            else _goToPage(index + 1);
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
