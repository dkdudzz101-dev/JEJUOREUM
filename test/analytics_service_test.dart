import 'package:flutter_test/flutter_test.dart';
import 'package:jeju_oreum/services/analytics_service.dart';
import 'package:jeju_oreum/models/hiking_record.dart';

void main() {
  group('AnalyticsService', () {
    late AnalyticsService analyticsService;

    setUp(() {
      analyticsService = AnalyticsService();
    });

    test('calculateMonthlyStats returns correct data for completed records', () {
      // Create test records
      final testRecords = [
        HikingRecord(
          oreumCode: 'test1',
          oreumName: '성산일출봉',
          startTime: DateTime(2024, 1, 15),
          totalDistance: 5.0,
          totalTime: 120,
          completed: true,
        ),
        HikingRecord(
          oreumCode: 'test2',
          oreumName: '새별오름',
          startTime: DateTime(2024, 1, 20),
          totalDistance: 3.5,
          totalTime: 90,
          completed: true,
        ),
        HikingRecord(
          oreumCode: 'test3',
          oreumName: '금오름',
          startTime: DateTime(2024, 2, 10),
          totalDistance: 4.2,
          totalTime: 100,
          completed: true,
        ),
      ];

      final monthlyStats = analyticsService.calculateMonthlyStats(testRecords);

      expect(monthlyStats.length, greaterThan(0));
      
      // Find January 2024 stats
      final janStats = monthlyStats.firstWhere(
        (s) => s.year == 2024 && s.month == 1,
        orElse: () => throw Exception('January stats not found'),
      );

      expect(janStats.hikingCount, 2);
      expect(janStats.totalDistance, 8.5);
      expect(janStats.totalTime, 210);
    });

    test('calculateMonthlyStats ignores incomplete records', () {
      final testRecords = [
        HikingRecord(
          oreumCode: 'test1',
          oreumName: '성산일출봉',
          startTime: DateTime(2024, 1, 15),
          totalDistance: 5.0,
          totalTime: 120,
          completed: false, // Not completed
        ),
        HikingRecord(
          oreumCode: 'test2',
          oreumName: '새별오름',
          startTime: DateTime(2024, 1, 20),
          totalDistance: 3.5,
          totalTime: 90,
          completed: true,
        ),
      ];

      final monthlyStats = analyticsService.calculateMonthlyStats(testRecords);

      final janStats = monthlyStats.firstWhere(
        (s) => s.year == 2024 && s.month == 1,
        orElse: () => throw Exception('January stats not found'),
      );

      // Only the completed record should be counted
      expect(janStats.hikingCount, 1);
      expect(janStats.totalDistance, 3.5);
    });

    test('calculateProgressTrend returns correct trend', () {
      final testRecords = [
        HikingRecord(
          oreumCode: 'test1',
          oreumName: '성산일출봉',
          startTime: DateTime.now().subtract(const Duration(days: 90)),
          totalDistance: 5.0,
          totalTime: 120,
          completed: true,
        ),
        HikingRecord(
          oreumCode: 'test2',
          oreumName: '새별오름',
          startTime: DateTime.now().subtract(const Duration(days: 10)),
          totalDistance: 3.5,
          totalTime: 90,
          completed: true,
        ),
        HikingRecord(
          oreumCode: 'test3',
          oreumName: '금오름',
          startTime: DateTime.now().subtract(const Duration(days: 5)),
          totalDistance: 4.2,
          totalTime: 100,
          completed: true,
        ),
      ];

      final progressTrend = analyticsService.calculateProgressTrend(testRecords);

      expect(progressTrend.averageHikesPerMonth, greaterThan(0));
      expect(progressTrend.averageDistancePerHike, greaterThan(0));
      expect(progressTrend.averageTimePerHike, greaterThan(0));
      expect(progressTrend.trend, isIn(['increasing', 'stable', 'decreasing']));
    });

    test('calculateProgressTrend handles empty records', () {
      final progressTrend = analyticsService.calculateProgressTrend([]);

      expect(progressTrend.averageHikesPerMonth, 0);
      expect(progressTrend.averageDistancePerHike, 0);
      expect(progressTrend.averageTimePerHike, 0);
      expect(progressTrend.trend, 'stable');
    });
  });
}
