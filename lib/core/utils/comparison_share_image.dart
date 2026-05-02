import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:reelboost_ai/core/l10n/app_strings.dart';
import 'package:reelboost_ai/core/utils/analysis_comparison.dart';
import 'package:reelboost_ai/models/post_analysis_models.dart';
import 'package:share_plus/share_plus.dart';

/// Shareable card image: before score, after score, improvement %.
Future<Uint8List> renderComparisonSharePng({
  required PostAnalysisResult before,
  required PostAnalysisResult after,
  required AppStrings strings,
}) async {
  const double w = 1080;
  const double h = 1200;
  const pad = 52.0;

  final cmp = compareScores(before, after);
  final rel = cmp.relativePercentVsBefore;
  final isPositive = cmp.delta > 0;
  final isNegative = cmp.delta < 0;

  final improvementMain = rel != null
      ? '${cmp.delta >= 0 ? '+' : ''}${rel.toStringAsFixed(0)}%'
      : '${cmp.delta >= 0 ? '+' : ''}${cmp.delta} pts';

  final improvementColor = isPositive
      ? const Color(0xFF4ADE80)
      : isNegative
          ? const Color(0xFFF87171)
          : const Color(0xFFB0B8C4);

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  final bg = Paint()
    ..shader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF06080D),
        Color(0xFF0E1522),
        Color(0xFF101820),
      ],
      stops: [0.0, 0.5, 1.0],
    ).createShader(const Rect.fromLTWH(0, 0, w, h));
  canvas.drawRRect(
    RRect.fromRectAndRadius(const Rect.fromLTWH(0, 0, w, h), const Radius.circular(48)),
    bg,
  );

  double y = pad + 20;

  final brand = TextPainter(
    text: TextSpan(
      text: strings.appTitle.toUpperCase(),
      style: const TextStyle(
        color: Color(0x8822D3EE),
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: 2.5,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  brand.paint(canvas, Offset(pad, y));
  y += brand.height + 36;

  final heading = TextPainter(
    text: TextSpan(
      text: strings.comparisonShareCardHeading,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 36,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.8,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: w - pad * 2);
  heading.paint(canvas, Offset(pad, y));
  y += heading.height + 40;

  final colW = (w - pad * 2 - 24) / 2;
  final scoreTop = y;

  void paintScoreBox(double x, String label, int score, Color accent) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, scoreTop, colW, 220),
      const Radius.circular(28),
    );
    final boxPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, boxPaint);
    final borderPaint = Paint()
      ..color = accent.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(rrect, borderPaint);

    final lp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.55),
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: colW - 32);
    lp.paint(canvas, Offset(x + 24, scoreTop + 28));

    final sp = TextPainter(
      text: TextSpan(
        text: '$score',
        style: TextStyle(
          color: Colors.white,
          fontSize: 96,
          fontWeight: FontWeight.w900,
          height: 1.0,
          shadows: [
            Shadow(color: accent.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 6)),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    sp.paint(canvas, Offset(x + 24, scoreTop + 72));
  }

  paintScoreBox(pad, strings.comparisonBefore, before.score, const Color(0xFF94A3B8));
  paintScoreBox(pad + colW + 24, strings.comparisonAfter, after.score, const Color(0xFF22D3EE));

  y = scoreTop + 220 + 36;

  final impLabel = TextPainter(
    text: TextSpan(
      text: strings.comparisonShareImprovementLabel,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.55),
        fontSize: 26,
        fontWeight: FontWeight.w700,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: w - pad * 2);
  impLabel.paint(canvas, Offset(pad, y));
  y += impLabel.height + 14;

  final impMain = TextPainter(
    text: TextSpan(
      text: improvementMain,
      style: TextStyle(
        color: improvementColor,
        fontSize: 88,
        fontWeight: FontWeight.w900,
        height: 1.05,
        letterSpacing: -2,
        shadows: [
          Shadow(
            color: improvementColor.withValues(alpha: 0.4),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
        ],
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: w - pad * 2);
  impMain.paint(canvas, Offset(pad, y));

  y += impMain.height + 28;

  final sub = TextPainter(
    text: TextSpan(
      text: rel != null ? strings.comparisonVsLast : strings.comparisonPointsVsLast,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.45),
        fontSize: 22,
        fontWeight: FontWeight.w500,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: w - pad * 2);
  sub.paint(canvas, Offset(pad, y));

  final picture = recorder.endRecording();
  final image = await picture.toImage(w.toInt(), h.toInt());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return bytes!.buffer.asUint8List();
}

Future<void> shareComparisonResultImage({
  required BuildContext context,
  required PostAnalysisResult before,
  required PostAnalysisResult after,
  required AppStrings strings,
}) async {
  Rect? shareOrigin;
  final box = context.findRenderObject();
  if (box is RenderBox && box.hasSize) {
    shareOrigin = box.localToGlobal(Offset.zero) & box.size;
  }

  final png = await renderComparisonSharePng(
    before: before,
    after: after,
    strings: strings,
  );

  if (!context.mounted) return;

  final safeName = strings.appTitle.replaceAll(RegExp(r'[^\w]+'), '_');
  final xFile = XFile.fromData(
    png,
    mimeType: 'image/png',
    name: '${safeName}_comparison.png',
  );

  await Share.shareXFiles(
    [xFile],
    subject: strings.comparisonShareCardHeading,
    text: '',
    sharePositionOrigin: shareOrigin,
  );
}
