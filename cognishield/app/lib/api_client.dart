import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

class ApiException implements Exception {
  ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ApiClient {
  ApiClient(String baseUrl) : baseUrl = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');

  final String baseUrl;

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Future<Map<String, dynamic>> _send(Future<http.Response> Function() call) async {
    try {
      final res = await call().timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) {
        throw ApiException('Server rejected the request (code ${res.statusCode}).');
      }
      final body = jsonDecode(utf8.decode(res.bodyBytes));
      if (body is! Map<String, dynamic>) {
        throw ApiException('Unrecognized server response.');
      }
      return body;
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException('The server did not respond within 15 seconds.');
    } on FormatException {
      throw ApiException('The server returned invalid JSON.');
    } catch (_) {
      throw ApiException(
        'Cannot reach the backend at $baseUrl. Make sure the server is running and the address is correct (Settings).',
      );
    }
  }

  Future<Map<String, dynamic>> _post(String path, String text) => _send(
        () => http.post(
          _uri(path),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'text': text}),
        ),
      );

  Future<bool> health() async {
    final j = await _send(() => http.get(_uri('/health')));
    return j['status'] == 'ok';
  }

  /// Scan anything for every threat type. [source] is manual | clipboard | notification.
  Future<ScanResult> analyzeAuto(String text, {String source = 'manual'}) async => ScanResult.fromJson(
        await _send(
          () => http.post(
            _uri('/analyze/auto'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'text': text, 'source': source}),
          ),
        ),
      );

  Future<ScanResult> analyzePropaganda(String text) async =>
      ScanResult.fromJson(await _post('/analyze/propaganda', text));

  Future<ScanResult> analyzeUrl(String text) async => ScanResult.fromJson(await _post('/analyze/url', text));

  Future<ScanResult> analyzeNotification(String text) async =>
      ScanResult.fromJson(await _post('/analyze/notification', text));

  Future<Stats> stats() async => Stats.fromJson(await _send(() => http.get(_uri('/stats'))));

  Future<List<HistoryItem>> history({int limit = 100}) async {
    final j = await _send(() => http.get(_uri('/history?limit=$limit')));
    return ((j['items'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(HistoryItem.fromJson)
        .toList();
  }

  Future<void> clearHistory() async {
    await _send(() => http.delete(_uri('/history')));
  }
}
