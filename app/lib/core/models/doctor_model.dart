// AarogyaMP — Doctor Dart model (mirrors schemas.py DoctorOut — FROZEN)
// Person C owns this file.
// IMPORTANT: Never render contact info if verification_status != "verified"

class Doctor {
  final String id;
  final String name;
  final String specialty;
  final String? qualification;
  final double? distanceKm;
  final String phone;
  final String? email;
  final String? hospital;
  final String? address;
  final Map<String, dynamic>? availability;
  final String verificationStatus;

  const Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    this.qualification,
    this.distanceKm,
    required this.phone,
    this.email,
    this.hospital,
    this.address,
    this.availability,
    required this.verificationStatus,
  });

  bool get isVerified => verificationStatus == 'verified';

  factory Doctor.fromJson(Map<String, dynamic> json) => Doctor(
    id: json['id'],
    name: json['name'],
    specialty: json['specialty'],
    qualification: json['qualification'],
    distanceKm: json['distance_km']?.toDouble(),
    phone: json['phone'],
    email: json['email'],
    hospital: json['hospital'],
    address: json['address'],
    availability: json['availability'],
    verificationStatus: json['verification_status'],
  );
}
