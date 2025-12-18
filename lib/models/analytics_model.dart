/// 분석 데이터 모델
class HikingAnalytics {
  final List<MonthlyStats> monthlyStats;
  final List<CategoryStats> categoryStats;
  final ProgressTrend progressTrend;

  HikingAnalytics({
    required this.monthlyStats,
    required this.categoryStats,
    required this.progressTrend,
  });
}

/// 월별 통계
class MonthlyStats {
  final int year;
  final int month;
  final int hikingCount;
  final double totalDistance;
  final int totalTime;

  MonthlyStats({
    required this.year,
    required this.month,
    required this.hikingCount,
    required this.totalDistance,
    required this.totalTime,
  });

  String get monthLabel => '$year.$month';

  factory MonthlyStats.fromJson(Map<String, dynamic> json) {
    return MonthlyStats(
      year: json['year'] ?? 0,
      month: json['month'] ?? 0,
      hikingCount: json['hiking_count'] ?? 0,
      totalDistance: (json['total_distance'] as num?)?.toDouble() ?? 0.0,
      totalTime: json['total_time'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'month': month,
      'hiking_count': hikingCount,
      'total_distance': totalDistance,
      'total_time': totalTime,
    };
  }
}

/// 카테고리별 통계
class CategoryStats {
  final String category;
  final int visitedCount;
  final int totalCount;
  final List<String> visitedOreums;

  CategoryStats({
    required this.category,
    required this.visitedCount,
    required this.totalCount,
    required this.visitedOreums,
  });

  double get completionRate =>
      totalCount > 0 ? (visitedCount / totalCount) * 100 : 0;

  factory CategoryStats.fromJson(Map<String, dynamic> json) {
    return CategoryStats(
      category: json['category'] ?? '',
      visitedCount: json['visited_count'] ?? 0,
      totalCount: json['total_count'] ?? 0,
      visitedOreums: (json['visited_oreums'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'visited_count': visitedCount,
      'total_count': totalCount,
      'visited_oreums': visitedOreums,
    };
  }
}

/// 진행 추세
class ProgressTrend {
  final double averageHikesPerMonth;
  final double averageDistancePerHike;
  final double averageTimePerHike;
  final String trend; // 'increasing', 'stable', 'decreasing'

  ProgressTrend({
    required this.averageHikesPerMonth,
    required this.averageDistancePerHike,
    required this.averageTimePerHike,
    required this.trend,
  });

  factory ProgressTrend.fromJson(Map<String, dynamic> json) {
    return ProgressTrend(
      averageHikesPerMonth:
          (json['average_hikes_per_month'] as num?)?.toDouble() ?? 0.0,
      averageDistancePerHike:
          (json['average_distance_per_hike'] as num?)?.toDouble() ?? 0.0,
      averageTimePerHike:
          (json['average_time_per_hike'] as num?)?.toDouble() ?? 0.0,
      trend: json['trend'] ?? 'stable',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'average_hikes_per_month': averageHikesPerMonth,
      'average_distance_per_hike': averageDistancePerHike,
      'average_time_per_hike': averageTimePerHike,
      'trend': trend,
    };
  }
}
