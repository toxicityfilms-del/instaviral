import 'package:reelboost_ai/features/creator_profile/domain/creator_profile.dart';
import 'package:reelboost_ai/models/user_model.dart';
import 'package:reelboost_ai/services/reelboost_api_service.dart';

abstract class CreatorProfileRepository {
  Future<CreatorProfile> load();
  Future<UserModel> save(CreatorProfile profile);
}

class CreatorProfileRepositoryImpl implements CreatorProfileRepository {
  CreatorProfileRepositoryImpl(this._api);

  final ReelboostApiService _api;

  @override
  Future<CreatorProfile> load() async {
    final user = await _api.getProfileMe();
    return CreatorProfile.fromUserModel(user);
  }

  @override
  Future<UserModel> save(CreatorProfile profile) async {
    return _api.saveProfile(
      name: profile.name,
      bio: profile.bio,
      instagram: profile.instagramLink,
      facebook: profile.facebookLink,
      niche: profile.niche,
    );
  }
}
