//
//  WatchDataCommunicator+Delegate.swift
//  running_app
//
//  WCSessionDelegate 프로토콜 완전 구현
//

import Foundation
import WatchConnectivity

// MARK: - WCSessionDelegate 구현
extension WatchDataCommunicator: WCSessionDelegate {
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            print("📱 WatchConnectivity 활성화 완료: \(activationState.rawValue)")
            
            switch activationState {
            case .activated:
                print("✅ Watch 연결 활성화됨")
                self.updateConnectionStatus()
                
            case .inactive:
                print("⚠️ Watch 연결 비활성화됨")
                self.isWatchConnected = false
                self.connectionStrength = .disconnected
                
            case .notActivated:
                print("❌ Watch 연결 활성화 실패")
                self.isWatchConnected = false
                self.connectionStrength = .disconnected
                
            @unknown default:
                print("⚠️ 알 수 없는 활성화 상태: \(activationState.rawValue)")
            }
            
            if let error = error {
                print("❌ Watch 활성화 오류: \(error.localizedDescription)")
                self.connectionStrength = .disconnected
            }
        }
    }
    
    // MARK: - iOS에서만 필요한 메서드들
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("📱 Watch 세션이 비활성화됨")
        DispatchQueue.main.async {
            self.isWatchConnected = false
            self.connectionStrength = .weak
        }
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("📱 Watch 세션이 비활성화됨 - 재활성화 시도")
        session.activate()
    }
    
    func sessionWatchStateDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            print("📱 Watch 상태 변경됨")
            print("  - isPaired: \(session.isPaired)")
            print("  - isWatchAppInstalled: \(session.isWatchAppInstalled)")
            print("  - isReachable: \(session.isReachable)")
            
            self.updateConnectionStatus()
        }
    }
    #endif
    
    // MARK: - 메시지 수신 처리
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("📱 Watch로부터 즉시 메시지 수신: \(message)")
        DispatchQueue.main.async {
            self.handleReceivedMessage(message, source: "SendMessage")
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        print("📱 Watch로부터 응답 요청 메시지 수신: \(message)")
        DispatchQueue.main.async {
            self.handleReceivedMessage(message, source: "SendMessageWithReply")
            
            // 응답 전송
            let reply = ["status": "received", "timestamp": Date().timeIntervalSince1970]
            replyHandler(reply)
        }
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any]) {
        print("📱 Watch로부터 UserInfo 수신: \(userInfo)")
        DispatchQueue.main.async {
            self.handleReceivedMessage(userInfo, source: "TransferUserInfo")
        }
    }
    
    // MARK: - 파일 전송 (필요한 경우)
    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        print("📱 Watch로부터 파일 수신: \(file.fileURL)")
        // 파일 처리 로직 (필요시 구현)
    }
    
    func session(_ session: WCSession, didFinish fileTransfer: WCSessionFileTransfer, error: Error?) {
        if let error = error {
            print("❌ 파일 전송 실패: \(error.localizedDescription)")
        } else {
            print("✅ 파일 전송 완료")
        }
    }
    
    // MARK: - UserInfo 전송 상태
    func session(_ session: WCSession, didFinish userInfoTransfer: WCSessionUserInfoTransfer, error: Error?) {
        if let error = error {
            print("❌ UserInfo 전송 실패: \(error.localizedDescription)")
        } else {
            print("✅ UserInfo 전송 완료")
            DispatchQueue.main.async {
                self.lastSyncTime = Date()
                if self.pendingMessagesCount > 0 {
                    self.pendingMessagesCount -= 1
                }
            }
        }
    }
    
    // MARK: - 애플리케이션 컨텍스트
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        print("📱 Watch로부터 ApplicationContext 수신: \(applicationContext)")
        DispatchQueue.main.async {
            self.handleReceivedMessage(applicationContext, source: "ApplicationContext")
        }
    }
    
    // MARK: - 통합 메시지 처리
    private func handleReceivedMessage(_ message: [String: Any], source: String) {
        print("📱 메시지 처리 중 (\(source)): \(message.keys)")
        
        // 메시지 타입 확인
        guard let messageType = message["type"] as? String else {
            print("⚠️ 메시지 타입이 없음 - 전체 메시지를 delegate에 전달")
            dataDelegate?.didReceiveUserProfileSync(message)
            return
        }
        
        // 타입별 처리
        switch messageType {
        case "realtime_data":
            dataDelegate?.didReceiveRealtimeData(message)
            
        case "workout_complete":
            dataDelegate?.didReceiveWorkoutComplete(message)
            
        case "assessment_complete":
            dataDelegate?.didReceiveAssessmentComplete(message)
            
        case "workout_end_signal":
            dataDelegate?.didReceiveWorkoutEndSignal()
            
        case "user_profile_sync":
            dataDelegate?.didReceiveUserProfileSync(message)
            
        default:
            print("⚠️ 알 수 없는 메시지 타입: \(messageType)")
            // 알 수 없는 타입도 delegate에 전달
            dataDelegate?.didReceiveUserProfileSync(message)
        }
    }
    
    // MARK: - 연결 상태 모니터링
    func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        print("📱 Watch로부터 바이너리 데이터 수신: \(messageData.count) bytes")
        // 바이너리 데이터 처리 (필요시 구현)
    }
    
    func session(_ session: WCSession, didReceiveMessageData messageData: Data, replyHandler: @escaping (Data) -> Void) {
        print("📱 Watch로부터 응답 요청 바이너리 데이터 수신: \(messageData.count) bytes")
        // 응답용 바이너리 데이터 생성 (필요시 구현)
        let replyData = Data("received".utf8)
        replyHandler(replyData)
    }
}
