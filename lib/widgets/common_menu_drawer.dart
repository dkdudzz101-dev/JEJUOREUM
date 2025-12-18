import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../screens/contact_us_screen.dart';
import '../screens/report_screen.dart';
import '../screens/announcements_screen.dart';
import '../screens/faq_screen.dart';
import '../screens/terms_of_use_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/statistics_screen.dart';
import '../screens/analytics_screen.dart';
import '../services/profile_provider.dart';

class CommonMenuDrawer {
  static void show(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.75,
              height: MediaQuery.of(context).size.height,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(0),
                  bottomLeft: Radius.circular(0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 상단 헤더
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '메뉴',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textBlack,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppTheme.textBlack),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppTheme.dividerGray),
                  const SizedBox(height: 20),

                  // 메뉴 항목들
                  _buildMenuItem(context, '통계 & 업적', () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const StatisticsScreen()),
                    );
                  }),
                  _buildMenuItem(context, '데이터 분석', () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
                    );
                  }),
                  const Divider(height: 1, color: AppTheme.dividerGray),
                  const SizedBox(height: 12),
                  _buildMenuItem(context, '문의하기', () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ContactUsScreen()),
                    );
                  }),
                  _buildMenuItem(context, '신고하기', () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ReportScreen()),
                    );
                  }),
                  _buildMenuItem(context, '공지사항', () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AnnouncementsScreen()),
                    );
                  }),
                  _buildMenuItem(context, '자주 묻는 질문', () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const FAQScreen()),
                    );
                  }),
                  _buildMenuItem(context, '이용약관', () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TermsOfUseScreen()),
                    );
                  }),
                  _buildMenuItem(context, '설정', () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
      },
    );
  }

  static Widget _buildMenuItem(BuildContext context, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            color: AppTheme.textBlack,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // AppBar에 추가할 햄버거 아이콘 버튼 (사용자 아이콘 포함)
  static Widget menuIconButton(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        final profileImageUrl = profileProvider.profileImageUrl;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 동그라미 사용자 아이콘 또는 프로필 사진
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFB8860B).withOpacity(0.1),
                border: Border.all(
                  color: const Color(0xFFB8860B),
                  width: 1.5,
                ),
              ),
              child: profileImageUrl != null && profileImageUrl.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        profileImageUrl,
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.person,
                            color: Color(0xFFB8860B),
                            size: 18,
                          );
                        },
                      ),
                    )
                  : const Icon(
                      Icons.person,
                      color: Color(0xFFB8860B),
                      size: 18,
                    ),
            ),
            const SizedBox(width: 8),
            // 햄버거 메뉴 아이콘
            IconButton(
              icon: const Icon(Icons.menu, color: AppTheme.textBlack),
              onPressed: () => show(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
          ],
        );
      },
    );
  }
}
