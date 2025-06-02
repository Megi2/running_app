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
    
    // MARK: - 사용자 프로필 로드
    private func loadUserProfile() {
        // UserDefaults에서 사용자 정보 로드 (iPhone에서 동기화)
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
    
    // MARK: - 칼로리 계산 메서드
    private func calculateCaloriesForPace(_ pace: Double) -> Double {
        guard pace > 0 else { return 0 }
        
        // 페이스를 속도(km/h)로 변환
        let speedKmh = 3600 / pace
        
        // 속도에 따른 METs 값
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
        
        // 분당 칼로리 = METs × 몸무게(kg) × (1/60)시간
        return mets * userWeight / 60
    }
    
    private func updateCalories() {
        if currentPace > 0 {
            let caloriesPerMinute = calculateCaloriesForPace(currentPace)
            // 1초당 칼로리 증가량
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
                        self.currentCalories = 0  // 칼로리 초기화
                        self.startTimer()
                        self.startDataTransmissionTimer()
                        self.startRealTimeAnalysis()
                        self.startCadenceTracking()
                        print("📍 HealthKit 워크아웃을 통한 위치 서비스 시작됨")
                    }
                }
            }
        } catch {
            print("워크아웃 시작 실패: \(error)")
        }
    }
    
    // WorkoutManager.swift의 endWorkout() 개선

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
                        print("📍 HealthKit 워크아웃 종료 - 위치 서비스 중지됨")
                        print("🔥 총 소모 칼로리: \(Int(self.currentCalories)) cal")
                        
                        // 최종 데이터 전송
                        self.sendFinalDataToPhone()
                        
                        // 2초 후 데이터 초기화 (전송 완료 대기)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            self.resetData()
                        }
                    }
                }
            }
        }
    }

    // 운동 종료 신호 별도 전송
    private func sendWorkoutEndSignal() {
        let endSignal: [String: Any] = [
            "type": "workout_end_signal",
            "timestamp": Date().timeIntervalSince1970
        ]
        
        // 즉시 전송 시도
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(endSignal, replyHandler: nil) { error in
                print("📱 종료 신호 즉시 전송 실패")
            }
        }
        
        // 안정적 전송도 보장
        WCSession.default.transferUserInfo(endSignal)
        print("📱 운동 종료 신호 전송 완료")
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
        
        // 케이던스 체크
        if cadence > 0 && !targetCadenceRange.contains(cadence) {
            if cadence < targetCadenceRange.lowerBound {
                warnings.append("케이던스가 너무 낮습니다 (\(Int(cadence)) < \(Int(targetCadenceRange.lowerBound)))")
            } else {
                warnings.append("케이던스가 너무 높습니다 (\(Int(cadence)) > \(Int(targetCadenceRange.upperBound)))")
            }
        }
        
        // 페이스 안정성 체크
        if recentPaces.count >= 20 {
            let paceCV = calculateCoefficientOfVariation(recentPaces)
            if paceCV > paceStabilityThreshold {
                warnings.append("페이스가 불안정합니다 (변동: \(String(format: "%.1f", paceCV))%)")
            }
        }
        
        // 경고 상태 업데이트
        DispatchQueue.main.async {
            if !warnings.isEmpty {
                if !self.isInWarningState {
                    self.isInWarningState = true
                    self.isWarningActive = true
                    self.warningMessage = warnings.joined(separator: "\n")
                    self.triggerHapticWarning()
                }
                // 경고가 계속되는 동안 주기적으로 진동
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
        currentCalories = 0  // 칼로리 초기화
        startDate = nil
        lastLocation = nil
        runningData.removeAll()
        paceCalculationBuffer.removeAll()
        stepCount = 0
        lastStepCountUpdate = Date()
        stepTimestamps.removeAll()
        lastAccelerationMagnitude = 0
        
        // 경고 상태 초기화
        isWarningActive = false
        warningMessage = ""
        isInWarningState = false
        
        // 버퍼 초기화
        recentPaces.removeAll()
        recentCadences.removeAll()
        recentHeartRates.removeAll()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5.0 // 5m마다 업데이트
        
        let authStatus = locationManager.authorizationStatus
        print("📍 현재 위치 권한 상태: \(authStatus.rawValue)")
        
        switch authStatus {
        case .notDetermined:
            print("📍 위치 권한 미결정 - 워크아웃 시작 시 자동 요청됨")
        case .denied, .restricted:
            print("❌ 위치 권한이 거부되었습니다. iPhone Watch 앱에서 권한을 허용해주세요.")
        case .authorizedWhenInUse, .authorizedAlways:
            print("✅ 위치 권한이 허용되었습니다.")
        @unknown default:
            print("⚠️ 알 수 없는 위치 권한 상태")
        }
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
    
    // MARK: - Helper Functions
    private func calculateAverage(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }
    
    // MARK: - Connectivity Check
    func checkConnectivityStatus() {
        print("📱 WCSession.isSupported: \(WCSession.isSupported())")
        print("📱 WCSession.isReachable: \(WCSession.default.isReachable)")
        print("📱 WCSession.activationState: \(WCSession.default.activationState.rawValue)")
    }
}

// MARK: - HealthKit Delegates
extension WorkoutManager {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        print("워크아웃 상태 변경: \(fromState.rawValue) -> \(toState.rawValue)")
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("워크아웃 세션 오류: \(error)")
    }
    
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else { continue }
            
            let statistics = workoutBuilder.statistics(for: quantityType)
            
            DispatchQueue.main.async {
                switch quantityType {
                case HKQuantityType.quantityType(forIdentifier: .heartRate):
                    let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                    if let heartRateValue = statistics?.mostRecentQuantity()?.doubleValue(for: heartRateUnit) {
                        self.heartRate = heartRateValue
                    }
                    
                case HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning):
                    let meterUnit = HKUnit.meter()
                    if let distanceValue = statistics?.sumQuantity()?.doubleValue(for: meterUnit) {
                        self.distance = distanceValue / 1000 // km로 변환
                        self.totalDistance = self.distance
                    }
                    
                case HKQuantityType.quantityType(forIdentifier: .stepCount):
                    let stepUnit = HKUnit.count()
                    if let stepValue = statistics?.sumQuantity()?.doubleValue(for: stepUnit) {
                        print("HealthKit 걸음 수: \(Int(stepValue))")
                    }
                    
                default:
                    break
                }
            }
        }
    }
    
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        // 이벤트 수집 처리
    }
}

