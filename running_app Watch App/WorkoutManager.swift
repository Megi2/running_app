//
//  WorkoutManager.swift (Watch App)
//  running_app Watch App
//
//  워치 운동 매니저 (수정된 버전)
//

import Foundation
import WatchKit
import HealthKit
import CoreLocation
import WatchConnectivity
import CoreMotion

class WorkoutManager: NSObject, ObservableObject, HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate, CLLocationManagerDelegate, WCSessionDelegate {
    @Published var isActive = false
    @Published var elapsedTime: TimeInterval = 0
    @Published var distance: Double = 0
    @Published var heartRate: Double = 0
    @Published var currentPace: Double = 0
    @Published var cadence: Double = 0
    @Published var currentCalories: Double = 0
    @Published var isWarningActive = false
    @Published var warningMessage = ""
    
    // 평가 모드 관련
    @Published var isAssessmentMode = false
    @Published var showAssessmentMode = false


    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private var healthStore = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private var locationManager = CLLocationManager()
    private var timer: Timer?
    private var dataTransmissionTimer: Timer?
    private var warningTimer: Timer?
    private var startDate: Date?
    internal var lastLocation: CLLocation?
    internal var runningData: [RunningDataPoint] = []
    
    private var userHeight: Double = 170.0
    private var userMaxHeartRate: Double = 190.0
    private var userRestingHeartRate: Double = 65.0
    
    // 실시간 분석을 위한 버퍼
    internal var recentPaces: [Double] = []
    internal var recentCadences: [Double] = []
    internal var recentHeartRates: [Double] = []
    private let bufferSize = 30
    
    // 경고 설정
    private var targetCadenceRange: ClosedRange<Double> = 170...180
    private var paceStabilityThreshold: Double = 15.0
    private var isInWarningState = false
    
    // 페이스 계산 변수들
    internal var totalDistance: Double = 0
    internal var paceCalculationBuffer: [(time: Date, distance: Double)] = []
    
    // 케이던스 측정 변수들
    internal var stepCount: Int = 0
    internal var lastStepCountUpdate: Date = Date()
    internal var pedometer = CMPedometer()
    internal var motionManager = CMMotionManager()
    internal var stepTimestamps: [Date] = []
    internal var lastAccelerationMagnitude: Double = 0
    internal var stepDetectionThreshold: Double = 1.2
    

    // 칼로리 계산을 위한 사용자 정보 (기본값)
    private var userWeight: Double = 70.0  // kg
    private var userGender: String = "male"
    private var userAge: Int = 30
    
    override init() {
        super.init()
        setupLocationManager()
        requestHealthKitPermissions()
        setupWatchConnectivity()
        loadUserProfile()
        setupAssessmentNotifications()
    }
    
    // MARK: - 평가 모드 관리
    func startAssessmentMode() {
        print("📊 Watch: 평가 모드 시작")
        isAssessmentMode = true
        showAssessmentMode = true
        
        // 평가 모드에서는 특별한 UI 표시
        DispatchQueue.main.async {
            // UI 업데이트는 ContentView에서 처리
        }
    }
    
    func startAssessmentWorkout() {
        print("📊 Watch: 평가 운동 시작")
        isAssessmentMode = true
        startWorkout()
    }
    
    // MARK: - 기존 메서드들은 그대로 유지
    private func loadUserProfile() {
        if let profileData = UserDefaults.standard.data(forKey: "UserProfile"),
           let profile = try? JSONDecoder().decode(UserProfileForWatch.self, from: profileData) {
            userWeight = profile.weight
            userGender = profile.gender
            userAge = profile.age
            print("✅ Watch에서 사용자 프로필 로드: \(userWeight)kg, \(userAge)세, \(userGender)")
        } else {
            print("⚠️ 사용자 프로필이 없음. 기본값 사용: \(userWeight)kg, \(userAge)세, \(userGender)")
        }
    }
    
