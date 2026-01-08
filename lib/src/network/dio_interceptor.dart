import 'package:dio/dio.dart';
import '../core/log_manager.dart';
import '../core/log_model.dart';

class EasyDebugDioInterceptor extends Interceptor {
  final Map<String, String> _requestMap = {};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final requestId = DateTime.now().microsecondsSinceEpoch.toString();
    _requestMap[options.uri.toString()] = requestId;

    final log = NetworkLog(
      id: requestId,
      timestamp: DateTime.now(),
      method: options.method,
      url: options.uri.toString(),
    );

    log.request = RequestDetails(
      headers: options.headers,
      body: options.data,
      contentType: options.contentType ?? '',
    );

    EasyDebugManager().addLog(log);

    // Store custom property to track this request in onResponse/onError if needed,
    // though we can't easily modify RequestOptions to store arbitrary data in a clean way
    // without using `extra`.
    options.extra['easy_debug_id'] = requestId;
    options.extra['easy_debug_start_time'] =
        DateTime.now().millisecondsSinceEpoch;

    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final requestId = response.requestOptions.extra['easy_debug_id'] as String?;
    final startTime =
        response.requestOptions.extra['easy_debug_start_time'] as int?;

    // We need to find the log in Manager. Since Manager holds a list, we technically should
    // have a better lookup mechanism than iterating, but for debug purposes and small list size (50),
    // iteration is fine. However, since we re-create the list in Manager, we should find the reference.

    // Actually, simple way: we already added the log object. We should probably keep a reference to it?
    // But `onRequest` creates it. `onResponse` is separate.
    // Ideally Manager should have `getLogById` or `updateLog`.
    // For now let's iterate to find the partial log.

    // BETTER APPROACH: Manager exposes logs. We can find by ID.
    final logs = EasyDebugManager().logsNotifier.value;
    try {
      final log = logs.firstWhere((element) => element.id == requestId);

      log.response = ResponseDetails(
        statusCode: response.statusCode,
        headers: response.headers.map,
        body: response.data,
        timestamp: DateTime.now(),
      );

      if (startTime != null) {
        log.durationMs = DateTime.now().millisecondsSinceEpoch - startTime;
      }

      EasyDebugManager().updateLog(log);
    } catch (e) {
      // Log might have been cleared or not found
    }

    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final requestId = err.requestOptions.extra['easy_debug_id'] as String?;
    final startTime = err.requestOptions.extra['easy_debug_start_time'] as int?;

    final logs = EasyDebugManager().logsNotifier.value;
    try {
      final log = logs.firstWhere((element) => element.id == requestId);

      log.error = ErrorDetails(
        errorMessage: err.message ?? 'Unknown Error',
        errorType: err.type.toString(),
        errorObject: err.error,
        stackTrace: err.stackTrace.toString(),
      );

      // Also capture response if available in error (e.g. 404/500)
      if (err.response != null) {
        log.response = ResponseDetails(
          statusCode: err.response?.statusCode,
          headers: err.response?.headers.map ?? {},
          body: err.response?.data,
          timestamp: DateTime.now(),
        );
      }

      if (startTime != null) {
        log.durationMs = DateTime.now().millisecondsSinceEpoch - startTime;
      }

      EasyDebugManager().updateLog(log);
    } catch (e) {
      // Log not found
    }

    super.onError(err, handler);
  }
}
