/// AarogyaMP — Doctor list screen stub (Person C, M1) — Route: /doctors
/// Never show unverified doctors — check verification_status client-side too (defense in depth).
import 'package:flutter/material.dart';

class DoctorListScreen extends StatelessWidget {
  const DoctorListScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Doctor List — M1')));
  }
}