    private func calculateCaloriesForPace(_ pace: Double) -> Double {
        guard pace > 0 else { return 0 }
        
        let speedKmh = 3600 / pace
        
        let mets: Double
        switch speedKmh {
        case 0..<4: mets = 4.0
        case 4..<6: mets = 6.0
        case 6..<8: mets = 8.3
        case 8..<9: mets = 9.8
        case 9..<10: mets = 10.5
        case 10..<11: mets = 11.0
        case 11..<12: mets = 11.8
        case 12..<13: mets = 12.8
        case 13..<14: mets = 13.8
        case 14..<16: mets = 15.3
        default: mets = 18.0
        }
        
        return mets * userWeight / 60
    }
    
    private func updateCalories() {
        if currentPace > 0 {
            let caloriesPerMinute = calculateCaloriesForPace(currentPace)
            currentCalories += caloriesPerMinute / 60
        }
    }
    
    func startWorkout() {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .running
        configuration.locationType = .outdoor
        
        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            builder = session?.associatedWorkoutBuilder()
            
            session?.delegate = self
            builder?.delegate = self
            
            builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)
            
            session?.startActivity(with: Date())
            builder?.beginCollection(withStart: Date()) { (success, error) in
                DispatchQueue.main.async {
                    if success {
                        self.isActive = true
                        self.startDate = Date()
                        self.currentCalories = 0
                        self.startTimer()
                        self.startDataTransmissionTimer()
                        self.startRealTimeAnalysis()
                        self.startCadenceTracking()
                        
                        if self.isAssessmentMode {
                            print("📊 평가 운동 시작됨")
                        } else {
                            print("🏃‍♂️ 일반 운동 시작됨")
                        }
                    }
                }
            }
        } catch {
            print("워크아웃 시작 실패: \(error)")
        }
    }
    
    func endWorkout() {
        print("🛑 운동 종료 시작...")
        
        // 먼저 실시간 전송 중단
        stopDataTransmissionTimer()
        stopRealTimeAnalysis()
        
        // 종료 신호 즉시 전송
        sendWorkoutEndSignal()
        
        session?.end()
        builder?.endCollection(withEnd: Date()) { (success, error) in
            if success {
                self.builder?.finishWorkout { (workout, error) in
                    DispatchQueue.main.async {
                        self.isActive = false
                        self.stopTimer()
                        self.stopCadenceTracking()
                        
                        if self.isAssessmentMode {
                            print("📊 평가 운동 완료")
                            self.sendAssessmentResult()
                        } else {
                            print("🏃‍♂️ 일반 운동 완료")
                        }
                        if UserDefaults.standard.bool(forKey: "IsAssessmentMode") {
                            self.sendAssessmentCompleteToPhone()
                        } else {
                            self.sendFinalDataToPhone()
                        }
                        
                        // 2초 후 데이터 초기화
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            self.resetData()
                        }
                    }
                }
            }
        }
    }
    
    private func sendAssessmentResult() {
        // 평가 완료 신호 전송
        let assessmentComplete: [String: Any] = [
            "type": "assessment_completed",
            "timestamp": Date().timeIntervalSince1970
        ]
        
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(assessmentComplete, replyHandler: nil) { error in
                print("📊 평가 완료 신호 전송 실패")
            }
        }
        WCSession.default.transferUserInfo(assessmentComplete)
        
        print("📊 평가 완료 신호 전송됨")
    }
    
    private func sendWorkoutEndSignal() {
        let endSignal: [String: Any] = [
            "type": "workout_end_signal",
            "timestamp": Date().timeIntervalSince1970,
            "isAssessment": isAssessmentMode
        ]
        
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(endSignal, replyHandler: nil) { error in
                print("📱 종료 신호 즉시 전송 실패")
            }
        }
        
        WCSession.default.transferUserInfo(endSignal)
        print("📱 운동 종료 신호 전송 완료")
    }
    
    // MARK: - Watch Connectivity
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
            DispatchQueue.main.async {
                print("⌚ Watch Connectivity 활성화 완료: \(activationState.rawValue)")
                if let error = error {
                    print("❌ Watch 활성화 오류: \(error.localizedDescription)")
                }
            }
        }
    
    // MARK: - 메시지 수신 처리 (sendMessage용)
        func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
            print("📱 iPhone으로부터 즉시 메시지 수신: \(message)")
            DispatchQueue.main.async {
                self.handleIncomingMessage(message, source: "SendMessage")
            }
        }
        
        // MARK: - UserInfo 수신 처리 (transferUserInfo용)
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
                print("⚠️ 메시지 타입이 없음. 레거시 방식으로 처리 시도")
                handleLegacyMessage(message)
                return
            }
            
            print("📱 메시지 타입 확인됨: \(messageType)")
            
            switch messageType {
            case "start_zone2_assessment":
                handleZone2AssessmentStart(message)
                
            case "stop_zone2_assessment":
                handleZone2AssessmentStop()
                
            case "realtime_data", "realtime_data_fallback":
                handleRealtimeData(message)
                
            case "workout_complete":
                handleWorkoutComplete(message)
                
            case "workout_end_signal":
                handleWorkoutEndSignal()
                
            default:
                print("⚠️ 알 수 없는 메시지 타입: \(messageType)")
                handleLegacyMessage(message)
            }
        }
        
        // MARK: - Zone 2 평가 시작 처리
        private func handleZone2AssessmentStart(_ message: [String: Any]) {
            print("📊 Zone 2 평가 모드 시작 신호 수신")
            
            let instructions = message["instructions"] as? String ?? "Zone 2 심박수 범위에서 최대한 오래 달려보세요"
            let zone2Lower = message["zone2_lower"] as? Double ?? 130
            let zone2Upper = message["zone2_upper"] as? Double ?? 150
            let zone2Range = zone2Lower...zone2Upper
            
            print("📊 평가 모드 파라미터:")
            print("   - 안내: \(instructions)")
            print("   - Zone 2 범위: \(Int(zone2Lower))-\(Int(zone2Upper)) bpm")
            
            // 평가 모드 매니저에게 전달
            AssessmentModeManager.shared.startAssessmentMode(
                instructions: instructions,
                zone2Range: zone2Range
            )
            
            print("✅ Zone 2 평가 화면 표시 요청 완료")
        }
        
        // MARK: - Zone 2 평가 종료 처리
        private func handleZone2AssessmentStop() {
            print("📊 Zone 2 평가 모드 종료 신호 수신")
            AssessmentModeManager.shared.stopAssessmentMode()
        }
        
        // MARK: - 실시간 데이터 처리 (기존 코드와 호환)
        private func handleRealtimeData(_ message: [String: Any]) {
            // 실시간 데이터는 현재 워치에서 iPhone으로만 전송하므로
            // 여기서는 특별한 처리 불필요
            print("📊 실시간 데이터 메시지 수신 (무시)")
        }
        
        // MARK: - 운동 완료 처리
        private func handleWorkoutComplete(_ message: [String: Any]) {
            print("🏁 운동 완료 신호 수신")
            // 워치에서는 특별한 처리 불필요
        }
        
        // MARK: - 운동 종료 신호 처리
        private func handleWorkoutEndSignal() {
            print("🛑 운동 종료 신호 수신")
            // 워치에서는 특별한 처리 불필요
        }
        
        // MARK: - 레거시 메시지 처리 (이전 버전 호환성)
        private func handleLegacyMessage(_ message: [String: Any]) {
            print("📱 레거시 메시지 처리 시도")
            
            // 이전 방식: isAssessment 플래그 확인
            if message["isAssessment"] as? Bool == true {
                print("📊 레거시 평가 모드 시작")
                
                let targetDistance = message["targetDistance"] as? Double ?? 1.0
                let instructions = "목표 거리 \(String(format: "%.1f", targetDistance))km를 완주해보세요"
                
                AssessmentModeManager.shared.startAssessmentMode(
                    instructions: instructions,
                    zone2Range: 130...150  // 기본값
                )
                return
            }
            
            // 워크아웃 데이터 확인
            if let workoutData = message["workoutData"] as? Data {
                print("📱 워크아웃 데이터 수신 (레거시)")
                // 워크아웃 데이터는 iPhone으로만 전송되므로 무시
                return
            }
            
            print("⚠️ 알 수 없는 레거시 메시지: \(message)")
        }
        
       
        
    private func startDataTransmissionTimer() {
        dataTransmissionTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            self.sendRealtimeDataToPhone()
        }
    }
    
    private func startRealTimeAnalysis() {
        warningTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            self.performRealTimeAnalysis()
        }
    }
    private func calculateCurrentPace() {
        let currentTime = Date()
        let currentDistance = distance
        
        paceCalculationBuffer.append((time: currentTime, distance: currentDistance))
        
        // 30초 이상 된 데이터 제거
        paceCalculationBuffer = paceCalculationBuffer.filter {
            currentTime.timeIntervalSince($0.time) <= 30
        }
        
        // 최소 10초간의 데이터가 있을 때 페이스 계산
        if paceCalculationBuffer.count >= 10 {
            let oldestEntry = paceCalculationBuffer.first!
            let timeInterval = currentTime.timeIntervalSince(oldestEntry.time)
            let distanceInterval = currentDistance - oldestEntry.distance
            
            // 거리가 실제로 증가했고, 시간도 흘렀을 때만 계산
            if timeInterval > 0 && distanceInterval > 0.001 { // 최소 1m 이상 이동
                // 속도 계산: km/h
                let speedKmh = (distanceInterval) / (timeInterval / 3600)
                
                if speedKmh > 0.1 { // 최소 0.1 km/h 이상
                    let newPace = 3600 / speedKmh // 초/km
                    
                    // 합리적인 페이스 범위 확인 (3분/km ~ 15분/km)
                    if newPace >= 180 && newPace <= 900 {
                        // 기존 페이스와 부드럽게 평균화
                        if self.currentPace > 0 && self.currentPace >= 180 && self.currentPace <= 900 {
                            self.currentPace = (self.currentPace * 0.8) + (newPace * 0.2)
                        } else {
                            self.currentPace = newPace
                        }
                        
                        print("🏃‍♂️ 페이스: \(String(format: "%.0f", self.currentPace))초/km, 칼로리: \(Int(self.currentCalories))cal")
                    }
                }
            }
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            guard let startDate = self.startDate else { return }
            self.elapsedTime = Date().timeIntervalSince(startDate)
            
            // GPS 기반 페이스 계산
            self.calculateCurrentPace()
            
            // 칼로리 업데이트
            self.updateCalories()
            
            // 매초 데이터 기록
            let dataPoint = RunningDataPoint(
                timestamp: Date(),
                pace: self.currentPace,
                heartRate: self.heartRate,
                cadence: self.cadence,
                distance: self.distance
            )
            self.runningData.append(dataPoint)
            
            // 실시간 분석을 위한 버퍼 업데이트
            self.updateDataBuffers()
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func stopDataTransmissionTimer() {
        dataTransmissionTimer?.invalidate()
        dataTransmissionTimer = nil
    }
    
    private func stopRealTimeAnalysis() {
        warningTimer?.invalidate()
        warningTimer = nil
        isWarningActive = false
        warningMessage = ""
    }
    
    private func updateDataBuffers() {
        if currentPace > 0 {
            recentPaces.append(currentPace)
            if recentPaces.count > bufferSize {
                recentPaces.removeFirst()
            }
        }
        
        if cadence > 0 {
            recentCadences.append(cadence)
            if recentCadences.count > bufferSize {
                recentCadences.removeFirst()
            }
        }
        
        if heartRate > 0 {
            recentHeartRates.append(heartRate)
            if recentHeartRates.count > bufferSize {
                recentHeartRates.removeFirst()
            }
        }
    }
    
    private func performRealTimeAnalysis() {
        var warnings: [String] = []
        
        if cadence > 0 && !targetCadenceRange.contains(cadence) {
            if cadence < targetCadenceRange.lowerBound {
                warnings.append("케이던스가 너무 낮습니다 (\(Int(cadence)) < \(Int(targetCadenceRange.lowerBound)))")
            } else {
                warnings.append("케이던스가 너무 높습니다 (\(Int(cadence)) > \(Int(targetCadenceRange.upperBound)))")
            }
        }
        
        if recentPaces.count >= 20 {
            let paceCV = calculateCoefficientOfVariation(recentPaces)
            if paceCV > paceStabilityThreshold {
                warnings.append("페이스가 불안정합니다 (변동: \(String(format: "%.1f", paceCV))%)")
            }
        }
        
        DispatchQueue.main.async {
            if !warnings.isEmpty {
                if !self.isInWarningState {
                    self.isInWarningState = true
                    self.isWarningActive = true
                    self.warningMessage = warnings.joined(separator: "\n")
                    self.triggerHapticWarning()
                }
                if self.elapsedTime.truncatingRemainder(dividingBy: 10) < 1 {
                    self.triggerHapticWarning()
                }
            } else {
                if self.isInWarningState {
                    self.isInWarningState = false
                    self.isWarningActive = false
                    self.warningMessage = ""
                    self.triggerSuccessHaptic()
                }
            }
        }
    }
    
    private func calculateCoefficientOfVariation(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
        let standardDeviation = sqrt(variance)
        
        return (standardDeviation / mean) * 100
    }
    
    private func triggerHapticWarning() {
        WKInterfaceDevice.current().play(.failure)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            WKInterfaceDevice.current().play(.failure)
        }
    }
    
    private func triggerSuccessHaptic() {
        WKInterfaceDevice.current().play(.success)
    }
    
    private func resetData() {
        elapsedTime = 0
        distance = 0
        totalDistance = 0
        heartRate = 0
        currentPace = 0
        cadence = 0
        currentCalories = 0
        startDate = nil
        lastLocation = nil
        runningData.removeAll()
        paceCalculationBuffer.removeAll()
        stepCount = 0
        lastStepCountUpdate = Date()
        stepTimestamps.removeAll()
        lastAccelerationMagnitude = 0
        
        isWarningActive = false
        warningMessage = ""
        isInWarningState = false
        
        recentPaces.removeAll()
        recentCadences.removeAll()
        recentHeartRates.removeAll()
        
        // 평가 모드 초기화
        isAssessmentMode = false
        showAssessmentMode = false
    }
    
    // MARK: - 설정 메서드들
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5.0
        
        let authStatus = locationManager.authorizationStatus
        print("📍 현재 위치 권한 상태: \(authStatus.rawValue)")
    }
    
    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    private func requestHealthKitPermissions() {
        let typesToShare: Set = [
            HKQuantityType.workoutType()
        ]
        
        let typesToRead: Set = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKQuantityType.quantityType(forIdentifier: .stepCount)!,
            HKQuantityType.quantityType(forIdentifier: .runningSpeed)!
        ]
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { (success, error) in
            if !success {
                print("HealthKit 권한 요청 실패: \(error?.localizedDescription ?? "알 수 없는 오류")")
            } else {
                print("✅ HealthKit 권한 승인 완료")
            }
        }
    }
    
    internal func calculateAverage(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }
    
    func checkConnectivityStatus() {
        print("📱 WCSession.isSupported: \(WCSession.isSupported())")
        print("📱 WCSession.isReachable: \(WCSession.default.isReachable)")
        print("📱 WCSession.activationState: \(WCSession.default.activationState.rawValue)")
    }
}
extension WorkoutManager {
    
