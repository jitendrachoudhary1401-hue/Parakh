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
/// Connects to FastAPI Backend (/api/v1/...) with JWT authentication and response envelope handling.
class ApiClient {
  final StorageService _storage;
  String _baseUrl;

  ApiClient(this._storage, {String? baseUrl})
      : _baseUrl = baseUrl ?? _resolveDefaultBaseUrl();

  static String _resolveDefaultBaseUrl() {
    if (kIsWeb) return AppConstants.localhostApiUrl;
    try {
      if (Platform.isAndroid) {
        return AppConstants.defaultApiBaseUrl; // 10.0.2.2 for Android emulator
      }
    } catch (_) {}
    return AppConstants.localhostApiUrl; // 127.0.0.1 for Desktop/LAN
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

  /// Generic GET
  Future<ApiResponse<Map<String, dynamic>>> get(String endpoint, {Map<String, String>? queryParams}) async {
    try {
      var uri = Uri.parse('$_baseUrl$endpoint');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      final response = await http.get(uri, headers: _headers()).timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } catch (e) {
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
      return _handleResponse(response);
    } catch (e) {
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
      return _handleResponse(response);
    } catch (e) {
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
      return _handleResponse(response);
    } catch (e) {
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
          ? 'Network unavailable. Stored in local offline queue.'
          : 'Service error: ${e.toString()}',
      errorCode: e is SocketException ? 'OFFLINE_MODE' : 'CLIENT_EXCEPTION',
      statusCode: 0,
    );
  }
}
