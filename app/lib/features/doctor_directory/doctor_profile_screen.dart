/// AarogyaMP — Doctor profile screen stub (Person C, M1) — Route: /doctors/:id
/// Call (tel:) / Email (mailto: prefilled) / Chat entry points.
import 'package:flutter/material.dart';

class DoctorProfileScreen extends StatelessWidget {
  final String doctorId;
  const DoctorProfileScreen({super.key, required this.doctorId});
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('Doctor Profile: $doctorId — M1')));
  }
}
