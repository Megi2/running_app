import Foundation
import Combine

// MARK: - 실시간 데이터 동기화 매니저
class RealtimeDataSynchronizer: ObservableObject {
    static let shared = RealtimeDataSynchronizer()
    
    // MARK: - Published Properties
    @Published var currentRealtimeData: RealtimeData?
    @Published var isReceivingData = false
    @Published var lastDataReceiveTime: Date?
    @Published var syncStatus: SyncStatus = .disconnected
    
    // MARK: - Private Properties
    private var localTimer: Timer?
    private var timeoutTimer: Timer?
    private var baseElapsedTime: TimeInterval = 0
    private var timerStartTime: Date?
    
    // 데이터 검증을 위한 이전 값들
    private var lastValidDistance: Double = 0
    private var lastValidElapsedTime: TimeInterval = 0
    
    // 설정값
    private let dataTimeoutInterval: TimeInterval = 10.0  // 10초 동안 데이터 없으면 타임아웃
    private let timerUpdateInterval: TimeInterval = 0.1   // 100ms마다 로컬 타이머 업데이트
    private let maxDistanceJump: Double = 0.5            // 한 번에 500m 이상 증가하면 에러로 간주
    
    private init() {
        setupTimeoutMonitoring()
    }
    
    // MARK: - 타임아웃 모니터링 설정
    private func setupTimeoutMonitoring() {
        // 주기적으로 데이터 수신 상태 확인
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            self.checkDataTimeout()
        }
    }
    
    // MARK: - 실시간 데이터 처리
    func processRealtimeData(_ rawData: [String: Any]) {
        // 1. 데이터 유효성 검증
        guard let validatedData = validateIncomingData(rawData) else {
            print("📱❌ 실시간 데이터 유효성 검증 실패")
            return
        }
        
        // 2. RealtimeData 객체 생성
        let realtimeData = createRealtimeData(from: validatedData)
        
        // 3. 데이터 일관성 검증
        if !isDataConsistent(realtimeData) {
            print("📱⚠️ 데이터 불일치 감지 - 이전 유효값으로 보정")
            let correctedData = correctInconsistentData(realtimeData)
            updateRealtimeData(correctedData)
        } else {
            updateRealtimeData(realtimeData)
        }
        
        // 4. 타이머 동기화
        synchronizeTimer(with: realtimeData)
        
        // 5. 상태 업데이트
        updateSyncStatus(.synchronized)
        resetTimeout()
    }
    
    // MARK: - 데이터 유효성 검증
    private func validateIncomingData(_ data: [String: Any]) -> [String: Any]? {
        // 필수 필드 확인
        let requiredFields = ["elapsed_time", "distance", "current_pace", "heart_rate"]
        for field in requiredFields {
            guard data[field] != nil else {
                print("📱❌ 필수 필드 누락: \(field)")
                return nil
            }
        }
        
        // 데이터 타입 및 범위 검증
        guard let elapsedTime = data["elapsed_time"] as? TimeInterval,
              let distance = data["distance"] as? Double,
              let currentPace = data["current_pace"] as? Double,
              let heartRate = data["heart_rate"] as? Double else {
            print("📱❌ 데이터 타입 불일치")
            return nil
        }
        
        // 범위 검증
        guard elapsedTime >= 0,
              distance >= 0,
              currentPace >= 0,
              heartRate >= 0 && heartRate <= 250 else {
            print("📱❌ 데이터 범위 오류")
            return nil
        }
        
        return data
    }
    
    // MARK: - RealtimeData 객체 생성
    private func createRealtimeData(from data: [String: Any]) -> RealtimeData {
        return RealtimeData(
            timestamp: data["timestamp"] as? TimeInterval ?? Date().timeIntervalSince1970,
            elapsedTime: data["elapsed_time"] as? TimeInterval ?? 0,
            currentPace: data["current_pace"] as? Double ?? 0,
            heartRate: data["heart_rate"] as? Double ?? 0,
            cadence: data["cadence"] as? Double ?? 0,
            distance: data["distance"] as? Double ?? 0,
            currentCalories: data["current_calories"] as? Double ?? 0,
            recentPaces: data["recent_paces"] as? [Double] ?? [],
            recentCadences: data["recent_cadences"] as? [Double] ?? [],
            recentHeartRates: data["recent_heart_rates"] as? [Double] ?? [],
            isWarningActive: data["is_warning_active"] as? Bool ?? false,
            warningMessage: data["warning_message"] as? String ?? ""
        )
    }
    
    // MARK: - 데이터 일관성 검증
    private func isDataConsistent(_ data: RealtimeData) -> Bool {
        // 시간 역행 검증
        if data.elapsedTime < lastValidElapsedTime {
            print("📱⚠️ 시간 역행 감지: \(data.elapsedTime) < \(lastValidElapsedTime)")
            return false
        }
        
        // 거리 점프 검증
        let distanceJump = data.distance - lastValidDistance
        if distanceJump > maxDistanceJump && lastValidDistance > 0 {
            print("📱⚠️ 거리 점프 감지: +\(distanceJump)km")
            return false
        }
        
        // 거리 역행 검증
        if data.distance < lastValidDistance && lastValidDistance > 0 {
            print("📱⚠️ 거리 역행 감지: \(data.distance) < \(lastValidDistance)")
            return false
        }
        
        return true
    }
    
    // MARK: - 데이터 보정
    private func correctInconsistentData(_ data: RealtimeData) -> RealtimeData {
        var correctedData = data
        
        // 시간 역행 보정
        if data.elapsedTime < lastValidElapsedTime {
            correctedData.elapsedTime = lastValidElapsedTime + 1.0
        }
        
        // 거리 점프 보정
        let distanceJump = data.distance - lastValidDistance
        if distanceJump > maxDistanceJump && lastValidDistance > 0 {
            correctedData.distance = lastValidDistance + 0.01  // 10m 증가로 보정
        }
        
        // 거리 역행 보정
        if data.distance < lastValidDistance && lastValidDistance > 0 {
            correctedData.distance = lastValidDistance
        }
        
        return correctedData
    }
    
    // MARK: - 실시간 데이터 업데이트
    private func updateRealtimeData(_ data: RealtimeData) {
        DispatchQueue.main.async {
            self.currentRealtimeData = data
            self.lastDataReceiveTime = Date()
            self.isReceivingData = true
            
            // 유효한 값으로 업데이트
            self.lastValidDistance = data.distance
            self.lastValidElapsedTime = data.elapsedTime
            
            print("📱✅ 실시간 데이터 업데이트: \(String(format: "%.2f", data.distance))km, \(String(format: "%.0f", data.elapsedTime))초")
        }
    }
    
    // MARK: - 타이머 동기화
    private func synchronizeTimer(with data: RealtimeData) {
        // 처음 데이터 수신 시 로컬 타이머 시작
        if localTimer == nil {
            startLocalTimer(baseElapsedTime: data.elapsedTime)
        } else {
            // 기존 타이머가 있으면 기준 시간 업데이트
            updateTimerBase(newElapsedTime: data.elapsedTime)
        }
    }
    
    private func startLocalTimer(baseElapsedTime: TimeInterval) {
        self.baseElapsedTime = baseElapsedTime
        self.timerStartTime = Date()
        
        localTimer = Timer.scheduledTimer(withTimeInterval: timerUpdateInterval, repeats: true) { _ in
            self.updateLocalTime()
        }
        
        print("📱⏱️ 로컬 타이머 시작: 기준 시간 \(baseElapsedTime)초")
    }
    
    private func updateTimerBase(newElapsedTime: TimeInterval) {
        self.baseElapsedTime = newElapsedTime
        self.timerStartTime = Date()
        
        print("📱🔄 타이머 기준 시간 업데이트: \(newElapsedTime)초")
    }
    
    private func updateLocalTime() {
        guard let timerStartTime = timerStartTime,
              let currentData = currentRealtimeData else { return }
        
        let localElapsed = Date().timeIntervalSince(timerStartTime)
        let totalElapsedTime = baseElapsedTime + localElapsed
        
        // 현재 데이터의 경과 시간 업데이트 (UI 표시용)
        DispatchQueue.main.async {
            var updatedData = currentData
            updatedData.elapsedTime = totalElapsedTime
            self.currentRealtimeData = updatedData
        }
    }
    
    // MARK: - 타임아웃 관리
    func resetTimeout() {
        timeoutTimer?.invalidate()
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: dataTimeoutInterval, repeats: false) { _ in
            self.handleDataTimeout()
        }
    }
    
    private func checkDataTimeout() {
        guard let lastReceiveTime = lastDataReceiveTime else { return }
        
        let timeSinceLastData = Date().timeIntervalSince(lastReceiveTime)
        if timeSinceLastData > dataTimeoutInterval && isReceivingData {
            handleDataTimeout()
        }
    }
    
    private func handleDataTimeout() {
        DispatchQueue.main.async {
            print("📱⏰ 실시간 데이터 수신 타임아웃")
            self.updateSyncStatus(.timeout)
            
            // 5초 후에도 데이터가 없으면 완전히 중단
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                if self.syncStatus == .timeout {
                    self.stopDataReception()
                }
            }
        }
    }
    
    // MARK: - 동기화 상태 관리
    func updateSyncStatus(_ status: SyncStatus) {
        DispatchQueue.main.async {
            let previousStatus = self.syncStatus
            self.syncStatus = status
            
            if previousStatus != status {
                self.handleSyncStatusChange(from: previousStatus, to: status)
            }
        }
    }
    
    private func handleSyncStatusChange(from previous: SyncStatus, to current: SyncStatus) {
        print("📱📊 동기화 상태 변경: \(previous) → \(current)")
        
        switch current {
        case .synchronized:
            if previous == .timeout || previous == .disconnected {
                print("📱✅ 실시간 데이터 연결 복구됨")
            }
            
        case .timeout:
            print("📱⚠️ 실시간 데이터 연결 불안정")
            
        case .disconnected:
            print("📱❌ 실시간 데이터 연결 끊어짐")
            
        case .error(let errorMessage):
            print("📱💥 실시간 데이터 오류: \(errorMessage)")
        }
    }
    
    // MARK: - 데이터 수신 중단
    func stopDataReception() {
        DispatchQueue.main.async {
            self.isReceivingData = false
            self.currentRealtimeData = nil
            self.lastDataReceiveTime = nil
            self.lastValidDistance = 0
            self.lastValidElapsedTime = 0
            self.updateSyncStatus(.disconnected)
            
            self.stopLocalTimer()
            
            print("📱🛑 실시간 데이터 수신 중단")
        }
    }
    
    private func stopLocalTimer() {
        localTimer?.invalidate()
        localTimer = nil
        timeoutTimer?.invalidate()
        timeoutTimer = nil
        timerStartTime = nil
        baseElapsedTime = 0
        
        print("📱⏹️ 로컬 타이머 중단")
    }
    
    // MARK: - 수동 재시작
    func restartDataReception() {
        stopDataReception()
        print("📱🔄 실시간 데이터 수신 재시작 대기 중...")
    }
    
    // MARK: - 디버깅 정보
    func getDebugInfo() -> [String: Any] {
        return [
            "isReceivingData": isReceivingData,
            "syncStatus": syncStatus.debugDescription,
            "lastDataReceiveTime": lastDataReceiveTime?.description ?? "없음",
            "lastValidDistance": lastValidDistance,
            "lastValidElapsedTime": lastValidElapsedTime,
            "currentElapsedTime": currentRealtimeData?.elapsedTime ?? 0,
            "timerRunning": localTimer != nil
        ]
    }
    
    // MARK: - 정리
    deinit {
        stopLocalTimer()
    }
}

