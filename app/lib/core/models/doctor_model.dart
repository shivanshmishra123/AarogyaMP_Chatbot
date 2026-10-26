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
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? 'Doctor',
    specialty: json['specialty'] as String? ?? 'General Physician',
    qualification: json['qualification'] as String?,
    distanceKm: (json['distance_km'] as num?)?.toDouble(),
    phone: json['phone'] as String? ?? '',
    email: json['email'] as String?,
    hospital: json['hospital'] as String?,
    address: json['address'] as String?,
    availability: json['availability'] is Map
        ? Map<String, dynamic>.from(json['availability'] as Map)
        : null,
    verificationStatus: json['verification_status'] as String? ?? 'verified',
  );
}

