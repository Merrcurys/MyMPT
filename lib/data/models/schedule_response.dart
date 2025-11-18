import 'package:my_mpt/domain/entities/schedule.dart';

class ScheduleResponse {
  final Map<String, List<Schedule>> weeklySchedule;
  final List<Schedule> todaySchedule;

  ScheduleResponse({
    required this.weeklySchedule,
    required this.todaySchedule,
  });

  factory ScheduleResponse.fromJson(Map<String, dynamic> json) {
    return ScheduleResponse(
      weeklySchedule: _getMockWeeklySchedule(),
      todaySchedule: _getMockTodaySchedule(),
    );
  }

  static Map<String, List<Schedule>> _getMockWeeklySchedule() {
    return {
      'Понедельник': [
        Schedule(
          id: '1',
          number: '1',
          subject: 'Математическое моделирование',
          teacher: 'Петров П.П.',
          startTime: '10:10',
          endTime: '11:40',
          building: 'Нахимовский',
        ),
        Schedule(
          id: '2',
          number: '2',
          subject: 'Физика',
          teacher: 'Петров П.П.',
          startTime: '10:10',
          endTime: '11:40',
          building: 'Нахимовский',
        ),
        Schedule(
          id: '3',
          number: '3',
          subject: 'Программирование',
          teacher: 'Сидоров С.С.',
          startTime: '12:00',
          endTime: '13:30',
          building: 'Нахимовский',
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
          subject: 'Обеспечение качества функционирования КС',
          teacher: 'Иванова И.И.',
          startTime: '08:30',
          endTime: '09:15',
          building: 'Нежинская',
        ),
        Schedule(
          id: '10',
          number: '2',
          subject: 'Иностранный язык в профессиональной деятельности',
          teacher: 'Завьялова П.П., Завьялова П.П.',
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
  }

  static List<Schedule> _getMockTodaySchedule() {
    return [
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
  }
}