//
//  WorkoutManger+WacthConnectivity.swift
//  running_app
//
//  Created by 전진하 on 6/17/25.
//


import Foundation
import WatchConnectivity

// MARK: - Watch Connectivity 관련 기능
extension WorkoutManager {
    
    // MARK: - 실시간 데이터 전송
    func startRealtimeDataTransmission() {
        realtimeDataTimer = Timer.scheduledTimer(withTimeInterval: realtimeDataInterval, repeats: true) { _ in
            self.sendRealtimeDataToPhone()
        }
        print("⌚ 실시간 데이터 전송 시작")
    }
    
    func stopRealtimeDataTransmission() {
        realtimeDataTimer?.invalidate()
        realtimeDataTimer = nil
        print("⌚ 실시간 데이터 전송 중단")
    }
    
    private func sendRealtimeDataToPhone() {
        let realtimeData: [String: Any] = [
            "type": "realtime_data",
            "timestamp": Date().timeIntervalSince1970,
            "elapsed_time": elapsedTime,
            "current_pace": currentPace,
            "heart_rate": heartRate,
            "cadence": cadence,
            "distance": distance,
            "current_calories": currentCalories,
            "recent_paces": Array(recentPaces.suffix(maxRecentDataCount)),
            "recent_cadences": Array(recentCadences.suffix(maxRecentDataCount)),
            "recent_heart_rates": Array(recentHeartRates.suffix(maxRecentDataCount)),
            "is_warning_active": isWarningActive,
            "warning_message": warningMessage,
            "is_assessment": isAssessmentMode
        ]
        
        // 1차: transferUserInfo 사용 (안정적)
        WCSession.default.transferUserInfo(realtimeData)
        
        // 2차: sendMessage도 시도 (빠른 전송)
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(realtimeData, replyHandler: nil) { error in
                print("⌚⚠️ 즉시 전송 실패: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - 최종 워크아웃 데이터 전송
    func sendFinalWorkoutData() {
        let workoutSummary = WorkoutSummary(
            date: workoutStartTime ?? Date(),
            duration: elapsedTime,
            distance: distance,
            averageHeartRate: calculateAverage(runningData.compactMap { $0.heartRate > 0 ? $0.heartRate : nil }),
            averagePace: calculateAverage(runningData.compactMap { $0.pace > 0 ? $0.pace : nil }),
            averageCadence: calculateAverage(runningData.compactMap { $0.cadence > 0 ? $0.cadence : nil }),
            dataPoints: runningData
        )
        
        guard let workoutData = try? JSONEncoder().encode(workoutSummary) else {
            print("❌ 워크아웃 데이터 인코딩 실패")
            return
        }
        
        let finalData: [String: Any] = [
            "type": isAssessmentMode ? "assessment_complete" : "workout_complete",
            "workoutData": workoutData,
            "isAssessment": isAssessmentMode,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        // 안정적 전송
        WCSession.default.transferUserInfo(finalData)
        
        // 즉시 전송 시도
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(finalData, replyHandler: { _ in
                print("⌚✅ 워크아웃 완료 데이터 즉시 전송 성공")
            }) { error in
                print("⌚⚠️ 즉시 전송 실패, 백그라운드 전송으로 대체")
            }
        }
        
        print("⌚ 워크아웃 완료 데이터 전송: \(isAssessmentMode ? "평가" : "일반") 모드")
    }
    
    func sendWorkoutEndSignal() {
        let endSignalData: [String: Any] = [
            "type": "workout_end_signal",
            "isAssessment": isAssessmentMode,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        // 안정적 전송
        WCSession.default.transferUserInfo(endSignalData)
        
        // 즉시 전송 시도
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(endSignalData, replyHandler: nil) { error in
                print("⌚⚠️ 종료 신호 즉시 전송 실패")
            }
        }
        
        print("⌚ 워크아웃 종료 신호 전송 완료")
    }
}

// MARK: - WCSessionDelegate
extension WorkoutManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            print("⌚ Watch Connectivity 활성화 완료: \(activationState.rawValue)")
            if let error = error {
                print("❌ Watch 활성화 오류: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - 메시지 수신 처리
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("📱 iPhone으로부터 즉시 메시지 수신: \(message)")
        DispatchQueue.main.async {
            self.handleIncomingMessage(message, source: "SendMessage")
        }
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any]) {
        print("📱 iPhone으로부터 UserInfo 수신: \(userInfo)")
        DispatchQueue.main.async {
            self.handleIncomingMessage(userInfo, source: "TransferUserInfo")
        }
    }
    
    // MARK: - 통합 메시지 처리
    private func handleIncomingMessage(_ message: [String: Any], source: String) {
        print("📱 메시지 처리 시작 (\(source)): \(message)")
        
        guard let messageType = message["type"] as? String else {
            print("⚠️ 메시지 타입이 없음. 레거시 처리 시도...")
            handleLegacyMessage(message)
            return
        }
        
        switch messageType {
        case "start_assessment":
            print("📊 평가 시작 신호 수신")
            startWorkout(isAssessment: true)
            
        case "user_profile_sync":
            print("👤 사용자 프로필 동기화 수신")
            handleUserProfileSync(message)
            
        default:
            print("⚠️ 알 수 없는 메시지 타입: \(messageType)")
        }
    }
    
    // MARK: - 레거시 메시지 처리
    private func handleLegacyMessage(_ message: [String: Any]) {
        if let isAssessment = message["isAssessment"] as? Bool, isAssessment {
            print("📊 레거시 평가 시작 신호 수신")
            startWorkout(isAssessment: true)
            return
        }
        
        print("⚠️ 처리할 수 없는 레거시 메시지: \(message)")
    }
    
    // MARK: - 사용자 프로필 동기화 처리
    private func handleUserProfileSync(_ message: [String: Any]) {
        if let profileData = try? JSONSerialization.data(withJSONObject: message) {
            UserDefaults.standard.set(profileData, forKey: "UserProfile")
            print("⌚ 사용자 프로필 로컬 저장 완료")
        }
    }
}
