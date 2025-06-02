//
//  AssessmentResultView.swift
//  running_app
//
//  Zone 2 평가 결과 화면 - 기존 컴포넌트 재사용
//

import SwiftUI

struct AssessmentResultView: View {
    let assessmentWorkout: WorkoutSummary
    let zone2CapacityScore: Zone2CapacityScore
    let recommendedGoals: Zone2Goals
    let zone2Profile: Zone2Profile
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // 축하 메시지
                    CelebrationHeaderView(workout: assessmentWorkout)
                    
                    // Zone 2 성과 요약
                    VStack(spacing: 20) {
                        Text("Zone 2 평가 결과")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        // Zone 2 기본 성과 (기존 컴포넌트 사용)
                        Zone2PerformanceCard(
                            title: "Zone 2 최대 지속력",
                            metrics: [
                                ("거리", "\(String(format: "%.2f", zone2Profile.maxSustainableDistance))km", .green),
                                ("시간", "\(Int(zone2Profile.maxSustainableTime/60))분 \(Int(zone2Profile.maxSustainableTime.truncatingRemainder(dividingBy: 60)))초", .blue),
                                ("Zone 2 유지율", "\(String(format: "%.1f", zone2Profile.zone2TimePercentage))%", .red),
                                ("평균 페이스", paceString(from: zone2Profile.averageZone2Pace), .purple)
                            ]
                        )
                        
                        // Zone 2 능력 점수 카드 (기존 컴포넌트 사용)
                        Zone2CapacityScoreCard(capacityScore: zone2CapacityScore, zone2Profile: zone2Profile)
                        
                        // 추천 목표 (기존 컴포넌트 사용)
                        Zone2RecommendedGoalsCard(goals: recommendedGoals)
                    }
                    
                    // 시작하기 버튼
                    Button("Zone 2 훈련 시작하기") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .font(.headline)
                    .padding(.horizontal, 40)
                }
                .padding()
            }
            .navigationTitle("Zone 2 평가 결과")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("완료") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func paceString(from pace: Double) -> String {
        let minutes = Int(pace) / 60
        let seconds = Int(pace) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
