class DoctorPhotos {
  final String? panCard;
  final String? aadhaarBack;
  final String? aadhaarFront;
  final String? profilePhoto;
  final String? cancelledCheque;
  final List<String>? degreeCertificates;
  final String? registrationCertificate;
  final String? aadhaarNumber;
  final String? panCardNumber;
  final String? degreeUniversityNumber;
  final String? medicalRegistrationNumber;

  DoctorPhotos({
    this.panCard,
    this.aadhaarBack,
    this.aadhaarFront,
    this.profilePhoto,
    this.cancelledCheque,
    this.degreeCertificates,
    this.registrationCertificate,
    this.aadhaarNumber,
    this.panCardNumber,
    this.degreeUniversityNumber,
    this.medicalRegistrationNumber,
  });

  factory DoctorPhotos.fromJson(Map<String, dynamic> json) {
    List<String>? degrees;
    if (json['degreeCertificates'] != null && json['degreeCertificates'] is List) {
      degrees = (json['degreeCertificates'] as List).map((e) => e.toString()).toList();
    }

    return DoctorPhotos(
      panCard: json['panCard'] as String?,
      aadhaarBack: json['aadhaarBack'] as String?,
      aadhaarFront: json['aadhaarFront'] as String?,
      profilePhoto: json['profilePhoto'] as String?,
      cancelledCheque: json['cancelledCheque'] as String?,
      degreeCertificates: degrees,
      registrationCertificate: json['registrationCertificate'] as String?,
      aadhaarNumber: json['aadhaarNumber'] as String?,
      panCardNumber: json['panCardNumber'] as String?,
      degreeUniversityNumber: json['degreeUniversityNumber'] as String?,
      medicalRegistrationNumber: json['medicalRegistrationNumber'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'panCard': panCard,
      'aadhaarBack': aadhaarBack,
      'aadhaarFront': aadhaarFront,
      'profilePhoto': profilePhoto,
      'cancelledCheque': cancelledCheque,
      'degreeCertificates': degreeCertificates,
      'registrationCertificate': registrationCertificate,
      'aadhaarNumber': aadhaarNumber,
      'panCardNumber': panCardNumber,
      'degreeUniversityNumber': degreeUniversityNumber,
      'medicalRegistrationNumber': medicalRegistrationNumber,
    };
  }
}

class UserAppointmentItem {
  final String id;
  final String? clinicId;
  final String appointmentDate;
  final int durationMinutes;
  final String consultationType;
  final String status;
  final String paymentStatus;
  final String consultationFee;
  final String patientName;
  final String? symptoms;
  final String? patientMobile;
  final int? patientAge;
  final String? userId;
  final String? userEmail;
  final String? cancelReason;
  final String? bookedAt;
  final String? doctorId;
  final String? doctorName;
  final String? doctorSpecialty;
  final DoctorPhotos? doctorPhoto;
  final String? clinicName;

  UserAppointmentItem({
    required this.id,
    this.clinicId,
    required this.appointmentDate,
    required this.durationMinutes,
    required this.consultationType,
    required this.status,
    required this.paymentStatus,
    required this.consultationFee,
    required this.patientName,
    this.patientMobile,
    this.patientAge,
    this.userId,
    this.userEmail,
    this.symptoms,
    this.cancelReason,
    this.bookedAt,
    this.doctorId,
    this.doctorName,
    this.doctorSpecialty,
    this.doctorPhoto,
    this.clinicName,
  });

