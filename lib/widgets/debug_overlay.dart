import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/performance_monitor.dart';
import '../services/navigation_provider.dart';

class DebugOverlay extends StatefulWidget {
  final Widget child;
  final bool showOverlay;
  final bool showPerformanceMetrics;
  final bool showWebViewInfo;
  final bool showNavigationState;
  final bool showFpsMeter;

  const DebugOverlay({
    Key? key,
    required this.child,
    this.showOverlay = kDebugMode,
    this.showPerformanceMetrics = true,
    this.showWebViewInfo = true,
    this.showNavigationState = true,
    this.showFpsMeter = true,
  }) : super(key: key);

  @override
  _DebugOverlayState createState() => _DebugOverlayState();

  static void toggle(BuildContext context) {
    final state = context.findAncestorStateOfType<_DebugOverlayState>();
    state?.toggleOverlay();
  }
}

class _DebugOverlayState extends State<DebugOverlay> with SingleTickerProviderStateMixin {
  bool _showPanel = false;
  bool _isMinimized = true;
  late AnimationController _animationController;
  final PerformanceMonitor _performanceMonitor = PerformanceMonitor();
  WebViewController? _webViewController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // 성능 모니터링 시작
    if (widget.showOverlay && widget.showFpsMeter) {
      _performanceMonitor.startFpsMonitoring();
      
      // 1초마다 화면 갱신
      _performanceMonitor.startTimer('debug_overlay');
      
      // 5초마다 메모리 사용량 로깅
      Timer.periodic(const Duration(seconds: 5), (_) {
        _performanceMonitor.logMemoryUsage();
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _performanceMonitor.stopTimer('debug_overlay');
    _performanceMonitor.dispose();
    super.dispose();
  }

  void toggleOverlay() {
    setState(() {
      _showPanel = !_showPanel;
      if (_showPanel) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void toggleMinimize() {
    setState(() {
      _isMinimized = !_isMinimized;
    });
  }

  void setWebViewController(WebViewController controller) {
    _webViewController = controller;
    _performanceMonitor.setWebViewController(controller);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showOverlay) {
      return widget.child;
    }

    return Stack(
      children: [
        // 메인 콘텐츠
        widget.child,

        // 디버그 패널 토글 버튼
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.small(
            heroTag: 'debug_toggle',
            onPressed: toggleOverlay,
            backgroundColor: Colors.blue,
            child: const Icon(Icons.bug_report, color: Colors.white),
          ),
        ),

        // 디버그 패널
        if (_showPanel)
          Positioned.fill(
            child: GestureDetector(
              onTap: toggleMinimize,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  final height = MediaQuery.of(context).size.height * 0.6 * _animationController.value;
                  return Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: _isMinimized ? 40 : height,
                    child: child!,
                  );
                },
                child: Material(
                  color: Colors.black87,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 헤더 바
                      _buildHeader(),
                      
                      // 컨텐츠 영역
                      if (!_isMinimized) Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (widget.showPerformanceMetrics) _buildPerformanceSection(),
                              if (widget.showNavigationState) _buildNavigationStateSection(),
                              if (widget.showWebViewInfo) _buildWebViewInfoSection(),
                              const SizedBox(height: 16),
                              _buildActionButtons(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Colors.black,
      child: Row(
        children: [
          const Icon(Icons.bug_report, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          const Text(
            '디버그 패널',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              _isMinimized ? Icons.expand_less : Icons.expand_more,
              color: Colors.white,
              size: 20,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: toggleMinimize,
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: toggleOverlay,
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceSection() {
    return Consumer<NavigationProvider>(
      builder: (context, provider, _) {
        return Card(
          color: Colors.black54,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '성능 메트릭',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Divider(color: Colors.white24),
                _buildMetricRow('FPS', '${_performanceMonitor.getMetrics()['fps']}'),
                _buildMetricRow('메모리 사용량', '${_performanceMonitor.getMemoryUsage().toStringAsFixed(2)} MB'),
                _buildMetricRow('GPS 상태', provider.isWeakGpsSignal ? '신호 약함' : '정상'),
                _buildMetricRow('네트워크', provider.isOnline ? '온라인' : '오프라인'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavigationStateSection() {
    return Consumer<NavigationProvider>(
      builder: (context, provider, _) {
        return Card(
          color: Colors.black54,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '내비게이션 상태',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Divider(color: Colors.white24),
                _buildMetricRow('상태', provider.isNavigating ? '내비게이션 중' : '정지'),
                if (provider.currentPosition != null) ...[
                  _buildMetricRow('위도', provider.currentPosition!.latitude.toStringAsFixed(6)),
                  _buildMetricRow('경도', provider.currentPosition!.longitude.toStringAsFixed(6)),
                ],
                if (provider.remainingDistance != null)
                  _buildMetricRow('남은 거리', '${provider.remainingDistance!.toStringAsFixed(2)} km'),
                if (provider.remainingTime != null)
                  _buildMetricRow('예상 시간', '${provider.remainingTime} 분'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWebViewInfoSection() {
    return Card(
      color: Colors.black54,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '웹뷰 정보',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const Divider(color: Colors.white24),
            _buildMetricRow('WebView 상태', _webViewController != null ? '로드됨' : '로드 안됨'),
            if (_webViewController != null) ...[
              _buildMetricRow('URL', 'Map View'),
              _buildMetricRow('JavaScript', '활성화됨'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('새로고침'),
          onPressed: () {
            _webViewController?.reload();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('웹뷰를 새로고침합니다.')),
            );
          },
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.cleaning_services, size: 16),
          label: const Text('캐시 정리'),
          onPressed: () async {
            await _webViewController?.clearCache();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('캐시가 정리되었습니다.')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          const Text(':', style: TextStyle(color: Colors.white54)),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
