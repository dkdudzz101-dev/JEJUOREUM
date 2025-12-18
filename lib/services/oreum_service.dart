import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/oreum_model.dart';
import '../models/trail_model.dart';
import '../models/point_model.dart';
import 'dart:math' as math;

class OreumService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// 모든 오름 가져오기
  Future<List<Oreum>> getAllOreums() async {
    try {
      final response = await _supabase
          .from('oreums')
          .select()
          .order('oreum_name');

      return (response as List)
          .map((json) => Oreum.fromJson(json))
          .toList();
    } catch (e) {
      print('오름 목록 가져오기 오류: $e');
      return [];
    }
  }

  /// 난이도별 오름 가져오기
  Future<List<Oreum>> getOreumsByDifficulty(String difficulty) async {
    try {
      final response = await _supabase
          .from('oreums')
          .select()
          .eq('difficulty', difficulty)
          .order('oreum_name');

      return (response as List)
          .map((json) => Oreum.fromJson(json))
          .toList();
    } catch (e) {
      print('난이도별 오름 가져오기 오류: $e');
      return [];
    }
  }

  /// 오름 검색
  Future<List<Oreum>> searchOreums(String query) async {
    try {
      final response = await _supabase
          .from('oreums')
          .select()
          .ilike('oreum_name', '%$query%')
          .order('oreum_name');

      return (response as List)
          .map((json) => Oreum.fromJson(json))
          .toList();
    } catch (e) {
      print('오름 검색 오류: $e');
      return [];
    }
  }

  /// 특정 오름의 등산로 가져오기
  Future<List<Trail>> getTrailsByOreumId(int oreumId) async {
    try {
      final response = await _supabase
          .from('trails')
          .select()
          .eq('oreum_id', oreumId);

      return (response as List)
          .map((json) => Trail.fromJson(json))
          .toList();
    } catch (e) {
      print('등산로 가져오기 오류: $e');
      return [];
    }
  }

  /// 특정 오름의 포인트 가져오기
  Future<List<TrailPoint>> getPointsByOreumId(int oreumId) async {
    try {
      final response = await _supabase
          .from('points')
          .select()
          .eq('oreum_id', oreumId);

      return (response as List)
          .map((json) => TrailPoint.fromJson(json))
          .toList();
    } catch (e) {
      print('포인트 가져오기 오류: $e');
      return [];
    }
  }

  /// 특정 오름 상세 정보 가져오기 (오름 + 등산로 + 포인트)
  Future<Map<String, dynamic>> getOreumDetail(int oreumId) async {
    try {
      // 병렬로 데이터 가져오기
      final results = await Future.wait([
        _supabase.from('oreums').select().eq('id', oreumId).single(),
        _supabase.from('trails').select().eq('oreum_id', oreumId),
        _supabase.from('points').select().eq('oreum_id', oreumId),
      ]);

      return {
        'oreum': Oreum.fromJson(results[0] as Map<String, dynamic>),
        'trails': (results[1] as List).map((json) => Trail.fromJson(json)).toList(),
        'points': (results[2] as List).map((json) => TrailPoint.fromJson(json)).toList(),
      };
    } catch (e) {
      print('오름 상세 정보 가져오기 오류: $e');
      rethrow;
    }
  }

  /// 근처 오름 찾기 (위도, 경도, 반경km)
  Future<List<Oreum>> getNearbyOreums(double lat, double lng, double radiusKm) async {
    try {
      // PostGIS ST_DWithin 함수 사용 (거리 기반 필터링)
      // 간단한 방법: 모든 오름 가져와서 클라이언트에서 필터링
      final allOreums = await getAllOreums();

      return allOreums.where((oreum) {
        final distance = _calculateDistance(
          lat, lng,
          oreum.summitLat, oreum.summitLng
        );
        return distance <= radiusKm;
      }).toList();
    } catch (e) {
      print('근처 오름 찾기 오류: $e');
      return [];
    }
  }

  /// 두 지점 간 거리 계산 (Haversine formula)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * (math.pi / 180);
  }
}