  factory UserAppointmentItem.fromJson(Map<String, dynamic> json) {
    return UserAppointmentItem(
      id: json['id'] as String? ?? '',
      clinicId: json['clinicId'] as String?,
      appointmentDate: json['appointmentDate'] as String? ?? '',
      durationMinutes: json['durationMinutes'] is int
          ? json['durationMinutes'] as int
          : int.tryParse(json['durationMinutes']?.toString() ?? '') ?? 30,
      consultationType: json['consultationType'] as String? ?? 'in_person',
      status: json['status'] as String? ?? 'pending',
      paymentStatus: json['paymentStatus'] as String? ?? 'pending',
      consultationFee: json['consultationFee']?.toString() ?? '0.00',
      patientName: json['patientName'] as String? ?? '',
      patientMobile: json['patientMobile'] as String?,
      patientAge: json['patientAge'] is int
          ? json['patientAge'] as int
          : int.tryParse(json['patientAge']?.toString() ?? ''),
      userId: json['userId'] as String?,
      userEmail: json['userEmail'] as String?,
      symptoms: json['symptoms'] as String?,
      cancelReason: json['cancelReason'] as String?,
      bookedAt: json['bookedAt'] as String?,
      doctorId: json['doctorId'] as String?,
      doctorName: json['doctorName'] as String?,
      doctorSpecialty: json['doctorSpecialty'] as String?,
      doctorPhoto: json['doctorPhoto'] != null && json['doctorPhoto'] is Map<String, dynamic>
          ? DoctorPhotos.fromJson(json['doctorPhoto'] as Map<String, dynamic>)
          : null,
      clinicName: json['clinicName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clinicId': clinicId,
      'appointmentDate': appointmentDate,
      'durationMinutes': durationMinutes,
      'consultationType': consultationType,
      'status': status,
      'paymentStatus': paymentStatus,
      'consultationFee': consultationFee,
      'patientName': patientName,
      'patientMobile': patientMobile,
      'patientAge': patientAge,
      'userId': userId,
      'userEmail': userEmail,
      'symptoms': symptoms,
      'cancelReason': cancelReason,
      'bookedAt': bookedAt,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'doctorSpecialty': doctorSpecialty,
      'doctorPhoto': doctorPhoto?.toJson(),
      'clinicName': clinicName,
    };
  }

  /// Helper to format date & time for UI display
  String get formattedDateTime {
    if (appointmentDate.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(appointmentDate).toUtc();
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final hour = dateTime.hour;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final formattedHour = (hour % 12 == 0) ? 12 : (hour % 12);

      if (hour == 0 && minute == '00' && !appointmentDate.contains('T')) {
        return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
      }

      return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year} at ${formattedHour.toString().padLeft(2, '0')}:$minute $period';
    } catch (_) {
      return appointmentDate;
    }
  }

  /// Helper to format bookedAt timestamp to IST (UTC+5:30)
  String get formattedBookedAt {
    if (bookedAt == null || bookedAt!.isEmpty) return '';
    try {
      DateTime dt = DateTime.parse(bookedAt!);
      if (dt.isUtc) {
        dt = dt.add(const Duration(hours: 5, minutes: 30));
      } else {
        dt = dt.toUtc().add(const Duration(hours: 5, minutes: 30));
      }
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final hour = dt.hour;
      final min = dt.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final formattedHour = (hour % 12 == 0) ? 12 : (hour % 12);
      return '${dt.day} ${months[dt.month - 1]} ${dt.year} at ${formattedHour.toString().padLeft(2, '0')}:$min $period IST';
    } catch (_) {
      return bookedAt!;
    }
  }

  /// Helper getter for doctor's profile picture
  String get displayDoctorPhoto {
    if (doctorPhoto?.profilePhoto != null && doctorPhoto!.profilePhoto!.isNotEmpty) {
      return doctorPhoto!.profilePhoto!;
    }
    if (doctorPhoto?.registrationCertificate != null && doctorPhoto!.registrationCertificate!.isNotEmpty) {
      return doctorPhoto!.registrationCertificate!;
    }
    if (doctorPhoto?.degreeCertificates != null && doctorPhoto!.degreeCertificates!.isNotEmpty) {
      return doctorPhoto!.degreeCertificates!.first;
    }
    return '';
  }
}

class AppointmentDetailModel {
  final String id;
  final String? clinicId;
  final String appointmentDate;
  final int durationMinutes;
  final String consultationType;
  final String status;
  final String paymentStatus;
  final String consultationFee;
  final String patientName;
  final String? patientMobile;
  final int? patientAge;
  final String? symptoms;
  final String? notes;
  final String? cancelReason;
  final String? paymentId;
  final String? bookedAt;
  final String? confirmedAt;
  final String? completedAt;
  final String? cancelledAt;
  final String? doctorId;
  final String? doctorName;
  final String? doctorMobile;
  final String? doctorEmail;
  final String? doctorSpecialty;
  final DoctorPhotos? doctorDocuments;
  final String? clinicName;
  final String? userId;
  final String? userName;
  final String? userMobile;

