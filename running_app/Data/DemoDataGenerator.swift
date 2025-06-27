//
//  DemoDataGenerator.swift
//  running_app
//
//  데모용 가짜 운동 데이터 생성기
//  실제 운동 없이도 평가 결과를 확인할 수 있습니다.
//

import Foundation

class DemoDataGenerator {
    static let shared = DemoDataGenerator()
    
    private init() {}
    
    // MARK: - 메인 데모 데이터 생성 메서드
    /// 데모용 Zone 2 평가 운동 데이터를 생성합니다
    /// - Parameter difficulty: 난이도 (beginner, intermediate, advanced)
    /// - Returns: 가짜 WorkoutSummary 데이터
    func generateDemoAssessmentWorkout(difficulty: DemoDifficulty = .intermediate) -> WorkoutSummary {
        print("🎭 데모 데이터 생성 시작 (난이도: \(difficulty.rawValue))")
        
        let demoSpecs = getDemoSpecs(for: difficulty)
        let dataPoints = generateDemoDataPoints(specs: demoSpecs)
        
        let workout = WorkoutSummary(
            date: Date(),  // 현재 시간으로 설정
            duration: demoSpecs.duration,
            distance: demoSpecs.distance,
            averageHeartRate: demoSpecs.averageHeartRate,
            averagePace: demoSpecs.averagePace,
            averageCadence: demoSpecs.averageCadence,
            dataPoints: dataPoints
        )
        
        print("✅ 데모 데이터 생성 완료:")
        print("   거리: \(String(format: "%.2f", workout.distance))km")
        print("   시간: \(Int(workout.duration/60))분 \(Int(workout.duration.truncatingRemainder(dividingBy: 60)))초")
        print("   평균 심박수: \(Int(workout.averageHeartRate)) bpm")
        print("   평균 페이스: \(Int(workout.averagePace/60))분 \(Int(workout.averagePace.truncatingRemainder(dividingBy: 60)))초/km")
        
        return workout
    }
    
    // MARK: - 난이도별 스펙 정의
    private func getDemoSpecs(for difficulty: DemoDifficulty) -> DemoWorkoutSpecs {
        let userProfile = UserProfileManager.shared.userProfile
        let zone2Range = userProfile.heartRateZones.zone2
        let zone2MiddleHR = (zone2Range.lowerBound + zone2Range.upperBound) / 2
        
        switch difficulty {
        case .beginner:
            // 초보자: 짧은 거리, 느린 페이스
            return DemoWorkoutSpecs(
                distance: 1.2,                    // 1.2km
                duration: 600,                    // 10분
                averageHeartRate: zone2MiddleHR - 5,  // Zone 2 하단
                averagePace: 500,                 // 8분 20초/km
                averageCadence: 155,              // 낮은 케이던스
                zone2Percentage: 75               // 75% Zone 2 유지
            )
            
        case .intermediate:
            // 중급자: 적당한 거리와 페이스
            return DemoWorkoutSpecs(
                distance: 2.8,                    // 2.8km
                duration: 1260,                   // 21분
                averageHeartRate: zone2MiddleHR,  // Zone 2 중간
                averagePace: 450,                 // 7분 30초/km
                averageCadence: 170,              // 적당한 케이던스
                zone2Percentage: 82               // 82% Zone 2 유지
            )
            
        case .advanced:
            // 고급자: 긴 거리, 빠른 페이스
            return DemoWorkoutSpecs(
                distance: 5.2,                    // 5.2km
                duration: 1950,                   // 32분 30초
                averageHeartRate: zone2MiddleHR + 3,  // Zone 2 상단
                averagePace: 375,                 // 6분 15초/km
                averageCadence: 178,              // 높은 케이던스
                zone2Percentage: 88               // 88% Zone 2 유지
            )
        }
    }
    