// MARK: - Location Manager Delegate
extension WorkoutManager {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        print("📍 위치 권한 상태 변경: \(status.rawValue)")
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            print("✅ 위치 권한 허용됨 - HealthKit 워크아웃을 통해 위치 데이터 수집")
        case .denied, .restricted:
            print("❌ 위치 권한 거부됨 - iPhone Watch 앱에서 권한을 허용해주세요")
        case .notDetermined:
            print("📍 위치 권한 대기 중 - 워크아웃이 시작되면 자동으로 요청됩니다")
        @unknown default:
            print("⚠️ 알 수 없는 권한 상태")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // 위치 정확도 확인 (20m 이하만 사용)
        guard location.horizontalAccuracy > 0 && location.horizontalAccuracy < 20 else {
            print("GPS 정확도 부족: \(location.horizontalAccuracy)m")
            return
        }
        
        if let lastLocation = self.lastLocation {
            let distance = location.distance(from: lastLocation)
            let timeInterval = location.timestamp.timeIntervalSince(lastLocation.timestamp)
            
            // 최소 2초 간격, 최소 3m 이동한 경우에만 계산
            if timeInterval >= 2.0 && distance >= 3.0 {
                let speedMps = distance / timeInterval // m/s
                
                // 합리적인 속도 범위 확인 (1 ~ 10 m/s, 즉 3.6 ~ 36 km/h)
                if speedMps >= 1.0 && speedMps <= 10.0 {
                    // 누적 거리 업데이트
                    self.totalDistance += distance / 1000 // km로 변환
                    
                    DispatchQueue.main.async {
                        self.distance = self.totalDistance
                        
                        // 페이스 계산 (초/km)
                        let speedKmh = speedMps * 3.6 // km/h로 변환
                        let newPace = 3600 / speedKmh // 초/km
                        
                        // 기존 페이스와 새 페이스를 평균내어 부드럽게 변화
                        if self.currentPace > 0 && self.currentPace >= 180 && self.currentPace <= 900 {
                            self.currentPace = (self.currentPace * 0.7) + (newPace * 0.3)
                        } else {
                            self.currentPace = newPace
                        }
                        
                        // 최종 합리적인 페이스 범위로 제한 (3분/km ~ 15분/km)
                        self.currentPace = max(180, min(900, self.currentPace))
                        
                        print("🏃‍♂️ GPS 페이스: \(String(format: "%.0f", self.currentPace))초/km, 칼로리: \(Int(self.currentCalories))cal")
                    }
                } else {
                    print("⚠️ 비정상적인 속도: \(String(format: "%.2f", speedMps))m/s")
                }
            }
        } else {
            print("📍 첫 GPS 위치 수신: 정확도 \(location.horizontalAccuracy)m")
        }
        