  AppointmentDetailModel({
    required this.id,
    this.clinicId,
    required this.appointmentDate,
    required this.durationMinutes,
    required this.consultationType,
    required this.status,
    required this.paymentStatus,
    required this.consultationFee,
    required this.patientName,
    this.patientMobile,
    this.patientAge,
    this.symptoms,
    this.notes,
    this.cancelReason,
    this.paymentId,
    this.bookedAt,
    this.confirmedAt,
    this.completedAt,
    this.cancelledAt,
    this.doctorId,
    this.doctorName,
    this.doctorMobile,
    this.doctorEmail,
    this.doctorSpecialty,
    this.doctorDocuments,
    this.clinicName,
    this.userId,
    this.userName,
    this.userMobile,
  });

  factory AppointmentDetailModel.fromJson(Map<String, dynamic> json) {
    DoctorPhotos? docs;
    if (json['doctorDocuments'] != null && json['doctorDocuments'] is Map<String, dynamic>) {
      docs = DoctorPhotos.fromJson(json['doctorDocuments'] as Map<String, dynamic>);
    } else if (json['doctorPhoto'] != null && json['doctorPhoto'] is Map<String, dynamic>) {
      docs = DoctorPhotos.fromJson(json['doctorPhoto'] as Map<String, dynamic>);
    }

    return AppointmentDetailModel(
      id: json['id'] as String? ?? '',
      clinicId: json['clinicId'] as String?,
      appointmentDate: json['appointmentDate'] as String? ?? '',
      durationMinutes: json['durationMinutes'] is int
          ? json['durationMinutes'] as int
          : int.tryParse(json['durationMinutes']?.toString() ?? '') ?? 30,
      consultationType: json['consultationType'] as String? ?? 'in_person',
      status: json['status'] as String? ?? 'pending',
      paymentStatus: json['paymentStatus'] as String? ?? 'pending',
      consultationFee: json['consultationFee']?.toString() ?? '0.00',
      patientName: json['patientName'] as String? ?? '',
      patientMobile: json['patientMobile'] as String?,
      patientAge: json['patientAge'] is int
          ? json['patientAge'] as int
          : int.tryParse(json['patientAge']?.toString() ?? ''),
      symptoms: json['symptoms'] as String?,
      notes: json['notes'] as String?,
      cancelReason: json['cancelReason'] as String?,
      paymentId: json['paymentId'] as String?,
      bookedAt: json['bookedAt'] as String?,
      confirmedAt: json['confirmedAt'] as String?,
      completedAt: json['completedAt'] as String?,
      cancelledAt: json['cancelledAt'] as String?,
      doctorId: json['doctorId'] as String?,
      doctorName: json['doctorName'] as String?,
      doctorMobile: json['doctorMobile'] as String?,
      doctorEmail: json['doctorEmail'] as String?,
      doctorSpecialty: json['doctorSpecialty'] as String?,
      doctorDocuments: docs,
      clinicName: json['clinicName'] as String?,
      userId: json['userId'] as String?,
      userName: json['userName'] as String?,
      userMobile: json['userMobile'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clinicId': clinicId,
      'appointmentDate': appointmentDate,
      'durationMinutes': durationMinutes,
      'consultationType': consultationType,
      'status': status,
      'paymentStatus': paymentStatus,
      'consultationFee': consultationFee,
      'patientName': patientName,
      'patientMobile': patientMobile,
      'patientAge': patientAge,
      'symptoms': symptoms,
      'notes': notes,
      'cancelReason': cancelReason,
      'paymentId': paymentId,
      'bookedAt': bookedAt,
      'confirmedAt': confirmedAt,
      'completedAt': completedAt,
      'cancelledAt': cancelledAt,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'doctorMobile': doctorMobile,
      'doctorEmail': doctorEmail,
      'doctorSpecialty': doctorSpecialty,
      'doctorDocuments': doctorDocuments?.toJson(),
      'clinicName': clinicName,
      'userId': userId,
      'userName': userName,
      'userMobile': userMobile,
    };
  }

  String get formattedDateTime {
    if (appointmentDate.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(appointmentDate).toUtc();
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final hour = dateTime.hour;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final formattedHour = (hour % 12 == 0) ? 12 : (hour % 12);

      if (hour == 0 && minute == '00' && !appointmentDate.contains('T')) {
        return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
      }

      return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year} at ${formattedHour.toString().padLeft(2, '0')}:$minute $period';
    } catch (_) {
      return appointmentDate;
    }
  }

