import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_menu_drawer.dart';
import 'category_oreum_list_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '제주오름',
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 메인 배경 이미지
            Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.6,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/main_background.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFF8FB5A8),
                      child: const Center(
                        child: Icon(
                          Icons.landscape,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // 오름 카테고리
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '오름 카테고리',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textBlack,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 140,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                children: [
                  _buildCategoryCard(
                    context,
                    '대표 명소 오름',
                    '14개',
                    const Color(0xFF8FB5A8),
                    'assets/images/categories/representative.png',
                  ),
                  const SizedBox(width: 12),
                  _buildCategoryCard(
                    context,
                    '전망 좋은 오름',
                    '14개',
                    const Color(0xFFA0988C),
                    'assets/images/categories/view.png',
                  ),
                  const SizedBox(width: 12),
                  _buildCategoryCard(
                    context,
                    '숲속 트레킹 오름',
                    '12개',
                    const Color(0xFF9B8B7E),
                    'assets/images/categories/forest.png',
                  ),
                  const SizedBox(width: 12),
                  _buildCategoryCard(
                    context,
                    '가족 산책 오름',
                    '11개',
                    const Color(0xFF8FB5A8),
                    'assets/images/categories/family.png',
                  ),
                  const SizedBox(width: 12),
                  _buildCategoryCard(
                    context,
                    '계절 명소 오름',
                    '14개',
                    const Color(0xFFA0988C),
                    'assets/images/categories/seasonal.png',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    String title,
    String count,
    Color color,
    String imagePath,
  ) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryOreumListScreen(category: title),
          ),
        );
      },
      child: Container(
        width: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            // 배경 이미지
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                imagePath,
                width: 180,
                height: 140,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 180,
                    height: 140,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [
                          color.withOpacity(0.8),
                          color,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Icon(
                      Icons.landscape,
                      size: 80,
                      color: Colors.white.withOpacity(0.15),
                    ),
                  );
                },
              ),
            ),
            // 그라데이션 오버레이
            Container(
              width: 180,
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.6),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            // 텍스트
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    count,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
