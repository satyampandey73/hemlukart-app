class DoctorScheduleItem {
  final String? id;
  final String? doctorId;
  final String? clinicId;
  final String dayOfWeek;
  final String sessionName;
  final String startTime;
  final String endTime;
  final int slotDuration;
  final String consultationType;
  final num consultationFee;
  final bool isAvailable;
  final String? createdAt;
  final String? updatedAt;

  DoctorScheduleItem({
    this.id,
    this.doctorId,
    this.clinicId,
    required this.dayOfWeek,
    required this.sessionName,
    required this.startTime,
    required this.endTime,
    this.slotDuration = 30,
    this.consultationType = 'video',
    this.consultationFee = 500,
    this.isAvailable = true,
    this.createdAt,
    this.updatedAt,
  });

  DoctorScheduleItem copyWith({
    String? id,
    String? doctorId,
    String? clinicId,
    String? dayOfWeek,
    String? sessionName,
    String? startTime,
    String? endTime,
    int? slotDuration,
    String? consultationType,
    num? consultationFee,
    bool? isAvailable,
    String? createdAt,
    String? updatedAt,
  }) {
    return DoctorScheduleItem(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      clinicId: clinicId ?? this.clinicId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      sessionName: sessionName ?? this.sessionName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      slotDuration: slotDuration ?? this.slotDuration,
      consultationType: consultationType ?? this.consultationType,
      consultationFee: consultationFee ?? this.consultationFee,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory DoctorScheduleItem.fromJson(Map<String, dynamic> json) {
    return DoctorScheduleItem(
      id: (json['id'] ?? json['_id'])?.toString(),
      doctorId: json['doctorId']?.toString(),
      clinicId: json['clinicId']?.toString(),
      dayOfWeek: (json['dayOfWeek'] ?? json['day'] ?? 'monday').toString().toLowerCase(),
      sessionName: (json['sessionName'] ?? json['session'] ?? 'morning').toString().toLowerCase(),
      startTime: (json['startTime'] ?? json['start'] ?? '09:00').toString(),
      endTime: (json['endTime'] ?? json['end'] ?? '13:00').toString(),
      slotDuration: json['slotDuration'] is int
          ? json['slotDuration'] as int
          : int.tryParse(json['slotDuration']?.toString() ?? '30') ?? 30,
      consultationType: (json['consultationType'] ?? json['type'] ?? 'video').toString(),
      consultationFee: json['consultationFee'] is num
          ? json['consultationFee'] as num
          : num.tryParse(json['consultationFee']?.toString() ?? '500') ?? 500,
      isAvailable: json['isAvailable'] is bool
          ? json['isAvailable'] as bool
          : (json['isAvailable']?.toString().toLowerCase() != 'false'),
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'dayOfWeek': dayOfWeek.toLowerCase(),
      'sessionName': sessionName.toLowerCase(),
      'startTime': startTime,
      'endTime': endTime,
      'slotDuration': slotDuration,
      'consultationType': consultationType,
      'consultationFee': consultationFee,
      'isAvailable': isAvailable,
    };
    if (clinicId != null && clinicId!.isNotEmpty) {
      data['clinicId'] = clinicId;
    }
    if (id != null && id!.isNotEmpty) {
      data['id'] = id;
    }
    return data;
  }
}

class DoctorSchedulesApiResponse {
  final bool success;
  final String message;
  final List<DoctorScheduleItem> schedules;

  DoctorSchedulesApiResponse({
    required this.success,
    this.message = '',
    required this.schedules,
  });

  factory DoctorSchedulesApiResponse.fromJson(Map<String, dynamic> json) {
    List<DoctorScheduleItem> items = [];
    final rawList = json['schedules'] ?? json['data'] ?? json['schedule'];
    if (rawList is List) {
      items = rawList
          .whereType<Map<String, dynamic>>()
          .map((e) => DoctorScheduleItem.fromJson(e))
          .toList();
    } else if (rawList is Map<String, dynamic>) {
      // If it's a map keyed by days
      rawList.forEach((key, val) {
        if (val is List) {
          for (var item in val) {
            if (item is Map<String, dynamic>) {
              items.add(DoctorScheduleItem.fromJson({
                ...item,
                'dayOfWeek': item['dayOfWeek'] ?? key,
              }));
            }
          }
        }
      });
    }

    return DoctorSchedulesApiResponse(
      success: json['success'] ?? true,
      message: json['message']?.toString() ?? '',
      schedules: items,
    );
  }

  Map<String, List<DoctorScheduleItem>> get groupedByDay {
    final Map<String, List<DoctorScheduleItem>> map = {
      'monday': [],
      'tuesday': [],
      'wednesday': [],
      'thursday': [],
      'friday': [],
      'saturday': [],
      'sunday': [],
    };

    for (var s in schedules) {
      final key = s.dayOfWeek.toLowerCase();
      if (!map.containsKey(key)) {
        map[key] = [];
      }
      map[key]!.add(s);
    }
    return map;
  }
}

class DoctorScheduleMutationResponse {
  final bool success;
  final String message;
  final List<DoctorScheduleItem> schedules;

  DoctorScheduleMutationResponse({
    required this.success,
    this.message = '',
    this.schedules = const [],
  });

  factory DoctorScheduleMutationResponse.fromJson(Map<String, dynamic> json) {
    List<DoctorScheduleItem> items = [];
    final rawList = json['schedules'] ?? json['data'];
    if (rawList is List) {
      items = rawList
          .whereType<Map<String, dynamic>>()
          .map((e) => DoctorScheduleItem.fromJson(e))
          .toList();
    }

    return DoctorScheduleMutationResponse(
      success: json['success'] ?? false,
      message: json['message']?.toString() ?? '',
      schedules: items,
    );
  }
}
