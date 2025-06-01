import Foundation
import WatchConnectivity

// MARK: - 데이터 매니저 (Core Data만 사용)
class RunningDataManager: NSObject, ObservableObject {
    @Published var workouts: [WorkoutSummary] = []
    @Published var bestDistance: Double = 0
    @Published var isReceivingRealtimeData = false
    @Published var currentRealtimeData: RealtimeData?
    @Published var isLoading = false
    
    // Core Data 매니저와 로컬 분석 엔진
    private let coreDataManager = CoreDataManager.shared
    private let analysisEngine = LocalAnalysisEngine()
    
    override init() {
        super.init()
        setupWatchConnectivity()
        loadData()
    }
    
    // MARK: - 데이터 로딩
    private func loadData() {
        isLoading = true
        
        // Core Data에서 데이터 로드
        let fetchedWorkouts = coreDataManager.fetchWorkouts()
        
        DispatchQueue.main.async {
            self.workouts = fetchedWorkouts
            self.updateBestDistance()
            self.isLoading = false
            
            print("✅ 데이터 로딩 완료: \(self.workouts.count)개 워크아웃")
        }
    }
    
    // MARK: - 새 워크아웃 저장
    private func saveNewWorkout(_ workout: WorkoutSummary) {
        // Core Data에 저장
        coreDataManager.saveWorkout(workout)
        
        // 메모리 배열 업데이트
        DispatchQueue.main.async {
            self.workouts.insert(workout, at: 0)
            self.updateBestDistance()
        }
        
        print("✅ 새 워크아웃 저장 완료: \(String(format: "%.2f", workout.distance))km")
    }
    
    // MARK: - 워크아웃 삭제
    func deleteWorkout(_ workout: WorkoutSummary) {
        coreDataManager.deleteWorkout(id: workout.id)
        
        DispatchQueue.main.async {
            self.workouts.removeAll { $0.id == workout.id }
            self.updateBestDistance()
        }
    }
    
    // MARK: - 모든 데이터 삭제
    func deleteAllWorkouts() {
        coreDataManager.deleteAllWorkouts()
        
        DispatchQueue.main.async {
            self.workouts.removeAll()
            self.bestDistance = 0
        }
    }
    
    // MARK: - 데이터 새로고침
    func refreshData() {
        loadData()
    }
    
    // MARK: - 최고 기록 업데이트
    private func updateBestDistance() {
        bestDistance = workouts.map { $0.distance }.max() ?? 0
    }
    
    // MARK: - 데이터 내보내기
    func exportData() -> Data? {
        let exportData = [
            "workouts": workouts,
            "exportDate": Date(),
            "appVersion": "1.0.0"
        ] as [String: Any]
        
        return try? JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
    }
    
    // MARK: - 데이터 통계
    func getDataStats() -> (workoutCount: Int, totalDistance: Double, oldestDate: Date?) {
        return coreDataManager.getDataStats()
    }
    
    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
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
        
        let efficiencies = thisWeekWorkouts.compactMap { workout -> Double? in
            guard workout.averageHeartRate > 0 && workout.averagePace > 0 else { return nil }
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
            currentCalories: message["current_calories"] as? Double ?? 0,
            recentPaces: message["recent_paces"] as? [Double] ?? [],
            recentCadences: message["recent_cadences"] as? [Double] ?? [],
            recentHeartRates: message["recent_heart_rates"] as? [Double] ?? [],
            isWarningActive: message["is_warning_active"] as? Bool ?? false,
            warningMessage: message["warning_message"] as? String ?? ""
        )
        
        self.currentRealtimeData = realtimeData
        self.isReceivingRealtimeData = true
        
        // 로컬에서 실시간 분석 수행
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
            
            // Core Data에 저장
            saveNewWorkout(workout)
            
            print("✅ Watch에서 새 워크아웃 수신 및 저장 완료")
        } catch {
            print("워크아웃 데이터 디코딩 실패: \(error)")
        }
    }
}
