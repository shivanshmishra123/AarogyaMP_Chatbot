// AarogyaMP — WebSocket Chat Service (M2 — Person C)
// Manages a single WebSocket connection per consultation room.
//
// Connection: ws://host/ws/chat/{consultationId}?token=<jwt>
// Send:    {"type": "text", "content": "..."}
// Receive: {id, consultation_id, sender_role, message_type, text, file_path, timestamp}
//
// Reconnect strategy (Reference §14):
//   On disconnect → wait → re-fetch HTTP history → reopen WS.
//   Max 3 attempts, exponential backoff: 1s, 2s, 4s.
//   After 3 failures the stream emits a ChatServiceEvent.connectionFailed.

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../api/api_client.dart';
import 'consultation_service.dart';

// Events emitted on the message stream
sealed class ChatServiceEvent {}

class ChatMessageReceived extends ChatServiceEvent {
  final ChatMessageModel message;
  ChatMessageReceived(this.message);
}

class ChatHistoryLoaded extends ChatServiceEvent {
  final List<ChatMessageModel> messages;
  ChatHistoryLoaded(this.messages);
}

class ChatConnectionStatus extends ChatServiceEvent {
  final bool connected;
  final String? error;
  ChatConnectionStatus({required this.connected, this.error});
}

class ChatService {
  final ConsultationService _consultationService;
  final String _wsBaseUrl;

  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  final _controller = StreamController<ChatServiceEvent>.broadcast();

  String? _consultationId;
  String? _token;
  int _reconnectAttempts = 0;
  static const _maxReconnectAttempts = 3;
  bool _disposed = false;

  ChatService(this._consultationService, this._wsBaseUrl);

  Stream<ChatServiceEvent> get events => _controller.stream;

  /// Connect to a consultation room.
  /// Step 1: load HTTP history (so we never miss messages).
  /// Step 2: open WebSocket.
  Future<void> connect(String consultationId, String token) async {
    _consultationId = consultationId;
    _token = token;
    _reconnectAttempts = 0;
    _disposed = false;

    // Load existing history first
    await _loadHistory();
    _openSocket();
  }

  Future<void> _loadHistory() async {
    try {
      final messages = await _consultationService.getMessages(_consultationId!);
      if (!_disposed) {
        _controller.add(ChatHistoryLoaded(messages));
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        if (!_disposed) {
          _controller.add(ChatConnectionStatus(
            connected: false,
            error: 'Consultation session not found.',
          ));
        }
      }
    } catch (_) {
      // History load failure is non-fatal — still open WS
    }
  }

  void _openSocket() {
    if (_disposed || _consultationId == null || _token == null) return;

    final uri = Uri.parse('$_wsBaseUrl/ws/chat/$_consultationId?token=$_token');
    try {
      _channel = WebSocketChannel.connect(uri);
      _sub?.cancel();
      _sub = _channel!.stream.listen(
        _onData,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );
      _reconnectAttempts = 0;
      if (!_disposed) {
        _controller.add(ChatConnectionStatus(connected: true));
      }
    } catch (e) {
      _scheduleReconnect();
    }
  }

  void _onData(dynamic raw) {
    if (_disposed) return;
    try {
      final map = jsonDecode(raw as String) as Map<String, dynamic>;
      final msg = ChatMessageModel.fromWsBroadcast(map);
      _controller.add(ChatMessageReceived(msg));
    } catch (_) {
      // Malformed frame — skip
    }
  }

  void _onError(Object error) {
    if (!_disposed) {
      _controller.add(ChatConnectionStatus(connected: false, error: error.toString()));
    }
    _scheduleReconnect();
  }

  void _onDone() {
    final code = _channel?.closeCode;
    if (code == 1008) {
      if (!_disposed) {
        _controller.add(ChatConnectionStatus(
          connected: false,
          error: 'Consultation session not found or access denied.',
        ));
      }
      return;
    }
    if (!_disposed) {
      _controller.add(ChatConnectionStatus(connected: false));
    }
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_disposed || _reconnectAttempts >= _maxReconnectAttempts) {
      if (!_disposed && _reconnectAttempts >= _maxReconnectAttempts) {
        _controller.add(ChatConnectionStatus(
          connected: false,
          error: 'Connection lost. Pull down to refresh.',
        ));
      }
      return;
    }
    final delay = Duration(seconds: pow(2, _reconnectAttempts).toInt()); // 1s, 2s, 4s
    _reconnectAttempts++;
    Future.delayed(delay, () async {
      if (_disposed) return;
      // Re-fetch history to catch messages sent while disconnected
      await _loadHistory();
      _openSocket();
    });
  }

  /// Send a text message over the open WebSocket.
  void sendText(String text) {
    if (_channel == null) return;
    try {
      _channel!.sink.add(jsonEncode({'type': 'text', 'content': text}));
    } catch (_) {
      // Channel closed — reconnect will handle
    }
  }

  /// Disconnect and clean up. Call from widget dispose().
  void disconnect() {
    _disposed = true;
    _sub?.cancel();
    _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    disconnect();
    _controller.close();
  }
}

/// A scoped provider — one ChatService instance per consultation screen.
/// Use ref.watch(chatServiceProvider) in the ChatScreen.
final chatServiceProvider = Provider<ChatService>((ref) {
  final consultationService = ref.watch(consultationServiceProvider);
  final service = ChatService(consultationService, kWsBaseUrl);
  ref.onDispose(service.dispose);
  return service;
});
