import 'package:socket_io_client/socket_io_client.dart' as io;

void main() async {
  final token = 'test-token-12345';

  final authOptions = [
    {
      'name': 'auth: {token}',
      'opt': io.OptionBuilder()
          .setPath('/ws')
          .setTransports(['websocket', 'polling'])
          .setAuth({'token': token}),
    },
    {
      'name': 'auth: {token: Bearer}',
      'opt': io.OptionBuilder()
          .setPath('/ws')
          .setTransports(['websocket', 'polling'])
          .setAuth({'token': 'Bearer $token'}),
    },
    {
      'name': 'auth: {token}, query: token',
      'opt': io.OptionBuilder()
          .setPath('/ws')
          .setTransports(['websocket', 'polling'])
          .setAuth({'token': token})
          .setQuery({'token': token}),
    },
    {
      'name': 'query: token',
      'opt': io.OptionBuilder()
          .setPath('/ws')
          .setTransports(['websocket', 'polling'])
          .setQuery({'token': token}),
    },
    {
      'name': 'query: authorization Bearer',
      'opt': io.OptionBuilder()
          .setPath('/ws')
          .setTransports(['websocket', 'polling'])
          .setQuery({'token': token, 'authorization': 'Bearer $token'}),
    },
    {
      'name': 'extraHeaders Authorization Bearer + auth',
      'opt': io.OptionBuilder()
          .setPath('/ws')
          .setTransports(['websocket', 'polling'])
          .setAuth({'token': token})
          .setExtraHeaders({
            'Authorization': 'Bearer $token',
            'authorization': 'Bearer $token',
            'token': token,
          }),
    },
  ];

  for (var item in authOptions) {
    final name = item['name'] as String;
    final builder = item['opt'] as io.OptionBuilder;

    print('\n----------------------------------------');
    print('Testing Auth Format: $name');

    final socket = io.io(
      'https://backend.chikitsakart.com',
      builder.enableAutoConnect().build(),
    );

    socket.onConnect((_) {
      print('✅ SUCCESS! $name CONNECTED! Socket ID: ${socket.id}');
      socket.disconnect();
    });

    socket.onConnectError((err) {
      print('❌ FAILED $name: $err');
      socket.disconnect();
    });

    await Future.delayed(const Duration(seconds: 3));
  }
}
