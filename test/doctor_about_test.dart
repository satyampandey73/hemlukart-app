import 'package:flutter_test/flutter_test.dart';
import 'package:hemlukart_app/models/doctor_model.dart';

void main() {
  test('DoctorApiResponse deserializes step 6 about response correctly', () {
    final responseJson = {
      "success": true,
      "message": "Professional profile updated successfully",
      "doctor": {
        "id": "2a156bac-3992-4003-9877-201adda5173a"
      }
    };

    final response = DoctorApiResponse.fromJson(responseJson);

    expect(response.success, isTrue);
    expect(response.message, equals("Professional profile updated successfully"));
    expect(response.doctor, isNotNull);
    expect(response.doctor!['id'], equals("2a156bac-3992-4003-9877-201adda5173a"));
  });
}
