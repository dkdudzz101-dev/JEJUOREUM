import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // for kDebugMode
import 'package:webview_flutter/webview_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/navigation_provider.dart';
import '../services/performance_monitor.dart';
import '../services/offline_map_service.dart';
import '../services/accessibility_service.dart';
import '../widgets/debug_overlay.dart';
import '../widgets/smooth_animation_route.dart';
import '../theme/app_theme.dart';

class NavigationScreen extends StatefulWidget {
  final String destination;
  final String estimatedTime;
  final String distance;
  final double? entranceLat;
  final double? entranceLng;
  final double? destinationLat;
  final double? destinationLng;
  final bool debugMode;

  const NavigationScreen({
    super.key,
    required this.destination,
    required this.estimatedTime,
    required this.distance,
    this.entranceLat,
    this.entranceLng,
    this.destinationLat,
    this.destinationLng,
    this.debugMode = kDebugMode,
  });

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> with WidgetsBindingObserver {
  // 서비스 인스턴스
  late final NavigationProvider _navigationProvider;
  late final PerformanceMonitor _performanceMonitor;
  late final OfflineMapService _offlineMapService;
  late final AccessibilityService _accessibilityService;
  
  // 상태 변수들
  bool _isInitialized = false;
  bool _isOffline = false;
  bool _isVoiceGuidanceEnabled = true;
  bool _showDebugOverlay = false;
  bool _isNavigating = false;
  bool _isAtEntrance = false;
  bool _isWeakGpsSignal = false;

  // 위치 및 거리 정보
  Position? _currentPosition;
  double? _remainingDistance;
  int? _remainingTime;
  Timer? _gpsSignalTimer;

  // 컨트롤러 및 스트림
  WebViewController? _webViewController;
  FlutterTts? _tts;
  StreamSubscription<Position>? _positionStream;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  // 상수
  static const double _entranceRadiusKm = 0.05; // 입구 반경 50m
  static const String _kakaoJsKey = '9fb90cfd5075a5a193d3545bb0ed61e1'; // 카카오맵 JavaScript 키
  static const Duration _gpsCheckInterval = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // 서비스 초기화
    _navigationProvider = context.read<NavigationProvider>();
    _performanceMonitor = PerformanceMonitor();
    _offlineMapService = OfflineMapService();
    _accessibilityService = AccessibilityService();
    
    // TTS 초기화
    _initTts();
    
    // 위치 권한 요청 및 위치 업데이트 시작
    _checkLocationPermission();
    
    // 네트워크 상태 모니터링 시작
    _startConnectivityMonitoring();
    
    // 오프라인 맵 데이터 로드 시도
    _loadOfflineMapData();
    
    // 접근성 알림
    _accessibilityService.announce(
      '${widget.destination}으로의 내비게이션이 시작되었습니다. '
      '예상 소요 시간은 ${widget.estimatedTime}입니다.'
    );
    
    // 성능 모니터링 시작
    if (widget.debugMode) {
      _performanceMonitor.startFpsMonitoring();
      _performanceMonitor.startTimer('navigation_screen');
    }
    super.initState();
    _initWebView();
    _requestLocationPermission();
    _startGpsSignalCheck();
  }

