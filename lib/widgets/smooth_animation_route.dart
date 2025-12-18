import 'package:flutter/material.dart';

/// 부드러운 페이지 전환을 위한 커스텀 라우트
class SmoothAnimationRoute<T> extends PageRoute<T> {
  /// 전환할 위젯을 빌드하는 빌더
  final WidgetBuilder builder;
  
  /// 전환 지속 시간
  final Duration duration;
  
  /// 전환 애니메이션 커브
  final Curve curve;
  
  /// 불투명도 전환 여부
  final bool opaque;
  
  /// 배경색
  final Color? barrierColor;
  
  /// 배경색 레이블
  final String? barrierLabel;
  
  /// 상태 유지 여부
  final bool maintainState;

  SmoothAnimationRoute({
    required this.builder,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    this.opaque = true,
    this.barrierColor,
    this.barrierLabel,
    this.maintainState = true,
    RouteSettings? settings,
  }) : super(settings: settings, fullscreenDialog: false);

  @override
  Duration get transitionDuration => duration;

  @override
  bool get barrierDismissible => false;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // 현재 경로와 새 경로의 설정 가져오기
    final route = ModalRoute.of(context);
    
    // 현재 화면이 전체 화면 대화상자인지 확인
    final bool isDialog = route is PageRoute && route.fullscreenDialog;

    // 화면 전환 애니메이션
    return SlideTransition(
      position: Tween<Offset>(
        begin: isDialog ? const Offset(0.0, 0.1) : const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: curve,
      )),
      child: FadeTransition(
        opacity: Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Interval(0.0, 0.5, curve: curve),
        )),
        child: child,
      ),
    );
  }
}

/// 내비게이션 확장 메서드
extension NavigatorExtensions on NavigatorState {
  /// 부드러운 전환으로 화면 이동
  Future<T?> pushSmooth<T extends Object?>({
    required BuildContext context,
    required WidgetBuilder builder,
    RouteSettings? settings,
    bool fullscreenDialog = false,
    Duration? duration,
    Curve? curve,
  }) {
    return Navigator.of(context).push<T>(
      SmoothAnimationRoute<T>(
        builder: builder,
        settings: settings,
        duration: duration ?? const Duration(milliseconds: 300),
        curve: curve ?? Curves.easeInOut,
        opaque: !fullscreenDialog,
        barrierColor: fullscreenDialog ? Colors.black54 : null,
      ),
    );
  }
  
  /// 대화상자 스타일의 부드러운 전환으로 화면 이동
  Future<T?> pushDialogSmooth<T extends Object?>({
    required BuildContext context,
    required WidgetBuilder builder,
    RouteSettings? settings,
    bool barrierDismissible = true,
    Color? barrierColor = Colors.black54,
    String? barrierLabel,
    bool useSafeArea = true,
    bool useRootNavigator = true,
    RouteSettings? routeSettings,
    Offset? anchorPoint,
  }) {
    return Navigator.of(context, rootNavigator: useRootNavigator).push<T>(
      _SmoothDialogRoute<T>(
        builder: builder,
        barrierDismissible: barrierDismissible,
        barrierColor: barrierColor,
        barrierLabel: barrierLabel,
        settings: routeSettings,
        anchorPoint: anchorPoint,
      ),
    );
  }
}

/// 부드러운 다이얼로그 전환을 위한 커스텀 라우트
class _SmoothDialogRoute<T> extends PopupRoute<T> {
  _SmoothDialogRoute({
    required this.builder,
    this.barrierDismissible = true,
    this.barrierColor = const Color(0x80000000),
    this.barrierLabel,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.transitionBuilder,
    RouteSettings? settings,
    this.anchorPoint,
  }) : super(settings: settings);

  final WidgetBuilder builder;
  final bool barrierDismissible;
  final String? barrierLabel;
  final Offset? anchorPoint;

  @override
  final Duration transitionDuration;

  @override
  final Color? barrierColor;

  final RouteTransitionsBuilder? transitionBuilder;

  @override
  Animation<double> createAnimation() {
    return CurvedAnimation(
      parent: super.createAnimation(),
      curve: Curves.easeInOut,
      reverseCurve: Curves.easeInOut.flipped,
    );
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: builder(context),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (transitionBuilder == null) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        ),
        child: ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
          ),
          child: child,
        ),
      );
    }
    
    return transitionBuilder!(context, animation, secondaryAnimation, child);
  }
}
