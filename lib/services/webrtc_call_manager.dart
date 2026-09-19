import 'dart:async';
import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class WebRtcCallManager {
  static const String serverUrl = 'https://backend.chikitsakart.com';

  io.Socket? _socket;
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  final List<RTCIceCandidate> _pendingIceCandidates = [];

  bool isMuted = false;
  bool isVideoOff = false;
  bool isConnected = false;
  bool isPeerConnected = false;

  bool get hasRemoteVideo {
    if (_remoteStream == null) return false;
    final videoTracks = _remoteStream!.getVideoTracks();
    return videoTracks.isNotEmpty && videoTracks.any((t) => t.enabled);
  }

  Timer? _fallbackOfferTimer;
  Timer? _peerDisconnectTimer;

  // Callbacks
  Function(String status)? onCallStatusChanged;
  Function(MediaStream stream)? onRemoteStreamAdded;
  Function()? onCallEnded;

  Future<void> initializeRenderers() async {
    print('[WebRTC] Initializing video renderers...');
    await localRenderer.initialize();
    await remoteRenderer.initialize();
  }

  Future<void> startCall({
    required String appointmentId,
    required String token,
    required bool isDoctor,
  }) async {
    print(
      '[WebRTC] Starting video call for appointment: $appointmentId (isDoctor: $isDoctor)',
    );
    onCallStatusChanged?.call('Connecting to room signaling server...');

    // 1. Initialize Renderers & User Media
    await initializeRenderers();
    await _getUserMedia();

    // 2. Connect to Socket.io signaling server
    _connectSocket(
      token: token,
      appointmentId: appointmentId,
      isDoctor: isDoctor,
    );
  }

  Future<void> _getUserMedia() async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': {'facingMode': 'user'},
    };

    try {
      print('[WebRTC] Requesting getUserMedia with facingMode: user...');
      _localStream = await navigator.mediaDevices.getUserMedia(
        mediaConstraints,
      );
      localRenderer.srcObject = _localStream;
      print(
        '[WebRTC] getUserMedia success! Tracks: ${_localStream?.getTracks().length}',
      );
      onCallStatusChanged?.call('Camera and Microphone active');
    } catch (e1) {
      print(
        '[WebRTC] Initial getUserMedia failed ($e1). Trying fallback constraints...',
      );
      try {
        _localStream = await navigator.mediaDevices.getUserMedia({
          'audio': true,
          'video': true,
        });
        localRenderer.srcObject = _localStream;
        print('[WebRTC] Fallback getUserMedia success!');
        onCallStatusChanged?.call('Camera and Microphone active (fallback)');
      } catch (e2) {
        print('[WebRTC ERROR] getUserMedia error: $e2');
        onCallStatusChanged?.call('Camera/Mic permission error: $e2');
      }
    }
  }

  Map? _parseMap(dynamic data) {
    if (data is Map) return data;
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map) return decoded;
      } catch (_) {}
    }
    return null;
  }

  void _connectSocket({
    required String token,
    required String appointmentId,
    required bool isDoctor,
  }) {
    final String cleanToken = token.replaceAll('Bearer ', '').trim();
    final String bearerToken = 'Bearer $cleanToken';

    print(
      '[WebRTC Socket] Connecting to $serverUrl/ws with cleanToken length: ${cleanToken.length}',
    );

    _socket = io.io(
      serverUrl,
      io.OptionBuilder()
          .setPath('/ws')
          .setTransports(['websocket', 'polling'])
          .setAuth({
            'token': cleanToken,
            'authorization': bearerToken,
            'Authorization': bearerToken,
          })
          .setExtraHeaders({
            'Authorization': bearerToken,
            'authorization': bearerToken,
            'token': cleanToken,
          })
          .setQuery({'token': cleanToken, 'authorization': bearerToken})
          .enableAutoConnect()
          .enableReconnection()
          .build(),
    );

    _socket?.onConnect((_) {
      isConnected = true;
      print(
        '[WebRTC Socket] Connected successfully! Socket ID: ${_socket?.id}',
      );
      onCallStatusChanged?.call('Connected to room signaling server');

      // Join room with appointmentId object
      print('[WebRTC Socket] Emitting join-room for: $appointmentId');
      _socket?.emitWithAck(
        'join-room',
        {'appointmentId': appointmentId},
        ack: (response) {
          print('[WebRTC Socket] join-room object ack response: $response');
        },
      );

      // If Doctor joins and peer connection is not yet initiated after 3s, create offer as fallback
      if (isDoctor) {
        _fallbackOfferTimer?.cancel();
        _fallbackOfferTimer = Timer(const Duration(milliseconds: 3000), () async {
          if (_peerConnection == null && isConnected) {
            print(
              '[WebRTC Fallback] Doctor fallback timer triggered. Creating PeerConnection & Offer...',
            );
            onCallStatusChanged?.call('Initializing video offer...');
            await _createPeerConnection(appointmentId);
            await _createOffer(appointmentId);
          }
        });
      }
    });

    _socket?.onConnectError((err) {
      print('[WebRTC Socket ERROR] Connect error: $err');
      final String msg = err is Map
          ? (err['message']?.toString() ?? err.toString())
          : err.toString();
      if (msg.contains('AUTH_INVALID') || msg.contains('AUTH_MISSING')) {
        onCallStatusChanged?.call(
          'Authentication failed ($msg). Please log out and log in again.',
        );
      } else {
        onCallStatusChanged?.call('Socket connection error: $msg');
      }
    });

    _socket?.onError((err) {
      print('[WebRTC Socket ERROR] Socket error: $err');
    });

    // 1. User Joined event
    _socket?.on('user-joined', (data) async {
      print('[WebRTC Socket EVENT] user-joined received: $data');
      onCallStatusChanged?.call(
        'Peer joined video call. Establishing WebRTC stream...',
      );
      await _createPeerConnection(appointmentId);
      await _createOffer(appointmentId);
    });

    // 2. Receive WebRTC Offer
    _socket?.on('offer', (data) async {
      print('[WebRTC Socket EVENT] offer received: $data');
      onCallStatusChanged?.call('Receiving incoming video call offer...');
      final parsed = _parseMap(data);
      final offerData = parsed != null ? (parsed['offer'] ?? parsed) : null;
      final offerMap = _parseMap(offerData);
      if (offerMap != null) {
        await _createPeerConnection(appointmentId);
        await _handleOffer(appointmentId, offerMap);
      }
    });

    // 3. Receive WebRTC Answer
    _socket?.on('answer', (data) async {
      print('[WebRTC Socket EVENT] answer received: $data');
      onCallStatusChanged?.call('Receiving video call answer...');
      final parsed = _parseMap(data);
      final answerData = parsed != null ? (parsed['answer'] ?? parsed) : null;
      final answerMap = _parseMap(answerData);
      if (answerMap != null) {
        await _handleAnswer(answerMap);
      }
    });

    // 4. Receive ICE candidate
    _socket?.on('ice-candidate', (data) async {
      print('[WebRTC Socket EVENT] ice-candidate received: $data');
      final parsed = _parseMap(data);
      final candData = parsed != null ? (parsed['candidate'] ?? parsed) : null;
      final candMap = _parseMap(candData);
      if (candMap != null) {
        int lineIndex = 0;
        if (candMap['sdpMLineIndex'] != null) {
          if (candMap['sdpMLineIndex'] is int) {
            lineIndex = candMap['sdpMLineIndex'] as int;
          } else if (candMap['sdpMLineIndex'] is String) {
            lineIndex = int.tryParse(candMap['sdpMLineIndex'] as String) ?? 0;
          }
        }
        final candidate = RTCIceCandidate(
          candMap['candidate']?.toString() ?? '',
          candMap['sdpMid']?.toString() ?? '',
          lineIndex,
        );
        await _addIceCandidate(candidate);
      }
    });

    // 5. Peer Left / Call Ended events
    void handlePeerLeft(String eventName, dynamic data) {
      print('[WebRTC Socket EVENT] $eventName received: $data');
      isPeerConnected = false;
      onCallStatusChanged?.call('Call ended by participant');
      onCallEnded?.call();
    }

    _socket?.on('user-left', (data) => handlePeerLeft('user-left', data));
    _socket?.on('leave-room', (data) => handlePeerLeft('leave-room', data));
    _socket?.on('end-call', (data) => handlePeerLeft('end-call', data));
    _socket?.on('call-ended', (data) => handlePeerLeft('call-ended', data));
    _socket?.on(
      'peer-disconnected',
      (data) => handlePeerLeft('peer-disconnected', data),
    );

    _socket?.onDisconnect((reason) {
      print('[WebRTC Socket] Disconnected from server: $reason');
      isConnected = false;
      onCallStatusChanged?.call('Disconnected from server');
    });
  }

  Future<void> _createPeerConnection(String appointmentId) async {
    if (_peerConnection != null) return;

    print('[WebRTC] Creating RTCPeerConnection with STUN iceServers...');

    final Map<String, dynamic> configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
        {'urls': 'stun:stun2.l.google.com:19302'},
        {'urls': 'stun:stun3.l.google.com:19302'},
        {'urls': 'stun:stun4.l.google.com:19302'},
        {'urls': 'stun:global.stun.twilio.com:3478'},
        {'urls': 'stun:stun.services.mozilla.com'},
        {'urls': 'stun:stun.stunprotocol.org:3478'},
      ],
      'sdpSemantics': 'unified-plan',
      'iceTransportPolicy': 'all',
      'iceCandidatePoolSize': 10,
    };

    _peerConnection = await createPeerConnection(configuration);

    // Add local tracks to peer connection
    if (_localStream != null) {
      _localStream!.getTracks().forEach((track) {
        print('[WebRTC] Adding local track (${track.kind}) to peer connection');
        _peerConnection?.addTrack(track, _localStream!);
      });
    }

    // Handle incoming remote tracks (Unified Plan)
    _peerConnection?.onTrack = (RTCTrackEvent event) {
      print(
        '[WebRTC EVENT] onTrack fired with ${event.streams.length} stream(s), kind: ${event.track.kind}',
      );
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
      }
      if (_remoteStream != null) {
        remoteRenderer.srcObject = _remoteStream;
      }
      isPeerConnected = true;
      print('[WebRTC SUCCESS] Remote track active (${event.track.kind})');
      onCallStatusChanged?.call('Video Call Connected! Live Stream active.');
      if (_remoteStream != null) {
        onRemoteStreamAdded?.call(_remoteStream!);
      }
    };

    // Handle incoming remote streams (Plan B fallback)
    _peerConnection?.onAddStream = (MediaStream stream) {
      print('[WebRTC EVENT] onAddStream fired! Stream ID: ${stream.id}');
      _remoteStream = stream;
      remoteRenderer.srcObject = _remoteStream;
      isPeerConnected = true;
      print('[WebRTC SUCCESS] Remote video stream active via onAddStream!');
      onCallStatusChanged?.call('Video Call Connected! Live Stream active.');
      onRemoteStreamAdded?.call(_remoteStream!);
    };

    // Send local ICE candidates to peer via socket
    _peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      print(
        '[WebRTC EVENT] Generated local ICE candidate: ${candidate.sdpMid}',
      );
      _socket?.emit('ice-candidate', {
        'roomId': appointmentId,
        'appointmentId': appointmentId,
        'candidate': {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        },
      });
    };

    _peerConnection?.onIceConnectionState = (RTCIceConnectionState state) {
      print('[WebRTC EVENT] ICE Connection State changed to: $state');
      if (state == RTCIceConnectionState.RTCIceConnectionStateConnected ||
          state == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
        _peerDisconnectTimer?.cancel();
        isPeerConnected = true;
        onCallStatusChanged?.call('Video Call Connected! Live Stream active.');
        try {
          Helper.setSpeakerphoneOn(true);
        } catch (_) {}
      } else if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
        print('[WebRTC] ICE Failed! Attempting automatic ICE restart...');
        onCallStatusChanged?.call('Reconnecting video stream...');
        _restartIce(appointmentId);
      } else if (state ==
          RTCIceConnectionState.RTCIceConnectionStateDisconnected) {
        onCallStatusChanged?.call('Participant disconnected. Ending call in 3s...');
        _peerDisconnectTimer?.cancel();
        _peerDisconnectTimer = Timer(const Duration(seconds: 3), () {
          print('[WebRTC] ICE Disconnect timeout reached (3s). Triggering onCallEnded.');
          isPeerConnected = false;
          onCallEnded?.call();
        });
      } else if (state == RTCIceConnectionState.RTCIceConnectionStateClosed) {
        _peerDisconnectTimer?.cancel();
        isPeerConnected = false;
        onCallEnded?.call();
      }
    };

    _peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      print('[WebRTC EVENT] PeerConnection State changed to: $state');
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        _peerDisconnectTimer?.cancel();
        isPeerConnected = true;
      } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        _peerDisconnectTimer?.cancel();
        _peerDisconnectTimer = Timer(const Duration(seconds: 3), () {
          print('[WebRTC] PeerConnection Disconnect timeout reached (3s). Triggering onCallEnded.');
          isPeerConnected = false;
          onCallEnded?.call();
        });
      } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
        _peerDisconnectTimer?.cancel();
        isPeerConnected = false;
        onCallEnded?.call();
      }
    };
  }

  Future<void> _restartIce(String appointmentId) async {
    try {
      if (_peerConnection != null) {
        final Map<String, dynamic> constraints = {
          'offerToReceiveAudio': true,
          'offerToReceiveVideo': true,
          'iceRestart': true,
        };
        final offer = await _peerConnection!.createOffer(constraints);
        await _peerConnection!.setLocalDescription(offer);
        _socket?.emit('offer', {
          'roomId': appointmentId,
          'appointmentId': appointmentId,
          'offer': {'sdp': offer.sdp, 'type': offer.type},
        });
      }
    } catch (e) {
      print('[WebRTC] ICE Restart error: $e');
    }
  }

  Future<void> _createOffer(String appointmentId) async {
    if (_peerConnection == null) return;

    final signalingState = _peerConnection!.signalingState;
    if (signalingState != null &&
        signalingState != RTCSignalingState.RTCSignalingStateStable) {
      print(
        '[WebRTC] Skip createOffer: PeerConnection signalingState is: $signalingState',
      );
      return;
    }

    try {
      print('[WebRTC] Creating SDP Offer...');
      final Map<String, dynamic> constraints = {
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': true,
      };
      final RTCSessionDescription offer = await _peerConnection!.createOffer(
        constraints,
      );
      await _peerConnection!.setLocalDescription(offer);

      print('[WebRTC Socket] Emitting SDP Offer to room: $appointmentId');
      _socket?.emit('offer', {
        'roomId': appointmentId,
        'appointmentId': appointmentId,
        'offer': {'sdp': offer.sdp, 'type': offer.type},
      });
    } catch (e) {
      print('[WebRTC ERROR] createOffer error: $e');
    }
  }

  Future<void> _handleOffer(String appointmentId, Map offerData) async {
    if (_peerConnection == null) return;

    try {
      print('[WebRTC] Handling incoming SDP Offer...');
      final String sdp = offerData['sdp']?.toString() ?? offerData.toString();
      final String type = offerData['type']?.toString() ?? 'offer';

      final RTCSessionDescription description = RTCSessionDescription(sdp, type);
      await _peerConnection!.setRemoteDescription(description);

      // Drain queued ICE candidates received before remote description
      await _drainPendingIceCandidates();

      print('[WebRTC] Creating SDP Answer...');
      final Map<String, dynamic> constraints = {
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': true,
      };
      final RTCSessionDescription answer = await _peerConnection!.createAnswer(
        constraints,
      );
      await _peerConnection!.setLocalDescription(answer);

      print('[WebRTC Socket] Emitting SDP Answer to room: $appointmentId');
      _socket?.emit('answer', {
        'roomId': appointmentId,
        'appointmentId': appointmentId,
        'answer': {'sdp': answer.sdp, 'type': answer.type},
      });
    } catch (e) {
      print('[WebRTC ERROR] handleOffer error: $e');
    }
  }

  Future<void> _handleAnswer(Map answerData) async {
    if (_peerConnection == null) return;

    try {
      print('[WebRTC] Handling incoming SDP Answer...');
      final String sdp = answerData['sdp']?.toString() ?? answerData.toString();
      final String type = answerData['type']?.toString() ?? 'answer';

      final RTCSessionDescription description = RTCSessionDescription(sdp, type);
      await _peerConnection!.setRemoteDescription(description);

      // Drain queued ICE candidates received before remote description
      await _drainPendingIceCandidates();
    } catch (e) {
      print('[WebRTC ERROR] handleAnswer error: $e');
    }
  }

  Future<void> _addIceCandidate(RTCIceCandidate candidate) async {
    if (_peerConnection != null) {
      final remoteDesc = await _peerConnection!.getRemoteDescription();
      if (remoteDesc != null) {
        print('[WebRTC] Adding ICE candidate directly: ${candidate.sdpMid}');
        await _peerConnection!.addCandidate(candidate);
        return;
      }
    }
    print(
      '[WebRTC] Remote description not ready. Queuing ICE candidate: ${candidate.sdpMid}',
    );
    _pendingIceCandidates.add(candidate);
  }

  Future<void> _drainPendingIceCandidates() async {
    if (_peerConnection == null) return;
    print(
      '[WebRTC] Draining ${_pendingIceCandidates.length} queued ICE candidate(s)...',
    );
    for (var cand in _pendingIceCandidates) {
      try {
        await _peerConnection!.addCandidate(cand);
      } catch (e) {
        print('[WebRTC ERROR] Failed to add queued ICE candidate: $e');
      }
    }
    _pendingIceCandidates.clear();
  }

  void toggleMute() {
    if (_localStream != null) {
      final audioTracks = _localStream!.getAudioTracks();
      if (audioTracks.isNotEmpty) {
        isMuted = !isMuted;
        audioTracks[0].enabled = !isMuted;
        print('[WebRTC] Microphone muted: $isMuted');
      }
    }
  }

  void toggleCamera() {
    if (_localStream != null) {
      final videoTracks = _localStream!.getVideoTracks();
      if (videoTracks.isNotEmpty) {
        isVideoOff = !isVideoOff;
        videoTracks[0].enabled = !isVideoOff;
        print('[WebRTC] Camera disabled: $isVideoOff');
      }
    }
  }

  Future<void> switchCamera() async {
    if (_localStream != null) {
      final videoTracks = _localStream!.getVideoTracks();
      if (videoTracks.isNotEmpty) {
        await Helper.switchCamera(videoTracks[0]);
        print('[WebRTC] Switched camera orientation');
      }
    }
  }

  Future<void> endCall(String appointmentId) async {
    print('[WebRTC] Ending video call session for appointment: $appointmentId');
    _fallbackOfferTimer?.cancel();
    _peerDisconnectTimer?.cancel();

    try {
      if (_socket != null) {
        final payload = {
          'appointmentId': appointmentId,
          'roomId': appointmentId,
        };
        _socket?.emit('leave-room', appointmentId);
        _socket?.emit('leave-room', payload);
        _socket?.emit('end-call', appointmentId);
        _socket?.emit('end-call', payload);
        _socket?.emit('call-ended', appointmentId);
        _socket?.emit('call-ended', payload);
        _socket?.emit('peer-disconnected', payload);
        _socket?.emit('user-left', payload);

        // Give the socket 500ms to flush the packets across the network before tearing down
        await Future.delayed(const Duration(milliseconds: 500));
        _socket?.disconnect();
        _socket?.dispose();
      }
    } catch (e) {
      print('[WebRTC cleanup] Socket cleanup error: $e');
    }

    try {
      _localStream?.getTracks().forEach((track) => track.stop());
      await _localStream?.dispose();
    } catch (e) {
      print('[WebRTC cleanup] Local stream cleanup error: $e');
    }

    try {
      await _peerConnection?.close();
      await _peerConnection?.dispose();
    } catch (e) {
      print('[WebRTC cleanup] PeerConnection cleanup error: $e');
    }

    try {
      localRenderer.srcObject = null;
      remoteRenderer.srcObject = null;
    } catch (_) {}

    try {
      await localRenderer.dispose();
      await remoteRenderer.dispose();
    } catch (e) {
      print('[WebRTC cleanup] Renderer cleanup error: $e');
    }

    _pendingIceCandidates.clear();
    isPeerConnected = false;
    isConnected = false;
  }
}
