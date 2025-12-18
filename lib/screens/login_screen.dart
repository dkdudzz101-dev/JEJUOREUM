import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import '../theme/app_theme.dart';
import 'main_tab_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<void> _loginWithKakao(BuildContext context) async {
    try {
      // 카카오톡 설치 여부 확인
      bool installed = await isKakaoTalkInstalled();

      OAuthToken token;
      if (installed) {
        // 카카오톡으로 로그인
        token = await UserApi.instance.loginWithKakaoTalk();
      } else {
        // 카카오 계정으로 로그인
        token = await UserApi.instance.loginWithKakaoAccount();
      }

      debugPrint('카카오 로그인 성공: ${token.accessToken}');

      // 사용자 정보 가져오기
      User user = await UserApi.instance.me();
      debugPrint('사용자 정보: ${user.kakaoAccount?.profile?.nickname}');

      // 로그인 성공 후 메인 화면으로 이동
      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainTabScreen()),
        );
      }
    } catch (error) {
      debugPrint('카카오 로그인 실패: $error');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그인에 실패했습니다: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 로고
                const Icon(
                  Icons.terrain,
                  size: 100,
                  color: AppTheme.stampGreen,
                ),
                const SizedBox(height: 20),

                // 앱 이름
                const Text(
                  '제주오름',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textBlack,
                  ),
                ),
                const SizedBox(height: 8),

                // 설명
                const Text(
                  '제주의 모든 오름을 탐방하세요',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textGray,
                  ),
                ),
                const SizedBox(height: 60),

                // 카카오 로그인 버튼
                InkWell(
                  onTap: () => _loginWithKakao(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE500),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/kakao_logo.png',
                          width: 24,
                          height: 24,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.chat_bubble,
                              size: 24,
                              color: Color(0xFF3C1E1E),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          '카카오로 시작하기',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3C1E1E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 게스트로 계속하기
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const MainTabScreen()),
                    );
                  },
                  child: const Text(
                    '로그인 없이 둘러보기',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textGray,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
