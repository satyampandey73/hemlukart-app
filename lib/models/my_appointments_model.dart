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
  final String? appointmentTime;
  final String? clinicName;

  UserAppointmentItem({
    required this.id,
    this.clinicId,
    required this.appointmentDate,
    this.appointmentTime,
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
      appointmentTime: (json['appointmentTime'] ?? json['time'] ?? json['slotTime'] ?? json['startTime'])?.toString(),
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
      'appointmentTime': appointmentTime,
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

  /// Universal IST date & time formatter
  static String formatDateTimeInIst({required String? dateStr, String? timeStr}) {
    if ((dateStr == null || dateStr.trim().isEmpty) && (timeStr == null || timeStr.trim().isEmpty)) {
      return '';
    }

    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    // 1. Resolve Time if provided directly
    String? formattedTime;
    if (timeStr != null && timeStr.trim().isNotEmpty) {
      final t = timeStr.trim();
      final isPm = t.toUpperCase().contains('PM');
      final isAm = t.toUpperCase().contains('AM');
      final digitsAndColon = t.replaceAll(RegExp(r'[^\d:]'), '');
      final parts = digitsAndColon.split(':');
      if (parts.isNotEmpty) {
        int h = int.tryParse(parts[0]) ?? 0;
        int m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
        if (isPm && h < 12) h += 12;
        if (isAm && h == 12) h = 0;
        final period = h >= 12 ? 'PM' : 'AM';
        final displayH = (h % 12 == 0) ? 12 : (h % 12);
        formattedTime = '${displayH.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $period';
      }
    }

    // 2. Resolve Date & fallback time from dateStr if timeStr is not provided
    if (dateStr == null || dateStr.trim().isEmpty) {
      return formattedTime ?? '';
    }

    final d = dateStr.trim();

    // Check if d is ISO timestamp with T
    if (d.contains('T')) {
      try {
        final parsed = DateTime.parse(d);
        // If UTC, convert to IST
        final ist = parsed.isUtc ? parsed.add(const Duration(hours: 5, minutes: 30)) : parsed;
        final day = ist.day;
        final month = months[ist.month - 1];
        final year = ist.year;

        if (formattedTime == null) {
          final h = ist.hour;
          final m = ist.minute.toString().padLeft(2, '0');
          final period = h >= 12 ? 'PM' : 'AM';
          final displayH = (h % 12 == 0) ? 12 : (h % 12);
          if (h == 0 && m == '00') {
            return '$day $month $year';
          }
          formattedTime = '${displayH.toString().padLeft(2, '0')}:$m $period';
        }

        return '$day $month $year at $formattedTime';
      } catch (_) {}
    }

    // Check if d is YYYY-MM-DD
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(d)) {
      final parts = d.split('-');
      final year = parts[0];
      final monthIndex = (int.tryParse(parts[1]) ?? 1) - 1;
      final month = (monthIndex >= 0 && monthIndex < 12) ? months[monthIndex] : parts[1];
      final day = int.tryParse(parts[2])?.toString() ?? parts[2];

      if (formattedTime != null) {
        return '$day $month $year at $formattedTime';
      }
      return '$day $month $year';
    }

    // Check if d is DD-MM-YYYY or DD/MM/YYYY
    if (RegExp(r'^\d{2}[-/]\d{2}[-/]\d{4}$').hasMatch(d)) {
      final sep = d.contains('/') ? '/' : '-';
      final parts = d.split(sep);
      final day = int.tryParse(parts[0])?.toString() ?? parts[0];
      final monthIndex = (int.tryParse(parts[1]) ?? 1) - 1;
      final month = (monthIndex >= 0 && monthIndex < 12) ? months[monthIndex] : parts[1];
      final year = parts[2];

      if (formattedTime != null) {
        return '$day $month $year at $formattedTime';
      }
      return '$day $month $year';
    }

    // Fallback: try DateTime.parse
    try {
      final parsed = DateTime.parse(d);
      final ist = parsed.isUtc ? parsed.add(const Duration(hours: 5, minutes: 30)) : parsed;
      final day = ist.day;
      final month = months[ist.month - 1];
      final year = ist.year;
      if (formattedTime != null) {
        return '$day $month $year at $formattedTime';
      }
      return '$day $month $year';
    } catch (_) {
      return formattedTime != null ? '$d at $formattedTime' : d;
    }
  }

  /// Helper to format date & time for UI display in IST
  String get formattedDateTime {
    return formatDateTimeInIst(dateStr: appointmentDate, timeStr: appointmentTime);
  }

  /// Returns only the formatted time (e.g. "02:05 PM")
  String get formattedTimeOnly {
    if (appointmentTime != null && appointmentTime!.trim().isNotEmpty) {
      final t = appointmentTime!.trim();
      final isPm = t.toUpperCase().contains('PM');
      final isAm = t.toUpperCase().contains('AM');
      final digitsAndColon = t.replaceAll(RegExp(r'[^\d:]'), '');
      final parts = digitsAndColon.split(':');
      if (parts.isNotEmpty) {
        int h = int.tryParse(parts[0]) ?? 0;
        int m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
        if (isPm && h < 12) h += 12;
        if (isAm && h == 12) h = 0;
        final period = h >= 12 ? 'PM' : 'AM';
        final displayH = (h % 12 == 0) ? 12 : (h % 12);
        return '${displayH.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $period';
      }
    }
    if (appointmentDate.contains('T')) {
      try {
        final parsed = DateTime.parse(appointmentDate);
        final ist = parsed.isUtc ? parsed.add(const Duration(hours: 5, minutes: 30)) : parsed;
        final h = ist.hour;
        final m = ist.minute.toString().padLeft(2, '0');
        final period = h >= 12 ? 'PM' : 'AM';
        final displayH = (h % 12 == 0) ? 12 : (h % 12);
        return '${displayH.toString().padLeft(2, '0')}:$m $period';
      } catch (_) {}
    }
    return '';
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

  /// Whether this appointment represents an online or video consultation
  bool get isVideoConsultation {
    final t = consultationType.toLowerCase().trim();
    return t == 'video' ||
        t == 'video_call' ||
        t == 'online' ||
        t == 'telehealth' ||
        t == 'telemedicine' ||
        t.contains('video') ||
        t.contains('online') ||
        t.contains('tele');
  }

  /// Helper to check whether scheduled consultation time + duration has passed in IST
  static bool checkMeetingTimeExpired({
    required String appointmentDate,
    String? appointmentTime,
    int durationMinutes = 30,
  }) {
    try {
      int year = 0, month = 1, day = 1;
      final d = appointmentDate.trim();
      final dateMatch = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})').firstMatch(d);
      if (dateMatch != null) {
        year = int.parse(dateMatch.group(1)!);
        month = int.parse(dateMatch.group(2)!);
        day = int.parse(dateMatch.group(3)!);
      } else {
        final parsed = DateTime.tryParse(d);
        if (parsed != null) {
          final ist = parsed.isUtc ? parsed.add(const Duration(hours: 5, minutes: 30)) : parsed;
          year = ist.year;
          month = ist.month;
          day = ist.day;
        }
      }

      if (year == 0) return false;

      int hour = 0, minute = 0;
      if (appointmentTime != null && appointmentTime.trim().isNotEmpty) {
        final t = appointmentTime.trim();
        final isPm = t.toUpperCase().contains('PM');
        final isAm = t.toUpperCase().contains('AM');
        final digitsAndColon = t.replaceAll(RegExp(r'[^\d:]'), '');
        final parts = digitsAndColon.split(':');
        if (parts.isNotEmpty) {
          hour = int.tryParse(parts[0]) ?? 0;
          minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
          if (isPm && hour < 12) hour += 12;
          if (isAm && hour == 12) hour = 0;
        }
      } else if (d.contains('T')) {
        final parsed = DateTime.tryParse(d);
        if (parsed != null) {
          final ist = parsed.isUtc ? parsed.add(const Duration(hours: 5, minutes: 30)) : parsed;
          hour = ist.hour;
          minute = ist.minute;
        }
      }

      final startDt = DateTime(year, month, day, hour, minute);
      final duration = durationMinutes > 0 ? durationMinutes : 30;
      final endDt = startDt.add(Duration(minutes: duration));

      final nowUtc = DateTime.now().toUtc();
      final nowIst = nowUtc.add(const Duration(hours: 5, minutes: 30));

      return nowIst.isAfter(endDt);
    } catch (_) {
      return false;
    }
  }

  /// Whether the scheduled consultation time has expired
  bool get isMeetingTimeExpired {
    return checkMeetingTimeExpired(
      appointmentDate: appointmentDate,
      appointmentTime: appointmentTime,
      durationMinutes: durationMinutes,
    );
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
  final String? appointmentTime;
  final String? clinicName;
  final String? userId;
  final String? userName;
  final String? userMobile;

  AppointmentDetailModel({
    required this.id,
    this.clinicId,
    required this.appointmentDate,
    this.appointmentTime,
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
      appointmentTime: (json['appointmentTime'] ?? json['time'] ?? json['slotTime'] ?? json['startTime'])?.toString(),
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
      'appointmentTime': appointmentTime,
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

  /// Helper to format date & time for UI display in IST
  String get formattedDateTime {
    return UserAppointmentItem.formatDateTimeInIst(dateStr: appointmentDate, timeStr: appointmentTime);
  }

  /// Returns only the formatted time (e.g. "02:05 PM")
  String get formattedTimeOnly {
    if (appointmentTime != null && appointmentTime!.trim().isNotEmpty) {
      final t = appointmentTime!.trim();
      final isPm = t.toUpperCase().contains('PM');
      final isAm = t.toUpperCase().contains('AM');
      final digitsAndColon = t.replaceAll(RegExp(r'[^\d:]'), '');
      final parts = digitsAndColon.split(':');
      if (parts.isNotEmpty) {
        int h = int.tryParse(parts[0]) ?? 0;
        int m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
        if (isPm && h < 12) h += 12;
        if (isAm && h == 12) h = 0;
        final period = h >= 12 ? 'PM' : 'AM';
        final displayH = (h % 12 == 0) ? 12 : (h % 12);
        return '${displayH.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $period';
      }
    }
    if (appointmentDate.contains('T')) {
      try {
        final parsed = DateTime.parse(appointmentDate);
        final ist = parsed.isUtc ? parsed.add(const Duration(hours: 5, minutes: 30)) : parsed;
        final h = ist.hour;
        final m = ist.minute.toString().padLeft(2, '0');
        final period = h >= 12 ? 'PM' : 'AM';
        final displayH = (h % 12 == 0) ? 12 : (h % 12);
        return '${displayH.toString().padLeft(2, '0')}:$m $period';
      } catch (_) {}
    }
    return '';
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

  /// Whether this appointment represents an online or video consultation
  bool get isVideoConsultation {
    final t = consultationType.toLowerCase().trim();
    return t == 'video' ||
        t == 'video_call' ||
        t == 'online' ||
        t == 'telehealth' ||
        t == 'telemedicine' ||
        t.contains('video') ||
        t.contains('online') ||
        t.contains('tele');
  }

  /// Whether the scheduled consultation time has expired
  bool get isMeetingTimeExpired {
    return UserAppointmentItem.checkMeetingTimeExpired(
      appointmentDate: appointmentDate,
      appointmentTime: appointmentTime,
      durationMinutes: durationMinutes,
    );
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
