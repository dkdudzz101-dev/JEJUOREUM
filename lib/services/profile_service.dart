import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

class ProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// 현재 사용자의 프로필 가져오기
  Future<UserProfile?> getCurrentUserProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      print('프로필 가져오기 실패: $e');
      return null;
    }
  }

  /// 프로필 업데이트
  Future<bool> updateProfile(UserProfile profile) async {
    try {
      await _supabase
          .from('profiles')
          .update(profile.toJson())
          .eq('id', profile.id);
      return true;
    } catch (e) {
      print('프로필 업데이트 실패: $e');
      return false;
    }
  }

  /// 프로필 이미지 URL 업데이트
  Future<bool> updateProfileImageUrl(String userId, String imageUrl) async {
    try {
      await _supabase
          .from('profiles')
          .update({'profile_image_url': imageUrl})
          .eq('id', userId);
      return true;
    } catch (e) {
      print('프로필 이미지 URL 업데이트 실패: $e');
      return false;
    }
  }
}
