import SwiftUI
import Charts

struct ContentView: View {
    @EnvironmentObject var dataManager: RunningDataManager
    @EnvironmentObject var profileManager: UserProfileManager
    @EnvironmentObject var assessmentManager: FitnessAssessmentManager
    
    var body: some View {
        NavigationView {
            TabView {
                // 홈 화면 (목표 중심으로 개편)
                HomeView()
                    .environmentObject(dataManager)
                    .environmentObject(assessmentManager)
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("홈")
                    }
                
                // 목표 & 진행상황 화면 (새로 추가)
                GoalsDashboardView()
                    .environmentObject(dataManager)
                    .tabItem {
                        Image(systemName: "target")
                        Text("목표")
                    }
                
                // 운동 기록 화면
                WorkoutHistoryView()
                    .environmentObject(dataManager)
                    .tabItem {
                        Image(systemName: "list.bullet")
                        Text("기록")
                    }
                
                // 분석 화면
                AnalysisView()
                    .environmentObject(dataManager)
                    .tabItem {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                        Text("분석")
                    }
                
                // 설정 화면
                SettingsView()
                    .environmentObject(dataManager)
                    .environmentObject(profileManager)
                    .tabItem {
                        Image(systemName: "gear")
                        Text("설정")
                    }
            }
            .navigationTitle("10km 달리기")
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("WorkoutCompleted"))) { notification in
            // 운동 완료 시 목표 진행상황 업데이트
            if let workout = notification.object as? WorkoutSummary {
                assessmentManager.updateProgress(with: workout)
            }
        }
    }
}
