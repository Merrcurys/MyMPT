import 'package:flutter/material.dart';
import 'package:my_mpt/core/constants/app_constants.dart';

/// Экран "Звонки"
class CallsScreen extends StatelessWidget {
  const CallsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Заглушка с данными звонков
    final List<Map<String, String>> callsData = [
      {'time': '1', 'description': '08:30 - Начало занятий'},
      {'time': '2', 'description': '09:15 - Первый звонок'},
      {'time': '3', 'description': '09:25 - Начало второго занятия'},
      {'time': '4', 'description': '10:10 - Второй звонок'},
      {'time': '5', 'description': '10:30 - Начало третьего занятия'},
      {'time': '6', 'description': '11:15 - Третий звонок'},
      {'time': '7', 'description': '11:25 - Начало четвертого занятия'},
      {'time': '8', 'description': '12:10 - Четвертый звонок'},
      {'time': '9', 'description': '12:30 - Начало пятого занятия'},
      {'time': '10', 'description': '13:15 - Окончание занятий'},
    ];

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Звонки',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Будние дни',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF81C784),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF333333),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.notifications,
                    size: 28,
                    color: Color(0xFF81C784),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Info card
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF121212),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF333333),
                  width: 1,
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.info,
                      color: Color(0xFF81C784),
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Звонки происходят за 5 минут до начала/окончания занятия',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Calls list
            const Text(
              'Расписание звонков',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Column(
              children: List.generate(
                callsData.length,
                (index) {
                  final data = callsData[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF121212),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF333333),
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Номер звонка
                            Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                color: Color(0xFF81C784),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  data['time']!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Описание звонка
                            Expanded(
                              child: Text(
                                data['description']!,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}