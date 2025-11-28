import 'package:flutter/material.dart';
import 'package:my_mpt/core/constants/app_constants.dart';
import 'package:my_mpt/presentation/screens/calls_screen.dart';
import 'package:my_mpt/presentation/screens/schedule_screen.dart';
import 'package:my_mpt/presentation/screens/settings_screen.dart';
import 'package:my_mpt/presentation/screens/today_schedule_screen.dart';
import 'package:my_mpt/presentation/screens/welcome_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

void main() {
  runZonedGuarded(
    () {
      runApp(const MyApp());
    },
    (e, st) {
      print("Error catched in main thread $e");
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.collegeName,
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
          background: Color(0xFF000000),
        ),
        textTheme: ThemeData.dark().textTheme.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF111111),
          indicatorColor: const Color(0x33FFFFFF),
          height: 80,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          elevation: 0,
          iconTheme: MaterialStateProperty.resolveWith<IconThemeData>(
            (states) => IconThemeData(
              color: states.contains(MaterialState.selected)
                  ? Colors.white
                  : Colors.white70,
            ),
          ),
          labelTextStyle: MaterialStateProperty.resolveWith<TextStyle>(
            (states) => TextStyle(
              fontSize: 11,
              fontWeight: states.contains(MaterialState.selected)
                  ? FontWeight.w600
                  : FontWeight.w500,
              letterSpacing: 0.1,
              color: states.contains(MaterialState.selected)
                  ? Colors.white
                  : Colors.white60,
            ),
          ),
        ),
      ),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
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

  final List<Widget> _screens = const [
    TodayScheduleScreen(),
    ScheduleScreen(),
    CallsScreen(),
    SettingsScreen(),
  ];

  final List<_NavItemData> _navItems = const [
    _NavItemData(icon: Icons.flash_on_outlined, label: 'Обзор'),
    _NavItemData(icon: Icons.view_week_outlined, label: 'Неделя'),
    _NavItemData(icon: Icons.notifications_none_outlined, label: 'Звонки'),
    _NavItemData(icon: Icons.settings_outlined, label: 'Настройки'),
  ];

  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('first_launch') ?? true;

    setState(() {
      _isFirstLaunch = isFirstLaunch;
      _isLoading = false;
    });
  }

  void _onSetupComplete() {
    setState(() {
      _isFirstLaunch = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_isFirstLaunch) {
      return WelcomeScreen(onSetupComplete: _onSetupComplete);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) =>
              setState(() => _currentIndex = index),
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
