import Foundation
import WatchConnectivity

// MARK: - 데이터 매니저
class RunningDataManager: NSObject, ObservableObject {
    @Published var workouts: [WorkoutSummary] = []
    @Published var bestDistance: Double = 0
    @Published var isReceivingRealtimeData = false
    @Published var currentRealtimeData: RealtimeData?
    
    // 로컬 분석 엔진 (Python 서버 대신 사용)
    private let analysisEngine = LocalAnalysisEngine()
    
    override init() {
        super.init()
        setupWatchConnectivity()
        loadSampleData() // 개발용 샘플 데이터
    }
    
    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    private func loadSampleData() {
        // 개발용 샘플 데이터 생성
        let sampleWorkout = WorkoutSummary(
            date: Date().addingTimeInterval(-86400), // 어제
            duration: 1800, // 30분
            distance: 5.2,
            averageHeartRate: 150,
            averagePace: 350, // 5:50/km
            averageCadence: 175,
            dataPoints: generateSampleDataPoints()
        )
        
        workouts.append(sampleWorkout)
        bestDistance = workouts.map { $0.distance }.max() ?? 0
    }
    
    private func generateSampleDataPoints() -> [RunningDataPoint] {
        var points: [RunningDataPoint] = []
        let startTime = Date().addingTimeInterval(-86400)
        
        for i in 0..<1800 { // 30분간 매초 데이터
            let point = RunningDataPoint(
                timestamp: startTime.addingTimeInterval(TimeInterval(i)),
                pace: 350 + Double.random(in: -20...20), // 5:50 ± 20초
                heartRate: 150 + Double.random(in: -10...10),
                cadence: 175 + Double.random(in: -5...5),
                distance: Double(i) * 0.0029 // 대략적인 거리 계산
            )
            points.append(point)
        }
        
        return points
    }
    
    // MARK: - 실시간 분석 (로컬에서 수행)
    private func performLocalAnalysis(_ realtimeData: RealtimeData) {
        // 페이스 안정성 분석
        if realtimeData.recentPaces.count >= 10 {
            let stabilityResult = analysisEngine.analyzePaceStability(paces: realtimeData.recentPaces)
            print("📊 페이스 안정성: CV=\(String(format: "%.1f", stabilityResult.cv))%, 상태=\(stabilityResult.level)")
            
            if stabilityResult.level == .unstable {
                print("⚠️ 페이스 불안정 감지: \(stabilityResult.warning)")
            }
        }
        
        // 효율성 분석
        if realtimeData.recentPaces.count >= 10 && realtimeData.recentHeartRates.count >= 10 {
            let efficiencyResult = analysisEngine.analyzeEfficiency(
                paces: realtimeData.recentPaces,
                heartRates: realtimeData.recentHeartRates
            )
            print("📈 효율성: \(String(format: "%.3f", efficiencyResult.averageEfficiency)), 트렌드: \(String(format: "%.4f", efficiencyResult.trend))")
        }
        
        // 케이던스 최적화
        if realtimeData.recentCadences.count >= 10 {
            let cadenceResult = analysisEngine.optimizeCadence(
                paces: realtimeData.recentPaces,
                cadences: realtimeData.recentCadences,
                heartRates: realtimeData.recentHeartRates
            )
            print("🦶 최적 케이던스: \(Int(cadenceResult.optimalRange.0))-\(Int(cadenceResult.optimalRange.1)) spm, 현재: \(Int(cadenceResult.currentAverage)) spm")
        }
    }
    
    func getWeeklyStats() -> WeeklyStats {
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let thisWeekWorkouts = workouts.filter { $0.date >= oneWeekAgo }
        
        let totalDistance = thisWeekWorkouts.map { $0.distance }.reduce(0, +)
        let workoutCount = thisWeekWorkouts.count
        let efficiencies = thisWeekWorkouts.map { workout in
            let speed = 3600 / workout.averagePace
            return speed / workout.averageHeartRate
        }
        let averageEfficiency = efficiencies.isEmpty ? 0 : efficiencies.reduce(0, +) / Double(efficiencies.count)
        
        return WeeklyStats(
            totalDistance: totalDistance,
            workoutCount: workoutCount,
            averageEfficiency: averageEfficiency
        )
    }
    
