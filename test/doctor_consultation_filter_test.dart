import 'package:flutter_test/flutter_test.dart';
import 'package:hemlukart_app/constants/app_state.dart';
import 'package:hemlukart_app/models/doctor_model.dart';

void main() {
  group('Doctor Consultation Type Filter Tests', () {
    test('Doctor without video consultation schedules/fees should return hasOnline = false', () {
      final docJson = ApiDoctor.fromJson({
        "id": "1671eb66-538c-490d-b42f-72ea9d4b7406",
        "fullName": "Dr Ashish Bansal",
        "schedules": [],
        "consultationFees": []
      });

      final doctor = Doctor.fromApiDoctor(docJson);

      expect(doctor.hasOnline, isFalse);
      expect(doctor.hasInPerson, isTrue);
    });

    test('Doctor with only in_person consultation schedule/fees should return hasOnline = false', () {
      final docJson = ApiDoctor.fromJson({
        "id": "a78cb806-93db-46e2-b9ea-9fd8409ef29f",
        "fullName": "Mohd Soyeb",
        "schedules": [
          {
            "id": "7c0bfb5c-58d0-4f4f-9b8d-80d824a13573",
            "consultationType": "in_person",
            "consultationFee": "450.00"
          }
        ],
        "consultationFees": [
          {
            "consultationType": "in_person",
            "fee": "450.00"
          }
        ]
      });

      final doctor = Doctor.fromApiDoctor(docJson);

      expect(doctor.hasOnline, isFalse);
      expect(doctor.hasInPerson, isTrue);
    });

    test('Doctor with video consultation schedule/fees should return hasOnline = true', () {
      final docJson = ApiDoctor.fromJson({
        "id": "4fef2944-49aa-40eb-9bda-79415bf1c01f",
        "fullName": "sakshi singh",
        "schedules": [
          {
            "consultationType": "in_person",
            "consultationFee": "369.00"
          },
          {
            "consultationType": "video",
            "consultationFee": "500.00"
          }
        ],
        "consultationFees": [
          {
            "consultationType": "in_person",
            "fee": "369.00"
          },
          {
            "consultationType": "video",
            "fee": "500.00"
          }
        ]
      });

      final doctor = Doctor.fromApiDoctor(docJson);

      expect(doctor.hasOnline, isTrue);
      expect(doctor.hasInPerson, isTrue);
    });
  });
}
