import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../constants/app_constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late Dio _dio;
  String _baseUrl = ApiConstants.defaultBaseUrl;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString(AppConstants.keyScriptUrl) ?? ApiConstants.defaultBaseUrl;
    _setupDio();
  }

  void _setupDio() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: ApiConstants.connectTimeout),
      receiveTimeout: const Duration(seconds: ApiConstants.receiveTimeout),
      headers: {'Content-Type': 'application/json'},
      followRedirects: true,
      maxRedirects: 3,
    ));

    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
    ));
  }

  Future<void> updateBaseUrl(String url) async {
    _baseUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyScriptUrl, url);
    _setupDio();
  }

  // ── GET ───────────────────────────────────────────────
  Future<dynamic> get({
    required String action,
    Map<String, String>? params,
  }) async {
    final queryParams = {'action': action, ...?params};
    final response = await _dio.get('', queryParameters: queryParams);
    return _handleResponse(response);
  }

  // ── POST ──────────────────────────────────────────────
  Future<dynamic> post({
    required String action,
    required Map<String, dynamic> data,
  }) async {
    final payload = {'action': action, ...data};
    final response = await _dio.post('', data: jsonEncode(payload));
    return _handleResponse(response);
  }

  // ── Response Handler ──────────────────────────────────
  dynamic _handleResponse(Response response) {
    if (response.statusCode != 200) {
      throw ApiException(
        'Server error: ${response.statusCode}',
        response.statusCode ?? 0,
      );
    }

    dynamic body = response.data;
    if (body is String) {
      try { body = jsonDecode(body); } catch (_) {}
    }

    if (body is Map) {
      if (body['success'] == false) {
        throw ApiException(body['error']?.toString() ?? 'Unknown error', 400);
      }
      return body['data'] ?? body;
    }

    return body;
  }

  // ── Convenience methods ────────────────────────────────
  Future<List<Map<String, dynamic>>> getRecords(String sheet) async {
    final result = await get(
      action: ApiConstants.actionGetRecords,
      params: {'sheet': sheet},
    );
    if (result is List) {
      return result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> createRecord(
      String sheet, Map<String, dynamic> data) async {
    final result = await post(
      action: ApiConstants.actionCreateRecord,
      data: {'sheet': sheet, 'record': data},
    );
    return Map<String, dynamic>.from(result as Map? ?? {});
  }

  Future<Map<String, dynamic>> updateRecord(
      String sheet, String id, Map<String, dynamic> data) async {
    final result = await post(
      action: ApiConstants.actionUpdateRecord,
      data: {'sheet': sheet, 'id': id, 'record': data},
    );
    return Map<String, dynamic>.from(result as Map? ?? {});
  }

  Future<void> deleteRecord(String sheet, String id) async {
    await post(
      action: ApiConstants.actionDeleteRecord,
      data: {'sheet': sheet, 'id': id},
    );
  }

  Future<Map<String, dynamic>> getDashboard() async {
    final result = await get(action: ApiConstants.actionGetDashboard);
    return Map<String, dynamic>.from(result as Map? ?? {});
  }

  Future<String> getNextNumber(String type) async {
    final result = await get(
      action: ApiConstants.actionGetNextNumber,
      params: {'type': type},
    );
    return result.toString();
  }

  Future<Map<String, dynamic>> uploadFile({
    required String fileName,
    required String base64Data,
    required String mimeType,
    required String folderId,
  }) async {
    final result = await post(
      action: ApiConstants.actionUploadFile,
      data: {
        'file_name': fileName,
        'data': base64Data,
        'mime_type': mimeType,
        'folder_id': folderId,
      },
    );
    return Map<String, dynamic>.from(result as Map? ?? {});
  }

  Future<Map<String, dynamic>> getReports({
    required String type,
    String? from,
    String? to,
  }) async {
    final result = await get(
      action: ApiConstants.actionGetReports,
      params: {'type': type, if (from != null) 'from': from, if (to != null) 'to': to},
    );
    return Map<String, dynamic>.from(result as Map? ?? {});
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException($statusCode): $message';
}
