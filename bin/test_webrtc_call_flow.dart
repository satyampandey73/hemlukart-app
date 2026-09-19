import 'package:socket_io_client/socket_io_client.dart' as io;

void main() async {
  final appointmentId = '91a3b5af-646f-4b48-aeb6-6a89facdcd93';

  print(
    'Simulating Doctor and Patient WebRTC Socket Room Flow for appointment: $appointmentId ...',
  );

  final doctorSocket = io.io(
    'https://backend.chikitsakart.com',
    io.OptionBuilder()
        .setPath('/ws')
        .setTransports(['websocket', 'polling'])
        .enableAutoConnect()
        .build(),
  );

  final patientSocket = io.io(
    'https://backend.chikitsakart.com',
    io.OptionBuilder()
        .setPath('/ws')
        .setTransports(['websocket', 'polling'])
        .enableAutoConnect()
        .build(),
  );

  doctorSocket.onConnect((_) {
    print('👨‍⚕️ DOCTOR SOCKET CONNECTED! Socket ID: ${doctorSocket.id}');
    print('👨‍⚕️ Doctor joining room: $appointmentId');
    doctorSocket.emit('join-room', appointmentId);
    doctorSocket.emit('join-room', {'appointmentId': appointmentId});
  });

  patientSocket.onConnect((_) {
    print('👨‍👩‍👧 PATIENT SOCKET CONNECTED! Socket ID: ${patientSocket.id}');
    print('👨‍👩‍👧 Patient joining room: $appointmentId');
    patientSocket.emit('join-room', appointmentId);
    patientSocket.emit('join-room', {'appointmentId': appointmentId});
  });

  doctorSocket.on('user-joined', (data) {
    print('👨‍⚕️ [DOCTOR EVENT] user-joined: $data');
    print('👨‍⚕️ Doctor sending offer to patient...');
    doctorSocket.emit('offer', {
      'roomId': appointmentId,
      'appointmentId': appointmentId,
      'offer': {
        'type': 'offer',
        'sdp': 'v=0\r\no=- 12345 2 IN IP4 127.0.0.1\r\ns=-\r\nt=0 0\r\n',
      },
    });
  });

  patientSocket.on('user-joined', (data) {
    print('👨‍👩‍👧 [PATIENT EVENT] user-joined: $data');
  });

  patientSocket.on('offer', (data) {
    print('👨‍👩‍👧 [PATIENT EVENT] offer received: $data');
    print('👨‍👩‍👧 Patient sending answer to doctor...');
    patientSocket.emit('answer', {
      'roomId': appointmentId,
      'appointmentId': appointmentId,
      'answer': {
        'type': 'answer',
        'sdp': 'v=0\r\no=- 54321 2 IN IP4 127.0.0.1\r\ns=-\r\nt=0 0\r\n',
      },
    });
  });

  doctorSocket.on('answer', (data) {
    print('👨‍⚕️ [DOCTOR EVENT] answer received: $data');
  });

  patientSocket.on('ice-candidate', (data) {
    print('👨‍👩‍👧 [PATIENT EVENT] ice-candidate received: $data');
  });

  doctorSocket.on('ice-candidate', (data) {
    print('👨‍⚕️ [DOCTOR EVENT] ice-candidate received: $data');
  });

  await Future.delayed(const Duration(seconds: 8));

  doctorSocket.disconnect();
  patientSocket.disconnect();
  print('Simulation finished.');
}
