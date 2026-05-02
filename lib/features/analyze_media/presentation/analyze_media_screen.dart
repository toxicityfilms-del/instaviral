import 'dart:async';
import 'dart:convert';
import 'dart:io' show File;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:reelboost_ai/core/ads/ad_policy.dart';
import 'package:reelboost_ai/core/haptics/app_haptics.dart';
import 'package:reelboost_ai/core/l10n/app_strings.dart';
import 'package:reelboost_ai/core/notifications/local_notifications_service.dart';
import 'package:reelboost_ai/core/premium/premium_checkout.dart';
import 'package:reelboost_ai/core/premium/premium_monthly_pitch_dialog.dart';
import 'package:reelboost_ai/core/providers/app_providers.dart';
import 'package:reelboost_ai/core/services/analysis_history_service.dart';
import 'package:reelboost_ai/core/services/previous_analysis_store.dart';
import 'package:reelboost_ai/core/theme/app_theme.dart';
import 'package:reelboost_ai/core/utils/ai_credits_limit_dialog.dart';
import 'package:reelboost_ai/core/utils/api_error_message.dart';
import 'package:reelboost_ai/core/utils/analysis_share_image.dart';
import 'package:reelboost_ai/core/utils/post_analysis_pack.dart';
import 'package:reelboost_ai/models/post_analysis_models.dart';
import 'package:reelboost_ai/services/reelboost_api_service.dart';
import 'package:reelboost_ai/widgets/analysis_comparison_panel.dart';
import 'package:reelboost_ai/widgets/app_card.dart';
import 'package:reelboost_ai/widgets/gradient_button.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnalyzeMediaScreen extends ConsumerStatefulWidget {
  const AnalyzeMediaScreen({super.key});

  @override
  ConsumerState<AnalyzeMediaScreen> createState() => _AnalyzeMediaScreenState();
}

class _AnalyzeMediaScreenState extends ConsumerState<AnalyzeMediaScreen> {
  final _picker = ImagePicker();
  final _notes = TextEditingController();

  XFile? _imageFile;
  Uint8List? _imagePreview;
  String? _imageDataUrl;

  XFile? _videoFile;
  Uint8List? _videoThumbBytes;
  String? _videoThumbDataUrl;
  VideoPlayerController? _videoCtrl;

  bool _loading = false;
  PostAnalysisResult? _result;
  PostAnalysisResult? _comparisonBefore;

  @override
  void dispose() {
    _notes.dispose();
    _videoCtrl?.dispose();
    super.dispose();
  }

  Future<void> _copy(String text, String msg) async {
    AppHaptics.copy();
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _mimeFromName(String name) {
    final n = name.toLowerCase();
    if (n.endsWith('.png')) return 'image/png';
    if (n.endsWith('.webp')) return 'image/webp';
    if (n.endsWith('.gif')) return 'image/gif';
    if (n.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }

  void _clearAllMedia() {
    _videoCtrl?.dispose();
    _videoCtrl = null;
    setState(() {
      _imageFile = null;
      _imagePreview = null;
      _imageDataUrl = null;

      _videoFile = null;
      _videoThumbBytes = null;
      _videoThumbDataUrl = null;

      _result = null;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final x = await _picker.pickImage(
      source: source,
      maxWidth: 1800,
      maxHeight: 1800,
      imageQuality: 88,
    );
    if (x == null || !mounted) return;
    final bytes = await x.readAsBytes();
    final mime = _mimeFromName(x.name.isNotEmpty ? x.name : x.path);
    final b64 = base64Encode(bytes);

    _videoCtrl?.dispose();
    _videoCtrl = null;

    setState(() {
      _videoFile = null;
      _videoThumbBytes = null;
      _videoThumbDataUrl = null;

      _imageFile = x;
      _imagePreview = bytes;
      _imageDataUrl = 'data:$mime;base64,$b64';
      _result = null;
    });
  }

  Future<void> _pickVideo(ImageSource source) async {
    if (kIsWeb) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video upload is not supported on web yet.')),
      );
      return;
    }
    final x = await _picker.pickVideo(source: source, maxDuration: const Duration(minutes: 3));
    if (x == null || !mounted) return;

    final thumb = await VideoThumbnail.thumbnailData(
      video: x.path,
      imageFormat: ImageFormat.PNG,
      maxWidth: 720,
      quality: 75,
    );
    if (thumb == null || thumb.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not generate video thumbnail. Try another video.')),
      );
      return;
    }

    final ctrl = VideoPlayerController.file(File(x.path));
    await ctrl.initialize();
    await ctrl.setLooping(true);
    if (!mounted) {
      ctrl.dispose();
      return;
    }

    final thumbB64 = base64Encode(thumb);

    setState(() {
      _imageFile = null;
      _imagePreview = null;
      _imageDataUrl = null;

      _videoCtrl?.dispose();
      _videoCtrl = ctrl;
      _videoFile = x;
      _videoThumbBytes = thumb;
      _videoThumbDataUrl = 'data:image/png;base64,$thumbB64';
      _result = null;
    });
  }

  Future<void> _toggleVideoPlay() async {
    final c = _videoCtrl;
    if (c == null) return;
    if (c.value.isPlaying) {
      await c.pause();
    } else {
      await c.play();
    }
    if (mounted) setState(() {});
  }

  Future<void> _analyze() async {
    final hasImage = _imageFile != null && _imageDataUrl != null && _imageDataUrl!.isNotEmpty;
    final hasVideo = _videoFile != null && _videoThumbDataUrl != null && _videoThumbDataUrl!.isNotEmpty;

    if (!hasImage && !hasVideo) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add an image or video first')),
      );
      return;
    }