  /// Helper to format bookedAt timestamp to IST (UTC+5:30)
  String get formattedBookedAt {
    if (bookedAt == null || bookedAt!.isEmpty) return '';
    try {
      DateTime dt = DateTime.parse(bookedAt!);
      if (dt.isUtc) {
        dt = dt.add(const Duration(hours: 5, minutes: 30));
      } else {
        dt = dt.toUtc().add(const Duration(hours: 5, minutes: 30));
      }
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final hour = dt.hour;
      final min = dt.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final formattedHour = (hour % 12 == 0) ? 12 : (hour % 12);
      return '${dt.day} ${months[dt.month - 1]} ${dt.year} at ${formattedHour.toString().padLeft(2, '0')}:$min $period IST';
    } catch (_) {
      return bookedAt!;
    }
  }

  String get displayDoctorPhoto {
    if (doctorDocuments?.profilePhoto != null && doctorDocuments!.profilePhoto!.isNotEmpty) {
      return doctorDocuments!.profilePhoto!;
    }
    if (doctorDocuments?.registrationCertificate != null && doctorDocuments!.registrationCertificate!.isNotEmpty) {
      return doctorDocuments!.registrationCertificate!;
    }
    if (doctorDocuments?.degreeCertificates != null && doctorDocuments!.degreeCertificates!.isNotEmpty) {
      return doctorDocuments!.degreeCertificates!.first;
    }
    return '';
  }
}

class SingleAppointmentApiResponse {
  final bool success;
  final AppointmentDetailModel? appointment;
  final String? message;

  SingleAppointmentApiResponse({
    required this.success,
    this.appointment,
    this.message,
  });

  factory SingleAppointmentApiResponse.fromJson(Map<String, dynamic> json) {
    return SingleAppointmentApiResponse(
      success: json['success'] as bool? ?? false,
      appointment: json['appointment'] != null && json['appointment'] is Map<String, dynamic>
          ? AppointmentDetailModel.fromJson(json['appointment'] as Map<String, dynamic>)
          : null,
      message: json['message'] as String?,
    );
  }
}

class AppointmentsPagination {
  final int total;
  final int page;
  final int pages;

  AppointmentsPagination({
    required this.total,
    required this.page,
    required this.pages,
  });

  factory AppointmentsPagination.fromJson(Map<String, dynamic> json) {
    return AppointmentsPagination(
      total: json['total'] is int ? json['total'] as int : int.tryParse(json['total']?.toString() ?? '') ?? 0,
      page: json['page'] is int ? json['page'] as int : int.tryParse(json['page']?.toString() ?? '') ?? 1,
      pages: json['pages'] is int ? json['pages'] as int : int.tryParse(json['pages']?.toString() ?? '') ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'page': page,
      'pages': pages,
    };
  }
}

class MyAppointmentsApiResponse {
  final bool success;
  final List<UserAppointmentItem> appointments;
  final AppointmentsPagination? pagination;
  final String? message;

  MyAppointmentsApiResponse({
    required this.success,
    required this.appointments,
    this.pagination,
    this.message,
  });

  factory MyAppointmentsApiResponse.fromJson(Map<String, dynamic> json) {
    List<UserAppointmentItem> list = [];
    if (json['appointments'] != null && json['appointments'] is List) {
      list = (json['appointments'] as List)
          .map((e) => UserAppointmentItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return MyAppointmentsApiResponse(
      success: json['success'] as bool? ?? false,
      appointments: list,
      pagination: json['pagination'] != null && json['pagination'] is Map<String, dynamic>
          ? AppointmentsPagination.fromJson(json['pagination'] as Map<String, dynamic>)
          : null,
      message: json['message'] as String?,
    );
  }
}
