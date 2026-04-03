int? _clampFreeRemaining(int? limit, int? remaining) {
  if (remaining == null) return null;
  if (limit != null) return remaining.clamp(0, limit);
  return remaining < 0 ? 0 : remaining;
}

class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    this.name = '',
    this.bio = '',
    this.instagramLink = '',
    this.facebookLink = '',
    this.tiktokLink = '',
    this.niche = '',
    this.isPremium = false,
    this.postAnalyzeLimit,
    this.postAnalyzeRemaining,
    this.postAnalyzeAdRewardsRemaining,
  });

  final String id;
  final String email;
  final String name;
  final String bio;
  final String instagramLink;
  final String facebookLink;
  final String tiktokLink;
  final String niche;
  final bool isPremium;
  /// Free plan daily cap (e.g. 5); null when [isPremium].
  final int? postAnalyzeLimit;
  /// Remaining post analyses today for free users; null when [isPremium].
  final int? postAnalyzeRemaining;
  /// How many rewarded-ad bonuses can still be earned today; null when [isPremium].
  final int? postAnalyzeAdRewardsRemaining;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final isPremium = json['isPremium'] == true;
    final lim = (json['postAnalyzeLimit'] as num?)?.toInt();
    final remRaw = (json['postAnalyzeRemaining'] as num?)?.toInt();
    final adRem = (json['postAnalyzeAdRewardsRemaining'] as num?)?.toInt();
    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      instagramLink:
          json['instagramLink'] as String? ?? json['instagram'] as String? ?? '',
      facebookLink:
          json['facebookLink'] as String? ?? json['facebook'] as String? ?? '',
      tiktokLink: json['tiktokLink'] as String? ?? '',
      niche: json['niche'] as String? ?? '',
      isPremium: isPremium,
      postAnalyzeLimit: isPremium ? null : lim,
      postAnalyzeRemaining: isPremium ? null : _clampFreeRemaining(lim, remRaw),
      postAnalyzeAdRewardsRemaining: isPremium
          ? null
          : (adRem == null ? null : (adRem < 0 ? 0 : adRem)),
    );
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? bio,
    String? instagramLink,
    String? facebookLink,
    String? tiktokLink,
    String? niche,
    bool? isPremium,
    int? postAnalyzeLimit,
    int? postAnalyzeRemaining,
    int? postAnalyzeAdRewardsRemaining,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      bio: bio ?? this.bio,
      instagramLink: instagramLink ?? this.instagramLink,
      facebookLink: facebookLink ?? this.facebookLink,
      tiktokLink: tiktokLink ?? this.tiktokLink,
      niche: niche ?? this.niche,
      isPremium: isPremium ?? this.isPremium,
      postAnalyzeLimit: postAnalyzeLimit ?? this.postAnalyzeLimit,
      postAnalyzeRemaining: postAnalyzeRemaining ?? this.postAnalyzeRemaining,
      postAnalyzeAdRewardsRemaining:
          postAnalyzeAdRewardsRemaining ?? this.postAnalyzeAdRewardsRemaining,
    );
  }

  /// Updates plan usage fields from `POST /post/analyze` [meta] without losing profile fields.
  UserModel withPostAnalyzeUsage({
    required bool isPremium,
    int? postAnalyzeLimit,
    int? postAnalyzeRemaining,
    int? postAnalyzeAdRewardsRemaining,
  }) {
    final lim = isPremium ? null : postAnalyzeLimit;
    final rem =
        isPremium ? null : _clampFreeRemaining(lim, postAnalyzeRemaining);
    final adIn = postAnalyzeAdRewardsRemaining ?? this.postAnalyzeAdRewardsRemaining;
    final adOut = isPremium
        ? null
        : (adIn == null ? null : (adIn < 0 ? 0 : adIn));
    return UserModel(
      id: id,
      email: email,
      name: name,
      bio: bio,
      instagramLink: instagramLink,
      facebookLink: facebookLink,
      tiktokLink: tiktokLink,
      niche: niche,
      isPremium: isPremium,
      postAnalyzeLimit: lim,
      postAnalyzeRemaining: rem,
      postAnalyzeAdRewardsRemaining: adOut,
    );
  }
}
