import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final urls = [
    'https://backend.chikitsakart.com/ws/?EIO=4&transport=polling',
    'https://backend.chikitsakart.com:5870/ws/?EIO=4&transport=polling',
    'https://backend.chikitsakart.com:5000/ws/?EIO=4&transport=polling',
    'https://backend.chikitsakart.com/socket.io/?EIO=4&transport=polling',
    'https://backend.chikitsakart.com/api/video-calls/start',
  ];

  for (var u in urls) {
    try {
      print('Testing: $u ...');
      final res = await http
          .get(Uri.parse(u))
          .timeout(const Duration(seconds: 5));
      print(
        'Status: ${res.statusCode}, Body: ${res.body.length > 200 ? res.body.substring(0, 200) : res.body}',
      );
    } catch (e) {
      print('Error testing $u: $e');
    }
  }
}
