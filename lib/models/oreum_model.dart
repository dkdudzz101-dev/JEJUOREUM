/// 오름 모델
class Oreum {
  final int id;
  final String folder;
  final String name;
  final double summitLng;
  final double summitLat;
  final double? summitElevation;
  final double? entranceLng;
  final double? entranceLat;
  final double? distanceKm;
  final double? elevMinM;
  final double? elevMaxM;
  final double? elevDiffM;
  final double? avgSlopeMPerKm;
  final String? difficulty;
  final String? color;
  final int? difficultyLevel;

  Oreum({
    required this.id,
    required this.folder,
    required this.name,
    required this.summitLng,
    required this.summitLat,
    this.summitElevation,
    this.entranceLng,
    this.entranceLat,
    this.distanceKm,
    this.elevMinM,
    this.elevMaxM,
    this.elevDiffM,
    this.avgSlopeMPerKm,
    this.difficulty,
    this.color,
    this.difficultyLevel,
  });

  factory Oreum.fromJson(Map<String, dynamic> json) {
    return Oreum(
      id: json['id'] ?? 0,
      folder: json['folder'] ?? '',
      name: json['oreum_name'] ?? json['name'] ?? '이름 없음',
      summitLng: (json['summit_lng'] as num?)?.toDouble() ?? 0.0,
      summitLat: (json['summit_lat'] as num?)?.toDouble() ?? 0.0,
      summitElevation: (json['summit_elevation'] as num?)?.toDouble(),
      entranceLng: (json['entrance_lng'] as num?)?.toDouble(),
      entranceLat: (json['entrance_lat'] as num?)?.toDouble(),
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      elevMinM: (json['elev_min_m'] as num?)?.toDouble(),
      elevMaxM: (json['elev_max_m'] as num?)?.toDouble(),
      elevDiffM: (json['elev_diff_m'] as num?)?.toDouble(),
      avgSlopeMPerKm: (json['avg_slope_m_per_km'] as num?)?.toDouble(),
      difficulty: json['difficulty'],
      color: json['color'],
      difficultyLevel: json['difficulty_level'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'folder': folder,
      'name': name,
      'summit_lng': summitLng,
      'summit_lat': summitLat,
      'summit_elevation': summitElevation,
      'entrance_lng': entranceLng,
      'entrance_lat': entranceLat,
      'distance_km': distanceKm,
      'elev_min_m': elevMinM,
      'elev_max_m': elevMaxM,
      'elev_diff_m': elevDiffM,
      'avg_slope_m_per_km': avgSlopeMPerKm,
      'difficulty': difficulty,
      'color': color,
      'difficulty_level': difficultyLevel,
    };
  }
}
