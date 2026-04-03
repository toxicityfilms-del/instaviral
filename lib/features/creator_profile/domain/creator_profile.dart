import 'package:reelboost_ai/models/user_model.dart';

/// Editable profile fields (MongoDB Profile collection via `POST /api/profile/save`).
class CreatorProfile {
  const CreatorProfile({
    required this.name,
    required this.niche,
    required this.bio,
    required this.instagramLink,
    required this.facebookLink,
  });

  final String name;
  final String niche;
  final String bio;
  final String instagramLink;
  final String facebookLink;

  factory CreatorProfile.fromUserModel(UserModel user) {
    return CreatorProfile(
      name: user.name,
      niche: user.niche,
      bio: user.bio,
      instagramLink: user.instagramLink,
      facebookLink: user.facebookLink,
    );
  }

  UserModel mergedInto(UserModel session) {
    return session.copyWith(
      name: name,
      niche: niche,
      bio: bio,
      instagramLink: instagramLink,
      facebookLink: facebookLink,
    );
  }
}