  @override
  void dispose() {
    // 리소스 정리
    _positionStream?.cancel();
    _connectivitySubscription?.cancel();
    _gpsSignalTimer?.cancel();
    _tts?.stop();
    _performanceMonitor.stopTimer('navigation_screen');
    _performanceMonitor.dispose();

    // 내비게이션 상태 초기화
    if (_navigationProvider.isNavigating) {
      _navigationProvider.updateNavigationStatus(false);
    }

    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        _checkLocationPermission();
        _navigationProvider.updateOnlineStatus(true);
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // 백그라운드에서도 내비게이션 유지
        if (_navigationProvider.isNavigating) {
          _startBackgroundService();
        }
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  Future<void> _requestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      debugPrint('GPS 위치 요청 중...');
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      debugPrint('GPS 위치 받음: ${position.latitude}, ${position.longitude}');
      setState(() {
        _currentPosition = position;
        _updateDistance();
      });
      _updateMapLocation();
    } catch (e) {
      debugPrint('위치 가져오기 오류: $e');
    }
  }

  void _startLocationUpdates() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      setState(() {
        _currentPosition = position;
        _updateDistance();
      });
      _updateMapLocation();
    });
  }

  void _updateDistance() {
    if (_currentPosition == null) {
      debugPrint('현재 위치 없음 - 거리 계산 불가');
      return;
    }

    // 현재 위치에서 입구까지의 거리
    if (widget.entranceLat == null || widget.entranceLng == null) {
      return;
    }

    final distanceToEntrance = _calculateDistance(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      widget.entranceLat!,
      widget.entranceLng!,
    );

    debugPrint('입구까지 거리: ${distanceToEntrance.toStringAsFixed(2)}km');

    // 입구 도착 여부 확인 (50m 이내)
    final wasAtEntrance = _isAtEntrance;
    _isAtEntrance = distanceToEntrance <= _entranceRadiusKm;

    if (!wasAtEntrance && _isAtEntrance) {
      debugPrint('✅ 입구 도착! 등산 시작');
    }

    setState(() {
      _remainingDistance = distanceToEntrance;

      if (_isAtEntrance) {
        // 입구에 도착했으면 등산로 거리와 시간 표시
        final trailDistance = double.tryParse(widget.distance.replaceAll(' km', '')) ?? 0.0;
        _remainingDistance = trailDistance;
        _remainingTime = (trailDistance * 15).toInt();
      } else {
        // 입구까지 가는 거리와 시간
        _remainingDistance = distanceToEntrance;
        _remainingTime = (distanceToEntrance * 15).toInt();
      }
    });
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371;

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * (math.pi / 180);
  }

  void _updateMapLocation() {
    if (_webViewController == null || _currentPosition == null) return;

    _webViewController!.runJavaScript('''
      if (typeof updateCurrentLocation === 'function') {
        updateCurrentLocation(${_currentPosition!.latitude}, ${_currentPosition!.longitude}, $_isAtEntrance);
      }
    ''');
  }

  Future<void> _initWebView() async {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..loadHtmlString(_buildMapHtml());

    setState(() {
      _webViewController = controller;
    });
  }

  // GPS 신호 상태 체크 시작
  void _startGpsSignalCheck() {
    // 5초마다 GPS 신호 상태 체크
    _gpsSignalTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_currentPosition != null) {
        // 정확도가 50m를 초과하면 신호 약함으로 판단
        final isWeak = _currentPosition!.accuracy > 50.0;
        if (mounted && _isWeakGpsSignal != isWeak) {
          setState(() {
            _isWeakGpsSignal = isWeak;
          });
        }
      }
    });
  }

  // 내 위치로 지도 이동
  void _moveToMyLocation() {
    if (_currentPosition != null) {
      _webViewController?.runJavaScript('''
        var moveLatLon = new kakao.maps.LatLng(${_currentPosition!.latitude}, ${_currentPosition!.longitude});
        map.setCenter(moveLatLon);
      ''');
    }
  }

  // 내비게이션 시작
  void _startNavigation() {
    setState(() {
      _isNavigating = true;
    });
    _startLocationUpdates();
    _showNavigationStartedSnackbar();
  }

  // 내비게이션 중지
  void _stopNavigation() {
    setState(() {
      _isNavigating = false;
    });
    _positionStream?.pause();
    _showNavigationStoppedSnackbar();
  }

  void _showNavigationStartedSnackbar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('내비게이션을 시작합니다. 안전운전하세요!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showNavigationStoppedSnackbar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('내비게이션을 중지했습니다.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // 정보 카드 위젯
  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      width: (MediaQuery.of(context).size.width - 56) / 2,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.stampGreen, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // TTS 초기화
  Future<void> _initTts() async {
    _tts = FlutterTts();
    await _tts?.setLanguage("ko-KR");
  }

  // 위치 권한 확인
  Future<void> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      _getCurrentLocation();
    }
  }

  // 연결 모니터링 시작
  void _startConnectivityMonitoring() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      setState(() {
        _isOffline = result == ConnectivityResult.none;
      });
      _navigationProvider.updateOnlineStatus(!_isOffline);
    });
  }

  // 오프라인 맵 데이터 로드
  Future<void> _loadOfflineMapData() async {
    try {
      // 오프라인 맵 서비스 초기화
      debugPrint('오프라인 맵 서비스 준비 완료');
    } catch (e) {
      debugPrint('오프라인 맵 데이터 로드 실패: $e');
    }
  }

  // 백그라운드 서비스 시작
  void _startBackgroundService() {
    // TODO: 백그라운드 서비스 구현
  }

  String _buildMapHtml() {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1.0,maximum-scale=1.0,user-scalable=no">
  <title>오름 길안내</title>
  <script type="text/javascript" src="https://dapi.kakao.com/v2/maps/sdk.js?appkey=$_kakaoJsKey&libraries=services"></script>
  <style>
    html, body { width: 100%; height: 100%; margin: 0; padding: 0; }
    #map { width: 100%; height: 100%; }
  </style>
</head>
<body>
  <div id="map"></div>
  <script>
    var map;
    var markers = [];
    var polylines = [];
    var userMarker = null;
    var destinationMarker = null;
    var directions = null;
    var isNavigating = false;

    // 지도 초기화
    function initMap() {
      // 지도 생성
      var mapContainer = document.getElementById('map');
      var mapOption = {
        center: new kakao.maps.LatLng(33.450701, 126.570667), // 기본 중심좌표 (제주시청)
        level: 5
      };

      map = new kakao.maps.Map(mapContainer, mapOption);
      
      // 방향 API 서비스 생성
      directions = new kakao.maps.services.Directions();
      
      // 지도 로드 완료 이벤트
      kakao.maps.event.addListener(map, 'tilesloaded', function() {
        // Flutter에 지도 로드 완료 알림
        if (window.flutter_inappwebview) {
          window.flutter_inappwebview.callHandler('mapLoaded');
        }
      });
      
      // 지도 확대/축소 이벤트
      kakao.maps.event.addListener(map, 'zoom_changed', function() {
        // 마커 크기 조정
        adjustMarkerSize();
      });
    }
    
    // 현재 위치 마커 업데이트
    function updateCurrentLocation(lat, lng, isAtEntrance) {
      var position = new kakao.maps.LatLng(lat, lng);
      
      // 사용자 마커가 없으면 생성
      if (!userMarker) {
        var imageSrc = 'https://t1.daumcdn.net/localimg/localimages/07/mapapidoc/markerStar.png';
        var imageSize = new kakao.maps.Size(24, 35);
        var markerImage = new kakao.maps.MarkerImage(imageSrc, imageSize);
        
        userMarker = new kakao.maps.Marker({
          position: position,
          image: markerImage
        });
        userMarker.setMap(map);
      } else {
        // 기존 마커 위치 업데이트
        userMarker.setPosition(position);
      }
      
      // 지도 중심을 현재 위치로 이동 (내비게이션 중일 때만)
      if (isAtEntrance || isNavigating) {
        map.panTo(position);
      }
    }
    
    // 목적지 마커 설정
    function setDestination(lat, lng, title) {
      var position = new kakao.maps.LatLng(lat, lng);
      
      // 기존 목적지 마커 제거
      if (destinationMarker) {
        destinationMarker.setMap(null);
      }
      
      // 목적지 마커 생성
      var imageSrc = 'https://t1.daumcdn.net/localimg/localimages/07/mapapidoc/marker_red.png';
      var imageSize = new kakao.maps.Size(24, 35);
      var markerImage = new kakao.maps.MarkerImage(imageSrc, imageSize);
      
      destinationMarker = new kakao.maps.Marker({
        position: position,
        image: markerImage,
        title: title || '목적지'
      });
      
      destinationMarker.setMap(map);
      
      // 인포윈도우에 목적지 표시
      var infowindow = new kakao.maps.InfoWindow({
        content: '<div style="padding:5px;font-size:12px;">' + (title || '목적지') + '</div>'
      });
      
      infowindow.open(map, destinationMarker);
      
      return position;
    }
    
    // 경로 표시
    function drawRoute(start, end) {
      // 기존 경로 제거
      clearRoutes();
      
      // 경로 요청
      directions.origin(start, function(result, status) {
        if (status === kakao.maps.services.Status.OK) {
          directions.destination(end, function(result, status) {
            if (status === kakao.maps.services.Status.OK) {
              // 경로 검색 결과
              directions.search(start, end, function(result, status) {
                if (status === kakao.maps.services.Status.OK) {
                  // 첫 번째 경로만 사용
                  var route = result[0];
                  
                  // 경로 좌표 추출
                  var points = [];
                  for (var i = 0; i < route.sections.length; i++) {
                    points = points.concat(route.sections[i].latlngs);
                  }
                  
                  // 경로 선 그리기
                  var polyline = new kakao.maps.Polyline({
                    path: points,
                    strokeWeight: 5,
                    strokeColor: '#3182CE',
                    strokeOpacity: 0.8,
                    strokeStyle: 'solid'
                  });
                  
                  polyline.setMap(map);
                  polylines.push(polyline);
                  
                  // 경유지 마커 표시
                  for (var i = 0; i < route.sections.length; i++) {
                    var section = route.sections[i];
                    
                    // 출발지, 도착지, 경유지 마커 추가
                    if (i === 0) {
                      // 출발지 마커
                      addMarker(section.latlngs[0], '출발', 'start');
                    }
                    
                    // 도착지 마커
                    if (i === route.sections.length - 1) {
                      addMarker(section.latlngs[section.latlngs.length - 1], '도착', 'arrival');
                    } else {
                      // 경유지 마커
                      addMarker(section.latlngs[section.latlngs.length - 1], '경유지 ' + (i + 1), 'waypoint');
                    }
                  }
                  
                  // 경로에 맞게 지도 영역 조정
                  var bounds = new kakao.maps.LatLngBounds();
                  points.forEach(function(point) {
                    bounds.extend(point);
                  });
                  
                  // 사용자 위치와 목적지도 경계에 포함
                  if (userMarker) {
                    bounds.extend(userMarker.getPosition());
                  }
                  if (destinationMarker) {
                    bounds.extend(destinationMarker.getPosition());
                  }
                  
                  map.setBounds(bounds);
                }
              });
            }
          });
        }
      });
    }
    
    // 마커 추가
    function addMarker(position, title, type) {
      var imageUrl = 'https://t1.daumcdn.net/localimg/localimages/07/mapapidoc/marker';
      var imageSize = new kakao.maps.Size(24, 35);
      var imageOffset = new kakao.maps.Point(12, 35);
      
      // 마커 이미지 설정
      switch(type) {
        case 'start':
          imageUrl += 'Start.png';
          break;
        case 'arrival':
          imageUrl += 'Red.png';
          break;
        case 'waypoint':
          imageUrl += 'Green.png';
          break;
        default:
          imageUrl += 'Black.png';
      }
      
      var markerImage = new kakao.maps.MarkerImage(imageUrl, imageSize, { offset: imageOffset });
      
      var marker = new kakao.maps.Marker({
        position: position,
        image: markerImage,
        title: title
      });
      
      marker.setMap(map);
      markers.push(marker);
      
      return marker;
    }
    
    // 마커 크기 조정 (줌 레벨에 따라)
    function adjustMarkerSize() {
      var level = map.getLevel();
      var size = 24 * Math.pow(1.2, 10 - level); // 줌 레벨에 따라 마커 크기 조정
      
      markers.forEach(function(marker) {
        var image = marker.getImage();
        image.size = new kakao.maps.Size(size, size * 1.5);
        marker.setImage(image);
      });
    }
    
    // 모든 경로 제거
    function clearRoutes() {
      polylines.forEach(function(polyline) {
        polyline.setMap(null);
      });
      polylines = [];
      
      markers.forEach(function(marker) {
        marker.setMap(null);
      });
      markers = [];
    }
    
    // 지도 초기화 실행
    initMap();
  </script>
</body>
</html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // WebView 지도
          if (_webViewController != null)
            WebViewWidget(controller: _webViewController!)
          else
            const Center(child: CircularProgressIndicator()),

          // GPS 신호 약함 배너
          if (_isWeakGpsSignal)
            Positioned(
              top: MediaQuery.of(context).padding.top + kToolbarHeight,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.orange.withOpacity(0.9),
                child: const Row(
                  children: [
                    Icon(Icons.gps_off, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'GPS 신호가 약합니다. 정확한 위치 정보가 지연될 수 있습니다.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 상단 앱바
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: const Text(
                '경로 안내',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // 지도 컨트롤 버튼
          Positioned(
          right: 16,
          top: MediaQuery.of(context).size.height / 2 - 60,
          child: Column(
            children: [
              FloatingActionButton(
                heroTag: 'zoom_in',
                mini: true,
                backgroundColor: Colors.white,
                onPressed: () {
                  _webViewController?.runJavaScript('map.setLevel(map.getLevel() - 1);');
                },
                child: const Icon(Icons.add, color: Colors.black),
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                heroTag: 'zoom_out',
                mini: true,
                backgroundColor: Colors.white,
                onPressed: () {
                  _webViewController?.runJavaScript('map.setLevel(map.getLevel() + 1);');
                },
                child: const Icon(Icons.remove, color: Colors.black),
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                heroTag: 'my_location',
                mini: true,
                backgroundColor: Colors.white,
                onPressed: _moveToMyLocation,
                child: const Icon(Icons.my_location, color: AppTheme.stampGreen),
              ),
            ],
          ),
        ),

        // 하단 정보 패널
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.destination} ${_isAtEntrance ? '등산로' : '입구'}까지',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                // 예상 시간 및 거리
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoCard(
                      '예상 시간',
                      _remainingTime != null
                          ? '${_remainingTime! ~/ 60}시간 ${_remainingTime! % 60}분'
                          : '계산 중...',
                      Icons.access_time,
                    ),
                    _buildInfoCard(
                      '남은 거리',
                      _remainingDistance != null
                          ? '${_remainingDistance!.toStringAsFixed(2)} km'
                          : '계산 중...',
                      Icons.place,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 내비게이션 시작/종료 버튼
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isNavigating ? _stopNavigation : _startNavigation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isNavigating ? Colors.red : AppTheme.stampGreen,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _isNavigating ? '내비게이션 종료' : '내비게이션 시작',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        ],
      ),
    );
  }
}
