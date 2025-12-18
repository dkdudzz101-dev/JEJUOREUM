import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import 'profile_service.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileService _profileService = ProfileService();
  UserProfile? _userProfile;
  bool _isLoading = false;
  String? _error;

  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// 프로필 이미지 URL getter (편의 메서드)
  String? get profileImageUrl => _userProfile?.profileImageUrl;

  /// 프로필 로드
  Future<void> loadProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _userProfile = await _profileService.getCurrentUserProfile();
      _error = null;
    } catch (e) {
      _error = '프로필을 불러오는데 실패했습니다: $e';
      _userProfile = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 프로필 업데이트
  Future<bool> updateProfile(UserProfile profile) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _profileService.updateProfile(profile);
      if (success) {
        _userProfile = profile;
        _error = null;
      } else {
        _error = '프로필 업데이트에 실패했습니다';
      }
      return success;
    } catch (e) {
      _error = '프로필 업데이트 중 오류 발생: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 프로필 이미지 URL 업데이트
  Future<bool> updateProfileImageUrl(String imageUrl) async {
    if (_userProfile == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final success = await _profileService.updateProfileImageUrl(
        _userProfile!.id,
        imageUrl,
      );

      if (success) {
        _userProfile = _userProfile!.copyWith(profileImageUrl: imageUrl);
        _error = null;
        return true;
      }

      _error = '프로필 이미지 업데이트에 실패했습니다';
      return false;
    } catch (e) {
      _error = '프로필 이미지 업데이트 중 오류 발생: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 프로필 초기화
  void clearProfile() {
    _userProfile = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
