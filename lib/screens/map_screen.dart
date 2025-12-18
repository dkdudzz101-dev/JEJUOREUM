import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import '../theme/app_theme.dart';
import 'oreum_detail_screen.dart';
import 'navigation_screen.dart';
import '../services/storage_oreum_service.dart';
import '../services/navigation_provider.dart';
import '../models/oreum_model.dart';

class MapScreen extends StatefulWidget {
  final Map<String, dynamic>? targetOreumData;

  const MapScreen({super.key, this.targetOreumData});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  WebViewController? _webViewController;
  int? _selectedOreumIndex;
  Position? _currentPosition;
  bool _isMapReady = false;
  double _zoom = 9.0;
  final PanelController _panelController = PanelController();
  bool _showAllTrails = false; // 모든 등산로 표시 토글

  // 네비게이션 목적지 (카드 없이 경로만 표시할 때 사용)
  Map<String, dynamic>? _navigationDestination;

  // 필터 상태
  String? _selectedDifficulty;
  int? _selectedDuration;
  String _sortBy = 'name'; // 'name', 'distance', 'difficulty'

  // 난이도 옵션
  final List<Map<String, dynamic>> _difficultyOptions = [
    {'label': '전체', 'value': null},
    {'label': '쉬움', 'value': '쉬움'},
    {'label': '보통', 'value': '보통'},
    {'label': '어려움', 'value': '어려움'},
  ];

  // 소요 시간 옵션
  final List<Map<String, dynamic>> _durationOptions = [
    {'label': '전체', 'value': null},
    {'label': '30분 이내', 'value': 30},
    {'label': '30분~1시간', 'value': 60},
    {'label': '1시간~2시간', 'value': 120},
    {'label': '2시간 이상', 'value': 121},
  ];
  
