import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AccessibilityService {
  static final AccessibilityService _instance = AccessibilityService._internal();
  
  factory AccessibilityService() => _instance;
  
  AccessibilityService._internal();
  
  // 스크린 리더에 알림
  Future<void> announce(String message, {bool polite = true}) async {
    // 간단한 접근성 알림
    debugPrint('[접근성] $message');
  }

  // 접근성 트리 업데이트
  void updateSemantics(BuildContext context, String routeName) {
    // 화면 전환 알림
    if (routeName.isNotEmpty) {
      announce('$routeName 화면으로 이동했습니다.');
    }
  }
  
  // 내비게이션을 위한 접근성 레이블 생성
  String getNavigationLabel(String destination, double? distance, int? time) {
    String label = '$destination 까지 ';
    
    if (distance != null) {
      if (distance >= 1) {
        label += '${distance.toStringAsFixed(1)}킬로미터 ';
      } else {
        label += '${(distance * 1000).toInt()}미터 ';
      }
    }
    
    if (time != null) {
      final hours = time ~/ 60;
      final minutes = time % 60;
      
      if (hours > 0) {
        label += '$hours시간 ';
      }
      if (minutes > 0 || hours == 0) {
        label += '${minutes}분 ';
      }
      label += '소요 예정입니다.';
    }
    
    return label;
  }
  
  // 버튼의 접근성 속성 설정
  Map<String, dynamic> buttonSemantics({
    required String label,
    String? hint,
    String? value,
    bool enabled = true,
    bool isSelected = false,
    bool isButton = true,
  }) {
    return {
      'label': label,
      'hint': hint,
      'value': value,
      'enabled': enabled,
      'isSelected': isSelected,
      'isButton': isButton,
      'semanticPropertie': true,
    };
  }
  
  // 이미지의 접근성 속성 설정
  Map<String, dynamic> imageSemantics({
    required String label,
    String? hint,
    bool isLiveRegion = false,
  }) {
    return {
      'label': label,
      'hint': hint,
      'isLiveRegion': isLiveRegion,
      'semanticPropertie': true,
    };
  }
  
  // 텍스트 필드의 접근성 속성 설정
  Map<String, dynamic> textFieldSemantics({
    required String label,
    String? hint,
    String? value,
    bool isFocused = false,
    bool isObscured = false,
    bool isReadOnly = false,
  }) {
    return {
      'label': label,
      'hint': hint,
      'value': value,
      'isFocused': isFocused,
      'isObscured': isObscured,
      'isReadOnly': isReadOnly,
      'semanticPropertie': true,
    };
  }
  
  // 접근성 알림 보내기
  void notifyAccessibilityChanges(BuildContext context) {
    debugPrint('[접근성] 내용이 업데이트되었습니다.');
  }
  
  // 화면 리더가 켜져 있는지 확인
  Future<bool> isScreenReaderEnabled() async {
    try {
      final bool? isEnabled = await const MethodChannel('accessibility')
          .invokeMethod('isScreenReaderEnabled');
      return isEnabled ?? false;
    } catch (e) {
      debugPrint('Screen reader check failed: $e');
      return false;
    }
  }
  
  // 접근성 설정 열기
  Future<void> openAccessibilitySettings() async {
    try {
      await const MethodChannel('accessibility')
          .invokeMethod('openAccessibilitySettings');
    } catch (e) {
      debugPrint('Failed to open accessibility settings: $e');
    }
  }
  
  // 접근성 관련 이벤트 리스너 등록
  void addAccessibilityListener(VoidCallback onAccessibilityChanged) {
    // 플랫폼 채널을 통해 접근성 변경 사항을 수신
    const MethodChannel('accessibility')
        .setMethodCallHandler((call) async {
      if (call.method == 'onAccessibilityChanged') {
        onAccessibilityChanged();
      }
    });
  }
  
  // 접근성 포커스 설정
  void requestFocus(FocusNode node) {
    if (node.canRequestFocus) {
      node.requestFocus();
      debugPrint('[접근성] 포커스가 설정되었습니다.');
    }
  }

  // 접근성 트리 새로고침
  void refreshSemantics() {
    debugPrint('[접근성] Semantics 새로고침');
  }
}
