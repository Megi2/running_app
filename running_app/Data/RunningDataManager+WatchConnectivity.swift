import Foundation
import WatchConnectivity

// MARK: - Watch Connectivity
extension RunningDataManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            print("📱 iPhone Watch Connectivity 활성화 완료: \(activationState.rawValue)")
            if let error = error {
                print("❌ iPhone 활성화 오류: \(error.localizedDescription)")
            }
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("📱 WCSession 비활성화")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("📱 WCSession 비활성화됨 - 재활성화 시도")
        WCSession.default.activate()
    }
    
    // 메시지 수신 처리 (sendMessage용)
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            self.handleIncomingData(message, source: "Message")
        }
    }
    
    // transferUserInfo 수신 처리 (더 안정적)
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any]) {
        DispatchQueue.main.async {
            self.handleIncomingData(userInfo, source: "UserInfo")
        }
    }
}
