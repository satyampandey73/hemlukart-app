import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;
import '../models/chat_model.dart';
import 'api_helper.dart';

class ChatService {
  static const String baseUrl = 'https://backend.chikitsakart.com/api/chat';

  /// API 1: POST https://backend.chikitsakart.com/api/chat/messages
  /// Sends a new chat message for a given appointment.
  static Future<SendMessageApiResponse> sendMessage({
    required String appointmentId,
    required String message,
    required String token,
  }) async {
    final Uri url = Uri.parse('$baseUrl/messages');

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final Map<String, dynamic> bodyData = {
      'appointmentId': appointmentId.trim(),
      'message': message.trim(),
    };

    try {
      final response = await http
          .post(url, headers: headers, body: jsonEncode(bodyData))
          .timeout(const Duration(seconds: 30));

      final Map<String, dynamic> body = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return SendMessageApiResponse.fromJson(body);
      } else {
        return SendMessageApiResponse(
          success: false,
          message:
              body['message'] as String? ??
              'Failed to send message (${response.statusCode})',
        );
      }
    } catch (e) {
      return SendMessageApiResponse(
        success: false,
        message: ApiHelper.getReadableErrorMessage(
          e,
          fallback: 'Error sending message',
        ),
      );
    }
  }

  /// API 2: GET https://backend.chikitsakart.com/api/chat/messages/{appointmentId}
  /// Fetches all messages for an appointment.
  static Future<ChatMessagesApiResponse> getMessages({
    required String appointmentId,
    required String token,
  }) async {
    final Uri url = Uri.parse('$baseUrl/messages/${appointmentId.trim()}');

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      final Map<String, dynamic> body = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ChatMessagesApiResponse.fromJson(body);
      } else {
        return ChatMessagesApiResponse(
          success: false,
          messages: [],
          message:
              body['message'] as String? ??
              'Failed to fetch messages (${response.statusCode})',
        );
      }
    } catch (e) {
      return ChatMessagesApiResponse(
        success: false,
        messages: [],
        message: ApiHelper.getReadableErrorMessage(
          e,
          fallback: 'Error fetching chat messages',
        ),
      );
    }
  }

  /// API 3: GET https://backend.chikitsakart.com/api/chat/threads
  /// Fetches all active conversation threads for doctor or patient.
  static Future<ChatThreadsApiResponse> getThreads({
    required String token,
  }) async {
    final Uri url = Uri.parse('$baseUrl/threads');

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      final Map<String, dynamic> body = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ChatThreadsApiResponse.fromJson(body);
      } else {
        return ChatThreadsApiResponse(
          success: false,
          threads: [],
          message:
              body['message'] as String? ??
              'Failed to fetch threads (${response.statusCode})',
        );
      }
    } catch (e) {
      return ChatThreadsApiResponse(
        success: false,
        threads: [],
        message: ApiHelper.getReadableErrorMessage(
          e,
          fallback: 'Error fetching chat threads',
        ),
      );
    }
  }

  /// API 4: GET https://backend.chikitsakart.com/api/chat/unread-count
  /// Fetches total unread messages count.
  static Future<UnreadCountApiResponse> getUnreadCount({
    required String token,
  }) async {
    final Uri url = Uri.parse('$baseUrl/unread-count');

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      final Map<String, dynamic> body = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return UnreadCountApiResponse.fromJson(body);
      } else {
        return UnreadCountApiResponse(
          success: false,
          unreadCount: 0,
          message: body['message'] as String? ?? 'Failed to fetch unread count',
        );
      }
    } catch (e) {
      return UnreadCountApiResponse(
        success: false,
        unreadCount: 0,
        message: ApiHelper.getReadableErrorMessage(
          e,
          fallback: 'Error fetching unread count',
        ),
      );
    }
  }

  /// API 5: PATCH https://backend.chikitsakart.com/api/chat/messages/{appointmentId}/read
  /// Marks all messages for an appointment as read.
  static Future<bool> markMessagesAsRead({
    required String appointmentId,
    required String token,
  }) async {
    final Uri url = Uri.parse('$baseUrl/messages/${appointmentId.trim()}/read');

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await http
          .patch(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static MediaType _resolveMediaType(String pathOrName) {
    final clean = pathOrName.toLowerCase();
    final ext = p.extension(clean).replaceAll('.', '').trim();
    switch (ext) {
      case 'png':
        return MediaType('image', 'png');
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'webp':
        return MediaType('image', 'webp');
      case 'gif':
        return MediaType('image', 'gif');
      case 'bmp':
        return MediaType('image', 'bmp');
      case 'svg':
        return MediaType('image', 'svg+xml');
      case 'pdf':
        return MediaType('application', 'pdf');
      case 'doc':
        return MediaType('application', 'msword');
      case 'docx':
        return MediaType(
          'application',
          'vnd.openxmlformats-officedocument.wordprocessingml.document',
        );
      case 'txt':
        return MediaType('text', 'plain');
      case 'mp4':
        return MediaType('video', 'mp4');
      case 'mov':
        return MediaType('video', 'quicktime');
      case 'avi':
        return MediaType('video', 'x-msvideo');
      case 'webm':
        return MediaType('video', 'webm');
      default:
        if (clean.contains('.png')) return MediaType('image', 'png');
        if (clean.contains('.jpg') || clean.contains('.jpeg')) return MediaType('image', 'jpeg');
        if (clean.contains('.pdf')) return MediaType('application', 'pdf');
        return MediaType('application', 'octet-stream');
    }
  }

  static String _resolveFileName(String filePath, [String? customName]) {
    String name = (customName != null && customName.trim().isNotEmpty)
        ? customName.trim()
        : p.basename(filePath);
    final ext = p.extension(name);
    if (ext.isEmpty) {
      final fileExt = p.extension(filePath);
      if (fileExt.isNotEmpty) {
        name = '$name$fileExt';
      } else {
        name = '$name.png';
      }
    }
    return name;
  }

  /// API 6: POST https://backend.chikitsakart.com/api/chat/documents
  /// Uploads a document/prescription/report file for an appointment.
  static Future<Map<String, dynamic>> uploadDocument({
    required String appointmentId,
    required String description,
    required String filePath,
    String? fileName,
    required String token,
  }) async {
    final Uri url = Uri.parse('$baseUrl/documents');

    try {
      final request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
      request.fields['appointmentId'] = appointmentId.trim();
      request.fields['description'] = description.trim();

      final resolvedName = _resolveFileName(filePath, fileName);
      final mediaType = _resolveMediaType(resolvedName);

      request.fields['fileName'] = resolvedName;
      request.fields['fileType'] = mediaType.mimeType;
      request.fields['mimeType'] = mediaType.mimeType;

      final file = await http.MultipartFile.fromPath(
        'file',
        filePath,
        filename: resolvedName,
        contentType: mediaType,
      );
      request.files.add(file);

      final streamedResponse = await request.send().timeout(const Duration(seconds: 45));
      final response = await http.Response.fromStream(streamedResponse);
      final dynamic body = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': body is Map ? (body['message'] ?? 'Document uploaded successfully') : 'Document uploaded successfully',
          'data': body,
        };
      } else {
        return {
          'success': false,
          'message': body is Map
              ? (body['message'] ?? 'Failed to upload document (${response.statusCode})')
              : 'Failed to upload document (${response.statusCode})',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error uploading document: $e',
      };
    }
  }

  /// API 7: GET https://backend.chikitsakart.com/api/chat/documents/{appointmentId}
  /// Fetches all documents uploaded for the consultation.
  static Future<List<ConsultationDocumentModel>> getDocuments({
    required String appointmentId,
    required String token,
  }) async {
    final Uri url = Uri.parse('$baseUrl/documents/${appointmentId.trim()}');

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      final dynamic body = jsonDecode(response.body);

      List<ConsultationDocumentModel> docs = [];
      if (body is Map) {
        final list = body['documents'] ?? body['data'] ?? body['files'];
        if (list is List) {
          docs = list
              .map((e) => ConsultationDocumentModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      } else if (body is List) {
        docs = body
            .map((e) => ConsultationDocumentModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return docs;
    } catch (e) {
      debugPrint('[ChatService] getDocuments error: $e');
      return [];
    }
  }

  /// API 8: POST https://backend.chikitsakart.com/api/chat/messages (multipart)
  /// Sends a chat message with optional media/document attachment.
  static Future<SendMessageApiResponse> sendMessageWithAttachment({
    required String appointmentId,
    required String message,
    String? filePath,
    String? fileName,
    required String token,
  }) async {
    if (filePath == null || filePath.isEmpty) {
      return sendMessage(
        appointmentId: appointmentId,
        message: message,
        token: token,
      );
    }

    final Uri url = Uri.parse('$baseUrl/messages');

    try {
      final request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
      request.fields['appointmentId'] = appointmentId.trim();
      request.fields['message'] = message.trim();

      final resolvedName = _resolveFileName(filePath, fileName);
      final mediaType = _resolveMediaType(resolvedName);

      request.fields['fileName'] = resolvedName;
      request.fields['fileType'] = mediaType.mimeType;
      request.fields['mimeType'] = mediaType.mimeType;

      final file = await http.MultipartFile.fromPath(
        'file',
        filePath,
        filename: resolvedName,
        contentType: mediaType,
      );
      request.files.add(file);

      final streamedResponse = await request.send().timeout(const Duration(seconds: 45));
      final response = await http.Response.fromStream(streamedResponse);
      final Map<String, dynamic> body = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return SendMessageApiResponse.fromJson(body);
      } else {
        return SendMessageApiResponse(
          success: false,
          message: body['message'] as String? ??
              'Failed to send message (${response.statusCode})',
        );
      }
    } catch (e) {
      return SendMessageApiResponse(
        success: false,
        message: 'Error sending message with attachment: $e',
      );
    }
  }
}

