import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:provider/provider.dart' as provider_pkg;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import 'services/navigation_provider.dart';
import 'services/profile_provider.dart';
import 'services/performance_monitor.dart';
import 'services/offline_map_service.dart';
import 'services/accessibility_service.dart';
import 'theme/app_theme.dart';
import 'screens/main_tab_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 카카오 SDK 초기화
  KakaoSdk.init(nativeAppKey: 'd94b9901b54787d2d3a54a2bff0c9584');

  // Supabase 초기화
  await Supabase.initialize(
    url: 'https://cpnoyaaccshtfncmefet.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNwbm95YWFjY3NodGZuY21lZmV0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc4OTY5MzEsImV4cCI6MjA3MzQ3MjkzMX0.niFyhmDQf4u6wiPq5m6xGeBbWzaxCpTHjsRJuqwdI64',
  );

  // 웹뷰 플랫폼 설정
  if (defaultTargetPlatform == TargetPlatform.android) {
    WebViewPlatform.instance = AndroidWebViewPlatform();
  } else if (defaultTargetPlatform == TargetPlatform.iOS) {
    WebViewPlatform.instance = WebKitWebViewPlatform();
  }

  // 서비스 초기화
  final navigationProvider = NavigationProvider();
  final profileProvider = ProfileProvider();
  final performanceMonitor = PerformanceMonitor();
  final offlineMapService = OfflineMapService();
  final accessibilityService = AccessibilityService();

  runApp(
    provider_pkg.MultiProvider(
      providers: [
        provider_pkg.ChangeNotifierProvider.value(value: navigationProvider),
        provider_pkg.ChangeNotifierProvider.value(value: profileProvider),
        provider_pkg.Provider.value(value: performanceMonitor),
        provider_pkg.Provider.value(value: offlineMapService),
        provider_pkg.Provider.value(value: accessibilityService),
      ],
      child: const JejuOreumApp(),
    ),
  );
}

class JejuOreumApp extends StatelessWidget {
  const JejuOreumApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 상태바 색상 설정
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );

    return MaterialApp(
      title: '제주오름',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const MainTabScreen(),
      // 라우트 설정
      routes: {
        // 향후 추가할 라우트들
      },
      builder: (context, child) {
        // 전역 설정 적용
        return Listener(
          onPointerDown: (_) {
            // 터치 이벤트 발생 시 포커스 해제
            final currentFocus = FocusScope.of(context);
            if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
              currentFocus.focusedChild?.unfocus();
            }
          },
          child: child!,
        );
      },
    );
  }
}
