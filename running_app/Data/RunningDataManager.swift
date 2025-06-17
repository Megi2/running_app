import Foundation
import CoreData
import SwiftUI

// MARK: - 메인 데이터 매니저 (WatchDataDelegate 구현)
class RunningDataManager: NSObject, ObservableObject, WatchDataDelegate {
    static let shared = RunningDataManager()
    
    // MARK: - Published Properties
    @Published var workouts: [WorkoutSummary] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - 실시간 데이터 (RealtimeDataSynchronizer로 위임)
    var currentRealtimeData: RealtimeData? {
        return realtimeSynchronizer.currentRealtimeData
    }
    
    var isReceivingRealtimeData: Bool {
        return realtimeSynchronizer.isReceivingData
    }
    
    // MARK: - Private Properties
    private let realtimeSynchronizer = RealtimeDataSynchronizer.shared
    private let watchCommunicator = WatchDataCommunicator.shared
    private let analysisEngine = LocalAnalysisEngine()
    
    // Core Data
    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "RunningDataModel")
        container.loadPersistentStores { _, error in
            if let error = error {
                print("❌ Core Data 로드 실패: \(error)")
            }
        }
        return container
    }()
    
    private var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // MARK: - 초기화
    internal override init() {
        super.init()
        setupCommunication()
        loadWorkouts()
    }
    
    // MARK: - 통신 설정
    private func setupCommunication() {
        // Watch 통신 델리게이트 설정
        watchCommunicator.dataDelegate = self
        
        print("📱 RunningDataManager 초기화 완료")
    }
    
    // MARK: - WatchDataDelegate 구현
    func didReceiveRealtimeData(_ data: [String: Any]) {
        print("📱 실시간 데이터 수신")
        
        // RealtimeDataSynchronizer에게 처리 위임
        realtimeSynchronizer.processRealtimeData(data)
        
        // 분석 엔진에서 실시간 분석 수행
        if let realtimeData = realtimeSynchronizer.currentRealtimeData {
            performRealtimeAnalysis(realtimeData)
        }
    }
    
    func didReceiveWorkoutComplete(_ data: [String: Any]) {
        print("📱 워크아웃 완료 데이터 수신")
        
        // 실시간 데이터 수신 종료
        realtimeSynchronizer.stopDataReception()
        
        // 평가 모드인지 확인
        let isAssessment = data["isAssessment"] as? Bool ?? false
        
        if let workoutData = data["workoutData"] as? Data {
            handleWorkoutData(workoutData, isAssessment: isAssessment)
        }
    }
    
    func didReceiveAssessmentComplete(_ data: [String: Any]) {
        print("📱 평가 완료 신호 수신")
        
        // 실시간 데이터 수신 종료
        realtimeSynchronizer.stopDataReception()
        
        // 평가 완료 알림 전송
        NotificationCenter.default.post(
            name: NSNotification.Name("AssessmentCompleted"),
            object: data
        )
    }
    
    func didReceiveWorkoutEndSignal() {
        print("📱 워크아웃 종료 신호 수신")
        
        // 실시간 데이터 수신 즉시 종료
        realtimeSynchronizer.stopDataReception()
    }
    
    func didReceiveUserProfileSync(_ data: [String: Any]) {
        print("📱 사용자 프로필 동기화 데이터 수신")
        
        // UserProfileManager에게 처리 위임
        if let profileData = try? JSONSerialization.data(withJSONObject: data) {
            UserDefaults.standard.set(profileData, forKey: "SyncedUserProfile")
        }
    }
    
    // MARK: - 워크아웃 데이터 처리
    private func handleWorkoutData(_ workoutData: Data, isAssessment: Bool) {
        do {
            let workout = try JSONDecoder().decode(WorkoutSummary.self, from: workoutData)
            
            // Core Data에 저장
            saveNewWorkout(workout)
            
            // 적절한 알림 전송
            if isAssessment {
                NotificationCenter.default.post(
                    name: NSNotification.Name("AssessmentCompleted"),
                    object: workout
                )
                print("📊 평가 운동 완료 알림 전송")
            } else {
                NotificationCenter.default.post(
                    name: NSNotification.Name("WorkoutCompleted"),
                    object: workout
                )
                print("🏃‍♂️ 일반 운동 완료 알림 전송")
            }
            
            print("✅ Watch에서 새 워크아웃 수신 및 저장 완료")
        } catch {
            print("❌ 워크아웃 데이터 디코딩 실패: \(error)")
            DispatchQueue.main.async {
                self.errorMessage = "워크아웃 데이터 처리 실패"
            }
        }
    }
    
    // MARK: - 실시간 분석
    private func performRealtimeAnalysis(_ realtimeData: RealtimeData) {
        // 페이스 분석
        if realtimeData.recentPaces.count >= 5 {
            let paceResult = analysisEngine.analyzePaceStability(paces: realtimeData.recentPaces)
            if paceResult.level == .unstable {
                print("📈 페이스 불안정 감지: 변동성 \(String(format: "%.2f", paceResult.cv))%")
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
    
    // MARK: - 워크아웃 저장
    private func saveNewWorkout(_ workout: WorkoutSummary) {
        DispatchQueue.main.async {
            self.isLoading = true
        }
        
        let backgroundContext = persistentContainer.newBackgroundContext()
        backgroundContext.perform {
            let entity = WorkoutEntity(context: backgroundContext)
            entity.id = workout.id
            entity.date = workout.date
            entity.duration = workout.duration
            entity.distance = workout.distance
            entity.averageHeartRate = workout.averageHeartRate
            entity.averagePace = workout.averagePace
            entity.averageCadence = workout.averageCadence
            
            // DataPoints 인코딩
            if let dataPointsData = try? JSONEncoder().encode(workout.dataPoints) {
                entity.dataPointsData = dataPointsData
            }
            
            do {
                try backgroundContext.save()
                print("✅ 새 워크아웃 Core Data 저장 완료")
                
                // 메인 스레드에서 UI 업데이트
                DispatchQueue.main.async {
                    self.loadWorkouts()
                    self.isLoading = false
                }
            } catch {
                print("❌ 워크아웃 저장 실패: \(error)")
                DispatchQueue.main.async {
                    self.errorMessage = "워크아웃 저장 실패"
                    self.isLoading = false
                }
            }
        }
    }
    
    // MARK: - 워크아웃 로드
    private func loadWorkouts() {
        let request: NSFetchRequest<WorkoutEntity> = WorkoutEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WorkoutEntity.date, ascending: false)]
        
        do {
            let entities = try context.fetch(request)
            self.workouts = entities.compactMap { entity in
                guard let id = entity.id,
                      let date = entity.date else { return nil }
                
                var dataPoints: [RunningDataPoint] = []
                if let data = entity.dataPointsData {
                    dataPoints = (try? JSONDecoder().decode([RunningDataPoint].self, from: data)) ?? []
                }
                
                return WorkoutSummary(
                    id: id,
                    date: date,
                    duration: entity.duration,
                    distance: entity.distance,
                    averageHeartRate: entity.averageHeartRate,
                    averagePace: entity.averagePace,
                    averageCadence: entity.averageCadence,
                    dataPoints: dataPoints
                )
            }
            
            print("✅ \(workouts.count)개 워크아웃 로드 완료")
        } catch {
            print("❌ 워크아웃 로드 실패: \(error)")
            DispatchQueue.main.async {
                self.errorMessage = "데이터 로드 실패"
            }
        }
    }
    
    // MARK: - 공개 메서드들
    
    // 수동으로 실시간 모드 종료 (디버깅용)
    func stopRealtimeDataReception() {
        realtimeSynchronizer.stopDataReception()
        print("📱 🛑 실시간 데이터 수신 수동 종료")
    }
    
    // 실시간 데이터 재시작
    func restartRealtimeDataReception() {
        realtimeSynchronizer.restartDataReception()
        print("📱 🔄 실시간 데이터 수신 재시작")
    }
    
    // 주간 통계
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
    
    // 데이터 내보내기
    func exportData() -> Data? {
        let exportData = [
            "workouts": workouts,
            "exportDate": Date(),
            "appVersion": "1.0.0"
        ] as [String: Any]
        
        return try? JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
    }
    
    // 데이터 통계
    func getDataStats() -> (workoutCount: Int, totalDistance: Double, oldestDate: Date?) {
        let totalDistance = workouts.map { $0.distance }.reduce(0, +)
        let oldestDate = workouts.last?.date
        return (workouts.count, totalDistance, oldestDate)
    }
    
    // 디버깅 정보
    func getDebugInfo() -> [String: Any] {
        var debugInfo = realtimeSynchronizer.getDebugInfo()
        debugInfo["workoutCount"] = workouts.count
        debugInfo["watchConnected"] = watchCommunicator.isWatchConnected
        debugInfo["connectionStrength"] = watchCommunicator.connectionStrength
        debugInfo["pendingMessages"] = watchCommunicator.pendingMessagesCount
        return debugInfo
    }
    
    // MARK: - Core Data 저장
    func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("❌ Core Data 저장 실패: \(error)")
            }
        }
    }
    func refreshData() {
        print("🔄 데이터 새로고침 시작")
        
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        // 워크아웃 다시 로드
        loadWorkouts()
        
        DispatchQueue.main.async {
            self.isLoading = false
            print("✅ 데이터 새로고침 완료: \(self.workouts.count)개 워크아웃")
        }
    }
}
