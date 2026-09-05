import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'constants.dart';
import 'storage_service.dart';

/// Standardized API Response
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final String? errorCode;
  final int statusCode;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.errorCode,
    required this.statusCode,
  });
}

/// Project PARAKH API Client
/// Connects to FastAPI Backend (/api/v1/...) with real JWT authentication, token rotation, and dual-mode wireless connectivity.
class ApiClient {
  final StorageService _storage;
  String _baseUrl;
  bool _isRefreshing = false;

  ApiClient(this._storage, {String? baseUrl})
      : _baseUrl = baseUrl ?? _resolveDefaultBaseUrl();

  static String _resolveDefaultBaseUrl() {
    if (kIsWeb) return AppConstants.localhostApiUrl;
    try {
      if (Platform.isAndroid) {
        return AppConstants.defaultApiBaseUrl;
      }
    } catch (_) {}
    return AppConstants.localhostApiUrl;
  }

  void updateBaseUrl(String url) {
    _baseUrl = url;
  }

  String get baseUrl => _baseUrl;

  Map<String, String> _headers({bool isMultipart = false}) {
    final token = _storage.getToken();
    final map = <String, String>{
      'Accept': 'application/json',
      AppConstants.apiKeyHeaderName: AppConstants.apiKey,
    };
    if (!isMultipart) {
      map['Content-Type'] = 'application/json';
    }
    if (token != null && token.isNotEmpty) {
      map['Authorization'] = 'Bearer $token';
    }
    return map;
  }

