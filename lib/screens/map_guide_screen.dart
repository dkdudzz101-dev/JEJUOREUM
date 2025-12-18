import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

class MapGuideScreen extends StatefulWidget {
  final String oreumName;
  final double lat;
  final double lng;

  const MapGuideScreen({
    super.key,
    required this.oreumName,
    required this.lat,
    required this.lng,
  });

  @override
  State<MapGuideScreen> createState() => _MapGuideScreenState();
}

class _MapGuideScreenState extends State<MapGuideScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    final kakaoMapUrl = 'https://map.kakao.com/link/map/${widget.oreumName},${widget.lat},${widget.lng}';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(kakaoMapUrl));
  }

  Future<void> _openKakaoNavigation() async {
    final kakaoMapUrl = 'kakaomap://route?ep=${widget.lat},${widget.lng}&by=FOOT';
    final webUrl = 'https://map.kakao.com/link/to/${widget.oreumName},${widget.lat},${widget.lng}';

    try {
      final kakaoUri = Uri.parse(kakaoMapUrl);
      if (await canLaunchUrl(kakaoUri)) {
        await launchUrl(kakaoUri, mode: LaunchMode.externalApplication);
      } else {
        final webUri = Uri.parse(webUrl);
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('카카오맵 열기 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('카카오맵을 열 수 없습니다')),
        );
      }
    }
  }

  Future<void> _openGoogleNavigation() async {
    final googleMapUrl = 'https://www.google.com/maps/dir/?api=1&destination=${widget.lat},${widget.lng}&travelmode=walking';

    try {
      final uri = Uri.parse(googleMapUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('구글맵 열기 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('구글맵을 열 수 없습니다')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textBlack),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.oreumName,
          style: const TextStyle(
            color: AppTheme.textBlack,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // 웹뷰
          WebViewWidget(controller: _controller),

          // 로딩 인디케이터
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),

          // 하단 버튼들
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '길안내 시작',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textGray.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // 카카오맵 버튼
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _openKakaoNavigation,
                            icon: const Icon(Icons.navigation, size: 20),
                            label: const Text(
                              '카카오맵',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFEE500),
                              foregroundColor: const Color(0xFF3C1E1E),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // 구글맵 버튼
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _openGoogleNavigation,
                            icon: const Icon(Icons.navigation, size: 20),
                            label: const Text(
                              '구글맵',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4285F4),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
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
}
