import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/hiking_record.dart';
import 'dart:convert';

class HikingRecordService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String recordsTableName = 'hiking_records';
  static const String achievementsTableName = 'user_achievements';
  static const String photosBucketName = 'hiking-photos';

  // ===================================
  // 1. 기록 저장 및 로드
  // ===================================

  /// 등산 기록 시작
  Future<String> startHikingRecord(String oreumCode, String oreumName) async {
    try {
      final userId = _supabase.auth.currentUser?.id ?? 'anonymous';

      final record = HikingRecord(
        oreumCode: oreumCode,
        oreumName: oreumName,
        startTime: DateTime.now(),
        completed: false,
      );

      final response = await _supabase
          .from(recordsTableName)
          .insert({
            'user_id': userId,
            ...record.toJson(),
          })
          .select()
          .single();

      return response['id'].toString();
    } catch (e) {
      print('등산 기록 시작 오류: $e');
      // 오프라인 모드: 로컬 저장
      return await _saveRecordLocally(HikingRecord(
        oreumCode: oreumCode,
        oreumName: oreumName,
        startTime: DateTime.now(),
      ));
    }
  }

  /// 등산 기록 업데이트
  Future<void> updateHikingRecord(String recordId, HikingRecord record) async {
    try {
      await _supabase
          .from(recordsTableName)
          .update(record.toJson())
          .eq('id', recordId);
    } catch (e) {
      print('등산 기록 업데이트 오류: $e');
      await _updateRecordLocally(recordId, record);
    }
  }

  /// 등산 기록 완료
  Future<void> completeHikingRecord(String recordId, HikingRecord record) async {
    final completedRecord = record.copyWith(
      endTime: DateTime.now(),
      completed: true,
    );

    await updateHikingRecord(recordId, completedRecord);
    await _checkAndUnlockAchievements();
  }

  /// 모든 등산 기록 가져오기
  Future<List<HikingRecord>> getAllRecords() async {
    try {
      final userId = _supabase.auth.currentUser?.id ?? 'anonymous';
      final response = await _supabase
          .from(recordsTableName)
          .select()
          .eq('user_id', userId)
          .order('start_time', ascending: false);

      return (response as List)
          .map((json) => HikingRecord.fromJson(json))
          .toList();
    } catch (e) {
      print('기록 가져오기 오류: $e');
      return await _getRecordsLocally();
    }
  }

  /// 완료된 등산 기록만 가져오기
  Future<List<HikingRecord>> getCompletedRecords() async {
    try {
      final userId = _supabase.auth.currentUser?.id ?? 'anonymous';
      final response = await _supabase
          .from(recordsTableName)
          .select()
          .eq('user_id', userId)
          .eq('completed', true)
          .order('start_time', ascending: false);

      return (response as List)
          .map((json) => HikingRecord.fromJson(json))
          .toList();
    } catch (e) {
      print('완료된 기록 가져오기 오류: $e');
      final allRecords = await _getRecordsLocally();
      return allRecords.where((r) => r.completed).toList();
    }
  }

  // ===================================
  // 2. 사진 업로드
  // ===================================

  /// 사진 업로드
  Future<String?> uploadPhoto(String recordId, File photoFile) async {
    try {
      final fileName = '${recordId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = '$recordId/$fileName';

      await _supabase.storage
          .from(photosBucketName)
          .upload(path, photoFile);

      return _supabase.storage
          .from(photosBucketName)
          .getPublicUrl(path);
    } catch (e) {
      print('사진 업로드 오류: $e');
      return null;
    }
  }

  /// 여러 사진 업로드
  Future<List<String>> uploadPhotos(String recordId, List<File> photoFiles) async {
    final urls = <String>[];
    for (var file in photoFiles) {
      final url = await uploadPhoto(recordId, file);
      if (url != null) {
        urls.add(url);
      }
    }
    return urls;
  }

  // ===================================
  // 3. 통계
  // ===================================

  /// 등산 통계 가져오기
  Future<HikingStatistics> getStatistics() async {
    try {
      final records = await getCompletedRecords();

      final totalHikes = records.length;
      final completedHikes = records.where((r) => r.completed).length;
      final totalDistance = records.fold<double>(
        0,
        (sum, r) => sum + r.totalDistance,
      );
      final totalTime = records.fold<int>(
        0,
        (sum, r) => sum + r.totalTime,
      );
      final uniqueOreums = records.map((r) => r.oreumCode).toSet().length;
      final maxAltitude = records.isEmpty
          ? 0.0
          : records.map((r) => r.maxAltitude).reduce((a, b) => a > b ? a : b);

      final achievements = await getUserAchievements();

      return HikingStatistics(
        totalHikes: totalHikes,
        completedHikes: completedHikes,
        totalDistance: totalDistance,
        totalTime: totalTime,
        uniqueOreums: uniqueOreums,
        maxAltitude: maxAltitude,
        achievements: achievements,
      );
    } catch (e) {
      print('통계 가져오기 오류: $e');
      return HikingStatistics(
        totalHikes: 0,
        completedHikes: 0,
        totalDistance: 0,
        totalTime: 0,
        uniqueOreums: 0,
        maxAltitude: 0,
        achievements: [],
      );
    }
  }

  // ===================================
  // 4. 업적
  // ===================================

  /// 사용자 업적 가져오기
  Future<List<Achievement>> getUserAchievements() async {
    try {
      final userId = _supabase.auth.currentUser?.id ?? 'anonymous';
      final response = await _supabase
          .from(achievementsTableName)
          .select()
          .eq('user_id', userId);

      return (response as List)
          .map((json) => Achievement.fromJson(json))
          .toList();
    } catch (e) {
      print('업적 가져오기 오류: $e');
      return _getDefaultAchievements();
    }
  }

  /// 업적 잠금 해제 확인
  Future<List<Achievement>> _checkAndUnlockAchievements() async {
    try {
      final stats = await getStatistics();
      final achievements = _getDefaultAchievements();
      final unlockedAchievements = <Achievement>[];

      for (var achievement in achievements) {
        if (achievement.isUnlocked) continue;

        bool shouldUnlock = false;

        switch (achievement.category) {
          case 'count':
            shouldUnlock = stats.totalHikes >= achievement.requiredCount;
            break;
          case 'distance':
            shouldUnlock = stats.totalDistance >= achievement.requiredCount;
            break;
          case 'altitude':
            shouldUnlock = stats.maxAltitude >= achievement.requiredCount;
            break;
          case 'unique':
            shouldUnlock = stats.uniqueOreums >= achievement.requiredCount;
            break;
        }

        if (shouldUnlock) {
          final unlockedAchievement = achievement.copyWith(
            unlockedAt: DateTime.now(),
          );
          await _unlockAchievement(unlockedAchievement);
          unlockedAchievements.add(unlockedAchievement);
        }
      }

      return unlockedAchievements;
    } catch (e) {
      print('업적 확인 오류: $e');
      return [];
    }
  }

  Future<void> _unlockAchievement(Achievement achievement) async {
    try {
      final userId = _supabase.auth.currentUser?.id ?? 'anonymous';
      await _supabase.from(achievementsTableName).upsert({
        'user_id': userId,
        ...achievement.toJson(),
      });
    } catch (e) {
      print('업적 잠금 해제 오류: $e');
    }
  }

  List<Achievement> _getDefaultAchievements() {
    return [
      Achievement(
        id: 'first_hike',
        title: '첫 등산',
        description: '첫 오름 등반 완료',
        iconName: 'hiking',
        requiredCount: 1,
        category: 'count',
      ),
      Achievement(
        id: 'early_bird',
        title: '초보 등산가',
        description: '5개 오름 등반 완료',
        iconName: 'terrain',
        requiredCount: 5,
        category: 'count',
      ),
      Achievement(
        id: 'experienced',
        title: '숙련된 등산가',
        description: '10개 오름 등반 완료',
        iconName: 'star',
        requiredCount: 10,
        category: 'count',
      ),
      Achievement(
        id: 'expert',
        title: '전문 등산가',
        description: '30개 오름 등반 완료',
        iconName: 'military_tech',
        requiredCount: 30,
        category: 'count',
      ),
      Achievement(
        id: 'master',
        title: '오름 마스터',
        description: '50개 오름 등반 완료',
        iconName: 'emoji_events',
        requiredCount: 50,
        category: 'count',
      ),
      Achievement(
        id: 'distance_10km',
        title: '10km 돌파',
        description: '누적 등산 거리 10km 달성',
        iconName: 'directions_walk',
        requiredCount: 10,
        category: 'distance',
      ),
      Achievement(
        id: 'distance_50km',
        title: '50km 돌파',
        description: '누적 등산 거리 50km 달성',
        iconName: 'directions_run',
        requiredCount: 50,
        category: 'distance',
      ),
      Achievement(
        id: 'distance_100km',
        title: '100km 돌파',
        description: '누적 등산 거리 100km 달성',
        iconName: 'rocket_launch',
        requiredCount: 100,
        category: 'distance',
      ),
      Achievement(
        id: 'explorer',
        title: '탐험가',
        description: '10개의 서로 다른 오름 등반',
        iconName: 'explore',
        requiredCount: 10,
        category: 'unique',
      ),
      Achievement(
        id: 'collector',
        title: '수집가',
        description: '30개의 서로 다른 오름 등반',
        iconName: 'collections',
        requiredCount: 30,
        category: 'unique',
      ),
    ];
  }

  // ===================================
  // 5. 로컬 저장 (오프라인)
  // ===================================

  Future<String> _saveRecordLocally(HikingRecord record) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final records = await _getRecordsLocally();

      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final recordWithId = record.copyWith(id: id);

      records.add(recordWithId);

      final jsonList = records.map((r) => r.toJson()).toList();
      await prefs.setString('hiking_records', jsonEncode(jsonList));

      return id;
    } catch (e) {
      print('로컬 저장 오류: $e');
      return '';
    }
  }

  Future<void> _updateRecordLocally(String recordId, HikingRecord record) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final records = await _getRecordsLocally();

      final index = records.indexWhere((r) => r.id == recordId);
      if (index != -1) {
        records[index] = record;
        final jsonList = records.map((r) => r.toJson()).toList();
        await prefs.setString('hiking_records', jsonEncode(jsonList));
      }
    } catch (e) {
      print('로컬 업데이트 오류: $e');
    }
  }

  Future<List<HikingRecord>> _getRecordsLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('hiking_records');

      if (jsonString == null) return [];

      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => HikingRecord.fromJson(json)).toList();
    } catch (e) {
      print('로컬 로드 오류: $e');
      return [];
    }
  }

  // ===================================
  // 6. 오프라인 동기화
  // ===================================

  Future<void> syncLocalRecordsToCloud() async {
    try {
      final localRecords = await _getRecordsLocally();
      final userId = _supabase.auth.currentUser?.id;

      if (userId == null) return;

      for (var record in localRecords) {
        await _supabase.from(recordsTableName).upsert({
          'user_id': userId,
          ...record.toJson(),
        });
      }

      // 동기화 후 로컬 데이터 삭제
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('hiking_records');
    } catch (e) {
      print('동기화 오류: $e');
    }
  }
}

extension AchievementCopyWith on Achievement {
  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? iconName,
    int? requiredCount,
    String? category,
    DateTime? unlockedAt,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      requiredCount: requiredCount ?? this.requiredCount,
      category: category ?? this.category,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }
}
