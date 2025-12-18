import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:csv/csv.dart';
import '../theme/app_theme.dart';
import '../widgets/common_menu_drawer.dart';
import 'oreum_detail_screen.dart';
import '../services/oreum_service.dart';
import '../models/oreum_model.dart';

class CategoryOreumListScreen extends StatefulWidget {
  final String category;

  const CategoryOreumListScreen({
    super.key,
    required this.category,
  });

  @override
  State<CategoryOreumListScreen> createState() => _CategoryOreumListScreenState();
}

class _CategoryOreumListScreenState extends State<CategoryOreumListScreen> {
  List<String> _oreumList = [];
  List<Oreum> _allOreums = [];
  bool _isLoading = true;
  final OreumService _oreumService = OreumService();

  @override
  void initState() {
    super.initState();
    _loadOreumData();
  }

  Future<void> _loadOreumData() async {
    try {
      // 모든 오름 데이터 로드
      final allOreums = await _oreumService.getAllOreums();

      // CSV에서 카테고리에 해당하는 오름 이름 로드
      final csvString = await rootBundle.loadString('assets/data/oreum_categories.csv');
      final List<List<dynamic>> csvData = const CsvToListConverter().convert(csvString);

      final List<String> filteredList = [];
      for (var i = 1; i < csvData.length; i++) {
        if (csvData[i][0] == widget.category) {
          filteredList.add(csvData[i][1].toString());
        }
      }

      setState(() {
        _allOreums = allOreums;
        _oreumList = filteredList;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading CSV: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  IconData _getCategoryIcon() {
    switch (widget.category) {
      case '대표 명소 오름':
        return Icons.star;
      case '전망 좋은 오름':
        return Icons.camera_alt;
      case '숲속 트레킹 오름':
        return Icons.nature;
      case '가족 산책 오름':
        return Icons.family_restroom;
      case '계절 명소 오름':
        return Icons.wb_sunny;
      default:
        return Icons.landscape;
    }
  }

  Color _getCategoryColor() {
    switch (widget.category) {
      case '대표 명소 오름':
        return const Color(0xFFFF9800);
      case '전망 좋은 오름':
        return const Color(0xFF2196F3);
      case '숲속 트레킹 오름':
        return const Color(0xFF4CAF50);
      case '가족 산책 오름':
        return const Color(0xFFE91E63);
      case '계절 명소 오름':
        return const Color(0xFF9C27B0);
      default:
        return AppTheme.stampGreen;
    }
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
        title: Text(
          widget.category,
          style: const TextStyle(
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _oreumList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 60,
                        color: AppTheme.textGray.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '오름 정보를 불러올 수 없습니다',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.textGray.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // 카테고리 헤더
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getCategoryColor(),
                            _getCategoryColor().withOpacity(0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _getCategoryIcon(),
                            size: 48,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.category,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '총 ${_oreumList.length}개의 오름',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 오름 리스트
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _oreumList.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
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
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _getCategoryColor().withOpacity(0.1),
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: _getCategoryColor(),
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                _oreumList[index],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textBlack,
                                ),
                              ),
                              trailing: Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: AppTheme.textGray.withOpacity(0.4),
                              ),
                              onTap: () {
                                // 해당 오름 이름으로 Oreum 객체 찾기
                                final oreumName = _oreumList[index];
                                final oreum = _allOreums.firstWhere(
                                  (o) => o.name == oreumName,
                                  orElse: () => _allOreums.first,
                                );

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => OreumDetailScreen(
                                      oreum: oreum,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
