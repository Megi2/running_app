import Foundation
import HealthKit
import WatchConnectivity
import CoreMotion

// MARK: - Apple Watch 완전한 워크아웃 매니저
class WorkoutManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var isWorkoutActive = false
    @Published var isAssessmentMode = false
    @Published var elapsedTime: TimeInterval = 0
    @Published var distance: Double = 0
    @Published var currentPace: Double = 0
    @Published var heartRate: Double = 0
    @Published var cadence: Double = 0
    @Published var currentCalories: Double = 0
    @Published var isWarningActive = false
    @Published var warningMessage = ""
    
    // MARK: - Private Properties
    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?
    
    // 데이터 전송 관련
    private var realtimeDataTimer: Timer?
    private let realtimeDataInterval: TimeInterval = 1.0
    
    // 워크아웃 데이터 저장
    private var runningData: [RunningDataPoint] = []
    private var workoutStartTime: Date?
    
    // 최근 데이터 (분석용)
    private var recentPaces: [Double] = []
    private var recentCadences: [Double] = []
    private var recentHeartRates: [Double] = []
    private let maxRecentDataCount = 20
    
    // 케이던스 계산용 모션 매니저
    private let motionManager = CMMotionManager()
    private var stepCount = 0
    private var lastStepTime = Date()
    private var stepTimestamps: [Date] = []
    
    // MARK: - 초기화
    override init() {
        super.init()
        setupComponents()
    }
    
    private func setupComponents() {
        setupWatchConnectivity()
        setupNotifications()
        setupMotionManager()
    }
    
    // MARK: - Watch Connectivity 설정
    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAssessmentStartSignal),
            name: NSNotification.Name("AssessmentStartReceived"),
            object: nil
        )
    }
    
    // MARK: - 모션 매니저 설정
    private func setupMotionManager() {
        guard motionManager.isAccelerometerAvailable else {
            print("⚠️ 가속도계를 사용할 수 없습니다")
            return
        }
        motionManager.accelerometerUpdateInterval = 0.1
    }
    
    // MARK: - 워크아웃 제어
    func startWorkout(isAssessment: Bool = false) {
        guard !isWorkoutActive else { return }
        
        self.isAssessmentMode = isAssessment
        
        requestHealthKitPermissions { [weak self] success in
            if success {
                DispatchQueue.main.async {
                    self?.beginWorkoutSession()
                }
            } else {
                print("❌ HealthKit 권한 거부됨")
            }
        }
    }
    
    func stopWorkout() {
        guard isWorkoutActive else { return }
        
        print("⌚ 워크아웃 종료 시작")
        
        stopRealtimeDataTransmission()
        stopCadenceDetection()
        sendWorkoutEndSignal()
        
        workoutSession?.end()
        
        DispatchQueue.main.async {
            self.isWorkoutActive = false
        }
    }
    
    // MARK: - 평가 시작 신호 처리
    @objc private func handleAssessmentStartSignal(_ notification: Notification) {
        DispatchQueue.main.async {
            self.startWorkout(isAssessment: true)
        }
    }
    
    // MARK: - HealthKit 권한 요청
    private func requestHealthKitPermissions(completion: @escaping (Bool) -> Void) {
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .runningSpeed)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]
        
        let typesToWrite: Set<HKSampleType> = [
            HKObjectType.workoutType(),
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]
        
        healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead) { success, error in
            if let error = error {
                print("❌ HealthKit 권한 요청 실패: \(error)")
            }
            completion(success)
        }
    }
    
    // MARK: - 워크아웃 세션 시작
    private func beginWorkoutSession() {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .running
        configuration.locationType = .outdoor
        
        do {
            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            workoutBuilder = workoutSession?.associatedWorkoutBuilder()
            
            workoutSession?.delegate = self
            workoutBuilder?.delegate = self
            
            workoutBuilder?.dataSource = HKLiveWorkoutDataSource(
                healthStore: healthStore,
                workoutConfiguration: configuration
            )
            
            workoutSession?.startActivity(with: Date())
            workoutBuilder?.beginCollection(withStart: Date()) { success, error in
                if let error = error {
                    print("❌ 워크아웃 데이터 수집 시작 실패: \(error)")
                } else {
                    print("✅ 워크아웃 데이터 수집 시작")
                }
            }
            
            DispatchQueue.main.async {
                self.isWorkoutActive = true
                self.workoutStartTime = Date()
                self.resetData()
                self.startRealtimeDataTransmission()
                self.startCadenceDetection()
            }
            
            print("⌚ 워크아웃 시작 (평가 모드: \(isAssessmentMode))")
            
        } catch {
            print("❌ 워크아웃 세션 생성 실패: \(error)")
        }
    }
    
    // MARK: - 실시간 데이터 전송
    private func startRealtimeDataTransmission() {
        realtimeDataTimer = Timer.scheduledTimer(withTimeInterval: realtimeDataInterval, repeats: true) { _ in
            self.sendRealtimeDataToPhone()
        }
        print("⌚ 실시간 데이터 전송 시작")
    }
    
    private func stopRealtimeDataTransmission() {
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
        
        // 안정적 전송
        WCSession.default.transferUserInfo(realtimeData)
        
        // 즉시 전송 시도
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(realtimeData, replyHandler: nil) { error in
                print("⌚⚠️ 즉시 전송 실패: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - 최종 워크아웃 데이터 전송
    private func sendFinalWorkoutData() {
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
    
    private func sendWorkoutEndSignal() {
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
    
    // MARK: - 케이던스 감지
    private func startCadenceDetection() {
        guard motionManager.isAccelerometerAvailable else {
            print("⚠️ 가속도계를 사용할 수 없어 케이던스 감지를 건너뜁니다")
            return
        }
        
        stepCount = 0
        stepTimestamps.removeAll()
        lastStepTime = Date()
        
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] (data, error) in
            guard let self = self, let accelerometerData = data else { return }
            
            let acceleration = accelerometerData.acceleration
            let magnitude = sqrt(acceleration.x * acceleration.x +
                               acceleration.y * acceleration.y +
                               acceleration.z * acceleration.z)
            
            if magnitude > 1.2 {
                let now = Date()
                if now.timeIntervalSince(self.lastStepTime) > 0.3 {
                    self.detectStep(at: now)
                    self.lastStepTime = now
                }
            }
        }
        
        print("⌚ 케이던스 감지 시작")
    }
    
    private func stopCadenceDetection() {
        motionManager.stopAccelerometerUpdates()
        print("⌚ 케이던스 감지 중단")
    }
    
    private func detectStep(at time: Date) {
        stepCount += 1
        stepTimestamps.append(time)
        
        let oneMinuteAgo = time.addingTimeInterval(-60)
        stepTimestamps = stepTimestamps.filter { $0 > oneMinuteAgo }
        
        let stepsInLastMinute = stepTimestamps.count
        DispatchQueue.main.async {
            self.cadence = Double(stepsInLastMinute)
        }
    }
    
    // MARK: - 데이터 처리
    private func updateRunningData() {
        let dataPoint = RunningDataPoint(
            timestamp: Date().timeIntervalSince1970,
            pace: currentPace,
            heartRate: heartRate,
            cadence: cadence,
            distance: distance
        )
        
        runningData.append(dataPoint)
        updateRecentData()
        checkForWarnings()
    }
    
    private func updateRecentData() {
        if currentPace > 0 {
            recentPaces.append(currentPace)
            if recentPaces.count > maxRecentDataCount {
                recentPaces.removeFirst()
            }
        }
        
        if cadence > 0 {
            recentCadences.append(cadence)
            if recentCadences.count > maxRecentDataCount {
                recentCadences.removeFirst()
            }
        }
        
        if heartRate > 0 {
            recentHeartRates.append(heartRate)
            if recentHeartRates.count > maxRecentDataCount {
                recentHeartRates.removeFirst()
            }
        }
    }
    
    private func checkForWarnings() {
        if heartRate > 180 {
            showWarning("심박수가 너무 높습니다 (180+ bpm)")
            return
        }
        
        if currentPace > 0 && currentPace < 180 {
            showWarning("너무 빠른 페이스입니다")
            return
        }
        
        if currentPace > 600 {
            showWarning("페이스가 너무 느립니다")
            return
        }
        
        clearWarning()
    }
    
    private func showWarning(_ message: String) {
        DispatchQueue.main.async {
            self.isWarningActive = true
            self.warningMessage = message
        }
    }
    
    private func clearWarning() {
        DispatchQueue.main.async {
            if self.isWarningActive {
                self.isWarningActive = false
                self.warningMessage = ""
            }
        }
    }
    
    // MARK: - 유틸리티
    private func calculateAverage(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }
    
    private func resetData() {
        elapsedTime = 0
        distance = 0
        currentPace = 0
        heartRate = 0
        cadence = 0
        currentCalories = 0
        runningData.removeAll()
        recentPaces.removeAll()
        recentCadences.removeAll()
        recentHeartRates.removeAll()
        
        stepCount = 0
        stepTimestamps.removeAll()
        lastStepTime = Date()
        
        clearWarning()
    }
    
    func updateTestData(elapsedTime: TimeInterval, distance: Double, pace: Double, heartRate: Double, cadence: Double) {
        DispatchQueue.main.async {
            self.elapsedTime = elapsedTime
            self.distance = distance
            self.currentPace = pace
            self.heartRate = heartRate
            self.cadence = cadence
            
            self.updateRunningData()
        }
    }
    
    // MARK: - 정리
    deinit {
        stopRealtimeDataTransmission()
        stopCadenceDetection()
        NotificationCenter.default.removeObserver(self)
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

// MARK: - HKWorkoutSessionDelegate
extension WorkoutManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        DispatchQueue.main.async {
            switch toState {
            case .running:
                print("⌚ 워크아웃 세션 실행 중")
                
            case .ended:
                print("⌚ 워크아웃 세션 종료됨")
                self.workoutBuilder?.endCollection(withEnd: Date()) { success, error in
                    if success {
                        self.workoutBuilder?.finishWorkout { workout, error in
                            if let error = error {
                                print("❌ 워크아웃 완료 처리 실패: \(error)")
                            } else {
                                print("✅ 워크아웃 완료 처리 성공")
                                self.sendFinalWorkoutData()
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                    self.resetData()
                                }
                            }
                        }
                    }
                }
                
            default:
                break
            }
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("❌ 워크아웃 세션 오류: \(error)")
    }
}

// MARK: - HKLiveWorkoutBuilderDelegate
extension WorkoutManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else { continue }
            
            let statistics = workoutBuilder.statistics(for: quantityType)
            
            DispatchQueue.main.async {
                switch quantityType {
                case HKQuantityType.quantityType(forIdentifier: .heartRate):
                    let heartRateUnit = HKUnit.count().unitDivided(by: .minute())
                    self.heartRate = statistics?.mostRecentQuantity()?.doubleValue(for: heartRateUnit) ?? 0
                    
                case HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning):
                    let meterUnit = HKUnit.meter()
                    let meters = statistics?.sumQuantity()?.doubleValue(for: meterUnit) ?? 0
                    self.distance = meters / 1000.0
                    
                case HKQuantityType.quantityType(forIdentifier: .runningSpeed):
                    let speedUnit = HKUnit.meter().unitDivided(by: .second())
                    let speed = statistics?.mostRecentQuantity()?.doubleValue(for: speedUnit) ?? 0
                    self.currentPace = speed > 0 ? 1000.0 / speed : 0
                    
                case HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned):
                    let calorieUnit = HKUnit.kilocalorie()
                    self.currentCalories = statistics?.sumQuantity()?.doubleValue(for: calorieUnit) ?? 0
                    
                case HKQuantityType.quantityType(forIdentifier: .stepCount):
                    // 가속도계 기반 케이던스를 사용하므로 별도 처리하지 않음
                    break
                    
                default:
                    break
                }
            }
        }
        
        updateRunningData()
    }
    
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        // 워크아웃 이벤트 처리 (필요시)
    }
}