    // MARK: - 프로필 로드 개선
    private func loadUserProfileImproved() {
        // 방법 1: UserDefaults에서 최신 프로필 확인
        if let profileData = UserDefaults.standard.data(forKey: "UserProfileForWatch"),
           let profile = try? JSONDecoder().decode(UserProfileForWatch.self, from: profileData) {
            updateUserProfile(profile)
            print("✅ Watch에서 사용자 프로필 로드 (UserDefaults): \(userWeight)kg, \(userAge)세, \(userGender)")
            return
        }
        
        // 방법 2: 기존 방식 (iPhone에서 동기화)
        if let profileData = UserDefaults.standard.data(forKey: "UserProfile"),
           let profile = try? JSONDecoder().decode(UserProfileForWatch.self, from: profileData) {
            updateUserProfile(profile)
            print("✅ Watch에서 사용자 프로필 로드 (기존): \(userWeight)kg, \(userAge)세, \(userGender)")
            return
        }
        
        print("⚠️ 사용자 프로필이 없음. 기본값 사용: \(userWeight)kg, \(userAge)세, \(userGender)")
    }
    
    private func updateUserProfile(_ profile: UserProfileForWatch) {
        userWeight = profile.weight
        userGender = profile.gender
        userAge = profile.age
        
        // Zone 2 심박수 범위 계산
        let maxHR = profile.maxHeartRate ?? (208 - (0.7 * Double(userAge)))
        let restingHR = profile.restingHeartRate ?? (userGender == "male" ? 65 : 70)
        let hrReserve = maxHR - restingHR
        
        let zone2Lower = restingHR + (hrReserve * 0.60)
        let zone2Upper = restingHR + (hrReserve * 0.70)
        
        // 워치에서 Zone 2 범위 저장
        UserDefaults.standard.set(zone2Lower, forKey: "Zone2Lower")
        UserDefaults.standard.set(zone2Upper, forKey: "Zone2Upper")
        
        print("⌚ Zone 2 범위 설정: \(Int(zone2Lower))-\(Int(zone2Upper)) bpm")
    }
    
