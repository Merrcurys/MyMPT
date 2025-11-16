import 'dart:async';
import 'package:my_mpt/domain/entities/schedule.dart';
import '../models/schedule_response.dart';

class ScheduleApiService {
  static const int _networkDelay = 500;

  Future<ScheduleResponse> getScheduleData() async {
    await Future.delayed(Duration(milliseconds: _networkDelay));
    return ScheduleResponse.fromJson({});
  }

  Future<List<Schedule>> getTodaySchedule() async {
    await Future.delayed(Duration(milliseconds: _networkDelay));
    return _getMockTodaySchedule();
  }

  Future<Map<String, List<Schedule>>> getWeeklySchedule() async {
    await Future.delayed(Duration(milliseconds: _networkDelay));
    return _getMockWeeklySchedule();
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

  static Map<String, List<Schedule>> _getMockWeeklySchedule() {
    return {
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
}