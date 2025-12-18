import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/storage_oreum_service.dart';
import '../services/hiking_record_service.dart';
import '../models/hiking_record.dart';

class OreumNavigationScreen extends StatefulWidget {
  final String oreumCode;
  final String oreumName;
  final Map<String, dynamic> geoJson;

  const OreumNavigationScreen({
    super.key,
    required this.oreumCode,
    required this.oreumName,
    required this.geoJson,
  });

  @override
  State<OreumNavigationScreen> createState() => _OreumNavigationScreenState();
}

class _OreumNavigationScreenState extends State<OreumNavigationScreen> {
  final StorageOreumService _service = StorageOreumService();
  final HikingRecordService _recordService = HikingRecordService();
  final MapController _mapController = MapController();
  final FlutterTts _tts = FlutterTts();
  final PanelController _panelController = PanelController();
  final ImagePicker _imagePicker = ImagePicker();

  // 위치 추적
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;
  bool _locationPermissionGranted = false;

  // 등산로 데이터
  List<LatLng> _trailPath = [];
  List<Map<String, dynamic>> _waypoints = [];
  Map<String, dynamic>? _targetEntrance;
  Map<String, dynamic>? _summit;

  // 네비게이션 상태
  bool _isNavigating = false;
  Map<String, dynamic>? _nextWaypoint;
  double _distanceToNext = 0;
  double _totalDistance = 0;
  double _progressPercentage = 0;

