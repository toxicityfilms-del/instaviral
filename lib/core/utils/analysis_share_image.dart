import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:reelboost_ai/core/l10n/app_strings.dart';
import 'package:reelboost_ai/core/theme/app_theme.dart';
import 'package:reelboost_ai/core/utils/post_analysis_pack.dart';
import 'package:reelboost_ai/models/post_analysis_models.dart';
import 'package:share_plus/share_plus.dart';

/// Renders a 9:16 PNG (Story-friendly) with viral score + engagement tips.
Future<Uint8List> renderAnalysisSharePng({
  required PostAnalysisResult result,
  required List<String> tipLines,
  required AppStrings strings,
}) async {
  const double w = 1080;
  const double h = 1920;
  const pad = 56.0;

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  final bg = Paint()
    ..shader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF06080D),
        Color(0xFF0E1522),
        Color(0xFF121A28),
      ],
      stops: [0.0, 0.45, 1.0],
    ).createShader(const Rect.fromLTWH(0, 0, w, h));
  canvas.drawRect(const Rect.fromLTWH(0, 0, w, h), bg);

  final accentStroke = Paint()
    ..shader = AppTheme.primaryGradient.createShader(const Rect.fromLTWH(0, 0, w, 40))
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4;
  canvas.drawLine(const Offset(pad, pad + 8), Offset(w - pad, pad + 8), accentStroke);

  double y = pad + 36;

  final badge = TextPainter(
    text: TextSpan(
      text: strings.appTitle.toUpperCase(),
      style: const TextStyle(
        color: Color(0x8822D3EE),
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: 3,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  badge.paint(canvas, Offset(pad, y));
  y += badge.height + 48;

  final scoreLabel = TextPainter(
    text: TextSpan(
      text: strings.analysisShareScoreLabel,
      style: const TextStyle(
        color: Color(0x99FFFFFF),
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: w - pad * 2);
  scoreLabel.paint(canvas, Offset(pad, y));
  y += scoreLabel.height + 16;

  final scoreNum = TextPainter(
    text: TextSpan(
      children: [
        TextSpan(
          text: '${result.score}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 140,
            fontWeight: FontWeight.w900,
            height: 1.0,
          ),
        ),
        const TextSpan(
          text: ' /100',
          style: TextStyle(
            color: Color(0x66FFFFFF),
            fontSize: 44,
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
        ),
      ],
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  scoreNum.paint(canvas, Offset(pad, y));
  y += scoreNum.height + 28;

  final niche = result.niche.trim().isEmpty ? '—' : result.niche.trim();
  final nicheTp = TextPainter(
    text: TextSpan(
      style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 30, height: 1.35),
      children: [
        TextSpan(
          text: '${strings.analysisShareNichePrefix}  ',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        TextSpan(text: niche, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    ),
    textDirection: TextDirection.ltr,
    maxLines: 3,
    ellipsis: '…',
  )..layout(maxWidth: w - pad * 2);
  nicheTp.paint(canvas, Offset(pad, y));
  y += nicheTp.height + 56;

  final tipsTitle = TextPainter(
    text: TextSpan(
      text: strings.analysisShareEngagementTips,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 34,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: w - pad * 2);
  tipsTitle.paint(canvas, Offset(pad, y));
  y += tipsTitle.height + 22;

  final bodyWidth = w - pad * 2;
  for (final line in tipLines) {
    final tp = TextPainter(
      text: TextSpan(
        text: '• $line',
        style: const TextStyle(
          color: Color(0xE6FFFFFF),
          fontSize: 28,
          height: 1.45,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 8,
      ellipsis: '…',
    )..layout(maxWidth: bodyWidth - 8);
    if (y + tp.height > h - pad - 120) break;
    tp.paint(canvas, Offset(pad + 4, y));
    y += tp.height + 14;
  }

  final footer = TextPainter(
    text: TextSpan(
      text: strings.appTitle,
      style: const TextStyle(
        color: Color(0x44FFFFFF),
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  footer.paint(canvas, Offset(pad, h - pad - footer.height));

  final picture = recorder.endRecording();
  final image = await picture.toImage(w.toInt(), h.toInt());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return bytes!.buffer.asUint8List();
}

/// Shares analysis as PNG via system sheet (Instagram Stories, WhatsApp, etc.).
Future<void> shareAnalysisResultImage({
  required BuildContext context,
  required PostAnalysisResult result,
  required bool includePremiumTips,
  required AppStrings strings,
}) async {
  Rect? shareOrigin;
  final box = context.findRenderObject();
  if (box is RenderBox && box.hasSize) {
    shareOrigin = box.localToGlobal(Offset.zero) & box.size;
  }

  List<String> tips;
  if (!includePremiumTips) {
    tips = [strings.analysisShareTipsLockedBody];
  } else if (result.engagementTips.isNotEmpty) {
    tips = result.engagementTips.map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
  } else {
    tips = [strings.analysisShareTipsEmpty];
  }

  final png = await renderAnalysisSharePng(
    result: result,
    tipLines: tips,
    strings: strings,
  );

  if (!context.mounted) return;

  final safeName = strings.appTitle.replaceAll(RegExp(r'[^\w]+'), '_');
  final xFile = XFile.fromData(
    png,
    mimeType: 'image/png',
    name: '${safeName}_analysis.png',
  );

  await Share.shareXFiles(
    [xFile],
    subject: strings.appTitle,
    // Caption often appears in WhatsApp; keep empty so image is primary (Stories-friendly).
    text: '',
    sharePositionOrigin: shareOrigin,
  );
}

/// Bottom sheet: share as Story-ready image or as text pack.
Future<void> showAnalysisShareSheet({
  required BuildContext context,
  required AppStrings strings,
  required PostAnalysisResult result,
  required bool includePremiumTips,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: AppTheme.cardBg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text(
                  strings.shareSheetTitle,
                  style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.photo_outlined, color: AppTheme.accent2.withValues(alpha: 0.95)),
                title: Text(strings.shareAsImageTitle),
                subtitle: Text(
                  strings.shareAsImageSubtitle,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 13),
                ),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  try {
                    await shareAnalysisResultImage(
                      context: context,
                      result: result,
                      includePremiumTips: includePremiumTips,
                      strings: strings,
                    );
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(strings.snackShareImageFailed)),
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.article_outlined, color: Colors.white.withValues(alpha: 0.85)),
                title: Text(strings.shareAsTextTitle),
                subtitle: Text(
                  strings.actionSharePack,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 13),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Share.share(postAnalysisCopyPack(result), subject: strings.appTitle);
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}
