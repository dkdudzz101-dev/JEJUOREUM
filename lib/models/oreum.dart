// 새 Supabase 테이블 구조에 맞는 오름 모델
class Oreum {
  // oreums 테이블 필드들 (19개 컬럼)
  final int? uniqueId;
  final String? name;
  final String? city;
  final String? address;
  final double? height;
  final double? lat;
  final double? lng;
  final String? description;
  final String? difficulty;
  final String? estimatedTime;
  final String? parking;
  final String? entranceInfo;
  final String? publicTransport;
  final String? difficultyDescription;
  final String? preparation;
  final String? safetyNotes;
  final String? toilet;
  final String? store;
  final String? water;
  final String? origin;

  Oreum({
    this.uniqueId,
    this.name,
    this.city,
    this.address,
    this.height,
    this.lat,
    this.lng,
    this.description,
    this.difficulty,
    this.estimatedTime,
    this.parking,
    this.entranceInfo,
    this.publicTransport,
    this.difficultyDescription,
    this.preparation,
    this.safetyNotes,
    this.toilet,
    this.store,
    this.water,
    this.origin,
  });

  factory Oreum.fromJson(Map<String, dynamic> json) {
    return Oreum(
      uniqueId: json['unique_id'] as int?,
      name: json['name'] as String?,
      city: json['city'] as String?,
      address: json['address'] as String?,
      height: _parseDouble(json['height']),
      lat: _parseDouble(json['lat']),
      lng: _parseDouble(json['lng']),
      description: json['description'] as String?,
      difficulty: json['difficulty'] as String?,
      estimatedTime: json['estimated_time'] as String?,
      parking: json['parking'] as String?,
      entranceInfo: json['entrance_info'] as String?,
      publicTransport: json['public_transport'] as String?,
      difficultyDescription: json['difficulty_description'] as String?,
      preparation: json['preparation'] as String?,
      safetyNotes: json['safety_notes'] as String?,
      toilet: json['toilet'] as String?,
      store: json['store'] as String?,
      water: json['water'] as String?,
      origin: json['origin'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'unique_id': uniqueId,
      'name': name,
      'city': city,
      'address': address,
      'height': height,
      'lat': lat,
      'lng': lng,
      'description': description,
      'difficulty': difficulty,
      'estimated_time': estimatedTime,
      'parking': parking,
      'entrance_info': entranceInfo,
      'public_transport': publicTransport,
      'difficulty_description': difficultyDescription,
      'preparation': preparation,
      'safety_notes': safetyNotes,
      'toilet': toilet,
      'store': store,
      'water': water,
      'origin': origin,
    };
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  // 편의 메소드들
  bool get hasValidCoordinates => lat != null && lng != null;

  String get displayName => name ?? '이름 없음';
  String get displayLocation => city ?? '';
  String get displayElevation => height != null ? '${height?.toStringAsFixed(1)}m' : '고도 정보 없음';
  String get displayDifficulty => difficultyDescription ?? '난이도 정보 없음';
  String get displayTime => estimatedTime ?? '소요시간 정보 없음';

  // 네비게이션용 좌표
  double? get navigationLatitude => lat;
  double? get navigationLongitude => lng;

  // 기존 코드 호환성을 위한 필드들
  String? get koreanName => name;
  double? get latitude => lat;
  double? get longitude => lng;
  String? get addressFull => address;
  String? get features => description;
  double? get officialElevation => height;
  String? get accessDifficulty => difficulty;
  String? get difficultyLevel => difficulty;
  String? get accessFeatures => entranceInfo;
  String? get oreumId => uniqueId?.toString();

  // 입구 좌표 관련 (현재는 없지만 호환성을 위해)
  double? get entranceLatitude => null;
  double? get entranceLongitude => null;
  bool get hasEntranceCoordinates => false;

  // 입구 정보 관련 메서드들
  Future<List<OreumEntrance>> getEntrances() async {
    if (name == null) return [];

    // OreumService를 통해 입구 정보 가져오기
    // 이 메서드는 순환 참조를 피하기 위해 별도 구현 필요
    return [];
  }
}

// 입구 정보 모델
class OreumEntrance {
  final int? uniqueId;
  final String? oreumName;
  final double? entranceLat;
  final double? entranceLng;
  final String? entranceType;
  final String? entranceDescription;

  OreumEntrance({
    this.uniqueId,
    this.oreumName,
    this.entranceLat,
    this.entranceLng,
    this.entranceType,
    this.entranceDescription,
  });

  factory OreumEntrance.fromJson(Map<String, dynamic> json) {
    return OreumEntrance(
      uniqueId: json['unique_id'] as int?,
      oreumName: json['oreum_name'] as String?,
      entranceLat: _parseDouble(json['entrance_lat']),
      entranceLng: _parseDouble(json['entrance_lng']),
      entranceType: json['entrance_type'] as String?,
      entranceDescription: json['entrance_description'] as String?,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  bool get hasValidCoordinates => entranceLat != null && entranceLng != null;
}