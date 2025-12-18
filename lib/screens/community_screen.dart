import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_menu_drawer.dart';
import 'community_post_detail_screen.dart';
import 'community_write_screen.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '커뮤니티',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.textBlack,
          ),
        ),
        centerTitle: true,
        actions: [
          CommonMenuDrawer.menuIconButton(context),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPostCard(
            context,
            username: '운영자',
            timeAgo: '2시간 전',
            title: '거문오름 기본 정보',
            content: '📍 위치: 제주시 조천읍\n'
                '🏔 형태: 복합형 화산체\n'
                '📏 표고: 456.6m\n'
                '🌲 카테고리: 대표 명소 오름, 숲속 트레킹\n\n'
                '유네스코 세계자연유산으로 지정된 거문오름은 트레킹형 오름으로 원시림이 잘 보존되어 있으며, '
                '트레킹 코스가 잘 정비되어 있어 가족 단위 방문에 적합합니다.',
            likeCount: 24,
            commentCount: 8,
            category: '대표 명소 오름',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CommunityWriteScreen(),
            ),
          );
        },
        backgroundColor: const Color(0xFF4CAF50),
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }

  Widget _buildPostCard(
    BuildContext context, {
    required String username,
    required String timeAgo,
    required String title,
    required String content,
    required int likeCount,
    required int commentCount,
    required String category,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CommunityPostDetailScreen(
                username: username,
                timeAgo: timeAgo,
                title: title,
                content: content,
                likeCount: likeCount,
                commentCount: commentCount,
                category: category,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 사용자 정보
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                        color: const Color(0xFFB8860B).withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: ClipOval(
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.landscape,
                              size: 20,
                              color: Color(0xFFB8860B),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textBlack,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          timeAgo,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textGray.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      category,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 제목
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textBlack,
                ),
              ),
              const SizedBox(height: 8),
              // 내용
              Text(
                content,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textGray.withOpacity(0.8),
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              // 좋아요, 댓글
              Row(
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 18,
                    color: AppTheme.textGray.withOpacity(0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$likeCount',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textGray.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 18,
                    color: AppTheme.textGray.withOpacity(0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$commentCount',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textGray.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
