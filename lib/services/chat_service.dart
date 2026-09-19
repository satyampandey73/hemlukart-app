import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_model.dart';

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
          .timeout(const Duration(seconds: 15));

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
        message: 'Error sending message: $e',
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
          .timeout(const Duration(seconds: 15));

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
        message: 'Error fetching chat messages: $e',
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
          .timeout(const Duration(seconds: 15));

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
        message: 'Error fetching chat threads: $e',
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
          .timeout(const Duration(seconds: 15));

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
        message: 'Error fetching unread count: $e',
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
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
