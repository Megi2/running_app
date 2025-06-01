//
//  RunningDataPoint.swift
//  running_app
//
//  Created by 전진하 on 5/29/25.
//


import Foundation

// MARK: - 워치 데이터 모델들
struct RunningDataPoint: Codable {
    let timestamp: Date
    let pace: Double
    let heartRate: Double
    let cadence: Double
    let distance: Double
}

struct WorkoutSummary: Codable {
    let date: Date
    let duration: TimeInterval
    let distance: Double
    let averageHeartRate: Double
    let averagePace: Double
    let averageCadence: Double
    let dataPoints: [RunningDataPoint]
}