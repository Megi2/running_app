import Foundation
import WatchKit
import HealthKit
import CoreLocation
import WatchConnectivity
import CoreMotion

class WorkoutManager: NSObject, ObservableObject {
    @Published var isActive = false
    @Published var elapsedTime: TimeInterval = 0
    @Published var distance: Double = 0
    @Published var heartRate: Double = 0
    @Published var currentPace: Double = 0
    @Published var cadence: Double = 0
    @Published var currentCalories: Double = 0  // 새로 추가!
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
    
    func endWorkout() {
        session?.end()
        builder?.endCollection(withEnd: Date()) { (success, error) in
            if success {
                self.builder?.finishWorkout { (workout, error) in
                    DispatchQueue.main.async {
                        self.isActive = false
                        self.stopTimer()
                        self.stopDataTransmissionTimer()
                        self.stopRealTimeAnalysis()
                        self.stopCadenceTracking()
                        print("📍 HealthKit 워크아웃 종료 - 위치 서비스 중지됨")
                        print("🔥 총 소모 칼로리: \(Int(self.currentCalories)) cal")
                        self.sendFinalDataToPhone()
                        self.resetData()
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
        dataTransmissionTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
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
}

// MARK: - Watch용 간단한 사용자 프로필 구조체
struct UserProfileForWatch: Codable {
    let weight: Double
    let gender: String
    let age: Int
}
