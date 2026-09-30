import 'dart:async';
import 'dart:io';

class ApiHelper {
  /// Standard 30-second timeout for all API requests
  static const Duration defaultTimeout = Duration(seconds: 30);

  /// Converts technical network/socket/timeout exceptions into clean user-facing error messages
  static String getReadableErrorMessage(
    dynamic error, {
    String fallback = 'Something went wrong. Please try again.',
    String? fallbackPrefix,
  }) {
    if (error == null) return fallback;
    final errStr = error.toString().toLowerCase();

    // Timeout errors
    if (error is TimeoutException ||
        errStr.contains('timeoutexception') ||
        errStr.contains('future not completed') ||
        errStr.contains('timed out') ||
        errStr.contains('timeout')) {
      return 'Network error. Request timed out, please check your internet connection.';
    }

    // Network / Socket / DNS host lookup / ClientException errors
    if (error is SocketException ||
        errStr.contains('socketexception') ||
        errStr.contains('failed host lookup') ||
        errStr.contains('network is unreachable') ||
        errStr.contains('connection refused') ||
        errStr.contains('connection reset') ||
        errStr.contains('clientexception') ||
        errStr.contains('no address associated with hostname') ||
        errStr.contains('handshakeexception') ||
        errStr.contains('network error') ||
        errStr.contains('os error')) {
      return 'Network error. Please check your internet connection.';
    }

    if (fallbackPrefix != null && fallbackPrefix.trim().isNotEmpty) {
      return '$fallbackPrefix: $error';
    }

    return fallback;
  }
}
