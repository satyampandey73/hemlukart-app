import 'package:socket_io_client/socket_io_client.dart' as io;

void main() async {
  print(
    'Connecting to Socket.io at https://backend.chikitsakart.com with path /ws ...',
  );

  final socket = io.io(
    'https://backend.chikitsakart.com',
    io.OptionBuilder()
        .setPath('/ws')
        .setTransports(['websocket', 'polling'])
        .enableAutoConnect()
        .build(),
  );

  socket.onConnect((_) {
    print('✅ CONNECTED! Socket ID: ${socket.id}');
    socket.emitWithAck(
      'join-room',
      '91a3b5af-646f-4b48-aeb6-6a89facdcd93',
      ack: (res) {
        print('✅ join-room string ack: $res');
      },
    );
    socket.emitWithAck(
      'join-room',
      {'appointmentId': '91a3b5af-646f-4b48-aeb6-6a89facdcd93'},
      ack: (res) {
        print('✅ join-room object ack: $res');
      },
    );
  });

  socket.onConnectError((err) => print('❌ CONNECT ERROR: $err'));
  socket.onError((err) => print('❌ ERROR: $err'));
  socket.on('user-joined', (data) => print('📩 USER JOINED: $data'));
  socket.on('offer', (data) => print('📩 OFFER: $data'));
  socket.on('answer', (data) => print('📩 ANSWER: $data'));
  socket.on('ice-candidate', (data) => print('📩 ICE CANDIDATE: $data'));

  await Future.delayed(const Duration(seconds: 10));
  socket.disconnect();
}