  // 필터링된 오름 목록
  List<Map<String, dynamic>> get _filteredOreums {
    var filtered = _oreums.where((oreum) {
      // 난이도 필터
      if (_selectedDifficulty != null &&
          oreum['difficulty'] != _selectedDifficulty) {
        return false;
      }

      // 소요 시간 필터
      if (_selectedDuration != null) {
        final duration = oreum['duration'] as int? ?? 0;

        if (_selectedDuration == 30 && duration > 30) return false;
        if (_selectedDuration == 60 && (duration <= 30 || duration > 60)) return false;
        if (_selectedDuration == 120 && (duration <= 60 || duration > 120)) return false;
        if (_selectedDuration == 121 && duration <= 120) return false;
      }

      return true;
    }).toList();

    // 정렬
    if (_sortBy == 'distance' && _currentPosition != null) {
      filtered.sort((a, b) {
        final distA = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          a['lat'] ?? 0.0,
          a['lng'] ?? 0.0,
        );
        final distB = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          b['lat'] ?? 0.0,
          b['lng'] ?? 0.0,
        );
        return distA.compareTo(distB);
      });
    } else if (_sortBy == 'difficulty') {
      final difficultyOrder = {'쉬움': 1, '보통': 2, '어려움': 3};
      filtered.sort((a, b) {
        final orderA = difficultyOrder[a['difficulty']] ?? 0;
        final orderB = difficultyOrder[b['difficulty']] ?? 0;
        return orderA.compareTo(orderB);
      });
    } else {
      // 기본 정렬 (이름순)
      filtered.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
    }

    return filtered;
  }



  static const String kKakaoJsKey = '9fb90cfd5075a5a193d3545bb0ed61e1'; // JavaScript 키

  final List<Map<String, dynamic>> _oreums = [];
  final StorageOreumService _oreumService = StorageOreumService();

  // 오름 이름에서 숫자와 점 제거 (예: "101.가마오름" → "가마오름")
  String _cleanOreumName(String name) {
    return name.replaceAll(RegExp(r'^\d+\.'), '').trim();
  }

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    // GPS는 백그라운드에서 받기 (기다리지 않음)
    _getCurrentLocation();

    // 오름 목록 먼저 불러오기
    await _loadOreums();

    // 타겟 오름이 있으면 선택
    if (widget.targetOreumData != null) {
      _selectTargetOreum();
    }

    // 지도 초기화
    _initWebView();
  }

  void _selectTargetOreum() {
    if (widget.targetOreumData == null) return;

    final targetName = widget.targetOreumData!['name'] as String?;
    if (targetName == null) return;

    final index = _oreums.indexWhere((oreum) => oreum['name'] == targetName);
    if (index != -1) {
      final oreum = _oreums[index];

      // 카드 없이 경로만 표시하기 위해 navigationDestination 설정
      setState(() {
        _navigationDestination = oreum;
        _selectedOreumIndex = null; // 카드 표시 안함
      });

      // 패널 닫기
      _panelController.close();

      // 지도가 준비되면 해당 위치로 이동하고 경로 표시
      Future.delayed(const Duration(milliseconds: 1000), () {
        debugPrint('=== targetOreumData 확인 ===');
        debugPrint('targetOreumData: ${widget.targetOreumData}');
        debugPrint('oreum entrance: ${oreum['entrance_lat']}, ${oreum['entrance_lng']}');
        debugPrint('oreum summit: ${oreum['summit_lat']}, ${oreum['summit_lng']}');

        // targetOreumData에서 좌표 추출
        double? destLat = widget.targetOreumData!['lat'];
        double? destLng = widget.targetOreumData!['lng'];

        // null이거나 0.0이면 oreum의 입구 좌표 사용
        if (destLat == null || destLat == 0.0) {
          destLat = oreum['entrance_lat'] as double? ?? oreum['summit_lat'] as double?;
        }
        if (destLng == null || destLng == 0.0) {
          destLng = oreum['entrance_lng'] as double? ?? oreum['summit_lng'] as double?;
        }

        debugPrint('최종 목적지: $destLat, $destLng');

        if (destLat != null && destLng != null && destLat != 0.0 && destLng != 0.0 && _webViewController != null) {
          _showRouteToDestination(destLat, destLng);
        }
      });
    }
  }

  void _focusOnLocation(double lat, double lng) {
    _webViewController?.runJavaScript('''
      map.setCenter(new kakao.maps.LatLng($lat, $lng));
      map.setLevel(3);
    ''');
  }

  Future<void> _showRouteToDestination(double destLat, double destLng) async {
    debugPrint('=== 경로 표시 시작 ===');
    debugPrint('목적지: $destLat, $destLng');
    debugPrint('현재 위치: $_currentPosition');

    if (_currentPosition == null) {
      debugPrint('현재 위치 없음 - 목적지만 표시');
      _focusOnLocation(destLat, destLng);
      return;
    }

    final startLat = _currentPosition!.latitude;
    final startLng = _currentPosition!.longitude;

    debugPrint('출발: $startLat, $startLng');
    debugPrint('도착: $destLat, $destLng');

    // 일단 직선 경로로 바로 표시 (빠른 피드백)
    _drawStraightRoute(startLat, startLng, destLat, destLng);

    // 카카오 Mobility API로 실제 경로 가져오기
    try {
      final url = 'https://apis-navi.kakaomobility.com/v1/directions?origin=$startLng,$startLat&destination=$destLng,$destLat&priority=RECOMMEND';
      debugPrint('API 호출: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'KakaoAK 9fb90cfd5075a5a193d3545bb0ed61e1',
          'KA': 'os=android origin=jeju_oreum',
        },
      );

      debugPrint('API 응답 코드: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final routes = data['routes'] as List?;

        if (routes != null && routes.isNotEmpty) {
          debugPrint('경로 찾음 - 실제 도로 경로로 업데이트');
          final sections = routes[0]['sections'] as List;
          final roads = sections[0]['roads'] as List;

          // 경로 좌표들 추출
          List<List<double>> pathCoords = [];
          for (var road in roads) {
            final vertexes = road['vertexes'] as List;
            for (int i = 0; i < vertexes.length; i += 2) {
              pathCoords.add([vertexes[i + 1], vertexes[i]]); // [lat, lng]
            }
          }

          debugPrint('경로 좌표 개수: ${pathCoords.length}');
          // 지도에 경로 그리기
          _drawRouteOnMap(pathCoords, destLat, destLng);
          return;
        }
      } else {
        debugPrint('API 실패: ${response.body}');
      }
    } catch (e) {
      debugPrint('경로 가져오기 실패: $e');
    }
  }

  void _drawRouteOnMap(List<List<double>> pathCoords, double destLat, double destLng) {
    final pathString = pathCoords.map((coord) => 'new kakao.maps.LatLng(${coord[0]}, ${coord[1]})').join(',');

    _webViewController?.runJavaScript('''
      // 기존 경로 제거
      if (window.routeLine) {
        window.routeLine.setMap(null);
      }
      if (window.destMarker) {
        window.destMarker.setMap(null);
      }

      // 경로 그리기
      var linePath = [$pathString];
      window.routeLine = new kakao.maps.Polyline({
        path: linePath,
        strokeWeight: 5,
        strokeColor: '#4A90E2',
        strokeOpacity: 0.8,
        strokeStyle: 'solid'
      });
      window.routeLine.setMap(map);

      // 목적지 마커
      window.destMarker = new kakao.maps.Marker({
        position: new kakao.maps.LatLng($destLat, $destLng),
        map: map
      });

      // 지도 범위 조정
      var bounds = new kakao.maps.LatLngBounds();
      for (var i = 0; i < linePath.length; i++) {
        bounds.extend(linePath[i]);
      }
      map.setBounds(bounds);
    ''');
  }

  void _drawStraightRoute(double startLat, double startLng, double destLat, double destLng) {
    _webViewController?.runJavaScript('''
      // 기존 경로 제거
      if (window.routeLine) {
        window.routeLine.setMap(null);
      }
      if (window.destMarker) {
        window.destMarker.setMap(null);
      }

      // 직선 경로 그리기
      var linePath = [
        new kakao.maps.LatLng($startLat, $startLng),
        new kakao.maps.LatLng($destLat, $destLng)
      ];
      window.routeLine = new kakao.maps.Polyline({
        path: linePath,
        strokeWeight: 5,
        strokeColor: '#FF6B6B',
        strokeOpacity: 0.8,
        strokeStyle: 'dashed'
      });
      window.routeLine.setMap(map);

      // 목적지 마커
      window.destMarker = new kakao.maps.Marker({
        position: new kakao.maps.LatLng($destLat, $destLng),
        map: map
      });

      // 지도 범위 조정
      var bounds = new kakao.maps.LatLngBounds();
      bounds.extend(linePath[0]);
      bounds.extend(linePath[1]);
      map.setBounds(bounds);
    ''');
  }


  Future<void> _launchKakaoNavigation(double lat, double lng, String name) async {
    final kakaoMapUrl = 'kakaomap://route?ep=$lat,$lng&by=FOOT';
    final webUrl = 'https://map.kakao.com/link/to/$name,$lat,$lng';

    try {
      final kakaoUri = Uri.parse(kakaoMapUrl);
      if (await canLaunchUrl(kakaoUri)) {
        await launchUrl(kakaoUri, mode: LaunchMode.externalApplication);
      } else {
        final webUri = Uri.parse(webUrl);
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('카카오맵 열기 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('카카오맵을 열 수 없습니다')),
        );
      }
    }
  }

  Future<void> _launchGoogleNavigation(double lat, double lng) async {
    final googleMapUrl = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=walking';

    try {
      final uri = Uri.parse(googleMapUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('구글맵 열기 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('구글맵을 열 수 없습니다')),
        );
      }
    }
  }

  Future<void> _loadOreums() async {
    try {
      final oreums = await _oreumService.getAllOreums();
      setState(() {
        _oreums.clear();
        _oreums.addAll(oreums.map((oreum) {
          // ID 필드 확인을 위한 디버그
          if (_oreums.isEmpty) {
            debugPrint('첫 번째 오름 데이터: ${oreum.keys.toList()}');
            debugPrint('첫 번째 오름 ID 값: ${oreum['id']}, oreum_id: ${oreum['oreum_id']}, pk: ${oreum['pk']}');
          }

          // 난이도에 따른 소요 시간 추정 (분 단위)
          // 거리(km)를 기반으로 계산: 쉬움(3km/h), 보통(2.5km/h), 어려움(2km/h)
          final distanceKm = (oreum['distance_km'] as num?)?.toDouble() ?? 2.0;
          int estimatedDuration;

          if (oreum['difficulty'] == '어려움') {
            estimatedDuration = (distanceKm / 2.0 * 60).round(); // 2km/h
          } else if (oreum['difficulty'] == '보통') {
            estimatedDuration = (distanceKm / 2.5 * 60).round(); // 2.5km/h
          } else {
            estimatedDuration = (distanceKm / 3.0 * 60).round(); // 3km/h (쉬움)
          }

          // Oreum 모델 객체 생성 (folder 필드 추가)
          final oreumModel = Oreum.fromJson({
            ...oreum,
            'folder': oreum['oreum_code'],  // folder 필드 매핑
          });

          // oreum_code를 고유 ID로 사용 (id가 null인 경우)
          final uniqueId = oreum['id'] ?? oreum['oreum_code'];

          return {
            'id': uniqueId,  // oreum_code를 ID로 사용
            'name': oreum['oreum_name'] ?? oreum['name'] ?? '이름 없음',
            'folder': oreum['oreum_code'],
            'lat': (oreum['summit_lat'] as num?)?.toDouble() ?? 0.0,
            'lng': (oreum['summit_lng'] as num?)?.toDouble() ?? 0.0,
            'entrance_lat': (oreum['entrance_lat'] as num?)?.toDouble(),
            'entrance_lng': (oreum['entrance_lng'] as num?)?.toDouble(),
            'difficulty': oreum['difficulty'],
            'duration': estimatedDuration,
            'color': oreum['color'],
            'distance': distanceKm,
            'elevation': (oreum['elev_diff_m'] as num?)?.toDouble(),
            'oreum_object': oreumModel,  // Oreum 모델 객체 저장
          };
        }));
      });
      debugPrint('Loaded ${_oreums.length} oreums from Supabase');
    } catch (e) {
      debugPrint('Failed to load oreums: $e');
    }
  }

  void _initWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..enableZoom(false)
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: (JavaScriptMessage message) {
          final data = jsonDecode(message.message);
          if (data['type'] == 'debug') {
            debugPrint('WebView Debug: ${data['message']}');
          } else if (data['type'] == 'markerClick') {
            // 마커 클릭 시 상세 화면으로 바로 이동
            final oreumId = data['oreumId'];
            final index = _oreums.indexWhere((oreum) => oreum['id'] == oreumId);
            if (index != -1) {
              final oreum = _oreums[index];
              final oreumModel = oreum['oreum_object'] as Oreum?;
              final entranceLat = oreum['entrance_lat'] as double?;
              final entranceLng = oreum['entrance_lng'] as double?;

              if (oreumModel != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OreumDetailScreen(
                      oreum: oreumModel,
                      entranceLat: entranceLat,
                      entranceLng: entranceLng,
                    ),
                  ),
                );
              }
            }
          } else if (data['type'] == 'zoomChanged') {
            final newZoom = data['level'].toDouble();
            setState(() {
              _zoom = newZoom;
            });
          } else if (data['type'] == 'mapReady') {
            setState(() {
              _isMapReady = true;
            });
            if (_currentPosition != null) {
              _updateMyLocation();
            }
          }
        },
      )
      ..loadHtmlString(_getKakaoMapHtml(_currentPosition));
  }

  String _getKakaoMapHtml(Position? initialPosition) {
    final initialLat = initialPosition?.latitude ?? 33.4256;
    final initialLng = initialPosition?.longitude ?? 126.7214;
    final initialLevel = initialPosition != null ? 5 : 9;

    final oreumMarkersJson = jsonEncode(_oreums.map((oreum) => {
      'id': oreum['id'],
      'name': oreum['name'],
      'lat': oreum['lat'],
      'lng': oreum['lng'],
      'color': oreum['color'] ?? '#4CAF50',
      'difficulty': oreum['difficulty'] ?? '쉬움',
    }).toList());

    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <style>
        * { margin: 0; padding: 0; }
        html, body { width: 100%; height: 100%; overflow: hidden; }
        #map { width: 100%; height: 100%; }
    </style>
</head>
<body>
    <div id="map"></div>
    <script type="text/javascript" src="https://dapi.kakao.com/v2/maps/sdk.js?appkey=$kKakaoJsKey"></script>
    <script>
        var map;

        window.onload = function() {
            FlutterChannel.postMessage(JSON.stringify({type: 'debug', message: 'Loading map'}));

            var mapContainer = document.getElementById('map');
            var mapOption = {
                center: new kakao.maps.LatLng($initialLat, $initialLng),
                level: $initialLevel
            };

            map = new kakao.maps.Map(mapContainer, mapOption);

            kakao.maps.event.addListener(map, 'zoom_changed', function() {
                var level = map.getLevel();
                var bounds = map.getBounds();
                FlutterChannel.postMessage(JSON.stringify({
                    type: 'zoomChanged',
                    level: level,
                    bounds: {
                        swLat: bounds.getSouthWest().getLat(),
                        swLng: bounds.getSouthWest().getLng(),
                        neLat: bounds.getNorthEast().getLat(),
                        neLng: bounds.getNorthEast().getLng()
                    }
                }));
            });

            var oreums = $oreumMarkersJson;
            var markers = [];

            oreums.forEach(function(oreum, index) {
                var markerPosition = new kakao.maps.LatLng(oreum.lat, oreum.lng);

                // 색상별 커스텀 마커 생성 (클릭 영역을 위한 투명한 외부 영역 추가)
                var markerContent = '<div style="' +
                    'width: 32px; height: 32px;' +
                    'display: flex; align-items: center; justify-content: center;' +
                    'cursor: pointer;' +
                    '">' +
                    '<div style="' +
                    'background-color: ' + oreum.color + ';' +
                    'width: 12px; height: 12px;' +
                    'border: 2px solid white;' +
                    'border-radius: 50%;' +
                    'box-shadow: 0 2px 4px rgba(0,0,0,0.3);' +
                    '"></div>' +
                    '</div>';

                var customOverlay = new kakao.maps.CustomOverlay({
                    position: markerPosition,
                    content: markerContent,
                    clickable: true
                });

                customOverlay.setMap(map);

                // 마커 정보 저장
                markers.push({
                    overlay: customOverlay,
                    oreumId: oreum.id
                });

                // 클릭 이벤트 (외부 div에 추가하여 클릭 영역 확대)
                setTimeout(function() {
                    var markerDiv = customOverlay.a;
                    if (markerDiv) {
                        markerDiv.onclick = function(e) {
                            e.stopPropagation();
                            FlutterChannel.postMessage(JSON.stringify({
                                type: 'markerClick',
                                oreumId: oreum.id
                            }));
                        };
                    }
                }, 100);
            });

            // 전역 변수로 markers 저장
            window.allMarkers = markers;

            FlutterChannel.postMessage(JSON.stringify({type: 'mapReady'}));
        };

        function setMyLocation(lat, lng) {
            if (!map) return;
            var position = new kakao.maps.LatLng(lat, lng);

            if (window.myLocationMarker) {
                window.myLocationMarker.setMap(null);
            }

            var imageSrc = 'data:image/svg+xml;base64,' + btoa('<svg xmlns="http://www.w3.org/2000/svg" width="40" height="40"><circle cx="20" cy="20" r="8" fill="blue" stroke="white" stroke-width="3"/></svg>');
            var imageSize = new kakao.maps.Size(40, 40);
            var markerImage = new kakao.maps.MarkerImage(imageSrc, imageSize);

            window.myLocationMarker = new kakao.maps.Marker({
                position: position,
                image: markerImage
            });
            window.myLocationMarker.setMap(map);
        }

        function moveToLocation(lat, lng, level) {
            if (!map) return;
            var position = new kakao.maps.LatLng(lat, lng);
            map.setCenter(position);
            if (level !== undefined) {
                map.setLevel(level);
            }
        }

        // 등산로 경로 표시 함수
        var trailPolylines = [];

        function displayTrail(pathData, clearPrevious) {
            if (!map || !pathData) return;

            // clearPrevious가 true이면 기존 등산로 제거
            if (clearPrevious === true) {
                trailPolylines.forEach(function(polyline) {
                    polyline.setMap(null);
                });
                trailPolylines = [];
            }

            try {
                // pathData는 [{lat: xx, lng: xx}, ...] 형식
                var path = pathData.map(function(point) {
                    return new kakao.maps.LatLng(point.lat, point.lng);
                });

                // Polyline 생성
                var polyline = new kakao.maps.Polyline({
                    path: path,
                    strokeWeight: 4,
                    strokeColor: '#FF6B6B',
                    strokeOpacity: 0.8,
                    strokeStyle: 'solid'
                });

                polyline.setMap(map);
                trailPolylines.push(polyline);

                // 등산로에 맞게 지도 범위 조정 (clearPrevious가 true일 때만)
                if (clearPrevious === true) {
                    var bounds = new kakao.maps.LatLngBounds();
                    path.forEach(function(point) {
                        bounds.extend(point);
                    });
                    map.setBounds(bounds);
                }

                FlutterChannel.postMessage(JSON.stringify({type: 'debug', message: '등산로 표시 완료'}));
            } catch (e) {
                FlutterChannel.postMessage(JSON.stringify({type: 'debug', message: '등산로 표시 오류: ' + e}));
            }
        }

        function clearAllTrails() {
            trailPolylines.forEach(function(polyline) {
                polyline.setMap(null);
            });
            trailPolylines = [];
        }

        function zoomIn() {
            if (!map) return;
            map.setLevel(map.getLevel() - 1);
        }

        function zoomOut() {
            if (!map) return;
            map.setLevel(map.getLevel() + 1);
        }

        // 필터 적용 함수
        function applyOreumFilter(filteredIndices) {
            if (!window.allMarkers) return;

            window.allMarkers.forEach(function(marker) {
                if (filteredIndices.includes(marker.index)) {
                    marker.overlay.setMap(map);
                } else {
                    marker.overlay.setMap(null);
                }
            });

            FlutterChannel.postMessage(JSON.stringify({
                type: 'debug',
                message: 'Filter applied: ' + filteredIndices.length + ' markers shown'
            }));
        }

        // 전체 마커 표시 함수
        function showAllMarkers() {
            if (!window.allMarkers) return;

            window.allMarkers.forEach(function(marker) {
                marker.overlay.setMap(map);
            });
        }
    </script>
</body>
</html>
''';
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
        });

        if (_isMapReady) {
          _updateMyLocation();
        }
      }
    } catch (e) {
      debugPrint('Location error: $e');
    }
  }

  Future<void> _loadAndDisplayTrails(int index) async {
    try {
      final oreum = _oreums[index];
      final oreumFolder = oreum['folder'];

      if (oreumFolder == null || oreumFolder.isEmpty) {
        debugPrint('오름 폴더 정보 없음');
        return;
      }

      debugPrint('등산로 로드 중: $oreumFolder');

      // Storage에서 GeoJSON 데이터 가져오기
      final geoJson = await _oreumService.getOreumGeoJson(oreumFolder);

      // 등산로 경로 추출
      final trailPath = _oreumService.getTrailPath(geoJson);

      if (trailPath.isEmpty) {
        debugPrint('등산로 데이터 없음');
        return;
      }

      // 등산로의 첫 번째 포인트를 입구로 사용 (GeoJSON에서 추출)
      double? entranceLat;
      double? entranceLng;
      if (trailPath.isNotEmpty) {
        final firstPoint = trailPath[0];
        entranceLat = firstPoint['lat'];
        entranceLng = firstPoint['lng'];
        setState(() {
          _oreums[index]['entrance_lat'] = entranceLat;
          _oreums[index]['entrance_lng'] = entranceLng;
        });
        debugPrint('입구 좌표 설정: $entranceLat, $entranceLng');
      }

      // 상세 정보 화면으로 이동 (등산로는 지도에 표시하지 않음)
      final oreumModel = oreum['oreum_object'] as Oreum?;
      if (oreumModel != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OreumDetailScreen(
              oreum: oreumModel,
              entranceLat: entranceLat ?? oreumModel.summitLat,
              entranceLng: entranceLng ?? oreumModel.summitLng,
            ),
          ),
        );
      }

      debugPrint('상세 정보 화면으로 이동');
    } catch (e) {
      debugPrint('등산로 로드 오류: $e');
    }
  }

  Future<void> _loadAllTrails() async {
    // Storage 기반에서는 모든 등산로를 한번에 로드하지 않음
    // 개별 오름 선택 시에만 로드
    debugPrint('_loadAllTrails: Storage 모드에서는 사용 안 함');
    return;
  }

  Future<void> _loadVisibleTrails(Map<String, dynamic> bounds) async {
    // Storage 기반에서는 화면 내 등산로를 자동으로 로드하지 않음
    // 사용자가 오름을 선택하면 해당 등산로만 로드
    debugPrint('_loadVisibleTrails: Storage 모드에서는 사용 안 함');
    return;
  }

  void _updateMyLocation() {
    if (_currentPosition != null && _webViewController != null) {
      _webViewController!.runJavaScript(
        'setMyLocation(${_currentPosition!.latitude}, ${_currentPosition!.longitude});'
      );
      _webViewController!.runJavaScript(
        'moveToLocation(${_currentPosition!.latitude}, ${_currentPosition!.longitude}, 5);'
      );
    }
  }

  void _moveToMyLocation() {
    if (_currentPosition != null && _webViewController != null) {
      _webViewController!.runJavaScript(
        'moveToLocation(${_currentPosition!.latitude}, ${_currentPosition!.longitude}, 5);'
      );
    } else {
      _getCurrentLocation();
    }
  }

  // 필터를 지도에 적용하는 메서드
  void _applyFiltersToMap() {
    if (_webViewController != null) {
      // 필터가 없으면 모든 마커 표시
      if (_selectedDifficulty == null && _selectedDuration == null) {
        debugPrint('필터 없음 - 모든 마커 표시');
        _webViewController?.runJavaScript('showAllMarkers();');
        return;
      }

      debugPrint('필터 적용 시작 - 난이도: $_selectedDifficulty, 소요시간: $_selectedDuration');

      // 필터링된 오름의 인덱스 목록 생성
      final filteredIndices = <int>[];
      for (int i = 0; i < _oreums.length; i++) {
        final oreum = _oreums[i];
        bool shouldInclude = true;

        // 난이도 필터
        if (_selectedDifficulty != null && oreum['difficulty'] != _selectedDifficulty) {
          shouldInclude = false;
        }

        // 소요 시간 필터
        if (_selectedDuration != null && shouldInclude) {
          final duration = oreum['duration'] as int? ?? 0;

          if (_selectedDuration == 30 && duration > 30) shouldInclude = false;
          if (_selectedDuration == 60 && (duration <= 30 || duration > 60)) shouldInclude = false;
          if (_selectedDuration == 120 && (duration <= 60 || duration > 120)) shouldInclude = false;
          if (_selectedDuration == 121 && duration <= 120) shouldInclude = false;
        }

        if (shouldInclude) {
          filteredIndices.add(i);
        }
      }

      debugPrint('필터링 결과: ${filteredIndices.length}개 오름 선택됨');

      // WebView에 필터 적용
      _webViewController?.runJavaScript('''
        applyOreumFilter(${jsonEncode(filteredIndices)});
      ''');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        // 팝업이 열려있으면 팝업을 닫음
        if (_selectedOreumIndex != null) {
          setState(() {
            _selectedOreumIndex = null;
          });
          return;
        }

        // 패널이 열려있으면 패널을 닫음
        if (_panelController.isPanelOpen) {
          _panelController.close();
          return;
        }

        // 그 외에는 아무것도 하지 않음 (앱 종료 방지)
      },
      child: Scaffold(
        body: SlidingUpPanel(
          controller: _panelController,
          minHeight: _navigationDestination != null ? 0 : 280,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          defaultPanelState: _navigationDestination != null ? PanelState.CLOSED : PanelState.OPEN,
          panel: _buildPanel(),
          body: Stack(
            children: [
          // 기존 지도 위젯들...
          if (_webViewController != null)
            WebViewWidget(controller: _webViewController!)
          else
            const Center(
              child: CircularProgressIndicator(),
            ),

          IgnorePointer(
            child: AnimatedOpacity(
              opacity: _zoom >= 7 ? 0.12 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: Container(color: const Color(0xFFFFF6E9)),
            ),
          ),

          IgnorePointer(
            child: AnimatedOpacity(
              opacity: _zoom >= 7 ? 0.06 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFDAF0F6), Color(0x00DAF0F6)],
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppTheme.backgroundWhite,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.dividerGray,
                                  width: 1,
                                ),
                              ),
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: '오름 검색',
                                  hintStyle: TextStyle(
                                    color: AppTheme.textGray.withOpacity(0.6),
                                    fontSize: 15,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    color: AppTheme.textGray,
                                    size: 22,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: AppTheme.textBlack,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // 리스트 버튼
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundWhite,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.dividerGray,
                                width: 1,
                              ),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.list,
                                color: AppTheme.textGray,
                              ),
                              onPressed: () {
                                _panelController.open();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            right: 16,
            top: MediaQuery.of(context).size.height / 2 - 120,
            child: Column(
              children: [
                // 모든 등산로 표시 토글
                FloatingActionButton(
                  heroTag: 'toggle_trails',
                  mini: false,
                  backgroundColor: _showAllTrails ? const Color(0xFF4CAF50) : Colors.white,
                  foregroundColor: _showAllTrails ? Colors.white : AppTheme.textGray,
                  onPressed: () {
                    setState(() {
                      _showAllTrails = !_showAllTrails;
                    });
                    if (_showAllTrails) {
                      _loadAllTrails();
                    } else {
                      _webViewController?.runJavaScript('clearAllTrails();');
                    }
                  },
                  child: const Icon(Icons.route),
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: 'zoom_in',
                  mini: true,
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.textBlack,
                  onPressed: () {
                    _webViewController?.runJavaScript('zoomIn();');
                  },
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'zoom_out',
                  mini: true,
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.textBlack,
                  onPressed: () {
                    _webViewController?.runJavaScript('zoomOut();');
                  },
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),

          Positioned(
            right: 16,
            bottom: _selectedOreumIndex != null ? 500 : 90,
            child: FloatingActionButton(
              heroTag: 'my_location',
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.stampGreen,
              onPressed: _moveToMyLocation,
              child: const Icon(Icons.my_location),
            ),
          ),

          // 정보 카드 비활성화
          // if (_selectedOreumIndex != null)
          //   Positioned(
          //     bottom: 300,
          //     left: 0,
          //     right: 0,
          //     child: _buildOreumInfoCard(_oreums[_selectedOreumIndex!]),
          //   ),

          // 네비게이션 바 (경로 표시 중일 때)
          if (_navigationDestination != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _navigationDestination!['name'] as String,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textBlack,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: AppTheme.textGray),
                            onPressed: () {
                              setState(() {
                                _navigationDestination = null;
                              });
                              _webViewController?.runJavaScript('clearAllTrails();');
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '길안내 시작',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textGray.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          // 카카오맵 버튼
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                final lat = _navigationDestination!['entrance_lat'] ??
                                           _navigationDestination!['summit_lat'];
                                final lng = _navigationDestination!['entrance_lng'] ??
                                           _navigationDestination!['summit_lng'];
                                final name = _navigationDestination!['name'] as String;
                                if (lat != null && lng != null) {
                                  _launchKakaoNavigation(lat, lng, name);
                                }
                              },
                              icon: const Icon(Icons.navigation, size: 20),
                              label: const Text(
                                '카카오맵',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFEE500),
                                foregroundColor: const Color(0xFF3C1E1E),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // 구글맵 버튼
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                final lat = _navigationDestination!['entrance_lat'] ??
                                           _navigationDestination!['summit_lat'];
                                final lng = _navigationDestination!['entrance_lng'] ??
                                           _navigationDestination!['summit_lng'];
                                if (lat != null && lng != null) {
                                  _launchGoogleNavigation(lat, lng);
                                }
                              },
                              icon: const Icon(Icons.navigation, size: 20),
                              label: const Text(
                                '구글맵',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4285F4),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPanel() {
    // 오름이 선택된 경우 오름 정보 패널 표시
    if (_selectedOreumIndex != null) {
      return _buildOreumDetailPanel(_oreums[_selectedOreumIndex!]);
    }

    // 선택되지 않은 경우 기존 오름 목록 패널 표시
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // 드래그 핸들
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 필터 섹션
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '오름 목록',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textBlack,
                      ),
                    ),
                    if (_selectedDifficulty != null || _selectedDuration != null)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedDifficulty = null;
                            _selectedDuration = null;
                            _applyFiltersToMap();
                          });
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('초기화', style: TextStyle(fontSize: 13)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // 난이도 필터 - 레이블과 칩을 한 줄에
                Row(
                  children: [
                    const Text(
                      '난이도',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textBlack,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        children: _difficultyOptions.map((option) {
                          final isSelected = _selectedDifficulty == option['value'];
                          return FilterChip(
                            label: Text(option['label']),
                            selected: isSelected,
                            onSelected: (_) {
                              setState(() {
                                _selectedDifficulty = isSelected ? null : option['value'];
                                _applyFiltersToMap();
                              });
                            },
                            backgroundColor: Colors.white,
                            selectedColor: AppTheme.stampGreen.withOpacity(0.2),
                            checkmarkColor: AppTheme.stampGreen,
                            labelStyle: TextStyle(
                              color: isSelected ? AppTheme.stampGreen : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                            side: BorderSide(
                              color: isSelected ? AppTheme.stampGreen : Colors.grey.shade300,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // 소요시간 필터 - 레이블과 칩을 한 줄에
                Row(
                  children: [
                    const Text(
                      '소요시간',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textBlack,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Wrap(
                          spacing: 6,
                          children: _durationOptions.map((option) {
                            final isSelected = _selectedDuration == option['value'];
                            return FilterChip(
                              label: Text(option['label']),
                              selected: isSelected,
                              onSelected: (_) {
                                setState(() {
                                  _selectedDuration = isSelected ? null : option['value'];
                                  _applyFiltersToMap();
                                });
                              },
                              backgroundColor: Colors.white,
                              selectedColor: AppTheme.stampGreen.withOpacity(0.2),
                              checkmarkColor: AppTheme.stampGreen,
                              labelStyle: TextStyle(
                                color: isSelected ? AppTheme.stampGreen : Colors.black87,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 12,
                              ),
                              side: BorderSide(
                                color: isSelected ? AppTheme.stampGreen : Colors.grey.shade300,
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // 정렬 옵션
                Row(
                  children: [
                    const Text(
                      '정렬',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textBlack,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildSortChip('이름순', 'name'),
                            const SizedBox(width: 6),
                            _buildSortChip('거리순', 'distance'),
                            const SizedBox(width: 6),
                            _buildSortChip('난이도순', 'difficulty'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // 오름 목록
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredOreums.length,
              itemBuilder: (context, index) {
                final oreum = _filteredOreums[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.dividerGray),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.dividerGray, width: 1),
                      ),
                      child: ClipOval(
                        child: Image.network(
                          'https://cpnoyaaccshtfncmefet.supabase.co/storage/v1/object/public/oreum-data/${oreum['folder']}/stamp.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            // 스탬프 로드 실패 시 난이도 텍스트 표시
                            return Container(
                              color: Color(int.parse((oreum['color'] ?? '#4CAF50').replaceAll('#', '0xFF'))).withOpacity(0.2),
                              child: Center(
                                child: Text(
                                  oreum['difficulty'] ?? '',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(int.parse((oreum['color'] ?? '#4CAF50').replaceAll('#', '0xFF'))),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    title: Text(
                      _cleanOreumName(oreum['name']),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textBlack,
                      ),
                    ),
                    subtitle: Text(
                      '${oreum['distance']?.toStringAsFixed(1) ?? '-'}km · ${oreum['elevation']?.toStringAsFixed(0) ?? '-'}m',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textGray.withOpacity(0.8),
                      ),
                    ),
                    onTap: () {
                      // 상세 화면으로 바로 이동
                      final oreumModel = oreum['oreum_object'] as Oreum?;
                      final entranceLat = oreum['entrance_lat'] as double?;
                      final entranceLng = oreum['entrance_lng'] as double?;

                      if (oreumModel != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OreumDetailScreen(
                              oreum: oreumModel,
                              entranceLat: entranceLat,
                              entranceLng: entranceLng,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 오름 상세 정보 패널
  Widget _buildOreumDetailPanel(Map<String, dynamic> oreum) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // 드래그 핸들
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 뒤로가기 버튼 + 오름 이름
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        setState(() {
                          _selectedOreumIndex = null;
                        });
                        _webViewController?.runJavaScript('clearAllTrails();');
                        _panelController.open();
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _cleanOreumName(oreum['name']),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textBlack,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 난이도 정보
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Color(int.parse((oreum['color'] ?? '#4CAF50').replaceAll('#', '0xFF'))).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '난이도: ${oreum['difficulty'] ?? '-'}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(int.parse((oreum['color'] ?? '#4CAF50').replaceAll('#', '0xFF'))),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${oreum['distance']?.toStringAsFixed(1) ?? '-'}km',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textGray,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${oreum['elevation']?.toStringAsFixed(0) ?? '-'}m',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textGray,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 길안내 시작 버튼들
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '길안내 시작',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textGray,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final lat = oreum['entrance_lat'] ?? oreum['summit_lat'];
                              final lng = oreum['entrance_lng'] ?? oreum['summit_lng'];
                              final name = oreum['name'] as String;
                              if (lat != null && lng != null) {
                                _launchKakaoNavigation(lat, lng, name);
                              }
                            },
                            icon: const Icon(Icons.navigation, size: 20),
                            label: const Text('카카오맵'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFEE500),
                              foregroundColor: const Color(0xFF3C1E1E),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final lat = oreum['entrance_lat'] ?? oreum['summit_lat'];
                              final lng = oreum['entrance_lng'] ?? oreum['summit_lng'];
                              if (lat != null && lng != null) {
                                _launchGoogleNavigation(lat, lng);
                              }
                            },
                            icon: const Icon(Icons.navigation, size: 20),
                            label: const Text('구글맵'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4285F4),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 상세정보 버튼
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OreumDetailScreen(
                            oreum: oreum['oreum_object'],
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.info_outline, size: 20),
                    label: const Text('상세정보'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textBlack,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(color: AppTheme.dividerGray),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip(String label, String value) {
    final isSelected = _sortBy == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _sortBy = value;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: AppTheme.stampGreen.withOpacity(0.2),
      checkmarkColor: AppTheme.stampGreen,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.stampGreen : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      side: BorderSide(
        color: isSelected ? AppTheme.stampGreen : Colors.grey.shade300,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildOreumInfoCard(Map<String, dynamic> oreum) {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              // Close button
              Positioned(
                top: 12,
                right: 12,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedOreumIndex = null;
                    });
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: oreum['imageUrl'] != null
                    ? Image.network(
                        oreum['imageUrl'],
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(Icons.landscape, size: 60, color: Colors.grey),
                            ),
                          );
                        },
                      )
                    : Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(Icons.landscape, size: 60, color: Colors.grey),
                        ),
                      ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        oreum['name'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (oreum['difficulty'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '난이도: ${oreum['difficulty']}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.star, size: 20, color: AppTheme.stampGreen),
                    const SizedBox(width: 12),
                    Text(
                      '난이도: ${oreum['difficulty'] ?? '-'}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textBlack,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.straighten, size: 20, color: AppTheme.stampGreen),
                    const SizedBox(width: 12),
                    Text(
                      '거리: ${oreum['distance']?.toStringAsFixed(2) ?? '-'}km',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textBlack,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.terrain, size: 20, color: AppTheme.stampGreen),
                    const SizedBox(width: 12),
                    Text(
                      '고도차: ${oreum['elevation']?.toStringAsFixed(0) ?? '-'}m',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textBlack,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OreumDetailScreen(
                          oreum: oreum['oreum_object'],
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundWhite,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '상세정보 보기',
                          style: TextStyle(
                            color: AppTheme.textBlack,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: AppTheme.textGray,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 길안내 버튼들
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '길안내 시작',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textGray,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final lat = oreum['entrance_lat'] ?? oreum['summit_lat'];
                              final lng = oreum['entrance_lng'] ?? oreum['summit_lng'];
                              final name = oreum['name'] as String;
                              if (lat != null && lng != null) {
                                _launchKakaoNavigation(lat, lng, name);
                              }
                            },
                            icon: const Icon(Icons.navigation, size: 18),
                            label: const Text('카카오맵'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFEE500),
                              foregroundColor: const Color(0xFF3C1E1E),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final lat = oreum['entrance_lat'] ?? oreum['summit_lat'];
                              final lng = oreum['entrance_lng'] ?? oreum['summit_lng'];
                              if (lat != null && lng != null) {
                                _launchGoogleNavigation(lat, lng);
                              }
                            },
                            icon: const Icon(Icons.navigation, size: 18),
                            label: const Text('구글맵'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4285F4),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  
  Future<bool> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }
    
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    
    return true;
  }
  
  void _showLocationPermissionAlert() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('위치 권한 필요'),
        content: const Text('내비게이션을 사용하려면 위치 권한이 필요합니다. 설정에서 위치 권한을 허용해주세요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openAppSettings();
            },
            child: const Text('설정으로 이동'),
          ),
        ],
      ),
    );
  }
  
  void _showLocationErrorAlert() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('위치 정보 오류'),
        content: const Text('현재 위치를 가져올 수 없습니다. GPS가 켜져 있는지 확인해주세요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}
