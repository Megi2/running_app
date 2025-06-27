//
//  FitnessAssessmentManager+Demo.swift
//  running_app
//
//  평가 매니저에 데모 기능을 추가하는 확장
//  실제 운동 없이도 평가 결과를 확인할 수 있습니다.
//

import Foundation
import SwiftUI

// MARK: - 데모 기능 확장
extension FitnessAssessmentManager {
    
    /// 데모용 평가를 실행합니다 (실제 운동 없이)
    /// - Parameter difficulty: 원하는 난이도 (초보자/중급자/고급자)
    func runDemoAssessment(difficulty: DemoDifficulty = .intermediate) {
        print("🎭 데모 평가 시작 (난이도: \(difficulty.rawValue))")
        
        // 1. 가짜 운동 데이터 생성
        let demoWorkout = DemoDataGenerator.shared.generateDemoAssessmentWorkout(difficulty: difficulty)
        
        // 2. 평가 진행 (실제 평가와 동일한 로직)
        processAssessmentWorkout(demoWorkout)
        
        // 3. 완료 알림
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.showDemoCompletionMessage(difficulty: difficulty)
        }
        
        print("✅ 데모 평가 완료")
    }
    
    /// 3가지 난이도 모두 체험할 수 있는 통합 데모
    func runComprehensiveDemo() {
        print("🎭 종합 데모 시작 - 3가지 난이도 모두 체험")
        
        // 중급자 난이도로 기본 설정
        runDemoAssessment(difficulty: .intermediate)
        
        // 사용자에게 다른 난이도도 체험할 수 있음을 알림
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.showAdditionalDemoOptions()
        }
    }
    
    /// 특정 수치로 맞춤 데모 실행
    /// - Parameters:
    ///   - distance: 원하는 거리 (km)
    ///   - duration: 원하는 시간 (분)
    ///   - pace: 원하는 페이스 (분/km)
    func runCustomDemo(distance: Double, duration: Double, pace: Double) {
        print("🎭 맞춤 데모 시작 - 거리: \(distance)km, 시간: \(duration)분, 페이스: \(pace)분/km")
        
        let customWorkout = createCustomDemoWorkout(
            distance: distance,
            durationMinutes: duration,
            paceMinutesPerKm: pace
        )
        
        processAssessmentWorkout(customWorkout)
        
        print("✅ 맞춤 데모 완료")
    }
    
    // MARK: - 내부 헬퍼 메서드들
    
    /// 맞춤 데모 워크아웃 생성
    private func createCustomDemoWorkout(distance: Double, durationMinutes: Double, paceMinutesPerKm: Double) -> WorkoutSummary {
        let userProfile = UserProfileManager.shared.userProfile
        let zone2Range = userProfile.heartRateZones.zone2
        let zone2MiddleHR = (zone2Range.lowerBound + zone2Range.upperBound) / 2
        
        let duration = durationMinutes * 60  // 분을 초로 변환
        let pace = paceMinutesPerKm * 60     // 분/km를 초/km로 변환
        
        // 기본적인 데이터 포인트 생성 (간단 버전)
        let dataPoints = createSimpleDataPoints(
            distance: distance,
            duration: duration,
            pace: pace,
            heartRate: zone2MiddleHR
        )
        
        return WorkoutSummary(
            date: Date(),
            duration: duration,
            distance: distance,
            averageHeartRate: zone2MiddleHR,
            averagePace: pace,
            averageCadence: 170,  // 기본 케이던스
            dataPoints: dataPoints
        )
    }
    
    /// 간단한 데이터 포인트 생성
    private func createSimpleDataPoints(distance: Double, duration: TimeInterval, pace: Double, heartRate: Double) -> [RunningDataPoint] {
        var dataPoints: [RunningDataPoint] = []
        let pointInterval: TimeInterval = 10  // 10초마다
        let totalPoints = Int(duration / pointInterval)
        
        for i in 0..<totalPoints {
            let timestamp = Date().timeIntervalSince1970 + (Double(i) * pointInterval)
            let progress = Double(i) / Double(totalPoints)
            let currentDistance = distance * progress
            
            let dataPoint = RunningDataPoint(
                timestamp: timestamp,
                pace: pace + Double.random(in: -20...20),  // 약간의 변동
                heartRate: heartRate + Double.random(in: -5...5),
                cadence: 170 + Double.random(in: -10...10),
                distance: currentDistance
            )
            
            dataPoints.append(dataPoint)
        }
        
        return dataPoints
    }
    
    /// 데모 완료 메시지 표시
    private func showDemoCompletionMessage(difficulty: DemoDifficulty) {
        print("🎉 데모 완료! 난이도: \(difficulty.rawValue)")
        print("📊 이제 목표 탭에서 개인 맞춤 목표를 확인해보세요!")
        
        // 알림 발송 (필요시 UI에서 처리)
        NotificationCenter.default.post(
            name: NSNotification.Name("DemoAssessmentCompleted"),
            object: ["difficulty": difficulty.rawValue]
        )
    }
    
    /// 추가 데모 옵션 안내
    private func showAdditionalDemoOptions() {
        print("💡 다른 난이도도 체험해보세요:")
        print("   🌱 초보자: 짧은 거리, 편안한 페이스")
        print("   🏃‍♂️ 중급자: 적당한 거리, 안정적인 페이스")
        print("   🔥 고급자: 긴 거리, 도전적인 페이스")
    }
    
    // MARK: - 데모 상태 확인
    
    /// 현재 설정이 데모 데이터인지 확인
    var isDemoData: Bool {
        guard let workout = assessmentWorkout else { return false }
        
        // 데모 데이터의 특징: 생성 시간이 현재와 매우 가까움
        let timeDifference = abs(workout.date.timeIntervalSinceNow)
        return timeDifference < 300  // 5분 이내에 생성된 데이터면 데모로 간주
    }
    
    /// 데모 데이터 정보 반환
    var demoDataInfo: String? {
        guard isDemoData else { return nil }
        
        if let workout = assessmentWorkout {
            return "데모 데이터 (\(String(format: "%.1f", workout.distance))km, \(Int(workout.duration/60))분)"
        }
        return "데모 데이터"
    }
    
    // MARK: - 데모 초기화
    
    /// 데모 데이터를 지우고 실제 평가를 위해 초기화
    func clearDemoData() {
        guard isDemoData else {
            print("⚠️ 실제 평가 데이터이므로 초기화하지 않습니다")
            return
        }
        
        print("🧹 데모 데이터 초기화 중...")
        resetAssessment()
        print("✅ 데모 데이터 초기화 완료. 이제 실제 평가를 진행할 수 있습니다.")
    }
}

// MARK: - 빠른 데모 실행을 위한 편의 메서드들
extension FitnessAssessmentManager {
    
    /// 초보자용 빠른 데모
    func quickDemoForBeginner() {
        print("🌱 초보자 데모 실행")
        runDemoAssessment(difficulty: .beginner)
    }
    
    /// 중급자용 빠른 데모
    func quickDemoForIntermediate() {
        print("🏃‍♂️ 중급자 데모 실행")
        runDemoAssessment(difficulty: .intermediate)
    }
    
    /// 고급자용 빠른 데모
    func quickDemoForAdvanced() {
        print("🔥 고급자 데모 실행")
        runDemoAssessment(difficulty: .advanced)
    }
    
    /// 랜덤 난이도 데모
    func randomDemo() {
        let randomDifficulty = DemoDifficulty.allCases.randomElement() ?? .intermediate
        print("🎲 랜덤 데모 실행 (난이도: \(randomDifficulty.rawValue))")
        runDemoAssessment(difficulty: randomDifficulty)
    }
}