    // MARK: - Zone 2 시간 비율 계산
    private func calculateZone2TimePercentage() -> Double {
        let zone2Lower = UserDefaults.standard.double(forKey: "Zone2Lower")
        let zone2Upper = UserDefaults.standard.double(forKey: "Zone2Upper")
        
        guard zone2Lower > 0 && zone2Upper > 0 else { return 0 }
        
        let zone2Points = runningData.filter { point in
            point.heartRate >= zone2Lower && point.heartRate <= zone2Upper
        }
        
        guard !runningData.isEmpty else { return 0 }
        
        return (Double(zone2Points.count) / Double(runningData.count)) * 100
    }
    
    // MARK: - 워크아웃 종료 시 호출 (기존 endWorkout 메서드 수정)
    func endWorkoutImproved() {
        print("🛑 운동 종료 시작...")
        
        // 먼저 실시간 전송 중단
        stopDataTransmissionTimer()
        stopRealTimeAnalysis()
        
        // 종료 신호 즉시 전송
        sendWorkoutEndSignal()
        
        session?.end()
        builder?.endCollection(withEnd: Date()) { (success, error) in
            if success {
                self.builder?.finishWorkout { (workout, error) in
                    DispatchQueue.main.async {
                        self.isActive = false
                        self.stopTimer()
                        self.stopCadenceTracking()
                        print("⌚ HealthKit 워크아웃 종료 완료")
                        print("🔥 총 소모 칼로리: \(Int(self.currentCalories)) cal")
                        
                        // 평가 모드인지 확인하여 적절한 전송 메서드 호출
                        if UserDefaults.standard.bool(forKey: "IsAssessmentMode") {
                            self.sendAssessmentCompleteToPhone()
                        } else {
                            self.sendFinalDataToPhone()
                        }
                        
                        // 2초 후 데이터 초기화
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            self.resetData()
                        }
                    }
                }
            }
        }
    }
}
// MARK: - WCSessionDelegate 수신 처리 개선
extension WorkoutManager {
    
