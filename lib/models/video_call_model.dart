class VideoCallSessionModel {
  final String id;
  final String appointmentId;
  final String? doctorId;
  final String? userId;
  final String status;
  final String? startedAt;
  final String? endedAt;

  VideoCallSessionModel({
    required this.id,
    required this.appointmentId,
    this.doctorId,
    this.userId,
    required this.status,
    this.startedAt,
    this.endedAt,
  });

  factory VideoCallSessionModel.fromJson(Map<String, dynamic> json) {
    final data = json['videoCall'] is Map<String, dynamic>
        ? json['videoCall'] as Map<String, dynamic>
        : (json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : json);

    return VideoCallSessionModel(
      id: data['id']?.toString() ?? data['_id']?.toString() ?? '',
      appointmentId: data['appointmentId']?.toString() ?? '',
      doctorId: data['doctorId']?.toString(),
      userId: data['userId']?.toString(),
      status: data['status']?.toString() ?? 'active',
      startedAt: data['startedAt']?.toString(),
      endedAt: data['endedAt']?.toString(),
    );
  }
}

class StartVideoCallResponse {
  final bool success;
  final String? message;
  final VideoCallSessionModel? videoCall;

  StartVideoCallResponse({
    required this.success,
    this.message,
    this.videoCall,
  });

  factory StartVideoCallResponse.fromJson(Map<String, dynamic> json) {
    VideoCallSessionModel? call;
    if (json['videoCall'] != null && json['videoCall'] is Map<String, dynamic>) {
      call = VideoCallSessionModel.fromJson(json['videoCall'] as Map<String, dynamic>);
    } else if (json['data'] != null && json['data'] is Map<String, dynamic>) {
      call = VideoCallSessionModel.fromJson(json['data'] as Map<String, dynamic>);
    }

    return StartVideoCallResponse(
      success: json['success'] as bool? ?? (json['status'] == 'success'),
      message: json['message'] as String?,
      videoCall: call,
    );
  }
}

class ActiveVideoCallResponse {
  final bool success;
  final bool exists;
  final String? message;
  final VideoCallSessionModel? videoCall;

  ActiveVideoCallResponse({
    required this.success,
    required this.exists,
    this.message,
    this.videoCall,
  });

  factory ActiveVideoCallResponse.fromJson(Map<String, dynamic> json) {
    VideoCallSessionModel? call;
    if (json['videoCall'] != null && json['videoCall'] is Map<String, dynamic>) {
      call = VideoCallSessionModel.fromJson(json['videoCall'] as Map<String, dynamic>);
    } else if (json['data'] != null && json['data'] is Map<String, dynamic>) {
      call = VideoCallSessionModel.fromJson(json['data'] as Map<String, dynamic>);
    }

    final bool hasCall = call != null || json['exists'] == true || json['isActive'] == true;

    return ActiveVideoCallResponse(
      success: json['success'] as bool? ?? hasCall,
      exists: hasCall,
      message: json['message'] as String?,
      videoCall: call,
    );
  }
}
