import 'package:flutter/services.dart';

class AppHaptics {
  static void copy() => HapticFeedback.selectionClick();

  static void success() => HapticFeedback.mediumImpact();

  static void light() => HapticFeedback.lightImpact();
}
