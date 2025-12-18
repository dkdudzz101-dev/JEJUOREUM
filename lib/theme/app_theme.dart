import 'package:flutter/material.dart';

class AppTheme {
  // PDF 디자인 기반 색상
  static const Color primaryBrown = Color(0xFFB8860B); // 골드/갈색 (버튼, 선택된 아이콘)
  static const Color stampGreen = Color(0xFF4A8B3F); // 스탬프 버튼 녹색
  static const Color backgroundWhite = Color(0xFFFAFAFA); // 배경
  static const Color cardWhite = Colors.white; // 카드 배경
  static const Color textBlack = Color(0xFF333333); // 기본 텍스트
  static const Color textGray = Color(0xFF666666); // 보조 텍스트
  static const Color dividerGray = Color(0xFFE0E0E0); // 구분선

  // 그림자
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 12,
      offset: const Offset(0, 2),
    ),
  ];

  // 라이트 테마
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: 'NanumGothic',
    scaffoldBackgroundColor: backgroundWhite,

    colorScheme: const ColorScheme.light(
      primary: primaryBrown,
      secondary: stampGreen,
      surface: cardWhite,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textBlack,
    ),

    // 앱바 테마
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: textBlack),
      titleTextStyle: TextStyle(
        color: textBlack,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        fontFamily: 'NanumGothic',
      ),
    ),

    // 카드 테마
    cardTheme: CardTheme(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: cardWhite,
      shadowColor: Colors.black.withOpacity(0.08),
    ),

    // 버튼 테마
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBrown,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'NanumGothic',
        ),
      ),
    ),

    // 텍스트 테마
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: textBlack,
        fontFamily: 'NanumGothic',
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: textBlack,
        fontFamily: 'NanumGothic',
      ),
      headlineSmall: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: textBlack,
        fontFamily: 'NanumGothic',
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textBlack,
        fontFamily: 'NanumGothic',
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textGray,
        fontFamily: 'NanumGothic',
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textGray,
        fontFamily: 'NanumGothic',
      ),
    ),

    // 입력 필드 테마
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: backgroundWhite,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: dividerGray),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: dividerGray),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryBrown, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );

  // 커스텀 스타일
  static BoxDecoration categoryCardDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(16),
    boxShadow: cardShadow,
  );

  static BoxDecoration mainCardDecoration = BoxDecoration(
    color: cardWhite,
    borderRadius: BorderRadius.circular(16),
    boxShadow: cardShadow,
  );

  // 스탬프 버튼 스타일
  static ButtonStyle stampButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: stampGreen,
    foregroundColor: Colors.white,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  );
}
