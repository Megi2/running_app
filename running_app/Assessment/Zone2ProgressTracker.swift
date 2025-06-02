import Foundation

class Zone2ProgressTracker: ObservableObject, Codable {
    @Published var bestDistance: Double = 0
    @Published var bestPace: Double = 999
    @Published var totalWorkouts: Int = 0
    @Published var achievements: [Zone2Achievement] = []
    @Published var personalRecords: [Zone2PersonalRecord] = []
    @Published var weeklyStats: Zone2WeeklyStats = Zone2WeeklyStats(totalDistance: 0, workoutCount: 0, averageEfficiency: 0)
    
    // 목표 달성 상태
    @Published var achievedShortTermDistance: Bool = false
    @Published var achievedMediumTermDistance: Bool = false
    @Published var achievedTargetPace: Bool = false
    
    // Zone 2 특화 기록들
    @Published var bestZone2Distance: Double = 0
    @Published var bestZone2Duration: Double = 0
    @Published var bestZone2Consistency: Double = 0  // 최고 Zone 2 유지율
    
    enum CodingKeys: CodingKey {
        case bestDistance, bestPace, totalWorkouts, achievements, personalRecords, weeklyStats
        case achievedShortTermDistance, achievedMediumTermDistance, achievedTargetPace
        case bestZone2Distance, bestZone2Duration, bestZone2Consistency
    }
    
    init(initialGoals: Zone2Goals) {
        // 초기화
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        bestDistance = try container.decode(Double.self, forKey: .bestDistance)
        bestPace = try container.decode(Double.self, forKey: .bestPace)
        totalWorkouts = try container.decode(Int.self, forKey: .totalWorkouts)
        achievements = try container.decode([Zone2Achievement].self, forKey: .achievements)
        personalRecords = try container.decode([Zone2PersonalRecord].self, forKey: .personalRecords)
        weeklyStats = try container.decode(Zone2WeeklyStats.self, forKey: .weeklyStats)
        achievedShortTermDistance = try container.decode(Bool.self, forKey: .achievedShortTermDistance)
        achievedMediumTermDistance = try container.decode(Bool.self, forKey: .achievedMediumTermDistance)
        achievedTargetPace = try container.decode(Bool.self, forKey: .achievedTargetPace)
        
        // Zone 2 특화 필드들 (기본값 제공)
        bestZone2Distance = try container.decodeIfPresent(Double.self, forKey: .bestZone2Distance) ?? 0
        bestZone2Duration = try container.decodeIfPresent(Double.self, forKey: .bestZone2Duration) ?? 0
        bestZone2Consistency = try container.decodeIfPresent(Double.self, forKey: .bestZone2Consistency) ?? 0
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
        try container.encode(bestZone2Distance, forKey: .bestZone2Distance)
        try container.encode(bestZone2Duration, forKey: .bestZone2Duration)
        try container.encode(bestZone2Consistency, forKey: .bestZone2Consistency)
    }
    
    // MARK: - 진행상황 업데이트
    func updateWeeklyProgress(_ workout: WorkoutSummary) {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        
        if workout.date >= weekAgo {
            weeklyStats = Zone2WeeklyStats(
                totalDistance: weeklyStats.totalDistance + workout.distance,
                workoutCount: weeklyStats.workoutCount + 1,
                averageEfficiency: weeklyStats.averageEfficiency // 별도 계산 필요
            )
        }
    }
    
    // MARK: - Zone 2 기록 업데이트
    func updateZone2Records(_ performance: Zone2WorkoutPerformance, workout: WorkoutSummary) {
        // Zone 2 최장 거리 기록
        if workout.distance > bestZone2Distance && performance.timeInZonePercentage >= 80 {
            bestZone2Distance = workout.distance
            personalRecords.append(Zone2PersonalRecord(
                type: .zone2Distance,
                value: workout.distance,
                date: workout.date,
                description: "Zone 2 최장거리: \(String(format: "%.2f", workout.distance))km"
            ))
        }
        
        // Zone 2 최장 시간 기록
        if workout.duration > bestZone2Duration && performance.timeInZonePercentage >= 80 {
            bestZone2Duration = workout.duration
            personalRecords.append(Zone2PersonalRecord(
                type: .zone2Duration,
                value: workout.duration,
                date: workout.date,
                description: "Zone 2 최장시간: \(Int(workout.duration/60))분"
            ))
        }
        
        // Zone 2 일관성 기록
        if performance.timeInZonePercentage > bestZone2Consistency {
            bestZone2Consistency = performance.timeInZonePercentage
            personalRecords.append(Zone2PersonalRecord(
                type: .zone2Distance, // 임시로 distance 타입 사용
                value: performance.timeInZonePercentage,
                date: workout.date,
                description: "Zone 2 최고 유지율: \(String(format: "%.1f", performance.timeInZonePercentage))%"
            ))
        }
        
        totalWorkouts += 1
    }
    
    // MARK: - 성취 추가
    func addAchievement(_ achievement: Zone2Achievement) {
        achievements.append(achievement)
    }
}
