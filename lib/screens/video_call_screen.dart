import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import '../constants/app_colors.dart';
import '../constants/app_state.dart';
import '../models/chat_model.dart';
import '../models/my_appointments_model.dart';
import '../services/appointment_service.dart';
import '../services/chat_service.dart';
import '../services/eprescription_service.dart';
import '../services/video_call_service.dart';
import '../services/webrtc_call_manager.dart';

class VideoCallScreen extends StatefulWidget {
  final String appointmentId;
  final String? videoCallId;
  final bool isDoctor;
  final String peerName;
  final String? peerSubtitle;
  final String? peerAvatar;
  final String? patientUserId;

  const VideoCallScreen({
    super.key,
    required this.appointmentId,
    this.videoCallId,
    required this.isDoctor,
    required this.peerName,
    this.peerSubtitle,
    this.peerAvatar,
    this.patientUserId,
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
  bool _callStarted = false; // guard: prevents double-starting
  bool _isCallEnded = false; // guard: prevents duplicate end triggers

  Timer? _callDurationTimer;
  int _callDurationSeconds = 0;

  // Consultation Actions & Tools State
  bool _isVideoMinimized = false;
  String _activeTool = 'Chat'; // 'Chat', 'Issue Prescription', 'View Prescription', 'Upload Documents', 'Consultation History'

  // Appointment Context Resolution
  AppointmentDetailModel? _resolvedAppointment;
  bool get isMeetingExpired => _resolvedAppointment?.isMeetingTimeExpired ?? false;
  String? _resolvedUserId;
  String? _resolvedDoctorId;
  String? _resolvedDoctorName;
  String? _resolvedPatientName;
  String? _resolvedPatientMobile;

  // Chat State
  final TextEditingController _chatMsgController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  List<ChatMessageModel> _chatMessages = [];
  bool _isLoadingChat = false;
  bool _isSendingChat = false;
  String? _chatAttachmentPath;
  String? _chatAttachmentName;
  Timer? _chatPollingTimer;

  // Issue Prescription State (Doctor only)
  final TextEditingController _medSearchController = TextEditingController();
  final TextEditingController _rxDiagnosisController = TextEditingController(text: 'General Consultation');
  final TextEditingController _rxGeneralInstructionsController = TextEditingController();
  final List<Map<String, dynamic>> _rxMedications = [];
  bool _isSubmittingRx = false;
  final List<String> _suggestedMeds = [
    'Ashwagandha Churna',
    'Brahmi Vati',
    'Triphala Churna',
    'Giloy Ghanvati',
    'Chyawanprash Awaleha',
    'Shatavari Churna',
    'Trikatu Churna',
    'Gokshuradi Guggulu',
    'Kaishore Guggulu',
    'Yograj Guggulu',
    'Avipattikar Churna',
    'Mahasudarshan Kwath',
    'Omeprazole 20mg',
    'Paracetamol 650mg',
    'Amoxicillin 500mg',
    'Pantoprazole 40mg',
    'Cetirizine 10mg',
    'Azithromycin 500mg',
    'Vitamin C 500mg',
    'Multivitamin Zinc',
  ];
  List<String> _filteredSuggestions = [];

  // View Prescription State
  List<Map<String, dynamic>> _prescriptions = [];
  bool _isLoadingPrescriptions = false;

  // Upload Documents State
  List<ConsultationDocumentModel> _documents = [];
  bool _isLoadingDocuments = false;
  bool _isUploadingDocument = false;

  // Consultation History State (Only completed consultations between this doctor & patient)
  List<UserAppointmentItem> _historyAppointments = [];
  bool _isLoadingHistory = false;

  @override
  void initState() {
    super.initState();
    _resolvedUserId = widget.patientUserId;
    if (!_callStarted) {
      _callStarted = true;
      _startCallSession();
    }
    _initConsultationData();
  }

  @override
  void dispose() {
    _callDurationTimer?.cancel();
    _chatPollingTimer?.cancel();
    _chatMsgController.dispose();
    _chatScrollController.dispose();
    _medSearchController.dispose();
    _rxDiagnosisController.dispose();
    _rxGeneralInstructionsController.dispose();
    if (!_isEndingCall) {
      _callManager.endCall(widget.appointmentId);
    }
    super.dispose();
  }

  Future<String?> _getToken() async {
    String? token = (widget.isDoctor ? _appState.doctorToken : _appState.authToken) ?? _appState.activeChatToken;
    if (token == null || token.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      token = (widget.isDoctor ? prefs.getString('doctor_token') : prefs.getString('auth_token')) ??
          prefs.getString('auth_token') ??
          prefs.getString('doctor_token');
    }
    return token;
  }

  void _initConsultationData() {
    _resolveAppointmentDetails();
    _fetchChatMessages();
    _fetchDocuments();
    _fetchPrescriptions();
    _chatPollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) {
        _fetchChatMessages(isBackground: true);
      }
    });
  }

  Future<void> _resolveAppointmentDetails() async {
    final token = await _getToken();
    if (token == null || token.isEmpty) return;
    try {
      final res = await AppointmentService.getAppointmentById(
        appointmentId: widget.appointmentId,
        token: token,
      );
      if (res.success && res.appointment != null) {
        if (mounted) {
          setState(() {
            _resolvedAppointment = res.appointment;
            _resolvedUserId = res.appointment!.userId ?? _resolvedUserId;
            _resolvedDoctorId = res.appointment!.doctorId;
            _resolvedDoctorName = res.appointment!.doctorName;
            _resolvedPatientName = res.appointment!.patientName;
            _resolvedPatientMobile = res.appointment!.patientMobile;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _handleRemoteCallEnded() async {
    if (!mounted || _isEndingCall || _isCallEnded) return;
    _isCallEnded = true;
    _isEndingCall = true;
    _callDurationTimer?.cancel();
    _chatPollingTimer?.cancel();

    final token = await _getToken();
    if (widget.videoCallId != null && token != null) {
      try {
        await VideoCallService.endVideoCall(
          videoCallId: widget.videoCallId!,
          token: token,
        );
      } catch (_) {}
    }

    // Do NOT auto-complete the appointment when a call ends or is cancelled remotely.
    // The appointment must remain open so doctor or patient can reconnect, or doctor can manually mark it complete.
    try {
      await _callManager.endCall(widget.appointmentId);
    } catch (_) {}

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Call disconnected. Appointment remains active so you can reconnect.'),
        duration: Duration(seconds: 3),
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

    final token = await _getToken();

    if (token == null || token.isEmpty) {
      setState(() {
        _statusMessage = 'Authentication error: Not logged in. Please log in to join.';
      });
      return;
    }

    final String? userId = widget.isDoctor
        ? (_appState.currentDoctorProfile?.id ?? _appState.currentUser?.id)
        : _appState.currentUser?.id;

    await _callManager.startCall(
      appointmentId: widget.appointmentId,
      token: token,
      isDoctor: widget.isDoctor,
      userId: userId,
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

  Future<void> _handleEndCallDirectly({bool markCompleted = false}) async {
    if (_isEndingCall) return;

    setState(() {
      _isEndingCall = true;
      _isCallEnded = true;
    });

    _callDurationTimer?.cancel();
    _chatPollingTimer?.cancel();

    final token = await _getToken();

    if (widget.videoCallId != null && token != null) {
      try {
        await VideoCallService.endVideoCall(
          videoCallId: widget.videoCallId!,
          token: token,
        );
      } catch (e) {
        debugPrint('[VideoCallScreen] endVideoCall error: $e');
      }
    }

    if (markCompleted && widget.isDoctor && token != null && token.isNotEmpty) {
      try {
        await AppointmentService.completeDoctorAppointment(
          appointmentId: widget.appointmentId,
          token: token,
        );
        debugPrint('[VideoCallScreen] Marked appointment ${widget.appointmentId} as completed');
      } catch (e) {
        debugPrint('[VideoCallScreen] completeDoctorAppointment error: $e');
      }
    }

    await _callManager.endCall(widget.appointmentId);

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _showCompleteConsultationConfirmation() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF059669)),
            SizedBox(width: 8),
            Text('Complete Consultation', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Are you sure you want to mark this consultation as completed? This will officially close the consultation.',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Mark as Completed', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final token = await _getToken();
    if (token != null && token.isNotEmpty) {
      try {
        await AppointmentService.completeDoctorAppointment(
          appointmentId: widget.appointmentId,
          token: token,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Consultation officially marked as completed!'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      } catch (e) {
        debugPrint('[VideoCallScreen] completeDoctorAppointment error: $e');
      }
    }

    await _handleEndCallDirectly(markCompleted: true);
  }

  Future<void> _handleEndCall() async {
    if (_isEndingCall) return;

    if (widget.isDoctor) {
      final action = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.call_end_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text('End Consultation Call', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isMeetingExpired
                    ? 'The scheduled consultation time has expired.'
                    : 'Choose how you want to end this session:',
                style: const TextStyle(fontSize: 13, color: AppColors.textDark),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '• Leave Call Only:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F4C47)),
                    ),
                    const Text(
                      'Keeps appointment open so you or patient can reconnect if disconnected due to internet issue.',
                      style: TextStyle(fontSize: 11, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Mark as Completed:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF059669)),
                    ),
                    const Text(
                      'Marks this appointment as officially completed in the system.',
                      style: TextStyle(fontSize: 11, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'cancel'),
              child: const Text('Stay in Call', style: TextStyle(color: Colors.grey)),
            ),
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx, 'leave'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF0F4C47)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Leave Call Only', style: TextStyle(color: Color(0xFF0F4C47))),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, 'complete'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Mark Completed', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      if (action == null || action == 'cancel') return;

      // Manual cancellation / leaving call should NEVER complete automatically!
      // Only mark completed if the doctor EXPLICITLY chose 'Mark Completed'.
      final bool shouldMarkCompleted = (action == 'complete');
      await _handleEndCallDirectly(markCompleted: shouldMarkCompleted);
    } else {
      // Patient leaving call
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Leave Consultation Call?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          content: const Text(
            'Are you sure you want to leave the video call? You can reconnect if the doctor is still available.',
            style: TextStyle(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Leave Call', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirm != true) return;
      await _handleEndCallDirectly(markCompleted: false);
    }
  }

  // -------------------------------------------------------------
  // CHAT METHODS (With Instant Optimistic Update)
  // -------------------------------------------------------------
  Future<void> _fetchChatMessages({bool isBackground = false}) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) return;

    if (!isBackground && _chatMessages.isEmpty) {
      setState(() => _isLoadingChat = true);
    }

    try {
      final res = await ChatService.getMessages(
        appointmentId: widget.appointmentId,
        token: token,
      );

      if (!mounted) return;

      if (res.success) {
        // Preserve any pending optimistic messages that haven't arrived from server yet
        final pendingTempMessages = _chatMessages.where((m) => m.id.startsWith('temp_')).toList();
        final List<ChatMessageModel> mergedList = List.from(res.messages);

        for (final temp in pendingTempMessages) {
          final alreadyInServer = res.messages.any((m) =>
              m.senderType == temp.senderType &&
              m.message == temp.message);
          if (!alreadyInServer) {
            mergedList.add(temp);
          }
        }

        final hadNewMessages = mergedList.length > _chatMessages.length;
        setState(() {
          _chatMessages = mergedList;
          _isLoadingChat = false;
        });
        if (hadNewMessages || !isBackground) {
          _scrollToBottomChat();
        }
      } else {
        if (!isBackground) setState(() => _isLoadingChat = false);
      }
    } catch (_) {
      if (!isBackground && mounted) setState(() => _isLoadingChat = false);
    }
  }

  void _scrollToBottomChat() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handlePickChatAttachment() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'jpg', 'JPG',
          'jpeg', 'JPEG',
          'png', 'PNG',
          'webp', 'WEBP',
          'gif', 'GIF',
          'pdf', 'PDF',
          'mp4', 'MP4',
          'mov', 'MOV',
          'avi', 'AVI',
          'webm', 'WEBM',
        ],
      );
      if (result != null && result.files.isNotEmpty && result.files.single.path != null) {
        setState(() {
          _chatAttachmentPath = result.files.single.path;
          _chatAttachmentName = result.files.single.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File selection failed: $e')),
        );
      }
    }
  }

  Future<void> _handleSendChatMessage() async {
    final text = _chatMsgController.text.trim();
    if ((text.isEmpty && _chatAttachmentPath == null) || _isSendingChat) return;

    final token = await _getToken();
    if (token == null || token.isEmpty) return;

    final filePathToSend = _chatAttachmentPath;
    final fileNameToSend = _chatAttachmentName;
    final messageText = text.isNotEmpty ? text : (_chatAttachmentName ?? 'Attachment');

    // 1. Instant Optimistic UI Update: Clear input and show message immediately
    _chatMsgController.clear();
    final String tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final currentUserId = widget.isDoctor
        ? (_appState.currentDoctorProfile?.id ?? _appState.currentUser?.id ?? 'doctor')
        : (_appState.currentUser?.id ?? 'user');

    final optimisticMsg = ChatMessageModel(
      id: tempId,
      appointmentId: widget.appointmentId,
      senderId: currentUserId,
      senderType: widget.isDoctor ? 'doctor' : 'user',
      message: messageText,
      isRead: false,
      createdAt: DateTime.now().toIso8601String(),
      fileUrl: filePathToSend,
      fileName: fileNameToSend,
    );

    setState(() {
      _chatMessages.add(optimisticMsg);
      _isSendingChat = true;
      _chatAttachmentPath = null;
      _chatAttachmentName = null;
    });

    _scrollToBottomChat();

    // 2. Perform background API call
    final res = await ChatService.sendMessageWithAttachment(
      appointmentId: widget.appointmentId,
      message: messageText,
      filePath: filePathToSend,
      fileName: fileNameToSend,
      token: token,
    );

    if (!mounted) return;

    setState(() => _isSendingChat = false);

    if (res.success) {
      if (res.data != null) {
        final idx = _chatMessages.indexWhere((m) => m.id == tempId);
        if (idx != -1) {
          setState(() {
            _chatMessages[idx] = res.data!;
          });
        }
      }
      _fetchChatMessages(isBackground: true);
    } else {
      // Revert optimistic message on failure
      setState(() {
        _chatMessages.removeWhere((m) => m.id == tempId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message ?? 'Failed to send message'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _viewImagePreview(String urlOrPath, {required bool isLocal, required String title}) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: InteractiveViewer(
                      maxScale: 4.0,
                      child: isLocal
                          ? Image.file(File(urlOrPath), fit: BoxFit.contain)
                          : Image.network(
                              urlOrPath,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Text('Failed to load image', style: TextStyle(color: Colors.white70)),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  void _viewDocument(ConsultationDocumentModel doc) {
    final fileName = doc.fileName ?? doc.fileUrl;
    final isImage = fileName.toLowerCase().endsWith('.png') ||
        fileName.toLowerCase().endsWith('.jpg') ||
        fileName.toLowerCase().endsWith('.jpeg') ||
        fileName.toLowerCase().endsWith('.webp') ||
        (doc.fileType ?? '').contains('image');

    if (isImage && doc.fileUrl.isNotEmpty) {
      _viewImagePreview(doc.fileUrl, isLocal: false, title: doc.description ?? doc.fileName ?? 'Document Preview');
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.insert_drive_file_rounded, color: Color(0xFF0F4C47)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                doc.description ?? 'Consultation Document',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('File Name: ${doc.fileName ?? "Document"}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            if (doc.description != null && doc.description!.isNotEmpty)
              Text('Description: ${doc.description}', style: const TextStyle(fontSize: 12, color: Colors.black87)),
            const SizedBox(height: 6),
            Text('Uploaded: ${doc.formattedDate}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            if (doc.uploadedBy != null)
              Text('By: ${doc.uploadedBy}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Color(0xFF0F4C47))),
          ),
        ],
      ),
    );
  }


  // -------------------------------------------------------------
  // ISSUE PRESCRIPTION METHODS (Doctor Only)
  // -------------------------------------------------------------
  void _onSearchMedicationChanged(String query) {
    if (query.trim().isEmpty) {
      setState(() => _filteredSuggestions = []);
      return;
    }
    final q = query.toLowerCase().trim();
    setState(() {
      _filteredSuggestions = _suggestedMeds.where((m) => m.toLowerCase().contains(q)).toList();
    });
  }

  void _addMedication(String medName) {
    setState(() {
      _rxMedications.add({
        'name': medName,
        'dosageForm': 'Tablet',
        'dosage': '1 Tab',
        'frequency': '1-0-1',
        'duration': '5 days',
        'timing': 'After meals',
        'instructions': 'Take with warm water',
      });
      _medSearchController.clear();
      _filteredSuggestions = [];
    });
  }

  Future<void> _handleSignAndSendPrescription() async {
    if (_isSubmittingRx) return;

    if (_rxMedications.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one medication before sending.')),
      );
      return;
    }

    final token = await _getToken();
    if (token == null || token.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Doctor token missing. Please log in.')),
        );
      }
      return;
    }

    final targetUserId = _resolvedUserId ?? 'patient_user';

    setState(() => _isSubmittingRx = true);

    List<Map<String, dynamic>> medsPayload = _rxMedications.map((m) {
      return {
        "name": m['name'] ?? 'Medication',
        "strength": m['dosage'] ?? '',
        "dosageForm": m['dosageForm'] ?? 'Tablet',
        "dosage": m['dosage'] ?? '1 Tab',
        "frequency": m['frequency'] ?? '1-0-1',
        "duration": m['duration'] ?? '5 days',
        "timing": m['timing'] ?? 'After meals',
        "instructions": m['instructions'] ?? '',
        "quantity": 30,
        "refillable": false,
      };
    }).toList();

    final res = await EPrescriptionService.createPrescription(
      appointmentId: widget.appointmentId,
      userId: targetUserId,
      diagnosis: _rxDiagnosisController.text.trim().isNotEmpty ? _rxDiagnosisController.text.trim() : 'Teleconsultation',
      medications: medsPayload,
      generalInstructions: _rxGeneralInstructionsController.text.trim(),
      token: token,
    );

    if (!mounted) return;

    setState(() => _isSubmittingRx = false);

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prescription signed and issued successfully!'),
          backgroundColor: Color(0xFF0F4C47),
        ),
      );
      setState(() {
        _rxMedications.clear();
        _rxGeneralInstructionsController.clear();
        _activeTool = 'View Prescription';
      });
      _fetchPrescriptions();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Failed to issue prescription'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // -------------------------------------------------------------
  // VIEW PRESCRIPTION METHODS
  // -------------------------------------------------------------
  Future<void> _fetchPrescriptions() async {
    final token = await _getToken();
    if (token == null || token.isEmpty) return;

    setState(() => _isLoadingPrescriptions = true);

    try {
      if (widget.isDoctor) {
        final res = await EPrescriptionService.getDoctorPrescriptions(token: token, limit: 30);
        if (mounted && res['success'] == true && res['prescriptions'] is List) {
          final list = List<Map<String, dynamic>>.from(res['prescriptions']);
          final currentSessionList = list.where((rx) {
            final apptId = (rx['appointmentId'] ?? rx['appointment_id'] ?? rx['appointment']?['id'])?.toString();
            return apptId == widget.appointmentId;
          }).toList();
          setState(() {
            _prescriptions = currentSessionList.isNotEmpty ? currentSessionList : list.take(5).toList();
            _isLoadingPrescriptions = false;
          });
          return;
        }
      } else {
        final res = await EPrescriptionService.getPatientPrescriptions(token: token, limit: 30);
        if (mounted && res['success'] == true && res['prescriptions'] is List) {
          final list = List<Map<String, dynamic>>.from(res['prescriptions']);
          final currentSessionList = list.where((rx) {
            final apptId = (rx['appointmentId'] ?? rx['appointment_id'] ?? rx['appointment']?['id'])?.toString();
            return apptId == widget.appointmentId;
          }).toList();
          setState(() {
            _prescriptions = currentSessionList.isNotEmpty ? currentSessionList : list.take(5).toList();
            _isLoadingPrescriptions = false;
          });
          return;
        }
      }
      if (mounted) setState(() => _isLoadingPrescriptions = false);
    } catch (_) {
      if (mounted) setState(() => _isLoadingPrescriptions = false);
    }
  }

  // -------------------------------------------------------------
  // UPLOAD DOCUMENTS METHODS
  // -------------------------------------------------------------
  Future<void> _fetchDocuments() async {
    final token = await _getToken();
    if (token == null || token.isEmpty) return;

    setState(() => _isLoadingDocuments = true);

    try {
      final docs = await ChatService.getDocuments(
        appointmentId: widget.appointmentId,
        token: token,
      );
      if (mounted) {
        setState(() {
          _documents = docs;
          _isLoadingDocuments = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingDocuments = false);
    }
  }

  Future<void> _handlePickAndUploadDocument() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf', 'PDF',
          'jpg', 'JPG',
          'jpeg', 'JPEG',
          'png', 'PNG',
          'webp', 'WEBP',
          'gif', 'GIF',
          'mp4', 'MP4',
          'mov', 'MOV',
          'avi', 'AVI',
          'webm', 'WEBM',
          'doc', 'DOC',
          'docx', 'DOCX',
        ],
      );

      if (result == null || result.files.isEmpty || result.files.single.path == null) {
        return;
      }

      final file = result.files.single;
      final filePath = file.path!;
      final defaultDesc = widget.isDoctor ? 'Prescription' : (file.name.isNotEmpty ? file.name : 'Consultation Document');

      if (!mounted) return;

      final descController = TextEditingController(text: defaultDesc);

      final shouldUpload = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.upload_file_rounded, color: Color(0xFF0F4C47)),
              SizedBox(width: 8),
              Text('Upload Document', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Selected: ${file.name}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 14),
              const Text('Document Description', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 6),
              TextField(
                controller: descController,
                decoration: InputDecoration(
                  hintText: 'e.g. Blood test report, Prescription',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F4C47),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Upload Now', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (shouldUpload != true) return;

      final token = await _getToken();
      if (token == null || token.isEmpty) return;

      setState(() => _isUploadingDocument = true);

      final res = await ChatService.uploadDocument(
        appointmentId: widget.appointmentId,
        description: descController.text.trim().isNotEmpty ? descController.text.trim() : defaultDesc,
        filePath: filePath,
        fileName: file.name,
        token: token,
      );

      if (!mounted) return;

      setState(() => _isUploadingDocument = false);

      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document uploaded successfully!'),
            backgroundColor: Color(0xFF0F4C47),
          ),
        );
        _fetchDocuments();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Failed to upload document'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingDocument = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading document: $e')),
        );
      }
    }
  }

  // -------------------------------------------------------------
  // CONSULTATION HISTORY METHODS
  // Strictly filter completed consultations between this doctor & patient
  // -------------------------------------------------------------
  Future<void> _fetchConsultationHistory() async {
    final token = await _getToken();
    if (token == null || token.isEmpty) return;

    setState(() => _isLoadingHistory = true);

    try {
      final res = widget.isDoctor
          ? await AppointmentService.getDoctorAppointments(token: token, status: 'completed', limit: 100)
          : await AppointmentService.getMyAppointments(token: token, status: 'completed', limit: 100);

      if (!mounted) return;

      if (res.success) {
        // Strict filter:
        // 1. Must be status == completed
        // 2. Must not be the current ongoing session
        // 3. Must be between THIS particular doctor and THIS particular patient
        final filtered = res.appointments.where((item) {
          if (item.status.toLowerCase() != 'completed') return false;
          if (item.id == widget.appointmentId) return false;

          if (widget.isDoctor) {
            final targetUserId = _resolvedUserId ?? widget.patientUserId;
            if (targetUserId != null && item.userId != null && item.userId == targetUserId) {
              return true;
            }
            if (_resolvedPatientMobile != null && item.patientMobile != null && item.patientMobile == _resolvedPatientMobile) {
              return true;
            }
            final targetName = (_resolvedPatientName ?? widget.peerName).trim().toLowerCase();
            return item.patientName.trim().toLowerCase() == targetName;
          } else {
            if (_resolvedDoctorId != null && item.doctorId != null && item.doctorId == _resolvedDoctorId) {
              return true;
            }
            final peerClean = (_resolvedDoctorName ?? widget.peerName).replaceAll('Dr.', '').replaceAll('Dr', '').trim().toLowerCase();
            final itemDocClean = (item.doctorName ?? '').replaceAll('Dr.', '').replaceAll('Dr', '').trim().toLowerCase();
            return itemDocClean.isNotEmpty && (itemDocClean == peerClean || itemDocClean.contains(peerClean) || peerClean.contains(itemDocClean));
          }
        }).toList();

        setState(() {
          _historyAppointments = filtered;
          _isLoadingHistory = false;
        });
      } else {
        setState(() => _isLoadingHistory = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  // -------------------------------------------------------------
  // MAIN BUILD
  // -------------------------------------------------------------
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
        backgroundColor: const Color(0xFFF1F5F9),
        body: SafeArea(
          child: _isVideoMinimized ? _buildMinimizedLayout() : _buildFullscreenLayout(),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // FULLSCREEN VIDEO LAYOUT
  // -------------------------------------------------------------
  Widget _buildFullscreenLayout() {
    return Stack(
      children: [
        // Remote Video View (Fullscreen)
        if (_callManager.remoteRenderer.textureId != null)
          Positioned.fill(
            child: RTCVideoView(
              _callManager.remoteRenderer,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            ),
          ),

        // Waiting / Audio-Only Overlay
        if (!_callManager.isPeerConnected || !_callManager.hasRemoteVideo)
          Positioned.fill(
            child: _buildAudioWaitingOverlay(),
          ),

        // Local Video Preview (PiP Top-Right Window)
        Positioned(
          right: 16,
          top: 16,
          child: _buildLocalVideoPip(width: 100, height: 140),
        ),

        // Top Status Bar (Overlay)
        Positioned(
          left: 16,
          top: 16,
          child: _buildLiveSessionPill(),
        ),

        // Bottom Bar Container (Video Controls + Tools Switcher)
        Positioned(
          left: 0,
          right: 0,
          bottom: 12,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCallControlsBar(),
              const SizedBox(height: 10),
              _buildConsultationToolsHeaderBar(isEmbeddedInFull: true),
            ],
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // MINIMIZED VIDEO LAYOUT
  // -------------------------------------------------------------
  Widget _buildMinimizedLayout() {
    return Column(
      children: [
        // Top Minimized Video Box
        Container(
          height: 215,
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(10, 8, 10, 6),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // Remote Video
                if (_callManager.remoteRenderer.textureId != null)
                  Positioned.fill(
                    child: RTCVideoView(
                      _callManager.remoteRenderer,
                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    ),
                  ),

                // Audio waiting placeholder if not video
                if (!_callManager.isPeerConnected || !_callManager.hasRemoteVideo)
                  Positioned.fill(
                    child: Container(
                      color: const Color(0xFF0F172A),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.white.withValues(alpha: 0.1),
                            backgroundImage: (widget.peerAvatar != null && widget.peerAvatar!.startsWith('http'))
                                ? NetworkImage(widget.peerAvatar!) as ImageProvider
                                : const AssetImage('assets/d1.jpg'),
                            onBackgroundImageError: (_, __) {},
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.peerName,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _callManager.isPeerConnected ? 'Connected (Audio Only)' : 'Waiting for connection...',
                            style: const TextStyle(fontSize: 11, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Local video PiP in bottom-right
                Positioned(
                  right: 10,
                  bottom: 44,
                  child: _buildLocalVideoPip(width: 65, height: 85),
                ),

                // Top Pills: Live session on left, Maximize & End Call on right
                Positioned(
                  left: 10,
                  top: 10,
                  child: _buildLiveSessionPill(),
                ),

                Positioned(
                  right: 10,
                  top: 10,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Maximize Button
                      GestureDetector(
                        onTap: () {
                          setState(() => _isVideoMinimized = false);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // End Call Button
                      GestureDetector(
                        onTap: _handleEndCall,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.call_end_rounded, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text('End Call', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom Call Controls (Mic, Cam, Switch, Speaker)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 7,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildCompactControlBtn(
                        icon: _callManager.isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                        color: _callManager.isMuted ? Colors.redAccent : Colors.white,
                        bgColor: _callManager.isMuted ? Colors.red.withValues(alpha: 0.3) : Colors.black54,
                        onTap: () {
                          setState(() => _callManager.toggleMute());
                        },
                      ),
                      const SizedBox(width: 14),
                      _buildCompactControlBtn(
                        icon: _callManager.isVideoOff ? Icons.videocam_off_rounded : Icons.videocam_rounded,
                        color: _callManager.isVideoOff ? Colors.redAccent : Colors.white,
                        bgColor: _callManager.isVideoOff ? Colors.red.withValues(alpha: 0.3) : Colors.black54,
                        onTap: () {
                          setState(() => _callManager.toggleCamera());
                        },
                      ),
                      const SizedBox(width: 14),
                      _buildCompactControlBtn(
                        icon: Icons.cameraswitch_rounded,
                        color: Colors.white,
                        bgColor: Colors.black54,
                        onTap: () async {
                          await _callManager.switchCamera();
                          setState(() {});
                        },
                      ),
                      const SizedBox(width: 14),
                      _buildCompactControlBtn(
                        icon: _isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                        color: _isSpeakerOn ? Colors.greenAccent : Colors.white70,
                        bgColor: Colors.black54,
                        onTap: () {
                          setState(() {
                            _isSpeakerOn = !_isSpeakerOn;
                            Helper.setSpeakerphoneOn(_isSpeakerOn);
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Consultation Actions & Tools Bar
        _buildConsultationToolsHeaderBar(isEmbeddedInFull: false),

        // Active Module View
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(10, 6, 10, 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _buildActiveModuleContent(),
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // CONSULTATION ACTIONS & TOOLS BAR (Matching screenshots 1-5)
  // -------------------------------------------------------------
  Widget _buildConsultationToolsHeaderBar({required bool isEmbeddedInFull}) {
    final tools = [
      {'id': 'Chat', 'title': 'Chat', 'icon': Icons.chat_bubble_outline_rounded},
      if (widget.isDoctor)
        {'id': 'Issue Prescription', 'title': 'Issue Prescription', 'icon': Icons.note_add_outlined},
      {'id': 'View Prescription', 'title': 'View Prescription', 'icon': Icons.receipt_long_outlined},
      {'id': 'Upload Documents', 'title': 'Upload Documents', 'icon': Icons.upload_file_outlined},
      {'id': 'Consultation History', 'title': 'Consultation History', 'icon': Icons.history_rounded},
    ];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: isEmbeddedInFull ? 12 : 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isEmbeddedInFull ? const Color(0xFF1E293B).withValues(alpha: 0.95) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isEmbeddedInFull ? Colors.white12 : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row with Expanded title to prevent overflow on any screen
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        'CONSULTATION TOOLS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                          color: isEmbeddedInFull ? Colors.white70 : const Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isMeetingExpired) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Time Expired',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.brown),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.isDoctor) ...[
                GestureDetector(
                  onTap: _showCompleteConsultationConfirmation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded, color: Colors.white, size: 12),
                        SizedBox(width: 4),
                        Text(
                          'Complete',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isEmbeddedInFull ? const Color(0xFF0F4C47) : const Color(0xFFE6F7F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF137E75).withValues(alpha: 0.3)),
                ),
                child: Text(
                  'Active: $_activeTool',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isEmbeddedInFull ? Colors.white : const Color(0xFF0F4C47),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Tool Buttons List with professional styling, clear contrast, and smooth scroll
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: tools.map((tool) {
                final isSelected = _activeTool == tool['id'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        setState(() {
                          _activeTool = tool['id'] as String;
                          _isVideoMinimized = true; // Auto minimize video when any tool is selected
                        });
                        if (_activeTool == 'Consultation History') {
                          _fetchConsultationHistory();
                        } else if (_activeTool == 'View Prescription') {
                          _fetchPrescriptions();
                        } else if (_activeTool == 'Upload Documents') {
                          _fetchDocuments();
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF0F4C47)
                              : (isEmbeddedInFull ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFF8FAFC)),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF0F4C47)
                                : (isEmbeddedInFull ? Colors.white24 : const Color(0xFFCBD5E1)),
                            width: 1.2,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF0F4C47).withValues(alpha: 0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              tool['icon'] as IconData,
                              size: 16,
                              color: isSelected ? Colors.white : (isEmbeddedInFull ? Colors.white : const Color(0xFF334155)),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              tool['title'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                color: isSelected ? Colors.white : (isEmbeddedInFull ? Colors.white : const Color(0xFF1E293B)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // ACTIVE MODULE SELECTOR
  // -------------------------------------------------------------
  Widget _buildActiveModuleContent() {
    switch (_activeTool) {
      case 'Chat':
        return _buildChatModule();
      case 'Issue Prescription':
        return widget.isDoctor ? _buildIssuePrescriptionModule() : _buildChatModule();
      case 'View Prescription':
        return _buildViewPrescriptionModule();
      case 'Upload Documents':
        return _buildUploadDocumentsModule();
      case 'Consultation History':
        return _buildConsultationHistoryModule();
      default:
        return _buildChatModule();
    }
  }

  // -------------------------------------------------------------
  // 1. CHAT MODULE (Matching screenshot 1)
  // -------------------------------------------------------------
  Widget _buildChatModule() {
    return Column(
      children: [
        // Module Title Header (Wrapped in Expanded to prevent overflow)
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Consultation Chat',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F4C47)),
                    ),
                    Text(
                      'Chatting with: ${widget.peerName}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20, color: Color(0xFF0F4C47)),
                onPressed: () => _fetchChatMessages(),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),

        // Consultation Notice Banner (matching screenshot 1)
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF0F4C47),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.amberAccent, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Consultation Session Notice: Real-time encrypted communication active. Share reports, ask queries, or send messages during this live call.',
                  style: TextStyle(color: Colors.white, fontSize: 11, height: 1.3),
                ),
              ),
            ],
          ),
        ),

        // Messages List
        Expanded(
          child: _isLoadingChat
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F4C47)))
              : _chatMessages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded, size: 36, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          const Text('No messages yet. Send a message or share files below.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _chatScrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      itemCount: _chatMessages.length,
                      itemBuilder: (context, index) {
                        final msg = _chatMessages[index];
                        final isMe = (widget.isDoctor && msg.senderType == 'doctor') ||
                            (!widget.isDoctor && msg.senderType != 'doctor');
                        return _buildChatBubble(msg, isMe);
                      },
                    ),
        ),

        // Attachment Preview Tag if picked
        if (_chatAttachmentPath != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: const Color(0xFFE6F7F2),
            child: Row(
              children: [
                const Icon(Icons.attach_file, size: 16, color: Color(0xFF0F4C47)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _chatAttachmentName ?? 'Attachment ready',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0F4C47)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _chatAttachmentPath = null;
                      _chatAttachmentName = null;
                    });
                  },
                  child: const Icon(Icons.close_rounded, size: 16, color: Colors.grey),
                ),
              ],
            ),
          ),

        // Chat Input Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Row(
            children: [
              // Attachment Button
              IconButton(
                icon: const Icon(Icons.attach_file_rounded, color: Color(0xFF64748B)),
                onPressed: _handlePickChatAttachment,
              ),
              Expanded(
                child: TextField(
                  controller: _chatMsgController,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _handleSendChatMessage(),
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Send Button
              GestureDetector(
                onTap: _handleSendChatMessage,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F4C47),
                    shape: BoxShape.circle,
                  ),
                  child: _isSendingChat
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChatBubble(ChatMessageModel msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF0F4C47) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isMe ? 14 : 2),
            bottomRight: Radius.circular(isMe ? 2 : 14),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (msg.fileUrl != null && msg.fileUrl!.isNotEmpty) ...[
              Builder(
                builder: (context) {
                  final isImg = (msg.fileName ?? msg.fileUrl!).toLowerCase().endsWith('.png') ||
                      (msg.fileName ?? msg.fileUrl!).toLowerCase().endsWith('.jpg') ||
                      (msg.fileName ?? msg.fileUrl!).toLowerCase().endsWith('.jpeg') ||
                      (msg.fileName ?? msg.fileUrl!).toLowerCase().endsWith('.webp') ||
                      (msg.fileType ?? '').contains('image');
                  final isLocal = !msg.fileUrl!.startsWith('http');

                  if (isImg) {
                    return GestureDetector(
                      onTap: () => _viewImagePreview(
                        msg.fileUrl!,
                        isLocal: isLocal,
                        title: msg.fileName ?? 'Image Preview',
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        constraints: const BoxConstraints(maxHeight: 180, maxWidth: 220),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: isLocal
                              ? Image.file(File(msg.fileUrl!), fit: BoxFit.cover)
                              : Image.network(
                                  msg.fileUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    padding: const EdgeInsets.all(8),
                                    color: Colors.grey.shade200,
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.image, size: 16, color: Colors.grey),
                                        SizedBox(width: 4),
                                        Text('Image Attachment', style: TextStyle(fontSize: 11, color: Colors.black87)),
                                      ],
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    );
                  }

                  return Container(
                    padding: const EdgeInsets.all(6),
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.white.withValues(alpha: 0.15) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.file_present_rounded,
                          size: 16,
                          color: isMe ? Colors.white : const Color(0xFF0F4C47),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            msg.fileName ?? 'Attached File',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isMe ? Colors.white : Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
            Text(
              msg.message,
              style: TextStyle(
                fontSize: 13,
                color: isMe ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              msg.formattedTime,
              style: TextStyle(
                fontSize: 9,
                color: isMe ? Colors.white70 : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 2. ISSUE PRESCRIPTION MODULE (Doctor Only - Matching screenshot 2)
  // -------------------------------------------------------------
  Widget _buildIssuePrescriptionModule() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Expanded to prevent overflow
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Prescription Module',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F4C47)),
                    ),
                    Text(
                      'Active Patient: ${widget.peerName}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F7F2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Doctor Rx', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0F4C47))),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Search Medication
          const Text(
            'Search Medication',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _medSearchController,
            onChanged: _onSearchMedicationChanged,
            decoration: InputDecoration(
              hintText: 'Start typing (e.g. Omeprazole...)',
              hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF64748B)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
            ),
          ),

          // Autocomplete Suggestions
          if (_filteredSuggestions.isNotEmpty || _medSearchController.text.trim().isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.only(top: 4),
              constraints: const BoxConstraints(maxHeight: 140),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
                ],
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  if (_medSearchController.text.trim().isNotEmpty && !_suggestedMeds.contains(_medSearchController.text.trim()))
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.add_circle_outline, size: 18, color: Color(0xFF0F4C47)),
                      title: Text('Add "${_medSearchController.text.trim()}"', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      onTap: () => _addMedication(_medSearchController.text.trim()),
                    ),
                  ..._filteredSuggestions.map(
                    (med) => ListTile(
                      dense: true,
                      leading: const Icon(Icons.medication_outlined, size: 18, color: Color(0xFF64748B)),
                      title: Text(med, style: const TextStyle(fontSize: 12)),
                      onTap: () => _addMedication(med),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),

          // CURRENT SELECTION Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'CURRENT SELECTION',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Color(0xFF475569)),
              ),
              Text(
                '${_rxMedications.length} items added',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Current Selection Box or List
          if (_rxMedications.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
              ),
              child: Column(
                children: [
                  Icon(Icons.receipt_outlined, size: 28, color: Colors.grey.shade400),
                  const SizedBox(height: 6),
                  const Text(
                    'No medications added yet. Search medicine above to prescribe.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            )
          else
            Column(
              children: _rxMedications.asMap().entries.map((entry) {
                final idx = entry.key;
                final med = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              med['name'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F4C47)),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                            onPressed: () {
                              setState(() => _rxMedications.removeAt(idx));
                            },
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: med['dosage'] ?? '1 Tab',
                              style: const TextStyle(fontSize: 11),
                              decoration: const InputDecoration(labelText: 'Dosage', isDense: true),
                              onChanged: (val) => med['dosage'] = val,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              initialValue: med['frequency'] ?? '1-0-1',
                              style: const TextStyle(fontSize: 11),
                              decoration: const InputDecoration(labelText: 'Frequency', isDense: true),
                              onChanged: (val) => med['frequency'] = val,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              initialValue: med['duration'] ?? '5 days',
                              style: const TextStyle(fontSize: 11),
                              decoration: const InputDecoration(labelText: 'Duration', isDense: true),
                              onChanged: (val) => med['duration'] = val,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 16),

          // General Instructions
          const Text(
            'General Instructions',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _rxGeneralInstructionsController,
            maxLines: 3,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Additional instructions for patient...',
              hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              contentPadding: const EdgeInsets.all(12),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
            ),
          ),
          const SizedBox(height: 18),

          // Buttons: SAVE DRAFT & SIGN & SEND
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Color(0xFF0F4C47)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Prescription draft saved locally.')),
                    );
                  },
                  child: const Text('SAVE DRAFT', style: TextStyle(color: Color(0xFF0F4C47), fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F4C47),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.shield_outlined, size: 16, color: Colors.white),
                  label: _isSubmittingRx
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('SIGN & SEND', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  onPressed: _handleSignAndSendPrescription,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 3. VIEW PRESCRIPTION MODULE (Matching screenshot 3)
  // -------------------------------------------------------------
  Widget _buildViewPrescriptionModule() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Patient Prescriptions',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F4C47)),
                    ),
                    Text(
                      'Prescribed medicines for: ${widget.peerName}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20, color: Color(0xFF0F4C47)),
                onPressed: _fetchPrescriptions,
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),
        Expanded(
          child: _isLoadingPrescriptions
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F4C47)))
              : _prescriptions.isEmpty
                  ? Center(
                      child: Container(
                        margin: const EdgeInsets.all(20),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.receipt_long_rounded, size: 36, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            const Text(
                              'No prescriptions recorded yet for this session.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _prescriptions.length,
                      itemBuilder: (context, idx) {
                        final rx = _prescriptions[idx];
                        final meds = (rx['medications'] is List) ? rx['medications'] as List : [];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    rx['prescriptionNumber'] ?? 'Rx #${rx['id']?.toString().substring(0, 8) ?? 'Record'}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F4C47)),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE6F7F2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      (rx['status'] ?? 'Issued').toString().toUpperCase(),
                                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF0F4C47)),
                                    ),
                                  ),
                                ],
                              ),
                              if (rx['diagnosis'] != null) ...[
                                const SizedBox(height: 4),
                                Text('Diagnosis: ${rx['diagnosis']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                              const SizedBox(height: 8),
                              ...meds.map((m) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.circle, size: 6, color: Color(0xFF0F4C47)),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            '${m['name']} - ${m['dosage'] ?? ''} (${m['frequency'] ?? ''}, ${m['duration'] ?? ''})',
                                            style: const TextStyle(fontSize: 11, color: Color(0xFF334155)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                              if (rx['generalInstructions'] != null && rx['generalInstructions'].toString().isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text('Instructions: ${rx['generalInstructions']}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // 4. UPLOAD DOCUMENTS MODULE (Matching screenshot 4)
  // -------------------------------------------------------------
  Widget _buildUploadDocumentsModule() {
    return Column(
      children: [
        // Header with Expanded to prevent overflow
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Prescriptions & Medical Documents',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F4C47)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Consultation files for: ${widget.peerName}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20, color: Color(0xFF0F4C47)),
                onPressed: _fetchDocuments,
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Upload Tap Box (Matching screenshot 4)
                GestureDetector(
                  onTap: _isUploadingDocument ? null : _handlePickAndUploadDocument,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE6F7F2),
                            shape: BoxShape.circle,
                          ),
                          child: _isUploadingDocument
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0F4C47)))
                              : const Icon(Icons.cloud_upload_outlined, size: 26, color: Color(0xFF0F4C47)),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Click to upload prescription or clinical report',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F4C47)),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Supports PDF, JPG, PNG, Medical Scans (Max 50MB)',
                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Documents List Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'CONSULTATION DOCUMENTS (${_documents.length})',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Color(0xFF475569)),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFF0F4C47),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      onPressed: _fetchDocuments,
                      child: const Text('Refresh', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Documents List or Empty placeholder
                if (_isLoadingDocuments)
                  const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: Color(0xFF0F4C47))))
                else if (_documents.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.description_outlined, size: 28, color: Colors.grey.shade400),
                        const SizedBox(height: 6),
                        const Text(
                          'No documents attached for this consultation yet. Click above to upload.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    children: _documents.map((doc) {
                      final isPdf = (doc.fileName ?? doc.fileUrl).toLowerCase().endsWith('.pdf') || (doc.fileType ?? '').contains('pdf');
                      final isImg = (doc.fileName ?? doc.fileUrl).toLowerCase().endsWith('.png') ||
                          (doc.fileName ?? doc.fileUrl).toLowerCase().endsWith('.jpg') ||
                          (doc.fileName ?? doc.fileUrl).toLowerCase().endsWith('.jpeg') ||
                          (doc.fileName ?? doc.fileUrl).toLowerCase().endsWith('.webp') ||
                          (doc.fileType ?? '').contains('image');
                      return InkWell(
                        onTap: () => _viewDocument(doc),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isPdf
                                      ? Colors.red.shade50
                                      : isImg
                                          ? const Color(0xFFE0F2FE)
                                          : const Color(0xFFE6F7F2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  isPdf
                                      ? Icons.picture_as_pdf_rounded
                                      : isImg
                                          ? Icons.image_rounded
                                          : Icons.insert_drive_file_rounded,
                                  color: isPdf
                                      ? Colors.red
                                      : isImg
                                          ? const Color(0xFF0284C7)
                                          : const Color(0xFF0F4C47),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      doc.description?.isNotEmpty == true ? doc.description! : (doc.fileName ?? 'Consultation File'),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E293B)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${doc.uploadedBy != null ? "By ${doc.uploadedBy} • " : ""}${doc.formattedDate}',
                                      style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.visibility_outlined, size: 18, color: Color(0xFF0F4C47)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // 5. CONSULTATION HISTORY MODULE (Matching screenshot 5)
  // ONLY shows completed consultations between this doctor & patient
  // -------------------------------------------------------------
  Widget _buildConsultationHistoryModule() {
    return Column(
      children: [
        // Header with Expanded to prevent overflow
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Consultation History',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F4C47)),
                    ),
                    Text(
                      'Completed visits: ${widget.peerName}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20, color: Color(0xFF0F4C47)),
                onPressed: _fetchConsultationHistory,
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),

        // Completed filter indicator badge
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(14, 8, 14, 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFE6F7F2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF0F4C47).withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              const Icon(Icons.verified_rounded, size: 15, color: Color(0xFF0F4C47)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${_historyAppointments.length} Completed Visit${_historyAppointments.length == 1 ? '' : 's'} with ${widget.peerName}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0F4C47)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: _isLoadingHistory
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F4C47)))
              : _historyAppointments.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.history_rounded, size: 36, color: Colors.grey.shade400),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'No past completed consultations found',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155), fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Completed visits between you and ${widget.peerName} will appear here.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _historyAppointments.length,
                      itemBuilder: (context, idx) {
                        final item = _historyAppointments[idx];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today_rounded, size: 13, color: Color(0xFF64748B)),
                                      const SizedBox(width: 6),
                                      Text(
                                        item.appointmentDate,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E293B)),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.videocam_rounded, size: 12, color: Color(0xFF2563EB)),
                                        SizedBox(width: 4),
                                        Text('Video Consult', style: TextStyle(fontSize: 10, color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                widget.isDoctor
                                    ? 'Patient: ${item.patientName.isNotEmpty ? item.patientName : "Patient"}'
                                    : 'Doctor: ${item.doctorName ?? "Assigned Specialist"}',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE6F7F2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      size: 12,
                                      color: Color(0xFF0F4C47),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'COMPLETED',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F4C47),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // REUSABLE SUB-WIDGETS (Video overlay, controls, PIP)
  // -------------------------------------------------------------
  Widget _buildLiveSessionPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _callManager.isPeerConnected ? Colors.greenAccent : Colors.amber,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _callManager.isPeerConnected ? 'LIVE SESSION  ⏱ $_formattedDuration' : 'Calling...',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildLocalVideoPip({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
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
                    size: width * 0.3,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildAudioWaitingOverlay() {
    return Container(
      color: const Color(0xFF0F172A),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 46,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            backgroundImage: (widget.peerAvatar != null && widget.peerAvatar!.startsWith('http'))
                ? NetworkImage(widget.peerAvatar!) as ImageProvider
                : const AssetImage('assets/d1.jpg'),
            onBackgroundImageError: (_, __) {},
          ),
          const SizedBox(height: 14),
          Text(
            widget.peerName,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            widget.peerSubtitle ?? (widget.isDoctor ? 'Patient' : 'Ayush Doctor'),
            style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),
          if (!_callManager.isPeerConnected) ...[
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
            const SizedBox(height: 10),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.mic, color: Colors.green, size: 14),
                  SizedBox(width: 6),
                  Text(
                    'Connected (Audio Only)',
                    style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallControlsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
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
              setState(() => _callManager.toggleMute());
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
              setState(() => _callManager.toggleCamera());
            },
          ),
          // Switch Camera
          IconButton(
            icon: const Icon(Icons.cameraswitch_rounded, color: Colors.white, size: 24),
            onPressed: () async {
              await _callManager.switchCamera();
              setState(() {});
            },
          ),
          // Speaker Toggle
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
          // End Call
          GestureDetector(
            onTap: _handleEndCall,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              child: _isEndingCall
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.call_end_rounded, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactControlBtn({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Icon(icon, color: color, size: 17),
      ),
    );
  }
}
