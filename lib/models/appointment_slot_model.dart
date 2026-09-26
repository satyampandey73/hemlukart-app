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

  /// Formats time string (e.g. "19:01", "07:01 PM", or ISO) to readable IST time string (e.g. "07:01 PM")
  String get displayTime {
    if (time.isEmpty) return '';
    try {
      if (time.contains('T')) {
        final dt = DateTime.parse(time);
        final ist = dt.isUtc ? dt.add(const Duration(hours: 5, minutes: 30)) : dt;
        final hour = ist.hour;
        final minute = ist.minute.toString().padLeft(2, '0');
        final period = hour >= 12 ? 'PM' : 'AM';
        final formattedHour = (hour % 12 == 0) ? 12 : (hour % 12);
        return '${formattedHour.toString().padLeft(2, '0')}:$minute $period';
      }

      final isPm = time.toUpperCase().contains('PM');
      final isAm = time.toUpperCase().contains('AM');
      final digitsAndColon = time.replaceAll(RegExp(r'[^\d:]'), '');
      final parts = digitsAndColon.split(':');

      if (parts.isNotEmpty) {
        int h = int.tryParse(parts[0]) ?? 9;
        int m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
        if (isPm && h < 12) {
          h += 12;
        } else if (isAm && h == 12) {
          h = 0;
        }
        final period = h >= 12 ? 'PM' : 'AM';
        final formattedHour = (h % 12 == 0) ? 12 : (h % 12);
        return '${formattedHour.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $period';
      }
    } catch (_) {}
    return time;
  }

  /// Categorizes slot into Morning, Afternoon, or Evening (IST)
  String get periodCategory {
    if (time.isEmpty) return 'Morning';
    try {
      int hour = 9;
      if (time.contains('T')) {
        final dt = DateTime.parse(time);
        final ist = dt.isUtc ? dt.add(const Duration(hours: 5, minutes: 30)) : dt;
        hour = ist.hour;
      } else {
        final isPm = time.toUpperCase().contains('PM');
        final isAm = time.toUpperCase().contains('AM');
        final digitsAndColon = time.replaceAll(RegExp(r'[^\d:]'), '');
        final parts = digitsAndColon.split(':');
        if (parts.isNotEmpty) {
          hour = int.tryParse(parts[0]) ?? 9;
          if (isPm && hour < 12) hour += 12;
          if (isAm && hour == 12) hour = 0;
        }
      }

      if (hour < 12) {
        return 'Morning';
      } else if (hour < 17) {
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
