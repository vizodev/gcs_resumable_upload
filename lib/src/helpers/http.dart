import 'package:dio/dio.dart';

class HttpProvider {
  static final _dio = Dio(BaseOptions(followRedirects: true, maxRedirects: 10));

  static Future<Response<T>> post<T>({
    required String url,
    dynamic data,
    required Map<String, String> headers,
  }) {
    return _dio.post(
      url,
      data: data,
      options: Options(
        headers: headers,
      ),
    );
  }

  static Future<Response<T>> put<T>({
    required String url,
    dynamic data,
    required Map<String, String> headers,
  }) async {
    print('Sending PUT request to $url; data: $data;headers: $headers');
    try {
      return await _dio.put(
        url,
        data: data,
        options: Options(
          headers: headers,
        ),
      );
    } on DioError catch (e) {
      if (e.response?.statusCode == 308) return e.response as Response<T>;
      print('DioError: ${e.response?.data}; ${e.message}');
      rethrow;
    }
  }
}
