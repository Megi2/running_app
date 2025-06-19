import Foundation
import WatchConnectivity

// MARK: - 통신 전담 매니저 (메인 클래스)
class WatchDataCommunicator: NSObject, ObservableObject {
    static let shared = WatchDataCommunicator()
    
    // MARK: - Published Properties
    @Published var isWatchConnected = false
    @Published var connectionStrength: ConnectionStrength = .disconnected
    @Published var lastSyncTime: Date?
    @Published var pendingMessagesCount = 0
    
    // MARK: - Internal Properties
    internal var session: WCSession {
        return WCSession.default
    }
    
    internal var messageQueue: [String: Any] = [:]
    internal var retryTimer: Timer?
    internal var connectionMonitorTimer: Timer?
    
    // MARK: - Delegates
    weak var dataDelegate: WatchDataDelegate?
    
    // MARK: - 초기화
    private override init() {
        super.init()
        initializeWatchConnectivity()
    }
    
    // MARK: - Watch Connectivity 초기화
    private func initializeWatchConnectivity() {
        guard WCSession.isSupported() else {
            print("❌ 이 기기는 WatchConnectivity를 지원하지 않습니다")
            return
        }
        
        session.delegate = self
        session.activate()
        startConnectionMonitoring()
        print("📱 WatchDataCommunicator 초기화 시작")
    }
    
    // MARK: - 정리
    deinit {
        connectionMonitorTimer?.invalidate()
        retryTimer?.invalidate()
    }
}