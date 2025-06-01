import Foundation
import CoreData

class CoreDataManager: ObservableObject {
    static let shared = CoreDataManager()
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "RunningDataModel")
        
        container.loadPersistentStores { _, error in
            if let error = error {
                print("Core Data 로드 실패: \(error)")
            } else {
                print("✅ Core Data 초기화 완료")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    private init() {}
    
    // MARK: - 워크아웃 저장
    func saveWorkout(_ workout: WorkoutSummary) {
        let workoutEntity = WorkoutEntity(context: context)
        workoutEntity.id = workout.id
        workoutEntity.date = workout.date
        workoutEntity.duration = workout.duration
        workoutEntity.distance = workout.distance
        workoutEntity.averageHeartRate = workout.averageHeartRate
        workoutEntity.averagePace = workout.averagePace
        workoutEntity.averageCadence = workout.averageCadence
        
        // DataPoints를 JSON으로 인코딩
        if let dataPointsData = try? JSONEncoder().encode(workout.dataPoints) {
            workoutEntity.dataPointsData = dataPointsData
        }
        
        saveContext()
    }
    
    // MARK: - 워크아웃 불러오기
    func fetchWorkouts() -> [WorkoutSummary] {
        let request: NSFetchRequest<WorkoutEntity> = WorkoutEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WorkoutEntity.date, ascending: false)]
        
        do {
            let workoutEntities = try context.fetch(request)
            return workoutEntities.compactMap { entity -> WorkoutSummary? in
                guard let id = entity.id,
                      let date = entity.date else {
                    print("⚠️ 필수 필드 누락: id=\(entity.id?.uuidString ?? "nil"), date=\(entity.date?.description ?? "nil")")
                    return nil
                }
                
                // JSON에서 DataPoints 디코딩
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
        } catch {
            print("워크아웃 데이터 불러오기 실패: \(error)")
            return []
        }
    }
    
    // MARK: - 워크아웃 삭제
    func deleteWorkout(id: UUID) {
        let request: NSFetchRequest<WorkoutEntity> = WorkoutEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            let workouts = try context.fetch(request)
            workouts.forEach { context.delete($0) }
            saveContext()
        } catch {
            print("워크아웃 삭제 실패: \(error)")
        }
    }
    
    // MARK: - 모든 데이터 삭제
    func deleteAllWorkouts() {
        let request: NSFetchRequest<NSFetchRequestResult> = WorkoutEntity.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        
        do {
            try context.execute(deleteRequest)
            saveContext()
            print("✅ 모든 워크아웃 데이터 삭제 완료")
        } catch {
            print("전체 데이터 삭제 실패: \(error)")
        }
    }
    
    // MARK: - 컨텍스트 저장
    func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
                print("✅ Core Data 저장 완료")
            } catch {
                print("Core Data 저장 실패: \(error)")
            }
        }
    }
    
    // MARK: - 데이터 통계
    func getDataStats() -> (workoutCount: Int, totalDistance: Double, oldestDate: Date?) {
        let request: NSFetchRequest<WorkoutEntity> = WorkoutEntity.fetchRequest()
        
        do {
            let workouts = try context.fetch(request)
            let totalDistance = workouts.reduce(0) { $0 + $1.distance }
            let oldestDate = workouts.min(by: { $0.date ?? Date() < $1.date ?? Date() })?.date
            
            return (workouts.count, totalDistance, oldestDate)
        } catch {
            return (0, 0, nil)
        }
    }
}
