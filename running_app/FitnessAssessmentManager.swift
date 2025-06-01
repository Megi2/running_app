//
//  FitnessAssessmentManager.swift
//  running_app
//
//  Created by 전진하 on 6/1/25.
//


//
//  FitnessAssessmentManager.swift
//  running_app
//
//  Created by AI Assistant on 6/1/25.
//

import Foundation
import SwiftUI

// MARK: - 체력 평가 및 목표 설정 매니저
class FitnessAssessmentManager: ObservableObject {
    static let shared = FitnessAssessmentManager()
    
    @Published var hasCompletedAssessment: Bool = false
    @Published var currentFitnessLevel: FitnessLevel = .beginner
    @Published var recommendedGoals: RunningGoals?
    @Published var assessmentWorkout: WorkoutSummary?
    @Published var progressTracker: ProgressTracker?
    
    private let userDefaults = UserDefaults.standard
    private let assessmentKey = "FitnessAssessment"
    private let goalsKey = "RunningGoals"
    
    private init() {
        loadAssessmentData()
    }
    
    // MARK: - 초기 체력 평가 (1km 달리기)
    func processAssessmentWorkout(_ workout: WorkoutSummary) {
        guard workout.distance >= 0.95 && workout.distance <= 1.1 else {
            print("⚠️ 평가 달리기는 1km 근처여야 합니다: \(workout.distance)km")
            return
        }
        
        assessmentWorkout = workout
        currentFitnessLevel = evaluateFitnessLevel(from: workout)
        recommendedGoals = generateInitialGoals(from: workout)
        progressTracker = ProgressTracker(initialGoals: recommendedGoals!)
        hasCompletedAssessment = true
        
        saveAssessmentData()
        
        print("✅ 체력 평가 완료: \(currentFitnessLevel.rawValue)")
        print("📊 추천 목표: \(recommendedGoals?.description ?? "없음")")
    }
    
    // MARK: - 체력 수준 평가
    private func evaluateFitnessLevel(from workout: WorkoutSummary) -> FitnessLevel {
        let pace = workout.averagePace // 초/km
        let heartRate = workout.averageHeartRate
        let efficiency = calculateEfficiency(workout)
        
        // 연령별 기준 조정
        let userAge = UserProfileManager.shared.userProfile.age
        let ageAdjustment = getAgeAdjustment(age: userAge)
        
        // 페이스 기준 (초/km)
        let adjustedPaceThresholds = PaceThresholds(
            excellent: 240 + ageAdjustment,  // 4분/km 기준
            good: 300 + ageAdjustment,       // 5분/km 기준
            average: 360 + ageAdjustment,    // 6분/km 기준
            poor: 480 + ageAdjustment        // 8분/km 기준
        )
        
        // 심박수 효율성 기준
        let efficiencyScore = efficiency * 1000 // 스케일링
        
        // 종합 평가
        let paceScore = getPaceScore(pace, thresholds: adjustedPaceThresholds)
        let efficiencyScore_normalized = getEfficiencyScore(efficiencyScore)
        let heartRateScore = getHeartRateScore(heartRate, age: userAge)
        
        let totalScore = (paceScore + efficiencyScore_normalized + heartRateScore) / 3
        
        switch totalScore {
        case 8...10: return .elite
        case 6..<8: return .advanced
        case 4..<6: return .intermediate
        case 2..<4: return .beginner
        default: return .novice
        }
    }
    
    // MARK: - 초기 목표 생성
    private func generateInitialGoals(from workout: WorkoutSummary) -> RunningGoals {
        let currentPace = workout.averagePace
        let currentDistance = workout.distance
        
        // 체력 수준에 따른 목표 설정
        let targetDistances = getTargetDistances(for: currentFitnessLevel)
        let targetPaces = getTargetPaces(currentPace: currentPace, level: currentFitnessLevel)
        
        return RunningGoals(
            shortTermDistance: targetDistances.shortTerm,
            mediumTermDistance: targetDistances.mediumTerm,
            longTermDistance: targetDistances.longTerm,
            targetPace: targetPaces.target,
            improvementPace: targetPaces.improvement,
            weeklyGoal: WeeklyGoal(
                runs: getWeeklyRuns(for: currentFitnessLevel),
                totalDistance: getWeeklyDistance(for: currentFitnessLevel),
                averagePace: targetPaces.target
            ),
            fitnessLevel: currentFitnessLevel,
            assessmentDate: Date()
        )
    }
    
