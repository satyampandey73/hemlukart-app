import 'package:flutter_test/flutter_test.dart';
import 'package:hemlukart_app/services/appointment_service.dart';
import 'package:hemlukart_app/models/my_appointments_model.dart';

void main() {
  group('Reschedule Appointment Time & Date Tests', () {
    test('parseAppointmentDate parses ISO, YYYY-MM-DD and DD-MM-YYYY correctly', () {
      final d1 = AppointmentService.parseAppointmentDate('2026-10-04');
      expect(d1.year, 2026);
      expect(d1.month, 10);
      expect(d1.day, 4);

      final d2 = AppointmentService.parseAppointmentDate('2026-10-04T07:45:00.000Z');
      expect(d2.year, 2026);
      expect(d2.month, 10);
      expect(d2.day, 4);

      final d3 = AppointmentService.parseAppointmentDate('04-10-2026');
      expect(d3.year, 2026);
      expect(d3.month, 10);
      expect(d3.day, 4);
    });

    test('parseAppointmentHourMinute auto-fills meeting time 1:10 PM correctly', () {
      final t1 = AppointmentService.parseAppointmentHourMinute(timeStr: '1:10 PM');
      expect(t1.hour, 13);
      expect(t1.minute, 10);

      final t2 = AppointmentService.parseAppointmentHourMinute(timeStr: '01:10 PM');
      expect(t2.hour, 13);
      expect(t2.minute, 10);

      final t3 = AppointmentService.parseAppointmentHourMinute(timeStr: '13:10');
      expect(t3.hour, 13);
      expect(t3.minute, 10);

      final t4 = AppointmentService.parseAppointmentHourMinute(
        timeStr: null,
        dateStr: '2026-10-04T07:40:00.000Z',
      );
      // 07:40 UTC in IST (+5:30) is 13:10 (1:10 PM)
      expect(t4.hour, 13);
      expect(t4.minute, 10);
    });

    test('formatIstToUtcIso correctly converts 1:15 PM IST to UTC without double-offset (no 6:45 PM bug)', () {
      final date = DateTime(2026, 10, 4);
      // Doctor selects 1:15 PM (13:15 IST)
      const hour = 13;
      const minute = 15;

      final utcIso = AppointmentService.formatIstToUtcIso(
        date: date,
        hour: hour,
        minute: minute,
      );

      // In UTC, 13:15 IST minus 5:30 is 07:45 UTC
      expect(utcIso, '2026-10-04T07:45:00.000Z');

      // When fetched from backend and formatted in IST, it should display 01:15 PM, NOT 06:45 PM!
      final formatted = UserAppointmentItem.formatDateTimeInIst(dateStr: utcIso);
      expect(formatted, contains('01:15 PM'));
      expect(formatted, isNot(contains('06:45 PM')));
    });

    test('formatDateTimeInIst preserves 1:15 PM when appointmentTime is provided', () {
      final formatted = UserAppointmentItem.formatDateTimeInIst(
        dateStr: '2026-10-04T07:45:00.000Z',
        timeStr: '01:15 PM',
      );
      expect(formatted, contains('01:15 PM'));
      expect(formatted, isNot(contains('06:45 PM')));
    });
  });
}
