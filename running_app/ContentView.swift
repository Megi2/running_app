import SwiftUI
import Charts

struct ContentView: View {
    @StateObject private var dataManager = RunningDataManager()
    
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
                    .tabItem {
                        Image(systemName: "gear")
                        Text("설정")
                    }
            }
            .navigationTitle("10km 달리기")
        }
    }
}
