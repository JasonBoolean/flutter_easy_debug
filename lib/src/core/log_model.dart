/// Represents simple configuration entries for Easy Debug
class EasyDebugConfig {
  /// Whether to clear logs when navigation (push) happens.
  /// Default: false
  final bool clearOnNavigation;

  /// Maximum number of logs to keep in memory.
  /// Default: 50
  final int maxLogCount;

  const EasyDebugConfig({
    this.clearOnNavigation = false,
    this.maxLogCount = 50,
  });
}

/// Represents a single network request/response log
class NetworkLog {
  final String id;
  final DateTime timestamp;
  final String method;
  final String url;

  RequestDetails? request;
  ResponseDetails? response;
  ErrorDetails? error;

  int? durationMs;

  NetworkLog({
    String? id,
    required this.timestamp,
    required this.method,
    required this.url,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  bool get isError =>
      error != null ||
      (response != null && (response!.statusCode ?? 200) >= 400);

  int get statusCode => response?.statusCode ?? 0;

  NetworkLog copyWith({
    String? id,
    DateTime? timestamp,
    String? method,
    String? url,
    RequestDetails? request,
    ResponseDetails? response,
    ErrorDetails? error,
    int? durationMs,
  }) {
    return NetworkLog(
        id: id ?? this.id,
        timestamp: timestamp ?? this.timestamp,
        method: method ?? this.method,
        url: url ?? this.url,
      )
      ..request = request ?? this.request
      ..response = response ?? this.response
      ..error = error ?? this.error
      ..durationMs = durationMs ?? this.durationMs;
  }
}

class RequestDetails {
  final Map<String, dynamic> headers;
  final dynamic body;
  final String contentType;

  RequestDetails({this.headers = const {}, this.body, this.contentType = ''});
}

class ResponseDetails {
  final int? statusCode;
  final Map<String, dynamic> headers;
  final dynamic body;
  final DateTime timestamp;

  ResponseDetails({
    this.statusCode,
    this.headers = const {},
    this.body,
    required this.timestamp,
  });
}

class ErrorDetails {
  final String errorMessage;
  final String? errorType;
  final dynamic errorObject;
  final String? stackTrace;

  ErrorDetails({
    required this.errorMessage,
    this.errorType,
    this.errorObject,
    this.stackTrace,
  });
}

class GeneralLog {
  final DateTime timestamp;
  final String message;
  final String? level; // e.g., 'INFO', 'ERROR'

  GeneralLog({required this.timestamp, required this.message, this.level});
}
