/// 등산로 모델
class Trail {
  final int id;
  final int oreumId;
  final String oreumFolder;
  final String oreumName;
  final String? trailName;
  final Map<String, dynamic> geojson;
  final double? lengthM;
  final String? difficulty;

  Trail({
    required this.id,
    required this.oreumId,
    required this.oreumFolder,
    required this.oreumName,
    this.trailName,
    required this.geojson,
    this.lengthM,
    this.difficulty,
  });

  factory Trail.fromJson(Map<String, dynamic> json) {
    return Trail(
      id: json['id'],
      oreumId: json['oreum_id'],
      oreumFolder: json['oreum_folder'],
      oreumName: json['oreum_name'],
      trailName: json['trail_name'],
      geojson: json['geojson'] as Map<String, dynamic>,
      lengthM: json['length_m']?.toDouble(),
      difficulty: json['difficulty'],
    );
  }

  /// GeoJSON LineString 좌표 리스트 가져오기
  List<List<double>> get coordinates {
    if (geojson['type'] == 'LineString') {
      return (geojson['coordinates'] as List)
          .map((coord) => (coord as List).map((e) => (e as num).toDouble()).toList())
          .toList();
    } else if (geojson['type'] == 'MultiLineString') {
      // MultiLineString의 첫 번째 선 사용
      return ((geojson['coordinates'] as List).first as List)
          .map((coord) => (coord as List).map((e) => (e as num).toDouble()).toList())
          .toList();
    }
    return [];
  }
}
