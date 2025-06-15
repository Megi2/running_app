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
                        
                        // 최종 데이터 전송
                        self.sendFinalDataToPhone()
                        
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
        print("📱 Watch Connectivity 활성화 완료")
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("📱 iPhone으로부터 메시지 수신: \(message)")
        
        if let messageType = message["type"] as? String {
            switch messageType {
            case "start_assessment":
                print("📊 평가 시작 신호 수신")
                DispatchQueue.main.async {
                    self.startAssessmentMode()
                }
            default:
                break
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any]) {
        print("📱 iPhone으로부터 UserInfo 수신: \(userInfo)")
        
        if let messageType = userInfo["type"] as? String {
            switch messageType {
            case "start_assessment":
                print("📊 평가 시작 신호 수신 (UserInfo)")
                DispatchQueue.main.async {
                    self.startAssessmentMode()
                }
            default:
                break
            }
        }
    }
    
    // MARK: - Timer 및 데이터 수집
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            guard let startDate = self.startDate else { return }
            self.elapsedTime = Date().timeIntervalSince(startDate)
            
            self.calculateCurrentPace()
            self.updateCalories()
            
            let dataPoint = RunningDataPoint(
                timestamp: Date(),
                pace: self.currentPace,
                heartRate: self.heartRate,
                cadence: self.cadence,
                distance: self.distance
            )
            self.runningData.append(dataPoint)
            
            self.updateDataBuffers()
        }
    }
    
    private func calculateCurrentPace() {
        let currentTime = Date()
        let currentDistance = distance
        
        paceCalculationBuffer.append((time: currentTime, distance: currentDistance))
        
        paceCalculationBuffer = paceCalculationBuffer.filter {
            currentTime.timeIntervalSince($0.time) <= 30
        }
        
        if paceCalculationBuffer.count >= 10 {
            let oldestEntry = paceCalculationBuffer.first!
            let timeInterval = currentTime.timeIntervalSince(oldestEntry.time)
            let distanceInterval = currentDistance - oldestEntry.distance
            
            if timeInterval > 0 && distanceInterval > 0.001 {
                let speedKmh = (distanceInterval) / (timeInterval / 3600)
                
                if speedKmh > 0.1 {
                    let newPace = 3600 / speedKmh
                    
                    if newPace >= 180 && newPace <= 900 {
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
    
    private func calculateAverage(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }
    
    func checkConnectivityStatus() {
        print("📱 WCSession.isSupported: \(WCSession.isSupported())")
        print("📱 WCSession.isReachable: \(WCSession.default.isReachable)")
        print("📱 WCSession.activationState: \(WCSession.default.activationState.rawValue)")
    }
}
