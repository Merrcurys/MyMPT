import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_mpt/core/services/background_task.dart';
import 'package:my_mpt/core/services/notification_service.dart';
import 'package:my_mpt/core/services/rustore_update_ui.dart';

import 'package:my_mpt/presentation/screens/calls_screen.dart';
import 'package:my_mpt/presentation/screens/overview_screen.dart';
import 'package:my_mpt/presentation/screens/schedule_screen.dart';
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

  // API для Overview: 0=Сегодня, 1=Завтра
  final ValueNotifier<int> _overviewPage = ValueNotifier<int>(0);

  late final List<Widget> _screens = <Widget>[
    OverviewScreen(innerPageRequest: _overviewPage),
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

  // Плавные переходы между root-экранами
  late final PageController _rootController = PageController(initialPage: _currentIndex);

  // Чтобы не конфликтовать с системным back-gesture от края
  static const double _systemGestureInset = 28.0;

  // На "Обзоре" ловим свайп только в двух карманах
  static const double _edgeZoneWidth = 70.0;

  // Пороги распознавания
  static const double _minDragDistance = 50.0;
  static const double _minVelocity = 500.0;

  double _dragDx = 0.0;

  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  @override
  void dispose() {
    _overviewPage.dispose();
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

  // Порядок: Сегодня -> Завтра -> Неделя -> Звонки -> Настройки
  void _goNextInChain() {
    if (_currentIndex == 0) {
      final page = _overviewPage.value.clamp(0, 1);
      if (page == 0) {
        _overviewPage.value = 1; // Сегодня -> Завтра
        return;
      }
      _animateRootTo(1); // Завтра -> Неделя
      return;
    }

    _animateRootTo(_currentIndex + 1);
  }

  void _goPrevInChain() {
    if (_currentIndex == 0) {
      final page = _overviewPage.value.clamp(0, 1);
      if (page == 1) {
        _overviewPage.value = 0; // Завтра -> Сегодня
      }
      return;
    }

    if (_currentIndex == 1) {
      // Неделя -> возвращаемся в Обзор на "Завтра"
      _overviewPage.value = 1;
      _animateRootTo(0);
      return;
    }

    _animateRootTo(_currentIndex - 1);
  }

  void _panStart(DragStartDetails details) => _dragDx = 0.0;

  void _panUpdate(DragUpdateDetails details) {
    _dragDx += details.delta.dx;
  }

  void _panEnd(DragEndDetails details) {
    final v = details.velocity.pixelsPerSecond.dx;

    final okByDistance = _dragDx.abs() >= _minDragDistance;
    final okByVelocity = v.abs() >= _minVelocity;
    if (!okByDistance && !okByVelocity) return;

    final toRight = okByDistance ? (_dragDx > 0) : (v > 0);
    if (toRight) {
      _goPrevInChain();
    } else {
      _goNextInChain();
    }
  }

  Widget _swipeLayerFull() {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragStart: _panStart,
        onHorizontalDragUpdate: _panUpdate,
        onHorizontalDragEnd: _panEnd,
      ),
    );
  }

  Widget _swipeLayerEdgesOnly() {
    return Stack(
      children: [
        Positioned(
          left: _systemGestureInset,
          top: 0,
          bottom: 0,
          width: _edgeZoneWidth,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: _panStart,
            onHorizontalDragUpdate: _panUpdate,
            onHorizontalDragEnd: _panEnd,
          ),
        ),
        Positioned(
          right: _systemGestureInset,
          top: 0,
          bottom: 0,
          width: _edgeZoneWidth,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: _panStart,
            onHorizontalDragUpdate: _panUpdate,
            onHorizontalDragEnd: _panEnd,
          ),
        ),
      ],
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
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (i) => setState(() => _currentIndex = i),
            children: _screens,
          ),

          // На Обзоре — только “карманы”, на остальных — вся ширина
          if (_currentIndex == 0) _swipeLayerEdgesOnly() else _swipeLayerFull(),
        ],
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _animateRootTo,
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
