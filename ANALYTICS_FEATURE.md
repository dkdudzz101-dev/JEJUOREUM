# 데이터 분석 기능 (Data Analytics Feature)

## 개요 (Overview)
제주오름 앱에 추가된 데이터 분석 기능은 사용자의 등산 활동을 심층 분석하여 유용한 인사이트를 제공합니다.

## 주요 기능 (Key Features)

### 1. 활동 추세 분석 (Activity Trend Analysis)
- 최근 활동의 증가/감소/안정 추세 파악
- 월 평균 등산 횟수 계산
- 등산당 평균 거리 및 소요 시간 분석
- 시각적 트렌드 인디케이터 제공

### 2. 월별 통계 (Monthly Statistics)
- 최근 6개월간의 등산 횟수 추적
- 월별 총 거리 및 총 소요 시간 계산
- 진행률 바를 통한 시각적 비교
- 월별 활동량 트렌드 확인

### 3. 카테고리별 달성률 (Category Completion Rate)
- 오름 카테고리별 방문 현황 분석
  - 대표 명소 오름
  - 전망 좋은 오름
  - 숲속 트레킹 오름
  - 가족 산책 오름
  - 계절 명소 오름
- 각 카테고리의 완료율 계산 (%)
- 방문한 오름 목록 표시
- 색상 코딩으로 달성률 시각화

## 기술 구조 (Technical Architecture)

### Models (`lib/models/analytics_model.dart`)
#### HikingAnalytics
메인 분석 데이터 컨테이너
```dart
class HikingAnalytics {
  final List<MonthlyStats> monthlyStats;
  final List<CategoryStats> categoryStats;
  final ProgressTrend progressTrend;
}
```

#### MonthlyStats
월별 통계 데이터
- year: 연도
- month: 월
- hikingCount: 등산 횟수
- totalDistance: 총 거리 (km)
- totalTime: 총 시간 (분)

#### CategoryStats
카테고리별 통계 데이터
- category: 카테고리 명
- visitedCount: 방문한 오름 수
- totalCount: 전체 오름 수
- visitedOreums: 방문한 오름 목록
- completionRate: 완료율 (%)

#### ProgressTrend
진행 추세 데이터
- averageHikesPerMonth: 월 평균 등산 횟수
- averageDistancePerHike: 등산당 평균 거리
- averageTimePerHike: 등산당 평균 시간
- trend: 추세 ('increasing', 'stable', 'decreasing')

### Service (`lib/services/analytics_service.dart`)
#### AnalyticsService
데이터 분석을 담당하는 서비스 클래스

##### 주요 메서드
- `loadCategoryData()`: CSV 파일에서 카테고리 데이터 로드
- `calculateMonthlyStats()`: 월별 통계 계산
- `calculateCategoryStats()`: 카테고리별 통계 계산
- `calculateProgressTrend()`: 활동 추세 계산
- `generateAnalytics()`: 전체 분석 데이터 생성

### UI Screen (`lib/screens/analytics_screen.dart`)
#### AnalyticsScreen
분석 결과를 표시하는 UI 화면

##### 주요 섹션
1. **진행 추세 섹션**: 그라데이션 배경의 카드로 현재 추세 표시
2. **월별 통계 섹션**: 진행률 바로 월별 활동량 표시
3. **카테고리 통계 섹션**: 각 카테고리의 달성률과 방문 오름 표시

## 데이터 소스 (Data Sources)
- `assets/data/oreum_categories.csv`: 오름 카테고리 정보
- Supabase `hiking_records` 테이블: 사용자 등산 기록

## 접근 방법 (Access)
1. 앱 우측 상단 메뉴 아이콘 클릭
2. "데이터 분석" 메뉴 선택

또는

1. 앱 우측 상단 메뉴 아이콘 클릭
2. "통계 & 업적" 메뉴 선택 (기존 통계 화면)

## 테스트 (Tests)
- `test/analytics_model_test.dart`: 분석 모델 단위 테스트
- `test/analytics_service_test.dart`: 분석 서비스 단위 테스트

### 테스트 커버리지
- 월별 통계 계산 로직
- 카테고리 완료율 계산
- 추세 분석 알고리즘
- 모델 직렬화/역직렬화
- 엣지 케이스 처리 (빈 데이터, 미완료 기록 등)

## 향후 개선 사항 (Future Enhancements)
- [ ] 차트 라이브러리를 사용한 시각화 개선
- [ ] 주간/연간 통계 추가
- [ ] 사용자 간 비교 기능
- [ ] 목표 설정 및 달성률 추적
- [ ] 데이터 내보내기 기능
- [ ] 더 상세한 분석 인사이트 제공
