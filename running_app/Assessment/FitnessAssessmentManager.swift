//
//  FitnessAssessmentManager.swift
//  running_app
//
//  Zone 2 최대 지속 능력 평가 및 목표 설정 매니저 (완전 수정됨)
//

import Foundation
import SwiftUI

// MARK: - Zone 2 최대 지속 능력 평가 매니저
class FitnessAssessmentManager: ObservableObject {
    static let shared = FitnessAssessmentManager()
    
    // Zone2 타입으로 완전히 통일
    @Published var hasCompletedAssessment: Bool = false
    @Published var zone2CapacityScore: Zone2CapacityScore?
    @Published var recommendedGoals: Zone2Goals?
    @Published var progressTracker: Zone2ProgressTracker?
    @Published var assessmentWorkout: WorkoutSummary?
    @Published var zone2Profile: Zone2Profile?
    
    private let userDefaults = UserDefaults.standard
    private let assessmentKey = "Zone2Assessment"
    
    private init() {
        loadAssessmentData()
    }
    
    // MARK: - Zone 2 최대 지속 능력 평가
    func processAssessmentWorkout(_ workout: WorkoutSummary) {
        print("📊 Zone 2 최대 지속 능력 평가 시작")
        print("🏃‍♂️ 거리: \(String(format: "%.2f", workout.distance))km")
        print("⏱️ 시간: \(Int(workout.duration/60))분 \(Int(workout.duration.truncatingRemainder(dividingBy: 60)))초")
        
        assessmentWorkout = workout
        
        // Zone 2 프로필 생성
        zone2Profile = createZone2Profile(from: workout)
        
        // Zone 2 능력 점수 계산 (등급 없는 연속적 평가)
        zone2CapacityScore = calculateZone2CapacityScore(from: workout)
        
        // Zone 2 최적화 목표 생성
        recommendedGoals = generateZone2Goals(from: workout)
        
        // Zone2ProgressTracker 생성 (올바른 타입 사용)
        if let goals = recommendedGoals {
            progressTracker = Zone2ProgressTracker(initialGoals: goals)
        }
        
        hasCompletedAssessment = true
        
        saveAssessmentData()
        
        print("✅ Zone 2 최대 지속 능력 평가 완료")
        print("🫀 Zone 2 범위: \(Int(zone2Profile?.zone2Range.lowerBound ?? 0))-\(Int(zone2Profile?.zone2Range.upperBound ?? 0)) bpm")
        print("📏 Zone 2 최대 거리: \(String(format: "%.2f", zone2Profile?.maxSustainableDistance ?? 0))km")
        print("💪 Zone 2 최대 지속시간: \(Int((zone2Profile?.maxSustainableTime ?? 0)/60))분")
        print("🎯 Zone 2 능력 점수: \(Int(zone2CapacityScore?.totalScore ?? 0))/100")
    }
    
    // MARK: - Zone 2 프로필 생성
    private func createZone2Profile(from workout: WorkoutSummary) -> Zone2Profile {
        let userProfile = UserProfileManager.shared.userProfile
        let maxHR = userProfile.maxHeartRate
        let restingHR = userProfile.restingHeartRate
        
        // Zone 2 범위 계산 (Karvonen 공식: 60-70% HRR)
        let hrReserve = maxHR - restingHR
        let zone2Lower = restingHR + (hrReserve * 0.60)
        let zone2Upper = restingHR + (hrReserve * 0.70)
        let zone2Range = zone2Lower...zone2Upper
        
        // 평가 운동에서 Zone 2 성능 분석
        let zone2Performance = analyzeZone2Performance(workout: workout, zone2Range: zone2Range)
        
        return Zone2Profile(
            zone2Range: zone2Range,
            maxSustainableDistance: workout.distance,
            maxSustainableTime: workout.duration,
            averageZone2Pace: zone2Performance.averagePace,
            zone2TimePercentage: zone2Performance.timeInZone,
            zone2Efficiency: zone2Performance.efficiency,
            assessmentDate: workout.date
        )
    }
    
