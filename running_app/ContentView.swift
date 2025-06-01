import SwiftUI
import Charts

struct ContentView: View {
    @EnvironmentObject var dataManager: RunningDataManager
    @EnvironmentObject var profileManager: UserProfileManager
    
    var body: some View {
        NavigationView {
            TabView {
                // 홈 화면
                HomeView()
                    .environmentObject(dataManager)
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("홈")
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
    }
}