// MARK: - 동기화 상태 열거형
enum SyncStatus: Equatable {
    case disconnected
    case synchronized
    case timeout
    case error(String)
    
    var debugDescription: String {
        switch self {
        case .disconnected:
            return "연결 끊어짐"
        case .synchronized:
            return "동기화됨"
        case .timeout:
            return "타임아웃"
        case .error(let message):
            return "오류: \(message)"
        }
    }
}

// MARK: - 실시간 데이터 구조체 (기존과 동일하지만 mutable로 변경)
struct RealtimeData {
    let timestamp: TimeInterval
    var elapsedTime: TimeInterval      // 로컬 타이머로 업데이트될 수 있도록 var로 변경
    let currentPace: Double
    let heartRate: Double
    let cadence: Double
    var distance: Double               // 보정될 수 있도록 var로 변경
    let currentCalories: Double
    let recentPaces: [Double]
    let recentCadences: [Double]
    let recentHeartRates: [Double]
    let isWarningActive: Bool
    let warningMessage: String
    
    // 계산된 프로퍼티들
    var formattedElapsedTime: String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var formattedDistance: String {
        return String(format: "%.2f km", distance)
    }
    
    var formattedPace: String {
        if currentPace <= 0 { return "--:--" }
        let minutes = Int(currentPace) / 60
        let seconds = Int(currentPace) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var formattedHeartRate: String {
        return heartRate > 0 ? "\(Int(heartRate)) bpm" : "-- bpm"
    }
    
    var formattedCadence: String {
        return cadence > 0 ? "\(Int(cadence)) spm" : "-- spm"
    }
}
