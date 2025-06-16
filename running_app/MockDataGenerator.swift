//
//  MockDataGenerator.swift
//  running_app
//
//  임시 데이터 생성기 - 워치 연결 없이 화면 테스트용
//

import Foundation
import SwiftUI

// MARK: - 임시 데이터 생성 클래스
class MockDataGenerator {
    static let shared = MockDataGenerator()
    
    private init() {}
    
    // MARK: - Zone 2 평가 임시 데이터 생성
    func generateMockAssessmentWorkout() -> WorkoutSummary {
        print("🎭 임시 Zone 2 평가 데이터 생성 중...")
        
        // 25세 여성 초급자가 Zone 2에서 최대한 오래 달린 시나리오
        let duration: TimeInterval = 1800 // 30분
        let distance: Double = 4.8 // 4.8km
        let averageHeartRate: Double = 145 // Zone 2 중간값
        let averagePace: Double = 375 // 6분 15초/km
        let averageCadence: Double = 168
        
        let dataPoints = generateMockDataPoints(
            duration: duration,
            distance: distance,
            baseHeartRate: averageHeartRate,
            basePace: averagePace,
            baseCadence: averageCadence
        )
        
        let workout = WorkoutSummary(
            date: Date(),
            duration: duration,
            distance: distance,
            averageHeartRate: averageHeartRate,
            averagePace: averagePace,
            averageCadence: averageCadence,
            dataPoints: dataPoints
        )
        
        print("✅ 임시 평가 데이터 생성 완료:")
        print("   거리: \(String(format: "%.1f", distance))km")
        print("   시간: \(Int(duration/60))분")
        print("   평균 심박수: \(Int(averageHeartRate)) bpm")
        print("   평균 페이스: \(Int(averagePace/60)):\(String(format: "%02d", Int(averagePace) % 60))/km")
        
        return workout
    }
    
    // MARK: - Zone 2 능력 점수 생성
    func generateMockZone2CapacityScore() -> Zone2CapacityScore {
        // 초급자 수준의 점수
        let distanceScore: Double = 65 // 괜찮은 거리 지속력
        let timeScore: Double = 70     // 좋은 시간 지속력
        let consistencyScore: Double = 80 // 우수한 Zone 2 일관성
        let efficiencyScore: Double = 55  // 개선 필요한 효율성
        
        let totalScore = (distanceScore + timeScore + consistencyScore + efficiencyScore) / 4
        
        return Zone2CapacityScore(
            totalScore: totalScore,
            distanceScore: distanceScore,
            timeScore: timeScore,
            consistencyScore: consistencyScore,
            efficiencyScore: efficiencyScore
        )
    }
    
    // MARK: - Zone 2 프로필 생성
    func generateMockZone2Profile() -> Zone2Profile {
        let userProfile = UserProfileManager.shared.userProfile
        let maxHR = userProfile.maxHeartRate
        let restingHR = userProfile.restingHeartRate
        
        // Zone 2 범위 계산 (60-70% HRR)
        let hrReserve = maxHR - restingHR
        let zone2Lower = restingHR + (hrReserve * 0.60)
        let zone2Upper = restingHR + (hrReserve * 0.70)
        
        return Zone2Profile(
            zone2Range: zone2Lower...zone2Upper,
            maxSustainableDistance: 4.8,
            maxSustainableTime: 1800, // 30분
            averageZone2Pace: 375, // 6분 15초/km
            zone2TimePercentage: 85, // 85% Zone 2 유지
            zone2Efficiency: 0.65, // 중간 수준 효율성
            assessmentDate: Date()
        )
    }
    
    // MARK: - Zone 2 목표 생성
    func generateMockZone2Goals() -> RunningGoals {
        return RunningGoals(
            shortTermDistance: 6.0,   // 4-6주: 6km
            mediumTermDistance: 8.0,  // 3-4개월: 8km
            longTermDistance: 12.0,   // 6-12개월: 12km
            targetPace: 350,          // 5분 50초/km 목표
            improvementPace: 330,     // 5분 30초/km 최종 목표
            weeklyGoal: WeeklyGoal(
                runs: 3,              // 주 3회
                totalDistance: 12.0,  // 주 12km
                averagePace: 360      // 6분/km 평균
            ), fitnessLevel: <#FitnessLevel#>,
            assessmentDate: Date()
        )
    }
    
