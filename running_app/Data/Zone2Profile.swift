import Foundation
import SwiftUI

// MARK: - Zone 2 프로필
struct Zone2Profile: Codable {
    let zone2Range: ClosedRange<Double>  // Zone 2 심박수 범위
    let maxSustainableDistance: Double   // Zone 2 최대 지속 거리
    let maxSustainableTime: Double       // Zone 2 최대 지속 시간 (초)
    let averageZone2Pace: Double         // Zone 2 평균 페이스
    let zone2TimePercentage: Double      // Zone 2 유지 시간 비율
    let zone2Efficiency: Double          // Zone 2 효율성 지수
    let assessmentDate: Date
    
    enum CodingKeys: CodingKey {
        case zone2Range_lower, zone2Range_upper
        case maxSustainableDistance, maxSustainableTime, averageZone2Pace
        case zone2TimePercentage, zone2Efficiency, assessmentDate
    }
    
    init(zone2Range: ClosedRange<Double>, maxSustainableDistance: Double, maxSustainableTime: Double,
         averageZone2Pace: Double, zone2TimePercentage: Double, zone2Efficiency: Double, assessmentDate: Date) {
        self.zone2Range = zone2Range
        self.maxSustainableDistance = maxSustainableDistance
        self.maxSustainableTime = maxSustainableTime
        self.averageZone2Pace = averageZone2Pace
        self.zone2TimePercentage = zone2TimePercentage
        self.zone2Efficiency = zone2Efficiency
        self.assessmentDate = assessmentDate
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let lower = try container.decode(Double.self, forKey: .zone2Range_lower)
        let upper = try container.decode(Double.self, forKey: .zone2Range_upper)
        zone2Range = lower...upper
        maxSustainableDistance = try container.decode(Double.self, forKey: .maxSustainableDistance)
        maxSustainableTime = try container.decode(Double.self, forKey: .maxSustainableTime)
        averageZone2Pace = try container.decode(Double.self, forKey: .averageZone2Pace)
        zone2TimePercentage = try container.decode(Double.self, forKey: .zone2TimePercentage)
        zone2Efficiency = try container.decode(Double.self, forKey: .zone2Efficiency)
        assessmentDate = try container.decode(Date.self, forKey: .assessmentDate)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(zone2Range.lowerBound, forKey: .zone2Range_lower)
        try container.encode(zone2Range.upperBound, forKey: .zone2Range_upper)
        try container.encode(maxSustainableDistance, forKey: .maxSustainableDistance)
        try container.encode(maxSustainableTime, forKey: .maxSustainableTime)
        try container.encode(averageZone2Pace, forKey: .averageZone2Pace)
        try container.encode(zone2TimePercentage, forKey: .zone2TimePercentage)
        try container.encode(zone2Efficiency, forKey: .zone2Efficiency)
        try container.encode(assessmentDate, forKey: .assessmentDate)
    }
}

// MARK: - Zone 2 능력 점수 (0-100점 연속적 평가)
struct Zone2CapacityScore: Codable {
    let totalScore: Double      // 총 점수 (0-100)
    let distanceScore: Double   // 거리 점수 (0-100)
    let timeScore: Double       // 시간 점수 (0-100)
    let consistencyScore: Double // 일관성 점수 (0-100)
    let efficiencyScore: Double // 효율성 점수 (0-100)
    
    var description: String {
        return "Zone 2 능력: \(Int(totalScore))/100점"
    }
    
    var strengthAreas: [String] {
        var strengths: [String] = []
        if distanceScore >= 70 { strengths.append("장거리 지속력") }
        if timeScore >= 70 { strengths.append("시간 지속력") }
        if consistencyScore >= 80 { strengths.append("Zone 2 일관성") }
        if efficiencyScore >= 70 { strengths.append("유산소 효율성") }
        return strengths
    }
    
    var improvementAreas: [String] {
        var improvements: [String] = []
        if distanceScore < 50 { improvements.append("거리 늘리기") }
        if timeScore < 50 { improvements.append("지속 시간") }
        if consistencyScore < 70 { improvements.append("Zone 2 유지") }
        if efficiencyScore < 50 { improvements.append("효율성 향상") }
        return improvements
    }
    
    var scoreColor: Color {
        switch totalScore {
        case 80...: return .green
        case 60..<80: return .blue
        case 40..<60: return .orange
        default: return .red
        }
    }
}

// MARK: - Zone 2 목표
struct Zone2Goals: Codable {
    let shortTermDistance: Double    // 단기 목표 (2-4주)
    let mediumTermDistance: Double   // 중기 목표 (2-3개월)
    let longTermDistance: Double     // 장기 목표 (6개월)
    let targetPace: Double          // 목표 페이스
    let improvementPace: Double     // 개선 목표 페이스
    let weeklyGoal: Zone2WeeklyGoal
    let assessmentDate: Date
    
    var description: String {
        return "단기: \(String(format: "%.1f", shortTermDistance))km, " +
               "중기: \(String(format: "%.1f", mediumTermDistance))km, " +
               "장기: \(String(format: "%.1f", longTermDistance))km"
    }
}

struct Zone2WeeklyGoal: Codable {
    let runs: Int              // 주간 운동 횟수
    let totalDistance: Double  // 주간 총 거리
    let averagePace: Double   // 목표 평균 페이스
}

// MARK: - Zone 2 성취 및 기록
struct Zone2Achievement: Codable, Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let date: Date
    let type: Zone2AchievementType
}

enum Zone2AchievementType: String, Codable {
    case distance = "거리"
    case pace = "페이스"
    case consistency = "꾸준함"
    case improvement = "개선"
    case zone2 = "Zone 2"
}

struct Zone2PersonalRecord: Codable, Identifiable {
    let id = UUID()
    let type: Zone2RecordType
    let value: Double
    let date: Date
    let description: String
}

enum Zone2RecordType: String, Codable {
    case distance = "최장거리"
    case pace = "최고페이스"
    case duration = "최장시간"
    case zone2Duration = "Zone 2 최장시간"
    case zone2Distance = "Zone 2 최장거리"
}

// MARK: - Zone 2 통계
struct Zone2WeeklyStats: Codable {
    let totalDistance: Double
    let workoutCount: Int
    let averageEfficiency: Double
    
    init(totalDistance: Double = 0, workoutCount: Int = 0, averageEfficiency: Double = 0) {
        self.totalDistance = totalDistance
        self.workoutCount = workoutCount
        self.averageEfficiency = averageEfficiency
    }
}

// MARK: - Zone 2 운동 성과
struct Zone2Performance {
    let timeInZone: Double      // Zone 2 유지 시간 비율
    let averagePace: Double     // Zone 2 구간 평균 페이스
    let efficiency: Double      // Zone 2 효율성
}

struct Zone2WorkoutPerformance {
    let timeInZonePercentage: Double
    let efficiency: Double
    let consistency: Double
    let maxContinuousTime: Double
}

// MARK: - Zone 2 평가 데이터
struct Zone2AssessmentData: Codable {
    let hasCompleted: Bool
    let zone2CapacityScore: Zone2CapacityScore?
    let goals: Zone2Goals?
    let tracker: Zone2ProgressTracker?
    let assessmentWorkout: WorkoutSummary?
    let zone2Profile: Zone2Profile?
}
