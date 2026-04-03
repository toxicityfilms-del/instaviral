import 'package:dio/dio.dart';

import 'package:reelboost_ai/core/l10n/app_strings.dart';
import 'package:reelboost_ai/core/utils/dio_error_message.dart';
import 'package:reelboost_ai/services/reelboost_api_service.dart';

/// User-facing text for failures from the reelboost API layer or Dio.
String apiErrorMessage(Object error) {
  if (error is ApiException) return error.message;
  if (error is PostAnalyzeLimitException) return error.message;
  if (error is DioException) {
    return dioErrorMessage(error) ?? error.message ?? 'Request failed';
  }
  return error.toString();
}

/// Message for post-analyze failures (network, server, invalid JSON); not used for post-analyze limit errors.
String analyzePostErrorMessage(Object error) {
  if (error is PostAnalyzeLimitException) return error.message;
  if (error is ApiException) {
    final m = error.message.trim();
    if (m.isEmpty) return 'Couldn’t analyze this post. Please try again.';
    return m;
  }
  if (error is DioException) {
    final fromBody = dioErrorMessage(error);
    if (fromBody != null && fromBody.trim().isNotEmpty) return fromBody.trim();
    final code = error.response?.statusCode;
    if (code != null && code >= 500) {
      return 'The server had a problem. Try again in a moment.';
    }
    if (code == 401) {
      return 'Your session expired. Sign in again to continue.';
    }
    if (code == 403) {
      return 'You don’t have permission to run this action. Check your account or try again.';
    }
    if (code == 429) {
      return 'Too many requests right now. Wait a minute and try again. If it persists, check API quota.';
    }
    return error.message ?? 'Couldn’t reach the server. Check your connection and try again.';
  }
  return apiErrorMessage(error);
}

/// Localized analyze errors (Hindi / English) for in-app snackbars.
String analyzePostErrorMessageLocalized(Object error, AppStrings s) {
  if (error is PostAnalyzeLimitException) return error.message;
  if (error is ApiException) {
    final m = error.message.trim();
    if (m.isEmpty) return s.errorGenericAnalyze;
    return m;
  }
  if (error is DioException) {
    final fromBody = dioErrorMessage(error);
    if (fromBody != null && fromBody.trim().isNotEmpty) return fromBody.trim();
    final code = error.response?.statusCode;
    if (code != null && code >= 500) return s.errorServer;
    if (code == 401) return s.errorSession;
    if (code == 403) {
      return 'You don’t have permission to run this action. Check your account or try again.';
    }
    if (code == 429) return s.errorTooManyRequests;
    return error.message ?? s.errorNetwork;
  }
  return apiErrorMessage(error);
}

/// Whether the user can retry the same request (e.g. network blip, 5xx).
bool isRetryableAnalyzeError(Object error) {
  if (error is PostAnalyzeLimitException) return false;
  if (error is ApiException) return true;
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badResponse:
        final c = error.response?.statusCode ?? 0;
        if (c == 429) {
          String bodyMsg = '';
          final data = error.response?.data;
          if (data is Map) {
            final m = data['message']?.toString();
            if (m != null) bodyMsg = m;
          }
          final m = '${error.message ?? ''} $bodyMsg'.toLowerCase();
          final quota =
              m.contains('exceeded your current quota') ||
              m.contains('insufficient_quota') ||
              m.contains('check your plan and billing');
          return !quota;
        }
        return c >= 500 || c == 408;
      case DioExceptionType.unknown:
        return true;
      case DioExceptionType.badCertificate:
      case DioExceptionType.cancel:
        return false;
    }
  }
  return false;
}
