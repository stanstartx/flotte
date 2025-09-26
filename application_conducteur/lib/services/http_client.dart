import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class HttpClient {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl, // corrigé
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  static bool _isRefreshing = false;

  static Dio get instance {
    _dio.interceptors.clear();

    // Logs pour debug
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: true,
        responseHeader: false,
        error: true,
      ),
    );

    // Intercepteur auth
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          print('➡️ Requête: ${options.method} ${options.baseUrl}${options.path}');
          final prefs = await SharedPreferences.getInstance();
          final access = prefs.getString('token') ?? AppConfig.token;
          if (access.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $access';
            print('✅ Token ajouté');
          }
          handler.next(options);
        },
        onError: (DioException error, handler) async {
          print('❌ Erreur HTTP: ${error.response?.statusCode}');
          print('URL: ${error.requestOptions.uri}');

          if (error.response?.statusCode == 401) {
            print('🔄 Token expiré, tentative de refresh...');
            final canRetry = await _refreshToken();
            if (canRetry) {
              try {
                final response = await _dio.fetch<dynamic>(error.requestOptions);
                return handler.resolve(response);
              } catch (e) {
                print('❌ Retry échoué: $e');
              }
            } else {
              print('⚠️ Refresh token failed → redirection login');
            }
          }
          return handler.next(error);
        },
      ),
    );

    return _dio;
  }

  static Future<bool> _refreshToken() async {
    if (_isRefreshing) return false;
    _isRefreshing = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final refresh = prefs.getString('refresh');
      if (refresh == null) {
        print('⚠️ Pas de refresh token dispo');
        return false;
      }

      print('🔄 Refresh du token...');
      final response = await Dio().post(
        '${AppConfig.apiBaseUrl}/auth/refresh/', // corrigé
        data: {'refresh': refresh},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200) {
        final newAccess = response.data['access'] as String?;
        if (newAccess != null && newAccess.isNotEmpty) {
          await prefs.setString('token', newAccess);
          AppConfig.token = newAccess; // update mémoire aussi
          print('✅ Token refresh OK');
          return true;
        }
      }

      print('❌ Refresh token échoué');
      return false;
    } catch (e) {
      print('Erreur refresh: $e');
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  static Future<bool> testConnection() async {
    try {
      final response = await _dio.get('/auth/test-connection/');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Test de connexion échoué: $e');
      return false;
    }
  }
}
