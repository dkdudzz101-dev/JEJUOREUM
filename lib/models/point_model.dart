/// 포인트 모델 (입구, 분기점 등)
class TrailPoint {
  final int id;
  final int oreumId;
  final String oreumFolder;
  final String oreumName;
  final String? pointType;
  final String? pointName;
  final double lng;
  final double lat;
  final double? elevation;

  TrailPoint({
    required this.id,
    required this.oreumId,
    required this.oreumFolder,
    required this.oreumName,
    this.pointType,
    this.pointName,
    required this.lng,
    required this.lat,
    this.elevation,
  });

  factory TrailPoint.fromJson(Map<String, dynamic> json) {
    return TrailPoint(
      id: json['id'],
      oreumId: json['oreum_id'],
      oreumFolder: json['oreum_folder'],
      oreumName: json['oreum_name'],
      pointType: json['point_type'],
      pointName: json['point_name'],
      lng: (json['lng'] as num).toDouble(),
      lat: (json['lat'] as num).toDouble(),
      elevation: json['elevation']?.toDouble(),
    );
  }

  /// 입구인지 확인
  bool get isEntrance => pointType?.contains('시종점') ?? false;

  /// 분기점인지 확인
  bool get isBranch => pointType?.contains('분기점') ?? false;
}
