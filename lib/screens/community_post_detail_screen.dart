import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_menu_drawer.dart';

class CommunityPostDetailScreen extends StatefulWidget {
  final String username;
  final String timeAgo;
  final String title;
  final String content;
  final int likeCount;
  final int commentCount;
  final String category;

  const CommunityPostDetailScreen({
    super.key,
    required this.username,
    required this.timeAgo,
    required this.title,
    required this.content,
    required this.likeCount,
    required this.commentCount,
    required this.category,
  });

  @override
  State<CommunityPostDetailScreen> createState() => _CommunityPostDetailScreenState();
}

class _CommunityPostDetailScreenState extends State<CommunityPostDetailScreen> {
  bool _isLiked = false;
  int _currentLikes = 0;

  @override
  void initState() {
    super.initState();
    _currentLikes = widget.likeCount;
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      _currentLikes = _isLiked ? _currentLikes + 1 : _currentLikes - 1;
    });
  }

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
          '게시글',
          style: TextStyle(
            color: AppTheme.textBlack,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          CommonMenuDrawer.menuIconButton(context),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 카테고리 태그
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.category,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 제목
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textBlack,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 사용자 정보
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
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
                                  size: 22,
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
                              widget.username,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textBlack,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.timeAgo,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textGray.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // 내용
                  Text(
                    widget.content,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textGray.withOpacity(0.9),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // 좋아요, 댓글
                  Row(
                    children: [
                      InkWell(
                        onTap: _toggleLike,
                        child: Row(
                          children: [
                            Icon(
                              _isLiked ? Icons.favorite : Icons.favorite_border,
                              size: 22,
                              color: _isLiked ? Colors.red : AppTheme.textGray.withOpacity(0.5),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$_currentLikes',
                              style: TextStyle(
                                fontSize: 15,
                                color: AppTheme.textGray.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 22,
                        color: AppTheme.textGray.withOpacity(0.5),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${widget.commentCount}',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppTheme.textGray.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 8, color: Color(0xFFF5F5F5)),
            // 댓글 섹션
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '댓글 ${widget.commentCount}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textBlack,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 48,
                          color: AppTheme.textGray.withOpacity(0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '댓글 기능 준비중입니다',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textGray.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
