//
//  SampleDataGenerator.swift
//  running_app
//
//  Zone 2 평가 시스템에 맞춰 수정된 샘플 데이터 생성기 (타입 오류 수정됨)
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
    
    // MARK: - Zone 2 평가 결과 생성 (Zone2 타입 사용)
    func generateZone2CapacityScore() -> Zone2CapacityScore {
        return Zone2CapacityScore(
            totalScore: 65.0,           // 중급 수준 점수
            distanceScore: 60.0,        // 거리 지속력
            timeScore: 70.0,            // 시간 지속력
            consistencyScore: 75.0,     // Zone 2 일관성
            efficiencyScore: 55.0       // 유산소 효율성
        )
    }
    
    func generateZone2Profile() -> Zone2Profile {
        return Zone2Profile(
            zone2Range: 135...155,              // 25세 여성 Zone 2 범위
            maxSustainableDistance: 1.02,      // 평가에서 달린 거리
            maxSustainableTime: 480,           // 8분
            averageZone2Pace: 470,             // 7분 50초/km
            zone2TimePercentage: 78.0,         // 78% Zone 2 유지
            zone2Efficiency: 0.45,             // 효율성 지수
            assessmentDate: Calendar.current.date(byAdding: .day, value: -60, to: Date())!
        )
    }
    
    func generateZone2Goals() -> Zone2Goals {
        return Zone2Goals(
            shortTermDistance: 2.5,     // 단기: 2.5km
            mediumTermDistance: 4.0,    // 중기: 4km
            longTermDistance: 6.5,      // 장기: 6.5km
            targetPace: 420,            // 7분/km
            improvementPace: 390,       // 6분 30초/km
            weeklyGoal: Zone2WeeklyGoal(
                runs: 3,
                totalDistance: 6.0,
                averagePace: 420
            ),
            assessmentDate: Calendar.current.date(byAdding: .day, value: -60, to: Date())!
        )
    }
    
    func generateZone2ProgressTracker() -> Zone2ProgressTracker {
        let goals = generateZone2Goals()
        let tracker = Zone2ProgressTracker(initialGoals: goals)
        
        // 현재 기록 설정
        tracker.bestDistance = 3.0
        tracker.bestPace = 420
        tracker.totalWorkouts = 9
        tracker.achievedShortTermDistance = true  // 2.5km 달성
        tracker.achievedMediumTermDistance = false // 4km 미달성
        tracker.achievedTargetPace = false
        
        // Zone 2 특화 기록
        tracker.bestZone2Distance = 2.7
        tracker.bestZone2Duration = 1140  // 19분
        tracker.bestZone2Consistency = 82.5  // 82.5% 유지율
        
        // 성취 기록
        tracker.achievements = [
            Zone2Achievement(
                title: "첫 목표 달성!",
                description: "2.0km 완주 성공",
                date: Calendar.current.date(byAdding: .day, value: -38, to: Date())!,
                type: .distance
            ),
            Zone2Achievement(
                title: "Zone 2 마스터",
                description: "80% 이상 Zone 2 유지",
                date: Calendar.current.date(byAdding: .day, value: -21, to: Date())!,
                type: .zone2
            )
        ]
        
        // 개인 기록
        tracker.personalRecords = [
            Zone2PersonalRecord(
                type: .distance,
                value: 3.0,
                date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!,
                description: "신기록: 3.00km"
            ),
            Zone2PersonalRecord(
                type: .pace,
                value: 420,
                date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!,
                description: "신기록: 7:00"
            ),
            Zone2PersonalRecord(
                type: .zone2Distance,
                value: 2.7,
                date: Calendar.current.date(byAdding: .day, value: -21, to: Date())!,
                description: "Zone 2 최장거리: 2.70km"
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
            
            // Zone 2 범위 심박수 (135-155)
            let baseHR = 145.0  // Zone 2 중간값
            let hrVariation = sin(Double(i) * 0.01) * 8 + Double.random(in: -5...5)
            let heartRate = baseHR + hrVariation
            
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
    
    // MARK: - 메인 로딩 함수 (수정됨 - 올바른 타입 사용)
    
    func loadSampleData() {
        print("🔄 Zone 2 샘플 데이터 로딩 시작...")
        
        // 1. 사용자 프로필 설정
        let profileManager = UserProfileManager.shared
        profileManager.userProfile = generateSampleUserProfile()
        profileManager.isProfileCompleted = true
        print("✅ 사용자 프로필 로딩 완료")
        
        // 2. Zone 2 체력 평가 매니저 설정 (올바른 Zone2 타입 사용)
        let assessmentManager = FitnessAssessmentManager.shared
        assessmentManager.hasCompletedAssessment = true
        assessmentManager.zone2CapacityScore = generateZone2CapacityScore()
        assessmentManager.recommendedGoals = generateZone2Goals()  // Zone2Goals 타입
        assessmentManager.assessmentWorkout = generateAssessmentWorkout()
        assessmentManager.zone2Profile = generateZone2Profile()
        assessmentManager.progressTracker = generateZone2ProgressTracker()  // Zone2ProgressTracker 타입
        print("✅ Zone 2 평가 데이터 로딩 완료")
        
        // 3. 운동 기록들 Core Data에 저장
        let coreDataManager = CoreDataManager.shared
        
        // 평가 운동 저장
        coreDataManager.saveWorkout(generateAssessmentWorkout())
        
        // 일반 운동들 저장
        for workout in generateWorkoutHistory() {
            coreDataManager.saveWorkout(workout)
        }
        print("✅ 운동 기록 저장 완료: 9개 워크아웃")
        
        print("🎉 Zone 2 샘플 데이터 로딩 완료: 25세 여성 초보 → 중급자 성장 스토리")
    }
}