    // MARK: - 실제 데이터 포인트 생성
    private func generateDemoDataPoints(specs: DemoWorkoutSpecs) -> [RunningDataPoint] {
        var dataPoints: [RunningDataPoint] = []
        let pointInterval: TimeInterval = 5  // 5초마다 데이터 포인트
        let totalPoints = Int(specs.duration / pointInterval)
        
        print("📊 \(totalPoints)개의 데이터 포인트 생성 중...")
        
        for i in 0..<totalPoints {
            let timestamp = Date().timeIntervalSince1970 + (Double(i) * pointInterval)
            let progress = Double(i) / Double(totalPoints)
            
            // 시간에 따른 자연스러운 변화 시뮬레이션
            let dataPoint = createRealisticDataPoint(
                timestamp: timestamp,
                progress: progress,
                specs: specs
            )
            
            dataPoints.append(dataPoint)
        }
        
        print("✅ 데이터 포인트 생성 완료")
        return dataPoints
    }
    
    // MARK: - 현실적인 데이터 포인트 생성
    private func createRealisticDataPoint(
        timestamp: TimeInterval,
        progress: Double,
        specs: DemoWorkoutSpecs
    ) -> RunningDataPoint {
        
        // 페이스 변화 (초반 빠름 -> 중반 안정 -> 후반 느려짐)
        let paceVariation = createPaceVariation(progress: progress)
        let currentPace = specs.averagePace + paceVariation
        
        // 심박수 변화 (점진적 상승 + 자연스러운 변동)
        let heartRateVariation = createHeartRateVariation(progress: progress)
        let currentHeartRate = specs.averageHeartRate + heartRateVariation
        
        // 케이던스 변화 (피로도에 따른 감소)
        let cadenceVariation = createCadenceVariation(progress: progress)
        let currentCadence = specs.averageCadence + cadenceVariation
        
        // 누적 거리
        let currentDistance = specs.distance * progress
        
        return RunningDataPoint(
            timestamp: timestamp,
            pace: currentPace,
            heartRate: currentHeartRate,
            cadence: currentCadence,
            distance: currentDistance
        )
    }
    
    // MARK: - 자연스러운 변화 패턴 생성
    private func createPaceVariation(progress: Double) -> Double {
        // 운동 초반: 약간 빠름 (-20초)
        // 운동 중반: 안정적 (기준값)
        // 운동 후반: 피로로 느려짐 (+30초)
        let baseVariation = sin(progress * .pi) * 15 + (progress * 35 - 20)
        let randomNoise = Double.random(in: -10...10)
        return baseVariation + randomNoise
    }
    
    private func createHeartRateVariation(progress: Double) -> Double {
        // 심박수는 점진적으로 상승하되 자연스러운 변동 포함
        let progressIncrease = progress * 8  // 최대 8bpm 상승
        let naturalVariation = sin(progress * .pi * 3) * 5  // 자연스러운 변동
        let randomNoise = Double.random(in: -3...3)
        return progressIncrease + naturalVariation + randomNoise
    }
    
    private func createCadenceVariation(progress: Double) -> Double {
        // 케이던스는 피로도에 따라 후반에 약간 감소
        let fatigueReduction = progress * -8  // 최대 8spm 감소
        let randomNoise = Double.random(in: -5...5)
        return fatigueReduction + randomNoise
    }
}

// MARK: - 데모 설정 구조체
struct DemoWorkoutSpecs {
    let distance: Double           // 총 거리 (km)
    let duration: TimeInterval     // 총 시간 (초)
    let averageHeartRate: Double   // 평균 심박수
    let averagePace: Double        // 평균 페이스 (초/km)
    let averageCadence: Double     // 평균 케이던스
    let zone2Percentage: Double    // Zone 2 유지 비율
}

// MARK: - 난이도 열거형
enum DemoDifficulty: String, CaseIterable {
    case beginner = "초보자"
    case intermediate = "중급자"
    case advanced = "고급자"
    
    var description: String {
        switch self {
        case .beginner:
            return "짧은 거리, 편안한 페이스"
        case .intermediate:
            return "적당한 거리, 안정적인 페이스"
        case .advanced:
            return "긴 거리, 도전적인 페이스"
        }
    }
    
    var emoji: String {
        switch self {
        case .beginner: return "🌱"
        case .intermediate: return "🏃‍♂️"
        case .advanced: return "🔥"
        }
    }
}