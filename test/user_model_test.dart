import 'package:flutter_test/flutter_test.dart';
import 'package:reelboost_ai/models/user_model.dart';

void main() {
  test('UserModel parses profile and usage fields from API JSON', () {
    final u = UserModel.fromJson({
      'id': '507f1f77bcf86cd799439011',
      'email': 'creator@test.com',
      'name': 'Test',
      'bio': 'Hello',
      'instagramLink': 'https://instagram.com/x',
      'facebookLink': '',
      'niche': 'Fitness & health',
      'isPremium': false,
      'postAnalyzeLimit': 5,
      'postAnalyzeRemaining': 4,
    });
    expect(u.isPremium, false);
    expect(u.postAnalyzeLimit, 5);
    expect(u.postAnalyzeRemaining, 4);
    expect(u.postAnalyzeAdRewardsRemaining, null);
    expect(u.niche, 'Fitness & health');
  });

  test('UserModel parses premium user (null limits)', () {
    final u = UserModel.fromJson({
      'id': '1',
      'email': 'pro@test.com',
      'isPremium': true,
      'postAnalyzeLimit': null,
      'postAnalyzeRemaining': null,
    });
    expect(u.isPremium, true);
    expect(u.postAnalyzeLimit, null);
    expect(u.postAnalyzeRemaining, null);
    expect(u.postAnalyzeAdRewardsRemaining, null);
  });

  test('withPostAnalyzeUsage updates counters without dropping profile', () {
    final base = UserModel.fromJson({
      'id': '1',
      'email': 'a@b.c',
      'name': 'N',
      'niche': 'Comedy',
      'isPremium': false,
      'postAnalyzeLimit': 5,
      'postAnalyzeRemaining': 5,
    });
    final next = base.withPostAnalyzeUsage(
      isPremium: false,
      postAnalyzeLimit: 5,
      postAnalyzeRemaining: 2,
    );
    expect(next.niche, 'Comedy');
    expect(next.postAnalyzeRemaining, 2);
  });

  test('UserModel clamps negative or out-of-range remaining for free users', () {
    final u = UserModel.fromJson({
      'id': '1',
      'email': 'a@b.c',
      'isPremium': false,
      'postAnalyzeLimit': 5,
      'postAnalyzeRemaining': -1,
    });
    expect(u.postAnalyzeRemaining, 0);
    final v = UserModel.fromJson({
      'id': '1',
      'email': 'a@b.c',
      'isPremium': false,
      'postAnalyzeLimit': 5,
      'postAnalyzeRemaining': 99,
    });
    expect(v.postAnalyzeRemaining, 5);
  });

  test('UserModel keeps postAnalyzeAdRewardsRemaining from server (non-negative)', () {
    final u = UserModel.fromJson({
      'id': '1',
      'email': 'a@b.c',
      'isPremium': false,
      'postAnalyzeLimit': 10,
      'postAnalyzeRemaining': 10,
      'postAnalyzeAdRewardsRemaining': 12,
    });
    expect(u.postAnalyzeAdRewardsRemaining, 12);
  });
}