    // MARK: - Zone 2 능력 점수 계산 (0-100점)
    private func calculateZone2CapacityScore(from workout: WorkoutSummary) -> Zone2CapacityScore {
        guard let zone2Profile = zone2Profile else {
            return Zone2CapacityScore(
                totalScore: 0,
                distanceScore: 0,
                timeScore: 0,
                consistencyScore: 0,
                efficiencyScore: 0
            )
        }
        
        let userAge = UserProfileManager.shared.userProfile.age
        let ageMultiplier = getAgeMultiplier(age: userAge)
        
        let distanceScore = evaluateDistanceScore(zone2Profile.maxSustainableDistance, ageMultiplier: ageMultiplier)
        let timeScore = evaluateTimeScore(zone2Profile.maxSustainableTime / 60, ageMultiplier: ageMultiplier)
        let consistencyScore = evaluateZone2ConsistencyScore(zone2Profile.zone2TimePercentage)
        let efficiencyScore = evaluateEfficiencyScore(zone2Profile.zone2Efficiency, ageMultiplier: ageMultiplier)
        
        let totalScore = (distanceScore + timeScore + consistencyScore + efficiencyScore) / 4 * 10 // 0-100 범위로 변환
        
        return Zone2CapacityScore(
            totalScore: totalScore,
            distanceScore: distanceScore * 10,
            timeScore: timeScore * 10,
            consistencyScore: consistencyScore * 10,
            efficiencyScore: efficiencyScore * 10
        )
    }
    
    // MARK: - Zone 2 성능 분석
    private func analyzeZone2Performance(workout: WorkoutSummary, zone2Range: ClosedRange<Double>) -> Zone2Performance {
        let dataPoints = workout.dataPoints
        
        // Zone 2 구간 필터링
        let zone2Points = dataPoints.filter { point in
            zone2Range.contains(point.heartRate)
        }
        
        let totalTime = workout.duration
        let zone2Time = Double(zone2Points.count) // 1초 간격 데이터포인트 가정
        let timeInZonePercentage = (zone2Time / totalTime) * 100
        
        // Zone 2 평균 페이스 계산
        let zone2Paces = zone2Points.compactMap { $0.pace > 0 ? $0.pace : nil }
        let averageZone2Pace = zone2Paces.isEmpty ? workout.averagePace : zone2Paces.reduce(0, +) / Double(zone2Paces.count)
        
        // Zone 2 효율성 계산
        let efficiency = calculateZone2Efficiency(
            distance: workout.distance,
            time: zone2Time,
            averageHR: zone2Points.map { $0.heartRate }.reduce(0, +) / Double(zone2Points.count)
        )
        
        return Zone2Performance(
            timeInZone: timeInZonePercentage,
            averagePace: averageZone2Pace,
            efficiency: efficiency
        )
    }
    
    // MARK: - Zone 2 효율성 계산
    private func calculateZone2Efficiency(distance: Double, time: Double, averageHR: Double) -> Double {
        guard time > 0 && averageHR > 0 else { return 0 }
        return (distance * 1000) / (time * averageHR)
    }
    
    // MARK: - 평가 점수 계산 함수들
    private func evaluateDistanceScore(_ distance: Double, ageMultiplier: Double) -> Double {
        let adjustedDistance = distance / ageMultiplier
        switch adjustedDistance {
        case 10...: return 10
        case 7..<10: return 8
        case 5..<7: return 6
        case 3..<5: return 4
        case 1..<3: return 2
        default: return 1
        }
    }
    
    private func evaluateTimeScore(_ timeMinutes: Double, ageMultiplier: Double) -> Double {
        let adjustedTime = timeMinutes / ageMultiplier
        switch adjustedTime {
        case 60...: return 10
        case 45..<60: return 8
        case 30..<45: return 6
        case 20..<30: return 4
        case 10..<20: return 2
        default: return 1
        }
    }
    
    private func evaluateZone2ConsistencyScore(_ percentage: Double) -> Double {
        switch percentage {
        case 90...: return 10
        case 80..<90: return 8
        case 70..<80: return 6
        case 60..<70: return 4
        case 50..<60: return 2
        default: return 1
        }
    }
    
    private func evaluateEfficiencyScore(_ efficiency: Double, ageMultiplier: Double) -> Double {
        let adjustedEfficiency = efficiency * ageMultiplier
        switch adjustedEfficiency {
        case 0.8...: return 10
        case 0.6..<0.8: return 8
        case 0.4..<0.6: return 6
        case 0.3..<0.4: return 4
        case 0.2..<0.3: return 2
        default: return 1
        }
    }
    
