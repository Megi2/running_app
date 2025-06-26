# 🏃‍♂️ PersonalizedRunningApp

**Apple Watch 연동 개인화된 러닝 훈련 앱**

실시간 생체신호 분석과 과학적 체력 평가를 통해 개인 맞춤형 러닝 목표를 제공하는 iOS 애플리케이션입니다.

## ✨ 주요 기능

- **개인별 체력 평가** - Zone 2 심박수 기반 최대 지속 능력 측정
- **실시간 AI 분석** - 페이스 안정성, 효율성, 케이던스 최적화
- **맞춤형 목표 설정** - 개인 능력에 맞는 단계별 목표 자동 생성
- **과훈련 방지** - 효율성 모니터링으로 안전한 훈련 환경

## 🛠 기술 스택

- **Swift 5.0** / **SwiftUI**
- **HealthKit** / **Watch Connectivity** / **CoreMotion**
- **Core Data** / **iOS 18.4+** / **watchOS 11.4+**

## 🚀 빠른 시작

```bash
git clone https://github.com/yourusername/PersonalizedRunningApp.git
cd PersonalizedRunningApp
open running_app.xcodeproj
```

> **필수 요구사항**: Apple Watch 페어링, HealthKit 권한 허용

## 📊 핵심 알고리즘

**Zone 2 계산**
```swift
let maxHR = 208 - (0.7 * age)  // Tanaka 공식
let zone2Range = restingHR + (hrReserve * 0.6...0.7)  // Karvonen 공식
```

**실시간 분석**
```swift
let paceStability = (standardDeviation / mean) * 100  // 변동계수
let efficiency = (3600 / pace) / heartRate  // 효율성
```

## 📁 프로젝트 구조

```
├── CoreApp/          # 메인 앱
├── UserProfile/      # 사용자 관리
├── Assessment/       # 체력 평가
├── Analysis/         # AI 분석
├── Data/            # 데이터 관리
└── Watch App/       # Apple Watch 앱
```

