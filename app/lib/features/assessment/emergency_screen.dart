/// AarogyaMP — Emergency screen stub (Person C, M1)
/// Route: /emergency
/// Full-screen, NO possible-causes list, NO dismiss-and-forget path (Reference §10, §12).
import 'package:flutter/material.dart';

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red[900],
      body: const Center(
        child: Text('EMERGENCY SCREEN — M1', style: TextStyle(color: Colors.white, fontSize: 24)),
      ),
    );
  }
}
