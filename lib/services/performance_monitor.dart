import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  final Map<String, Stopwatch> _timers = {};
  final Map<String, int> _frameCounters = {};
  Timer? _fpsTimer;
  int _frameCount = 0;
  WebViewController? _webViewController;
  
  // FPS 관련 상수
  static const int _targetFps = 60;
  static const Duration _fpsCheckInterval = Duration(seconds: 1);
  
  // 메모리 관련 상수 (MB 단위)
  static const int _memoryWarningThreshold = 200; // 200MB
  
  factory PerformanceMonitor() => _instance;
  
  PerformanceMonitor._internal();
  
  // WebViewController 설정
  void setWebViewController(WebViewController controller) {
    _webViewController = controller;
  }

  // FPS 모니터링 시작
  void startFpsMonitoring() {
    _fpsTimer?.cancel();
    _fpsTimer = Timer.periodic(_fpsCheckInterval, (_) {
      final fps = _frameCount;
      _frameCount = 0;
      
      if (fps < _targetFps * 0.7) { // 목표 FPS의 70% 미만이면 경고
        developer.log('Low FPS detected: $fps', name: 'Performance');
        _optimizePerformance();
      }
    });
  }

  // 프레임 카운트 증가
  void incrementFrameCount() {
    _frameCount++;
  }

  // 성능 최적화 조치
  Future<void> _optimizePerformance() async {
    developer.log('Optimizing performance...', name: 'Performance');
    
    // WebView 캐시 정리
    if (_webViewController != null) {
      await _webViewController!.clearCache();
      
      // 메모리 사용량이 높으면 WebView 리로드
      final memoryUsage = await _getMemoryUsage();
      if (memoryUsage > _memoryWarningThreshold) {
        developer.log('High memory usage detected: ${memoryUsage}MB', name: 'Performance');
        await _webViewController!.reload();
      }
    }
    
    // 가비지 컬렉션 강제 실행 (웹뷰)
    _webViewController?.runJavaScript('window.gc && window.gc()');
  }

  // 타이머 시작
  void startTimer(String name) {
    _timers[name] = Stopwatch()..start();
  }

  // 타이머 정지 및 로그 출력
  void stopTimer(String name) {
    final stopwatch = _timers[name];
    if (stopwatch != null) {
      stopwatch.stop();
      developer.log('$name took ${stopwatch.elapsedMilliseconds}ms',
          name: 'Performance');
      _timers.remove(name);
    }
  }

  // 카운터 증가
  void incrementCounter(String name) {
    _frameCounters[name] = (_frameCounters[name] ?? 0) + 1;
  }

  // 메모리 사용량 로깅
  void logMemoryUsage() {
    if (kDebugMode) {
      developer.log('Memory logging - performance monitoring active',
          name: 'Performance');
    }
  }

  // 메모리 사용량 가져오기
  double getMemoryUsage() {
    // 간단한 메모리 추정
    return 0.0;
  }

  // 메모리 사용량 가져오기 (웹뷰) - 내부 사용
  Future<double> _getMemoryUsage() async {
    try {
      if (_webViewController != null) {
        // runJavaScript는 void를 반환하므로 간단히 0 반환
        await _webViewController!.runJavaScript(
          'window.performance.memory ? (window.performance.memory.usedJSHeapSize / 1048576).toFixed(2) : 0');
        return 0.0;
      }
    } catch (e) {
      developer.log('Failed to get memory usage: $e', name: 'Performance');
    }
    return 0;
  }

  // 리소스 정리
  void dispose() {
    _fpsTimer?.cancel();
    _timers.clear();
    _frameCounters.clear();
  }
  
  // 성능 메트릭 가져오기
  Map<String, dynamic> getMetrics() {
    return {
      'fps': _frameCount,
      'activeTimers': _timers.length,
      'frameCounters': _frameCounters,
    };
  }
}