    // MARK: - 진행상황 추적기 생성
    func generateMockProgressTracker() -> ProgressTracker {
        // 임시로 빈 ProgressTracker 생성
        let tracker = ProgressTracker(initialGoals: <#RunningGoals#>)
        
        // 현재 기록 설정
        tracker.bestDistance = 4.8
        tracker.bestPace = 375
        tracker.totalWorkouts = 1
        
        // 목표 달성 상태 (아직 미달성)
        tracker.achievedShortTermDistance = false
        tracker.achievedMediumTermDistance = false
        tracker.achievedTargetPace = false
        
        // Zone 2 특화 기록 (주석 처리 - 기존 ProgressTracker에 없음)
        // tracker.bestZone2Distance = 4.8
        // tracker.bestZone2Duration = 1800
        // tracker.bestZone2Consistency = 85.0
        
        // 성취 기록 추가
        tracker.achievements.append(Achievement(
            title: "Zone 2 첫 평가 완료!",
            description: "4.8km Zone 2 지속 능력 측정 완료",
            date: Date(),
            type: .distance
        ))
        
        // 개인 기록 추가
        tracker.personalRecords.append(PersonalRecord(
            type: .distance,
            value: 4.8,
            date: Date(),
            description: "Zone 2 최대 지속 거리: 4.8km"
        ))
        
        tracker.personalRecords.append(PersonalRecord(
            type: .duration,
            value: 1800,
            date: Date(),
            description: "Zone 2 최대 지속 시간: 30분"
        ))
        
        return tracker
    }
    
    // MARK: - 임시 데이터 포인트 생성 (상세한 시계열 데이터)
    private func generateMockDataPoints(
        duration: TimeInterval,
        distance: Double,
        baseHeartRate: Double,
        basePace: Double,
        baseCadence: Double
    ) -> [RunningDataPoint] {
        
        var dataPoints: [RunningDataPoint] = []
        let startTime = Date()
        let intervalSeconds = 5 // 5초마다 데이터 포인트
        let totalPoints = Int(duration / Double(intervalSeconds))
        
        for i in 0..<totalPoints {
            let timestamp = startTime.addingTimeInterval(Double(i * intervalSeconds))
            let progress = Double(i) / Double(totalPoints)
            
            // Zone 2 심박수 변화 시뮬레이션
            let heartRateVariation = sin(Double(i) * 0.1) * 8 + Double.random(in: -5...5)
            let fatigueFactor = progress * 10 // 피로로 인한 점진적 증가
            let heartRate = max(130, min(160, baseHeartRate + heartRateVariation + fatigueFactor))
            
            // 페이스 변화 시뮬레이션 (Zone 2에서는 상대적으로 안정적)
            let paceVariation = sin(Double(i) * 0.05) * 15 + Double.random(in: -10...10)
            let tirednessFactor = progress * 20 // 피로로 인한 페이스 저하
            let pace = max(300, min(450, basePace + paceVariation + tirednessFactor))
            
            // 케이던스 변화 시뮬레이션
            let cadenceVariation = sin(Double(i) * 0.08) * 5 + Double.random(in: -3...3)
            let cadence = max(160, min(180, baseCadence + cadenceVariation))
            
            // 거리 누적 계산
            let currentDistance = (progress * distance)
            
            let dataPoint = RunningDataPoint(
                timestamp: timestamp,
                pace: pace,
                heartRate: heartRate,
                cadence: cadence,
                distance: currentDistance
            )
            
            dataPoints.append(dataPoint)
        }
        
        return dataPoints
    }
    
    // MARK: - 전체 평가 데이터 패키지 생성
    func generateCompleteAssessmentData() -> Zone2AssessmentData {
        let workout = generateMockAssessmentWorkout()
        let capacityScore = generateMockZone2CapacityScore()
        let zone2Profile = generateMockZone2Profile()
        let goals = generateMockZone2Goals()
        let tracker = generateMockProgressTracker()
        
        return Zone2AssessmentData(
            hasCompleted: true,
            zone2CapacityScore: capacityScore,
            goals: goals,
            tracker: tracker,
            assessmentWorkout: workout,
            zone2Profile: zone2Profile
        )
    }
}
