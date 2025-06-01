import Foundation
import SwiftUI

// MARK: - 기본 데이터 모델들
struct RunningDataPoint: Codable {
    let timestamp: Date
    let pace: Double
    let heartRate: Double
    let cadence: Double
    let distance: Double
}

struct WorkoutSummary: Codable, Identifiable {
    let id: UUID
    let date: Date
    let duration: TimeInterval
    let distance: Double
    let averageHeartRate: Double
    let averagePace: Double
    let averageCadence: Double
    let dataPoints: [RunningDataPoint]
    
    // 기본 이니셜라이저 (새 워크아웃용 - Watch에서 받을 때)
    init(date: Date, duration: TimeInterval, distance: Double, averageHeartRate: Double, averagePace: Double, averageCadence: Double, dataPoints: [RunningDataPoint]) {
        self.id = UUID()
        self.date = date
        self.duration = duration
        self.distance = distance
        self.averageHeartRate = averageHeartRate
        self.averagePace = averagePace
        self.averageCadence = averageCadence
        self.dataPoints = dataPoints
    }
    
    // Core Data 복원용 이니셜라이저 (CoreDataManager에서 사용)
    init(id: UUID, date: Date, duration: TimeInterval, distance: Double, averageHeartRate: Double, averagePace: Double, averageCadence: Double, dataPoints: [RunningDataPoint]) {
        self.id = id
        self.date = date
        self.duration = duration
        self.distance = distance
        self.averageHeartRate = averageHeartRate
        self.averagePace = averagePace
        self.averageCadence = averageCadence
        self.dataPoints = dataPoints
    }
}

struct RealtimeData {
    let timestamp: TimeInterval
    let elapsedTime: TimeInterval
    let currentPace: Double
    let heartRate: Double
    let cadence: Double
    let distance: Double
    let currentCalories: Double // 칼로리 추가
    let recentPaces: [Double]
    let recentCadences: [Double]
    let recentHeartRates: [Double]
    let isWarningActive: Bool
    let warningMessage: String
}

// MARK: - 분석 결과 데이터 모델들
struct EfficiencyMetrics {
    let paceCV: Double
    let averageEfficiency: Double
    let optimalCadenceRange: (Double, Double)
}

struct WeeklyStats {
    let totalDistance: Double
    let workoutCount: Int
    let averageEfficiency: Double
}

struct LongTermTrends {
    let efficiencyImprovement: Double
    let distanceImprovement: Double
    let recoveryPattern: String
}

struct OvertrainingAssessment {
    let level: OvertrainingLevel
    let recommendedRestDays: Int
    let recommendations: [String]
}

enum OvertrainingLevel: String, CaseIterable {
    case low = "낮음"
    case medium = "보통"
    case high = "높음"
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
}

struct CadenceData {
    let currentAverage: Double
    let optimalRange: (Double, Double)
    let inRangePercentage: Double
}

// MARK: - LocalAnalysisEngine 결과 타입들
struct PaceStabilityResult {
    let cv: Double
    let level: StabilityLevel
    let warning: String
}

enum StabilityLevel {
    case stable, moderate, unstable, insufficient
}

struct EfficiencyResult {
    let averageEfficiency: Double
    let trend: Double
    let recommendation: String
}

struct CadenceOptimizationResult {
    let optimalRange: (Double, Double)
    let currentAverage: Double
    let recommendation: String
}

struct OvertrainingRiskResult {
    let level: OvertrainingLevel
    let riskScore: Double
    let recommendations: [String]
}

struct WorkoutAnalysisResult {
    let paceStability: PaceStabilityResult
    let efficiency: EfficiencyResult
    let cadenceOptimization: CadenceOptimizationResult
}

// MARK: - 트렌드 분석용 enum
enum TrendDirection {
    case improving, declining, stable
    
    var iconName: String {
        switch self {
        case .improving: return "arrow.up.circle.fill"
        case .declining: return "arrow.down.circle.fill"
        case .stable: return "minus.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .improving: return .green
        case .declining: return .red
        case .stable: return .orange
        }
    }
}

// MARK: - 헬퍼 함수들
func zip3<A, B, C>(_ a: [A], _ b: [B], _ c: [C]) -> [(A, B, C)] {
    let minCount = min(a.count, b.count, c.count)
    return (0..<minCount).map { (a[$0], b[$0], c[$0]) }
}

extension Array where Element == Double {
    func average() -> Double {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / Double(count)
    }
}
