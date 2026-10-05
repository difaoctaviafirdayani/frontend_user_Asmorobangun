import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'config.dart';

class ApiException implements Exception {
  final String message;
  final int status;
  ApiException(this.message, [this.status = 0]);

  /// 400/409/422: ditolak oleh VALIDASI SERVER (lapisan 2). Pesannya aman ditampilkan ke pengguna.
  bool get isValidation => status == 400 || status == 409 || status == 422;

  /// 401: belum login atau token tidak sah (lapisan 3 - autentikasi).
  bool get isUnauthenticated => status == 401;

  /// 403: login sah tetapi tidak berhak (lapisan 4 - otorisasi).
  bool get isForbidden => status == 403;

  @override
  String toString() => message;
}

/// Klien tipis untuk backend Express. Semua respons diharapkan berupa JSON object.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  String? token;

  /// Dipanggil saat server menjawab 401 padahal ada token (sesi habis).
  void Function()? onUnauthorized;

  Uri _uri(String path, [Map<String, String>? query]) {
    var uri = Uri.parse('${AppConfig.apiBase}$path');
    if (query != null && query.isNotEmpty) uri = uri.replace(queryParameters: query);
    _assertSecure(uri);
    return uri;
  }

  /// LAPISAN 5 (bagian "data dalam perjalanan"): ENKRIPSI IN-TRANSIT.
  /// Pada build rilis, request ke alamat non-HTTPS diblokir sehingga token dan
  /// password tidak pernah terkirim sebagai teks biasa. Saat debug, http ke
  /// localhost/emulator tetap diizinkan untuk pengembangan.
  void _assertSecure(Uri uri) {
    if (uri.scheme == 'https') return;
    if (kReleaseMode) {
      throw ApiException('Koneksi tidak aman diblokir. Aplikasi hanya boleh memakai HTTPS pada versi rilis.');
    }
  }

  Map<String, String> _headers({bool json = true}) => {
        'Accept': 'application/json',
        if (json) 'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<Map<String, dynamic>> get(String path, {Map<String, String>? query}) =>
      _send(() => http.get(_uri(path, query), headers: _headers(json: false)));

  Future<Map<String, dynamic>> post(String path, {Object? body}) => _send(
      () => http.post(_uri(path), headers: _headers(), body: jsonEncode(body ?? {})));

  Future<Map<String, dynamic>> patch(String path, {Object? body}) => _send(
      () => http.patch(_uri(path), headers: _headers(), body: jsonEncode(body ?? {})));

  Future<Map<String, dynamic>> delete(String path) =>
      _send(() => http.delete(_uri(path), headers: _headers(json: false)));

  /// Unggah satu file (multipart). Dipakai untuk bukti bayar dan foto profil.
  Future<Map<String, dynamic>> upload(
    String path, {
    required String field,
    required List<int> bytes,
    required String filename,
    Map<String, String>? fields,
    String method = 'POST',
  }) async {
    _ensureSecure();
    try {
      final req = http.MultipartRequest(method, _uri(path));
      if (token != null) req.headers['Authorization'] = 'Bearer $token';
      if (fields != null) req.fields.addAll(fields);
      req.files.add(http.MultipartFile.fromBytes(
        field,
        bytes,
        filename: filename,
        contentType: _mediaType(filename),
      ));
      final streamed = await req.send().timeout(const Duration(seconds: 60));
      final res = await http.Response.fromStream(streamed);
      return _handle(res);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException('Unggah terlalu lama. Coba lagi dengan koneksi yang lebih stabil.');
    } catch (_) {
      throw ApiException('Tidak bisa terhubung ke server. Periksa koneksi internet kamu.');
    }
  }

  MediaType _mediaType(String filename) {
    final dot = filename.lastIndexOf('.');
    final ext = dot >= 0 ? filename.substring(dot + 1).toLowerCase() : '';
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'webp':
        return MediaType('image', 'webp');
      case 'gif':
        return MediaType('image', 'gif');
      case 'pdf':
        return MediaType('application', 'pdf');
      default:
        return MediaType('application', 'octet-stream');
    }
  }

  /// Tolak koneksi tidak terenkripsi pada build rilis (lapisan 5 - enkripsi).
  void _ensureSecure() {
    if (!AppConfig.isSecureTransport) {
      throw ApiException('Koneksi tidak aman diblokir. Server harus memakai HTTPS.');
    }
  }

  Future<Map<String, dynamic>> _send(Future<http.Response> Function() request) async {
    _ensureSecure();
    try {
      final res = await request().timeout(const Duration(seconds: 20));
      return _handle(res);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException('Server tidak merespons. Coba lagi sebentar lagi.');
    } catch (_) {
      throw ApiException('Tidak bisa terhubung ke server. Periksa koneksi internet kamu.');
    }
  }

  String _messageFrom(Map<String, dynamic> data, int status) {
    final err = data['error'];
    if (err is String && err.isNotEmpty) return err;
    final errors = data['errors'];
    if (errors is List && errors.isNotEmpty) return errors.map((e) => e.toString()).join('\n');
    if (status == 401) return 'Sesi login tidak valid. Silakan masuk lagi.';
    if (status == 403) return 'Kamu tidak punya izin untuk melakukan ini.';
    if (status == 404) return 'Data tidak ditemukan.';
    if (status >= 500) return 'Server sedang bermasalah. Coba lagi nanti.';
    return 'Terjadi kesalahan. Coba lagi.';
  }

  Map<String, dynamic> _handle(http.Response res) {
    Map<String, dynamic> data = {};
    try {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      if (decoded is Map<String, dynamic>) data = decoded;
    } catch (_) {
      data = {};
    }
    if (res.statusCode >= 400) {
      if (res.statusCode == 401 && token != null) onUnauthorized?.call();
      final msg = data['error'];
      final fallback = switch (res.statusCode) {
        401 => 'Sesi login tidak valid. Silakan masuk lagi.',
        403 => 'Kamu tidak punya izin untuk melakukan ini.',
        404 => 'Data tidak ditemukan.',
        413 => 'Ukuran data terlalu besar.',
        429 => 'Terlalu banyak percobaan. Coba lagi sebentar lagi.',
        >= 500 => 'Server sedang bermasalah. Coba lagi nanti.',
        _ => 'Terjadi kesalahan. Coba lagi.',
      };
      throw ApiException(msg is String && msg.isNotEmpty ? msg : fallback, res.statusCode);
    }
    return data;
  }
}

final api = ApiClient.instance;
