//
//  UserProfile.swift
//  running_app
//
//  Created by 전진하 on 6/1/25.
//


import Foundation
import SwiftUI

// MARK: - 사용자 프로필 데이터 모델 (단순화)
struct UserProfile: Codable {
    let id: UUID
    var gender: Gender
    var age: Int
    var weight: Double // kg
    var height: Double // cm
    var createdDate: Date
    var isCompleted: Bool
    
    init() {
        self.id = UUID()
        self.gender = .male
        self.age = 25
        self.weight = 70.0
        self.height = 170.0
        self.createdDate = Date()
        self.isCompleted = false
    }
    
    // MARK: - 계산된 속성들
    
    /// 최대 심박수 계산 (Tanaka 공식)
    var maxHeartRate: Double {
        return 208 - (0.7 * Double(age))
    }
    
    /// 안정시 심박수 추정 (성별 기반)
    var restingHeartRate: Double {
        return gender == .male ? 65 : 70
    }
    
    /// 심박수 존 계산 (Karvonen 공식)
    var heartRateZones: HeartRateZones {
        let maxHR = maxHeartRate
        let restHR = restingHeartRate
        let hrReserve = maxHR - restHR
        
        return HeartRateZones(
            zone1: restHR + (hrReserve * 0.5)...restHR + (hrReserve * 0.6), // 50-60% - 지방연소
            zone2: restHR + (hrReserve * 0.6)...restHR + (hrReserve * 0.7), // 60-70% - 유산소
            zone3: restHR + (hrReserve * 0.7)...restHR + (hrReserve * 0.8), // 70-80% - 유산소 파워
            zone4: restHR + (hrReserve * 0.8)...restHR + (hrReserve * 0.9), // 80-90% - 무산소
            zone5: restHR + (hrReserve * 0.9)...maxHR                       // 90-100% - 뉴로파워
        )
    }
    
    /// BMI 계산
    var bmi: Double {
        let heightInMeters = height / 100
        return weight / (heightInMeters * heightInMeters)
    }
    
    /// BMI 카테고리
    var bmiCategory: String {
        switch bmi {
        case ..<18.5: return "저체중"
        case 18.5..<25: return "정상"
        case 25..<30: return "과체중"
        default: return "비만"
        }
    }
    
    /// 칼로리 소모량 계산 (MET 기반)
    func calculateCalories(pace: Double, duration: TimeInterval) -> Double {
        guard pace > 0 && duration > 0 else { return 0 }
        
        // 페이스를 속도(km/h)로 변환
        let speedKmh = 3600 / pace
        
        // 속도에 따른 METs 값
        let mets: Double
        switch speedKmh {
        case 0..<4: mets = 4.0      // 걷기
        case 4..<6: mets = 6.0      // 느린 조깅
        case 6..<8: mets = 8.3      // 조깅
        case 8..<9: mets = 9.8      // 달리기
        case 9..<10: mets = 10.5    // 6분/km
        case 10..<11: mets = 11.0   // 5분 30초/km
        case 11..<12: mets = 11.8   // 5분/km
        case 12..<13: mets = 12.8   // 4분 30초/km
        case 13..<14: mets = 13.8   // 4분/km
        case 14..<16: mets = 15.3   // 빠른 달리기
        default: mets = 18.0        // 매우 빠른 달리기
        }
        
        // 칼로리 계산: METs × 몸무게(kg) × 시간(시간)
        let durationInHours = duration / 3600
        return mets * weight * durationInHours
    }
    
    /// 실시간 칼로리율 계산 (분당 칼로리)
    func caloriesPerMinute(pace: Double) -> Double {
        return calculateCalories(pace: pace, duration: 60) // 1분간 칼로리
    }
}

// MARK: - 열거형 정의
enum Gender: String, CaseIterable, Codable {
    case male = "남성"
    case female = "여성"
    
    var icon: String {
        switch self {
        case .male: return "person.fill"
        case .female: return "person.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .male: return .blue
        case .female: return .pink
        }
    }
}

// MARK: - 심박수 존 데이터
struct HeartRateZones {
    let zone1: ClosedRange<Double> // 50-60% - 지방연소
    let zone2: ClosedRange<Double> // 60-70% - 유산소
    let zone3: ClosedRange<Double> // 70-80% - 유산소 파워
    let zone4: ClosedRange<Double> // 80-90% - 무산소
    let zone5: ClosedRange<Double> // 90-100% - 뉴로파워
    
    func getZone(for heartRate: Double) -> Int? {
        if zone1.contains(heartRate) { return 1 }
        if zone2.contains(heartRate) { return 2 }
        if zone3.contains(heartRate) { return 3 }
        if zone4.contains(heartRate) { return 4 }
        if zone5.contains(heartRate) { return 5 }
        return nil
    }
    
    func getZoneColor(for zone: Int) -> Color {
        switch zone {
        case 1: return .gray
        case 2: return .blue
        case 3: return .green
        case 4: return .orange
        case 5: return .red
        default: return .primary
        }
    }
    
    func getZoneName(for zone: Int) -> String {
        switch zone {
        case 1: return "지방연소"
        case 2: return "유산소"
        case 3: return "유산소 파워"
        case 4: return "무산소"
        case 5: return "뉴로파워"
        default: return "알 수 없음"
        }
    }
}