// AarogyaMP — Doctor Directory Service (M2 — Person C)
// Live: GET /api/doctors?specialty=&lat=&lng=&radius_km=
// Mirrors DoctorOut schema (FROZEN §11). Server-side: only verified doctors returned.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../api/endpoints.dart';
import '../models/doctor_model.dart';

class DoctorService {
  final Dio _dio;
  DoctorService(this._dio);

  /// Fetch verified doctors. All params optional.
  /// Server enforces verification_status == 'verified' — no client-side filtering needed.
  Future<List<Doctor>> getDoctors({
    String? specialty,
    double? lat,
    double? lng,
    double? radiusKm,
  }) async {
    final params = <String, dynamic>{};
    if (specialty != null) params['specialty'] = specialty;
    if (lat != null) params['lat'] = lat;
    if (lng != null) params['lng'] = lng;
    if (radiusKm != null) params['radius_km'] = radiusKm;

    final response = await _dio.get(
      Endpoints.listDoctors,
      queryParameters: params.isEmpty ? null : params,
    );
    final data = response.data as Map<String, dynamic>;
    return (data['doctors'] as List)
        .map((d) => Doctor.fromJson(d as Map<String, dynamic>))
        .toList();
  }

  /// Fallback when navigating to profile without a pre-loaded Doctor object.
  /// No GET /api/doctors/{id} endpoint exists yet (M3 TODO for Person A).
  /// We fetch all and filter — acceptable because list is small in pilot.
  Future<Doctor?> getDoctorById(String id) async {
    final all = await getDoctors();
    return all.cast<Doctor?>().firstWhere(
          (d) => d?.id == id,
          orElse: () => null,
        );
  }
}

final doctorServiceProvider = Provider<DoctorService>((ref) {
  return DoctorService(ref.watch(dioProvider));
});
