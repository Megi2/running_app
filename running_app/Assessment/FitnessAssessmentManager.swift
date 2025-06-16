//
//  FitnessAssessmentManager.swift
//  running_app
//
//  FitnessLevel 점수 기반 체력 평가 매니저
//

import Foundation
import SwiftUI

// MARK: - 체력 평가 매니저
class FitnessAssessmentManager: ObservableObject {
    static let shared = FitnessAssessmentManager()
    
    @Published var hasCompletedAssessment: Bool = false
    @Published var currentFitnessLevel: FitnessLevel = FitnessLevel(score: 0, date: Date())
    @Published var recommendedGoals: RunningGoals?
    @Published var progressTracker: ProgressTracker?
    @Published var assessmentWorkout: WorkoutSummary?
    
    private let userDefaults = UserDefaults.standard
    private let assessmentKey = "FitnessAssessment"
    
    private init() {
        loadAssessmentData()
    }
    
    // MARK: - 평가 처리
    func processAssessmentWorkout(_ workout: WorkoutSummary) {
        assessmentWorkout = workout
        
        // 체력 점수 계산
        let fitnessScore = calculateFitnessScore(from: workout)
        currentFitnessLevel = FitnessLevel(score: fitnessScore, date: Date())
        
        // 목표 생성
        recommendedGoals = generateGoals(from: workout)
        
        // 진행 상황 추적기 초기화
        progressTracker = ProgressTracker(initialGoals: recommendedGoals!)
        
        hasCompletedAssessment = true
        saveAssessmentData()
        
        print("✅ 체력 평가 완료: \(currentFitnessLevel.displayName)")
    }
    
    // MARK: - 체력 점수 계산
    private func calculateFitnessScore(from workout: WorkoutSummary) -> Double {
        let userProfile = UserProfileManager.shared.userProfile
        let userAge = userProfile.age
        
        // 기본 점수들 (0-100)
        let distanceScore = calculateDistanceScore(workout.distance, age: userAge)
        let paceScore = calculatePaceScore(workout.averagePace, age: userAge)
        let durationScore = calculateDurationScore(workout.duration, age: userAge)
        let heartRateScore = calculateHeartRateScore(workout.averageHeartRate, pace: workout.averagePace, age: userAge)
        
        // 가중 평균으로 총 점수 계산
        let totalScore = (distanceScore * 0.3 + paceScore * 0.3 + durationScore * 0.2 + heartRateScore * 0.2)
        
        return min(100, max(0, totalScore))
    }
    
    private func calculateDistanceScore(_ distance: Double, age: Int) -> Double {
        let ageMultiplier = getAgeMultiplier(age: age)
        let adjustedDistance = distance * ageMultiplier
        
        switch adjustedDistance {
        case 5...: return 100
        case 3..<5: return 80
        case 2..<3: return 60
        case 1..<2: return 40
        default: return 20
        }
    }
    
    private func calculatePaceScore(_ pace: Double, age: Int) -> Double {
        let ageMultiplier = getAgeMultiplier(age: age)
        let adjustedPace = pace / ageMultiplier
        
        switch adjustedPace {
        case 0..<300: return 100    // 5분/km 미만
        case 300..<360: return 80   // 5-6분/km
        case 360..<420: return 60   // 6-7분/km
        case 420..<480: return 40   // 7-8분/km
        default: return 20          // 8분/km 이상
        }
    }
    
    private func calculateDurationScore(_ duration: Double, age: Int) -> Double {
        let minutes = duration / 60
        let ageMultiplier = getAgeMultiplier(age: age)
        let adjustedMinutes = minutes * ageMultiplier
        
        switch adjustedMinutes {
        case 30...: return 100
        case 20..<30: return 80
        case 15..<20: return 60
        case 10..<15: return 40
        default: return 20
        }
    }
    
