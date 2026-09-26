class ChatMessageModel {
  final String id;
  final String appointmentId;
  final String senderId;
  final String senderType; // 'doctor' or 'user'
  final String message;
  final bool isRead;
  final String createdAt;

  final String? fileUrl;
  final String? fileType;
  final String? fileName;
  final int? fileSize;

  ChatMessageModel({
    required this.id,
    required this.appointmentId,
    required this.senderId,
    required this.senderType,
    required this.message,
    this.isRead = false,
    required this.createdAt,
    this.fileUrl,
    this.fileType,
    this.fileName,
    this.fileSize,
  });

  static bool _parseBool(dynamic val) {
    if (val == null) return false;
    if (val is bool) return val;
    if (val is String) {
      final s = val.trim().toLowerCase();
      return s == 'true' || s == '1' || s == 'yes';
    }
    if (val is num) return val == 1;
    return false;
  }

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    bool readVal = false;
    if (json['isRead'] != null) {
      readVal = _parseBool(json['isRead']);
    } else if (json['read'] != null) {
      readVal = _parseBool(json['read']);
    }

    return ChatMessageModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      appointmentId: json['appointmentId']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? json['userId']?.toString() ?? json['doctorId']?.toString() ?? '',
      senderType: json['senderType']?.toString() ?? (json['role']?.toString() ?? 'user'),
      message: json['message']?.toString() ?? json['text']?.toString() ?? '',
      isRead: readVal,
      createdAt: json['createdAt']?.toString() ?? json['timestamp']?.toString() ?? DateTime.now().toIso8601String(),
      fileUrl: json['fileUrl']?.toString() ?? json['file']?.toString() ?? json['attachmentUrl']?.toString() ?? json['documentUrl']?.toString(),
      fileType: json['fileType']?.toString() ?? json['mimeType']?.toString(),
      fileName: json['fileName']?.toString() ?? json['originalName']?.toString(),
      fileSize: json['fileSize'] is int ? json['fileSize'] as int : int.tryParse(json['fileSize']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'appointmentId': appointmentId,
      'senderId': senderId,
      'senderType': senderType,
      'message': message,
      'isRead': isRead,
      'createdAt': createdAt,
      if (fileUrl != null) 'fileUrl': fileUrl,
      if (fileType != null) 'fileType': fileType,
      if (fileName != null) 'fileName': fileName,
      if (fileSize != null) 'fileSize': fileSize,
    };
  }

  String get formattedTime {
    if (createdAt.isEmpty) return '';
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      final hour = (dt.hour % 12 == 0) ? 12 : (dt.hour % 12);
      final min = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$min $period';
    } catch (_) {
      return createdAt;
    }
  }
}

class ChatThreadModel {
  final String appointmentId;
  final String? patientName;
  final String? doctorName;
  final String? lastMessage;
  final String? lastMessageAt;
  final int unreadCount;

  ChatThreadModel({
    required this.appointmentId,
    this.patientName,
    this.doctorName,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  factory ChatThreadModel.fromJson(Map<String, dynamic> json) {
    return ChatThreadModel(
      appointmentId: json['appointmentId']?.toString() ?? json['id']?.toString() ?? '',
      patientName: json['patientName']?.toString() ?? json['patient']?['fullName']?.toString() ?? json['user']?['fullName']?.toString(),
      doctorName: json['doctorName']?.toString() ?? json['doctor']?['fullName']?.toString(),
      lastMessage: json['lastMessage']?.toString() ?? json['latestMessage']?['message']?.toString(),
      lastMessageAt: json['lastMessageAt']?.toString() ?? json['updatedAt']?.toString(),
      unreadCount: json['unreadCount'] is int
          ? json['unreadCount'] as int
          : int.tryParse(json['unreadCount']?.toString() ?? '') ?? 0,
    );
  }
}

class ChatMessagesApiResponse {
  final bool success;
  final List<ChatMessageModel> messages;
  final String? message;

  ChatMessagesApiResponse({
    required this.success,
    required this.messages,
    this.message,
  });

  factory ChatMessagesApiResponse.fromJson(Map<String, dynamic> json) {
    List<ChatMessageModel> list = [];
    if (json['messages'] != null && json['messages'] is List) {
      list = (json['messages'] as List).map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>)).toList();
    } else if (json['data'] != null && json['data'] is List) {
      list = (json['data'] as List).map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return ChatMessagesApiResponse(
      success: ChatMessageModel._parseBool(json['success']),
      messages: list,
      message: json['message'] as String?,
    );
  }
}

class SendMessageApiResponse {
  final bool success;
  final ChatMessageModel? data;
  final String? message;

