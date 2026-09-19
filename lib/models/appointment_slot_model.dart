class AppointmentSlot {
  final String time;
  final bool available;

  AppointmentSlot({
    required this.time,
    required this.available,
  });

  factory AppointmentSlot.fromJson(Map<String, dynamic> json) {
    return AppointmentSlot(
      time: json['time'] as String? ?? '',
      available: json['available'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time,
      'available': available,
    };
  }

  /// Formats ISO 8601 string (e.g. "2026-08-01T09:30:00.000Z") to readable time string (e.g. "09:30 AM")
  String get displayTime {
    if (time.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(time).toUtc();
      final hour = dateTime.hour;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final formattedHour = (hour % 12 == 0) ? 12 : (hour % 12);
      return '${formattedHour.toString().padLeft(2, '0')}:$minute $period';
    } catch (_) {
      return time;
    }
  }

  /// Categorizes slot into Morning, Afternoon, or Evening
  String get periodCategory {
    if (time.isEmpty) return 'Morning';
    try {
      final dateTime = DateTime.parse(time).toUtc();
      if (dateTime.hour < 12) {
        return 'Morning';
      } else if (dateTime.hour < 17) {
        return 'Afternoon';
      } else {
        return 'Evening';
      }
    } catch (_) {
      return 'Morning';
    }
  }
}

class AppointmentSlotDoctor {
  final String id;
  final String fullName;

  AppointmentSlotDoctor({
    required this.id,
    required this.fullName,
  });

  factory AppointmentSlotDoctor.fromJson(Map<String, dynamic> json) {
    return AppointmentSlotDoctor(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
    };
  }
}

class AppointmentSlotsApiResponse {
  final bool success;
  final String date;
  final AppointmentSlotDoctor? doctor;
  final List<AppointmentSlot> slots;
  final String? message;

  AppointmentSlotsApiResponse({
    required this.success,
    required this.date,
    this.doctor,
    required this.slots,
    this.message,
  });

  factory AppointmentSlotsApiResponse.fromJson(Map<String, dynamic> json) {
    List<AppointmentSlot> slotsList = [];
    if (json['slots'] != null && json['slots'] is List) {
      slotsList = (json['slots'] as List)
          .map((item) => AppointmentSlot.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return AppointmentSlotsApiResponse(
      success: json['success'] as bool? ?? false,
      date: json['date'] as String? ?? '',
      doctor: json['doctor'] != null && json['doctor'] is Map<String, dynamic>
          ? AppointmentSlotDoctor.fromJson(json['doctor'] as Map<String, dynamic>)
          : null,
      slots: slotsList,
      message: json['message'] as String?,
    );
  }
}
