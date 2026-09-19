import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../constants/app_colors.dart';
import '../constants/app_state.dart';
import '../services/appointment_service.dart';
import '../services/video_call_service.dart';
import '../services/webrtc_call_manager.dart';

class VideoCallScreen extends StatefulWidget {
  final String appointmentId;
  final String? videoCallId;
  final bool isDoctor;
  final String peerName;
  final String? peerSubtitle;
  final String? peerAvatar;

  const VideoCallScreen({
    super.key,
    required this.appointmentId,
    this.videoCallId,
    required this.isDoctor,
    required this.peerName,
    this.peerSubtitle,
    this.peerAvatar,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final AppState _appState = AppState();
  final WebRtcCallManager _callManager = WebRtcCallManager();

  String _statusMessage = 'Initializing WebRTC video call...';
  bool _isEndingCall = false;
  bool _isSpeakerOn = true;
  bool _callStarted = false;   // guard: prevents double-starting
  bool _isCallEnded = false;   // guard: prevents duplicate end triggers

  Timer? _callDurationTimer;
  Timer? _activeCallCheckTimer;
  int _callDurationSeconds = 0;

  @override
  void initState() {
    super.initState();
    if (!_callStarted) {
      _callStarted = true;
      _startCallSession();
    }
  }

  @override
  void dispose() {
    _callDurationTimer?.cancel();
    _activeCallCheckTimer?.cancel();
    if (!_isEndingCall) {
      _callManager.endCall(widget.appointmentId);
    }
    super.dispose();
  }

  Future<void> _handleRemoteCallEnded() async {
    if (!mounted || _isEndingCall || _isCallEnded) return;
    _isCallEnded = true;
    _isEndingCall = true;
    _callDurationTimer?.cancel();
    _activeCallCheckTimer?.cancel();

    final token = (widget.isDoctor ? _appState.doctorToken : _appState.authToken) ?? _appState.activeChatToken;
    if (widget.videoCallId != null && token != null) {
      try {
        await VideoCallService.endVideoCall(
          videoCallId: widget.videoCallId!,
          token: token,
        );
      } catch (_) {}
    }

    if (widget.isDoctor && token != null && token.isNotEmpty) {
      try {
        await AppointmentService.completeDoctorAppointment(
          appointmentId: widget.appointmentId,
          token: token,
        );
      } catch (_) {}
    }

    try {
      await _callManager.endCall(widget.appointmentId);
    } catch (_) {}

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Call ended by participant'),
        duration: Duration(seconds: 2),
      ),
    );
    Navigator.of(context).pop(true);
  }

