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
    Map<String, dynamic> data;
    if (json['videoCall'] is Map<String, dynamic>) {
      data = json['videoCall'] as Map<String, dynamic>;
    } else if (json['data'] is Map<String, dynamic>) {
      final inner = json['data'] as Map<String, dynamic>;
      if (inner['videoCall'] is Map<String, dynamic>) {
        data = inner['videoCall'] as Map<String, dynamic>;
      } else if (inner['call'] is Map<String, dynamic>) {
        data = inner['call'] as Map<String, dynamic>;
      } else {
        data = inner;
      }
    } else if (json['call'] is Map<String, dynamic>) {
      data = json['call'] as Map<String, dynamic>;
    } else if (json['activeCall'] is Map<String, dynamic>) {
      data = json['activeCall'] as Map<String, dynamic>;
    } else {
      data = json;
    }

    return VideoCallSessionModel(
      id: data['id']?.toString() ?? data['_id']?.toString() ?? '',
      appointmentId: data['appointmentId']?.toString() ?? data['roomId']?.toString() ?? '',
      doctorId: data['doctorId']?.toString(),
      userId: data['userId']?.toString() ?? data['patientId']?.toString(),
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
    } else if (json['call'] != null && json['call'] is Map<String, dynamic>) {
      call = VideoCallSessionModel.fromJson(json['call'] as Map<String, dynamic>);
    } else if (json['id'] != null || json['_id'] != null) {
      call = VideoCallSessionModel.fromJson(json);
    }

    return StartVideoCallResponse(
      success: json['success'] as bool? ?? (json['status'] == 'success') ?? (call != null),
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
    } else if (json['call'] != null && json['call'] is Map<String, dynamic>) {
      call = VideoCallSessionModel.fromJson(json['call'] as Map<String, dynamic>);
    } else if (json['activeCall'] != null && json['activeCall'] is Map<String, dynamic>) {
      call = VideoCallSessionModel.fromJson(json['activeCall'] as Map<String, dynamic>);
    } else if (json['id'] != null || json['_id'] != null) {
      call = VideoCallSessionModel.fromJson(json);
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
