import 'dart:convert';

import 'package:http/http.dart' as http;

import 'config.dart';

class ErrorReporter {
  ErrorReporter._();
  static DateTime? _last;
  static String? _lastMessage;

  static Future<void> report(String message, {String? path, int? status, Object? detail}) async {
    final now = DateTime.now();
    if (_lastMessage == message && _last != null && now.difference(_last!) < const Duration(seconds: 10)) {
      return;
    }
    _last = now;
    _lastMessage = message;
    try {
      await http
          .post(
            Uri.parse('${AppConfig.apiBase}/logs'),
            headers: {
              'Content-Type': 'application/json',
              'ngrok-skip-browser-warning': 'true',
            },
            body: jsonEncode({
              'source': 'user',
              'message': message,
              'path': path,
              'status': status,
              'detail': detail?.toString(),
            }),
          )
          .timeout(const Duration(seconds: 5));
    } catch (_) {}
  }
}