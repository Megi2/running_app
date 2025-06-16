//
//  MockAssessmentResultView.swift
//  running_app
//
//  임시 평가 결과 화면
//

import SwiftUI

// MARK: - 임시 평가 결과 화면
struct MockAssessmentResultView: View {
    let assessmentWorkout: WorkoutSummary
    let zone2CapacityScore: Zone2CapacityScore
    let recommendedGoals: RunningGoals
    let zone2Profile: Zone2Profile
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var mockHandler = MockAssessmentHandler.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // 축하 메시지
                    CelebrationHeader(
                        workout: assessmentWorkout,
                        zone2Profile: zone2Profile
                    )
                    
                    // Zone 2 성과 요약
                    VStack(spacing: 20) {
                        Text("Zone 2 평가 결과")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        // Zone 2 기본 성과
                        Zone2PerformanceCard(
                            title: "Zone 2 최대 지속력",
                            metrics: [
                                ("거리", "\(String(format: "%.1f", zone2Profile.maxSustainableDistance))km", .green),
                                ("시간", "\(Int(zone2Profile.maxSustainableTime/60))분", .blue),
                                ("Zone 2 유지율", "\(String(format: "%.0f", zone2Profile.zone2TimePercentage))%", .red),
                                ("평균 페이스", paceString(from: zone2Profile.averageZone2Pace), .purple)
                            ]
                        )
                        
                        // Zone 2 능력 점수 카드
                        Zone2CapacityScoreCard(
                            capacityScore: zone2CapacityScore,
                            zone2Profile: zone2Profile
                        )
                        
                        // 추천 목표
                        RunningGoalsCard(
                            goals: recommendedGoals
                        )
                    }
                    
                    // 시작하기 버튼
                    Button("Zone 2 훈련 시작하기") {
                        mockHandler.dismissResult()
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .font(.headline)
                    .padding(.horizontal, 40)
                }
                .padding()
            }
            .navigationTitle("평가 완료!")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("완료") {
                        mockHandler.dismissResult()
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

// MARK: - 축하 헤더
struct CelebrationHeader: View {
    let workout: WorkoutSummary
    let zone2Profile: Zone2Profile
    
    var body: some View {
        VStack(spacing: 20) {
            // 성공 아이콘과 메시지
            VStack(spacing: 16) {
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.red)
                    .symbolEffect(.bounce, value: true)
                
                Text("평가 완료!")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("\(String(format: "%.1f", workout.distance))km를 \(Int(workout.duration/60))분간 완주하셨습니다")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // 핵심 성과 요약
            HStack(spacing: 20) {
                AchievementBadge(
                    title: "지속 거리",
                    value: "\(String(format: "%.1f", zone2Profile.maxSustainableDistance))km",
                    color: .green
                )
                
                AchievementBadge(
                    title: "Zone 2 유지",
                    value: "\(Int(zone2Profile.zone2TimePercentage))%",
                    color: .red
                )
                
                AchievementBadge(
                    title: "지속 시간",
                    value: "\(Int(zone2Profile.maxSustainableTime/60))분",
                    color: .blue
                )
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.red.opacity(0.1), Color.blue.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
    }
}

// MARK: - 성취 배지
struct AchievementBadge: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - 러닝 목표 카드 (RunningGoals 타입용)
struct RunningGoalsCard: View {
    let goals: RunningGoals
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("개인 맞춤 목표")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                RunningGoalRow(
                    title: "단기 목표 (4-6주)",
                    value: "\(String(format: "%.1f", goals.shortTermDistance))km",
                    color: .green,
                    description: "Zone 2에서 편안하게 완주 가능한 거리",
                    progress: 0.8 // 현재 4.8km / 6km = 80%
                )
                
                RunningGoalRow(
                    title: "중기 목표 (3-4개월)",
                    value: "\(String(format: "%.1f", goals.mediumTermDistance))km",
                    color: .orange,
                    description: "Zone 2 능력 향상 후 도전할 거리",
                    progress: 0.6 // 현재 4.8km / 8km = 60%
                )
                
                RunningGoalRow(
                    title: "장기 목표 (6-12개월)",
                    value: "\(String(format: "%.1f", goals.longTermDistance))km",
                    color: .purple,
                    description: "최종 목표 거리",
                    progress: 0.4 // 현재 4.8km / 12km = 40%
                )
                
                Divider()
                
                RunningGoalRow(
                    title: "목표 페이스 개선",
                    value: paceString(from: goals.targetPace),
                    color: .blue,
                    description: "Zone 2에서 달성할 목표 페이스",
                    progress: 0.7 // 현재 6:15 → 목표 5:50
                )
                
                RunningGoalRow(
                    title: "주간 훈련량",
                    value: "\(goals.weeklyGoal.runs)회, \(String(format: "%.1f", goals.weeklyGoal.totalDistance))km",
                    color: .red,
                    description: "주당 권장 Zone 2 훈련량",
                    progress: 0.33 // 1회 완료 / 3회 목표
                )
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func paceString(from pace: Double) -> String {
        let minutes = Int(pace) / 60
        let seconds = Int(pace) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - 러닝 목표 행 (RunningGoals용)
struct RunningGoalRow: View {
    let title: String
    let value: String
    let color: Color
    let description: String
    let progress: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
            
            // 진행률 바
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * progress, height: 4)
                        .cornerRadius(2)
                        .animation(.easeInOut(duration: 1.5), value: progress)
                }
            }
            .frame(height: 4)
            
            HStack {
                Text("현재 진행률")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(color)
            }
        }
    }
}
