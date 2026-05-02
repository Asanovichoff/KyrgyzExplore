import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../booking/models/booking_model.dart';
import '../models/message_model.dart';
import '../repositories/message_repository.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.booking});

  final BookingModel booking;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messages = <MessageModel>[];
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  bool _loading = true;
  bool _sending = false;
  bool _connected = false;
  StompClient? _stompClient;

  static const _wsBase = String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: 'ws://localhost:8080',
  );

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // 1. Load REST history first so the screen isn't empty while STOMP connects.
    try {
      final repo = ref.read(messageRepositoryProvider);
      final history = await repo.getHistory(widget.booking.id);
      if (mounted) setState(() => _messages.addAll(history));
      // Mark existing messages as read now that the user has opened the screen.
      await repo.markRead(widget.booking.id);
    } catch (_) {}

    if (!mounted) return;
    setState(() => _loading = false);
    _scrollToBottom();

    // 2. Connect STOMP WebSocket with the user's JWT in the CONNECT header.
    //    STOMP is a text-based messaging protocol layered on top of WebSocket.
    //    We send to /app/chat/{id} and subscribe to /topic/booking/{id}.
    final token = await ref.read(authRepositoryProvider).getAccessToken();
    _stompClient = StompClient(
      config: StompConfig(
        url: '$_wsBase/ws',
        stompConnectHeaders: token != null
            ? {'Authorization': 'Bearer $token'}
            : {},
        onConnect: _onStompConnected,
        onDisconnect: (_) { if (mounted) setState(() => _connected = false); },
        onWebSocketError: (_) { if (mounted) setState(() => _connected = false); },
        onStompError: (_) { if (mounted) setState(() => _connected = false); },
      ),
    );
    _stompClient!.activate();
  }

  void _onStompConnected(StompFrame frame) {
    if (mounted) setState(() => _connected = true);
    _stompClient!.subscribe(
      destination: '/topic/booking/${widget.booking.id}',
      callback: (frame) {
        if (frame.body == null) return;
        final msg = MessageModel.fromJson(
          jsonDecode(frame.body!) as Map<String, dynamic>,
        );
        if (mounted) {
          setState(() => _messages.add(msg));
          _scrollToBottom();
        }
      },
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || !_connected) return;

    setState(() => _sending = true);
    // STOMP send is synchronous fire-and-forget. The server echoes the message
    // back on the /topic/ subscription, so we don't manually append it here.
    _stompClient!.send(
      destination: '/app/chat/${widget.booking.id}',
      body: jsonEncode({'content': text}),
    );
    _inputCtrl.clear();
    setState(() => _sending = false);
  }

  @override
  void dispose() {
    _stompClient?.deactivate();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.booking.listingTitle ?? 'Chat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(
                        child: Text(
                          'No messages yet.\nSay hello!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: kGrey),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 16),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) => _MessageBubble(
                          message: _messages[i],
                          isOwn: _messages[i].senderId == currentUser?.id,
                        ),
                      ),
          ),
          _InputBar(
            controller: _inputCtrl,
            sending: _sending,
            onSend: _connected ? _sendMessage : null,
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Message bubble
// ──────────────────────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isOwn});

  final MessageModel message;
  final bool isOwn;

  @override
  Widget build(BuildContext context) {
    final time =
        '${message.createdAt.hour.toString().padLeft(2, '0')}:${message.createdAt.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment:
            isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isOwn)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 2),
              child: Text(
                message.senderName,
                style: const TextStyle(
                  fontSize: 11,
                  color: kGrey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.72,
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isOwn ? kTeal : const Color(0xFFEEEEEE),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isOwn ? 16 : 4),
                bottomRight: Radius.circular(isOwn ? 4 : 16),
              ),
            ),
            child: Text(
              message.content,
              style: TextStyle(
                color: isOwn ? Colors.white : kDark,
                fontSize: 15,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
            child: Text(
              time,
              style: const TextStyle(fontSize: 10, color: kGrey),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Input bar
// ──────────────────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback? onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                maxLines: 4,
                minLines: 1,
                maxLength: 2000,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Type a message…',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  counterText: '',
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: sending ? null : onSend,
              icon: sending
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded),
              style: IconButton.styleFrom(backgroundColor: kTeal),
            ),
          ],
        ),
      ),
    );
  }
}