    func calculateLongTermTrends() -> LongTermTrends {
        guard workouts.count >= 2 else {
            return LongTermTrends(
                efficiencyImprovement: 0,
                distanceImprovement: 0,
                recoveryPattern: "데이터 부족"
            )
        }
        
        // 최근 5개와 이전 5개 운동 비교
        let recentWorkouts = Array(workouts.prefix(5))
        let olderWorkouts = Array(workouts.dropFirst(5).prefix(5))
        
        let recentEfficiencies = recentWorkouts.map { workout in
            let speed = 3600 / workout.averagePace
            return speed / workout.averageHeartRate
        }
        let recentEfficiency = recentEfficiencies.isEmpty ? 0 : recentEfficiencies.reduce(0, +) / Double(recentEfficiencies.count)
        
        let olderEfficiencies = olderWorkouts.map { workout in
            let speed = 3600 / workout.averagePace
            return speed / workout.averageHeartRate
        }
        let olderEfficiency = olderEfficiencies.isEmpty ? 0 : olderEfficiencies.reduce(0, +) / Double(olderEfficiencies.count)
        
        let efficiencyImprovement = olderEfficiency > 0 ? ((recentEfficiency - olderEfficiency) / olderEfficiency) * 100 : 0
        
        let recentDistances = recentWorkouts.map { $0.distance }
        let recentDistance = recentDistances.isEmpty ? 0 : recentDistances.reduce(0, +) / Double(recentDistances.count)
        
        let olderDistances = olderWorkouts.map { $0.distance }
        let olderDistance = olderDistances.isEmpty ? 0 : olderDistances.reduce(0, +) / Double(olderDistances.count)
        
        let distanceImprovement = recentDistance - olderDistance
        
        return LongTermTrends(
            efficiencyImprovement: efficiencyImprovement,
            distanceImprovement: distanceImprovement,
            recoveryPattern: "정상"
        )
    }
    
    func assessOvertrainingRisk() -> OvertrainingAssessment {
        // 로컬 분석 엔진 사용
        let riskResult = analysisEngine.assessOvertrainingRisk(workouts: workouts)
        
        return OvertrainingAssessment(
            level: riskResult.level,
            recommendedRestDays: getRecommendedRestDays(for: riskResult.level),
            recommendations: riskResult.recommendations
        )
    }
    
