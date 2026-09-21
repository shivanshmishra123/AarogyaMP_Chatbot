/// AarogyaMP — Chat screen stub (Person C, M1) — Route: /chat/:consultationId
/// WebSocket realtime chat. See Reference §14 for reconnect requirements.
import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  final String consultationId;
  const ChatScreen({super.key, required this.consultationId});
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('Chat: $consultationId — M1')));
  }
}
