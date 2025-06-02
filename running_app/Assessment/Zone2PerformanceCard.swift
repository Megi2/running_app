import SwiftUI

// MARK: - Zone 2 성과 카드
struct Zone2PerformanceCard: View {
    let title: String
    let metrics: [(String, String, Color)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                ForEach(Array(metrics.enumerated()), id: \.offset) { index, metric in
                    Zone2MetricView(title: metric.0, value: metric.1, color: metric.2)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct Zone2MetricView: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Zone 2 능력 점수 카드
struct Zone2CapacityScoreCard: View {
    let capacityScore: Zone2CapacityScore
    let zone2Profile: Zone2Profile
    
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.title)
                    .foregroundColor(capacityScore.scoreColor)
                
                VStack(alignment: .leading) {
                    Text("Zone 2 능력 점수")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(capacityScore.totalScore))/100")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(capacityScore.scoreColor)
                }
                
                Spacer()
            }
            
            // 세부 점수 차트
            VStack(spacing: 8) {
                ScoreBar(title: "거리 지속력", score: capacityScore.distanceScore, color: .green)
                ScoreBar(title: "시간 지속력", score: capacityScore.timeScore, color: .blue)
                ScoreBar(title: "Zone 2 일관성", score: capacityScore.consistencyScore, color: .red)
                ScoreBar(title: "유산소 효율성", score: capacityScore.efficiencyScore, color: .purple)
            }
            
            // 강점과 개선점
            VStack(alignment: .leading, spacing: 8) {
                if !capacityScore.strengthAreas.isEmpty {
                    Text("강점 영역")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                    
                    ForEach(capacityScore.strengthAreas, id: \.self) { strength in
                        Text("✓ \(strength)")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                
                if !capacityScore.improvementAreas.isEmpty {
                    Text("개선 영역")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                        .padding(.top, 4)
                    
                    ForEach(capacityScore.improvementAreas, id: \.self) { improvement in
                        Text("→ \(improvement)")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(capacityScore.scoreColor.opacity(0.1))
        .cornerRadius(12)
    }
}

struct ScoreBar: View {
    let title: String
    let score: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(score))")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(color)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)
                        .cornerRadius(3)
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * (score / 100), height: 6)
                        .cornerRadius(3)
                }
            }
            .frame(height: 6)
        }
    }
}

// MARK: - Zone 2 추천 목표 카드
struct Zone2RecommendedGoalsCard: View {
    let goals: Zone2Goals
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Zone 2 기반 추천 목표")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                Zone2GoalRow(
                    title: "단기 목표 (4-6주)",
                    value: "\(String(format: "%.1f", goals.shortTermDistance))km",
                    color: .green,
                    description: "Zone 2에서 편안하게 완주 가능한 거리"
                )
                
                Zone2GoalRow(
                    title: "중기 목표 (3-4개월)",
                    value: "\(String(format: "%.1f", goals.mediumTermDistance))km",
                    color: .orange,
                    description: "Zone 2 능력 향상 후 도전할 거리"
                )
                
                Zone2GoalRow(
                    title: "장기 목표 (6-12개월)",
                    value: "\(String(format: "%.1f", goals.longTermDistance))km",
                    color: .purple,
                    description: "최종 목표 거리"
                )
                
                Divider()
                
                Zone2GoalRow(
                    title: "Zone 2 목표 페이스",
                    value: paceString(from: goals.targetPace),
                    color: .red,
                    description: "Zone 2 유지하며 달릴 목표 페이스"
                )
                
                Zone2GoalRow(
                    title: "주간 Zone 2 훈련",
                    value: "\(goals.weeklyGoal.runs)회, \(String(format: "%.1f", goals.weeklyGoal.totalDistance))km",
                    color: .blue,
                    description: "주당 권장 Zone 2 훈련량"
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

struct Zone2GoalRow: View {
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
