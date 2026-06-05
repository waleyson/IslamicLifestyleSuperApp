import 'package:dio/dio.dart';
import '../models/prayer_times_model.dart';

class PrayerTimesRepository {
  final Dio _dio;

  PrayerTimesRepository({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://api.aladhan.com',
                connectTimeout: const Duration(seconds: 8),
                receiveTimeout: const Duration(seconds: 8),
              ),
            );

  /// Fetches prayer times from Aladhan API based on the user's IP.
  Future<PrayerTimesModel> fetchPrayerTimesByIp() async {
    final response = await _dio.get('/v1/timingsByIp');
    final responseBody = response.data as Map<String, dynamic>;
    if (responseBody['code'] == 200 && responseBody['data'] != null) {
      final data = responseBody['data'] as Map<String, dynamic>;
      return PrayerTimesModel.fromAladhanJson(data);
    } else {
      throw Exception('Failed to load prayer times: ${responseBody['status'] ?? 'Unknown error'}');
    }
  }
}
