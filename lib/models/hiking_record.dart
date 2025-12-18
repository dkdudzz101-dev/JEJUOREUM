class HikingRecord {
  final String? id;
  final String oreumCode;
  final String oreumName;
  final DateTime startTime;
  final DateTime? endTime;
  final List<HikingPoint> trackingPoints;
  final List<String> photoUrls;
  final double totalDistance;
  final int totalTime; // 분
  final double maxAltitude;
  final double minAltitude;
  final bool completed;
  final Map<String, dynamic>? statistics;

  HikingRecord({
    this.id,
    required this.oreumCode,
    required this.oreumName,
    required this.startTime,
    this.endTime,
    this.trackingPoints = const [],
    this.photoUrls = const [],
    this.totalDistance = 0,
    this.totalTime = 0,
    this.maxAltitude = 0,
    this.minAltitude = 0,
    this.completed = false,
    this.statistics,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'oreum_code': oreumCode,
      'oreum_name': oreumName,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'tracking_points': trackingPoints.map((p) => p.toJson()).toList(),
      'photo_urls': photoUrls,
      'total_distance': totalDistance,
      'total_time': totalTime,
      'max_altitude': maxAltitude,
      'min_altitude': minAltitude,
      'completed': completed,
      'statistics': statistics,
    };
  }

  factory HikingRecord.fromJson(Map<String, dynamic> json) {
    return HikingRecord(
      id: json['id'],
      oreumCode: json['oreum_code'],
      oreumName: json['oreum_name'],
      startTime: DateTime.parse(json['start_time']),
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      trackingPoints: (json['tracking_points'] as List?)
              ?.map((p) => HikingPoint.fromJson(p))
              .toList() ??
          [],
      photoUrls: (json['photo_urls'] as List?)?.map((e) => e.toString()).toList() ?? [],
      totalDistance: (json['total_distance'] as num?)?.toDouble() ?? 0,
      totalTime: json['total_time'] ?? 0,
      maxAltitude: (json['max_altitude'] as num?)?.toDouble() ?? 0,
      minAltitude: (json['min_altitude'] as num?)?.toDouble() ?? 0,
      completed: json['completed'] ?? false,
      statistics: json['statistics'],
    );
  }

  HikingRecord copyWith({
    String? id,
    String? oreumCode,
    String? oreumName,
    DateTime? startTime,
    DateTime? endTime,
    List<HikingPoint>? trackingPoints,
    List<String>? photoUrls,
    double? totalDistance,
    int? totalTime,
    double? maxAltitude,
    double? minAltitude,
    bool? completed,
    Map<String, dynamic>? statistics,
  }) {
    return HikingRecord(
      id: id ?? this.id,
      oreumCode: oreumCode ?? this.oreumCode,
      oreumName: oreumName ?? this.oreumName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      trackingPoints: trackingPoints ?? this.trackingPoints,
      photoUrls: photoUrls ?? this.photoUrls,
      totalDistance: totalDistance ?? this.totalDistance,
      totalTime: totalTime ?? this.totalTime,
      maxAltitude: maxAltitude ?? this.maxAltitude,
      minAltitude: minAltitude ?? this.minAltitude,
      completed: completed ?? this.completed,
      statistics: statistics ?? this.statistics,
    );
  }
}

class HikingPoint {
  final double latitude;
  final double longitude;
  final double altitude;
  final DateTime timestamp;
  final double? speed;

  HikingPoint({
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.timestamp,
    this.speed,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'timestamp': timestamp.toIso8601String(),
      'speed': speed,
    };
  }

  factory HikingPoint.fromJson(Map<String, dynamic> json) {
    return HikingPoint(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      altitude: (json['altitude'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
      speed: (json['speed'] as num?)?.toDouble(),
    );
  }
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String iconName;
  final int requiredCount;
  final String category; // distance, count, altitude, time
  final DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
    required this.requiredCount,
    required this.category,
    this.unlockedAt,
  });

  bool get isUnlocked => unlockedAt != null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon_name': iconName,
      'required_count': requiredCount,
      'category': category,
      'unlocked_at': unlockedAt?.toIso8601String(),
    };
  }

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      iconName: json['icon_name'],
      requiredCount: json['required_count'],
      category: json['category'],
      unlockedAt: json['unlocked_at'] != null ? DateTime.parse(json['unlocked_at']) : null,
    );
  }
}

class HikingStatistics {
  final int totalHikes;
  final int completedHikes;
  final double totalDistance;
  final int totalTime;
  final int uniqueOreums;
  final double maxAltitude;
  final List<Achievement> achievements;

  HikingStatistics({
    required this.totalHikes,
    required this.completedHikes,
    required this.totalDistance,
    required this.totalTime,
    required this.uniqueOreums,
    required this.maxAltitude,
    required this.achievements,
  });

  Map<String, dynamic> toJson() {
    return {
      'total_hikes': totalHikes,
      'completed_hikes': completedHikes,
      'total_distance': totalDistance,
      'total_time': totalTime,
      'unique_oreums': uniqueOreums,
      'max_altitude': maxAltitude,
      'achievements': achievements.map((a) => a.toJson()).toList(),
    };
  }

  factory HikingStatistics.fromJson(Map<String, dynamic> json) {
    return HikingStatistics(
      totalHikes: json['total_hikes'] ?? 0,
      completedHikes: json['completed_hikes'] ?? 0,
      totalDistance: (json['total_distance'] as num?)?.toDouble() ?? 0,
      totalTime: json['total_time'] ?? 0,
      uniqueOreums: json['unique_oreums'] ?? 0,
      maxAltitude: (json['max_altitude'] as num?)?.toDouble() ?? 0,
      achievements: (json['achievements'] as List?)
              ?.map((a) => Achievement.fromJson(a))
              .toList() ??
          [],
    );
  }
}
