class DoctorSendOtpResponse {
  final bool success;
  final String message;
  final String? otp;

  DoctorSendOtpResponse({
    required this.success,
    required this.message,
    this.otp,
  });

  factory DoctorSendOtpResponse.fromJson(Map<String, dynamic> json) {
    return DoctorSendOtpResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      otp: json['otp']?.toString(),
    );
  }
}

class DoctorVerifyOtpResponse {
  final bool success;
  final String message;
  final String? token;
  final Map<String, dynamic>? doctor;

  DoctorVerifyOtpResponse({
    required this.success,
    required this.message,
    this.token,
    this.doctor,
  });

  factory DoctorVerifyOtpResponse.fromJson(Map<String, dynamic> json) {
    return DoctorVerifyOtpResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      token: json['token'] as String?,
      doctor: json['doctor'] as Map<String, dynamic>?,
    );
  }
}

class DoctorApiResponse {
  final bool success;
  final String message;
  final Map<String, dynamic>? doctor;

  DoctorApiResponse({
    required this.success,
    required this.message,
    this.doctor,
  });

  factory DoctorApiResponse.fromJson(Map<String, dynamic> json) {
    return DoctorApiResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      doctor: json['doctor'] as Map<String, dynamic>?,
    );
  }
}

class DoctorConsentResponse {
  final bool success;
  final String message;
  final String? registrationStatus;

  DoctorConsentResponse({
    required this.success,
    required this.message,
    this.registrationStatus,
  });

  factory DoctorConsentResponse.fromJson(Map<String, dynamic> json) {
    return DoctorConsentResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      registrationStatus: json['registrationStatus'] as String?,
    );
  }
}

class DoctorDocumentsData {
  final String? panCard;
  final String? aadhaarBack;
  final String? aadhaarFront;
  final String? aadhaarNumber;
  final String? panCardNumber;
  final String? cancelledCheque;
  final List<String>? degreeCertificates;
  final String? degreeUniversityNumber;
  final String? registrationCertificate;
  final String? medicalRegistrationNumber;

  DoctorDocumentsData({
    this.panCard,
    this.aadhaarBack,
    this.aadhaarFront,
    this.aadhaarNumber,
    this.panCardNumber,
    this.cancelledCheque,
    this.degreeCertificates,
    this.degreeUniversityNumber,
    this.registrationCertificate,
    this.medicalRegistrationNumber,
  });

  factory DoctorDocumentsData.fromJson(Map<String, dynamic> json) {
    return DoctorDocumentsData(
      panCard: json['panCard'] as String?,
      aadhaarBack: json['aadhaarBack'] as String?,
      aadhaarFront: json['aadhaarFront'] as String?,
      aadhaarNumber: json['aadhaarNumber'] as String?,
      panCardNumber: json['panCardNumber'] as String?,
      cancelledCheque: json['cancelledCheque'] as String?,
      degreeCertificates: (json['degreeCertificates'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      degreeUniversityNumber: json['degreeUniversityNumber'] as String?,
      registrationCertificate: json['registrationCertificate'] as String?,
      medicalRegistrationNumber: json['medicalRegistrationNumber'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'panCard': panCard,
      'aadhaarBack': aadhaarBack,
      'aadhaarFront': aadhaarFront,
      'aadhaarNumber': aadhaarNumber,
      'panCardNumber': panCardNumber,
      'cancelledCheque': cancelledCheque,
      'degreeCertificates': degreeCertificates,
      'degreeUniversityNumber': degreeUniversityNumber,
      'registrationCertificate': registrationCertificate,
      'medicalRegistrationNumber': medicalRegistrationNumber,
    };
  }
}

class DoctorDocumentsResponse {
  final bool success;
  final String message;
  final DoctorDocumentsData? documents;

  DoctorDocumentsResponse({
    required this.success,
    required this.message,
    this.documents,
  });

  factory DoctorDocumentsResponse.fromJson(Map<String, dynamic> json) {
    return DoctorDocumentsResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      documents: json['documents'] != null && json['documents'] is Map<String, dynamic>
          ? DoctorDocumentsData.fromJson(json['documents'] as Map<String, dynamic>)
          : null,
    );
  }
}