    setState(() {
      _loading = true;
      _result = null;
    });

    final api = ref.read(reelboostApiProvider);
    final session = ref.read(authControllerProvider).asData?.value;
    try {
      final mediaBytes = hasVideo ? await _videoFile!.readAsBytes() : await _imageFile!.readAsBytes();
      final mediaFileName = hasVideo
          ? (_videoFile!.name.isNotEmpty ? _videoFile!.name : _videoFile!.path.split('/').last)
          : (_imageFile!.name.isNotEmpty ? _imageFile!.name : _imageFile!.path.split('/').last);
      final mediaMime = hasVideo ? 'video/mp4' : _mimeFromName(mediaFileName);
      final thumbDataUrl = hasVideo ? _videoThumbDataUrl : _imageDataUrl;

      final response = await api.analyzeMedia(
        mediaBytes: mediaBytes.toList(),
        mediaFileName: mediaFileName,
        mediaMime: mediaMime,
        thumbnailDataUrl: thumbDataUrl,
        creatorNiche: session?.niche ?? '',
        creatorBio: session?.bio ?? '',
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      );

      if (session != null) {
        ref.read(authControllerProvider.notifier).applyUser(
              session.withPostAnalyzeUsage(
                isPremium: response.isPremium,
                postAnalyzeLimit: response.postAnalyzeLimit ?? session.postAnalyzeLimit,
                postAnalyzeRemaining: response.postAnalyzeRemaining ?? session.postAnalyzeRemaining,
                postAnalyzeAdRewardsRemaining: response.postAnalyzeAdRewardsRemaining ??
                    session.postAnalyzeAdRewardsRemaining,
              ),
            );
      }
      if (!mounted) return;
      final previous = await PreviousAnalysisStore.load(PreviousAnalysisStore.sourceMediaAnalyzer);
      if (!mounted) return;
      setState(() {
        _result = response.result;
        _comparisonBefore = previous;
      });
      await PreviousAnalysisStore.save(PreviousAnalysisStore.sourceMediaAnalyzer, response.result);
      AppHaptics.success();
      final noteTitle = _notes.text.trim();
      unawaited(
        AnalysisHistoryService.add(
          source: 'media_analyze',
          title: noteTitle.isNotEmpty
              ? noteTitle
              : (hasVideo ? 'Video analysis' : 'Image analysis'),
          result: response.result,
        ),
      );
      if (!mounted) return;
      final rem = response.postAnalyzeRemaining;
      if (response.isPremium != true && rem != null && rem <= 0) {
        showLastFreeAiUseSnackBar(
          context,
          onUpgrade: () => showPremiumMonthlyPitchDialog(
            context,
            onDebugStartPurchase: () => attemptPremiumRazorpayCheckout(ref, context),
          ),
        );
      }
    } on PostAnalyzeLimitException catch (e) {
      if (!mounted) return;
      await showAiCreditsLimitDialog(
        context,
        onUpgrade: () => showPremiumMonthlyPitchDialog(
          context,
          onDebugStartPurchase: () => attemptPremiumRazorpayCheckout(ref, context),
        ),
      );
      final s = ref.read(authControllerProvider).asData?.value;
      if (s != null) {
        ref.read(authControllerProvider.notifier).applyUser(
              s.withPostAnalyzeUsage(
                isPremium: false,
                postAnalyzeLimit: e.limit ?? s.postAnalyzeLimit,
                postAnalyzeRemaining: 0,
                postAnalyzeAdRewardsRemaining: s.postAnalyzeAdRewardsRemaining,
              ),
            );
      }
    } catch (e) {
      if (!mounted) return;
      final strings = ref.read(appStringsProvider);
      final msg = analyzePostErrorMessageLocalized(e, strings);
      final showRetry = isRetryableAnalyzeError(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          duration: const Duration(seconds: 8),
          action: showRetry
              ? SnackBarAction(label: strings.retry, onPressed: _analyze)
              : null,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
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

  @override
  Widget build(BuildContext context) {
    final r = _result;
    final s = ref.watch(appStringsProvider);
    final session = ref.watch(authControllerProvider).asData?.value;
    final showPremiumFields = r != null &&
        session != null &&
        AdPolicy.isPremium(session) &&
        !r.lockedPremiumFields;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.tileAnalyzeMedia),
        actions: [
          if (_imageFile != null || _videoFile != null)
            IconButton(
              tooltip: 'Clear',
              onPressed: _loading ? null : _clearAllMedia,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.scaffoldGradient(context)),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Upload a post (image/video)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  'We’ll analyze what’s actually in your media and generate a hook, caption, hashtags, audio, and best time.',
                  style: TextStyle(color: AppTheme.onCardSecondary(context), height: 1.35),
                ),
                const SizedBox(height: 12),
                AppCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.compare_arrows_rounded, color: AppTheme.onCardSecondary(context), size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          s.analyzeMediaCompareTitle,
                          style: TextStyle(color: AppTheme.onCardSecondary(context), fontSize: 12.5, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Media',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 10),
                      if (_imagePreview != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.memory(
                            _imagePreview!,
                            height: 220,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(onPressed: _loading ? null : _clearAllMedia, child: const Text('Remove')),
                        ),
                      ] else if (_videoFile != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            height: 240,
                            width: double.infinity,
                            color: Colors.black.withValues(alpha: 0.25),
                            child: _videoCtrl != null && _videoCtrl!.value.isInitialized
                                ? Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      AspectRatio(
                                        aspectRatio:
                                            _videoCtrl!.value.aspectRatio == 0 ? (16 / 9) : _videoCtrl!.value.aspectRatio,
                                        child: VideoPlayer(_videoCtrl!),
                                      ),
                                      Positioned(
                                        bottom: 10,
                                        right: 10,
                                        child: FilledButton.tonalIcon(
                                          onPressed: _loading ? null : _toggleVideoPlay,
                                          icon: Icon(
                                            _videoCtrl!.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                          ),
                                          label: Text(_videoCtrl!.value.isPlaying ? 'Pause' : 'Play'),
                                        ),
                                      ),
                                    ],
                                  )
                                : (_videoThumbBytes != null
                                    ? Image.memory(_videoThumbBytes!, fit: BoxFit.cover)
                                    : const Center(child: CircularProgressIndicator())),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(onPressed: _loading ? null : _clearAllMedia, child: const Text('Remove')),
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _loading ? null : () => _pickImage(ImageSource.gallery),
                                icon: const Icon(Icons.photo_library_outlined),
                                label: const Text('Image'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _loading ? null : () => _pickVideo(ImageSource.gallery),
                                icon: const Icon(Icons.video_library_outlined),
                                label: const Text('Video'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _loading ? null : () => _pickImage(ImageSource.camera),
                                icon: const Icon(Icons.camera_alt_outlined),
                                label: const Text('Camera'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _loading ? null : () => _pickVideo(ImageSource.camera),
                                icon: const Icon(Icons.videocam_outlined),
                                label: const Text('Record'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Tip: for videos we analyze the thumbnail frame so results stay specific to your content.',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12, height: 1.35),
                        ),
                      ],
                      const SizedBox(height: 14),
                      TextField(
                        controller: _notes,
                        maxLines: 3,
                        enabled: !_loading,
                        decoration: const InputDecoration(
                          labelText: 'Notes (optional)',
                          hintText: 'e.g. target audience, what you want to highlight, CTA…',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GradientButton(
                        label: 'Analyze Post',
                        loading: _loading,
                        onPressed: _loading ? null : _analyze,
                        icon: Icons.auto_awesome,
                      ),
                    ],
                  ),
                ),
                if (r != null) ...[
                  const SizedBox(height: 16),
                  _ResultsCard(
                    result: r,
                    comparisonBefore: _comparisonBefore,
                    strings: s,
                    showPremiumFields: showPremiumFields,
                    onCopy: _copy,
                    copyPackLabel: s.actionCopyFullPack,
                    snackCopied: s.snackFullPackCopied,
                    shareLabel: s.actionShare,
                    remindLabel: s.actionRemindPost,
                    onShare: () => showAnalysisShareSheet(
                      context: context,
                      strings: s,
                      result: r,
                      includePremiumTips: showPremiumFields,
                    ),
                    onRemind: _pickPostReminder,
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

class _ResultsCard extends StatelessWidget {
  const _ResultsCard({
    required this.result,
    this.comparisonBefore,
    required this.strings,
    required this.showPremiumFields,
    required this.onCopy,
    required this.copyPackLabel,
    required this.snackCopied,
    required this.shareLabel,
    required this.remindLabel,
    required this.onShare,
    required this.onRemind,
  });

  final PostAnalysisResult result;
  final PostAnalysisResult? comparisonBefore;
  final AppStrings strings;
  final bool showPremiumFields;
  final Future<void> Function(String text, String msg) onCopy;
  final String copyPackLabel;
  final String snackCopied;
  final String shareLabel;
  final String remindLabel;
  final VoidCallback onShare;
  final VoidCallback onRemind;

  @override
  Widget build(BuildContext context) {
    final tags = result.hashtags;
    final tagsText = tags.join(' ');
    final pc = AppTheme.onCardPrimary(context);
    final sc = AppTheme.onCardSecondary(context);
    final chipBg = Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45);

    Widget section({
      required String title,
      required String value,
      required IconData icon,
      String? copyLabel,
      String? copyValue,
    }) {
      return AppCard(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: pc.withValues(alpha: 0.88), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                if (copyValue != null && copyValue.trim().isNotEmpty)
                  TextButton(
                    onPressed: () => onCopy(copyValue, copyLabel ?? 'Copied'),
                    child: const Text('Copy'),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            SelectableText(
              value.trim().isEmpty ? '—' : value.trim(),
              style: TextStyle(color: pc.withValues(alpha: 0.88), height: 1.4),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Results',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        if (comparisonBefore != null) ...[
          AnalysisComparisonPanel(
            before: comparisonBefore!,
            after: result,
            strings: strings,
            showPremiumSuggestionFields: showPremiumFields,
          ),
          const SizedBox(height: 12),
        ],
        AppCard(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.insights_rounded, color: pc.withValues(alpha: 0.88), size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Viral score',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${result.score} · Niche: ${result.niche.isEmpty ? "—" : result.niche}',
                style: TextStyle(color: pc.withValues(alpha: 0.88), height: 1.35),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        FilledButton.tonalIcon(
          onPressed: () => onCopy(postAnalysisCopyPack(result), snackCopied),
          icon: const Icon(Icons.copy_all_rounded),
          label: Text(copyPackLabel),
          style: FilledButton.styleFrom(
            foregroundColor: pc,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onShare,
                icon: const Icon(Icons.share_rounded, size: 20),
                label: Text(shareLabel, style: const TextStyle(fontSize: 12.5)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onRemind,
                icon: const Icon(Icons.alarm_add_rounded, size: 20),
                label: Text(remindLabel, style: const TextStyle(fontSize: 12.5)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (showPremiumFields) ...[
          section(
            title: '3‑second hook',
            value: result.hook,
            icon: Icons.flash_on_rounded,
            copyLabel: 'Hook copied',
            copyValue: result.hook,
          ),
          const SizedBox(height: 12),
          section(
            title: 'Caption',
            value: result.caption,
            icon: Icons.format_quote_rounded,
            copyLabel: 'Caption copied',
            copyValue: result.caption,
          ),
          const SizedBox(height: 12),
          AppCard(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.tag_rounded, color: pc.withValues(alpha: 0.88), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Hashtags (15)',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    TextButton(
                      onPressed: tagsText.trim().isEmpty ? null : () => onCopy(tagsText, 'Hashtags copied'),
                      child: const Text('Copy'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags.isEmpty
                      ? [
                          Text(
                            '—',
                            style: TextStyle(color: sc),
                          ),
                        ]
                      : tags.map((t) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                              color: chipBg,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: pc.withValues(alpha: 0.1)),
                            ),
                            child: Text(
                              t,
                              style: TextStyle(color: pc, fontWeight: FontWeight.w600),
                            ),
                          );
                        }).toList(),
                ),
              ],
            ),
          ),
        ] else ...[
          AppCard(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
            child: Column(
              children: [
                Icon(Icons.lock_rounded, color: pc.withValues(alpha: 0.65), size: 32),
                const SizedBox(height: 10),
                Text(
                  'Pro: hook, caption & AI hashtags',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Free includes score, timing & audio only. Upgrade for full AI.',
                  style: TextStyle(color: sc, height: 1.35, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        section(
          title: 'Best time to post',
          value: result.bestTime,
          icon: Icons.schedule_rounded,
          copyLabel: 'Best time copied',
          copyValue: result.bestTime,
        ),
        const SizedBox(height: 12),
        section(
          title: 'Trending audio',
          value: result.audio,
          icon: Icons.music_note_rounded,
          copyLabel: 'Audio suggestion copied',
          copyValue: result.audio,
        ),
      ],
    );
  }
}

