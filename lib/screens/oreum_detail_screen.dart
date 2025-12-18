import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../models/oreum_model.dart';
import 'main_tab_screen.dart';

class OreumDetailScreen extends StatefulWidget {
  final Oreum oreum;
  final double? entranceLat;
  final double? entranceLng;

  const OreumDetailScreen({
    super.key,
    required this.oreum,
    this.entranceLat,
    this.entranceLng,
  });

  @override
  State<OreumDetailScreen> createState() => _OreumDetailScreenState();
}

class _OreumDetailScreenState extends State<OreumDetailScreen> {

  Oreum get oreum => widget.oreum;

  // folder에서 오름 번호 추출 (예: "100.대수산봉" -> "100")
  String get oreumNumber {
    if (oreum.folder.contains('.')) {
      return oreum.folder.split('.')[0];
    }
    return oreum.folder;
  }

  String get thumbnailUrl =>
      'https://cpnoyaaccshtfncmefet.supabase.co/storage/v1/object/public/oreum-data/thumbnails/$oreumNumber.png';

  String get elevationChartUrl =>
      'https://cpnoyaaccshtfncmefet.supabase.co/storage/v1/object/public/oreum-data/elevation_charts/${oreumNumber}_elevation.png';

  String get mapImageUrl =>
      'https://cpnoyaaccshtfncmefet.supabase.co/storage/v1/object/public/geojson/${oreum.folder}/map.png';

  Future<void> _openKakaoMap() async {
    final lat = widget.entranceLat ?? oreum.entranceLat ?? oreum.summitLat;
    final lng = widget.entranceLng ?? oreum.entranceLng ?? oreum.summitLng;

    debugPrint('=== 입구안내 버튼 클릭 ===');
    debugPrint('widget.entranceLat: ${widget.entranceLat}');
    debugPrint('widget.entranceLng: ${widget.entranceLng}');
    debugPrint('oreum.entranceLat: ${oreum.entranceLat}');
    debugPrint('oreum.entranceLng: ${oreum.entranceLng}');
    debugPrint('oreum.summitLat: ${oreum.summitLat}');
    debugPrint('oreum.summitLng: ${oreum.summitLng}');
    debugPrint('최종 선택된 좌표: $lat, $lng');

    if (lat == null || lng == null) {
      debugPrint('좌표 정보 없음');
      return;
    }

    if (mounted) {
      // 지도 탭으로 이동
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => MainTabScreen(
            initialTab: 2, // 지도 탭
            targetOreumData: {
              'name': oreum.name,
              'lat': lat,
              'lng': lng,
            },
          ),
        ),
        (route) => false,
      );
    }
  }

  Future<void> _startClimbing() async {
    final lat = widget.entranceLat ?? oreum.entranceLat ?? oreum.summitLat;
    final lng = widget.entranceLng ?? oreum.entranceLng ?? oreum.summitLng;

    if (lat == null || lng == null) {
      debugPrint('좌표 정보 없음');
      return;
    }

    if (mounted) {
      // 지도 탭으로 이동
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => MainTabScreen(
            initialTab: 2, // 지도 탭
            targetOreumData: {
              'name': oreum.name,
              'lat': lat,
              'lng': lng,
            },
          ),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 상단 이미지와 AppBar
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.white,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: AppTheme.textBlack),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('제주오름'),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    mapImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(Icons.map, size: 80, color: Colors.grey),
                        ),
                      );
                    },
                  ),
                  // 그라데이션 오버레이
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  // 오름 이름과 정보
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          oreum.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            if (oreum.difficulty != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _getDifficultyColor(oreum.difficulty!),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  oreum.difficulty!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            if (oreum.distanceKm != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${oreum.distanceKm!.toStringAsFixed(1)}km',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 본문 내용
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 입구안내 / 등산시작 버튼
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _openKakaoMap,
                          icon: const Icon(Icons.location_on),
                          label: const Text('입구안내'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Color(0xFF4A90E2), width: 1.5),
                            foregroundColor: const Color(0xFF4A90E2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _startClimbing,
                          icon: const Icon(Icons.terrain),
                          label: const Text('등산시작'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A90E2),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // 고도정보 그래프
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    '고도정보',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textBlack,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      elevationChartUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.show_chart, size: 60, color: Colors.grey),
                                SizedBox(height: 8),
                                Text(
                                  '고도 정보 없음',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // 탐방로 지도 (스토리지 이미지)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    '탐방로 지도',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textBlack,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      mapImageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint('지도 이미지 로드 실패: $error');
                        return Container(
                          height: 300,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.terrain, size: 60, color: Colors.grey),
                                SizedBox(height: 8),
                                Text(
                                  '지도 이미지 없음',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    '오름 정상까지의 추천 탐방로입니다.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textGray,
                    ),
                  ),
                ),

                // 사진 갤러리
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    '사진 갤러리',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textBlack,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    children: [
                      _buildGalleryImage('https://picsum.photos/400/400?random=50'),
                      _buildGalleryImage('https://picsum.photos/400/400?random=51'),
                      _buildGalleryImage('https://picsum.photos/400/400?random=52'),
                      _buildGalleryImage('https://picsum.photos/400/400?random=53'),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // 방문객 리뷰
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    '방문객 리뷰',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textBlack,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                _buildReview(
                  name: '김지은',
                  rating: 5,
                  review: '가을에 방문했는데 억새가 정말 장관이었어요! 바람이 많이 불었지만 경치가 너무 아름다워서 전혀 힘들지 않았습니다. 인생샷 많이 건졌어요!',
                ),
                _buildReview(
                  name: '박준우',
                  rating: 4,
                  review: '가족들과 함께 갔는데, 아이들도 쉽게 오를 수 있는 코스여 좋았습니다. 정상에서 보는 경치 정말 최고였어요. 다음엔 일몰 보러 다시 와야겠어요.',
                ),
                _buildReview(
                  name: '최유리',
                  rating: 5,
                  review: '세벌오름은 언제 와도 좋은 곳 같아요. 특히 노을 질 때 가면 정말 환상적인 풍경을 볼 수 있습니다. 제주도 오면 꼭 들르는 곳이에요!',
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryImage(String imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: const Center(
              child: Icon(Icons.image, size: 50, color: Colors.grey),
            ),
          );
        },
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case '쉬움':
        return const Color(0xFF4CAF50);
      case '보통':
        return const Color(0xFFFF9800);
      case '어려움':
        return const Color(0xFFF44336);
      default:
        return Colors.grey;
    }
  }

  Widget _buildReview({
    required String name,
    required int rating,
    required String review,
  }) {
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.dividerGray,
                child: Icon(Icons.person, color: AppTheme.textGray, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textBlack,
                      ),
                    ),
                    Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          size: 16,
                          color: const Color(0xFFFFC107),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textBlack,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