    // 기존 session(_:didReceiveUserInfo:) 메서드를 이것으로 교체하세요
    
    
    // 기존 handleIncomingData 메서드에 추가할 케이스
    private func handleIncomingDataImproved(_ data: [String: Any], source: String) {
        print("⌚ iPhone으로부터 데이터 수신 (\(source)): \(data["type"] as? String ?? "unknown")")
        
        if let messageType = data["type"] as? String {
            switch messageType {
            case "user_profile_sync":
                handleProfileSync(data)
            case "start_assessment":
                handleAssessmentStart(data)
            case "realtime_data", "realtime_data_fallback":
                // 기존 실시간 데이터 처리
                break
            case "workout_complete":
                // 기존 워크아웃 완료 처리
                break
            default:
                print("⌚ 알 수 없는 메시지 타입: \(messageType)")
            }
        }
    }
    
    private func handleProfileSync(_ data: [String: Any]) {
        print("⌚ 프로필 동기화 수신")
        
        let profile = UserProfileForWatch(
            weight: data["weight"] as? Double ?? 70.0,
            gender: data["gender"] as? String ?? "male",
            age: data["age"] as? Int ?? 30,
            height: data["height"] as? Double,
            maxHeartRate: data["maxHeartRate"] as? Double,
            restingHeartRate: data["restingHeartRate"] as? Double
        )
        
        // 프로필 저장
        if let profileData = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(profileData, forKey: "UserProfileForWatch")
            print("⌚ 새 프로필 저장 완료")
        }
        