  Future<void> _startCallSession() async {
    _callManager.onCallStatusChanged = (status) {
      if (!mounted) return;
      setState(() {
        _statusMessage = status;
      });
      if (status.contains('Live Stream active')) {
        _startTimer();
      }
    };

    _callManager.onRemoteStreamAdded = (_) {
      if (!mounted) return;
      setState(() {});
    };

    _callManager.onCallEnded = () async {
      await _handleRemoteCallEnded();
    };

    final token = (widget.isDoctor ? _appState.doctorToken : _appState.authToken) ?? _appState.activeChatToken;

    if (token == null || token.isEmpty) {
      setState(() {
        _statusMessage = 'Authentication error: Not logged in';
      });
      return;
    }

    // Check active call status every 3s as a fail-safe detection
    _activeCallCheckTimer?.cancel();
    _activeCallCheckTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!mounted || _isEndingCall || _isCallEnded) return;
      try {
        final checkToken = (widget.isDoctor ? _appState.doctorToken : _appState.authToken) ?? _appState.activeChatToken;
        if (checkToken == null || checkToken.isEmpty) return;
        final res = await VideoCallService.getActiveVideoCall(
          appointmentId: widget.appointmentId,
          token: checkToken,
        );
        if (!res.exists || res.videoCall == null || res.videoCall!.status.toLowerCase() == 'ended' || res.videoCall!.status.toLowerCase() == 'completed') {
          print('[VideoCallScreen] Active call poll indicates call has ended.');
          await _handleRemoteCallEnded();
        }
      } catch (_) {}
    });

    await _callManager.startCall(
      appointmentId: widget.appointmentId,
      token: token,
      isDoctor: widget.isDoctor,
    );
    if (mounted) setState(() {});
  }

  void _startTimer() {
    _callDurationTimer?.cancel();
    _callDurationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _callDurationSeconds++;
        });
      }
    });
  }

  String get _formattedDuration {
    final minutes = (_callDurationSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_callDurationSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _handleEndCall() async {
    if (_isEndingCall) return;

    setState(() {
      _isEndingCall = true;
      _isCallEnded = true;
    });

    _callDurationTimer?.cancel();
    _activeCallCheckTimer?.cancel();

    final token = (widget.isDoctor ? _appState.doctorToken : _appState.authToken) ?? _appState.activeChatToken;

    if (widget.videoCallId != null && token != null) {
      try {
        await VideoCallService.endVideoCall(
          videoCallId: widget.videoCallId!,
          token: token,
        );
      } catch (e) {
        print('[VideoCallScreen] endVideoCall error: $e');
      }
    }

    // If doctor ends consultation call, mark appointment as completed so it cannot be restarted
    if (widget.isDoctor && token != null && token.isNotEmpty) {
      try {
        await AppointmentService.completeDoctorAppointment(
          appointmentId: widget.appointmentId,
          token: token,
        );
        print('[VideoCallScreen] Marked appointment ${widget.appointmentId} as completed');
      } catch (e) {
        print('[VideoCallScreen] completeDoctorAppointment error: $e');
      }
    }

    await _callManager.endCall(widget.appointmentId);

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _handleEndCall();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
        child: Stack(
          children: [
            // Remote Video View (Fullscreen)
            Positioned.fill(
              child: (_callManager.isPeerConnected &&
                      _callManager.hasRemoteVideo &&
                      _callManager.remoteRenderer.textureId != null)
                  ? RTCVideoView(
                      _callManager.remoteRenderer,
                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    )
                  : Container(
                      color: const Color(0xFF0F172A),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundColor: Colors.white.withValues(alpha: 0.1),
                            backgroundImage: (widget.peerAvatar != null && widget.peerAvatar!.startsWith('http'))
                                ? NetworkImage(widget.peerAvatar!) as ImageProvider
                                : const AssetImage('assets/d1.jpg'),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.peerName,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.peerSubtitle ?? (widget.isDoctor ? 'Patient' : 'Ayush Doctor'),
                            style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.7)),
                          ),
                          const SizedBox(height: 24),
                          if (!_callManager.isPeerConnected) ...[
                            const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                            ),
                            const SizedBox(height: 12),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.mic, color: Colors.green, size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    'Connected (Audio Only)',
                                    style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              _statusMessage,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12, color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),

            // Local Video Preview (PiP Top-Right Window)
            Positioned(
              right: 16,
              top: 16,
              child: Container(
                width: 110,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: (_callManager.localRenderer.textureId != null && !_callManager.isVideoOff)
                      ? RTCVideoView(
                          _callManager.localRenderer,
                          mirror: true,
                          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                        )
                      : Container(
                          color: Colors.black87,
                          child: Center(
                            child: Icon(
                              _callManager.isVideoOff ? Icons.videocam_off_rounded : Icons.videocam_rounded,
                              color: Colors.white54,
                              size: 28,
                            ),
                          ),
                        ),
                ),
              ),
            ),

            // Top Status Bar (Overlay)
            Positioned(
              left: 16,
              top: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _callManager.isPeerConnected ? Colors.green : Colors.amber,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _callManager.isPeerConnected ? _formattedDuration : 'Calling...',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Control Bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(36),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Mic Mute Toggle
                        IconButton(
                          icon: Icon(
                            _callManager.isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                            color: _callManager.isMuted ? Colors.redAccent : Colors.white,
                            size: 24,
                          ),
                          onPressed: () {
                            setState(() {
                              _callManager.toggleMute();
                            });
                          },
                        ),

                        // Camera Toggle
                        IconButton(
                          icon: Icon(
                            _callManager.isVideoOff ? Icons.videocam_off_rounded : Icons.videocam_rounded,
                            color: _callManager.isVideoOff ? Colors.redAccent : Colors.white,
                            size: 24,
                          ),
                          onPressed: () {
                            setState(() {
                              _callManager.toggleCamera();
                            });
                          },
                        ),

                        // Switch Camera
                        IconButton(
                          icon: const Icon(
                            Icons.cameraswitch_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          onPressed: () async {
                            await _callManager.switchCamera();
                            setState(() {});
                          },
                        ),

                        // Speakerphone Toggle
                        IconButton(
                          icon: Icon(
                            _isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                            color: _isSpeakerOn ? Colors.greenAccent : Colors.white70,
                            size: 24,
                          ),
                          onPressed: () {
                            setState(() {
                              _isSpeakerOn = !_isSpeakerOn;
                              Helper.setSpeakerphoneOn(_isSpeakerOn);
                            });
                          },
                        ),

                        // End Call Button
                        GestureDetector(
                          onTap: _handleEndCall,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: _isEndingCall
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(
                                    Icons.call_end_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
