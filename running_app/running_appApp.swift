import SwiftUI

@main
struct running_appApp: App {
    @StateObject private var profileManager = UserProfileManager.shared
    @StateObject private var dataManager = RunningDataManager()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if profileManager.isProfileCompleted {
                    // 프로필 설정 완료 - 메인 앱 표시
                    ContentView()
                        .environmentObject(profileManager)
                        .environmentObject(dataManager)
                } else {
                    // 프로필 설정 미완료 - 설정 화면 표시
                    ProfileSetupView()
                        .environmentObject(profileManager)
                }
            }
            .onReceive(profileManager.$isProfileCompleted) { isCompleted in
                // 프로필 완료 상태 변경 시 Watch에 프로필 동기화
                if isCompleted {
                    syncProfileToWatch()
                }
            }
        }
    }
    
    private func syncProfileToWatch() {
        // iPhone에서 Watch로 사용자 프로필 동기화
        let profile = profileManager.userProfile
        let watchProfile = UserProfileForWatch(
            weight: profile.weight,
            gender: profile.gender.rawValue,
            age: profile.age
        )
        
        if let profileData = try? JSONEncoder().encode(watchProfile) {
            UserDefaults.standard.set(profileData, forKey: "UserProfile")
            print("✅ Watch로 프로필 동기화 완료")
        }
    }
}

// MARK: - Watch 동기화용 간단한 프로필 구조체
struct UserProfileForWatch: Codable {
    let weight: Double
    let gender: String
    let age: Int
}