    // MARK: - 진행상황 업데이트
    func updateProgress(with workout: WorkoutSummary) {
        guard hasCompletedAssessment,
              let tracker = progressTracker,
              let goals = recommendedGoals else { return }
        
        // 새로운 개인 기록 체크
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
                description: "신기록: \(paceString(workout.averagePace))"
            ))
        }
        
        // 주간 진행상황 업데이트
        tracker.updateWeeklyProgress(workout)
        
        // 목표 달성 체크
        checkGoalAchievements(workout: workout, tracker: tracker, goals: goals)
        
        // 체력 수준 재평가 (매 5회 운동마다)
        tracker.totalWorkouts += 1
        if tracker.totalWorkouts % 5 == 0 {
            reassessFitnessLevel()
        }
        
        saveAssessmentData()
    }
    
    // MARK: - 목표 달성 체크
    private func checkGoalAchievements(workout: WorkoutSummary, tracker: ProgressTracker, goals: RunningGoals) {
        // 거리 목표 달성
        if workout.distance >= goals.shortTermDistance && !tracker.achievedShortTermDistance {
            tracker.achievedShortTermDistance = true
            tracker.achievements.append(Achievement(
                title: "첫 목표 달성!",
                description: "\(String(format: "%.1f", goals.shortTermDistance))km 완주",
                date: workout.date,
                type: .distance
            ))
            
            // 다음 목표로 업그레이드
            upgradeGoals()
        }
        
        if workout.distance >= goals.mediumTermDistance && !tracker.achievedMediumTermDistance {
            tracker.achievedMediumTermDistance = true
            tracker.achievements.append(Achievement(
                title: "중급 목표 달성!",
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
                description: "목표: \(paceString(goals.targetPace))",
                date: workout.date,
                type: .pace
            ))
        }
    }
    
    // MARK: - 목표 업그레이드
    private func upgradeGoals() {
        guard let currentGoals = recommendedGoals,
              let tracker = progressTracker else { return }
        
        // 현재 최고 기록을 바탕으로 새로운 목표 설정
        let newShortTerm = min(currentGoals.mediumTermDistance, tracker.bestDistance + 1.0)
        let newMediumTerm = min(currentGoals.longTermDistance, tracker.bestDistance + 2.5)
        let newLongTerm = min(21.0, tracker.bestDistance + 5.0) // 하프마라톤까지
        
        // 페이스 목표도 개선
        let paceImprovement = 15.0 // 15초/km 개선
        let newTargetPace = max(240, tracker.bestPace - paceImprovement)
        let newImprovementPace = max(220, newTargetPace - 20)
        
        recommendedGoals = RunningGoals(
            shortTermDistance: newShortTerm,
            mediumTermDistance: newMediumTerm,
            longTermDistance: newLongTerm,
            targetPace: newTargetPace,
            improvementPace: newImprovementPace,
            weeklyGoal: WeeklyGoal(
                runs: min(5, currentGoals.weeklyGoal.runs + 1),
                totalDistance: currentGoals.weeklyGoal.totalDistance + 2.0,
                averagePace: newTargetPace
            ),
            fitnessLevel: currentFitnessLevel,
            assessmentDate: currentGoals.assessmentDate
        )
        
        // 달성 상태 리셋
        tracker.achievedShortTermDistance = false
        tracker.achievedMediumTermDistance = false
        tracker.achievedTargetPace = false
        
        print("🎯 목표 업그레이드: \(newShortTerm)km → \(newMediumTerm)km → \(newLongTerm)km")
    }
    
    // MARK: - 체력 수준 재평가
    private func reassessFitnessLevel() {
        guard let tracker = progressTracker else { return }
        
        // 최근 5회 운동의 평균 성능으로 재평가
        let recentWorkouts = getRecentWorkouts(count: 5)
        if recentWorkouts.count >= 3 {
            let avgPace = recentWorkouts.map { $0.averagePace }.average()
            let avgDistance = recentWorkouts.map { $0.distance }.average()
            let avgHeartRate = recentWorkouts.map { $0.averageHeartRate }.average()
            
            // 가상의 평가 운동 생성
            let evaluationWorkout = WorkoutSummary(
                date: Date(),
                duration: avgPace * avgDistance,
                distance: avgDistance,
                averageHeartRate: avgHeartRate,
                averagePace: avgPace,
                averageCadence: 175,
                dataPoints: []
            )
            
            let newLevel = evaluateFitnessLevel(from: evaluationWorkout)
            if newLevel != currentFitnessLevel {
                currentFitnessLevel = newLevel
                tracker.achievements.append(Achievement(
                    title: "체력 수준 향상!",
                    description: "새로운 등급: \(newLevel.displayName)",
                    date: Date(),
                    type: .level
                ))
                
                print("📈 체력 수준 업그레이드: \(newLevel.rawValue)")
            }
        }
    }
    
    // MARK: - 헬퍼 함수들
    private func calculateEfficiency(_ workout: WorkoutSummary) -> Double {
        guard workout.averageHeartRate > 0 && workout.averagePace > 0 else { return 0 }
        let speed = 3600 / workout.averagePace // km/h
        return speed / workout.averageHeartRate
    }
    
    private func getAgeAdjustment(age: Int) -> Double {
        switch age {
        case 15...25: return -15  // 젊은 층은 더 빠른 기준
        case 26...35: return 0    // 기본
        case 36...45: return 15   // 약간 여유
        case 46...55: return 30   // 더 여유
        default: return 45        // 시니어층
        }
    }
    
    private func getPaceScore(_ pace: Double, thresholds: PaceThresholds) -> Double {
        switch pace {
        case ...thresholds.excellent: return 10
        case thresholds.excellent..<thresholds.good: return 8
        case thresholds.good..<thresholds.average: return 6
        case thresholds.average..<thresholds.poor: return 4
        default: return 2
        }
    }
    
    private func getEfficiencyScore(_ efficiency: Double) -> Double {
        switch efficiency {
        case 80...: return 10
        case 60..<80: return 8
        case 40..<60: return 6
        case 20..<40: return 4
        default: return 2
        }
    }
    
    private func getHeartRateScore(_ heartRate: Double, age: Int) -> Double {
        let maxHR = 208 - (0.7 * Double(age))
        let percentage = heartRate / maxHR * 100
        
        switch percentage {
        case ...70: return 10  // 효율적
        case 70..<80: return 8
        case 80..<85: return 6
        case 85..<90: return 4
        default: return 2      // 너무 높음
        }
    }
    
    private func getTargetDistances(for level: FitnessLevel) -> (shortTerm: Double, mediumTerm: Double, longTerm: Double) {
        switch level {
        case .novice: return (1.5, 2.5, 5.0)
        case .beginner: return (2.0, 3.5, 5.0)
        case .intermediate: return (3.0, 5.0, 10.0)
        case .advanced: return (5.0, 10.0, 15.0)
        case .elite: return (10.0, 15.0, 21.0)
        }
    }
    
    private func getTargetPaces(currentPace: Double, level: FitnessLevel) -> (target: Double, improvement: Double) {
        let improvement: Double
        switch level {
        case .novice: improvement = 60    // 1분 개선 목표
        case .beginner: improvement = 45  // 45초 개선
        case .intermediate: improvement = 30 // 30초 개선
        case .advanced: improvement = 20  // 20초 개선
        case .elite: improvement = 10     // 10초 개선
        }
        
        let target = max(240, currentPace - improvement) // 최소 4분/km
        let ultimateImprovement = max(220, target - 20)   // 최종 목표
        
        return (target, ultimateImprovement)
    }
    
    private func getWeeklyRuns(for level: FitnessLevel) -> Int {
        switch level {
        case .novice: return 2
        case .beginner: return 3
        case .intermediate: return 3
        case .advanced: return 4
        case .elite: return 4
        }
    }
    
    private func getWeeklyDistance(for level: FitnessLevel) -> Double {
        switch level {
        case .novice: return 4.0
        case .beginner: return 6.0
        case .intermediate: return 10.0
        case .advanced: return 15.0
        case .elite: return 20.0
        }
    }
    
    private func getRecentWorkouts(count: Int) -> [WorkoutSummary] {
        // RunningDataManager에서 최근 운동 가져오기
        let allWorkouts = RunningDataManager().workouts
        return Array(allWorkouts.prefix(count))
    }
    
    private func paceString(_ pace: Double) -> String {
        let minutes = Int(pace) / 60
        let seconds = Int(pace) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // MARK: - 데이터 저장/로드
    private func saveAssessmentData() {
        if hasCompletedAssessment {
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
    
    // MARK: - 리셋 함수
    func resetAssessment() {
        hasCompletedAssessment = false
        currentFitnessLevel = .beginner
        recommendedGoals = nil
        progressTracker = nil
        assessmentWorkout = nil
        
        userDefaults.removeObject(forKey: assessmentKey)
        print("🔄 체력 평가 데이터 초기화 완료")
    }
}

// MARK: - 데이터 모델들
enum FitnessLevel: String, CaseIterable, Codable {
    case novice = "초보자"
    case beginner = "입문자"
    case intermediate = "중급자"
    case advanced = "상급자" 
    case elite = "엘리트"
    
    var displayName: String { rawValue }
    
    var color: Color {
        switch self {
        case .novice: return .red
        case .beginner: return .orange
        case .intermediate: return .yellow
        case .advanced: return .green
        case .elite: return .purple
        }
    }
    
    var icon: String {
        switch self {
        case .novice: return "figure.walk"
        case .beginner: return "figure.run"
        case .intermediate: return "figure.run.circle"
        case .advanced: return "figure.run.circle.fill"
        case .elite: return "crown.fill"
        }
    }
}

struct RunningGoals: Codable {
    let shortTermDistance: Double    // 단기 목표 (2-4주)
    let mediumTermDistance: Double   // 중기 목표 (2-3개월)
    let longTermDistance: Double     // 장기 목표 (6개월)
    let targetPace: Double          // 목표 페이스
    let improvementPace: Double     // 개선 목표 페이스
    let weeklyGoal: WeeklyGoal
    let fitnessLevel: FitnessLevel
    let assessmentDate: Date
    
    var description: String {
        return "단기: \(String(format: "%.1f", shortTermDistance))km, " +
               "중기: \(String(format: "%.1f", mediumTermDistance))km, " +
               "장기: \(String(format: "%.1f", longTermDistance))km"
    }
}

struct WeeklyGoal: Codable {
    let runs: Int              // 주간 운동 횟수
    let totalDistance: Double  // 주간 총 거리
    let averagePace: Double   // 목표 평균 페이스
}

struct Achievement: Codable, Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let date: Date
    let type: AchievementType
}

enum AchievementType: String, Codable {
    case distance = "거리"
    case pace = "페이스"
    case level = "등급"
    case consistency = "꾸준함"
    case improvement = "개선"
}

struct PersonalRecord: Codable, Identifiable {
    let id = UUID()
    let type: RecordType
    let value: Double
    let date: Date
    let description: String
}

enum RecordType: String, Codable {
    case distance = "최장거리"
    case pace = "최고페이스"
    case duration = "최장시간"
}

class ProgressTracker: ObservableObject, Codable {
    @Published var bestDistance: Double = 0
    @Published var bestPace: Double = 999
    @Published var totalWorkouts: Int = 0
    @Published var achievements: [Achievement] = []
    @Published var personalRecords: [PersonalRecord] = []
    @Published var weeklyStats: WeeklyStats = WeeklyStats(totalDistance: 0, workoutCount: 0, averageEfficiency: 0)
    
    // 목표 달성 상태
    @Published var achievedShortTermDistance: Bool = false
    @Published var achievedMediumTermDistance: Bool = false
    @Published var achievedTargetPace: Bool = false
    
    enum CodingKeys: CodingKey {
        case bestDistance, bestPace, totalWorkouts, achievements, personalRecords, weeklyStats
        case achievedShortTermDistance, achievedMediumTermDistance, achievedTargetPace
    }
    
    init(initialGoals: RunningGoals) {
        // 초기화
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        bestDistance = try container.decode(Double.self, forKey: .bestDistance)
        bestPace = try container.decode(Double.self, forKey: .bestPace)
        totalWorkouts = try container.decode(Int.self, forKey: .totalWorkouts)
        achievements = try container.decode([Achievement].self, forKey: .achievements)
        personalRecords = try container.decode([PersonalRecord].self, forKey: .personalRecords)
        weeklyStats = try container.decode(WeeklyStats.self, forKey: .weeklyStats)
        achievedShortTermDistance = try container.decode(Bool.self, forKey: .achievedShortTermDistance)
        achievedMediumTermDistance = try container.decode(Bool.self, forKey: .achievedMediumTermDistance)
        achievedTargetPace = try container.decode(Bool.self, forKey: .achievedTargetPace)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(bestDistance, forKey: .bestDistance)
        try container.encode(bestPace, forKey: .bestPace)
        try container.encode(totalWorkouts, forKey: .totalWorkouts)
        try container.encode(achievements, forKey: .achievements)
        try container.encode(personalRecords, forKey: .personalRecords)
        try container.encode(weeklyStats, forKey: .weeklyStats)
        try container.encode(achievedShortTermDistance, forKey: .achievedShortTermDistance)
        try container.encode(achievedMediumTermDistance, forKey: .achievedMediumTermDistance)
        try container.encode(achievedTargetPace, forKey: .achievedTargetPace)
    }
    
    func updateWeeklyProgress(_ workout: WorkoutSummary) {
        // 주간 통계 업데이트 로직
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        
        if workout.date >= weekAgo {
            weeklyStats.totalDistance += workout.distance
            weeklyStats.workoutCount += 1
            // 효율성 계산...
        }
    }
}

struct PaceThresholds {
    let excellent: Double
    let good: Double
    let average: Double
    let poor: Double
}

struct FitnessAssessmentData: Codable {
    let hasCompleted: Bool
    let fitnessLevel: FitnessLevel
    let goals: RunningGoals?
    let tracker: ProgressTracker?
    let assessmentWorkout: WorkoutSummary?
}

extension Array where Element == Double {
    func average() -> Double {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / Double(count)
    }
}