import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_state.dart';
import '../models/chat_model.dart';

class ChatScreen extends StatefulWidget {
  final String appointmentId;
  final String recipientName;
  final String? recipientSubtitle;
  final String? recipientAvatar;

  const ChatScreen({
    super.key,
    required this.appointmentId,
    required this.recipientName,
    this.recipientSubtitle,
    this.recipientAvatar,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final AppState _appState = AppState();
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatMessageModel> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _error;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    _markRead();
    // Poll for new messages every 4 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _fetchMessages(isBackground: true);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _markRead() async {
    await _appState.markChatMessagesRead(widget.appointmentId);
  }

  Future<void> _fetchMessages({bool isBackground = false}) async {
    if (!isBackground && _messages.isEmpty) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    final res = await _appState.fetchChatMessages(widget.appointmentId);

    if (!mounted) return;

    if (res.success) {
      final pendingTemp = _messages.where((m) => m.id.startsWith('temp_')).toList();
      final List<ChatMessageModel> merged = List.from(res.messages);

      for (final temp in pendingTemp) {
        final alreadyInServer = res.messages.any((m) =>
            m.senderType == temp.senderType &&
            m.message == temp.message);
        if (!alreadyInServer) {
          merged.add(temp);
        }
      }

      setState(() {
        _messages = merged;
        _isLoading = false;
      });
      if (!isBackground) {
        _scrollToBottom();
      }
    } else {
      if (!isBackground) {
        setState(() {
          _error = res.message ?? 'Failed to load messages';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleSendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty || _isSending) return;

    _msgController.clear();

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final isDoctorLoggedIn = _appState.isDoctorLoggedIn;
    final currentUserId = isDoctorLoggedIn
        ? (_appState.currentDoctorProfile?.id ?? _appState.currentUser?.id ?? 'doctor')
        : (_appState.currentUser?.id ?? 'user');

    final optimisticMsg = ChatMessageModel(
      id: tempId,
      appointmentId: widget.appointmentId,
      senderId: currentUserId,
      senderType: isDoctorLoggedIn ? 'doctor' : 'user',
      message: text,
      isRead: false,
      createdAt: DateTime.now().toIso8601String(),
    );

    setState(() {
      _messages.add(optimisticMsg);
      _isSending = true;
    });
    _scrollToBottom();

    final res = await _appState.sendChatMessage(
      appointmentId: widget.appointmentId,
      message: text,
    );

    if (!mounted) return;

    setState(() {
      _isSending = false;
    });

    if (res.success) {
      if (res.data != null) {
        final idx = _messages.indexWhere((m) => m.id == tempId);
        if (idx != -1) {
          setState(() {
            _messages[idx] = res.data!;
          });
        }
      }
      _fetchMessages(isBackground: true);
    } else {
      setState(() {
        _messages.removeWhere((m) => m.id == tempId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message ?? 'Failed to send message'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              backgroundImage: (widget.recipientAvatar != null && widget.recipientAvatar!.startsWith('http'))
                  ? NetworkImage(widget.recipientAvatar!) as ImageProvider
                  : const AssetImage('assets/d1.jpg'),
              onBackgroundImageError: (_, __) {},
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.recipientName,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.recipientSubtitle ?? 'Online Consultation',
                    style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.8)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _fetchMessages();
              _markRead();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat Messages List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null && _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text(_error!, style: const TextStyle(color: AppColors.textLight)),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _fetchMessages,
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                              child: const Text('Retry', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      )
                    : _messages.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.chat_rounded, size: 54, color: Color(0xFFCBD5E1)),
                                const SizedBox(height: 12),
                                const Text(
                                  'No messages yet.',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF475569)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Start the conversation with ${widget.recipientName}!',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(14),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final msg = _messages[index];
                              final bool isDoctorLoggedIn = _appState.isDoctorLoggedIn;
                              final bool isMe = (isDoctorLoggedIn && msg.senderType.toLowerCase() == 'doctor') ||
                                  (!isDoctorLoggedIn && msg.senderType.toLowerCase() == 'user');

                              return _buildChatBubble(msg, isMe);
                            },
                          ),
          ),

          // Message Input Field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        fillColor: const Color(0xFFF1F5F9),
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _handleSendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: _isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      onPressed: _handleSendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(ChatMessageModel msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
          border: isMe ? null : Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msg.message,
              style: TextStyle(
                fontSize: 14,
                color: isMe ? Colors.white : const Color(0xFF0F172A),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  msg.formattedTime,
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe ? Colors.white.withValues(alpha: 0.7) : const Color(0xFF94A3B8),
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    msg.isRead ? Icons.done_all_rounded : Icons.done_rounded,
                    size: 13,
                    color: msg.isRead ? const Color(0xFF6EE7B7) : Colors.white.withValues(alpha: 0.7),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
