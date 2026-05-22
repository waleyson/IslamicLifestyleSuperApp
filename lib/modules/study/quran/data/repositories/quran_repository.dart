import 'package:dio/dio.dart';
import '../models/surah_model.dart';

class QuranRepository {
  final Dio _dio;

  QuranRepository({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://api.alquran.cloud/v1',
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
              ),
            );

  /// Fetches all 114 Surahs from the Quran API.
  Future<List<SurahModel>> fetchAllSurahs() async {
    final response = await _dio.get('/surah');
    final data = response.data['data'] as List<dynamic>;
    return data
        .map((json) => SurahModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
