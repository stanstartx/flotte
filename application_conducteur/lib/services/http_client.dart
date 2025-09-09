import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class HttpClient {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConfig.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 20),
    headers: {
      'Content-Type': 'application/json',
    },
  ));

  static bool _isRefreshing = false;
  static final List<Future<Response<dynamic>> Function()> _retryQueue = [];

  static Dio get instance {
    _dio.interceptors.clear();
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final access = prefs.getString('token');
        if (access != null && access.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $access';
        }
        handler.next(options);
      },
      onError: (DioException error, handler) async {
        if (error.response?.statusCode == 401) {
          final canRetry = await _refreshToken();
          if (canRetry) {
            final requestOptions = error.requestOptions;
            final future = () => _dio.fetch<dynamic>(requestOptions);
            try {
              final response = await future();
              return handler.resolve(response);
            } catch (e) {
              return handler.next(error);
            }
          }
        }
        return handler.next(error);
      },
    ));
    return _dio;
  }

  static Future<bool> _refreshToken() async {
    if (_isRefreshing) return false;
    _isRefreshing = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final refresh = prefs.getString('refresh');
      if (refresh == null) return false;
      final response = await Dio().post('${AppConfig.baseUrl}/api/auth/refresh/', data: {'refresh': refresh});
      if (response.statusCode == 200) {
        final newAccess = response.data['access'] as String?;
        if (newAccess != null) {
          await prefs.setString('token', newAccess);
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    } finally {
      _isRefreshing = false;
    }
  }
}





