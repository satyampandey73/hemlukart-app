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
  final String? profilePhoto;
  final String? prescription;
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
    this.profilePhoto,
    this.prescription,
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
      profilePhoto: json['profilePhoto'] as String?,
      prescription: (json['prescription'] ) as String?,
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
      'profilePhoto': profilePhoto,
      'prescription': prescription,
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

class DoctorGraduationDetails {
  final int? yearOfPassing;
  final String? universityName;

  DoctorGraduationDetails({
    this.yearOfPassing,
    this.universityName,
  });

  factory DoctorGraduationDetails.fromJson(Map<String, dynamic> json) {
    int? parsedYear;
    if (json['yearOfPassing'] != null) {
      parsedYear = int.tryParse(json['yearOfPassing'].toString());
    }
    return DoctorGraduationDetails(
      yearOfPassing: parsedYear,
      universityName: json['universityName']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'yearOfPassing': yearOfPassing,
      'universityName': universityName,
    };
  }
}

class DoctorHighestQualification {
  final String? degree;
  final int? yearOfPassing;
  final String? specialization;
  final String? universityName;

  DoctorHighestQualification({
    this.degree,
    this.yearOfPassing,
    this.specialization,
    this.universityName,
  });

  factory DoctorHighestQualification.fromJson(Map<String, dynamic> json) {
    int? parsedYear;
    if (json['yearOfPassing'] != null) {
      parsedYear = int.tryParse(json['yearOfPassing'].toString());
    }
    return DoctorHighestQualification(
      degree: json['degree']?.toString(),
      yearOfPassing: parsedYear,
      specialization: json['specialization']?.toString(),
      universityName: json['universityName']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'degree': degree,
      'yearOfPassing': yearOfPassing,
      'specialization': specialization,
      'universityName': universityName,
    };
  }
}

class DoctorExpertise {
  final List<String>? areasOfExpertise;
  final List<String>? consultationLanguages;

  DoctorExpertise({
    this.areasOfExpertise,
    this.consultationLanguages,
  });

