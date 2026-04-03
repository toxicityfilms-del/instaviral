import 'package:flutter/material.dart';
import 'package:reelboost_ai/features/creator_profile/presentation/creator_profile_screen.dart';

/// Backward-compatible entry: opens the same [CreatorProfileScreen].
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CreatorProfileScreen();
  }
}
