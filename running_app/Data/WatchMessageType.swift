import Foundation
import WatchConnectivity

// MARK: - 통신 메시지 타입 정의
enum WatchMessageType: String, CaseIterable {
    case realtimeData = "realtime_data"
    case workoutComplete = "workout_complete"
    case assessmentComplete = "assessment_complete"
    case workoutEndSignal = "workout_end_signal"
    case startAssessment = "start_assessment"
    case userProfileSync = "user_profile_sync"
}

// MARK: - 통신 결과 타입
enum CommunicationResult {
    case success
    case failed(Error)
    case notReachable
}

// MARK: - 통신 전담 매니저
class WatchDataCommunicator: NSObject, ObservableObject {
    
    static let shared = WatchDataCommunicator()
    
    // MARK: - Published Properties
    @Published var isWatchConnected = false
    @Published var connectionStrength: ConnectionStrength = .disconnected
    @Published var lastSyncTime: Date?
    @Published var pendingMessagesCount = 0
    
    // MARK: - Private Properties
    private var session: WCSession {
        return WCSession.default
    }
    
    private var messageQueue: [String: Any] = [:]
    private var retryTimer: Timer?
    private var connectionMonitorTimer: Timer?
    
    // MARK: - Delegates
    weak var dataDelegate: WatchDataDelegate?
    
    // MARK: - 초기화
    private override init() {
        super.init()
        setupWatchConnectivity()
        startConnectionMonitoring()
    }
    
    // MARK: - Watch Connectivity 설정
    private func setupWatchConnectivity() {
        guard WCSession.isSupported() else {
            print("❌ 이 기기는 WatchConnectivity를 지원하지 않습니다")
            return
        }
        
        session.delegate = self
        session.activate()
        print("📱 WatchDataCommunicator 초기화 시작")
    }
    
