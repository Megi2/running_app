import Foundation
import HealthKit
import CoreLocation
import WatchConnectivity

// MARK: - HealthKit Delegates
extension WorkoutManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        print("워크아웃 상태 변경: \(fromState.rawValue) -> \(toState.rawValue)")
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("워크아웃 세션 오류: \(error)")
    }
}

extension WorkoutManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else { continue }
            
            let statistics = workoutBuilder.statistics(for: quantityType)
            
            DispatchQueue.main.async {
                switch quantityType {
                case HKQuantityType.quantityType(forIdentifier: .heartRate):
                    let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                    if let heartRateValue = statistics?.mostRecentQuantity()?.doubleValue(for: heartRateUnit) {
                        self.heartRate = heartRateValue
                    }
                    
                case HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning):
                    let meterUnit = HKUnit.meter()
                    if let distanceValue = statistics?.sumQuantity()?.doubleValue(for: meterUnit) {
                        self.distance = distanceValue / 1000 // km로 변환
                        self.totalDistance = self.distance
                    }
                    
                case HKQuantityType.quantityType(forIdentifier: .stepCount):
                    let stepUnit = HKUnit.count()
                    if let stepValue = statistics?.sumQuantity()?.doubleValue(for: stepUnit) {
                        print("HealthKit 걸음 수: \(Int(stepValue))")
                    }
                    
                default:
                    break
                }
            }
        }
    }
    
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        // 이벤트 수집 처리
    }
}

// MARK: - Location Manager Delegate
extension WorkoutManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        print("📍 위치 권한 상태 변경: \(status.rawValue)")
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            print("✅ 위치 권한 허용됨 - HealthKit 워크아웃을 통해 위치 데이터 수집")
        case .denied, .restricted:
            print("❌ 위치 권한 거부됨 - iPhone Watch 앱에서 권한을 허용해주세요")
        case .notDetermined:
            print("📍 위치 권한 대기 중 - 워크아웃이 시작되면 자동으로 요청됩니다")
        @unknown default:
            print("⚠️ 알 수 없는 권한 상태")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // 위치 정확도 확인 (20m 이하만 사용)
        guard location.horizontalAccuracy > 0 && location.horizontalAccuracy < 20 else {
            print("GPS 정확도 부족: \(location.horizontalAccuracy)m")
            return
        }
        
        if let lastLocation = self.lastLocation {
            let distance = location.distance(from: lastLocation)
            let timeInterval = location.timestamp.timeIntervalSince(lastLocation.timestamp)
            
            // 최소 2초 간격, 최소 3m 이동한 경우에만 계산
            if timeInterval >= 2.0 && distance >= 3.0 {
                let speedMps = distance / timeInterval // m/s
                
                // 합리적인 속도 범위 확인 (1 ~ 10 m/s, 즉 3.6 ~ 36 km/h)
                if speedMps >= 1.0 && speedMps <= 10.0 {
                    // 누적 거리 업데이트
                    self.totalDistance += distance / 1000 // km로 변환
                    
                    DispatchQueue.main.async {
                        self.distance = self.totalDistance
                        
                        // 페이스 계산 (초/km)
                        let speedKmh = speedMps * 3.6 // km/h로 변환
                        let newPace = 3600 / speedKmh // 초/km
                        
                        // 기존 페이스와 새 페이스를 평균내어 부드럽게 변화
                        if self.currentPace > 0 && self.currentPace >= 180 && self.currentPace <= 900 {
                            self.currentPace = (self.currentPace * 0.7) + (newPace * 0.3)
                        } else {
                            self.currentPace = newPace
                        }
                        
                        // 최종 합리적인 페이스 범위로 제한 (3분/km ~ 15분/km)
                        self.currentPace = max(180, min(900, self.currentPace))
                        
                        print("🏃‍♂️ GPS 페이스: \(String(format: "%.0f", self.currentPace))초/km, 칼로리: \(Int(self.currentCalories))cal")
                    }
                } else {
                    print("⚠️ 비정상적인 속도: \(String(format: "%.2f", speedMps))m/s")
                }
            }
        } else {
            print("📍 첫 GPS 위치 수신: 정확도 \(location.horizontalAccuracy)m")
        }
        
        self.lastLocation = location
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let clError = error as! CLError
        
        switch clError.code {
        case .denied:
            print("❌ 위치 권한이 거부되었습니다. 설정 > 개인정보 보호 > 위치 서비스에서 허용해주세요.")
        case .locationUnknown:
            print("⚠️ 위치를 찾을 수 없습니다. GPS 신호를 기다리는 중...")
        case .network:
            print("⚠️ 네트워크 오류로 위치를 찾을 수 없습니다.")
        case .headingFailure:
            print("⚠️ 나침반 오류")
        default:
            print("⚠️ 위치 오류: \(error.localizedDescription)")
        }
        
        // GPS 실패 시에도 다른 데이터는 계속 수집
        if isActive {
            print("📍 GPS 없이 운동 계속 - 케이던스와 심박수는 정상 수집")
        }
    }
}

