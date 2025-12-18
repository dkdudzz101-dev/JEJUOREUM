import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math' as math;

/// Storage 기반 오름 서비스 (GeoJSON)
class StorageOreumService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String bucketName = 'oreum-data';

  // ===================================
  // 1. 오름 목록 (테이블에서 빠르게 가져오기)
  // ===================================

  /// 모든 오름 목록 가져오기
  Future<List<Map<String, dynamic>>> getAllOreums() async {
    try {
      final response = await _supabase
          .from('oreums')
          .select()
          .order('oreum_name');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('오름 목록 가져오기 오류: $e');
      return [];
    }
  }

  /// 난이도별 필터링
  Future<List<Map<String, dynamic>>> getOreumsByDifficulty(String difficulty) async {
    try {
      final response = await _supabase
          .from('oreums')
          .select()
          .eq('difficulty', difficulty)
          .order('oreum_name');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('난이도별 필터링 오류: $e');
      return [];
    }
  }

  /// 거리별 필터링 (최대 거리)
  Future<List<Map<String, dynamic>>> getOreumsByDistance(double maxKm) async {
    try {
      final response = await _supabase
          .from('oreums')
          .select()
          .lte('distance_km', maxKm)
          .order('distance_km');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('거리별 필터링 오류: $e');
      return [];
    }
  }

  /// 소요시간별 필터링 (최대 시간, 분)
  Future<List<Map<String, dynamic>>> getOreumsByTime(int maxMinutes) async {
    try {
      final response = await _supabase
          .from('oreums')
          .select()
          .lte('total_time', maxMinutes)
          .order('total_time');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('시간별 필터링 오류: $e');
      return [];
    }
  }

  /// 오름 검색 (이름)
  Future<List<Map<String, dynamic>>> searchOreums(String query) async {
    try {
      final response = await _supabase
          .from('oreums')
          .select()
          .ilike('oreum_name', '%$query%')
          .order('oreum_name');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('검색 오류: $e');
      return [];
    }
  }

  // ===================================
  // 2. 상세 데이터 (GeoJSON & 이미지)
  // ===================================

  /// GeoJSON 데이터 다운로드
  Future<Map<String, dynamic>> getOreumGeoJson(String oreumCode) async {
    try {
      final bytes = await _supabase.storage
          .from(bucketName)
          .download('$oreumCode/data.geojson');

      final jsonString = utf8.decode(bytes);
      return jsonDecode(jsonString);
    } catch (e) {
      print('GeoJSON 다운로드 오류: $e');
      rethrow;
    }
  }

  /// 지도 이미지 URL
  String getOreumMapUrl(String oreumCode) {
    return _supabase.storage
        .from(bucketName)
        .getPublicUrl('$oreumCode/map.png');
  }

  // ===================================
  // 3. 등산로 정보 파싱
  // ===================================

  /// 등산로 경로 좌표 추출
  List<Map<String, double>> getTrailPath(Map<String, dynamic> geoJson) {
    final features = geoJson['features'] as List?;
    if (features == null) return [];

    for (var feature in features) {
      if (feature['geometry']['type'] == 'LineString') {
        final coords = feature['geometry']['coordinates'] as List;
        return coords.map<Map<String, double>>((coord) => {
          'lat': (coord[1] as num).toDouble(),
          'lng': (coord[0] as num).toDouble(),
        }).toList();
      }
    }

    return [];
  }

  /// 주요 지점(Waypoints) 추출
  List<Map<String, dynamic>> getWaypoints(Map<String, dynamic> geoJson) {
    final features = geoJson['features'] as List?;
    if (features == null) return [];

    final waypoints = <Map<String, dynamic>>[];

    for (var feature in features) {
      if (feature['geometry']['type'] == 'Point') {
        final coords = feature['geometry']['coordinates'];
        final props = feature['properties'];

        waypoints.add({
          'lat': (coords[1] as num).toDouble(),
          'lng': (coords[0] as num).toDouble(),
          'type': props['MANAGE_SP2'] ?? '기타',
          'name': props['DETAIL_SPO'] ?? '',
          'description': props['ETC_MATTER'] ?? '',
        });
      }
    }

    return waypoints;
  }

  /// 입구 지점들만 필터링
  List<Map<String, dynamic>> getEntrances(Map<String, dynamic> geoJson) {
    final waypoints = getWaypoints(geoJson);
    return waypoints.where((wp) {
      final type = wp['type'] as String;
      return type.contains('시종점') || type.contains('입구');
    }).toList();
  }

  /// 정상 지점 찾기
  Map<String, dynamic>? getSummit(Map<String, dynamic> geoJson) {
    final waypoints = getWaypoints(geoJson);
    try {
      return waypoints.firstWhere((wp) {
        final type = wp['type'] as String;
        return type.contains('정상');
      });
    } catch (e) {
      return null;
    }
  }

  // ===================================
  // 4. 네비게이션 헬퍼
  // ===================================

  /// 현재 위치에서 가장 가까운 입구 찾기
  Map<String, dynamic>? findNearestEntrance(
    double userLat,
    double userLng,
    Map<String, dynamic> geoJson,
  ) {
    final entrances = getEntrances(geoJson);

    if (entrances.isEmpty) {
      return null;
    }

    double minDistance = double.infinity;
    Map<String, dynamic>? nearest;

    for (var entrance in entrances) {
      final distance = calculateDistance(
        userLat,
        userLng,
        entrance['lat'],
        entrance['lng'],
      );

      if (distance < minDistance) {
        minDistance = distance;
        nearest = entrance;
        nearest['distance'] = distance;
      }
    }

    return nearest;
  }

  /// 두 좌표 사이의 거리 계산 (Haversine formula, km)
  double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371; // 지구 반경 (km)
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);

    final a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
      math.sin(dLng / 2) * math.sin(dLng / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  double _toRadians(double degrees) {
    return degrees * math.pi / 180;
  }
}
