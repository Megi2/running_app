//
//  FitnessAssessmentDataModels.swift
//  running_app
//
//  Running 타입 정의 (Zone2와 분리)
//

import Foundation
import SwiftUI

// MARK: - 체력 수준
struct FitnessLevel: Codable {
    let score: Double  // 0-100 점수
    let date: Date
    
    var displayName: String {
        return "체력 점수: \(Int(score))/100"
    }
    
    var color: Color {
        switch score {
        case 80...: return .green
        case 60..<80: return .blue
        case 40..<60: return .orange
        default: return .red
        }
    }
    
    var icon: String {
        switch score {
        case 80...: return "crown.fill"
        case 60..<80: return "figure.run.circle.fill"
        case 40..<60: return "figure.run.circle"
        default: return "figure.run"
        }
    }
    
    var description: String {
        switch score {
        case 80...: return "매우 우수한 체력"
        case 60..<80: return "좋은 체력"
        case 40..<60: return "보통 체력"
        default: return "향상 필요"
        }
    }
}

// MARK: - 러닝 목표
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

// MARK: - 주간 목표
struct WeeklyGoal: Codable {
    let runs: Int              // 주간 운동 횟수
    let totalDistance: Double  // 주간 총 거리
    let averagePace: Double   // 목표 평균 페이스
}

// MARK: - 성취
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

// MARK: - 개인 기록
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

// MARK: - 진행 상황 추적
class ProgressTracker: ObservableObject, Codable {
    @Published var bestDistance: Double = 0
    @Published var bestPace: Double = 999
    @Published var totalWorkouts: Int = 0
    @Published var achievements: [Achievement] = []
    @Published var personalRecords: [PersonalRecord] = []
    @Published var weeklyStats: WeeklyStats = WeeklyStats()
    
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
            let efficiency = workout.averageHeartRate > 0 && workout.averagePace > 0 ?
                (3600 / workout.averagePace) / workout.averageHeartRate : 0
            weeklyStats.addWorkout(distance: workout.distance, efficiency: efficiency)
        }
        
        // 개인 기록 업데이트
        if workout.distance > bestDistance {
            bestDistance = workout.distance
            personalRecords.append(PersonalRecord(
                type: .distance,
                value: workout.distance,
                date: workout.date,
                description: "신기록: \(String(format: "%.2f", workout.distance))km"
            ))
        }
        
        if workout.averagePace < bestPace && workout.averagePace > 0 {
            bestPace = workout.averagePace
            personalRecords.append(PersonalRecord(
                type: .pace,
                value: workout.averagePace,
                date: workout.date,
                description: "신기록: \(paceString(from: workout.averagePace))"
            ))
        }
        
        totalWorkouts += 1
    }
    
    private func paceString(from pace: Double) -> String {
        let minutes = Int(pace) / 60
        let seconds = Int(pace) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
