import 'package:flutter_test/flutter_test.dart';
import 'package:hemlukart_app/models/doctor_model.dart';

void main() {
  test('DoctorDocumentsResponse JSON deserialization matches API schema', () {
    final apiJson = {
      "success": true,
      "message": "Documents uploaded successfully",
      "documents": {
        "panCard": "https://res.cloudinary.com/dubhfgcd6/image/upload/v1785234503/doctors/documents/hi1kxyeagraecf8bdtru.png",
        "aadhaarBack": "https://res.cloudinary.com/dubhfgcd6/image/upload/v1785234503/doctors/documents/m2larh7coyn0l03slgdh.png",
        "aadhaarFront": "https://res.cloudinary.com/dubhfgcd6/image/upload/v1785234501/doctors/documents/xldy5rfy4m93wkowtzn3.png",
        "aadhaarNumber": "123456789012",
        "panCardNumber": "ABCDE1234F",
        "cancelledCheque": "https://res.cloudinary.com/dubhfgcd6/image/upload/v1785234503/doctors/documents/i5hxk3xfqftcuitroscf.png",
        "degreeCertificates": [
          "https://res.cloudinary.com/dubhfgcd6/image/upload/v1785234498/doctors/documents/mkzfqmhiij2iqz3mip5c.png"
        ],
        "degreeUniversityNumber": "UNI12345",
        "registrationCertificate": "https://res.cloudinary.com/dubhfgcd6/image/upload/v1785314888/doctors/documents/xgxdfaubrh9obl71fgfc.png",
        "medicalRegistrationNumber": "MCI123456789"
      }
    };

    final response = DoctorDocumentsResponse.fromJson(apiJson);

    expect(response.success, isTrue);
    expect(response.message, equals("Documents uploaded successfully"));
    expect(response.documents, isNotNull);
    expect(response.documents!.aadhaarNumber, equals("123456789012"));
    expect(response.documents!.panCardNumber, equals("ABCDE1234F"));
    expect(response.documents!.medicalRegistrationNumber, equals("MCI123456789"));
    expect(response.documents!.degreeUniversityNumber, equals("UNI12345"));
    expect(response.documents!.degreeCertificates, hasLength(1));
    expect(
      response.documents!.degreeCertificates!.first,
      equals("https://res.cloudinary.com/dubhfgcd6/image/upload/v1785234498/doctors/documents/mkzfqmhiij2iqz3mip5c.png"),
    );
  });
}
