import 'package:flutter_test/flutter_test.dart';
import 'package:hemlukart_app/models/doctor_leave_model.dart';
import 'package:hemlukart_app/models/doctor_model.dart';
import 'package:hemlukart_app/constants/app_state.dart';

void main() {
  group('Doctor Leave Models & Serialization Tests', () {
    test('DoctorCreateLeaveApiResponse parses user POST response accurately', () {
      final jsonResponse = {
        "success": true,
        "message": "Leave added for 1 day(s)",
        "data": [
          {
            "id": "96cebbc6-2324-46fc-8f87-410ee9bca557",
            "doctorId": "433e9bab-c7ca-49c0-be9b-2365e951c92b",
            "clinicId": null,
            "date": "2026-10-05",
            "startTime": null,
            "endTime": null,
            "isBlocked": true,
            "reason": "sjjkfs",
            "createdAt": "2026-10-05T05:47:30.731Z",
            "updatedAt": "2026-10-05T05:47:30.731Z"
          }
        ]
      };

      final parsed = DoctorCreateLeaveApiResponse.fromJson(jsonResponse);
      expect(parsed.success, isTrue);
      expect(parsed.message, equals('Leave added for 1 day(s)'));
      expect(parsed.data.length, equals(1));

      final leave = parsed.data.first;
      expect(leave.id, equals('96cebbc6-2324-46fc-8f87-410ee9bca557'));
      expect(leave.doctorId, equals('433e9bab-c7ca-49c0-be9b-2365e951c92b'));
      expect(leave.date, equals('2026-10-05'));
      expect(leave.reason, equals('sjjkfs'));
      expect(leave.isBlocked, isTrue);
      expect(leave.dayNumber, equals('05'));
      expect(leave.monthYear, equals('Oct 2026'));
      expect(leave.formattedFullDate, contains('Oct 05, 2026'));
    });

    test('DoctorLeavesApiResponse parses user GET response accurately', () {
      final jsonResponse = {
        "success": true,
        "data": [
          {
            "id": "88f1836c-9139-46c5-9e48-54a9540a32bb",
            "doctorId": "433e9bab-c7ca-49c0-be9b-2365e951c92b",
            "clinicId": null,
            "date": "2026-10-07",
            "startTime": null,
            "endTime": null,
            "isBlocked": true,
            "reason": "Family",
            "createdAt": "2026-10-03T12:28:06.274Z",
            "updatedAt": "2026-10-03T12:28:06.274Z"
          },
          {
            "id": "cdb83147-0498-4507-8d7e-62692ba8de7e",
            "doctorId": "433e9bab-c7ca-49c0-be9b-2365e951c92b",
            "clinicId": null,
            "date": "2026-10-06",
            "startTime": null,
            "endTime": null,
            "isBlocked": true,
            "reason": "Family",
            "createdAt": "2026-10-03T12:28:06.274Z",
            "updatedAt": "2026-10-03T12:28:06.274Z"
          }
        ]
      };

      final parsed = DoctorLeavesApiResponse.fromJson(jsonResponse);
      expect(parsed.success, isTrue);
      expect(parsed.data.length, equals(2));
      expect(parsed.data[0].date, equals('2026-10-07'));
      expect(parsed.data[0].reason, equals('Family'));
      expect(parsed.data[1].date, equals('2026-10-06'));
    });

    test('ApiDoctor parses upcomingLeaves correctly from GET /api/doctors/:doctorId', () {
      final docJson = {
        "id": "433e9bab-c7ca-49c0-be9b-2365e951c92b",
        "mobile": "9898989898",
        "fullName": "Rahul tomar",
        "upcomingLeaves": [
          {
            "id": "36ec2df9-f3a3-42a4-99ca-fe4de85f4534",
            "date": "2026-10-05",
            "reason": "Family"
          },
          {
            "id": "bf86d797-7e3d-410d-870a-ab0fd3690d88",
            "date": "2026-10-05",
            "reason": "fsdf"
          },
          {
            "id": "cdb83147-0498-4507-8d7e-62692ba8de7e",
            "date": "2026-10-06",
            "reason": "Family"
          }
        ]
      };

      final apiDoctor = ApiDoctor.fromJson(docJson);
      expect(apiDoctor.upcomingLeaves, isNotNull);
      expect(apiDoctor.upcomingLeaves!.length, equals(3));
      expect(apiDoctor.upcomingLeaves![0].date, equals('2026-10-05'));
      expect(apiDoctor.upcomingLeaves![0].reason, equals('Family'));

      // Test Doctor wrapper and getLeaveForDate helper
      final doctor = Doctor.fromApiDoctor(apiDoctor);
      expect(doctor.upcomingLeaves.length, equals(3));

      final leaveOnOct5 = doctor.getLeaveForDate(DateTime(2026, 10, 5));
      expect(leaveOnOct5, isNotNull);
      expect(leaveOnOct5!.reason, equals('Family'));

      final leaveOnOct6 = doctor.getLeaveForDate(DateTime(2026, 10, 6));
      expect(leaveOnOct6, isNotNull);
      expect(leaveOnOct6!.reason, equals('Family'));

      final leaveOnOct8 = doctor.getLeaveForDate(DateTime(2026, 10, 8));
      expect(leaveOnOct8, isNull);
    });
  });
}
