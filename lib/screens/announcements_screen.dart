import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AnnouncementsScreen extends StatelessWidget {
  const AnnouncementsScreen({super.key});

  final List<Map<String, String>> _announcements = const [
    {
      'title': '시스템 점검 안내',
      'date': '2023년 11월 15일',
    },
    {
      'title': '새로운 서비스 출시 공지',
      'date': '2023년 11월 10일',
    },
    {
      'title': '개인정보처리방침 변경 안내',
      'date': '2023년 10월 26일',
    },
    {
      'title': '서버 안정화 작업 안료',
      'date': '2023년 10월 20일',
    },
    {
      'title': '모바일 앱 업데이트 예정',
      'date': '2023년 10월 10일',
    },
    {
      'title': '커뮤니티 가이드라인 변경',
      'date': '2023년 09월 28일',
    },
    {
      'title': '고객센터 운영 시간 변경',
      'date': '2023년 09월 15일',
    },
    {
      'title': '신규 이벤트 안내: 친구 초대',
      'date': '2023년 09월 05일',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textBlack),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '공지사항',
          style: TextStyle(
            color: AppTheme.textBlack,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _announcements.length,
        itemBuilder: (context, index) {
          final announcement = _announcements[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.campaign,
                  color: AppTheme.primaryBrown,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        announcement['title']!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textBlack,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        announcement['date']!,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textGray.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
