//
//  WatchConnectivityManager.swift
//  running_app
//
//  워치와 핸드폰 간 통신을 관리하는 매니저
//

import Foundation
import WatchConnectivity

class WatchConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchConnectivityManager()
    
    @Published var isWatchConnected = false
    @Published var lastSyncTime: Date?
    
    private override init() {
        super.init()
        setupWatchConnectivity()
    }
    
    // MARK: - 워치 연결 설정
    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
            print("📱 WatchConnectivity 초기화 시작")
        } else {
            print("❌ 이 기기는 WatchConnectivity를 지원하지 않습니다")
        }
    }
    
    // MARK: - 프로필 동기화 (iPhone → Watch)
    func syncProfileToWatch() {
        let profileManager = UserProfileManager.shared
        let profile = profileManager.userProfile
        
        let watchProfile: [String: Any] = [
            "type": "user_profile_sync",
            "weight": profile.weight,
            "gender": profile.gender.rawValue,
            "age": profile.age,
            "height": profile.height,
            "maxHeartRate": profile.maxHeartRate,
            "restingHeartRate": profile.restingHeartRate,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        // 방법 1: transferUserInfo (안정적, 백그라운드에서도 전송)
        WCSession.default.transferUserInfo(watchProfile)
        print("📱➡️⌚ 사용자 프로필 동기화 시작 (transferUserInfo)")
        
        // 방법 2: sendMessage (즉시 전송, 워치가 활성화된 경우에만)
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(watchProfile, replyHandler: { response in
                print("📱➡️⌚ 프로필 즉시 전송 성공: \(response)")
            }) { error in
                print("📱➡️⌚ 프로필 즉시 전송 실패: \(error.localizedDescription)")
                // transferUserInfo로 이미 전송했으므로 문제없음
            }
        }
        
        // 로컬에도 저장 (워치가 읽을 수 있도록)
        if let profileData = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(profileData, forKey: "UserProfileForWatch")
            print("📱 워치용 프로필 로컬 저장 완료")
        }
    }
    
    // MARK: - 체력 평가 시작 신호 전송
    func startAssessmentMode() {
        let assessmentSignal: [String: Any] = [
            "type": "start_assessment",
            "isAssessment": true,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        // 즉시 전송 시도
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(assessmentSignal, replyHandler: { response in
                print("📱➡️⌚ 체력 평가 시작 신호 즉시 전송 성공")
            }) { error in
                print("📱➡️⌚ 체력 평가 시작 신호 즉시 전송 실패: \(error.localizedDescription)")
            }
        }
        
        // 안정적 전송도 보장
        WCSession.default.transferUserInfo(assessmentSignal)
        print("📱➡️⌚ 체력 평가 시작 신호 전송 완료")
    }
    
    // MARK: - WCSessionDelegate 메서드들
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            switch activationState {
            case .activated:
                self.isWatchConnected = session.isPaired && session.isWatchAppInstalled
                print("📱 WatchConnectivity 활성화 완료")
                print("📱 워치 페어링: \(session.isPaired)")
                print("📱 워치 앱 설치: \(session.isWatchAppInstalled)")
                print("📱 워치 연결 가능: \(session.isReachable)")
                
                // 활성화 완료 후 프로필 동기화
                if self.isWatchConnected {
                    self.syncProfileToWatch()
                }
                
            case .inactive:
                self.isWatchConnected = false
                print("📱 WatchConnectivity 비활성화")
                
            case .notActivated:
                self.isWatchConnected = false
                print("📱 WatchConnectivity 활성화 실패")
                if let error = error {
                    print("📱 활성화 오류: \(error.localizedDescription)")
                }
                
            @unknown default:
                print("📱 알 수 없는 WatchConnectivity 상태")
            }
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("📱 WCSession 비활성화")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("📱 WCSession 비활성화됨 - 재활성화 시도")
        session.activate()
    }
    
    // MARK: - 워치로부터 데이터 수신
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            self.handleIncomingMessage(message, source: "Message")
        }
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any]) {
        DispatchQueue.main.async {
            self.handleIncomingMessage(userInfo, source: "UserInfo")
        }
    }
    
    // MARK: - 수신 메시지 처리
    private func handleIncomingMessage(_ message: [String: Any], source: String) {
        guard let messageType = message["type"] as? String else {
            print("📱⌚ 알 수 없는 메시지 타입: \(message)")
            return
        }
        
        lastSyncTime = Date()
        print("📱⌚ 워치로부터 메시지 수신 (\(source)): \(messageType)")
        
        switch messageType {
        case "workout_complete":
            handleWorkoutComplete(message)
            
        case "assessment_complete":
            handleAssessmentComplete(message)
            
        case "realtime_data", "realtime_data_fallback":
            handleRealtimeData(message)
            
        case "workout_end_signal":
            handleWorkoutEndSignal()
            
        default:
            print("📱⌚ 처리되지 않은 메시지 타입: \(messageType)")
        }
    }
    
    // MARK: - 개별 메시지 처리 메서드들
    private func handleWorkoutComplete(_ message: [String: Any]) {
        print("📱⌚ 워크아웃 완료 데이터 수신")
        
        if let workoutData = message["workoutData"] as? Data {
            do {
                let workout = try JSONDecoder().decode(WorkoutSummary.self, from: workoutData)
                
                // RunningDataManager에 저장
                let dataManager = RunningDataManager()
                dataManager.saveNewWorkout(workout)
                
                // 평가 운동인지 확인
                if let isAssessment = message["isAssessment"] as? Bool, isAssessment {
                    // 체력 평가 완료 처리
                    FitnessAssessmentManager.shared.processAssessmentWorkout(workout)
                    
                    // 알림 발송
                    NotificationCenter.default.post(
                        name: NSNotification.Name("AssessmentCompleted"),
                        object: workout
                    )
                }
                
                print("📱⌚ 워크아웃 데이터 저장 완료: \(String(format: "%.2f", workout.distance))km")
                
            } catch {
                print("📱⌚ 워크아웃 데이터 디코딩 실패: \(error)")
            }
        }
    }
    
    private func handleAssessmentComplete(_ message: [String: Any]) {
        print("📱⌚ 체력 평가 완료 데이터 수신")
        handleWorkoutComplete(message) // 워크아웃 완료와 동일하게 처리
    }
    
    private func handleRealtimeData(_ message: [String: Any]) {
        // RunningDataManager의 실시간 데이터 업데이트
        let dataManager = RunningDataManager()
        dataManager.updateRealtimeData(from: message)
    }
    
    private func handleWorkoutEndSignal() {
        print("📱⌚ 워크아웃 종료 신호 수신")
        let dataManager = RunningDataManager()
        dataManager.stopRealtimeDataReception()
    }
    
    // MARK: - 연결 상태 확인
    func checkConnectionStatus() {
        let session = WCSession.default
        print("📱 === 워치 연결 상태 확인 ===")
        print("📱 지원 여부: \(WCSession.isSupported())")
        print("📱 활성화 상태: \(session.activationState.rawValue)")
        print("📱 페어링 상태: \(session.isPaired)")
        print("📱 워치 앱 설치: \(session.isWatchAppInstalled)")
        print("📱 연결 가능: \(session.isReachable)")
        print("📱 마지막 동기화: \(lastSyncTime?.description ?? "없음")")
    }
    
    // MARK: - 수동 재연결
    func reconnectToWatch() {
        print("📱 워치 재연결 시도")
        WCSession.default.activate()
        
        // 3초 후 프로필 재동기화
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if self.isWatchConnected {
                self.syncProfileToWatch()
            }
        }
    }
}