    private func getAgeMultiplier(age: Int) -> Double {
        switch age {
        case 15...25: return 1.1
        case 26...35: return 1.0
        case 36...45: return 0.9
        case 46...55: return 0.8
        default: return 0.7
        }
    }
    
    // MARK: - Zone 2 목표 생성
    private func generateZone2Goals(from workout: WorkoutSummary) -> Zone2Goals {
        guard let zone2Profile = zone2Profile else {
            return createDefaultZone2Goals()
        }
        
        let baseDistance = zone2Profile.maxSustainableDistance
        let basePace = zone2Profile.averageZone2Pace
        
        let targetDistances = calculateZone2TargetDistances(baseDistance: baseDistance)
        let targetPaces = calculateZone2TargetPaces(basePace: basePace)
        
        return Zone2Goals(
            shortTermDistance: targetDistances.shortTerm,
            mediumTermDistance: targetDistances.mediumTerm,
            longTermDistance: targetDistances.longTerm,
            targetPace: targetPaces.target,
            improvementPace: targetPaces.improvement,
            weeklyGoal: Zone2WeeklyGoal(
                runs: 3,
                totalDistance: getZone2WeeklyDistance(baseDistance: baseDistance),
                averagePace: targetPaces.target
            ),
            assessmentDate: Date()
        )
    }
    
    private func calculateZone2TargetDistances(baseDistance: Double) -> (shortTerm: Double, mediumTerm: Double, longTerm: Double) {
        let shortTerm = min(21.0, baseDistance * 1.2)
        let mediumTerm = min(42.0, baseDistance * 1.5)
        let longTerm = min(50.0, baseDistance * 2.0)
        
        return (shortTerm, mediumTerm, longTerm)
    }
    
    private func calculateZone2TargetPaces(basePace: Double) -> (target: Double, improvement: Double) {
        let improvement = basePace * 0.05
        let target = max(300, basePace - improvement)
        let ultimateImprovement = max(280, target - (basePace * 0.03))
        
        return (target, ultimateImprovement)
    }
    
    private func getZone2WeeklyDistance(baseDistance: Double) -> Double {
        return min(50.0, baseDistance * 2.5)
    }
    
    private func createDefaultZone2Goals() -> Zone2Goals {
        return Zone2Goals(
            shortTermDistance: 3.0,
            mediumTermDistance: 5.0,
            longTermDistance: 10.0,
            targetPace: 360,
            improvementPace: 330,
            weeklyGoal: Zone2WeeklyGoal(runs: 3, totalDistance: 8.0, averagePace: 360),
            assessmentDate: Date()
        )
    }
    
    // MARK: - 데이터 저장/로드
    private func saveAssessmentData() {
        if hasCompletedAssessment {
            let assessmentData = Zone2AssessmentData(
                hasCompleted: hasCompletedAssessment,
                zone2CapacityScore: zone2CapacityScore,
                goals: recommendedGoals,
                tracker: progressTracker,
                assessmentWorkout: assessmentWorkout,
                zone2Profile: zone2Profile
            )
            
            if let encoded = try? JSONEncoder().encode(assessmentData) {
                userDefaults.set(encoded, forKey: assessmentKey)
            }
        }
    }
    
    private func loadAssessmentData() {
        if let data = userDefaults.data(forKey: assessmentKey),
           let assessmentData = try? JSONDecoder().decode(Zone2AssessmentData.self, from: data) {
            hasCompletedAssessment = assessmentData.hasCompleted
            zone2CapacityScore = assessmentData.zone2CapacityScore
            recommendedGoals = assessmentData.goals
            progressTracker = assessmentData.tracker
            assessmentWorkout = assessmentData.assessmentWorkout
            zone2Profile = assessmentData.zone2Profile
        }
    }
    
    // MARK: - 리셋 함수
    func resetAssessment() {
        hasCompletedAssessment = false
        zone2CapacityScore = nil
        recommendedGoals = nil
        progressTracker = nil
        assessmentWorkout = nil
        zone2Profile = nil
        
        userDefaults.removeObject(forKey: assessmentKey)
        print("🔄 Zone 2 체력 평가 데이터 초기화 완료")
    }
}
