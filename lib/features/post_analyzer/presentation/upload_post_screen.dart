import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:reelboost_ai/core/ads/ad_policy.dart';
import 'package:reelboost_ai/core/ads/ads_support.dart';
import 'package:reelboost_ai/core/ads/app_ads_service.dart';
import 'package:reelboost_ai/core/haptics/app_haptics.dart';
import 'package:reelboost_ai/core/l10n/app_strings.dart';
import 'package:reelboost_ai/core/notifications/local_notifications_service.dart';
import 'package:reelboost_ai/core/providers/app_providers.dart';
import 'package:reelboost_ai/core/theme/app_theme.dart';
import 'package:reelboost_ai/core/services/analysis_history_service.dart';
import 'package:reelboost_ai/core/utils/api_error_message.dart';
import 'package:reelboost_ai/core/utils/post_analysis_pack.dart';
import 'package:reelboost_ai/widgets/app_card.dart';
import 'package:reelboost_ai/features/profile/presentation/profile_screen.dart';
import 'package:reelboost_ai/features/analyze_media/presentation/analyze_media_screen.dart';
import 'package:reelboost_ai/models/post_analysis_models.dart';
import 'package:reelboost_ai/models/user_model.dart';
import 'package:reelboost_ai/services/reelboost_api_service.dart';
import 'package:reelboost_ai/services/payments/razorpay_payment_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reelboost_ai/widgets/gradient_button.dart';
import 'package:share_plus/share_plus.dart';

