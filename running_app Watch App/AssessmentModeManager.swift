//
//  AssessmentModeManager.swift
//  running_app
//
//  Created by 전진하 on 6/16/25.
//


//
//  AssessmentModeManager.swift
//  running_app Watch App
//
//  Zone 2 평가 모드 관리
//

import Foundation
import SwiftUI
import WatchConnectivity

class AssessmentModeManager: ObservableObject {
    static let shared = AssessmentModeManager()
    
    @Published var isAssessmentMode = false
    @Published var assessmentInstructions = ""
    @Published var targetZone2Range: ClosedRange<Double> = 130...150
    @Published var showAssessmentScreen = false
    
    private init() {}
    
    // MARK: - 평가 모드 시작
    func startAssessmentMode(instructions: String, zone2Range: ClosedRange<Double>) {
        print("📊 Zone 2 평가 모드 시작")
        print("🫀 목표 심박수 범위: \(Int(zone2Range.lowerBound))-\(Int(zone2Range.upperBound)) bpm")
        
        DispatchQueue.main.async {
            self.isAssessmentMode = true
            self.assessmentInstructions = instructions
            self.targetZone2Range = zone2Range
            self.showAssessmentScreen = true
        }
        
        // 알림 발송
        NotificationCenter.default.post(
            name: NSNotification.Name("AssessmentModeStarted"),
            object: nil
        )
    }
    
    // MARK: - 평가 모드 종료
    func stopAssessmentMode() {
        print("📊 Zone 2 평가 모드 종료")
        
        DispatchQueue.main.async {
            self.isAssessmentMode = false
            self.showAssessmentScreen = false
            self.assessmentInstructions = ""
        }
        
        // 알림 발송
        NotificationCenter.default.post(
            name: NSNotification.Name("AssessmentModeEnded"),
            object: nil
        )
    }
    
    // MARK: - 평가 운동 시작
    func startAssessmentWorkout() {
        print("🏃‍♂️ Zone 2 평가 운동 시작")
        
        // 평가 모드 화면 숨기고 운동 화면으로 전환
        DispatchQueue.main.async {
            self.showAssessmentScreen = false
        }
        
        // 워크아웃 매니저에게 평가 모드임을 알림
        NotificationCenter.default.post(
            name: NSNotification.Name("StartAssessmentWorkout"),
            object: ["isAssessment": true, "zone2Range": targetZone2Range]
        )
    }
    
    // MARK: - 메시지 처리
    func handleAssessmentMessage(_ message: [String: Any]) {
        print("📱 평가 모드 메시지 수신: \(message)")
        
        if let messageType = message["type"] as? String {
            switch messageType {
            case "start_zone2_assessment":
                let instructions = message["instructions"] as? String ?? "Zone 2에서 최대한 오래 달려보세요"
                let lowerBound = message["zone2_lower"] as? Double ?? 130
                let upperBound = message["zone2_upper"] as? Double ?? 150
                let zone2Range = lowerBound...upperBound
                
                startAssessmentMode(instructions: instructions, zone2Range: zone2Range)
                
            case "stop_zone2_assessment":
                stopAssessmentMode()
                
            default:
                print("⚠️ 알 수 없는 평가 메시지 타입: \(messageType)")
            }
        }
    }
}