import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import '../models/hiking_record.dart';
import '../models/analytics_model.dart';

/// 등산 데이터 분석 서비스
class AnalyticsService {
  Map<String, List<String>>? _categoryMap;

  /// CSV에서 카테고리 데이터 로드
  Future<void> loadCategoryData() async {
    if (_categoryMap != null) return;

    try {
      final csvString =
          await rootBundle.loadString('assets/data/oreum_categories.csv');
      final List<List<dynamic>> rows =
          const CsvToListConverter().convert(csvString);

      _categoryMap = {};

      // 첫 번째 행은 헤더이므로 건너뜀
      for (int i = 1; i < rows.length; i++) {
        if (rows[i].length >= 2) {
          final category = rows[i][0].toString();
          final oreumName = rows[i][1].toString();

          if (!_categoryMap!.containsKey(category)) {
            _categoryMap![category] = [];
          }
          _categoryMap![category]!.add(oreumName);
        }
      }
    } catch (e) {
      print('카테고리 데이터 로드 오류: $e');
      _categoryMap = {};
    }
  }

  /// 월별 통계 계산
  List<MonthlyStats> calculateMonthlyStats(List<HikingRecord> records) {
    final Map<String, MonthlyStats> monthlyMap = {};

    for (var record in records) {
      if (!record.completed) continue;

      final date = record.startTime;
      final key = '${date.year}-${date.month}';

      if (!monthlyMap.containsKey(key)) {
        monthlyMap[key] = MonthlyStats(
          year: date.year,
          month: date.month,
          hikingCount: 0,
          totalDistance: 0,
          totalTime: 0,
        );
      }

      final existing = monthlyMap[key]!;
      monthlyMap[key] = MonthlyStats(
        year: existing.year,
        month: existing.month,
        hikingCount: existing.hikingCount + 1,
        totalDistance: existing.totalDistance + record.totalDistance,
        totalTime: existing.totalTime + record.totalTime,
      );
    }

    // 최근 6개월만 반환
    final sortedStats = monthlyMap.values.toList()
      ..sort((a, b) {
        final dateA = DateTime(a.year, a.month);
        final dateB = DateTime(b.year, b.month);
        return dateB.compareTo(dateA);
      });

    return sortedStats.take(6).toList().reversed.toList();
  }

  /// 카테고리별 통계 계산
  Future<List<CategoryStats>> calculateCategoryStats(
      List<HikingRecord> records) async {
    await loadCategoryData();

    final visitedOreums = records
        .where((r) => r.completed)
        .map((r) => r.oreumName)
        .toSet()
        .toList();

    final List<CategoryStats> categoryStatsList = [];

    _categoryMap?.forEach((category, oreumList) {
      final visited = visitedOreums.where((name) => oreumList.contains(name)).toList();

      categoryStatsList.add(CategoryStats(
        category: category,
        visitedCount: visited.length,
        totalCount: oreumList.length,
        visitedOreums: visited,
      ));
    });

    // 방문 비율이 높은 순으로 정렬
    categoryStatsList.sort((a, b) => b.completionRate.compareTo(a.completionRate));

    return categoryStatsList;
  }

  /// 진행 추세 계산
  ProgressTrend calculateProgressTrend(List<HikingRecord> records) {
    final completedRecords = records.where((r) => r.completed).toList();

    if (completedRecords.isEmpty) {
      return ProgressTrend(
        averageHikesPerMonth: 0,
        averageDistancePerHike: 0,
        averageTimePerHike: 0,
        trend: 'stable',
      );
    }

    // 월별 등산 횟수 계산
    final monthlyMap = <String, int>{};
    for (var record in completedRecords) {
      final key = '${record.startTime.year}-${record.startTime.month}';
      monthlyMap[key] = (monthlyMap[key] ?? 0) + 1;
    }

    final averageHikesPerMonth = monthlyMap.isNotEmpty
        ? monthlyMap.values.reduce((a, b) => a + b) / monthlyMap.length
        : 0.0;

    // 평균 거리 및 시간 계산
    final totalDistance = completedRecords.fold<double>(
      0,
      (sum, r) => sum + r.totalDistance,
    );
    final totalTime = completedRecords.fold<int>(
      0,
      (sum, r) => sum + r.totalTime,
    );

    final averageDistancePerHike = totalDistance / completedRecords.length;
    final averageTimePerHike = totalTime / completedRecords.length;

    // 추세 계산 (최근 3개월 vs 이전 3개월)
    final now = DateTime.now();
    final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);
    final sixMonthsAgo = DateTime(now.year, now.month - 6, now.day);

    final recentRecords = completedRecords
        .where((r) => r.startTime.isAfter(threeMonthsAgo))
        .length;
    final olderRecords = completedRecords
        .where((r) =>
            r.startTime.isAfter(sixMonthsAgo) &&
            r.startTime.isBefore(threeMonthsAgo))
        .length;

    String trend = 'stable';
    if (recentRecords > olderRecords * 1.2) {
      trend = 'increasing';
    } else if (recentRecords < olderRecords * 0.8) {
      trend = 'decreasing';
    }

    return ProgressTrend(
      averageHikesPerMonth: averageHikesPerMonth,
      averageDistancePerHike: averageDistancePerHike,
      averageTimePerHike: averageTimePerHike,
      trend: trend,
    );
  }

  /// 전체 분석 데이터 생성
  Future<HikingAnalytics> generateAnalytics(
      List<HikingRecord> records) async {
    final monthlyStats = calculateMonthlyStats(records);
    final categoryStats = await calculateCategoryStats(records);
    final progressTrend = calculateProgressTrend(records);

    return HikingAnalytics(
      monthlyStats: monthlyStats,
      categoryStats: categoryStats,
      progressTrend: progressTrend,
    );
  }
}