Future<void> _copyToClipboard(BuildContext context, String text, String message) async {
  AppHaptics.copy();
  await Clipboard.setData(ClipboardData(text: text));
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

/// Upload post + idea → `POST /api/post/analyze` (optional image). Video analysis lives in Analyze Media.
class UploadPostScreen extends ConsumerStatefulWidget {
  const UploadPostScreen({super.key});

  @override
  ConsumerState<UploadPostScreen> createState() => _UploadPostScreenState();
}

class _UploadPostScreenState extends ConsumerState<UploadPostScreen> {
  static const String _ideaDraftKey = 'upload_post_idea_draft_v1';
  static const String _lastFailKey = 'upload_post_last_fail_v1';

  final _idea = TextEditingController();
  final _picker = ImagePicker();
  /// Non-null only in non-release builds (Razorpay is not used for Play Store release).
  RazorpayPaymentService? _payments;

  XFile? _imageFile;
  String? _imageDataUrl;
  Uint8List? _previewBytes;

  PostAnalysisResult? _result;
  bool _resultIsPremium = false;
  bool _loading = false;
  bool _rewardLoading = false;
  bool _retryingReward = false;
  String? _pendingRewardCompletionId;
  int? _pendingRewardCompletedAtMs;
  String? _lastFailIdea;

  @override
  void initState() {
    super.initState();
    if (!kReleaseMode) {
      _payments = RazorpayPaymentService()..init();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _sanitizeStaleFreeLimitCache();
      await _syncProfileFromServer();
      await _restorePendingRewardState();
      final prefs = await SharedPreferences.getInstance();
      final draft = prefs.getString(_ideaDraftKey);
      if (!mounted) return;
      if (draft != null && draft.isNotEmpty) {
        _idea.text = draft;
        setState(() {});
      }
      final fail = prefs.getString(_lastFailKey);
      if (!mounted) return;
      if (fail != null && fail.isNotEmpty) {
        setState(() => _lastFailIdea = fail);
      }
    });
  }

  void _sanitizeStaleFreeLimitCache() {
    final session = ref.read(authControllerProvider).asData?.value;
    if (session == null || AdPolicy.isPremium(session)) return;
    final staleLimit = session.postAnalyzeLimit == 5;
    final staleRemaining = session.postAnalyzeRemaining == 5;
    if (!staleLimit && !staleRemaining) return;
    ref.read(authControllerProvider.notifier).applyUser(
          session.copyWith(
            postAnalyzeLimit: staleLimit ? 3 : session.postAnalyzeLimit,
            postAnalyzeRemaining: staleRemaining
                ? 3
                : (session.postAnalyzeRemaining == null
                    ? null
                    : session.postAnalyzeRemaining!.clamp(0, 3)),
          ),
        );
  }

  @override
  void dispose() {
    final ideaText = _idea.text;
    SharedPreferences.getInstance().then((p) => p.setString(_ideaDraftKey, ideaText));
    _payments?.dispose();
    _idea.dispose();
    super.dispose();
  }

  Future<void> _syncProfileFromServer() async {
    try {
      final u = await ref.read(reelboostApiProvider).getProfileMe();
      ref.read(authControllerProvider.notifier).applyUser(u);
      if (mounted) setState(() {});
    } catch (_) {
      // Keep cached session; analyzer still works.
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final x = await _picker.pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (x == null || !mounted) return;
    final bytes = await x.readAsBytes();
    final mime = _mimeFromName(x.name.isNotEmpty ? x.name : x.path);
    final b64 = base64Encode(bytes);
    setState(() {
      _imageFile = x;
      _previewBytes = bytes;
      _imageDataUrl = 'data:$mime;base64,$b64';
    });
  }

  String _mimeFromName(String name) {
    final n = name.toLowerCase();
    if (n.endsWith('.png')) return 'image/png';
    if (n.endsWith('.webp')) return 'image/webp';
    if (n.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  void _clearImage() {
    setState(() {
      _imageFile = null;
      _imageDataUrl = null;
      _previewBytes = null;
    });
  }

  bool _isAtDailyLimit(UserModel? session) {
    if (session == null) return false;
    if (!AdPolicy.enforcePostAnalyzeLimits(session)) return false;
    final r = session.postAnalyzeRemaining;
    final cap = session.postAnalyzeLimit ?? 3;
    if (r == null) return false;
    return r.clamp(0, cap) <= 0;
  }

  bool get _hasPendingReward =>
      _pendingRewardCompletionId != null && _pendingRewardCompletedAtMs != null;

  String _pendingRewardIdKey(UserModel? u) =>
      'pending_reward_claim_id_${u?.id ?? "anon"}';
  String _pendingRewardAtKey(UserModel? u) =>
      'pending_reward_claim_at_${u?.id ?? "anon"}';

  String _newRewardCompletionId(UserModel? u) {
    final uid = (u?.id ?? 'anon').replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    final ts = DateTime.now().millisecondsSinceEpoch;
    final r = Random().nextInt(1 << 31);
    return 'rw_${uid}_${ts}_$r';
  }

  Future<void> _savePendingRewardState({
    required String completionId,
    required int completedAtMs,
  }) async {
    _pendingRewardCompletionId = completionId;
    _pendingRewardCompletedAtMs = completedAtMs;
    final s = ref.read(authControllerProvider).asData?.value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingRewardIdKey(s), completionId);
    await prefs.setInt(_pendingRewardAtKey(s), completedAtMs);
    if (mounted) setState(() {});
  }

  Future<void> _clearPendingRewardState() async {
    final s = ref.read(authControllerProvider).asData?.value;
    _pendingRewardCompletionId = null;
    _pendingRewardCompletedAtMs = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingRewardIdKey(s));
    await prefs.remove(_pendingRewardAtKey(s));
    if (mounted) setState(() {});
  }

  Future<void> _restorePendingRewardState() async {
    final s = ref.read(authControllerProvider).asData?.value;
    if (s == null || AdPolicy.isPremium(s)) {
      await _clearPendingRewardState();
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_pendingRewardIdKey(s));
    final at = prefs.getInt(_pendingRewardAtKey(s));
    if (id == null || at == null) return;
    _pendingRewardCompletionId = id;
    _pendingRewardCompletedAtMs = at;
    if (mounted) setState(() {});
  }

  /// Remaining and cap for free users; null values mean server usage isn't synced yet.
  (int?, int?) _freeUsageNumbers(UserModel? session) {
    if (session == null) return (null, null);
    if (!AdPolicy.enforcePostAnalyzeLimits(session)) return (null, null);
    final cap = session.postAnalyzeLimit ?? 3;
    final r = (session.postAnalyzeRemaining != null && cap != null)
        ? session.postAnalyzeRemaining!.clamp(0, cap)
        : session.postAnalyzeRemaining;
    return (r, cap);
  }

  String _analyzeButtonLabel(UserModel? session) {
    if (_loading) return 'Analyzing…';
    if (_isAtDailyLimit(session)) return 'Daily limit reached';
    return 'Analyze post';
  }

  Future<void> _openProfileForUpgrade(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
    );
  }

  Future<void> _watchAdForBonus() async {
    final session = ref.read(authControllerProvider).asData?.value;
    if (!AdPolicy.showAds(session)) return;
    if (!supportsMobileAds) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rewarded ads are not available on this platform.')),
      );
      return;
    }
    if (_rewardLoading || _loading || _hasPendingReward || _retryingReward) return;
    setState(() => _rewardLoading = true);
    try {
      final earned = await AppAdsService.showRewardedForBonus(user: session);
      if (!mounted) return;
      if (!earned) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Watch the full ad to unlock 1 more analysis. Close early and it won’t count.',
            ),
          ),
        );
        return;
      }
      final completionId = _newRewardCompletionId(session);
      final completedAtMs = DateTime.now().millisecondsSinceEpoch;
      // Requirement: always attempt claim after a completed ad.
      await _claimReward(completionId: completionId, completedAtMs: completedAtMs);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _rewardLoading = false);
    }
  }

  Future<void> _claimReward({
    required String completionId,
    required int completedAtMs,
  }) async {
    try {
      final api = ref.read(reelboostApiProvider);
      final data = await api.grantPostAnalyzeAdReward(
        completionId: completionId,
        completedAtMs: completedAtMs,
      );
      final s = ref.read(authControllerProvider).asData?.value;
      final rem = (data['postAnalyzeRemaining'] as num?)?.toInt();
      final lim = (data['postAnalyzeLimit'] as num?)?.toInt();
      if (s != null) {
        // Client trusts server usage values.
        ref.read(authControllerProvider.notifier).applyUser(
              s.copyWith(
                isPremium: data['isPremium'] == true,
                postAnalyzeLimit: lim,
                postAnalyzeRemaining: rem,
                postAnalyzeAdRewardsRemaining:
                    (data['postAnalyzeAdRewardsRemaining'] as num?)?.toInt(),
              ),
            );
      }
      await _clearPendingRewardState();
      if (!mounted) return;
      final already = data['alreadyClaimed'] == true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            already
                ? (rem != null
                    ? 'Bonus already claimed earlier. $rem analyses remaining today.'
                    : 'Bonus already claimed earlier.')
                : (rem != null
                    ? (lim != null
                        ? 'Unlocked 1 analysis. $rem of $lim remaining today.'
                        : 'Unlocked 1 analysis. $rem remaining today.')
                    : 'Unlocked 1 more analysis. Your usage was updated.'),
          ),
        ),
      );
    } catch (e) {
      final cooldown = e is ApiException && e.code == 'REWARD_COOLDOWN';
      final suspended = e is ApiException && e.code == 'AD_REWARD_SUSPENDED';
      if (!cooldown && !suspended) {
        await _savePendingRewardState(
          completionId: completionId,
          completedAtMs: completedAtMs,
        );
      }
      if (!mounted) return;
      if (cooldown || suspended) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(apiErrorMessage(e))),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Ad watched but reward failed. Tap Retry to claim your bonus.',
          ),
          duration: const Duration(seconds: 8),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () {
              if (context.mounted) _retryPendingRewardClaim();
            },
          ),
        ),
      );
    }
  }

  Future<void> _retryPendingRewardClaim() async {
    final s = ref.read(authControllerProvider).asData?.value;
    if (AdPolicy.isPremium(s)) {
      await _clearPendingRewardState();
      return;
    }
    final id = _pendingRewardCompletionId;
    final at = _pendingRewardCompletedAtMs;
    if (id == null || at == null || _retryingReward || _loading || _rewardLoading) {
      return;
    }
    setState(() => _retryingReward = true);
    try {
      await _claimReward(completionId: id, completedAtMs: at);
    } finally {
      if (mounted) setState(() => _retryingReward = false);
    }
  }

  /// Shown when the user hits the server limit (403) or when already at 0 and they try to analyze.
  Future<void> _showDailyLimitDialog(BuildContext context, {String? serverDetail, int? limit}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.hourglass_disabled_rounded, color: AppTheme.accent2.withValues(alpha: 0.95), size: 36),
        title: const Text('Daily limit reached'),
        content: Text(
          [
            if (serverDetail != null && serverDetail.trim().isNotEmpty) serverDetail.trim(),
            limit != null
                ? 'You’ve used all $limit free post analyses for today. Upgrade to Premium for unlimited analyses every day.'
                : 'You’ve used all your free post analyses for today. Upgrade to Premium for unlimited analyses every day.',
          ].where((s) => s.isNotEmpty).join('\n\n'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _openProfileForUpgrade(context);
            },
            child: const Text('Upgrade to Premium'),
          ),
        ],
      ),
    );
  }

  Future<void> _showPremiumPitchDialog(BuildContext context, {String? detail}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.workspace_premium_rounded, color: AppTheme.accent.withValues(alpha: 0.95), size: 36),
        title: const Text('Upgrade to Premium'),
        content: Text(
          [
            if (detail != null && detail.isNotEmpty) detail,
            'Premium unlocks unlimited post analyses every day. '
                'Free accounts have a daily analysis limit.',
          ].where((s) => s.isNotEmpty).join('\n\n'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Maybe later'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _openProfileForUpgrade(context);
            },
            child: const Text('View plans'),
          ),
        ],
      ),
    );
  }

  Future<void> _showFreemiumLimitDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        title: const Text('Limit Reached'),
        content: const Text('Upgrade to Pro ₹199/month to continue'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await openPayment();
            },
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }

  Future<void> openPayment() async {
    final current = ref.read(authControllerProvider).asData?.value;
    if (current == null) return;
    try {
      final result = await _payments.buyPremium199(
        userId: current.id,
        email: current.email,
        name: current.name,
      );

      if (!mounted) return;

      if (result.status == PremiumPurchaseStatus.cancelled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment cancelled')),
        );
        return;
      }
      if (result.status == PremiumPurchaseStatus.failed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Payment failed')),
        );
        return;
      }

      final ok = await _payments.upgradeUserOnBackend(userId: current.id);
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upgrade failed. Please try again.')),
        );
        return;
      }

      final merged = current.withPostAnalyzeUsage(
        isPremium: true,
        postAnalyzeLimit: null,
        postAnalyzeRemaining: null,
        postAnalyzeAdRewardsRemaining: null,
      );
      ref.read(authControllerProvider.notifier).applyUser(merged);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are now Premium')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: $e')),
      );
    }
  }

  Future<void> _pickPostReminder() async {
    final strings = ref.read(appStringsProvider);
    await LocalNotificationsService.requestPermissionIfSupported();
    if (!mounted) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (t == null || !mounted) return;
    await LocalNotificationsService.scheduleDailyPostingReminder(
      time: t,
      title: strings.reminderNotifTitle,
      body: strings.reminderNotifBody,
    );
    final p = await SharedPreferences.getInstance();
    await p.setInt('post_reminder_hour_v1', t.hour);
    await p.setInt('post_reminder_minute_v1', t.minute);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(strings.snackReminderScheduled)));
  }

  Future<void> _analyze() async {
    final idea = _idea.text.trim();
    final hasImage = _imageDataUrl != null && _imageDataUrl!.isNotEmpty && _imageFile != null;
    if (idea.isEmpty && !hasImage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter an idea and/or add an image')),
      );
      return;
    }
    final sessionBefore = ref.read(authControllerProvider).asData?.value;
    if (_isAtDailyLimit(sessionBefore)) {
      if (!mounted) return;
      await _showDailyLimitDialog(context);
      return;
    }
    setState(() {
      _loading = true;
      _result = null;
    });
    final api = ref.read(reelboostApiProvider);
    final session = ref.read(authControllerProvider).asData?.value;
    try {
      final response = hasImage
          ? await api.analyzeMedia(
              mediaBytes: (await _imageFile!.readAsBytes()).toList(),
              mediaFileName:
                  _imageFile!.name.isNotEmpty ? _imageFile!.name : _imageFile!.path.split('/').last,
              mediaMime: _mimeFromName(_imageFile!.name.isNotEmpty ? _imageFile!.name : _imageFile!.path),
              thumbnailDataUrl: _imageDataUrl,
              creatorNiche: session?.niche ?? '',
              creatorBio: session?.bio ?? '',
              notes: idea.isEmpty ? null : idea,
            )
          : await api.analyzePost(
              idea: idea.isEmpty ? null : idea,
              imageBase64: null,
              creatorNiche: session?.niche ?? '',
              creatorBio: session?.bio ?? '',
            );
      if (session != null) {
        ref.read(authControllerProvider.notifier).applyUser(
              session.withPostAnalyzeUsage(
                isPremium: response.isPremium,
                postAnalyzeLimit: response.postAnalyzeLimit ?? session.postAnalyzeLimit,
                postAnalyzeRemaining: response.postAnalyzeRemaining ?? session.postAnalyzeRemaining,
                postAnalyzeAdRewardsRemaining:
                    response.postAnalyzeAdRewardsRemaining ?? session.postAnalyzeAdRewardsRemaining,
              ),
            );
      }
      if (!mounted) return;
      setState(() {
        _result = response.result;
        _resultIsPremium = response.isPremium;
        _lastFailIdea = null;
      });
      AppHaptics.success();
      unawaited(SharedPreferences.getInstance().then((p) => p.remove(_lastFailKey)));
      unawaited(
        AnalysisHistoryService.add(
          source: 'post_analyze',
          title: idea.isNotEmpty ? idea : 'Post analysis',
          result: response.result,
        ),
      );
      final rem = response.postAnalyzeRemaining;
      if (response.isPremium != true && rem != null && rem <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('That was your last free analysis for today.'),
            action: SnackBarAction(
              label: 'Upgrade',
              onPressed: () {
                if (context.mounted) _openProfileForUpgrade(context);
              },
            ),
          ),
        );
      }
    } on PostAnalyzeLimitException catch (e) {
      if (!mounted) return;
      await _showDailyLimitDialog(
        context,
        serverDetail: e.message,
        limit: e.limit,
      );
      if (session != null) {
        ref.read(authControllerProvider.notifier).applyUser(
              session.withPostAnalyzeUsage(
                isPremium: false,
                postAnalyzeLimit: e.limit ?? session.postAnalyzeLimit,
                postAnalyzeRemaining: 0,
                postAnalyzeAdRewardsRemaining: session.postAnalyzeAdRewardsRemaining,
              ),
            );
      }
    } catch (e) {
      if (!mounted) return;
      if (e is ApiException && e.code == 'LIMIT_REACHED') {
        await _showDailyLimitDialog(
          context,
          serverDetail: 'You have used your 3 free analyses today',
          limit: session?.postAnalyzeLimit,
        );
        return;
      }
      final strings = ref.read(appStringsProvider);
      final msg = analyzePostErrorMessageLocalized(e, strings);
      final showRetry = isRetryableAnalyzeError(e);
      unawaited(
        SharedPreferences.getInstance().then((p) => p.setString(_lastFailKey, idea)),
      );
      setState(() => _lastFailIdea = idea);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          duration: const Duration(seconds: 8),
          action: showRetry
              ? SnackBarAction(
                  label: strings.retry,
                  onPressed: () {
                    if (context.mounted) _analyze();
                  },
                )
              : null,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authControllerProvider).asData?.value;
    final userIsFree = session?.isPremium == false;
    final niche = session?.niche.trim() ?? '';
    final hasNiche = niche.isNotEmpty;
    final atDailyLimit = _isAtDailyLimit(session);
    final freeUsage =
        AdPolicy.enforcePostAnalyzeLimits(session) ? _freeUsageNumbers(session) : null;
    final s = ref.watch(appStringsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Upload post')),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.scaffoldGradient(context)),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_lastFailIdea != null) ...[
                  AppCard(
                    padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.amber.shade400),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            s.analyzeFailBanner,
                            style: TextStyle(color: AppTheme.onCardSecondary(context), height: 1.35),
                          ),
                        ),
                        TextButton(onPressed: _loading ? null : _analyze, child: Text(s.retry)),
                        IconButton(
                          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                          onPressed: () async {
                            await SharedPreferences.getInstance().then((p) => p.remove(_lastFailKey));
                            if (mounted) setState(() => _lastFailIdea = null);
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  'Post analyzer',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  'Describe your Instagram idea. Optionally attach an image. For video, use Analyze Media on Home.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.58), height: 1.35),
                ),
                const SizedBox(height: 14),
                if (hasNiche)
                  _NicheConnectedChip(niche: niche)
                else
                  _MissingNicheWarning(
                    onOpenProfile: () async {
                      await Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
                      );
                      await _syncProfileFromServer();
                    },
                  ),
                if (session != null) ...[
                  const SizedBox(height: 12),
                  _UsageTierBanner(
                    session: session,
                    onUpgradeTap: () => _showPremiumPitchDialog(context),
                  ),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: _idea,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Idea',
                    hintText: 'e.g. morning routine GRWM, product unboxing, funny skit…',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Media (optional)',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Text(
                  'Image',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                if (_previewBytes != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.memory(
                      _previewBytes!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(onPressed: _clearImage, child: const Text('Remove image')),
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('Gallery'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: const Text('Camera'),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  'Video',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                AppCard(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome_mosaic_rounded, color: AppTheme.accent2.withValues(alpha: 0.9), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Use Analyze Media for video uploads and smarter results.',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.72), height: 1.35, fontSize: 12.5),
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton.tonal(
                        onPressed: _loading
                            ? null
                            : () {
                                Navigator.of(context).push<void>(
                                  MaterialPageRoute<void>(builder: (_) => const AnalyzeMediaScreen()),
                                );
                              },
                        child: const Text('Open'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (freeUsage != null) ...[
                  _FreeUsageHighlight(
                    remaining: freeUsage.$1,
                    cap: freeUsage.$2,
                    atLimit: atDailyLimit,
                  ),
                  const SizedBox(height: 14),
                ],
                GradientButton(
                  label: _analyzeButtonLabel(session),
                  loading: _loading,
                  onPressed: (_loading || atDailyLimit) ? null : _analyze,
                  icon: Icons.auto_awesome,
                ),
                if (session != null && AdPolicy.showAds(session) && atDailyLimit) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      onPressed: _loading
                          ? null
                          : () => _showPremiumPitchDialog(context),
                      icon: const Icon(Icons.workspace_premium_rounded, size: 22),
                      label: const Text('Upgrade to Premium'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
                if (session != null &&
                    atDailyLimit &&
                    supportsMobileAds &&
                    AdPolicy.showRewardedPostAnalyzeOption(session)) ...[
                  const SizedBox(height: 10),
                  if (_hasPendingReward) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Ad watched but reward not claimed yet.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          FilledButton.tonal(
                            onPressed: _retryingReward ? null : _retryPendingRewardClaim,
                            child: _retryingReward
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Colors.white.withValues(alpha: 0.85),
                                    ),
                                  )
                                : const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  OutlinedButton.icon(
                    onPressed: (_loading || _rewardLoading || _retryingReward || _hasPendingReward)
                        ? null
                        : _watchAdForBonus,
                    icon: _rewardLoading
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          )
                        : const Icon(Icons.play_circle_outline_rounded),
                    label: Text(
                      _rewardLoading
                          ? 'Opening ad…'
                          : _retryingReward
                              ? 'Retrying claim…'
                              : _hasPendingReward
                                  ? 'Claim pending (Retry above)'
                                  : 'Watch Ad to Unlock 1 More Analysis',
                    ),
                  ),
                ],
                if (_result != null) ...[
                  const SizedBox(height: 36),
                  _PostAnalyzerResultsSection(
                    result: _result!,
                    isPremium: !userIsFree,
                    strings: s,
                    copyPackLabel: s.actionCopyFullPack,
                    shareButtonLabel: s.actionSharePack,
                    remindButtonLabel: s.actionRemindPost,
                    onCopyCaption: _result!.caption.isEmpty
                        ? null
                        : () => _copyToClipboard(context, _result!.caption, 'Caption copied'),
                    onCopyPack: () => _copyToClipboard(
                      context,
                      postAnalysisCopyPack(_result!),
                      s.snackFullPackCopied,
                    ),
                    onSharePack: () => Share.share(postAnalysisCopyPack(_result!), subject: s.appTitle),
                    onScheduleReminder: _pickPostReminder,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Prominent free-usage readout above the analyze button.
class _FreeUsageHighlight extends StatelessWidget {
  const _FreeUsageHighlight({
    required this.remaining,
    required this.cap,
    required this.atLimit,
  });

  final int? remaining;
  final int? cap;
  final bool atLimit;

  @override
  Widget build(BuildContext context) {
    final displayLimit = 3;
    final rem = remaining;
    final displayRemaining = rem == null ? 3 : rem.clamp(0, 3);
    return Semantics(
      label: atLimit
          ? 'Daily limit reached. Zero of $displayLimit analyses remaining'
          : '$displayRemaining of $displayLimit analyses remaining today',
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: atLimit ? const Color(0x33DC2626) : Colors.white.withValues(alpha: 0.07),
          border: Border.all(
            color: atLimit ? const Color(0x55F87171) : Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'FREE PLAN · TODAY',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.55,
                color: Colors.white.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$displayRemaining',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withValues(alpha: 0.96),
                      ),
                ),
                Text(
                  ' of $displayLimit',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.52),
                      ),
                ),
                const Spacer(),
                Text(
                  atLimit ? 'Limit reached' : 'remaining',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.48),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: displayLimit > 0 ? displayRemaining / displayLimit : 0,
                minHeight: 7,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                color: atLimit ? const Color(0xFFF87171) : AppTheme.accent2.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UsageTierBanner extends StatelessWidget {
  const _UsageTierBanner({
    required this.session,
    required this.onUpgradeTap,
  });

  final UserModel session;
  final VoidCallback onUpgradeTap;

  @override
  Widget build(BuildContext context) {
    if (AdPolicy.isPremium(session)) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppTheme.accent.withValues(alpha: 0.14),
          border: Border.all(color: AppTheme.accent.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(Icons.workspace_premium_rounded, color: AppTheme.accent2.withValues(alpha: 0.95), size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Premium · Unlimited post analyses',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
              ),
            ),
          ],
        ),
      );
    }

    final lim = session.postAnalyzeLimit;
    if (lim == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white.withValues(alpha: 0.05),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Text(
          'Free plan usage updates after profile sync.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12.5, height: 1.35),
        ),
      );
    }
    final rem = session.postAnalyzeRemaining?.clamp(0, lim);
    if (rem == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white.withValues(alpha: 0.05),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Text(
          'Free plan: $lim free analyses per day (usage updates after profile sync).',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12.5, height: 1.35),
        ),
      );
    }

    final atLimit = rem <= 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: atLimit ? const Color(0x33DC2626) : Colors.white.withValues(alpha: 0.06),
        border: Border.all(
          color: atLimit ? const Color(0x66F87171) : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            atLimit ? Icons.block_rounded : Icons.pie_chart_outline_rounded,
            color: atLimit ? const Color(0xFFF87171) : AppTheme.accent2.withValues(alpha: 0.9),
            size: 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  atLimit ? 'Daily limit reached' : 'Free plan usage',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  atLimit
                      ? 'You’ve used all $lim analyses for today. Upgrade for unlimited.'
                      : '$rem of $lim analyses remaining today.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.68),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                if (atLimit) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: onUpgradeTap,
                    icon: const Icon(Icons.workspace_premium_rounded, size: 18),
                    label: const Text('Upgrade to Premium'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NicheConnectedChip extends StatelessWidget {
  const _NicheConnectedChip({required this.niche});

  final String niche;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppTheme.accent2.withValues(alpha: 0.1),
        border: Border.all(color: AppTheme.accent2.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_rounded, color: AppTheme.accent2.withValues(alpha: 0.95), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profile niche sent to AI',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  niche,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 13,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MissingNicheWarning extends StatelessWidget {
  const _MissingNicheWarning({required this.onOpenProfile});

  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    const amber = Color(0xFFFBBF24);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0x26F59E0B),
        border: Border.all(color: const Color(0x55FBBF24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: amber, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No niche on your profile',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'We’ll analyze without a niche — results are broader. Add a niche in Profile so hooks, hashtags, timing, and audio match your vertical.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.68),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: onOpenProfile,
                  icon: const Icon(Icons.person_rounded, size: 20),
                  label: const Text('Open profile'),
                  style: TextButton.styleFrom(
                    foregroundColor: amber,
                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PostAnalyzerResultsSection extends StatelessWidget {
  const _PostAnalyzerResultsSection({
    required this.result,
    required this.isPremium,
    required this.strings,
    required this.copyPackLabel,
    required this.shareButtonLabel,
    required this.remindButtonLabel,
    required this.onCopyCaption,
    required this.onCopyPack,
    required this.onSharePack,
    required this.onScheduleReminder,
  });

  final PostAnalysisResult result;
  final bool isPremium;
  final AppStrings strings;
  final String copyPackLabel;
  final String shareButtonLabel;
  final String remindButtonLabel;
  final VoidCallback? onCopyCaption;
  final VoidCallback onCopyPack;
  final VoidCallback onSharePack;
  final VoidCallback onScheduleReminder;

  @override
  Widget build(BuildContext context) {
    final fg = AppTheme.onCardPrimary(context);
    final bg = Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ResultsScreenHeader(),
        const SizedBox(height: 14),
        _GlassResultCard(
          child: Row(
            children: [
              _IconOrb(icon: Icons.insights_rounded, colors: const [Color(0xFF22D3EE), Color(0xFF7C3AED)]),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Viral score', style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(
                      '${result.score} · Niche: ${result.niche.isEmpty ? "—" : result.niche}',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.84)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.tonalIcon(
          onPressed: onCopyPack,
          icon: const Icon(Icons.copy_all_rounded),
          label: Text(copyPackLabel),
          style: FilledButton.styleFrom(
            foregroundColor: fg,
            backgroundColor: bg,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onSharePack,
                icon: const Icon(Icons.share_rounded, size: 20),
                label: Text(shareButtonLabel, style: const TextStyle(fontSize: 12.5)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onScheduleReminder,
                icon: const Icon(Icons.alarm_add_rounded, size: 20),
                label: Text(remindButtonLabel, style: const TextStyle(fontSize: 12.5)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (isPremium) ...[
          _HookHeroCard(text: result.hook),
          const SizedBox(height: 20),
          _CaptionResultCard(
            text: result.improvedCaption.isNotEmpty ? result.improvedCaption : result.caption,
            onCopy: onCopyCaption,
          ),
          const SizedBox(height: 20),
          _HashtagsGridCard(tags: result.betterHashtags.isNotEmpty ? result.betterHashtags : result.hashtags),
          const SizedBox(height: 20),
          _EngagementTipsCard(tips: result.engagementTips),
        ] else ...[
          const _ProLockedCard(),
          const SizedBox(height: 20),
        ],
        const SizedBox(height: 20),
        _AccentStripeCard(
          icon: Icons.schedule_rounded,
          title: strings.viralBestTimeTitle,
          body: result.bestTime.trim().isEmpty ? strings.postAnalyzeBestTimeFallback : result.bestTime,
          stripeGradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF22D3EE), Color(0xFF7C3AED)],
          ),
        ),
        const SizedBox(height: 20),
        _AccentStripeCard(
          icon: Icons.graphic_eq_rounded,
          title: strings.viralAudioSuggestionTitle,
          body: result.audio.trim().isEmpty ? strings.postAnalyzeAudioFallback : result.audio,
          stripeGradient: AppTheme.primaryGradient,
        ),
      ],
    );
  }
}

class _ResultsScreenHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    AppTheme.accent.withValues(alpha: 0.35),
                    AppTheme.accent2.withValues(alpha: 0.22),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accent.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Analysis results',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Everything you need to publish',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.52),
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 1,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(1),
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                AppTheme.accent2.withValues(alpha: 0.45),
                AppTheme.accent.withValues(alpha: 0.45),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HookHeroCard extends StatelessWidget {
  const _HookHeroCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final display = text.isEmpty ? '—' : text;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: AppTheme.primaryGradient,
        boxShadow: [
          ...AppTheme.cardShadow,
          BoxShadow(
            color: AppTheme.accent.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.cardBg,
                      Color.lerp(AppTheme.cardBg, AppTheme.accent, 0.12)!,
                      AppTheme.bgElevated,
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              right: -40,
              top: -30,
              child: IgnorePointer(
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.accent2.withValues(alpha: 0.18),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.accent2.withValues(alpha: 0.2),
                          AppTheme.accent.withValues(alpha: 0.15),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.accent2.withValues(alpha: 0.35)),
                    ),
                    child: Text(
                      'HOOK',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                        color: AppTheme.accent2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    display,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.28,
                      letterSpacing: -0.6,
                      fontSize: 26,
                      color: Colors.white.withValues(alpha: 0.98),
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaptionResultCard extends StatelessWidget {
  const _CaptionResultCard({
    required this.text,
    required this.onCopy,
  });

  final String text;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _GlassResultCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _IconOrb(icon: Icons.format_quote_rounded, colors: [AppTheme.accent2, AppTheme.accent]),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Caption',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              if (onCopy != null)
                FilledButton.tonalIcon(
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy_rounded, size: 20),
                  label: const Text('Copy'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.bgElevated,
                    foregroundColor: AppTheme.accent2,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            height: 3,
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: AppTheme.primaryGradient,
            ),
          ),
          Text(
            text.isEmpty ? '—' : text,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.55,
              color: Colors.white.withValues(alpha: 0.88),
            ),
          ),
        ],
      ),
    );
  }
}

class _HashtagsGridCard extends StatelessWidget {
  const _HashtagsGridCard({required this.tags});

  final List<String> tags;

  String get _joined {
    return tags.map((t) => t.startsWith('#') ? t : '#$t').join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _GlassResultCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _IconOrb(icon: Icons.tag_rounded, colors: [AppTheme.accent, const Color(0xFFEC4899)]),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Hashtags',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: tags.isEmpty ? null : () => _copyToClipboard(context, _joined, 'Hashtags copied'),
                icon: const Icon(Icons.copy_rounded, size: 20),
                label: const Text('Copy'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.bgElevated,
                  foregroundColor: AppTheme.accent2,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (tags.isEmpty)
            Text(
              '—',
              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white.withValues(alpha: 0.45)),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.6,
              ),
              itemCount: tags.length,
              itemBuilder: (context, index) {
                final raw = tags[index];
                final label = raw.startsWith('#') ? raw : '#$raw';
                return Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.bgElevated,
                        Color.lerp(AppTheme.bgElevated, AppTheme.accent, 0.06)!,
                      ],
                    ),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.2,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _AccentStripeCard extends StatelessWidget {
  const _AccentStripeCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.stripeGradient,
  });

  final IconData icon;
  final String title;
  final String body;
  final Gradient stripeGradient;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: AppTheme.cardBg,
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
        boxShadow: AppTheme.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(gradient: stripeGradient),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _IconOrb(icon: icon, colors: const [Color(0xFF22D3EE), Color(0xFF7C3AED)], small: true),
                        const SizedBox(width: 12),
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      body.isEmpty ? '—' : body,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        height: 1.5,
                        color: Colors.white.withValues(alpha: 0.84),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassResultCard extends StatelessWidget {
  const _GlassResultCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: AppTheme.cardBg,
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
        child: child,
      ),
    );
  }
}

class _ProLockedCard extends StatelessWidget {
  const _ProLockedCard();

  @override
  Widget build(BuildContext context) {
    return _GlassResultCard(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        alignment: Alignment.center,
        child: Column(
          children: [
            const Icon(Icons.lock_rounded, size: 32, color: Colors.white70),
            const SizedBox(height: 8),
            Text(
              '🔒 Pro Feature',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _EngagementTipsCard extends StatelessWidget {
  const _EngagementTipsCard({required this.tips});

  final List<String> tips;

  @override
  Widget build(BuildContext context) {
    return _GlassResultCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Engagement tips', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          if (tips.isEmpty)
            const Text('—')
          else
            ...tips.map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('• $t', style: const TextStyle(height: 1.35)),
              ),
            ),
        ],
      ),
    );
  }
}

class _IconOrb extends StatelessWidget {
  const _IconOrb({
    required this.icon,
    required this.colors,
    this.small = false,
  });

  final IconData icon;
  final List<Color> colors;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final s = small ? 40.0 : 48.0;
    final iconSize = small ? 20.0 : 24.0;
    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: iconSize),
    );
  }
}
