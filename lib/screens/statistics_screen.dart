import 'package:flutter/material.dart';
import '../services/hiking_record_service.dart';
import '../models/hiking_record.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final HikingRecordService _service = HikingRecordService();
  HikingStatistics? _statistics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final stats = await _service.getStatistics();
      setState(() {
        _statistics = stats;
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
        title: const Text('통계 & 업적'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStatistics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _statistics == null
              ? const Center(child: Text('통계를 불러올 수 없습니다'))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 전체 통계
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue[700]!, Colors.blue[500]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '나의 등산 기록',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildOverallStatItem(
                                    '총 등산',
                                    '${_statistics!.totalHikes}회',
                                  ),
                                ),
                                Expanded(
                                  child: _buildOverallStatItem(
                                    '완료',
                                    '${_statistics!.completedHikes}회',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildOverallStatItem(
                                    '총 거리',
                                    '${_statistics!.totalDistance.toStringAsFixed(1)}km',
                                  ),
                                ),
                                Expanded(
                                  child: _buildOverallStatItem(
                                    '총 시간',
                                    '${(_statistics!.totalTime / 60).toStringAsFixed(1)}시간',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 상세 통계
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '상세 통계',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDetailStatCard(
                                    Icons.location_on,
                                    '다녀온 오름',
                                    '${_statistics!.uniqueOreums}',
                                    Colors.green,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildDetailStatCard(
                                    Icons.height,
                                    '최고 고도',
                                    '${_statistics!.maxAltitude.toStringAsFixed(0)}m',
                                    Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDetailStatCard(
                                    Icons.speed,
                                    '평균 거리',
                                    _statistics!.totalHikes > 0
                                        ? '${(_statistics!.totalDistance / _statistics!.totalHikes).toStringAsFixed(2)}km'
                                        : '0km',
                                    Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildDetailStatCard(
                                    Icons.timer,
                                    '평균 시간',
                                    _statistics!.totalHikes > 0
                                        ? '${(_statistics!.totalTime / _statistics!.totalHikes).toStringAsFixed(0)}분'
                                        : '0분',
                                    Colors.purple,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // 업적
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '업적',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_statistics!.achievements.where((a) => a.isUnlocked).length}/${_statistics!.achievements.length} 달성',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 16),
                            ..._buildAchievementsList(_statistics!.achievements),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }

  Widget _buildOverallStatItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailStatCard(IconData icon, String label, String value, Color color) {
    return Card(
      elevation: 2,
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
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAchievementsList(List<Achievement> achievements) {
    return achievements.map((achievement) {
      final isUnlocked = achievement.isUnlocked;

      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        color: isUnlocked ? Colors.amber[50] : Colors.grey[100],
        child: ListTile(
          leading: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isUnlocked ? Colors.amber : Colors.grey[300],
            ),
            child: Icon(
              _getAchievementIcon(achievement.iconName),
              color: isUnlocked ? Colors.white : Colors.grey[600],
              size: 28,
            ),
          ),
          title: Text(
            achievement.title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isUnlocked ? Colors.black : Colors.grey[600],
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                achievement.description,
                style: TextStyle(
                  color: isUnlocked ? Colors.grey[700] : Colors.grey[500],
                ),
              ),
              if (isUnlocked && achievement.unlockedAt != null) ...[
                const SizedBox(height: 4),
                Text(
                  '달성일: ${_formatDate(achievement.unlockedAt!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
          trailing: isUnlocked
              ? const Icon(Icons.check_circle, color: Colors.amber, size: 32)
              : Icon(Icons.lock, color: Colors.grey[400], size: 32),
        ),
      );
    }).toList();
  }

  IconData _getAchievementIcon(String iconName) {
    switch (iconName) {
      case 'hiking':
        return Icons.hiking;
      case 'terrain':
        return Icons.terrain;
      case 'star':
        return Icons.star;
      case 'military_tech':
        return Icons.military_tech;
      case 'emoji_events':
        return Icons.emoji_events;
      case 'directions_walk':
        return Icons.directions_walk;
      case 'directions_run':
        return Icons.directions_run;
      case 'rocket_launch':
        return Icons.rocket_launch;
      case 'explore':
        return Icons.explore;
      case 'collections':
        return Icons.collections;
      default:
        return Icons.star;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}
