class BookedAppointment {
  final String id;
  final String? userId;
  final String? doctorId;
  final String? clinicId;
  final String? appointmentDate;
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
    return BookAppointmentApiResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      appointment: json['appointment'] != null && json['appointment'] is Map<String, dynamic>
          ? BookedAppointment.fromJson(json['appointment'] as Map<String, dynamic>)
          : null,
    );
  }
}
