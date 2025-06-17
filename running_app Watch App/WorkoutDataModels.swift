//
//  WorkoutSummary.swift
//  running_app
//
//  Created by 전진하 on 6/17/25.
//


import Foundation

// MARK: - 워크아웃 요약 구조체
struct WorkoutSummary: Identifiable, Codable {
    let id: UUID
    let date: Date
    let duration: TimeInterval
    let distance: Double
    let averageHeartRate: Double
    let averagePace: Double
    let averageCadence: Double
    let dataPoints: [RunningDataPoint]
    
    init(id: UUID = UUID(), date: Date, duration: TimeInterval, distance: Double, 
         averageHeartRate: Double, averagePace: Double, averageCadence: Double, 
         dataPoints: [RunningDataPoint] = []) {
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

// MARK: - 러닝 데이터 포인트
struct RunningDataPoint: Identifiable, Codable {
    let id = UUID()
    let timestamp: TimeInterval
    let pace: Double
    let heartRate: Double
    let cadence: Double
    let distance: Double
    
    init(timestamp: TimeInterval, pace: Double, heartRate: Double, cadence: Double, distance: Double) {
        self.timestamp = timestamp
        self.pace = pace
        self.heartRate = heartRate
        self.cadence = cadence
        self.distance = distance
    }
}

// MARK: - 실시간 데이터 구조체 (iPhone과 동일한 구조)
struct RealtimeData: Codable {
    let timestamp: TimeInterval
    var elapsedTime: TimeInterval
    let currentPace: Double
    let heartRate: Double
    let cadence: Double
    var distance: Double
    let currentCalories: Double
    let recentPaces: [Double]
    let recentCadences: [Double]
    let recentHeartRates: [Double]
    let isWarningActive: Bool
    let warningMessage: String
    
    init(timestamp: TimeInterval, elapsedTime: TimeInterval, currentPace: Double,
         heartRate: Double, cadence: Double, distance: Double, currentCalories: Double,
         recentPaces: [Double] = [], recentCadences: [Double] = [], recentHeartRates: [Double] = [],
         isWarningActive: Bool = false, warningMessage: String = "") {
        self.timestamp = timestamp
        self.elapsedTime = elapsedTime
        self.currentPace = currentPace
        self.heartRate = heartRate
        self.cadence = cadence
        self.distance = distance
        self.currentCalories = currentCalories
        self.recentPaces = recentPaces
        self.recentCadences = recentCadences
        self.recentHeartRates = recentHeartRates
        self.isWarningActive = isWarningActive
        self.warningMessage = warningMessage
    }
}