  /// Exchange refresh token for a brand new access token (real JWT rotation)
  Future<bool> tryRefreshToken() async {
    if (_isRefreshing) return false;
    final refreshToken = _storage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    _isRefreshing = true;
    try {
      final uri = Uri.parse('$_baseUrl${AppConstants.authRefresh}');
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              AppConstants.apiKeyHeaderName: AppConstants.apiKey,
            },
            body: jsonEncode({'refresh_token': refreshToken}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        final data = decoded['data'] ?? decoded;
        final newAccessToken = data['access_token'] ?? data['token'];
        final newRefreshToken = data['refresh_token'];
        if (newAccessToken != null) {
          await _storage.saveToken(newAccessToken);
          if (newRefreshToken != null) {
            await _storage.saveRefreshToken(newRefreshToken);
          }
          _isRefreshing = false;
          return true;
        }
      }
    } catch (_) {}
    _isRefreshing = false;
    return false;
  }

  /// Automatically attempt failover to alternate gateway (Wi-Fi LAN or ADB Localhost)
  Future<bool> _trySwitchGateway() async {
    final alternateUrl = _baseUrl.contains('127.0.0.1')
        ? AppConstants.wifiLanApiUrl
        : AppConstants.defaultApiBaseUrl;

    try {
      final healthUri = Uri.parse('$alternateUrl${AppConstants.healthCheck}');
      final testResp = await http.get(healthUri).timeout(const Duration(seconds: 3));
      if (testResp.statusCode == 200) {
        _baseUrl = alternateUrl;
        await _storage.setCustomApiUrl(alternateUrl);
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Generic GET
  Future<ApiResponse<Map<String, dynamic>>> get(String endpoint, {Map<String, String>? queryParams}) async {
    try {
      var uri = Uri.parse('$_baseUrl$endpoint');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      final response = await http.get(uri, headers: _headers()).timeout(const Duration(seconds: 15));

      // Automatic JWT Token Refresh on 401 Unauthorized
      if (response.statusCode == 401 && !endpoint.contains('/auth/')) {
        final refreshed = await tryRefreshToken();
        if (refreshed) {
          final retryResponse = await http.get(uri, headers: _headers()).timeout(const Duration(seconds: 15));
          return _handleResponse(retryResponse);
        }
      }

      return _handleResponse(response);
    } catch (e) {
      if (e is SocketException) {
        final switched = await _trySwitchGateway();
        if (switched) {
          return get(endpoint, queryParams: queryParams);
        }
      }
      return _handleException(e);
    }
  }

  /// Generic POST
  Future<ApiResponse<Map<String, dynamic>>> post(String endpoint, {dynamic body}) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final response = await http
          .post(
            uri,
            headers: _headers(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 60));

      // Automatic JWT Token Refresh on 401 Unauthorized
      if (response.statusCode == 401 && !endpoint.contains('/auth/')) {
        final refreshed = await tryRefreshToken();
        if (refreshed) {
          final retryResponse = await http
              .post(
                uri,
                headers: _headers(),
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(const Duration(seconds: 60));
          return _handleResponse(retryResponse);
        }
      }

      return _handleResponse(response);
    } catch (e) {
      if (e is SocketException) {
        final switched = await _trySwitchGateway();
        if (switched) {
          return post(endpoint, body: body);
        }
      }
      return _handleException(e);
    }
  }

  /// Generic PATCH
  Future<ApiResponse<Map<String, dynamic>>> patch(String endpoint, {dynamic body}) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final response = await http
          .patch(
            uri,
            headers: _headers(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 20));

      // Automatic JWT Token Refresh on 401 Unauthorized
      if (response.statusCode == 401 && !endpoint.contains('/auth/')) {
        final refreshed = await tryRefreshToken();
        if (refreshed) {
          final retryResponse = await http
              .patch(
                uri,
                headers: _headers(),
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(const Duration(seconds: 20));
          return _handleResponse(retryResponse);
        }
      }

      return _handleResponse(response);
    } catch (e) {
      if (e is SocketException) {
        final switched = await _trySwitchGateway();
        if (switched) {
          return patch(endpoint, body: body);
        }
      }
      return _handleException(e);
    }
  }

  /// Multipart Image Upload
  Future<ApiResponse<Map<String, dynamic>>> uploadFile(
    String endpoint, {
    required File file,
    required String fieldName,
    Map<String, String>? extraFields,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(_headers(isMultipart: true));

      if (extraFields != null) {
        request.fields.addAll(extraFields);
      }

      request.files.add(await http.MultipartFile.fromPath(fieldName, file.path));

      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 401 && !endpoint.contains('/auth/')) {
        final refreshed = await tryRefreshToken();
        if (refreshed) {
          return uploadFile(endpoint, file: file, fieldName: fieldName, extraFields: extraFields);
        }
      }

      return _handleResponse(response);
    } catch (e) {
      if (e is SocketException) {
        final switched = await _trySwitchGateway();
        if (switched) {
          return uploadFile(endpoint, file: file, fieldName: fieldName, extraFields: extraFields);
        }
      }
      return _handleException(e);
    }
  }

  ApiResponse<Map<String, dynamic>> _handleResponse(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      final isSuccess = response.statusCode >= 200 && response.statusCode < 300;

      if (decoded is Map<String, dynamic>) {
        return ApiResponse<Map<String, dynamic>>(
          success: isSuccess && (decoded['success'] ?? true),
          data: decoded['data'] is Map<String, dynamic> ? decoded['data'] : decoded,
          message: decoded['message'] ?? (isSuccess ? 'Success' : 'Request failed'),
          errorCode: decoded['error_code'] ?? (isSuccess ? null : 'HTTP_${response.statusCode}'),
          statusCode: response.statusCode,
        );
      }

      return ApiResponse<Map<String, dynamic>>(
        success: isSuccess,
        data: {'result': decoded},
        message: isSuccess ? 'Success' : 'Request failed',
        statusCode: response.statusCode,
      );
    } catch (_) {
      return ApiResponse<Map<String, dynamic>>(
        success: response.statusCode >= 200 && response.statusCode < 300,
        data: {'raw': response.body},
        message: response.reasonPhrase ?? 'Error',
        statusCode: response.statusCode,
      );
    }
  }

  ApiResponse<Map<String, dynamic>> _handleException(dynamic e) {
    return ApiResponse<Map<String, dynamic>>(
      success: false,
      message: e is SocketException
          ? 'Network gateway unreachable. Device will auto-retry via Wi-Fi/ADB.'
          : 'Service error: ${e.toString()}',
      errorCode: e is SocketException ? 'OFFLINE_MODE' : 'CLIENT_EXCEPTION',
      statusCode: 0,
    );
  }
}
