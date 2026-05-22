import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final apiClientServiceProvider = Provider<ApiClientService>((ref) {
  return ApiClientService();
});

class ApiClientService {
  late final Dio _dio;

  ApiClientService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.islamicsuperapp.example.com/v1', // Placeholder
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));

    // Add Auth interceptor later
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return await _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return await _dio.post(path, data: data);
  }
  
  // other methods (put, delete) will go here
}
