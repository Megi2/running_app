import Foundation
import WatchConnectivity

extension WorkoutManager {
    
    // MARK: - 실시간 데이터 전송
    func sendRealtimeDataToPhone() {
        guard WCSession.default.activationState == .activated else {
            return
        }
        
        // 필수 데이터만 전송 (크기 최소화)
        let realtimeData: [String: Any] = [
            "type": "realtime_data",
            "timestamp": Date().timeIntervalSince1970,
            "elapsed_time": elapsedTime,
            "current_pace": currentPace,
            "heart_rate": heartRate,
            "cadence": cadence,
            "distance": distance,
            "current_calories": currentCalories,
            "is_warning_active": isWarningActive,
            "warning_message": warningMessage,
            "is_assessment": isAssessmentMode  // 평가 모드 여부 추가
        ]
        
        // 1차: transferUserInfo 사용 (안정적)
        WCSession.default.transferUserInfo(realtimeData)
        
        // 2차: sendMessage도 시도 (빠른 전송)
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(realtimeData, replyHandler: nil) { error in
                // 실패해도 transferUserInfo로 전송되므로 괜찮음
            }
        }
        
        print("📱 실시간 데이터 전송: 거리 \(String(format: "%.2f", distance))km")
    }
    
    // MARK: - 최종 워크아웃 데이터 전송
    func sendFinalDataToPhone() {
        guard WCSession.default.activationState == .activated else {
            print("⚠️ WCSession이 활성화되지 않음 - 최종 데이터 전송 실패")
            return
        }
        
        let workoutSummary = WorkoutSummary(
            date: Date(),
            duration: elapsedTime,
            distance: distance,
            averageHeartRate: calculateAverage(runningData.compactMap { $0.heartRate > 0 ? $0.heartRate : nil }),
            averagePace: calculateAverage(runningData.compactMap { $0.pace > 0 ? $0.pace : nil }),
            averageCadence: calculateAverage(runningData.compactMap { $0.cadence > 0 ? $0.cadence : nil }),
            dataPoints: runningData
        )
        
        do {
            let data = try JSONEncoder().encode(workoutSummary)
            let message = [
                "type": "workout_complete",
                "workoutData": data,
                "total_calories": currentCalories,
                "isAssessment": isAssessmentMode  // 평가 모드 여부 추가
            ] as [String: Any]
            
            // 중요한 데이터이므로 transferUserInfo 사용 (보장된 전송)
            WCSession.default.transferUserInfo(message)
            print("✅ 최종 워크아웃 데이터 전송 완료 (transferUserInfo)")
            
            // 추가로 sendMessage도 시도 (즉시 전송용)
            if WCSession.default.isReachable {
                WCSession.default.sendMessage(message, replyHandler: { response in
                    print("✅ 즉시 전송도 성공")
                }) { error in
                    print("⚠️ 즉시 전송 실패, transferUserInfo로 전송됨")
                }
            }
            
        } catch {
            print("❌ 워크아웃 데이터 인코딩 실패: \(error)")
        }
    }
    
    // MARK: - 대안 전송 방식
    private func fallbackToUserInfoTransfer(data: [String: Any]) {
        // 중요하지 않은 데이터는 제거하여 크기 축소
        let essentialData: [String: Any] = [
            "type": "realtime_data_fallback",
            "timestamp": data["timestamp"] ?? Date().timeIntervalSince1970,
            "elapsed_time": data["elapsed_time"] ?? 0,
            "current_pace": data["current_pace"] ?? 0,
            "heart_rate": data["heart_rate"] ?? 0,
            "cadence": data["cadence"] ?? 0,
            "distance": data["distance"] ?? 0,
            "current_calories": data["current_calories"] ?? 0,
            "is_warning_active": data["is_warning_active"] ?? false,
            "is_assessment": data["is_assessment"] ?? false
        ]
        
        WCSession.default.transferUserInfo(essentialData)
        print("📱 대안 전송 방식 사용: transferUserInfo")
    }
}
