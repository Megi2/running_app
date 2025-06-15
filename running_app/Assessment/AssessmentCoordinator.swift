import Foundation
import WatchConnectivity
import SwiftUI

class AssessmentCoordinator: ObservableObject {
    static let shared = AssessmentCoordinator()
    
    @Published var isAssessmentModeActive = false
    @Published var isWaitingForAssessmentStart = false
    @Published var showingAssessmentResult = false
    @Published var assessmentResult: AssessmentResult?
    
    private init() {
        setupNotifications()
    }
    
    private func setupNotifications() {
        // Watch에서 평가 완료 신호를 받을 때
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAssessmentCompleted),
            name: NSNotification.Name("AssessmentCompleted"),
            object: nil
        )
    }
    
    // MARK: - 평가 시작
    func startAssessment() {
        print("📊 평가 모드 시작")
        
        isWaitingForAssessmentStart = true
        isAssessmentModeActive = true
        
        // Watch로 평가 시작 신호 전송
        sendAssessmentStartSignalToWatch()
    }
    
    private func sendAssessmentStartSignalToWatch() {
        let message: [String: Any] = [
            "type": "start_assessment",
            "isAssessment": true,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        if WCSession.isSupported() && WCSession.default.activationState == .activated {
            // 즉시 전송
            if WCSession.default.isReachable {
                WCSession.default.sendMessage(message, replyHandler: { response in
                    print("✅ Watch로 평가 시작 신호 전송 성공")
                }) { error in
                    print("⚠️ 즉시 전송 실패: \(error)")
                    WCSession.default.transferUserInfo(message)
                }
            } else {
                // 백그라운드 전송
                WCSession.default.transferUserInfo(message)
                print("📱 Watch로 평가 시작 신호 전송 (백그라운드)")
            }
        }
    }
    
    // MARK: - 평가 완료 처리
    @objc private func handleAssessmentCompleted(_ notification: Notification) {
        guard let workout = notification.object as? WorkoutSummary else { return }
        
        DispatchQueue.main.async {
            self.isAssessmentModeActive = false
            self.isWaitingForAssessmentStart = false
            
            // 평가 결과 생성
            let result = AssessmentResult(
                workout: workout,
                completedAt: Date()
            )
            self.assessmentResult = result
            self.showingAssessmentResult = true
            
            // FitnessAssessmentManager에 전달
            FitnessAssessmentManager.shared.processAssessmentWorkout(workout)
            
            print("✅ 평가 완료 처리됨")
        }
    }
    
    // MARK: - 상태 초기화
    func resetAssessmentState() {
        isAssessmentModeActive = false
        isWaitingForAssessmentStart = false
        showingAssessmentResult = false
        assessmentResult = nil
    }
}

// MARK: - 평가 결과 구조체
struct AssessmentResult {
    let workout: WorkoutSummary
    let completedAt: Date
}
