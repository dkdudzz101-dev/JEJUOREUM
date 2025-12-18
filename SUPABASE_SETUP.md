# Supabase 연동 완료

## ✅ 완료된 작업

### 1. 데이터베이스 (Supabase)
- **286개 오름** 데이터 업로드 완료
- **895개 등산로** (고도 포함) 업로드 완료
- **1,192개 포인트** (입구, 분기점) 업로드 완료

### 2. Flutter 프로젝트 반영

#### 생성된 파일:
```
lib/
├── config/
│   └── supabase_config.dart        # Supabase 설정
├── models/
│   ├── oreum_model.dart            # 오름 모델
│   ├── trail_model.dart            # 등산로 모델
│   └── point_model.dart            # 포인트 모델
├── services/
│   └── oreum_service.dart          # 오름 데이터 서비스
└── screens/
    └── oreum_list_screen.dart      # 오름 목록 화면 (테스트용)
```

## 🚀 사용 방법

### 1. 오름 목록 가져오기
```dart
final oreumService = OreumService();
final oreums = await oreumService.getAllOreums();
```

### 2. 난이도별 필터링
```dart
final easyOreums = await oreumService.getOreumsByDifficulty('쉬움');
```

### 3. 오름 검색
```dart
final results = await oreumService.searchOreums('가마');
```

### 4. 특정 오름 상세 정보
```dart
final detail = await oreumService.getOreumDetail(1);
// detail['oreum'] - 오름 정보
// detail['trails'] - 등산로 목록
// detail['points'] - 포인트 목록
```

### 5. 근처 오름 찾기
```dart
final nearbyOreums = await oreumService.getNearbyOreums(
  33.3, 126.5, 10.0  // 위도, 경도, 반경(km)
);
```

## 📊 데이터 구조

### Oreum (오름)
- id, name, folder
- summit_lng, summit_lat, summit_elevation (정상 좌표/고도)
- entrance_lng, entrance_lat (입구 좌표)
- distance_km (거리)
- elev_diff_m (고도차)
- difficulty (쉬움/보통/어려움)
- color (난이도별 색상: #4CAF50, #FFC107, #F44336)

### Trail (등산로)
- id, oreum_id
- trail_name (코스명)
- geojson (경로 LineString, 고도 포함)
- length_m (길이)

### TrailPoint (포인트)
- id, oreum_id
- point_type (시종점/분기점)
- lng, lat (좌표)
- elevation (고도)

## 🎨 난이도별 색상

- 🟢 **쉬움** (144개): #4CAF50 (초록)
- 🟡 **보통** (124개): #FFC107 (노랑)
- 🔴 **어려움** (18개): #F44336 (빨강)

## 🧪 테스트 방법

main.dart를 수정해서 테스트 화면 실행:

```dart
// lib/main.dart
home: const OreumListScreen(), // 테스트용
```

그리고 실행:
```bash
flutter run
```

## 📱 다음 단계

1. ✅ Supabase 연동 완료
2. ⏳ 지도 화면에 오름 마커 표시
3. ⏳ 오름 상세 화면 구현
4. ⏳ GPS 추적 및 길안내 구현
5. ⏳ 사용자 인증 및 스탬프 기능
6. ⏳ 커뮤니티 기능

## 🔑 Supabase 정보

- **URL**: https://cpnoyaaccshtfncmefet.supabase.co
- **Anon Key**: (main.dart에 설정됨)

## 📝 주의사항

- Supabase 키는 이미 main.dart에 설정되어 있습니다
- 모든 오름 데이터는 누구나 읽기 가능 (RLS 정책 적용)
- 사용자 데이터는 본인만 접근 가능

## 🐛 문제 해결

### 데이터가 안 보이는 경우:
1. 인터넷 연결 확인
2. Supabase Dashboard에서 데이터 확인
3. Flutter 콘솔에서 에러 로그 확인

### 빌드 오류:
```bash
flutter pub get
flutter clean
flutter run
```
