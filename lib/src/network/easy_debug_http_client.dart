import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/log_manager.dart';
import '../core/log_model.dart';

/// A wrapper client for the `http` package that logs network activity to `EasyDebugManager`.
///
/// Usage:
/// ```dart
/// final client = EasyDebugHttpClient(http.Client());
/// final response = await client.get(Uri.parse('https://example.com'));
/// ```
class EasyDebugHttpClient extends http.BaseClient {
  final http.Client _inner;

  EasyDebugHttpClient(this._inner);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final startTime = DateTime.now();
    final requestId = startTime.millisecondsSinceEpoch.toString();

    // 1. Log Request
    final requestHeaders = <String, String>{};
    request.headers.forEach((k, v) => requestHeaders[k] = v);

    String? requestBody;
    if (request is http.Request && request.body.isNotEmpty) {
      requestBody = request.body;
    }

    final networkLog =
        NetworkLog(
            id: requestId,
            url: request.url.toString(),
            method: request.method,
            timestamp: startTime,
          )
          ..request = RequestDetails(
            headers: requestHeaders,
            body: _tryFormatJson(requestBody),
            contentType: request.headers['content-type'] ?? '',
          );

    EasyDebugManager().addLog(networkLog);

    try {
      // 2. Send Request
      final response = await _inner.send(request);

      // 3. Log Response (Streamed)
      // Note: We need to copy the stream to read it without consuming it from the caller's perspective,
      // OR we just wait for the bytes. For BaseClient.send, it returns a StreamedResponse.
      // Reading the stream here would consume it, breaking the caller.
      //
      // Solution: We transform the stream to tap into the data as it flows through.

      final responseBodyBytes = <int>[];
      final originalStream = response.stream;

      final transformer = StreamTransformer<List<int>, List<int>>.fromHandlers(
        handleData: (data, sink) {
          responseBodyBytes.addAll(data);
          sink.add(data);
        },
        handleDone: (sink) {
          sink.close();
          // Stream is done, we have the full body bytes now.
          _logResponse(networkLog, response, responseBodyBytes, DateTime.now());
        },
        handleError: (error, stackTrace, sink) {
          sink.addError(error, stackTrace);
          // Log error if stream fails
          EasyDebugManager().updateLog(
            networkLog.copyWith(
              error: ErrorDetails(
                errorMessage: error.toString(),
                stackTrace: stackTrace.toString(),
              ),
              durationMs: DateTime.now().difference(startTime).inMilliseconds,
            ),
          );
        },
      );

      final newStream = originalStream.transform(transformer);

      return http.StreamedResponse(
        newStream,
        response.statusCode,
        contentLength: response.contentLength,
        request: response.request,
        headers: response.headers,
        isRedirect: response.isRedirect,
        persistentConnection: response.persistentConnection,
        reasonPhrase: response.reasonPhrase,
      );
    } catch (e, stack) {
      // 4. Handle Transport Error
      EasyDebugManager().updateLog(
        networkLog.copyWith(
          error: ErrorDetails(
            errorMessage: e.toString(),
            stackTrace: stack.toString(),
          ),
          durationMs: DateTime.now().difference(startTime).inMilliseconds,
        ),
      );
      rethrow;
    }
  }

  void _logResponse(
    NetworkLog log,
    http.StreamedResponse response,
    List<int> bodyBytes,
    DateTime endTime,
  ) {
    String? responseBody;
    try {
      responseBody = utf8.decode(bodyBytes, allowMalformed: true);
    } catch (_) {
      responseBody = '<binary data>';
    }

    final responseHeaders = <String, String>{};
    response.headers.forEach((k, v) => responseHeaders[k] = v);

    EasyDebugManager().updateLog(
      log.copyWith(
        response: ResponseDetails(
          statusCode: response.statusCode,
          headers: responseHeaders,
          body: _tryFormatJson(responseBody),
          timestamp: endTime,
        ),
        durationMs: endTime.difference(log.timestamp).inMilliseconds,
      ),
    );
  }

  String? _tryFormatJson(String? body) {
    if (body == null) return null;
    try {
      final decoded = jsonDecode(body);
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(decoded);
    } catch (_) {
      return body;
    }
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
