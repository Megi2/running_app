//
//  ContentView.swift
//  running_app
//
//  메인 콘텐츠 뷰 (타입 수정됨)
//

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
                
                // 목표 & 진행상황 화면
                GoalsDashboardView()
                    .environmentObject(dataManager)
                    .environmentObject(assessmentManager)
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
                updateProgressWithWorkout(workout)
            }
        }
    }
    
    private func updateProgressWithWorkout(_ workout: WorkoutSummary) {
        // Zone 2 평가가 완료된 경우에만 진행상황 업데이트
        if assessmentManager.hasCompletedAssessment,
           let tracker = assessmentManager.progressTracker {
            
            // 기본 기록 업데이트
            if workout.distance > tracker.bestDistance {
                tracker.bestDistance = workout.distance
            }
            
            if workout.averagePace < tracker.bestPace {
                tracker.bestPace = workout.averagePace
            }
            
            tracker.totalWorkouts += 1
            
            // 주간 통계 업데이트
            tracker.updateWeeklyProgress(workout)
            
            print("📊 진행상황 업데이트 완료: 최고거리 \(tracker.bestDistance)km")
        }
    }
}
