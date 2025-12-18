import 'package:flutter/material.dart';
import '../services/storage_oreum_service.dart';
import 'oreum_navigation_screen.dart';

class StorageOreumDetailScreen extends StatefulWidget {
  final String oreumCode;
  final String oreumName;

  const StorageOreumDetailScreen({
    super.key,
    required this.oreumCode,
    required this.oreumName,
  });

  @override
  State<StorageOreumDetailScreen> createState() => _StorageOreumDetailScreenState();
}

class _StorageOreumDetailScreenState extends State<StorageOreumDetailScreen> {
  final StorageOreumService _service = StorageOreumService();
  Map<String, dynamic>? _geoJson;
  bool _isLoading = true;
  String? _error;

  // 파싱된 데이터
  List<Map<String, double>> _trailPath = [];
  List<Map<String, dynamic>> _waypoints = [];
  List<Map<String, dynamic>> _entrances = [];
  Map<String, dynamic>? _summit;

  // 등산로 정보
  String? _difficulty;
  double? _distanceKm;
  int? _upTime;
  int? _downTime;
  int? _totalTime;

  @override
  void initState() {
    super.initState();
    _loadOreumDetail();
  }

  Future<void> _loadOreumDetail() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final geoJson = await _service.getOreumGeoJson(widget.oreumCode);

      setState(() {
        _geoJson = geoJson;
        _trailPath = _service.getTrailPath(geoJson);
        _waypoints = _service.getWaypoints(geoJson);
        _entrances = _service.getEntrances(geoJson);
        _summit = _service.getSummit(geoJson);
        _extractTrailInfo(geoJson);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _extractTrailInfo(Map<String, dynamic> geoJson) {
    final features = geoJson['features'] as List?;
    if (features == null) return;

    for (var feature in features) {
      if (feature['geometry']['type'] == 'LineString') {
        final props = feature['properties'];
        _difficulty = props['PMNTN_DFFL'];
        _distanceKm = props['PMNTN_LT'];
        _upTime = props['PMNTN_UPPL'];
        _downTime = props['PMNTN_GODN'];
        _totalTime = (_upTime ?? 0) + (_downTime ?? 0);
        break;
      }
    }
  }

  Color _getDifficultyColor(String? difficulty) {
    switch (difficulty) {
      case '쉬움':
        return Colors.green;
      case '보통':
        return Colors.orange;
      case '어려움':
        return Colors.red;
      default:
        return Colors.grey;
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.oreumName),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOreumDetail,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('오류: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadOreumDetail,
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 지도 이미지
                      Image.network(
                        _service.getOreumMapUrl(widget.oreumCode),
                        width: double.infinity,
                        height: 300,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: double.infinity,
                            height: 300,
                            color: Colors.grey[300],
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image_not_supported, size: 64),
                                SizedBox(height: 8),
                                Text('지도 이미지를 불러올 수 없습니다'),
                              ],
                            ),
                          );
                        },
                      ),

                      // 등산로 정보
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        color: Colors.blue[50],
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '등산로 정보',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 16,
                              runSpacing: 8,
                              children: [
                                if (_difficulty != null)
                                  _buildInfoChip(
                                    '난이도',
                                    _difficulty!,
                                    _getDifficultyColor(_difficulty),
                                  ),
                                if (_distanceKm != null)
                                  _buildInfoChip(
                                    '거리',
                                    '${_distanceKm}km',
                                    Colors.blue,
                                  ),
                                if (_upTime != null)
                                  _buildInfoChip(
                                    '올라가는 시간',
                                    '$_upTime분',
                                    Colors.purple,
                                  ),
                                if (_downTime != null)
                                  _buildInfoChip(
                                    '내려오는 시간',
                                    '$_downTime분',
                                    Colors.purple,
                                  ),
                                if (_totalTime != null)
                                  _buildInfoChip(
                                    '총 소요시간',
                                    '$_totalTime분',
                                    Colors.deepPurple,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // 입구 정보
                      if (_entrances.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '입구 정보',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...(_entrances.map((entrance) => Card(
                                    child: ListTile(
                                      leading: Icon(
                                        _getWaypointIcon(entrance['type']),
                                        color: Colors.green,
                                      ),
                                      title: Text(entrance['name'] ?? entrance['type']),
                                      subtitle: entrance['description']?.isNotEmpty == true
                                          ? Text(entrance['description'])
                                          : null,
                                      trailing: const Icon(Icons.chevron_right),
                                      onTap: () {
                                        if (_geoJson != null) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => OreumNavigationScreen(
                                                oreumCode: widget.oreumCode,
                                                oreumName: widget.oreumName,
                                                geoJson: _geoJson!,
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ))),
                            ],
                          ),
                        ),

                      // 정상 정보
                      if (_summit != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '정상',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Card(
                                color: Colors.orange[50],
                                child: ListTile(
                                  leading: Icon(
                                    Icons.terrain,
                                    color: Colors.orange[700],
                                  ),
                                  title: Text(_summit!['name'] ?? _summit!['type']),
                                  subtitle: _summit!['description']?.isNotEmpty == true
                                      ? Text(_summit!['description'])
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 16),

                      // 주요 지점
                      if (_waypoints.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '주요 지점',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...(_waypoints.map((waypoint) {
                                // 입구와 정상은 이미 위에 표시했으므로 제외
                                final type = waypoint['type'] as String;
                                if (type.contains('시종점') ||
                                    type.contains('입구') ||
                                    type.contains('정상')) {
                                  return const SizedBox.shrink();
                                }

                                return Card(
                                  child: ListTile(
                                    leading: Icon(_getWaypointIcon(type)),
                                    title: Text(waypoint['name'] ?? type),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(type),
                                        if (waypoint['description']?.isNotEmpty == true)
                                          Text(waypoint['description']),
                                      ],
                                    ),
                                  ),
                                );
                              })),
                            ],
                          ),
                        ),

                      // 등산로 경로 정보
                      if (_trailPath.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '등산로 경로',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('총 ${_trailPath.length}개 좌표점'),
                                      const SizedBox(height: 8),
                                      Text(
                                        '시작: ${_trailPath.first['lat']?.toStringAsFixed(6)}, ${_trailPath.first['lng']?.toStringAsFixed(6)}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      Text(
                                        '종료: ${_trailPath.last['lat']?.toStringAsFixed(6)}, ${_trailPath.last['lng']?.toStringAsFixed(6)}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
      bottomNavigationBar: _isLoading || _error != null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (_geoJson != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OreumNavigationScreen(
                            oreumCode: widget.oreumCode,
                            oreumName: widget.oreumName,
                            geoJson: _geoJson!,
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.navigation),
                  label: const Text('등산 시작'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildInfoChip(String label, String value, Color color) {
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: color,
        child: const Icon(Icons.info, size: 16, color: Colors.white),
      ),
      label: Text('$label: $value'),
      backgroundColor: color.withOpacity(0.1),
    );
  }
}