    // MARK: - 연결 모니터링
    private func startConnectionMonitoring() {
        connectionMonitorTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            self.updateConnectionStatus()
        }
    }
    
    internal func updateConnectionStatus() {
        DispatchQueue.main.async {
            let wasConnected = self.isWatchConnected
            self.isWatchConnected = self.session.isPaired && self.session.isWatchAppInstalled
            
            // 연결 강도 업데이트
            if self.isWatchConnected {
                if self.session.isReachable {
                    self.connectionStrength = .strong
                } else {
                    self.connectionStrength = .weak
                }
            } else {
                self.connectionStrength = .disconnected
            }
            
            // 연결 상태 변화 감지
            if wasConnected != self.isWatchConnected {
                self.handleConnectionStateChange()
            }
        }
    }
    
    private func handleConnectionStateChange() {
        if isWatchConnected {
            print("✅ Watch 연결됨 - 대기 중인 메시지 전송 시작")
            retryPendingMessages()
        } else {
            print("❌ Watch 연결 끊어짐")
        }
    }
    
    // MARK: - 메시지 전송 (공개 인터페이스)
    func sendMessage(
        type: WatchMessageType,
        data: [String: Any] = [:],
        priority: MessagePriority = .normal,
        completion: ((CommunicationResult) -> Void)? = nil
    ) {
        var message = data
        message["type"] = type.rawValue
        message["timestamp"] = Date().timeIntervalSince1970
        message["messageId"] = UUID().uuidString
        
        sendMessageInternal(message, priority: priority, completion: completion)
    }
    
    // MARK: - 내부 메시지 전송 로직
    private func sendMessageInternal(
        _ message: [String: Any],
        priority: MessagePriority,
        completion: ((CommunicationResult) -> Void)? = nil
    ) {
        guard session.activationState == .activated else {
            completion?(.failed(CommunicationError.sessionNotActivated))
            return
        }
        
        guard isWatchConnected else {
            // 연결이 안 되어 있으면 큐에 저장
            queueMessage(message, priority: priority)
            completion?(.notReachable)
            return
        }
        
        switch priority {
        case .high:
            sendHighPriorityMessage(message, completion: completion)
        case .normal:
            sendNormalPriorityMessage(message, completion: completion)
        case .low:
            sendLowPriorityMessage(message, completion: completion)
        }
    }
    
    // MARK: - 우선순위별 전송 메서드
    private func sendHighPriorityMessage(
        _ message: [String: Any],
        completion: ((CommunicationResult) -> Void)? = nil
    ) {
        // 실시간 데이터용 - 즉시 전송 시도, 실패해도 큐에 저장하지 않음
        if session.isReachable {
            session.sendMessage(message, replyHandler: { _ in
                DispatchQueue.main.async {
                    self.lastSyncTime = Date()
                    completion?(.success)
                }
            }) { error in
                DispatchQueue.main.async {
                    print("📱⚠️ 고우선순위 메시지 전송 실패: \(error.localizedDescription)")
                    completion?(.failed(error))
                }
            }
        } else {
            completion?(.notReachable)
        }
    }
    
    private func sendNormalPriorityMessage(
        _ message: [String: Any],
        completion: ((CommunicationResult) -> Void)? = nil
    ) {
        // 일반 데이터용 - 즉시 전송 + 백그라운드 전송
        if session.isReachable {
            session.sendMessage(message, replyHandler: { _ in
                DispatchQueue.main.async {
                    self.lastSyncTime = Date()
                    completion?(.success)
                }
            }) { error in
                // 즉시 전송 실패 시 백그라운드 전송
                self.session.transferUserInfo(message)
                DispatchQueue.main.async {
                    print("📱⚠️ 즉시 전송 실패, 백그라운드 전송으로 대체")
                    completion?(.success)
                }
            }
        } else {
            // 연결이 안 되어 있으면 백그라운드 전송만
            session.transferUserInfo(message)
            DispatchQueue.main.async {
                self.lastSyncTime = Date()
                completion?(.success)
            }
        }
    }
    
    private func sendLowPriorityMessage(
        _ message: [String: Any],
        completion: ((CommunicationResult) -> Void)? = nil
    ) {
        // 저우선순위 데이터용 - 백그라운드 전송만
        session.transferUserInfo(message)
        DispatchQueue.main.async {
            self.lastSyncTime = Date()
            completion?(.success)
        }
    }
    
    // MARK: - 메시지 큐 관리
    private func queueMessage(_ message: [String: Any], priority: MessagePriority) {
        guard let messageId = message["messageId"] as? String else { return }
        
        messageQueue[messageId] = message
        DispatchQueue.main.async {
            self.pendingMessagesCount = self.messageQueue.count
        }
        
        print("📱📝 메시지 큐에 저장됨: \(messageId)")
    }
    
    func retryPendingMessages() {
        guard !messageQueue.isEmpty else { return }
        
        print("📱🔄 대기 중인 메시지 \(messageQueue.count)개 재전송 시작")
        
        for (messageId, message) in messageQueue {
            sendMessageInternal(message as? [String: Any] ?? [:], priority: .normal) { result in
                if case .success = result {
                    DispatchQueue.main.async {
                        self.messageQueue.removeValue(forKey: messageId)
                        self.pendingMessagesCount = self.messageQueue.count
                    }
                }
            }
        }
    }
    
    // MARK: - 정리
    deinit {
        connectionMonitorTimer?.invalidate()
        retryTimer?.invalidate()
    }
}

// MARK: - 지원 타입 정의
enum ConnectionStrength {
    case disconnected
    case weak      // transferUserInfo만 가능
    case strong    // sendMessage 가능
}

enum MessagePriority {
    case high      // 실시간 데이터
    case normal    // 일반 메시지
    case low       // 설정, 프로필 등
}

enum CommunicationError: Error {
    case sessionNotActivated
    case watchNotConnected
    case messageTooBig
    case unknown(String)
}

// MARK: - 델리게이트 프로토콜
protocol WatchDataDelegate: AnyObject {
    func didReceiveRealtimeData(_ data: [String: Any])
    func didReceiveWorkoutComplete(_ data: [String: Any])
    func didReceiveAssessmentComplete(_ data: [String: Any])
    func didReceiveWorkoutEndSignal()
    func didReceiveUserProfileSync(_ data: [String: Any])
}
