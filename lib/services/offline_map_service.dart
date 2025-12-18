import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class OfflineMapService {
  static final OfflineMapService _instance = OfflineMapService._internal();
  static const String _tileCacheDir = 'map_tiles';
  static const String _mapDataFile = 'offline_map_data.json';
  
  // 카카오맵 타일 서버 URL 목록
  static const List<String> _mapTileUrls = [
    'https://t1.daumcdn.net/mapjsapi/images/2.0/maptile',
    'https://t1.daumcdn.net/mapjsapi/images/map',
    'https://map1.daumcdn.net/map_2d_hd/2111ydg',
  ];

  factory OfflineMapService() => _instance;
  
  OfflineMapService._internal();

  // 로컬 저장소 경로 가져오기
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  // 타일 캐시 디렉토리 경로 가져오기
  Future<String> get _tileCachePath async {
    final localPath = await _localPath;
    final tilePath = path.join(localPath, _tileCacheDir);
    final dir = Directory(tilePath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return tilePath;
  }

  // 오프라인 맵 데이터 파일 경로 가져오기
  Future<String> get _offlineMapDataPath async {
    final localPath = await _localPath;
    return path.join(localPath, _mapDataFile);
  }

  // 특정 영역의 맵 타일 미리 다운로드
  Future<void> preloadMapTiles({
    required double lat,
    required double lng,
    required int zoomLevel,
    int radius = 2, // 반경 (타일 단위)
  }) async {
    if (!await _isOnline()) return;
    
    final tilePath = await _tileCachePath;
    final tiles = _calculateTiles(lat, lng, zoomLevel, radius);
    
    await Future.wait(
      tiles.map((tile) => _downloadAndCacheTile(tile, zoomLevel, tilePath)),
      eagerError: false,
    );
    
    // 오프라인 맵 데이터 저장
    await _saveOfflineMapData(lat, lng, zoomLevel, radius);
  }

  // 위도/경도를 타일 좌표로 변환
  List<Point<int>> _calculateTiles(double lat, double lng, int zoom, int radius) {
    final n = math.pow(2.0, zoom).toDouble();
    final latRad = lat * math.pi / 180.0;
    final xTile = ((lng + 180.0) / 360.0 * n) % n;
    final yTile = (1.0 - math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) / math.pi) / 2.0 * n;
    
    final tiles = <Point<int>>[];
    final centerX = xTile.floor();
    final centerY = yTile.floor();
    
    // 주변 타일 계산
    for (int dx = -radius; dx <= radius; dx++) {
      for (int dy = -radius; dy <= radius; dy++) {
        final x = centerX + dx;
        final y = centerY + dy;
        if (x >= 0 && y >= 0 && x < n && y < n) {
          tiles.add(Point(x, y));
        }
      }
    }
    
    return tiles;
  }

  // 타일 다운로드 및 캐시
  Future<void> _downloadAndCacheTile(Point<int> tile, int zoom, String cachePath) async {
    final tileKey = '${tile.x}_${tile.y}_$zoom.png';
    final file = File(path.join(cachePath, tileKey));
    
    // 이미 캐시된 파일이 있으면 건너뜀
    if (await file.exists()) return;
    
    // 각 URL 시도
    for (final baseUrl in _mapTileUrls) {
      try {
        final url = '$baseUrl?x=${tile.x}&y=${tile.y}&z=$zoom';
        final response = await http.get(Uri.parse(url));
        
        if (response.statusCode == 200) {
          await file.writeAsBytes(response.bodyBytes);
          debugPrint('Cached tile: $tileKey');
          break;
        }
      } catch (e) {
        debugPrint('Failed to download tile: $e');
      }
    }
  }

  // 오프라인 맵 데이터 저장
  Future<void> _saveOfflineMapData(
    double lat, 
    double lng, 
    int zoomLevel, 
    int radius
  ) async {
    final file = File(await _offlineMapDataPath);
    final data = {
      'lat': lat,
      'lng': lng,
      'zoomLevel': zoomLevel,
      'radius': radius,
      'cachedAt': DateTime.now().toIso8601String(),
    };
    
    await file.writeAsString(jsonEncode(data));
  }

  // 오프라인 맵 데이터 로드
  Future<Map<String, dynamic>?> loadOfflineMapData() async {
    try {
      final file = File(await _offlineMapDataPath);
      if (await file.exists()) {
        final data = await file.readAsString();
        return jsonDecode(data) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Failed to load offline map data: $e');
    }
    return null;
  }

  // 오프라인 맵 HTML 생성
  String getOfflineMapHtml() {
    return '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width,initial-scale=1.0">
        <title>오프라인 지도</title>
        <style>
          #map { width: 100%; height: 100vh; }
          .offline-notice {
            position: absolute;
            top: 10px;
            left: 10px;
            background: rgba(255, 255, 255, 0.9);
            padding: 5px 10px;
            border-radius: 4px;
            font-size: 12px;
            z-index: 1000;
          }
        </style>
      </head>
      <body>
        <div id="map"></div>
        <div class="offline-notice">오프라인 모드</div>
        <script>
          // 오프라인 지도 초기화 로직
          function initOfflineMap() {
            const mapContainer = document.getElementById('map');
            const mapOptions = {
              center: new kakao.maps.LatLng(33.450701, 126.570667),
              level: 3
            };
            
            const map = new kakao.maps.Map(mapContainer, mapOptions);
            
            // 오프라인에서 사용 가능한 기능들
            window.updateCurrentLocation = function(lat, lng) {
              const position = new kakao.maps.LatLng(lat, lng);
              if (!window.userMarker) {
                const imageSrc = 'https://t1.daumcdn.net/localimg/localimages/07/mapapidoc/markerStar.png';
                const imageSize = new kakao.maps.Size(24, 35);
                const markerImage = new kakao.maps.MarkerImage(imageSrc, imageSize);
                
                window.userMarker = new kakao.maps.Marker({
                  position: position,
                  image: markerImage
                });
                window.userMarker.setMap(map);
              } else {
                window.userMarker.setPosition(position);
              }
              
              if (window.isNavigating) {
                map.panTo(position);
              }
            };
            
            // 오프라인에서도 사용 가능한 기본 기능들...
          }
          
          // 지도 API 로드 완료 후 초기화
          window.onload = function() {
            if (typeof kakao !== 'undefined' && kakao.maps) {
              initOfflineMap();
            } else {
              // 오프라인에서도 지도가 표시되도록 폴백
              document.getElementById('map').innerHTML = 
                '<div style="padding:20px;text-align:center;">' +
                '<h3>오프라인 지도</h3>' +
                '<p>인터넷에 연결하면 더 자세한 지도를 볼 수 있습니다.</p>' +
                '</div>';
            }
          };
        </script>
      </body>
      </html>
    ''';
  }

  // 인터넷 연결 상태 확인
  Future<bool> _isOnline() async {
    try {
      final result = await InternetAddress.lookup('www.google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  // 캐시된 타일 경로 가져오기
  Future<String?> getCachedTilePath(int x, int y, int z) async {
    final tilePath = await _tileCachePath;
    final tileFile = File(path.join(tilePath, '${x}_${y}_$z.png'));
    return await tileFile.exists() ? tileFile.path : null;
  }

  // 캐시된 모든 타일 삭제
  Future<void> clearCache() async {
    try {
      final tilePath = await _tileCachePath;
      final dir = Directory(tilePath);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
      
      final dataFile = File(await _offlineMapDataPath);
      if (await dataFile.exists()) {
        await dataFile.delete();
      }
    } catch (e) {
      debugPrint('Failed to clear map cache: $e');
    }
  }

  // 캐시 크기 가져오기 (바이트 단위)
  Future<int> getCacheSize() async {
    try {
      final tilePath = await _tileCachePath;
      final dir = Directory(tilePath);
      
      if (!await dir.exists()) return 0;
      
      int totalSize = 0;
      await for (var file in dir.list(recursive: true)) {
        if (file is File) {
          totalSize += await file.length();
        }
      }
      
      return totalSize;
    } catch (e) {
      debugPrint('Failed to calculate cache size: $e');
      return 0;
    }
  }
}

// 2D 점을 나타내는 간단한 클래스
class Point<T extends num> {
  final T x;
  final T y;
  
  Point(this.x, this.y);
  
  @override
  String toString() => 'Point($x, $y)';
}
