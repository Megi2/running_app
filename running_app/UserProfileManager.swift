import Foundation
import SwiftUICore

class UserProfileManager: ObservableObject {
    static let shared = UserProfileManager()
    
    @Published var userProfile: UserProfile
    @Published var isProfileCompleted: Bool = false
    @Published var showingCompletionView: Bool = false // 완료 화면 표시 여부 추가
    
    private let userDefaults = UserDefaults.standard
    private let profileKey = "UserProfile"
    
    private init() {
        // UserDefaults에서 프로필 로드
        if let savedProfileData = userDefaults.data(forKey: profileKey),
           let savedProfile = try? JSONDecoder().decode(UserProfile.self, from: savedProfileData) {
            self.userProfile = savedProfile
            self.isProfileCompleted = savedProfile.isCompleted
        } else {
            // 새 프로필 생성
            self.userProfile = UserProfile()
            self.isProfileCompleted = false
        }
    }
    
    // MARK: - 프로필 저장 (완료 화면만 표시)
    func saveProfileForCompletion() {
        userProfile.isCompleted = true
        
        if let encodedProfile = try? JSONEncoder().encode(userProfile) {
            userDefaults.set(encodedProfile, forKey: profileKey)
            
            DispatchQueue.main.async {
                self.showingCompletionView = true // 완료 화면만 표시
                // isProfileCompleted는 아직 true로 하지 않음
            }
            
            print("✅ 사용자 프로필 저장 완료 (완료 화면 대기)")
            printProfileSummary()
        }
    }
    
    // MARK: - 실제 완료 처리 (시작하기 버튼 클릭 시)
    func completeProfileSetup() {
        DispatchQueue.main.async {
            self.isProfileCompleted = true
            self.showingCompletionView = false
        }
        print("🎉 프로필 설정 완전 완료 - 메인 앱으로 이동")
    }
    
    // MARK: - 프로필 업데이트
    func updateProfile(_ newProfile: UserProfile) {
        userProfile = newProfile
        saveProfileForCompletion() // 완료 화면만 표시
    }
    
    // MARK: - 프로필 초기화
    func resetProfile() {
        userDefaults.removeObject(forKey: profileKey)
        
        userProfile = UserProfile()
        isProfileCompleted = false
        showingCompletionView = false
        
        print("🔄 사용자 프로필 초기화")
    }
    
    // MARK: - 칼로리 계산 메서드들
    
    /// 실시간 칼로리 계산 (누적)
    func calculateTotalCalories(dataPoints: [RunningDataPoint]) -> Double {
        guard !dataPoints.isEmpty else { return 0 }
        
        var totalCalories: Double = 0
        
        for i in 1..<dataPoints.count {
            let prevPoint = dataPoints[i-1]
            let currentPoint = dataPoints[i]
            
            let duration = currentPoint.timestamp.timeIntervalSince(prevPoint.timestamp)
            let pace = (prevPoint.pace + currentPoint.pace) / 2 // 평균 페이스
            
            if pace > 0 && duration > 0 {
                let segmentCalories = userProfile.calculateCalories(pace: pace, duration: duration)
                totalCalories += segmentCalories
            }
        }
        
        return totalCalories
    }
    
    /// 현재 페이스 기준 분당 칼로리
    func currentCaloriesPerMinute(pace: Double) -> Double {
        return userProfile.caloriesPerMinute(pace: pace)
    }
    
    /// 예상 총 칼로리 (현재 페이스 유지 시)
    func estimatedTotalCalories(currentPace: Double, elapsedTime: TimeInterval, targetDistance: Double, currentDistance: Double) -> Double {
        // 이미 소모한 칼로리
        let consumedCalories = userProfile.calculateCalories(pace: currentPace, duration: elapsedTime)
        
        // 남은 거리
        let remainingDistance = max(0, targetDistance - currentDistance)
        
        if remainingDistance <= 0 {
            return consumedCalories
        }
        
        // 남은 시간 예상 (현재 페이스 기준)
        let remainingTime = remainingDistance * currentPace / 1000 // 페이스는 초/km
        
        // 남은 구간 예상 칼로리
        let remainingCalories = userProfile.calculateCalories(pace: currentPace, duration: remainingTime)
        
        return consumedCalories + remainingCalories
    }
    
    // MARK: - 심박수 존 분석
    func getHeartRateZone(for heartRate: Double) -> (zone: Int?, name: String, color: Color) {
        let zones = userProfile.heartRateZones
        let zone = zones.getZone(for: heartRate)
        
        if let zone = zone {
            return (zone, zones.getZoneName(for: zone), zones.getZoneColor(for: zone))
        } else {
            return (nil, "범위 외", .gray)
        }
    }
    
    // MARK: - 디버그 정보
    private func printProfileSummary() {
        print("""
        👤 사용자 프로필 요약:
        - 성별: \(userProfile.gender.rawValue)
        - 나이: \(userProfile.age)세
        - 몸무게: \(userProfile.weight)kg
        - 키: \(userProfile.height)cm
        - BMI: \(String(format: "%.1f", userProfile.bmi)) (\(userProfile.bmiCategory))
        - 최대 심박수: \(Int(userProfile.maxHeartRate)) bpm
        - 안정시 심박수: \(Int(userProfile.restingHeartRate)) bpm
        - 6분/km 칼로리: \(String(format: "%.1f", userProfile.caloriesPerMinute(pace: 360))) cal/분
        """)
    }
}