    private func calculateHeartRateScore(_ heartRate: Double, pace: Double, age: Int) -> Double {
        guard pace > 0 && heartRate > 0 else { return 50 }
        
        // 효율성 계산 (속도/심박수)
        let speedKmh = 3600 / pace
        let efficiency = speedKmh / heartRate
        
        switch efficiency {
        case 0.08...: return 100
        case 0.06..<0.08: return 80
        case 0.04..<0.06: return 60
        case 0.02..<0.04: return 40
        default: return 20
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
    
    // 불필요한 헬퍼 메서드들 제거
    // evaluateDistanceScore, evaluatePaceScore, evaluateHeartRateScore, getAgeMultiplier 메서드들 제거
    
    // MARK: - 목표 생성
    private func generateGoals(from workout: WorkoutSummary) -> RunningGoals {
        let baseDistance = workout.distance
        let basePace = workout.averagePace
        let fitnessScore = currentFitnessLevel.score
        
        // 점수 기반 목표 조정
        let scoreMultiplier = fitnessScore / 50.0 // 50점 기준으로 정규화
        
        return RunningGoals(
            shortTermDistance: min(10.0, baseDistance * (1.0 + scoreMultiplier * 0.5)),
            mediumTermDistance: min(21.0, baseDistance * (1.5 + scoreMultiplier * 0.8)),
            longTermDistance: min(42.0, baseDistance * (2.0 + scoreMultiplier * 1.0)),
            targetPace: max(300, basePace * (1.0 - scoreMultiplier * 0.1)),
            improvementPace: max(280, basePace * (1.0 - scoreMultiplier * 0.15)),
            weeklyGoal: WeeklyGoal(
                runs: getWeeklyRuns(for: fitnessScore),
                totalDistance: getWeeklyDistance(baseDistance: baseDistance, score: fitnessScore),
                averagePace: max(300, basePace * (1.0 - scoreMultiplier * 0.1))
            ),
            fitnessLevel: currentFitnessLevel,
            assessmentDate: Date()
        )
    }
    
    private func getWeeklyRuns(for score: Double) -> Int {
        switch score {
        case 80...: return 5
        case 60..<80: return 4
        default: return 3
        }
    }
    
    private func getWeeklyDistance(baseDistance: Double, score: Double) -> Double {
        let multiplier = 2.0 + (score / 100.0) * 1.5
        return min(30.0, baseDistance * multiplier)
    }
    
    // MARK: - 진행상황 업데이트
    func updateProgress(with workout: WorkoutSummary) {
        guard let tracker = progressTracker,
              let goals = recommendedGoals else { return }
        
        // 새로운 체력 점수 계산
        let newScore = calculateFitnessScore(from: workout)
        if newScore > currentFitnessLevel.score {
            currentFitnessLevel = FitnessLevel(score: newScore, date: Date())
            
            tracker.achievements.append(Achievement(
                title: "체력 향상!",
                description: "점수: \(Int(currentFitnessLevel.score))/100",
                date: Date(),
                type: .improvement
            ))
        }
        
        // 기록 업데이트
        if workout.distance > tracker.bestDistance {
            tracker.bestDistance = workout.distance
            tracker.personalRecords.append(PersonalRecord(
                type: .distance,
                value: workout.distance,
                date: workout.date,
                description: "신기록: \(String(format: "%.2f", workout.distance))km"
            ))
        }
        
        if workout.averagePace < tracker.bestPace {
            tracker.bestPace = workout.averagePace
            tracker.personalRecords.append(PersonalRecord(
                type: .pace,
                value: workout.averagePace,
                date: workout.date,
                description: "신기록: \(paceString(from: workout.averagePace))"
            ))
        }
        
        // 목표 달성 체크
        checkGoalAchievements(workout: workout, tracker: tracker, goals: goals)
        
        // 주간 진행상황 업데이트
        tracker.updateWeeklyProgress(workout)
        
        tracker.totalWorkouts += 1
        saveAssessmentData()
    }
    
    private func checkGoalAchievements(workout: WorkoutSummary, tracker: ProgressTracker, goals: RunningGoals) {
        // 거리 목표 달성
        if workout.distance >= goals.shortTermDistance && !tracker.achievedShortTermDistance {
            tracker.achievedShortTermDistance = true
            tracker.achievements.append(Achievement(
                title: "단기 목표 달성!",
                description: "\(String(format: "%.1f", goals.shortTermDistance))km 완주",
                date: workout.date,
                type: .distance
            ))
        }
        
        if workout.distance >= goals.mediumTermDistance && !tracker.achievedMediumTermDistance {
            tracker.achievedMediumTermDistance = true
            tracker.achievements.append(Achievement(
                title: "중기 목표 달성!",
                description: "\(String(format: "%.1f", goals.mediumTermDistance))km 완주",
                date: workout.date,
                type: .distance
            ))
        }
        
        // 페이스 목표 달성
        if workout.averagePace <= goals.targetPace && !tracker.achievedTargetPace {
            tracker.achievedTargetPace = true
            tracker.achievements.append(Achievement(
                title: "목표 페이스 달성!",
                description: "목표: \(paceString(from: goals.targetPace))",
                date: workout.date,
                type: .pace
            ))
        }
    }
    
    private func paceString(from pace: Double) -> String {
        let minutes = Int(pace) / 60
        let seconds = Int(pace) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // MARK: - 데이터 저장/로드
    private func saveAssessmentData() {
        let assessmentData = FitnessAssessmentData(
            hasCompleted: hasCompletedAssessment,
            fitnessLevel: currentFitnessLevel,
            goals: recommendedGoals,
            tracker: progressTracker,
            assessmentWorkout: assessmentWorkout
        )
        
        if let encoded = try? JSONEncoder().encode(assessmentData) {
            userDefaults.set(encoded, forKey: assessmentKey)
        }
    }
    
    private func loadAssessmentData() {
        if let data = userDefaults.data(forKey: assessmentKey),
           let assessmentData = try? JSONDecoder().decode(FitnessAssessmentData.self, from: data) {
            hasCompletedAssessment = assessmentData.hasCompleted
            currentFitnessLevel = assessmentData.fitnessLevel
            recommendedGoals = assessmentData.goals
            progressTracker = assessmentData.tracker
            assessmentWorkout = assessmentData.assessmentWorkout
        }
    }
    
    func resetAssessment() {
        hasCompletedAssessment = false
        currentFitnessLevel = FitnessLevel(score: 0, date: Date())
        recommendedGoals = nil
        progressTracker = nil
        assessmentWorkout = nil
        
        userDefaults.removeObject(forKey: assessmentKey)
        print("🔄 체력 평가 데이터 초기화 완료")
    }
}

// MARK: - 저장용 데이터 구조체
struct FitnessAssessmentData: Codable {
    let hasCompleted: Bool
    let fitnessLevel: FitnessLevel
    let goals: RunningGoals?
    let tracker: ProgressTracker?
    let assessmentWorkout: WorkoutSummary?
}
