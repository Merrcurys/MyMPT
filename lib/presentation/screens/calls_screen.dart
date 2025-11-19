import 'package:flutter/material.dart';
import 'package:my_mpt/data/models/call.dart';
import 'package:my_mpt/data/services/calls_service.dart';

/// Экран отображения расписания звонков техникума
///
/// Этот экран показывает расписание звонков на учебный день
/// с детализацией по периодам и времени начала/окончания каждого звона

/// Основной экран расписания звонков
class CallsScreen extends StatelessWidget {
  const CallsScreen({super.key});

  /// Цвет фона экрана
  static const _backgroundColor = Color(0xFF000000);

  /// Градиент для заголовка экрана
  static const List<Color> _headerGradient = [
    Color(0xFF333333),
    Color(0xFF111111),
  ];

  @override
  Widget build(BuildContext context) {
    final List<Call> callsData = CallsService.getCalls();

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _CallsHeader(),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.45),
                      blurRadius: 30,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: Column(
                  children: List.generate(callsData.length, (index) {
                    final call = callsData[index];
                    final isLast = index == callsData.length - 1;
                    return _CallTimelineTile(
                      period: call.period,
                      startTime: call.startTime,
                      endTime: call.endTime,
                      description: call.description,
                      showConnector: !isLast,
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Виджет заголовка экрана звонков
class _CallsHeader extends StatelessWidget {
  const _CallsHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: CallsScreen._headerGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Звонки техникума',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Расписание звонков на учебный день',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

/// Виджет элемента временной шкалы звонков
class _CallTimelineTile extends StatelessWidget {
  /// Номер периода/пары
  final String period;

  /// Время начала периода
  final String startTime;

  /// Время окончания периода
  final String endTime;

  /// Описание периода
  final String description;

  /// Флаг отображения соединительной линии
  final bool showConnector;

  const _CallTimelineTile({
    required this.period,
    required this.startTime,
    required this.endTime,
    required this.description,
    required this.showConnector,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF333333), Color(0xFF111111)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  period,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            if (showConnector)
              Container(
                width: 2,
                height: 48,
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: const Color(0xFFFFFFFF).withOpacity(0.3),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$startTime - $endTime',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
