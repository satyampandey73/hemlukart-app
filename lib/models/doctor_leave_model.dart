
class DoctorLeaveItem {
  final String id;
  final String? doctorId;
  final String? clinicId;
  final String date; // YYYY-MM-DD
  final String? startTime;
  final String? endTime;
  final bool isBlocked;
  final String? reason;
  final String? createdAt;
  final String? updatedAt;

  DoctorLeaveItem({
    required this.id,
    this.doctorId,
    this.clinicId,
    required this.date,
    this.startTime,
    this.endTime,
    this.isBlocked = true,
    this.reason,
    this.createdAt,
    this.updatedAt,
  });

  factory DoctorLeaveItem.fromJson(Map<String, dynamic> json) {
    return DoctorLeaveItem(
      id: json['id']?.toString() ?? '',
      doctorId: json['doctorId']?.toString(),
      clinicId: json['clinicId']?.toString(),
      date: json['date']?.toString() ?? '',
      startTime: json['startTime']?.toString(),
      endTime: json['endTime']?.toString(),
      isBlocked: json['isBlocked'] as bool? ?? true,
      reason: json['reason']?.toString(),
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (doctorId != null) 'doctorId': doctorId,
      if (clinicId != null) 'clinicId': clinicId,
      'date': date,
      if (startTime != null) 'startTime': startTime,
      if (endTime != null) 'endTime': endTime,
      'isBlocked': isBlocked,
      if (reason != null) 'reason': reason,
      if (createdAt != null) 'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
    };
  }

  DateTime? get parsedDate {
    try {
      if (date.contains('T')) {
        return DateTime.parse(date).toLocal();
      }
      return DateTime.parse(date);
    } catch (_) {
      return null;
    }
  }

  /// E.g. "03"
  String get dayNumber {
    final d = parsedDate;
    if (d != null) {
      return d.day.toString().padLeft(2, '0');
    }
    final parts = date.split('-');
    if (parts.length == 3) return parts[2];
    return date;
  }

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  static const List<String> _weekdays = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  ];

  /// E.g. "Oct 2026"
  String get monthYear {
    final d = parsedDate;
    if (d != null && d.month >= 1 && d.month <= 12) {
      return '${_months[d.month - 1]} ${d.year}';
    }
    return '';
  }

  /// E.g. "Sat, Oct 03, 2026"
  String get formattedFullDate {
    final d = parsedDate;
    if (d != null && d.month >= 1 && d.month <= 12 && d.weekday >= 1 && d.weekday <= 7) {
      final w = _weekdays[d.weekday - 1];
      final m = _months[d.month - 1];
      final dayStr = d.day.toString().padLeft(2, '0');
      return '$w, $m $dayStr, ${d.year}';
    }
    return date;
  }
}

class DoctorLeavesApiResponse {
  final bool success;
  final List<DoctorLeaveItem> data;
  final String? message;

  DoctorLeavesApiResponse({
    required this.success,
    required this.data,
    this.message,
  });

  factory DoctorLeavesApiResponse.fromJson(Map<String, dynamic> json) {
    List<DoctorLeaveItem> items = [];
    if (json['data'] != null && json['data'] is List) {
      items = (json['data'] as List)
          .map((e) => DoctorLeaveItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return DoctorLeavesApiResponse(
      success: json['success'] as bool? ?? false,
      data: items,
      message: json['message']?.toString(),
    );
  }
}

class DoctorCreateLeaveApiResponse {
  final bool success;
  final String? message;
  final List<DoctorLeaveItem> data;

  DoctorCreateLeaveApiResponse({
    required this.success,
    this.message,
    required this.data,
  });

  factory DoctorCreateLeaveApiResponse.fromJson(Map<String, dynamic> json) {
    List<DoctorLeaveItem> items = [];
    if (json['data'] != null && json['data'] is List) {
      items = (json['data'] as List)
          .map((e) => DoctorLeaveItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return DoctorCreateLeaveApiResponse(
      success: json['success'] as bool? ?? false,
      message: json['message']?.toString(),
      data: items,
    );
  }
}