        // 즉시 적용
        updateUserProfile(profile)
        
        // iPhone으로 확인 응답 전송
        let response: [String: Any] = [
            "type": "profile_sync_ack",
            "success": true,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(response, replyHandler: nil) { error in
                print("⌚ 프로필 동기화 확인 응답 전송 실패: \(error)")
            }
        }
    }
    
    private func handleAssessmentStart(_ data: [String: Any]) {
        print("⌚ 체력 평가 모드 시작 신호 수신")
        
        // 평가 플래그 설정
        UserDefaults.standard.set(true, forKey: "IsAssessmentMode")
        
        // UI에 평가 모드 표시 (필요시)
        DispatchQueue.main.async {
            // 평가 모드 UI 업데이트
        }
    }
    func setupAssessmentNotifications() {
        // 평가 운동 시작 알림 수신
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("StartAssessmentWorkout"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleAssessmentWorkoutStart()
            
            // 즉시 운동 시작
            self?.startWorkout()
        }
        
        // 평가 모드 시작 알림 수신
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("AssessmentModeStarted"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("📊 평가 모드 활성화 알림 수신")
        }
        
        print("✅ 평가 모드 알림 설정 완료")
    }

    // MARK: - 평가 운동 시작 알림 처리
    func handleAssessmentWorkoutStart() {
        // 평가 운동이 시작될 때의 특별한 설정
        isAssessmentMode = true
        print("🏃‍♂️ Zone 2 평가 운동 모드로 전환")
        
        // 평가 모드에서는 다른 경고 설정 사용
        setupAssessmentModeWarnings()
    }

    // MARK: - 평가 모드 전용 경고 설정
    private func setupAssessmentModeWarnings() {
        // Zone 2 평가에서는 심박수 경고가 더 중요
        targetCadenceRange = 160...190  // 케이던스는 좀 더 관대하게
        paceStabilityThreshold = 20.0   // 페이스 안정성도 관대하게
        
        print("⚙️ 평가 모드 경고 설정 완료")
    }

    
    // MARK: - 평가 완료 시 데이터 전송 개선
    func sendAssessmentCompleteToPhone() {
        guard UserDefaults.standard.bool(forKey: "IsAssessmentMode") else {
            sendFinalDataToPhone() // 일반 운동 완료
            return
        }
        
        print("⌚ 체력 평가 완료 - 데이터 전송 시작")
        
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
                "type": "assessment_complete",
                "workoutData": data,
                "isAssessment": true,
                "total_calories": currentCalories,
                "zone2_time_percentage": calculateZone2TimePercentage(),
                "timestamp": Date().timeIntervalSince1970
            ] as [String: Any]
            
            // 중요한 데이터이므로 transferUserInfo 사용
            WCSession.default.transferUserInfo(message)
            print("✅ 체력 평가 데이터 전송 완료 (transferUserInfo)")
            
            // 추가로 sendMessage도 시도
            if WCSession.default.isReachable {
                WCSession.default.sendMessage(message, replyHandler: { response in
                    print("✅ 체력 평가 즉시 전송도 성공")
                }) { error in
                    print("⚠️ 체력 평가 즉시 전송 실패, transferUserInfo로 전송됨")
                }
            }
            
            // 평가 모드 플래그 해제
            UserDefaults.standard.removeObject(forKey: "IsAssessmentMode")
            
        } catch {
            print("❌ 체력 평가 데이터 인코딩 실패: \(error)")
        }
    }
}
