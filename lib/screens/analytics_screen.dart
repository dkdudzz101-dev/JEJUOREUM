import 'package:flutter/material.dart';
import '../services/hiking_record_service.dart';
import '../services/analytics_service.dart';
import '../models/analytics_model.dart';

/// 데이터 분석 화면
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final HikingRecordService _recordService = HikingRecordService();
  final AnalyticsService _analyticsService = AnalyticsService();
  HikingAnalytics? _analytics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final records = await _recordService.getAllRecords();
      final analytics = await _analyticsService.generateAnalytics(records);
      setState(() {
        _analytics = analytics;
        _isLoading = false;
      });
    } catch (e) {
      // TODO: Replace with proper logging framework in production
      debugPrint('분석 로드 오류: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('데이터 분석'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _analytics == null
              ? const Center(child: Text('분석 데이터를 불러올 수 없습니다'))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 진행 추세
                      _buildProgressTrendSection(_analytics!.progressTrend),

                      const SizedBox(height: 16),

                      // 월별 통계
                      _buildMonthlyStatsSection(_analytics!.monthlyStats),

                      const SizedBox(height: 16),

                      // 카테고리별 통계
                      _buildCategoryStatsSection(_analytics!.categoryStats),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }

  Widget _buildProgressTrendSection(ProgressTrend trend) {
    IconData trendIcon;
    Color trendColor;
    String trendText;

    switch (trend.trend) {
      case 'increasing':
        trendIcon = Icons.trending_up;
        trendColor = Colors.green;
        trendText = '증가 추세';
        break;
      case 'decreasing':
        trendIcon = Icons.trending_down;
        trendColor = Colors.red;
        trendText = '감소 추세';
        break;
      default:
        trendIcon = Icons.trending_flat;
        trendColor = Colors.blue;
        trendText = '안정적';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [trendColor.shade700, trendColor.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(trendIcon, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Text(
                '활동 추세: $trendText',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildTrendStatItem(
                  '월 평균 등산',
                  '${trend.averageHikesPerMonth.toStringAsFixed(1)}회',
                ),
              ),
              Expanded(
                child: _buildTrendStatItem(
                  '평균 거리',
                  '${trend.averageDistancePerHike.toStringAsFixed(1)}km',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTrendStatItem(
            '평균 소요시간',
            '${trend.averageTimePerHike.toStringAsFixed(0)}분',
          ),
        ],
      ),
    );
  }

  Widget _buildTrendStatItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyStatsSection(List<MonthlyStats> monthlyStats) {
    if (monthlyStats.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                '월별 통계 데이터가 없습니다',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ),
        ),
      );
    }

    final maxCount = monthlyStats
        .map((s) => s.hikingCount)
        .reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '월별 등산 횟수',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: monthlyStats.map((stat) {
                  final percentage = maxCount > 0 ? stat.hikingCount / maxCount : 0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              stat.monthLabel,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${stat.hikingCount}회',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: percentage,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.blue.shade400,
                          ),
                          minHeight: 8,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryStatsSection(List<CategoryStats> categoryStats) {
    if (categoryStats.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                '카테고리별 통계 데이터가 없습니다',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '카테고리별 달성률',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...categoryStats.map((stat) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            stat.category,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          '${stat.visitedCount}/${stat.totalCount}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: stat.completionRate / 100,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getProgressColor(stat.completionRate),
                            ),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${stat.completionRate.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _getProgressColor(stat.completionRate),
                          ),
                        ),
                      ],
                    ),
                    if (stat.visitedOreums.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        '방문한 오름: ${stat.visitedOreums.join(", ")}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Color _getProgressColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 50) return Colors.orange;
    if (percentage >= 20) return Colors.blue;
    return Colors.grey;
  }
}
