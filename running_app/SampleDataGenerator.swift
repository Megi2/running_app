//
//  SampleDataGenerator.swift
//  running_app
//
//  샘플 데이터 생성기 (수정된 버전)
//

import Foundation

class SampleDataGenerator {
    static let shared = SampleDataGenerator()
    private init() {}
    
    // MARK: - 25세 여성 초보 러너 샘플 데이터
    
    func generateSampleUserProfile() -> UserProfile {
        var profile = UserProfile()
        profile.gender = .female
        profile.age = 25
        profile.weight = 58.0
        profile.height = 163.0
        profile.isCompleted = true
        return profile
    }
    
    func generateAssessmentWorkout() -> WorkoutSummary {
        return WorkoutSummary(
            date: Calendar.current.date(byAdding: .day, value: -60, to: Date())!,
            duration: 480, // 8분
            distance: 1.02,
            averageHeartRate: 165,
            averagePace: 470, // 7분 50초/km
            averageCadence: 160,
            dataPoints: generateAssessmentDataPoints()
        )
    }
    
    func generateWorkoutHistory() -> [WorkoutSummary] {
        return [
            // 1주차 첫 운동
            WorkoutSummary(
                date: Calendar.current.date(byAdding: .day, value: -57, to: Date())!,
                duration: 540,
                distance: 1.1,
                averageHeartRate: 155,
                averagePace: 490,
                averageCadence: 158,
                dataPoints: generateBeginnerDataPoints(distance: 1.1, pace: 490)
            ),
            
            // 1주차 두 번째
            WorkoutSummary(
                date: Calendar.current.date(byAdding: .day, value: -54, to: Date())!,
                duration: 600,
                distance: 1.2,
                averageHeartRate: 162,
                averagePace: 500,
                averageCadence: 162,
                dataPoints: generateBeginnerDataPoints(distance: 1.2, pace: 500)
            ),
            
            // 2주차
            WorkoutSummary(
                date: Calendar.current.date(byAdding: .day, value: -50, to: Date())!,
                duration: 720,
                distance: 1.5,
                averageHeartRate: 158,
                averagePace: 480,
                averageCadence: 165,
                dataPoints: generateBeginnerDataPoints(distance: 1.5, pace: 480)
            ),
            
            // 3주차
            WorkoutSummary(
                date: Calendar.current.date(byAdding: .day, value: -43, to: Date())!,
                duration: 840,
                distance: 1.8,
                averageHeartRate: 160,
                averagePace: 467,
                averageCadence: 168,
                dataPoints: generateBeginnerDataPoints(distance: 1.8, pace: 467)
            ),
            
            // 4주차 - 첫 목표 달성
            WorkoutSummary(
                date: Calendar.current.date(byAdding: .day, value: -38, to: Date())!,
                duration: 900,
                distance: 2.0,
                averageHeartRate: 163,
                averagePace: 450,
                averageCadence: 170,
                dataPoints: generateProgressDataPoints(distance: 2.0, pace: 450)
            ),
            
            // 6주차
            WorkoutSummary(
                date: Calendar.current.date(byAdding: .day, value: -28, to: Date())!,
                duration: 1080,
                distance: 2.4,
                averageHeartRate: 158,
                averagePace: 450,
                averageCadence: 172,
                dataPoints: generateProgressDataPoints(distance: 2.4, pace: 450)
            ),
            
            // 7주차
            WorkoutSummary(
                date: Calendar.current.date(byAdding: .day, value: -21, to: Date())!,
                duration: 1200,
                distance: 2.7,
                averageHeartRate: 155,
                averagePace: 444,
                averageCadence: 174,
                dataPoints: generateProgressDataPoints(distance: 2.7, pace: 444)
            ),
            
            // 8주차 - 최근 최고 기록
            WorkoutSummary(
                date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!,
                duration: 1260,
                distance: 3.0,
                averageHeartRate: 152,
                averagePace: 420, // 7분/km
                averageCadence: 176,
                dataPoints: generateProgressDataPoints(distance: 3.0, pace: 420)
            )
        ]
    }
    
    func generateCurrentGoals() -> RunningGoals {
        return RunningGoals(
            shortTermDistance: 4.0,
            mediumTermDistance: 5.0,
            longTermDistance: 7.5,
            targetPace: 400, // 6분 40초/km
            improvementPace: 380,
            weeklyGoal: WeeklyGoal(
                runs: 3,
                totalDistance: 8.0,
                averagePace: 420
            ),
            fitnessLevel: FitnessLevel(score: 65, date: Calendar.current.date(byAdding: .day, value: -60, to: Date())!),
            assessmentDate: Calendar.current.date(byAdding: .day, value: -60, to: Date())!
        )
    }
    
    func generateProgressTracker() -> ProgressTracker {
        let tracker = ProgressTracker(initialGoals: generateCurrentGoals())
        tracker.bestDistance = 3.0
        tracker.bestPace = 420
        tracker.totalWorkouts = 9
        tracker.achievedShortTermDistance = true
        tracker.achievedMediumTermDistance = false
        tracker.achievedTargetPace = false
        
        tracker.achievements = [
            Achievement(
                title: "첫 목표 달성!",
                description: "2.0km 완주 성공",
                date: Calendar.current.date(byAdding: .day, value: -38, to: Date())!,
                type: .distance
            ),
            Achievement(
                title: "체력 향상!",
                description: "점수: 65/100",
                date: Calendar.current.date(byAdding: .day, value: -10, to: Date())!,
                type: .improvement
            )
        ]
        
        tracker.personalRecords = [
            PersonalRecord(
                type: .distance,
                value: 3.0,
                date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!,
                description: "신기록: 3.00km"
            ),
            PersonalRecord(
                type: .pace,
                value: 420,
                date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!,
                description: "신기록: 7:00"
            )
        ]
        
        return tracker
    }
    
