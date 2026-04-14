import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:reelboost_ai/models/caption_models.dart';
import 'package:reelboost_ai/models/post_analysis_models.dart';

import 'package:reelboost_ai/models/hashtag_models.dart';
import 'package:reelboost_ai/models/trends_models.dart';
import 'package:reelboost_ai/models/user_model.dart';
import 'package:reelboost_ai/models/viral_models.dart';

class ApiException implements Exception {
  const ApiException(this.message, [this.code]);
  final String message;
  /// Server error code when present (e.g. `REWARD_COOLDOWN`).
  final String? code;

  @override
  String toString() => message;
}

/// Free plan hit the daily post-analyze cap (`403` + `POST_ANALYZE_LIMIT`).
class PostAnalyzeLimitException implements Exception {
  PostAnalyzeLimitException({
    required this.message,
    this.limit = 5,
    this.used,
  });

  final String message;
  final int limit;
  final int? used;

  @override
  String toString() => message;
}

/// REST paths (`/hashtag/...`, etc.). Dio is configured with the same base URL as the app-wide API base URL.
class ReelboostApiService {
  ReelboostApiService(this._dio);

  final Dio _dio;

  Future<HashtagBuckets> generateHashtags(String keyword) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/hashtag/generate',
      data: {'keyword': keyword},
    );
    return _unwrapData(res, HashtagBuckets.fromJson);
  }

  Future<CaptionResult> generateCaption(String idea) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/caption/generate',
      data: {'idea': idea},
    );
    return _unwrapData(res, CaptionResult.fromJson);
  }

  Future<List<String>> generateIdeas(String niche) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/ideas/generate',
      data: {'niche': niche},
    );
    final data = _unwrapMap(res);
    final ideas = data['ideas'] as List<dynamic>? ?? [];
    return ideas.map((e) => e.toString()).toList();
  }

  Future<ViralAnalysis> analyzeViral({
    required String caption,
    String hashtags = '',
    String niche = '',
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/viral/analyze',
      data: {
        'caption': caption,
        'hashtags': hashtags,
        'niche': niche.trim(),
      },
    );
    return _unwrapData(res, ViralAnalysis.fromJson);
  }

  Future<TrendsPayload> getTrends() async {
    final res = await _dio.get<Map<String, dynamic>>('/trends');
    return _unwrapData(res, TrendsPayload.fromJson);
  }

  Future<UserModel> getProfileMe() async {
    final res = await _dio.get<Map<String, dynamic>>('/profile/me');
    return _unwrapData(res, UserModel.fromJson);
  }

  Future<UserModel> saveProfile({
    required String name,
    required String bio,
    required String instagram,
    required String facebook,
    required String niche,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/profile/save',
      data: {
        'name': name,
        'bio': bio,
        'instagram': instagram,
        'facebook': facebook,
        'niche': niche,
      },
    );
    return _unwrapData(res, UserModel.fromJson);
  }

  Future<PostAnalyzeResponse> analyzePost({
    String? idea,
    String? imageBase64,
    String? creatorNiche,
    String? creatorBio,
  }) async {
    final data = <String, dynamic>{
      // Always send profile fields so the API can tailor prompts (empty = not set on profile).
      'niche': (creatorNiche ?? '').trim(),
      'bio': (creatorBio ?? '').trim(),
    };
    if (idea != null && idea.trim().isNotEmpty) data['idea'] = idea.trim();
    if (imageBase64 != null && imageBase64.trim().isNotEmpty) {
      data['imageBase64'] = imageBase64.trim();
    }
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/post/analyze',
        data: data,
      );
      return _unwrapPostAnalyze(res);
    } on DioException catch (e) {
      final limit = _postAnalyzeLimitFromDio(e);
      if (limit != null) {
        throw limit;
      }
      rethrow;
    }
  }

  /// Upload image/video (multipart) and analyze it using a thumbnail (for video) + niche/bio.
  ///
  /// `mediaBytes`: raw uploaded file bytes (image/* or video/*).
  /// `mediaFileName`: file name (best-effort).
  /// `mediaMime`: MIME type (e.g. image/jpeg, video/mp4).
  /// `thumbnailDataUrl`: required for video uploads; optional for images.
  Future<PostAnalyzeResponse> analyzeMedia({
    required List<int> mediaBytes,
    required String mediaFileName,
    required String mediaMime,
    String? thumbnailDataUrl,
    String? creatorNiche,
    String? creatorBio,
    String? notes,
  }) async {
    final form = FormData.fromMap({
      'media': MultipartFile.fromBytes(
        mediaBytes,
        filename: mediaFileName,
        contentType: DioMediaType.parse(mediaMime),
      ),
      'niche': (creatorNiche ?? '').trim(),
      'bio': (creatorBio ?? '').trim(),
      'notes': (notes ?? '').trim(),
      if (thumbnailDataUrl != null && thumbnailDataUrl.trim().isNotEmpty)
        'thumbnailDataUrl': thumbnailDataUrl.trim(),
    });
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/post/analyze-media',
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );
      return _unwrapPostAnalyze(res);
    } on DioException catch (e) {
      final limit = _postAnalyzeLimitFromDio(e);
      if (limit != null) throw limit;
      rethrow;
    }
  }

  static const String _defaultLimitMessage =
      "You've reached today's limit for free post analyses. Upgrade to Premium for unlimited analyses.";

  /// Detects `403` with `code` `POST_ANALYZE_LIMIT` (case-insensitive).
  PostAnalyzeLimitException? _postAnalyzeLimitFromDio(DioException e) {
    if (e.response?.statusCode != 403) return null;
    final raw = _dioResponseDataMap(e.response?.data);
    if (raw == null) return null;
    final code = raw['code']?.toString();
    if (code == null || code.toUpperCase() != 'POST_ANALYZE_LIMIT') return null;
    final msg = raw['message']?.toString().trim();
    return PostAnalyzeLimitException(
      message: (msg != null && msg.isNotEmpty) ? msg : _defaultLimitMessage,
      limit: (raw['limit'] as num?)?.toInt() ?? 5,
      used: (raw['used'] as num?)?.toInt(),
    );
  }

  /// Dio may deserialize JSON as `Map<dynamic, dynamic>` or a raw string; normalize for code checks.
  Map<String, dynamic>? _dioResponseDataMap(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String && data.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return null;
  }

  /// Prefer values from response headers when present (same instant as JSON `meta`).
  static int? _rateLimitIntHeader(Response<dynamic> response, String name) {
    final raw = response.headers.value(name);
    if (raw == null) return null;
    final t = raw.trim();
    if (t.isEmpty) return null;
    return int.tryParse(t);
  }

  PostAnalyzeResponse _unwrapPostAnalyze(Response<Map<String, dynamic>> res) {
    final body = res.data;
    if (body == null || body['success'] != true) {
      throw ApiException(body?['message']?.toString() ?? 'Request failed');
    }
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Invalid response shape');
    }
    final meta = body['meta'];
    var isPremium = false;
    int? lim;
    int? rem;
    int? adRem;
    if (meta is Map<String, dynamic>) {
      isPremium = meta['isPremium'] == true;
      lim = (meta['postAnalyzeLimit'] as num?)?.toInt();
      rem = (meta['postAnalyzeRemaining'] as num?)?.toInt();
      adRem = (meta['postAnalyzeAdRewardsRemaining'] as num?)?.toInt();
    }
    if (!isPremium) {
      final limH = _rateLimitIntHeader(res, 'x-ratelimit-limit');
      final remH = _rateLimitIntHeader(res, 'x-ratelimit-remaining');
      if (limH != null) lim = limH;
      if (remH != null) rem = remH;
    }
    return PostAnalyzeResponse(
      result: PostAnalysisResult.fromJson(data),
      isPremium: isPremium,
      postAnalyzeLimit: lim,
      postAnalyzeRemaining: rem,
      postAnalyzeAdRewardsRemaining: adRem,
    );
  }

  /// Server grants +1 effective post-analyze slot after a rewarded ad (max 3/day).
  Future<Map<String, dynamic>> grantPostAnalyzeAdReward({
    required String completionId,
    required int completedAtMs,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/usage/ad-reward',
        data: {
          'completionId': completionId,
          'completedAtMs': completedAtMs,
        },
      );
      final body = res.data;
      if (body == null || body['success'] != true) {
        throw ApiException(body?['message']?.toString() ?? 'Request failed');
      }
      final data = body['data'];
      if (data is! Map<String, dynamic>) {
        throw const ApiException('Invalid response shape');
      }
      return data;
    } on DioException catch (e) {
      final raw = _dioResponseDataMap(e.response?.data);
      if (e.response?.statusCode == 400 && raw != null) {
        final msg = raw['message']?.toString() ?? 'Request failed';
        final code = raw['code']?.toString();
        throw ApiException(msg, code);
      }
      rethrow;
    }
  }

  Map<String, dynamic> _unwrapMap(Response<Map<String, dynamic>> res) {
    final body = res.data;
    if (body == null || body['success'] != true) {
      throw ApiException(body?['message']?.toString() ?? 'Request failed');
    }
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Invalid response shape');
    }
    return data;
  }

  T _unwrapData<T>(
    Response<Map<String, dynamic>> res,
    T Function(Map<String, dynamic> json) parse,
  ) {
    final data = _unwrapMap(res);
    return parse(data);
  }
}
