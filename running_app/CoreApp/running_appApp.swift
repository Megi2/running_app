//
//  running_appApp.swift
//  running_app
//
//  메인 앱 진입점 (수정된 버전)
//

import SwiftUI
import WatchConnectivity

@main
struct running_appApp: App {
    @StateObject private var profileManager = UserProfileManager.shared
    @StateObject private var dataManager = RunningDataManager()
    @StateObject private var assessmentManager = FitnessAssessmentManager.shared
    @StateObject private var assessmentCoordinator = AssessmentCoordinator.shared
    
    var body: some Scene {
        WindowGroup {
            Group {
                if !profileManager.isProfileCompleted {
                    // 1단계: 프로필 설정 미완료 - 프로필 설정 화면
                    ProfileSetupView()
                        .environmentObject(profileManager)
                } else if !assessmentManager.hasCompletedAssessment && !assessmentCoordinator.isAssessmentModeActive {
                    // 2단계: 프로필 완료, 체력 평가 미완료, 평가 진행 중 아님 - 평가 안내 화면
                    AssessmentWelcomeScreenView()
                        .environmentObject(assessmentManager)
                        .environmentObject(dataManager)
                        .environmentObject(assessmentCoordinator)
                } else {
                    // 3단계: 모든 설정 완료 또는 평가 진행 중 - 메인 앱
                    ContentView()
                        .environmentObject(profileManager)
                        .environmentObject(dataManager)
                        .environmentObject(assessmentManager)
                        .environmentObject(assessmentCoordinator)
                }
            }
            .onReceive(profileManager.$isProfileCompleted) { isCompleted in
                if isCompleted {
                    syncProfileToWatch()
                }
            }
            .onReceive(assessmentCoordinator.$isAssessmentModeActive) { isActive in
                print("📊 평가 모드 상태 변경: \(isActive)")
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
}

// MARK: - 평가 환영 화면 (수정된 버전)
struct AssessmentWelcomeScreenView: View {
    @EnvironmentObject var assessmentManager: FitnessAssessmentManager
    @EnvironmentObject var dataManager: RunningDataManager
    @EnvironmentObject var assessmentCoordinator: AssessmentCoordinator
    @State private var showingAssessmentSetup = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                Spacer()
                
                VStack(spacing: 20) {
                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 100))
                        .foregroundColor(.red)
                    
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
                        icon: "heart.fill",
                        title: "Zone 2 기반 평가",
                        description: "편안한 심박수로 최대한 오래 달려보세요"
                    )
                    
                    WelcomeFeature(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "정량적 목표 설정",
                        description: "측정된 능력에 기반한 과학적 목표"
                    )
                    
                    WelcomeFeature(
                        icon: "brain.head.profile",
                        title: "AI 실시간 분석",
                        description: "운동 중 효율성과 페이스 안정성 모니터링"
                    )
                }
                
                VStack(spacing: 16) {
                    Button("Zone 2 체력 평가 시작하기") {
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
                .foregroundColor(.red)
                .frame(width: 40, height: 40)
                .background(Color.red.opacity(0.1))
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