    // MARK: - 데이터 포인트 생성 함수들
    
    private func generateAssessmentDataPoints() -> [RunningDataPoint] {
        var dataPoints: [RunningDataPoint] = []
        let startTime = Date()
        
        for i in 0..<480 { // 8분
            let timestamp = startTime.addingTimeInterval(Double(i))
            let progress = Double(i) / 480.0
            
            let basePace = 470.0
            let paceVariation = sin(Double(i) * 0.02) * 40 + Double.random(in: -20...20)
            let fatigueFactor = progress * 30
            let pace = basePace + paceVariation + fatigueFactor
            
            let baseHR = 155.0
            let hrIncrease = progress * 15
            let hrVariation = Double.random(in: -5...5)
            let heartRate = baseHR + hrIncrease + hrVariation
            
            let baseCadence = 160.0
            let cadenceVariation = Double.random(in: -8...8)
            let cadence = baseCadence + cadenceVariation
            
            let distance = progress * 1.02
            
            dataPoints.append(RunningDataPoint(
                timestamp: timestamp,
                pace: pace,
                heartRate: heartRate,
                cadence: cadence,
                distance: distance
            ))
        }
        
        return dataPoints
    }
    
    private func generateBeginnerDataPoints(distance: Double, pace: Double) -> [RunningDataPoint] {
        var dataPoints: [RunningDataPoint] = []
        let duration = distance * pace
        let startTime = Date()
        
        for i in stride(from: 0, to: Int(duration), by: 5) {
            let timestamp = startTime.addingTimeInterval(Double(i))
            let progress = Double(i) / duration
            
            let paceVariation = sin(Double(i) * 0.01) * 30 + Double.random(in: -15...15)
            let currentPace = pace + paceVariation
            
            let targetHR = 155.0 + (pace < 450 ? 10 : 0)
            let hrVariation = Double.random(in: -8...8)
            let heartRate = targetHR + hrVariation
            
            let baseCadence = 158.0 + (Double(i) / duration) * 10
            let cadenceVariation = Double.random(in: -5...5)
            let cadence = baseCadence + cadenceVariation
            
            let currentDistance = progress * distance
            
            dataPoints.append(RunningDataPoint(
                timestamp: timestamp,
                pace: currentPace,
                heartRate: heartRate,
                cadence: cadence,
                distance: currentDistance
            ))
        }
        
        return dataPoints
    }
    
    private func generateProgressDataPoints(distance: Double, pace: Double) -> [RunningDataPoint] {
        var dataPoints: [RunningDataPoint] = []
        let duration = distance * pace
        let startTime = Date()
        
        for i in stride(from: 0, to: Int(duration), by: 5) {
            let timestamp = startTime.addingTimeInterval(Double(i))
            let progress = Double(i) / duration
            
            let paceVariation = sin(Double(i) * 0.01) * 15 + Double.random(in: -10...10)
            let currentPace = pace + paceVariation
            
            let targetHR = 150.0 + (pace < 430 ? 8 : 0)
            let hrVariation = Double.random(in: -5...5)
            let heartRate = targetHR + hrVariation
            
            let baseCadence = 170.0 + (Double(i) / duration) * 8
            let cadenceVariation = Double.random(in: -3...3)
            let cadence = baseCadence + cadenceVariation
            
            let currentDistance = progress * distance
            
            dataPoints.append(RunningDataPoint(
                timestamp: timestamp,
                pace: currentPace,
                heartRate: heartRate,
                cadence: cadence,
                distance: currentDistance
            ))
        }
        
        return dataPoints
    }
    
    // MARK: - 메인 로딩 함수
    
    func loadSampleData() {
        print("🔄 샘플 데이터 로딩 시작...")
        
        // 1. 사용자 프로필 설정
        let profileManager = UserProfileManager.shared
        profileManager.userProfile = generateSampleUserProfile()
        profileManager.isProfileCompleted = true
        print("✅ 사용자 프로필 로딩 완료")
        
        // 2. 체력 평가 매니저 설정
        let assessmentManager = FitnessAssessmentManager.shared
        assessmentManager.hasCompletedAssessment = true
        assessmentManager.currentFitnessLevel = FitnessLevel(score: 65, date: Calendar.current.date(byAdding: .day, value: -60, to: Date())!)
        assessmentManager.recommendedGoals = generateCurrentGoals()
        assessmentManager.assessmentWorkout = generateAssessmentWorkout()
        assessmentManager.progressTracker = generateProgressTracker()
        print("✅ 체력 평가 데이터 로딩 완료")
        
        // 3. 운동 기록들 Core Data에 저장
        let coreDataManager = CoreDataManager.shared
        
        // 평가 운동 저장
        coreDataManager.saveWorkout(generateAssessmentWorkout())
        
        // 일반 운동들 저장
        for workout in generateWorkoutHistory() {
            coreDataManager.saveWorkout(workout)
        }
        print("✅ 운동 기록 저장 완료: 9개 워크아웃")
        
        print("🎉 샘플 데이터 로딩 완료: 25세 여성 초보 러너 → 중급자 성장 스토리")
    }
}
