class BookedAppointment {
  final String id;
  final String? userId;
  final String? doctorId;
  final String? clinicId;
  final String? appointmentDate;
  final String? appointmentTime;
  final int? durationMinutes;
  final String? consultationType;
  final String? patientName;
  final String? patientMobile;
  final int? patientAge;
  final String? symptoms;
  final String? notes;
  final String? status;
  final String? cancelReason;
  final String? rescheduledFrom;
  final String? rescheduledAt;
  final String? consultationFee;
  final String? paymentStatus;
  final String? paymentId;
  final String? bookedAt;
  final String? confirmedAt;
  final String? completedAt;
  final String? cancelledAt;
  final String? createdAt;
  final String? updatedAt;

  BookedAppointment({
    required this.id,
    this.userId,
    this.doctorId,
    this.clinicId,
    this.appointmentDate,
    this.appointmentTime,
    this.durationMinutes,
    this.consultationType,
    this.patientName,
    this.patientMobile,
    this.patientAge,
    this.symptoms,
    this.notes,
    this.status,
    this.cancelReason,
    this.rescheduledFrom,
    this.rescheduledAt,
    this.consultationFee,
    this.paymentStatus,
    this.paymentId,
    this.bookedAt,
    this.confirmedAt,
    this.completedAt,
    this.cancelledAt,
    this.createdAt,
    this.updatedAt,
  });

  factory BookedAppointment.fromJson(Map<String, dynamic> json) {
    return BookedAppointment(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String?,
      doctorId: json['doctorId'] as String?,
      clinicId: json['clinicId'] as String?,
      appointmentDate: json['appointmentDate'] as String?,
      appointmentTime: (json['appointmentTime'] ?? json['time'] ?? json['slotTime'] ?? json['startTime'])?.toString(),
      durationMinutes: json['durationMinutes'] is int
          ? json['durationMinutes'] as int
          : int.tryParse(json['durationMinutes']?.toString() ?? ''),
      consultationType: json['consultationType'] as String?,
      patientName: json['patientName'] as String?,
      patientMobile: json['patientMobile'] as String?,
      patientAge: json['patientAge'] is int
          ? json['patientAge'] as int
          : int.tryParse(json['patientAge']?.toString() ?? ''),
      symptoms: json['symptoms'] as String?,
      notes: json['notes'] as String?,
      status: json['status'] as String?,
      cancelReason: json['cancelReason'] as String?,
      rescheduledFrom: json['rescheduledFrom'] as String?,
      rescheduledAt: json['rescheduledAt'] as String?,
      consultationFee: json['consultationFee']?.toString(),
      paymentStatus: json['paymentStatus'] as String?,
      paymentId: json['paymentId'] as String?,
      bookedAt: json['bookedAt'] as String?,
      confirmedAt: json['confirmedAt'] as String?,
      completedAt: json['completedAt'] as String?,
      cancelledAt: json['cancelledAt'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'doctorId': doctorId,
      'clinicId': clinicId,
      'appointmentDate': appointmentDate,
      'durationMinutes': durationMinutes,
      'consultationType': consultationType,
      'patientName': patientName,
      'patientMobile': patientMobile,
      'patientAge': patientAge,
      'symptoms': symptoms,
      'notes': notes,
      'status': status,
      'cancelReason': cancelReason,
      'rescheduledFrom': rescheduledFrom,
      'rescheduledAt': rescheduledAt,
      'consultationFee': consultationFee,
      'paymentStatus': paymentStatus,
      'paymentId': paymentId,
      'bookedAt': bookedAt,
      'confirmedAt': confirmedAt,
      'completedAt': completedAt,
      'cancelledAt': cancelledAt,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

class BookAppointmentApiResponse {
  final bool success;
  final String message;
  final BookedAppointment? appointment;

  BookAppointmentApiResponse({
    required this.success,
    required this.message,
    this.appointment,
  });

  factory BookAppointmentApiResponse.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? aptMap;
    if (json['appointment'] is Map<String, dynamic>) {
      aptMap = json['appointment'] as Map<String, dynamic>;
    } else if (json['data'] is Map<String, dynamic>) {
      final d = json['data'] as Map<String, dynamic>;
      if (d['appointment'] is Map<String, dynamic>) {
        aptMap = d['appointment'] as Map<String, dynamic>;
      } else {
        aptMap = d;
      }
    }

    return BookAppointmentApiResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      appointment: aptMap != null ? BookedAppointment.fromJson(aptMap) : null,
    );
  }
}

class AppointmentPaymentDetails {
  final String keyId;
  final String orderId;
  final num amount;
  final String currency;

  AppointmentPaymentDetails({
    required this.keyId,
    required this.orderId,
    required this.amount,
    required this.currency,
  });

  factory AppointmentPaymentDetails.fromJson(Map<String, dynamic> json) {
    return AppointmentPaymentDetails(
      keyId: json['keyId']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      amount: json['amount'] is num
          ? json['amount'] as num
          : num.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      currency: json['currency']?.toString() ?? 'INR',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'keyId': keyId,
      'orderId': orderId,
      'amount': amount,
      'currency': currency,
    };
  }
}

class InitiateAppointmentPaymentApiResponse {
  final bool success;
  final String message;
  final BookedAppointment? appointment;
  final AppointmentPaymentDetails? payment;

  InitiateAppointmentPaymentApiResponse({
    required this.success,
    required this.message,
    this.appointment,
    this.payment,
  });

  factory InitiateAppointmentPaymentApiResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : null;
    final aptMap = (data?['appointment'] is Map<String, dynamic>)
        ? data!['appointment'] as Map<String, dynamic>
        : (json['appointment'] is Map<String, dynamic> ? json['appointment'] as Map<String, dynamic> : null);
    final payMap = (data?['payment'] is Map<String, dynamic>)
        ? data!['payment'] as Map<String, dynamic>
        : (json['payment'] is Map<String, dynamic> ? json['payment'] as Map<String, dynamic> : null);

    return InitiateAppointmentPaymentApiResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      appointment: aptMap != null ? BookedAppointment.fromJson(aptMap) : null,
      payment: payMap != null ? AppointmentPaymentDetails.fromJson(payMap) : null,
    );
  }
}

class VerifyAppointmentPaymentApiResponse {
  final bool success;
  final String message;
  final BookedAppointment? appointment;

  VerifyAppointmentPaymentApiResponse({
    required this.success,
    required this.message,
    this.appointment,
  });

  factory VerifyAppointmentPaymentApiResponse.fromJson(Map<String, dynamic> json) {
    final aptMap = (json['appointment'] is Map<String, dynamic>)
        ? json['appointment'] as Map<String, dynamic>
        : (json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : null);

    return VerifyAppointmentPaymentApiResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      appointment: aptMap != null ? BookedAppointment.fromJson(aptMap) : null,
    );
  }
}
