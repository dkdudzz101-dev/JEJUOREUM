import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/hiking_record.dart';

class HikingRecordDetailScreen extends StatelessWidget {
  final HikingRecord record;

  const HikingRecordDetailScreen({
    super.key,
    required this.record,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy년 MM월 dd일 HH:mm');
    final duration = record.endTime != null
        ? record.endTime!.difference(record.startTime)
        : Duration.zero;

    return Scaffold(
      appBar: AppBar(
        title: Text(record.oreumName),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareRecord(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 지도
            if (record.trackingPoints.isNotEmpty)
              SizedBox(
                height: 300,
                child: FlutterMap(
                  options: MapOptions(
                    center: LatLng(
                      record.trackingPoints.first.latitude,
                      record.trackingPoints.first.longitude,
                    ),
                    zoom: 14,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.jeju_oreum',
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: record.trackingPoints
                              .map((p) => LatLng(p.latitude, p.longitude))
                              .toList(),
                          strokeWidth: 3,
                          color: Colors.blue,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        // 시작점
                        Marker(
                          point: LatLng(
                            record.trackingPoints.first.latitude,
                            record.trackingPoints.first.longitude,
                          ),
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.play_circle,
                            color: Colors.green,
                            size: 32,
                          ),
                        ),
                        // 종료점
                        Marker(
                          point: LatLng(
                            record.trackingPoints.last.latitude,
                            record.trackingPoints.last.longitude,
                          ),
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.flag,
                            color: Colors.red,
                            size: 32,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // 기본 정보
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: Colors.blue[50],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        record.completed ? Icons.check_circle : Icons.access_time,
                        color: record.completed ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        record.completed ? '완료' : '진행 중',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: record.completed ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '시작: ${dateFormat.format(record.startTime)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  if (record.endTime != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '종료: ${dateFormat.format(record.endTime!)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ],
              ),
            ),

            // 통계
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '등산 통계',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          Icons.directions_walk,
                          '총 거리',
                          '${record.totalDistance.toStringAsFixed(2)} km',
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          Icons.timer,
                          '소요 시간',
                          '${record.totalTime} 분',
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          Icons.trending_up,
                          '최고 고도',
                          '${record.maxAltitude.toStringAsFixed(0)} m',
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          Icons.trending_down,
                          '최저 고도',
                          '${record.minAltitude.toStringAsFixed(0)} m',
                          Colors.purple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildStatCard(
                    Icons.route,
                    '기록된 위치 점',
                    '${record.trackingPoints.length} 개',
                    Colors.teal,
                  ),
                ],
              ),
            ),

            // 사진
            if (record.photoUrls.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '사진',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: record.photoUrls.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            _showPhotoDialog(context, record.photoUrls[index]);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: NetworkImage(record.photoUrls[index]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String label, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showPhotoDialog(BuildContext context, String photoUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Stack(
          children: [
            Image.network(photoUrl),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _shareRecord() {
    final text = '''
${record.oreumName} 등산 완료!

📍 거리: ${record.totalDistance.toStringAsFixed(2)}km
⏱️ 시간: ${record.totalTime}분
⛰️ 최고 고도: ${record.maxAltitude.toStringAsFixed(0)}m

제주 오름 앱으로 기록했습니다.
''';

    Share.share(text);
  }
}
