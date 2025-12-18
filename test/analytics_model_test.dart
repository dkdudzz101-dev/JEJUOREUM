import 'package:flutter_test/flutter_test.dart';
import 'package:jeju_oreum/models/analytics_model.dart';

void main() {
  group('MonthlyStats', () {
    test('monthLabel returns correct format', () {
      final stats = MonthlyStats(
        year: 2024,
        month: 3,
        hikingCount: 5,
        totalDistance: 25.5,
        totalTime: 300,
      );

      expect(stats.monthLabel, '2024.3');
    });

    test('toJson and fromJson work correctly', () {
      final stats = MonthlyStats(
        year: 2024,
        month: 6,
        hikingCount: 10,
        totalDistance: 50.0,
        totalTime: 600,
      );

      final json = stats.toJson();
      final recreated = MonthlyStats.fromJson(json);

      expect(recreated.year, stats.year);
      expect(recreated.month, stats.month);
      expect(recreated.hikingCount, stats.hikingCount);
      expect(recreated.totalDistance, stats.totalDistance);
      expect(recreated.totalTime, stats.totalTime);
    });
  });

  group('CategoryStats', () {
    test('completionRate calculates correctly', () {
      final stats = CategoryStats(
        category: '대표 명소 오름',
        visitedCount: 7,
        totalCount: 14,
        visitedOreums: ['성산일출봉', '새별오름', '금오름'],
      );

      expect(stats.completionRate, 50.0);
    });

    test('completionRate handles zero totalCount', () {
      final stats = CategoryStats(
        category: '테스트',
        visitedCount: 0,
        totalCount: 0,
        visitedOreums: [],
      );

      expect(stats.completionRate, 0.0);
    });

    test('toJson and fromJson work correctly', () {
      final stats = CategoryStats(
        category: '전망 좋은 오름',
        visitedCount: 5,
        totalCount: 10,
        visitedOreums: ['군산오름', '금오름'],
      );

      final json = stats.toJson();
      final recreated = CategoryStats.fromJson(json);

      expect(recreated.category, stats.category);
      expect(recreated.visitedCount, stats.visitedCount);
      expect(recreated.totalCount, stats.totalCount);
      expect(recreated.visitedOreums, stats.visitedOreums);
      expect(recreated.completionRate, stats.completionRate);
    });
  });

  group('ProgressTrend', () {
    test('toJson and fromJson work correctly', () {
      final trend = ProgressTrend(
        averageHikesPerMonth: 5.5,
        averageDistancePerHike: 4.2,
        averageTimePerHike: 95.0,
        trend: 'increasing',
      );

      final json = trend.toJson();
      final recreated = ProgressTrend.fromJson(json);

      expect(recreated.averageHikesPerMonth, trend.averageHikesPerMonth);
      expect(recreated.averageDistancePerHike, trend.averageDistancePerHike);
      expect(recreated.averageTimePerHike, trend.averageTimePerHike);
      expect(recreated.trend, trend.trend);
    });

    test('handles different trend values', () {
      for (var trendValue in ['increasing', 'stable', 'decreasing']) {
        final trend = ProgressTrend(
          averageHikesPerMonth: 1.0,
          averageDistancePerHike: 1.0,
          averageTimePerHike: 1.0,
          trend: trendValue,
        );

        expect(trend.trend, trendValue);
      }
    });
  });

  group('HikingAnalytics', () {
    test('creates instance with all required fields', () {
      final monthlyStats = [
        MonthlyStats(
          year: 2024,
          month: 1,
          hikingCount: 5,
          totalDistance: 25.0,
          totalTime: 300,
        ),
      ];

      final categoryStats = [
        CategoryStats(
          category: '대표 명소 오름',
          visitedCount: 3,
          totalCount: 10,
          visitedOreums: ['성산일출봉'],
        ),
      ];

      final progressTrend = ProgressTrend(
        averageHikesPerMonth: 5.0,
        averageDistancePerHike: 5.0,
        averageTimePerHike: 60.0,
        trend: 'stable',
      );

      final analytics = HikingAnalytics(
        monthlyStats: monthlyStats,
        categoryStats: categoryStats,
        progressTrend: progressTrend,
      );

      expect(analytics.monthlyStats, monthlyStats);
      expect(analytics.categoryStats, categoryStats);
      expect(analytics.progressTrend, progressTrend);
    });
  });
}
