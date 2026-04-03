import 'package:dio/dio.dart';

String? _bodyMessage(DioException e) {
  final data = e.response?.data;
  if (data is Map) {
    final message = data['message'];
    if (message != null && message.toString().trim().isNotEmpty) {
      return message.toString();
    }
    final errs = data['errors'];
    if (errs is List && errs.isNotEmpty) {
      final first = errs.first;
      if (first is Map && first['msg'] != null) {
        return first['msg'].toString();
      }
    }
  }
  return null;
}

/// User-facing text for [DioException] (network, TLS, HTTP status).
String? dioErrorMessage(Object e) {
  if (e is! DioException) return null;

  if (e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.sendTimeout ||
      e.type == DioExceptionType.receiveTimeout) {
    return 'Request timed out. Check your internet connection and that the API is reachable.';
  }

  if (e.type == DioExceptionType.connectionError) {
    final m = (e.message ?? '').toLowerCase();
    if (m.contains('failed host lookup')) {
      return 'Could not reach the server. Check the API URL and your connection.';
    }
    if (m.contains('connection refused')) {
      return 'Could not connect to the server. It may be down or the URL may be wrong.';
    }
    return 'Network error. Check your connection and try again.';
  }

  if (e.type == DioExceptionType.badCertificate) {
    return 'Secure connection failed. Check your network or device date and time.';
  }

  if (e.type == DioExceptionType.cancel) {
    return 'Request was cancelled.';
  }

  if (e.type == DioExceptionType.badResponse) {
    final fromBody = _bodyMessage(e);
    if (fromBody != null) return fromBody;
    final code = e.response?.statusCode;
    if (code == 401) {
      return 'Your session expired or credentials are invalid. Sign in again.';
    }
    if (code == 403) {
      return 'You don’t have permission for this action.';
    }
    if (code == 429) {
      return 'Too many requests. Wait a moment and try again.';
    }
    if (code != null && code >= 500) {
      return 'The server had a problem. Try again in a moment.';
    }
    return e.message ?? 'Request failed';
  }

  final fromBody = _bodyMessage(e);
  if (fromBody != null) return fromBody;

  if (e.type == DioExceptionType.unknown && e.error != null) {
    return 'Something went wrong (${e.error}). Check your connection and try again.';
  }

  return e.message ?? 'Request failed';
}
