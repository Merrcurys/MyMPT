import 'package:flutter/material.dart';
import 'package:my_mpt/domain/entities/schedule.dart';

/// Экран "Расписание на сегодня"
class TodayScheduleScreen extends StatelessWidget {
  const TodayScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Данные расписания на сегодня
    final List<Schedule> scheduleData = [
      Schedule(
        id: '1',
        number: '1',
        subject: 'Математика',
        teacher: 'Иванова И.И.',
        startTime: '08:30',
        endTime: '09:15',
        building: 'Нежинская',
      ),
      Schedule(
        id: '2',
        number: '2',
        subject: 'Физика',
        teacher: 'Петров П.П.',
        startTime: '09:25',
        endTime: '10:10',
        building: 'Нахимовский',
      ),
      Schedule(
        id: '3',
        number: '3',
        subject: 'Программирование',
        teacher: 'Сидоров С.С.',
        startTime: '10:30',
        endTime: '11:15',
        building: 'Нежинская',
      ),
      Schedule(
        id: '4',
        number: '4',
        subject: 'Английский язык',
        teacher: 'Козлова К.К.',
        startTime: '11:25',
        endTime: '12:10',
        building: 'Нахимовский',
      ),
      Schedule(
        id: '5',
        number: '5',
        subject: 'Физическая культура',
        teacher: 'Васильев В.В.',
        startTime: '12:30',
        endTime: '13:15',
        building: 'Нежинская',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок недели
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFF7943C),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Числитель',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Четверг, 12 ноября',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Информация о корпусе
        Center(
          child: Text(
            'Нежинская',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[400],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        
        // Элементы расписания
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.separated(
              itemCount: scheduleData.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = scheduleData[index];
                return _ScheduleItem(
                  number: item.number,
                  subject: item.subject,
                  teacher: item.teacher,
                  startTime: item.startTime,
                  endTime: item.endTime,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Компактная карточка занятия
class _ScheduleItem extends StatelessWidget {
  final String number;
  final String subject;
  final String teacher;
  final String startTime;
  final String endTime;

  const _ScheduleItem({
    required this.number,
    required this.subject,
    required this.teacher,
    required this.startTime,
    required this.endTime,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF333333),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Номер пары
            Text(
              number,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            // Информация о паре
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    teacher,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            // Время
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  startTime,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  endTime,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}