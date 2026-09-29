// AarogyaMP — Chat Screen (M2 — Person C)
// USE_MOCKS=true  → simulated delay + canned response (unchanged from M1 UI)
// USE_MOCKS=false → real WebSocket via ChatService + ConsultationService history
//
// Flow (live):
//   1. initState → ChatService.connect(consultationId, token)
//   2. ChatService loads HTTP history first (ChatHistoryLoaded event)
//   3. ChatService opens WS (ChatConnectionStatus connected=true)
//   4. Incoming messages arrive as ChatMessageReceived events
//   5. User sends → ChatService.sendText()
//   6. dispose → ChatService.disconnect()
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/services/chat_service.dart';
import '../../core/services/consultation_service.dart';
import '../../core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Mock message model (mock-mode only — keeps M1 UX intact)
// ─────────────────────────────────────────────────────────────────────────────
class _MockMsg {
  final String text;
  final bool isPatient;
  final DateTime time;
  _MockMsg({required this.text, required this.isPatient, required this.time});
}

// ─────────────────────────────────────────────────────────────────────────────
// Chat Screen
// ─────────────────────────────────────────────────────────────────────────────
class ChatScreen extends ConsumerStatefulWidget {
  final String consultationId;
  final String? doctorName;

  const ChatScreen({
    super.key,
    required this.consultationId,
    this.doctorName,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  static const _useMocks = bool.fromEnvironment('USE_MOCKS', defaultValue: true);

  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  // ── Mock state ──
  final List<_MockMsg> _mockMessages = [];

  // ── Live state ──
  final List<ChatMessageModel> _liveMessages = [];
  StreamSubscription<ChatServiceEvent>? _eventSub;
  bool _wsConnected = false;
  String? _wsError;
  bool _isHistoryLoaded = false;
  String _myRole = 'patient'; // filled from auth on init

  @override
  void initState() {
    super.initState();
    if (_useMocks) {
      _mockMessages.add(_MockMsg(
        text:
            'Hello! I am ${widget.doctorName ?? 'your doctor'}. I have reviewed your symptom report. How are you feeling now?',
        isPatient: false,
        time: DateTime.now().subtract(const Duration(minutes: 2)),
      ));
    } else {
      _connectLive();
    }
  }

  void _connectLive() {
    final auth = ref.read(authProvider);
    final token = auth.accessToken ?? '';
    _myRole = auth.role == UserRole.doctor ? 'doctor' : 'patient';

    final chatService = ref.read(chatServiceProvider);
    chatService.connect(widget.consultationId, token);

    _eventSub = chatService.events.listen(_onChatEvent);
  }

  void _onChatEvent(ChatServiceEvent event) {
    if (!mounted) return;
    switch (event) {
      case ChatHistoryLoaded(:final messages):
        setState(() {
          _liveMessages.clear();
          _liveMessages.addAll(messages);
          _isHistoryLoaded = true;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

      case ChatMessageReceived(:final message):
        // Avoid duplicates (WS may echo our own sent message back)
        if (!_liveMessages.any((m) => m.id == message.id)) {
          setState(() => _liveMessages.add(message));
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _scrollToBottom());
        }

      case ChatConnectionStatus(:final connected, :final error):
        setState(() {
          _wsConnected = connected;
          _wsError = error;
        });
    }
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    if (!_useMocks) {
      ref.read(chatServiceProvider).disconnect();
    }
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Send ──────────────────────────────────────────────────────────────────

  void _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;
    _controller.clear();

    if (_useMocks) {
      setState(() {
        _mockMessages.add(_MockMsg(text: text, isPatient: true, time: DateTime.now()));
        _isSending = true;
      });
      _scrollToBottom();
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _mockMessages.add(_MockMsg(
          text:
              'Thank you for sharing that. Based on your symptoms, I recommend resting and taking paracetamol. Please drink plenty of fluids.',
          isPatient: false,
          time: DateTime.now(),
        ));
      });
      _scrollToBottom();
    } else {
      // Live: send over WebSocket. The server will broadcast it back and
      // it will arrive via the ChatMessageReceived event.
      ref.read(chatServiceProvider).sendText(text);
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final subtitle = _useMocks
        ? 'Consultation · Mock mode'
        : _wsConnected
            ? 'Connected'
            : _wsError != null
                ? 'Disconnected'
                : 'Connecting...';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.doctorName ?? 'Chat',
                style: Theme.of(context).textTheme.titleMedium),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _wsConnected || _useMocks
                        ? AppColors.onSurfaceVariant
                        : AppColors.riskHighText,
                  ),
            ),
          ],
        ),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Connection error banner
            if (!_useMocks && _wsError != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: AppColors.riskHighBg,
                child: Row(
                  children: [
                    const Icon(Icons.wifi_off_rounded,
                        size: 16, color: AppColors.riskHighText),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _wsError!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.riskHighText,
                            ),
                      ),
                    ),
                    if (_wsError!.contains('not found'))
                      TextButton(
                        onPressed: () => context.push(Routes.doctorList),
                        child: const Text('Find Doctor',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
                      )
                    else
                      TextButton(
                        onPressed: () {
                          setState(() => _wsError = null);
                          _connectLive();
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Reconnect',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.primary)),
                      ),
                  ],
                ),
              ),

            // Message list
            Expanded(
              child: _useMocks
                  ? _buildMockList()
                  : _buildLiveList(),
            ),

            // Input bar
            _InputBar(
              controller: _controller,
              isSending: _isSending,
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMockList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _mockMessages.length + (_isSending ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == _mockMessages.length) return const _TypingIndicator();
        final m = _mockMessages[i];
        return _ChatBubble(
          text: m.text,
          isMe: m.isPatient,
          timestamp: m.time,
        );
      },
    );
  }

  Widget _buildLiveList() {
    if (!_isHistoryLoaded) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_liveMessages.isEmpty) {
      return Center(
        child: Text(
          'No messages yet.\nSend a message to start the consultation.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
        ),
      );
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _liveMessages.length,
      itemBuilder: (context, i) {
        final m = _liveMessages[i];
        final isMe = m.senderRole == _myRole;
        return _ChatBubble(
          text: m.text ?? '[${m.messageType}]',
          isMe: isMe,
          timestamp: m.timestamp,
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.surfaceBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.surfaceBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.surfaceBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.5),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              maxLines: null,
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: isSending ? null : onSend,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: isSending
                    ? AppColors.primary.withValues(alpha: 0.4)
                    : AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final DateTime timestamp;

  const _ChatBubble({
    required this.text,
    required this.isMe,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm').format(timestamp.toLocal());
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                  color: AppColors.primaryLight, shape: BoxShape.circle),
              child: const Icon(Icons.medical_services_rounded,
                  color: AppColors.primary, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                    border: isMe
                        ? null
                        : Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: Text(
                    text,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isMe ? Colors.white : AppColors.onSurface,
                        ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  timeStr,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 10,
                      ),
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
                color: AppColors.primaryLight, shape: BoxShape.circle),
            child: const Icon(Icons.medical_services_rounded,
                color: AppColors.primary, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Doctor is typing',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                ),
                const SizedBox(width: 6),
                const SizedBox(
                  width: 20,
                  height: 12,
                  child: CircularProgressIndicator(
                      color: AppColors.primary, strokeWidth: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
