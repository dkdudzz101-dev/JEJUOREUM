import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/hiking_record_service.dart';
import '../models/hiking_record.dart';
import 'hiking_record_detail_screen.dart';

class HikingHistoryScreen extends StatefulWidget {
  const HikingHistoryScreen({super.key});

  @override
  State<HikingHistoryScreen> createState() => _HikingHistoryScreenState();
}

class _HikingHistoryScreenState extends State<HikingHistoryScreen> {
  final HikingRecordService _service = HikingRecordService();
  List<HikingRecord> _records = [];
  bool _isLoading = true;
  bool _showCompletedOnly = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final records = _showCompletedOnly
          ? await _service.getCompletedRecords()
          : await _service.getAllRecords();

      setState(() {
        _records = records;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('등산 기록'),
        actions: [
          IconButton(
            icon: Icon(_showCompletedOnly ? Icons.check_circle : Icons.list),
            tooltip: _showCompletedOnly ? '전체 보기' : '완료만 보기',
            onPressed: () {
              setState(() {
                _showCompletedOnly = !_showCompletedOnly;
              });
              _loadRecords();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRecords,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.hiking,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '등산 기록이 없습니다',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '오름을 등반하고 기록을 남겨보세요!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _records.length,
                  itemBuilder: (context, index) {
                    final record = _records[index];
                    return _buildRecordCard(record);
                  },
                ),
    );
  }

  Widget _buildRecordCard(HikingRecord record) {
    final dateFormat = DateFormat('yyyy년 MM월 dd일 HH:mm');
    final duration = record.endTime != null
        ? record.endTime!.difference(record.startTime)
        : Duration.zero;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HikingRecordDetailScreen(record: record),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Container(
              padding: const EdgeInsets.all(16),
              color: record.completed ? Colors.green[50] : Colors.orange[50],
              child: Row(
                children: [
                  Icon(
                    record.completed ? Icons.check_circle : Icons.access_time,
                    color: record.completed ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.oreumName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateFormat.format(record.startTime),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (record.photoUrls.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.photo, size: 16, color: Colors.blue),
                          const SizedBox(width: 4),
                          Text(
                            '${record.photoUrls.length}',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // 통계
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      Icons.directions_walk,
                      '거리',
                      '${record.totalDistance.toStringAsFixed(2)}km',
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      Icons.timer,
                      '시간',
                      '${record.totalTime}분',
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      Icons.height,
                      '최고 고도',
                      '${record.maxAltitude.toStringAsFixed(0)}m',
                    ),
                  ),
                ],
              ),
            ),

            // 사진 미리보기
            if (record.photoUrls.isNotEmpty)
              Container(
                height: 100,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: record.photoUrls.length.clamp(0, 5),
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: NetworkImage(record.photoUrls[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
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
    );
  }
}