  SendMessageApiResponse({
    required this.success,
    this.data,
    this.message,
  });

  factory SendMessageApiResponse.fromJson(Map<String, dynamic> json) {
    ChatMessageModel? msg;
    if (json['data'] != null && json['data'] is Map<String, dynamic>) {
      msg = ChatMessageModel.fromJson(json['data'] as Map<String, dynamic>);
    } else if (json['message'] != null && json['message'] is Map<String, dynamic>) {
      msg = ChatMessageModel.fromJson(json['message'] as Map<String, dynamic>);
    }
    return SendMessageApiResponse(
      success: ChatMessageModel._parseBool(json['success']),
      data: msg,
      message: json['message'] is String ? json['message'] as String : null,
    );
  }
}

class ChatThreadsApiResponse {
  final bool success;
  final List<ChatThreadModel> threads;
  final String? message;

  ChatThreadsApiResponse({
    required this.success,
    required this.threads,
    this.message,
  });

  factory ChatThreadsApiResponse.fromJson(Map<String, dynamic> json) {
    List<ChatThreadModel> list = [];
    if (json['threads'] != null && json['threads'] is List) {
      list = (json['threads'] as List).map((e) => ChatThreadModel.fromJson(e as Map<String, dynamic>)).toList();
    } else if (json['data'] != null && json['data'] is List) {
      list = (json['data'] as List).map((e) => ChatThreadModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return ChatThreadsApiResponse(
      success: ChatMessageModel._parseBool(json['success']),
      threads: list,
      message: json['message'] as String?,
    );
  }
}

class UnreadCountApiResponse {
  final bool success;
  final int unreadCount;
  final String? message;

  UnreadCountApiResponse({
    required this.success,
    required this.unreadCount,
    this.message,
  });

  factory UnreadCountApiResponse.fromJson(Map<String, dynamic> json) {
    int count = 0;
    if (json['data'] != null && json['data'] is Map<String, dynamic>) {
      final dataMap = json['data'] as Map<String, dynamic>;
      count = dataMap['unreadCount'] is int
          ? dataMap['unreadCount'] as int
          : int.tryParse(dataMap['unreadCount']?.toString() ?? '') ?? 0;
    } else if (json['unreadCount'] != null) {
      count = json['unreadCount'] is int
          ? json['unreadCount'] as int
          : int.tryParse(json['unreadCount']?.toString() ?? '') ?? 0;
    }

    return UnreadCountApiResponse(
      success: ChatMessageModel._parseBool(json['success']),
      unreadCount: count,
      message: json['message'] as String?,
    );
  }
}

class ConsultationDocumentModel {
  final String id;
  final String appointmentId;
  final String? description;
  final String fileUrl;
  final String? fileName;
  final String? fileType;
  final int? fileSize;
  final String? uploadedBy;
  final String createdAt;

  ConsultationDocumentModel({
    required this.id,
    required this.appointmentId,
    this.description,
    required this.fileUrl,
    this.fileName,
    this.fileType,
    this.fileSize,
    this.uploadedBy,
    required this.createdAt,
  });

  factory ConsultationDocumentModel.fromJson(Map<String, dynamic> json) {
    return ConsultationDocumentModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      appointmentId: json['appointmentId']?.toString() ?? '',
      description: json['description']?.toString(),
      fileUrl: json['fileUrl']?.toString() ?? json['url']?.toString() ?? json['path']?.toString() ?? '',
      fileName: json['fileName']?.toString() ?? json['originalName']?.toString() ?? json['name']?.toString(),
      fileType: json['fileType']?.toString() ?? json['mimeType']?.toString() ?? json['type']?.toString(),
      fileSize: json['fileSize'] is int
          ? json['fileSize'] as int
          : int.tryParse(json['fileSize']?.toString() ?? ''),
      uploadedBy: json['uploadedBy']?.toString() ?? json['senderType']?.toString() ?? json['role']?.toString(),
      createdAt: json['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
    );
  }

  String get formattedDate {
    if (createdAt.isEmpty) return '';
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      final year = dt.year;
      final hour = (dt.hour % 12 == 0) ? 12 : (dt.hour % 12);
      final min = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '$day/$month/$year $hour:$min $period';
    } catch (_) {
      return createdAt;
    }
  }
}

