import SwiftUI
import WatchConnectivity

@main
struct running_appApp: App {
    @StateObject private var profileManager = UserProfileManager.shared
    @StateObject private var dataManager = RunningDataManager()
    @StateObject private var assessmentManager = FitnessAssessmentManager.shared
    
    var body: some Scene {
        WindowGroup {
            Group {
                if !profileManager.isProfileCompleted {
                    // 1단계: 프로필 설정 미완료 - 프로필 설정 화면
                    ProfileSetupView()
                        .environmentObject(profileManager)
                } else if !assessmentManager.hasCompletedAssessment {
                    // 2단계: 프로필 완료, 체력 평가 미완료 - 평가 안내 화면
                    AssessmentWelcomeScreenView()
                        .environmentObject(assessmentManager)
                        .environmentObject(dataManager)
                } else {
                    // 3단계: 모든 설정 완료 - 메인 앱
                    ContentView()
                        .environmentObject(profileManager)
                        .environmentObject(dataManager)
                        .environmentObject(assessmentManager)
                }
            }
            .onReceive(profileManager.$isProfileCompleted) { isCompleted in
                if isCompleted {
                    syncProfileToWatch()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("StartAssessmentRun"))) { notification in
                // Watch로 평가 모드 시작 신호 전송
                if let userInfo = notification.userInfo,
                   let targetDistance = userInfo["targetDistance"] as? Double,
                   let isAssessment = userInfo["isAssessment"] as? Bool {
                    startAssessmentMode(targetDistance: targetDistance, isAssessment: isAssessment)
                }
            }
        }
    }
    
    private func syncProfileToWatch() {
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
    
    private func startAssessmentMode(targetDistance: Double, isAssessment: Bool) {
        // Watch Connectivity를 통해 평가 모드 시작 신호 전송
        // 실제 구현에서는 WCSession을 사용
        print("📱 평가 모드 시작 신호 전송: \(targetDistance)km, 평가모드: \(isAssessment)")
        
        // WCSession을 통한 실제 구현
        if WCSession.isSupported() && WCSession.default.isReachable {
            let message = [
                "command": "start_assessment",
                "targetDistance": targetDistance,
                "isAssessment": isAssessment
            ] as [String: Any]
            
            WCSession.default.sendMessage(message, replyHandler: nil) { error in
                print("평가 모드 시작 신호 전송 실패: \(error)")
            }
        }
    }
}

// MARK: - 평가 환영 화면 (프로필 완료 후 처음 표시)
struct AssessmentWelcomeScreenView: View {
    @EnvironmentObject var assessmentManager: FitnessAssessmentManager
    @EnvironmentObject var dataManager: RunningDataManager
    @State private var showingAssessmentSetup = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                Spacer()
                
                VStack(spacing: 20) {
                    Image(systemName: "figure.run.circle.fill")
                        .font(.system(size: 100))
                        .foregroundColor(.blue)
                    
                    VStack(spacing: 12) {
                        Text("환영합니다!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("이제 당신만의 러닝 여정을 시작해볼까요?")
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                VStack(spacing: 20) {
                    WelcomeFeature(
                        icon: "target",
                        title: "개인 맞춤 목표",
                        description: "1km 평가로 당신에게 딱 맞는 목표를 설정해드려요"
                    )
                    
                    WelcomeFeature(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "성장 추적",
                        description: "실력 향상에 따라 목표가 자동으로 업데이트돼요"
                    )
                    
                    WelcomeFeature(
                        icon: "brain.head.profile",
                        title: "AI 코칭",
                        description: "실시간 분석으로 더 효과적인 운동을 도와드려요"
                    )
                }
                
                VStack(spacing: 16) {
                    Button("체력 평가 시작하기") {
                        showingAssessmentSetup = true
                    }
                    .buttonStyle(.borderedProminent)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    
                    Button("나중에 하기") {
                        // 기본 목표로 설정하고 건너뛰기
                        assessmentManager.hasCompletedAssessment = true
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingAssessmentSetup) {
            AssessmentSetupView()
                .environmentObject(dataManager)
        }
    }
}

struct WelcomeFeature: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40, height: 40)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
    }
}

// MARK: - Watch용 간단한 사용자 프로필 구조체
struct UserProfileForWatch: Codable {
    let weight: Double
    let gender: String
    let age: Int
}