  factory DoctorExpertise.fromJson(Map<String, dynamic> json) {
    return DoctorExpertise(
      areasOfExpertise: (json['areasOfExpertise'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      consultationLanguages: (json['consultationLanguages'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'areasOfExpertise': areasOfExpertise,
      'consultationLanguages': consultationLanguages,
    };
  }
}

class DoctorBankDetails {
  final String? bankName;
  final String? ifscCode;
  final String? panNumber;
  final String? accountNumber;
  final String? accountHolderName;

  DoctorBankDetails({
    this.bankName,
    this.ifscCode,
    this.panNumber,
    this.accountNumber,
    this.accountHolderName,
  });

  factory DoctorBankDetails.fromJson(Map<String, dynamic> json) {
    return DoctorBankDetails(
      bankName: json['bankName']?.toString(),
      ifscCode: json['ifscCode']?.toString(),
      panNumber: json['panNumber']?.toString(),
      accountNumber: json['accountNumber']?.toString(),
      accountHolderName: json['accountHolderName']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bankName': bankName,
      'ifscCode': ifscCode,
      'panNumber': panNumber,
      'accountNumber': accountNumber,
      'accountHolderName': accountHolderName,
    };
  }
}

class DoctorConsent {
  final String? consentGivenAt;
  final bool? informationCorrect;
  final bool? validAyushRegistration;
  final bool? agreedTermsAndConditions;
  final bool? digitalVerificationConsent;
  final bool? agreedTelemedicineGuidelines;

  DoctorConsent({
    this.consentGivenAt,
    this.informationCorrect,
    this.validAyushRegistration,
    this.agreedTermsAndConditions,
    this.digitalVerificationConsent,
    this.agreedTelemedicineGuidelines,
  });

  factory DoctorConsent.fromJson(Map<String, dynamic> json) {
    return DoctorConsent(
      consentGivenAt: json['consentGivenAt']?.toString(),
      informationCorrect: json['informationCorrect'] as bool?,
      validAyushRegistration: json['validAyushRegistration'] as bool?,
      agreedTermsAndConditions: json['agreedTermsAndConditions'] as bool?,
      digitalVerificationConsent: json['digitalVerificationConsent'] as bool?,
      agreedTelemedicineGuidelines: json['agreedTelemedicineGuidelines'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'consentGivenAt': consentGivenAt,
      'informationCorrect': informationCorrect,
      'validAyushRegistration': validAyushRegistration,
      'agreedTermsAndConditions': agreedTermsAndConditions,
      'digitalVerificationConsent': digitalVerificationConsent,
      'agreedTelemedicineGuidelines': agreedTelemedicineGuidelines,
    };
  }
}

class DoctorSchedule {
  final String id;
  final String doctorId;
  final String? clinicId;
  final String dayOfWeek;
  final String sessionName;
  final String startTime;
  final String endTime;
  final int slotDuration;
  final bool isAvailable;
  final String consultationType;
  final String consultationFee;
  final String? createdAt;
  final String? updatedAt;

  DoctorSchedule({
    required this.id,
    required this.doctorId,
    this.clinicId,
    required this.dayOfWeek,
    required this.sessionName,
    required this.startTime,
    required this.endTime,
    required this.slotDuration,
    required this.isAvailable,
    required this.consultationType,
    required this.consultationFee,
    this.createdAt,
    this.updatedAt,
  });

  factory DoctorSchedule.fromJson(Map<String, dynamic> json) {
    int parsedDuration = 30;
    if (json['slotDuration'] != null) {
      parsedDuration = int.tryParse(json['slotDuration'].toString()) ?? 30;
    }

    return DoctorSchedule(
      id: json['id']?.toString() ?? '',
      doctorId: json['doctorId']?.toString() ?? '',
      clinicId: json['clinicId']?.toString(),
      dayOfWeek: json['dayOfWeek']?.toString() ?? '',
      sessionName: json['sessionName']?.toString() ?? '',
      startTime: json['startTime']?.toString() ?? '',
      endTime: json['endTime']?.toString() ?? '',
      slotDuration: parsedDuration,
      isAvailable: json['isAvailable'] as bool? ?? true,
      consultationType: json['consultationType']?.toString() ?? '',
      consultationFee: json['consultationFee']?.toString() ?? '0.00',
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'doctorId': doctorId,
      'clinicId': clinicId,
      'dayOfWeek': dayOfWeek,
      'sessionName': sessionName,
      'startTime': startTime,
      'endTime': endTime,
      'slotDuration': slotDuration,
      'isAvailable': isAvailable,
      'consultationType': consultationType,
      'consultationFee': consultationFee,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

class DoctorConsultationFee {
  final String consultationType;
  final String fee;

  DoctorConsultationFee({
    required this.consultationType,
    required this.fee,
  });

  factory DoctorConsultationFee.fromJson(Map<String, dynamic> json) {
    return DoctorConsultationFee(
      consultationType: json['consultationType']?.toString() ??
          json['type']?.toString() ??
          json['mode']?.toString() ??
          '',
      fee: json['fee']?.toString() ??
          json['consultationFee']?.toString() ??
          json['amount']?.toString() ??
          json['price']?.toString() ??
          '0.00',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'consultationType': consultationType,
      'fee': fee,
    };
  }
}

class ApiDoctor {
  final String id;
  final String? mobile;
  final bool? isMobileVerified;
  final String fullName;
  final String? gender;
  final String? dateOfBirth;
  final String? email;
  final String? address;
  final String? city;
  final String? state;
  final String? pinCode;
  final String? ayushSystem;
  final DoctorGraduationDetails? graduationDetails;
  final String? registrationNumber;
  final String? stateAyushCouncil;
  final DoctorHighestQualification? highestQualification;
  final int? totalExperience;
  final String? currentClinicOrHospital;
  final String? currentDesignation;
  final DoctorExpertise? expertise;
  final String? about;
  final String? consultationPhilosophy;
  final String? achievements;
  final DoctorBankDetails? bankDetails;
  final DoctorDocumentsData? documents;
  final DoctorConsent? consent;
  final String? registrationStatus;
  final String? rejectionReason;
  final bool? isActive;
  final bool? isDeleted;
  final String? deletedAt;
  final String? lastLoginAt;
  final String? createdBy;
  final String? createdAt;
  final String? updatedAt;
  final String? createdByName;
  final String? createdByRole;
  final List<DoctorSchedule>? schedules;
  final List<DoctorConsultationFee>? consultationFees;

  ApiDoctor({
    required this.id,
    this.mobile,
    this.isMobileVerified,
    required this.fullName,
    this.gender,
    this.dateOfBirth,
    this.email,
    this.address,
    this.city,
    this.state,
    this.pinCode,
    this.ayushSystem,
    this.graduationDetails,
    this.registrationNumber,
    this.stateAyushCouncil,
    this.highestQualification,
    this.totalExperience,
    this.currentClinicOrHospital,
    this.currentDesignation,
    this.expertise,
    this.about,
    this.consultationPhilosophy,
    this.achievements,
    this.bankDetails,
    this.documents,
    this.consent,
    this.registrationStatus,
    this.rejectionReason,
    this.isActive,
    this.isDeleted,
    this.deletedAt,
    this.lastLoginAt,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.createdByName,
    this.createdByRole,
    this.schedules,
    this.consultationFees,
  });

  factory ApiDoctor.fromJson(Map<String, dynamic> json) {
    int? parsedExp;
    if (json['totalExperience'] != null) {
      parsedExp = int.tryParse(json['totalExperience'].toString());
    }

    return ApiDoctor(
      id: json['id']?.toString() ?? '',
      mobile: json['mobile']?.toString(),
      isMobileVerified: json['isMobileVerified'] as bool?,
      fullName: json['fullName']?.toString() ?? 'Dr. Unknown',
      gender: json['gender']?.toString(),
      dateOfBirth: json['dateOfBirth']?.toString(),
      email: json['email']?.toString(),
      address: json['address']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      pinCode: json['pinCode']?.toString(),
      ayushSystem: json['ayushSystem']?.toString(),
      graduationDetails: json['graduationDetails'] != null &&
              json['graduationDetails'] is Map<String, dynamic>
          ? DoctorGraduationDetails.fromJson(
              json['graduationDetails'] as Map<String, dynamic>)
          : null,
      registrationNumber: json['registrationNumber']?.toString(),
      stateAyushCouncil: json['stateAyushCouncil']?.toString(),
      highestQualification: json['highestQualification'] != null &&
              json['highestQualification'] is Map<String, dynamic>
          ? DoctorHighestQualification.fromJson(
              json['highestQualification'] as Map<String, dynamic>)
          : null,
      totalExperience: parsedExp,
      currentClinicOrHospital: json['currentClinicOrHospital']?.toString(),
      currentDesignation: json['currentDesignation']?.toString(),
      expertise: json['expertise'] != null &&
              json['expertise'] is Map<String, dynamic>
          ? DoctorExpertise.fromJson(
              json['expertise'] as Map<String, dynamic>)
          : null,
      about: json['about']?.toString(),
      consultationPhilosophy: json['consultationPhilosophy']?.toString(),
      achievements: json['achievements']?.toString(),
      bankDetails: json['bankDetails'] != null &&
              json['bankDetails'] is Map<String, dynamic>
          ? DoctorBankDetails.fromJson(
              json['bankDetails'] as Map<String, dynamic>)
          : null,
      documents: json['documents'] != null &&
              json['documents'] is Map<String, dynamic>
          ? DoctorDocumentsData.fromJson(
              json['documents'] as Map<String, dynamic>)
          : null,
      consent: json['consent'] != null &&
              json['consent'] is Map<String, dynamic>
          ? DoctorConsent.fromJson(
              json['consent'] as Map<String, dynamic>)
          : null,
      registrationStatus: json['registrationStatus']?.toString() ?? json['status']?.toString(),
      rejectionReason: json['rejectionReason']?.toString(),
      isActive: json['isActive'] as bool?,
      isDeleted: json['isDeleted'] as bool?,
      deletedAt: json['deletedAt']?.toString(),
      lastLoginAt: json['lastLoginAt']?.toString(),
      createdBy: json['createdBy']?.toString(),
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
      createdByName: json['createdByName']?.toString(),
      createdByRole: json['createdByRole']?.toString(),
      schedules: json['schedules'] != null && json['schedules'] is List
          ? (json['schedules'] as List)
              .map((e) => DoctorSchedule.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      consultationFees: json['consultationFees'] != null && json['consultationFees'] is List
          ? (json['consultationFees'] as List)
              .map((e) => DoctorConsultationFee.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }
}

class DoctorsListApiResponse {
  final bool success;
  final List<ApiDoctor> doctors;
  final Map<String, dynamic>? pagination;
  final String message;

  DoctorsListApiResponse({
    required this.success,
    required this.doctors,
    this.pagination,
    this.message = '',
  });

  factory DoctorsListApiResponse.fromJson(Map<String, dynamic> json) {
    return DoctorsListApiResponse(
      success: json['success'] ?? false,
      doctors: json['doctors'] != null && json['doctors'] is List
          ? (json['doctors'] as List)
              .map((e) => ApiDoctor.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      pagination: json['pagination'] as Map<String, dynamic>?,
      message: json['message']?.toString() ?? '',
    );
  }
}

class SingleDoctorApiResponse {
  final bool success;
  final ApiDoctor? doctor;
  final String message;

  SingleDoctorApiResponse({
    required this.success,
    this.doctor,
    this.message = '',
  });

  factory SingleDoctorApiResponse.fromJson(Map<String, dynamic> json) {
    return SingleDoctorApiResponse(
      success: json['success'] ?? false,
      doctor: json['doctor'] != null && json['doctor'] is Map<String, dynamic>
          ? ApiDoctor.fromJson(json['doctor'] as Map<String, dynamic>)
          : null,
      message: json['message']?.toString() ?? '',
    );
  }
}
