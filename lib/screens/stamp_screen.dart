import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../widgets/common_menu_drawer.dart';

class StampScreen extends StatelessWidget {
  const StampScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 스탬프 데이터 (실제 앱에서는 API나 데이터베이스에서 가져옵니다)
    final List<Map<String, dynamic>> stamps = [
      {
        'name': '새별오름',
        'date': '2023.10.26',
        'image': 'assets/images/stampbook/saebyeol.png',
      },
      {
        'name': '아부오름',
        'date': '2023.11.05',
        'image': 'assets/images/stampbook/abu.png',
      },
      {
        'name': '용눈이오름',
        'date': '2023.11.18',
        'image': 'assets/images/stampbook/yongnuni.png',
      },
      {
        'name': '다랑쉬오름',
        'date': '2023.12.01',
        'image': 'assets/images/stampbook/darangsui.png',
      },
      {
        'name': '성산일출봉',
        'date': '2024.01.10',
        'image': 'assets/images/stampbook/sunrise.png',
      },
      {
        'name': '금오름',
        'date': '2024.01.28',
        'image': 'assets/images/stampbook/geum.png',
      },
    ];

    final int totalOreum = 368;
    final int completedOreum = stamps.length;
    final double progress = completedOreum / totalOreum;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '제주오름',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          CommonMenuDrawer.menuIconButton(context),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 완등 현황 섹션
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '나의 오름 완등 현황',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '총 $totalOreum개의 오름 중 $completedOreum개 완등',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF8A00)),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                Text(
                  '다음 완등까지 ${(1 / (progress == 0 ? 0.01 : progress) - completedOreum).toInt()}개 남음',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          
          // 획득한 스탬프 섹션
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              '획득한 스탬프',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // 스탬프 그리드
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.9,
              ),
              itemCount: stamps.length,
              itemBuilder: (context, index) {
                return _buildStampCard(stamps[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStampCard(Map<String, dynamic> stamp) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 스탬프 이미지
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Image.asset(
                stamp['image'],
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                  );
                },
              ),
            ),
          ),
          
          // 스탬프 정보
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stamp['name'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${stamp['date']} 방문',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