        self.lastLocation = location
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let clError = error as! CLError
        
        switch clError.code {
        case .denied:
            print("❌ 위치 권한이 거부되었습니다. 설정 > 개인정보 보호 > 위치 서비스에서 허용해주세요.")
        case .locationUnknown:
            print("⚠️ 위치를 찾을 수 없습니다. GPS 신호를 기다리는 중...")
        case .network:
            print("⚠️ 네트워크 오류로 위치를 찾을 수 없습니다.")
        case .headingFailure:
            print("⚠️ 나침반 오류")
        default:
            print("⚠️ 위치 오류: \(error.localizedDescription)")
        }
        
        // GPS 실패 시에도 다른 데이터는 계속 수집
        if isActive {
            print("📍 GPS 없이 운동 계속 - 케이던스와 심박수는 정상 수집")
        }
    }
}

// MARK: - Watch Connectivity Delegate
extension WorkoutManager {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("Watch Connectivity 활성화 완료")
    }
    
    func sendRealtimeDataToPhone() {
        guard WCSession.default.activationState == .activated else {
            return
        }
        
        // 필수 데이터만 전송 (크기 최소화)
        let realtimeData: [String: Any] = [
            "type": "realtime_data",
            "timestamp": Date().timeIntervalSince1970,
            "elapsed_time": elapsedTime,
            "current_pace": currentPace,
            "heart_rate": heartRate,
            "cadence": cadence,
            "distance": distance,
            "current_calories": currentCalories,
            "is_warning_active": isWarningActive,
            "warning_message": warningMessage
            // 배열 데이터 제거 (크기 줄임)
        ]
        
        // 1차: transferUserInfo 사용 (안정적)
        WCSession.default.transferUserInfo(realtimeData)
        
        // 2차: sendMessage도 시도 (빠른 전송)
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(realtimeData, replyHandler: nil) { error in
                // 실패해도 transferUserInfo로 전송되므로 괜찮음
            }
        }
        
        print("📱 실시간 데이터 전송: 거리 \(String(format: "%.2f", distance))km")
    }
    
    // 대안: transferUserInfo 사용 (백그라운드에서도 전송됨)
    private func fallbackToUserInfoTransfer(data: [String: Any]) {
        // 중요하지 않은 데이터는 제거하여 크기 축소
        let essentialData: [String: Any] = [
            "type": "realtime_data_fallback",
            "timestamp": data["timestamp"] ?? Date().timeIntervalSince1970,
            "elapsed_time": data["elapsed_time"] ?? 0,
            "current_pace": data["current_pace"] ?? 0,
            "heart_rate": data["heart_rate"] ?? 0,
            "cadence": data["cadence"] ?? 0,
            "distance": data["distance"] ?? 0,
            "current_calories": data["current_calories"] ?? 0,
            "is_warning_active": data["is_warning_active"] ?? false
        ]
        
        WCSession.default.transferUserInfo(essentialData)
        print("📱 대안 전송 방식 사용: transferUserInfo")
    }
    
    func sendFinalDataToPhone() {
        guard WCSession.default.activationState == .activated else {
            print("⚠️ WCSession이 활성화되지 않음 - 최종 데이터 전송 실패")
            return
        }
        
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
                "type": "workout_complete",
                "workoutData": data,
                "total_calories": currentCalories
            ] as [String: Any]
            
            // 중요한 데이터이므로 transferUserInfo 사용 (보장된 전송)
            WCSession.default.transferUserInfo(message)
            print("✅ 최종 워크아웃 데이터 전송 완료 (transferUserInfo)")
            
            // 추가로 sendMessage도 시도 (즉시 전송용)
            if WCSession.default.isReachable {
                WCSession.default.sendMessage(message, replyHandler: { response in
                    print("✅ 즉시 전송도 성공")
                }) { error in
                    print("⚠️ 즉시 전송 실패, transferUserInfo로 전송됨")
                }
            }
            
        } catch {
            print("❌ 워크아웃 데이터 인코딩 실패: \(error)")
        }
    }
}

// MARK: - Watch용 간단한 사용자 프로필 구조체
struct UserProfileForWatch: Codable {
    let weight: Double
    let gender: String
    let age: Int
}