// MARK: - Watch Connectivity Delegate
extension WorkoutManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("Watch Connectivity 활성화 완료: \(activationState.rawValue)")
        if let error = error {
            print("WCSession 활성화 에러: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 메시지 수신 처리
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("📱 iPhone에서 메시지 수신: \(message)")
        handleReceivedMessage(message)
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        print("📱 iPhone에서 응답 요청 메시지 수신: \(message)")
        handleReceivedMessage(message)
        
        // 응답 전송
        let reply: [String: Any] = [
            "status": "received",
            "timestamp": Date().timeIntervalSince1970
        ]
        replyHandler(reply)
    }
    
    // MARK: - 메시지 처리
    private func handleReceivedMessage(_ message: [String: Any]) {
        DispatchQueue.main.async {
            if let command = message["command"] as? String {
                switch command {
                case "start_assessment":
                    if let targetDistance = message["targetDistance"] as? Double,
                       let isAssessment = message["isAssessment"] as? Bool {
                        print("🎯 평가 모드 시작: \(targetDistance)km, 평가: \(isAssessment)")
                        // 평가 모드 플래그 설정
                        // 실제 구현에서는 WorkoutManager에 평가 모드 상태를 추가
                    }
                    
                case "stop_workout":
                    if self.isActive {
                        self.endWorkout()
                    }
                    
                case "get_status":
                    // 현재 상태 전송
                    self.sendCurrentStatus()
                    
                default:
                    print("⚠️ 알 수 없는 명령: \(command)")
                }
            }
        }
    }
    
    // MARK: - 현재 상태 전송
    private func sendCurrentStatus() {
        guard WCSession.default.isReachable else {
            print("📱 iPhone이 연결되지 않음")
            return
        }
        
        let statusMessage: [String: Any] = [
            "type": "status_update",
            "isActive": isActive,
            "elapsedTime": elapsedTime,
            "distance": distance,
            "currentPace": currentPace,
            "heartRate": heartRate,
            "cadence": cadence,
            "currentCalories": currentCalories
        ]
        
        WCSession.default.sendMessage(statusMessage, replyHandler: nil) { error in
            print("상태 전송 실패: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 실시간 데이터 전송
    func sendRealtimeDataToPhone() {
        guard WCSession.default.isReachable else {
            print("📱 iPhone이 연결되지 않음 - 실시간 데이터 전송 건너뛰기")
            return
        }
        
        let realtimeData: [String: Any] = [
            "type": "realtime_data",
            "timestamp": Date().timeIntervalSince1970,
            "elapsed_time": elapsedTime,
            "current_pace": currentPace,
            "heart_rate": heartRate,
            "cadence": cadence,
            "distance": distance,
            "current_calories": currentCalories,
            "recent_paces": recentPaces,
            "recent_cadences": recentCadences,
            "recent_heart_rates": recentHeartRates,
            "is_warning_active": isWarningActive,
            "warning_message": warningMessage
        ]
        
        WCSession.default.sendMessage(realtimeData, replyHandler: { response in
            print("📱 실시간 데이터 전송 성공, 응답: \(response)")
        }) { error in
            print("📱 실시간 데이터 전송 실패: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 최종 워크아웃 데이터 전송
    func sendFinalDataToPhone() {
        guard WCSession.default.isReachable else {
            print("📱 iPhone이 연결되지 않음 - 최종 데이터 저장은 나중에 동기화됨")
            return
        }
        
        let workoutSummary = WorkoutSummary(
            date: Date(),
            duration: elapsedTime,
            distance: distance,
            averageHeartRate: runningData.compactMap { $0.heartRate }.average(),
            averagePace: runningData.compactMap { $0.pace }.average(),
            averageCadence: runningData.compactMap { $0.cadence }.average(),
            dataPoints: runningData
        )
        
        do {
            let data = try JSONEncoder().encode(workoutSummary)
            let message: [String: Any] = [
                "type": "workout_complete",
                "workoutData": data,
                "total_calories": currentCalories,
                "timestamp": Date().timeIntervalSince1970
            ]
            
            WCSession.default.sendMessage(message, replyHandler: { response in
                print("📱 최종 워크아웃 데이터 전송 성공: \(response)")
            }) { error in
                print("📱 최종 데이터 전송 실패: \(error.localizedDescription)")
                // 실패 시 로컬에 임시 저장
                self.saveWorkoutLocally(workoutSummary)
            }
        } catch {
            print("워크아웃 데이터 인코딩 실패: \(error)")
        }
    }
    
    // MARK: - 로컬 임시 저장 (나중에 동기화용)
    private func saveWorkoutLocally(_ workout: WorkoutSummary) {
        // UserDefaults에 임시 저장
        do {
            let data = try JSONEncoder().encode(workout)
            let key = "pending_workout_\(Date().timeIntervalSince1970)"
            UserDefaults.standard.set(data, forKey: key)
            print("💾 워크아웃 로컬 임시 저장: \(key)")
        } catch {
            print("로컬 저장 실패: \(error)")
        }
    }
    
    // MARK: - 에러 처리 메서드들
    func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        print("📱 iPhone에서 데이터 메시지 수신: \(messageData.count)bytes")
    }
    
    func session(_ session: WCSession, didReceiveMessageData messageData: Data, replyHandler: @escaping (Data) -> Void) {
        print("📱 iPhone에서 응답 요청 데이터 메시지 수신: \(messageData.count)bytes")
        let replyData = "received".data(using: .utf8) ?? Data()
        replyHandler(replyData)
    }
    
    // MARK: - 연결 상태 변화 처리
    func sessionReachabilityDidChange(_ session: WCSession) {
        print("Watch 연결 상태 변경: \(session.isReachable)")
        if session.isReachable {
            print("✅ iPhone과 연결됨 - 실시간 데이터 전송 가능")
        } else {
            print("❌ iPhone 연결 끊어짐 - 로컬 저장 모드")
        }
    }
}

// MARK: - Extensions
extension Array where Element == Double {
    func average() -> Double {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / Double(count)
    }
}
