import 'package:flutter/material.dart';
import 'package:my_mpt/domain/entities/schedule.dart';

/// Экран "Расписание"
class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Данные расписания на неделю
    final Map<String, List<Schedule>> weeklySchedule = {
      'Понедельник': [
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
      ],
      'Вторник': [
        Schedule(
          id: '4',
          number: '1',
          subject: 'Английский язык',
          teacher: 'Козлова К.К.',
          startTime: '08:30',
          endTime: '09:15',
          building: 'Нахимовский',
        ),
        Schedule(
          id: '5',
          number: '2',
          subject: 'Физическая культура',
          teacher: 'Васильев В.В.',
          startTime: '09:25',
          endTime: '10:10',
          building: 'Нежинская',
        ),
      ],
      'Среда': [
        Schedule(
          id: '6',
          number: '1',
          subject: 'Математика',
          teacher: 'Иванова И.И.',
          startTime: '08:30',
          endTime: '09:15',
          building: 'Нежинская',
        ),
        Schedule(
          id: '7',
          number: '2',
          subject: 'Программирование',
          teacher: 'Сидоров С.С.',
          startTime: '09:25',
          endTime: '10:10',
          building: 'Нахимовский',
        ),
        Schedule(
          id: '8',
          number: '3',
          subject: 'Физика',
          teacher: 'Петров П.П.',
          startTime: '10:30',
          endTime: '11:15',
          building: 'Нежинская',
        ),
      ],
      'Четверг': [
        Schedule(
          id: '9',
          number: '1',
          subject: 'Математика',
          teacher: 'Иванова И.И.',
          startTime: '08:30',
          endTime: '09:15',
          building: 'Нежинская',
        ),
        Schedule(
          id: '10',
          number: '2',
          subject: 'Физика',
          teacher: 'Петров П.П.',
          startTime: '09:25',
          endTime: '10:10',
          building: 'Нахимовский',
        ),
        Schedule(
          id: '11',
          number: '3',
          subject: 'Программирование',
          teacher: 'Сидоров С.С.',
          startTime: '10:30',
          endTime: '11:15',
          building: 'Нежинская',
        ),
        Schedule(
          id: '12',
          number: '4',
          subject: 'Английский язык',
          teacher: 'Козлова К.К.',
          startTime: '11:25',
          endTime: '12:10',
          building: 'Нахимовский',
        ),
        Schedule(
          id: '13',
          number: '5',
          subject: 'Физическая культура',
          teacher: 'Васильев В.В.',
          startTime: '12:30',
          endTime: '13:15',
          building: 'Нежинская',
        ),
      ],
      'Пятница': [
        Schedule(
          id: '14',
          number: '1',
          subject: 'Физика',
          teacher: 'Петров П.П.',
          startTime: '08:30',
          endTime: '09:15',
          building: 'Нахимовский',
        ),
        Schedule(
          id: '15',
          number: '2',
          subject: 'Математика',
          teacher: 'Иванова И.И.',
          startTime: '09:25',
          endTime: '10:10',
          building: 'Нежинская',
        ),
      ],
    };

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
                const Text(
                  'Четверг, 12 ноября',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Расписание на всю неделю
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              itemCount: weeklySchedule.keys.toList().length,
              itemBuilder: (context, dayIndex) {
                final day = weeklySchedule.keys.toList()[dayIndex];
                final daySchedule = weeklySchedule[day]!;
                
                // Функция для определения основного корпуса для дня
                String _getPrimaryBuilding(List<Schedule> schedule) {
                  if (schedule.isEmpty) return '';
                  
                  // Подсчет вхождений каждого корпуса
                  final buildingCount = <String, int>{};
                  for (final item in schedule) {
                    final building = item.building;
                    buildingCount[building] = (buildingCount[building] ?? 0) + 1;
                  }
                  
                  // Поиск корпуса с наибольшим количеством вхождений
                  String primaryBuilding = '';
                  int maxCount = 0;
                  buildingCount.forEach((building, count) {
                    if (count > maxCount) {
                      maxCount = count;
                      primaryBuilding = building;
                    }
                  });
                  
                  return primaryBuilding;
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Заголовок дня
                    Center(
                      child: Text(
                        '$day, ${_getPrimaryBuilding(daySchedule)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Элементы расписания для этого дня
                    Column(
                      children: List.generate(
                        daySchedule.length,
                        (index) {
                          final data = daySchedule[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ScheduleItem(
                              number: data.number,
                              subject: data.subject,
                              teacher: data.teacher,
                              startTime: data.startTime,
                              endTime: data.endTime,
                            ),
                          );
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                  ],
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