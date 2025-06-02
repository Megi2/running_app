//
//  AssessmentSummaryCard.swift
//  running_app
//
//  Zone 2 평가 결과 요약 카드들 (수정됨)
//

import SwiftUI

struct AssessmentSummaryCard: View {
    let workout: WorkoutSummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("평가 달리기 결과")
                .font(.headline)
                .fontWeight(.bold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                AssessmentMetric(title: "거리", value: String(format: "%.2f km", workout.distance), icon: "location")
                AssessmentMetric(title: "시간", value: timeString(from: workout.duration), icon: "clock")
                AssessmentMetric(title: "평균 페이스", value: paceString(from: workout.averagePace), icon: "speedometer")
                AssessmentMetric(title: "평균 심박수", value: "\(Int(workout.averageHeartRate)) bpm", icon: "heart")
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func paceString(from pace: Double) -> String {
        if pace == 0 { return "--:--" }
        let minutes = Int(pace) / 60
        let seconds = Int(pace) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct AssessmentMetric: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
    }
}

struct RecommendedGoalsCard: View {
    let goals: Zone2Goals  // RunningGoals → Zone2Goals로 변경
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("추천 목표")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                GoalRow(
                    title: "단기 목표 (2-4주)",
                    value: "\(String(format: "%.1f", goals.shortTermDistance))km",
                    color: .green,
                    description: "첫 번째 도전할 거리"
                )
                
                GoalRow(
                    title: "중기 목표 (2-3개월)",
                    value: "\(String(format: "%.1f", goals.mediumTermDistance))km",
                    color: .orange,
                    description: "중간 단계 목표"
                )
                
                GoalRow(
                    title: "장기 목표 (6개월)",
                    value: "\(String(format: "%.1f", goals.longTermDistance))km",
                    color: .purple,
                    description: "최종 목표 거리"
                )
                
                Divider()
                
                GoalRow(
                    title: "목표 페이스",
                    value: paceString(from: goals.targetPace),
                    color: .blue,
                    description: "향후 달성할 페이스"
                )
                
                GoalRow(
                    title: "주간 목표",
                    value: "\(goals.weeklyGoal.runs)회, \(String(format: "%.1f", goals.weeklyGoal.totalDistance))km",
                    color: .red,
                    description: "주당 권장 운동량"
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

struct GoalRow: View {
    let title: String
    let value: String
    let color: Color
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
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
        }
    }
}