  // 등산 기록
  String? _currentRecordId;
  List<HikingPoint> _trackingPoints = [];
  List<String> _photoUrls = [];
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _initializeNavigation();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _tts.stop();
    super.dispose();
  }

  Future<void> _initializeNavigation() async {
    await _setupTts();
    await _checkLocationPermission();
    _parseTrailData();
    await _getCurrentLocation();
    _findNearestEntrance();
    _startNavigation();
  }

  Future<void> _setupTts() async {
    await _tts.setLanguage('ko-KR');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    setState(() {
      _locationPermissionGranted = permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    });

    if (!_locationPermissionGranted) {
      _speak('위치 권한이 필요합니다');
    }
  }

  Future<void> _getCurrentLocation() async {
    if (!_locationPermissionGranted) return;

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
      });

      // 지도 중심을 현재 위치로 이동
      _mapController.move(
        LatLng(position.latitude, position.longitude),
        16,
      );
    } catch (e) {
      print('위치 가져오기 오류: $e');
    }
  }

  void _parseTrailData() {
    final pathCoords = _service.getTrailPath(widget.geoJson);
    _trailPath = pathCoords
        .map((coord) => LatLng(coord['lat']!, coord['lng']!))
        .toList();

    _waypoints = _service.getWaypoints(widget.geoJson);
    _summit = _service.getSummit(widget.geoJson);
  }

  void _findNearestEntrance() {
    if (_currentPosition == null) return;

    _targetEntrance = _service.findNearestEntrance(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      widget.geoJson,
    );

    if (_targetEntrance != null) {
      final distance = _targetEntrance!['distance'] ?? 0;
      _speak('가장 가까운 입구까지 ${distance.toStringAsFixed(0)}미터입니다');
    }
  }

  void _startNavigation() async {
    if (!_locationPermissionGranted) return;

    // 등산 기록 시작
    try {
      _startTime = DateTime.now();
      _currentRecordId = await _recordService.startHikingRecord(
        widget.oreumCode,
        widget.oreumName,
      );
    } catch (e) {
      print('기록 시작 오류: $e');
    }

    setState(() {
      _isNavigating = true;
    });

    _speak('${widget.oreumName} 등산을 시작합니다');

    // 위치 추적 시작
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // 5미터마다 업데이트
      ),
    ).listen((Position position) {
      setState(() {
        _currentPosition = position;
      });

      // 등산 경로 기록
      _trackingPoints.add(HikingPoint(
        latitude: position.latitude,
        longitude: position.longitude,
        altitude: position.altitude,
        timestamp: DateTime.now(),
        speed: position.speed,
      ));

      _updateNavigation();
    });
  }

  void _updateNavigation() {
    if (_currentPosition == null || _trailPath.isEmpty) return;

    // 다음 웨이포인트 찾기
    _findNextWaypoint();

    // 진행률 계산
    _calculateProgress();

    // 경로 이탈 확인
    _checkOffTrail();
  }

  void _findNextWaypoint() {
    if (_waypoints.isEmpty) return;

    double minDistance = double.infinity;
    Map<String, dynamic>? nearest;

    for (var waypoint in _waypoints) {
      final distance = _service.calculateDistance(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        waypoint['lat'],
        waypoint['lng'],
      );

      // 아직 도달하지 않은 웨이포인트 중 가장 가까운 것
      if (distance < minDistance && distance > 0.01) {
        // 10m 이상
        minDistance = distance;
        nearest = waypoint;
      }
    }

    if (nearest != null && nearest != _nextWaypoint) {
      setState(() {
        _nextWaypoint = nearest;
        _distanceToNext = minDistance;
      });

      // 웨이포인트가 변경되면 안내
      final type = _nextWaypoint!['type'];
      final name = _nextWaypoint!['name'];
      if (minDistance < 0.1) {
        // 100m 이내
        _speak('${name ?? type}까지 ${(minDistance * 1000).toStringAsFixed(0)}미터 남았습니다');
      }
    } else if (nearest != null) {
      setState(() {
        _distanceToNext = minDistance;
      });
    }
  }

  void _calculateProgress() {
    if (_trailPath.isEmpty || _currentPosition == null) return;

    // 시작점부터 현재 위치까지의 거리 계산
    double coveredDistance = 0;
    LatLng? closestPoint;
    double minDistToTrail = double.infinity;

    for (int i = 0; i < _trailPath.length; i++) {
      final distance = _service.calculateDistance(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        _trailPath[i].latitude,
        _trailPath[i].longitude,
      );

      if (distance < minDistToTrail) {
        minDistToTrail = distance;
        closestPoint = _trailPath[i];
      }
    }

    if (closestPoint != null) {
      int closestIndex = _trailPath.indexOf(closestPoint);
      for (int i = 0; i < closestIndex; i++) {
        coveredDistance += _service.calculateDistance(
          _trailPath[i].latitude,
          _trailPath[i].longitude,
          _trailPath[i + 1].latitude,
          _trailPath[i + 1].longitude,
        );
      }
    }

    // 전체 거리 계산
    if (_totalDistance == 0) {
      for (int i = 0; i < _trailPath.length - 1; i++) {
        _totalDistance += _service.calculateDistance(
          _trailPath[i].latitude,
          _trailPath[i].longitude,
          _trailPath[i + 1].latitude,
          _trailPath[i + 1].longitude,
        );
      }
    }

    setState(() {
      _progressPercentage = (_totalDistance > 0) ? (coveredDistance / _totalDistance) * 100 : 0;
    });
  }

  void _checkOffTrail() {
    if (_trailPath.isEmpty || _currentPosition == null) return;

    // 등산로에서 가장 가까운 점까지의 거리
    double minDist = double.infinity;
    for (var point in _trailPath) {
      final dist = _service.calculateDistance(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        point.latitude,
        point.longitude,
      );
      if (dist < minDist) {
        minDist = dist;
      }
    }

    // 50미터 이상 벗어나면 경고
    if (minDist > 0.05) {
      _speak('등산로에서 벗어났습니다');
    }
  }

  Future<void> _speak(String text) async {
    await _tts.speak(text);
  }

  void _stopNavigation() async {
    // 등산 기록 저장
    if (_currentRecordId != null && _trackingPoints.isNotEmpty) {
      await _saveHikingRecord(completed: false);
    }

    setState(() {
      _isNavigating = false;
    });
    _positionStream?.cancel();
    _tts.stop();
  }

  Future<void> _completeHike() async {
    if (_currentRecordId == null) return;

    await _saveHikingRecord(completed: true);

    _speak('등산을 완료했습니다. 수고하셨습니다!');

    // 업적 확인 및 표시
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('등산 기록이 저장되었습니다!'),
        backgroundColor: Colors.green,
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context);
    });
  }

  Future<void> _saveHikingRecord({required bool completed}) async {
    if (_currentRecordId == null || _trackingPoints.isEmpty) return;

    try {
      // 통계 계산
      final maxAlt = _trackingPoints.map((p) => p.altitude).reduce((a, b) => a > b ? a : b);
      final minAlt = _trackingPoints.map((p) => p.altitude).reduce((a, b) => a < b ? a : b);
      final totalTime = _startTime != null
          ? DateTime.now().difference(_startTime!).inMinutes
          : 0;

      final record = HikingRecord(
        id: _currentRecordId,
        oreumCode: widget.oreumCode,
        oreumName: widget.oreumName,
        startTime: _startTime ?? DateTime.now(),
        endTime: DateTime.now(),
        trackingPoints: _trackingPoints,
        photoUrls: _photoUrls,
        totalDistance: _totalDistance,
        totalTime: totalTime,
        maxAltitude: maxAlt,
        minAltitude: minAlt,
        completed: completed,
      );

      if (completed) {
        await _recordService.completeHikingRecord(_currentRecordId!, record);
      } else {
        await _recordService.updateHikingRecord(_currentRecordId!, record);
      }
    } catch (e) {
      print('기록 저장 오류: $e');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (photo == null) return;

      // 사진 업로드
      if (_currentRecordId != null) {
        final url = await _recordService.uploadPhoto(
          _currentRecordId!,
          File(photo.path),
        );

        if (url != null) {
          setState(() {
            _photoUrls.add(url);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('사진이 저장되었습니다')),
          );
        }
      }
    } catch (e) {
      print('사진 촬영 오류: $e');
    }
  }

  Future<void> _sendEmergencySOS() async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('현재 위치를 확인할 수 없습니다')),
      );
      return;
    }

    final lat = _currentPosition!.latitude;
    final lng = _currentPosition!.longitude;
    final message = '긴급 구조 요청!\n'
        '위치: ${widget.oreumName}\n'
        '좌표: $lat, $lng\n'
        'Google Maps: https://www.google.com/maps?q=$lat,$lng';

    // 119 전화
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 32),
            SizedBox(width: 8),
            Text('긴급 구조'),
          ],
        ),
        content: Text(
          '현재 위치:\n'
          '${widget.oreumName}\n'
          '좌표: $lat, $lng\n\n'
          '119에 전화하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('119 전화'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final uri = Uri.parse('tel:119');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 지도
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: _currentPosition != null
                  ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                  : _trailPath.isNotEmpty
                      ? _trailPath.first
                      : LatLng(33.361, 126.529), // 제주도 중심
              zoom: 16,
              maxZoom: 18,
              minZoom: 10,
            ),
            children: [
              // 지도 타일
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.jeju_oreum',
              ),

              // 등산로 경로
              if (_trailPath.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _trailPath,
                      strokeWidth: 4,
                      color: Colors.blue,
                    ),
                  ],
                ),

              // 웨이포인트 마커
              MarkerLayer(
                markers: [
                  // 입구들
                  ..._waypoints.where((wp) {
                    final type = wp['type'] as String;
                    return type.contains('시종점') || type.contains('입구');
                  }).map((entrance) => Marker(
                        point: LatLng(entrance['lat'], entrance['lng']),
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.login,
                          color: Colors.green,
                          size: 30,
                        ),
                      )),

                  // 정상
                  if (_summit != null)
                    Marker(
                      point: LatLng(_summit!['lat'], _summit!['lng']),
                      width: 50,
                      height: 50,
                      child: const Icon(
                        Icons.terrain,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),

                  // 기타 웨이포인트
                  ..._waypoints.where((wp) {
                    final type = wp['type'] as String;
                    return !type.contains('시종점') &&
                        !type.contains('입구') &&
                        !type.contains('정상');
                  }).map((wp) => Marker(
                        point: LatLng(wp['lat'], wp['lng']),
                        width: 30,
                        height: 30,
                        child: Icon(
                          _getWaypointIcon(wp['type']),
                          color: Colors.orange,
                          size: 24,
                        ),
                      )),

                  // 현재 위치
                  if (_currentPosition != null)
                    Marker(
                      point: LatLng(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                      ),
                      width: 60,
                      height: 60,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.navigation,
                            color: Colors.blue,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // 슬라이딩 패널
          SlidingUpPanel(
            controller: _panelController,
            minHeight: 200,
            maxHeight: MediaQuery.of(context).size.height * 0.7,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            panel: _buildNavigationPanel(),
            body: Container(), // 지도는 이미 Stack에 있음
          ),

          // 상단 앱바
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        _stopNavigation();
                        Navigator.pop(context);
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text(
                          widget.oreumName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.my_location),
                      onPressed: () {
                        if (_currentPosition != null) {
                          _mapController.move(
                            LatLng(
                              _currentPosition!.latitude,
                              _currentPosition!.longitude,
                            ),
                            16,
                          );
                        }
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationPanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 핸들
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 진행률
          Row(
            children: [
              const Icon(Icons.directions_walk, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '진행률: ${_progressPercentage.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _progressPercentage / 100,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 다음 웨이포인트
          if (_nextWaypoint != null)
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      _getWaypointIcon(_nextWaypoint!['type']),
                      size: 32,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _nextWaypoint!['name'] ?? _nextWaypoint!['type'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${(_distanceToNext * 1000).toStringAsFixed(0)}m 남음',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // 현재 위치 정보
          if (_currentPosition != null)
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    '고도',
                    '${_currentPosition!.altitude.toStringAsFixed(0)}m',
                    Icons.height,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoCard(
                    '속도',
                    '${(_currentPosition!.speed * 3.6).toStringAsFixed(1)} km/h',
                    Icons.speed,
                  ),
                ),
              ],
            ),

          const Spacer(),

          // 액션 버튼들
          if (_isNavigating) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _takePhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('사진'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _sendEmergencySOS,
                    icon: const Icon(Icons.sos),
                    label: const Text('긴급'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _completeHike,
                    icon: const Icon(Icons.flag),
                    label: const Text('완료'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // 제어 버튼
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isNavigating ? _stopNavigation : _startNavigation,
                  icon: Icon(_isNavigating ? Icons.stop : Icons.play_arrow),
                  label: Text(_isNavigating ? '중지' : '시작'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: _isNavigating ? Colors.red : Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, size: 24, color: Colors.grey[700]),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getWaypointIcon(String type) {
    if (type.contains('시종점') || type.contains('입구')) {
      return Icons.login;
    } else if (type.contains('정상')) {
      return Icons.terrain;
    } else if (type.contains('분기점')) {
      return Icons.fork_right;
    } else if (type.contains('화장실')) {
      return Icons.wc;
    } else if (type.contains('쉼터')) {
      return Icons.deck;
    } else if (type.contains('안내판')) {
      return Icons.info;
    } else {
      return Icons.place;
    }
  }
}
