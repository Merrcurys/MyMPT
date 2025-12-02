import 'package:flutter/material.dart';
import 'package:my_mpt/data/models/call.dart';
import 'package:my_mpt/data/services/calls_service.dart';
import 'package:my_mpt/presentation/widgets/calls/calls_header.dart';
import 'package:my_mpt/presentation/widgets/calls/call_timeline_tile.dart';

/// Экран отображения расписания звонков техникума
///
/// Этот экран показывает расписание звонков на учебный день
/// с детализацией по периодам и времени начала/окончания каждого звона

/// Основной экран расписания звонков
class CallsScreen extends StatelessWidget {
  const CallsScreen({super.key});

  /// Цвет фона экрана
  static const _backgroundColor = Color(0xFF000000);

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
              const CallsHeader(),
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
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 30,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: Column(
                  children: List.generate(callsData.length, (index) {
                    final call = callsData[index];
                    final isLast = index == callsData.length - 1;
                    return CallTimelineTile(
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
