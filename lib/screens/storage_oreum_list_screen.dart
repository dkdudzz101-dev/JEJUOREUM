import 'package:flutter/material.dart';
import '../services/storage_oreum_service.dart';
import 'storage_oreum_detail_screen.dart';

class StorageOreumListScreen extends StatefulWidget {
  const StorageOreumListScreen({super.key});

  @override
  State<StorageOreumListScreen> createState() => _StorageOreumListScreenState();
}

class _StorageOreumListScreenState extends State<StorageOreumListScreen> {
  final StorageOreumService _service = StorageOreumService();
  List<Map<String, dynamic>> _oreums = [];
  List<Map<String, dynamic>> _filteredOreums = [];
  bool _isLoading = true;
  String? _error;

  // 필터 상태
  String? _selectedDifficulty;
  double? _maxDistance;
  int? _maxTime;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadOreums();
  }

  Future<void> _loadOreums() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final oreums = await _service.getAllOreums();

      setState(() {
        _oreums = oreums;
        _filteredOreums = oreums;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredOreums = _oreums.where((oreum) {
        // 난이도 필터
        if (_selectedDifficulty != null && oreum['difficulty'] != _selectedDifficulty) {
          return false;
        }

        // 거리 필터
        if (_maxDistance != null) {
          final distance = oreum['distance_km'];
          if (distance == null || distance > _maxDistance!) {
            return false;
          }
        }

        // 시간 필터
        if (_maxTime != null) {
          final time = oreum['total_time'];
          if (time == null || time > _maxTime!) {
            return false;
          }
        }

        // 검색어 필터
        if (_searchQuery.isNotEmpty) {
          final name = oreum['oreum_name']?.toString().toLowerCase() ?? '';
          if (!name.contains(_searchQuery.toLowerCase())) {
            return false;
          }
        }

        return true;
      }).toList();
    });
  }

  void _resetFilters() {
    setState(() {
      _selectedDifficulty = null;
      _maxDistance = null;
      _maxTime = null;
      _searchQuery = '';
      _filteredOreums = _oreums;
    });
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

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('필터'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 난이도
                const Text('난이도', style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 8,
                  children: ['쉬움', '보통', '어려움'].map((diff) {
                    return ChoiceChip(
                      label: Text(diff),
                      selected: _selectedDifficulty == diff,
                      onSelected: (selected) {
                        setDialogState(() {
                          _selectedDifficulty = selected ? diff : null;
                        });
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // 거리
                const Text('최대 거리', style: TextStyle(fontWeight: FontWeight.bold)),
                Slider(
                  value: _maxDistance ?? 10.0,
                  min: 1.0,
                  max: 10.0,
                  divisions: 9,
                  label: _maxDistance != null ? '${_maxDistance!.toStringAsFixed(1)}km' : '제한 없음',
                  onChanged: (value) {
                    setDialogState(() {
                      _maxDistance = value;
                    });
                  },
                ),
                Text(_maxDistance != null ? '${_maxDistance!.toStringAsFixed(1)}km 이하' : '제한 없음'),

                const SizedBox(height: 16),

                // 소요시간
                const Text('최대 시간', style: TextStyle(fontWeight: FontWeight.bold)),
                Slider(
                  value: (_maxTime ?? 180).toDouble(),
                  min: 30,
                  max: 180,
                  divisions: 15,
                  label: _maxTime != null ? '${_maxTime}분' : '제한 없음',
                  onChanged: (value) {
                    setDialogState(() {
                      _maxTime = value.toInt();
                    });
                  },
                ),
                Text(_maxTime != null ? '$_maxTime분 이하' : '제한 없음'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _resetFilters();
                Navigator.pop(context);
              },
              child: const Text('초기화'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                _applyFilters();
                Navigator.pop(context);
              },
              child: const Text('적용'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('제주 오름'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOreums,
          ),
        ],
      ),
      body: Column(
        children: [
          // 검색 바
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: '오름 이름 검색',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                          _applyFilters();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                _applyFilters();
              },
            ),
          ),

          // 필터 칩
          if (_selectedDifficulty != null || _maxDistance != null || _maxTime != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 8,
                children: [
                  if (_selectedDifficulty != null)
                    Chip(
                      label: Text('난이도: $_selectedDifficulty'),
                      onDeleted: () {
                        setState(() {
                          _selectedDifficulty = null;
                        });
                        _applyFilters();
                      },
                    ),
                  if (_maxDistance != null)
                    Chip(
                      label: Text('${_maxDistance!.toStringAsFixed(1)}km 이하'),
                      onDeleted: () {
                        setState(() {
                          _maxDistance = null;
                        });
                        _applyFilters();
                      },
                    ),
                  if (_maxTime != null)
                    Chip(
                      label: Text('$_maxTime분 이하'),
                      onDeleted: () {
                        setState(() {
                          _maxTime = null;
                        });
                        _applyFilters();
                      },
                    ),
                ],
              ),
            ),

          // 목록 개수
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Text(
                  '총 ${_filteredOreums.length}개 오름',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_filteredOreums.length != _oreums.length)
                  Text(
                    ' (전체: ${_oreums.length}개)',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ),

          // 오름 목록
          Expanded(
            child: _isLoading
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
                              onPressed: _loadOreums,
                              child: const Text('다시 시도'),
                            ),
                          ],
                        ),
                      )
                    : _filteredOreums.isEmpty
                        ? const Center(
                            child: Text('검색 결과가 없습니다'),
                          )
                        : ListView.builder(
                            itemCount: _filteredOreums.length,
                            itemBuilder: (context, index) {
                              final oreum = _filteredOreums[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: ListTile(
                                  title: Text(
                                    oreum['oreum_name'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          if (oreum['difficulty'] != null) ...[
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: _getDifficultyColor(
                                                  oreum['difficulty'],
                                                ),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                oreum['difficulty'],
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                          if (oreum['distance_km'] != null)
                                            Text('${oreum['distance_km']}km'),
                                          if (oreum['total_time'] != null) ...[
                                            const SizedBox(width: 8),
                                            Text('${oreum['total_time']}분'),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => StorageOreumDetailScreen(
                                          oreumCode: oreum['oreum_code'],
                                          oreumName: oreum['oreum_name'],
                                        ),
                                      ),
                                    );
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
}