    private func getRecommendedRestDays(for level: OvertrainingLevel) -> Int {
        switch level {
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }
    
    func calculateOptimalCadence() -> CadenceData {
        guard !workouts.isEmpty else {
            return CadenceData(
                currentAverage: 175,
                optimalRange: (170, 180),
                inRangePercentage: 0
            )
        }
        
        let allDataPoints = workouts.flatMap { $0.dataPoints }
        let validCadences = allDataPoints.compactMap { $0.cadence > 0 ? $0.cadence : nil }
        
        if validCadences.isEmpty {
            return CadenceData(
                currentAverage: 175,
                optimalRange: (170, 180),
                inRangePercentage: 0
            )
        }
        
        // 로컬 분석 엔진으로 최적 케이던스 계산
        let paces = allDataPoints.compactMap { $0.pace > 0 ? $0.pace : nil }
        let cadences = allDataPoints.compactMap { $0.cadence > 0 ? $0.cadence : nil }
        let heartRates = allDataPoints.compactMap { $0.heartRate > 0 ? $0.heartRate : nil }
        
        let cadenceResult = analysisEngine.optimizeCadence(
            paces: paces,
            cadences: cadences,
            heartRates: heartRates
        )
        
        // 최적 범위 유지율 계산
        let inRangeCount = validCadences.filter {
            $0 >= cadenceResult.optimalRange.0 && $0 <= cadenceResult.optimalRange.1
        }.count
        let inRangePercentage = Double(inRangeCount) / Double(validCadences.count) * 100
        
        return CadenceData(
            currentAverage: cadenceResult.currentAverage,
            optimalRange: cadenceResult.optimalRange,
            inRangePercentage: inRangePercentage
        )
    }
    
    // MARK: - 워크아웃별 상세 분석
    func analyzeWorkout(_ workout: WorkoutSummary) -> WorkoutAnalysisResult {
        let paces = workout.dataPoints.compactMap { $0.pace > 0 ? $0.pace : nil }
        let cadences = workout.dataPoints.compactMap { $0.cadence > 0 ? $0.cadence : nil }
        let heartRates = workout.dataPoints.compactMap { $0.heartRate > 0 ? $0.heartRate : nil }
        
        let stabilityResult = analysisEngine.analyzePaceStability(paces: paces)
        let efficiencyResult = analysisEngine.analyzeEfficiency(paces: paces, heartRates: heartRates)
        let cadenceResult = analysisEngine.optimizeCadence(paces: paces, cadences: cadences, heartRates: heartRates)
        
        return WorkoutAnalysisResult(
            paceStability: stabilityResult,
            efficiency: efficiencyResult,
            cadenceOptimization: cadenceResult
        )
    }
}



// MARK: - Watch Connectivity
extension RunningDataManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("iPhone Watch Connectivity 활성화 완료")
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("WCSession 비활성화")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("WCSession 비활성화됨")
        WCSession.default.activate()
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            if let messageType = message["type"] as? String {
                switch messageType {
                case "realtime_data":
                    self.handleRealtimeData(message)
                case "workout_complete":
                    self.handleWorkoutComplete(message)
                default:
                    // 기존 방식 (이전 버전 호환성)
                    if let workoutData = message["workoutData"] as? Data {
                        self.handleLegacyWorkoutData(workoutData)
                    }
                }
            }
        }
    }
    
    private func handleRealtimeData(_ message: [String: Any]) {
        let realtimeData = RealtimeData(
            timestamp: message["timestamp"] as? TimeInterval ?? Date().timeIntervalSince1970,
            elapsedTime: message["elapsed_time"] as? TimeInterval ?? 0,
            currentPace: message["current_pace"] as? Double ?? 0,
            heartRate: message["heart_rate"] as? Double ?? 0,
            cadence: message["cadence"] as? Double ?? 0,
            distance: message["distance"] as? Double ?? 0,
            recentPaces: message["recent_paces"] as? [Double] ?? [],
            recentCadences: message["recent_cadences"] as? [Double] ?? [],
            recentHeartRates: message["recent_heart_rates"] as? [Double] ?? [],
            isWarningActive: message["is_warning_active"] as? Bool ?? false,
            warningMessage: message["warning_message"] as? String ?? ""
        )
        
        self.currentRealtimeData = realtimeData
        self.isReceivingRealtimeData = true
        
        // 로컬에서 실시간 분석 수행 (서버 대신)
        performLocalAnalysis(realtimeData)
    }
    
    private func handleWorkoutComplete(_ message: [String: Any]) {
        if let workoutData = message["workoutData"] as? Data {
            handleLegacyWorkoutData(workoutData)
        }
        
        // 실시간 데이터 수신 종료
        self.isReceivingRealtimeData = false
        self.currentRealtimeData = nil
    }
    
    private func handleLegacyWorkoutData(_ workoutData: Data) {
        do {
            let workout = try JSONDecoder().decode(WorkoutSummary.self, from: workoutData)
            self.workouts.insert(workout, at: 0) // 최신 데이터를 맨 앞에 추가
            self.bestDistance = max(self.bestDistance, workout.distance)
        } catch {
            print("워크아웃 데이터 디코딩 실패: \(error)")
        }
    }
}
