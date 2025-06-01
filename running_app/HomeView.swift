import SwiftUI

struct HomeView: View {
    @EnvironmentObject var dataManager: RunningDataManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 실시간 모니터링 (운동 중일 때만 표시)
                if dataManager.isReceivingRealtimeData {
                    RealtimeMonitoringView()
                        .environmentObject(dataManager)
                }
                
                // 목표 진행상황
                GoalProgressView()
                    .environmentObject(dataManager)
                
                // 최근 운동
                RecentWorkoutView()
                    .environmentObject(dataManager)
                
                // 주간 통계
                WeeklyStatsView()
                    .environmentObject(dataManager)
            }
            .padding()
        }
        .navigationTitle("홈")
    }
}

struct MetricView: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
}

struct WeeklyStatsView: View {
    @EnvironmentObject var dataManager: RunningDataManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("이번 주 통계")
                .font(.headline)
                .fontWeight(.bold)
            
            let weeklyStats = dataManager.getWeeklyStats()
            
            HStack {
                VStack(alignment: .leading) {
                    Text("총 거리")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f km", weeklyStats.totalDistance))
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .center) {
                    Text("운동 횟수")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(weeklyStats.workoutCount)회")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("평균 효율성")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.3f", weeklyStats.averageEfficiency))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.purple)
                }
            }
        }
        .padding()
        .background(Color.purple.opacity(0.1))
        .cornerRadius(12)
    }
}

struct RealtimeMonitoringView: View {
    @EnvironmentObject var dataManager: RunningDataManager
    @State private var isExpanded = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.purple)
                    .font(.title2)
                
                Text("AI 실시간 분석")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.blue)
                }
            }
            
            if isExpanded, let realtimeData = dataManager.currentRealtimeData {
                VStack(spacing: 12) {
                    // 경고 상태 표시
                    if realtimeData.isWarningActive {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            VStack(alignment: .leading) {
                                Text("워치에서 경고 발생")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.red)
                                Text(realtimeData.warningMessage)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(10)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // 실시간 데이터 표시
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 10) {
                        RealtimeMetricView(
                            title: "경과 시간",
                            value: timeString(from: realtimeData.elapsedTime),
                            icon: "clock",
                            color: .primary
                        )
                        
                        RealtimeMetricView(
                            title: "현재 페이스",
                            value: paceString(from: realtimeData.currentPace),
                            icon: "speedometer",
                            color: .blue
                        )
                        
                        RealtimeMetricView(
                            title: "심박수",
                            value: "\(Int(realtimeData.heartRate)) bpm",
                            icon: "heart.fill",
                            color: .red
                        )
                        
                        RealtimeMetricView(
                            title: "케이던스",
                            value: "\(Int(realtimeData.cadence)) spm",
                            icon: "figure.walk",
                            color: getCadenceColor(realtimeData.cadence)
                        )
                    }
                    
                    // AI 분석 결과 (최근 데이터가 충분할 때)
                    if realtimeData.recentPaces.count >= 10 {
                        VStack(spacing: 8) {
                            HStack {
                                Text("AI 분석 결과")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Spacer()
                            }
                            
                            let paceCV = calculateCV(realtimeData.recentPaces)
                            HStack {
                                Text("페이스 안정성")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text(String(format: "%.1f%%", paceCV))
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(paceCV > 15 ? .red : paceCV > 10 ? .orange : .green)
                            }
                            
                            ProgressView(value: min(paceCV / 20, 1.0))
                                .progressViewStyle(LinearProgressViewStyle(tint: paceCV > 15 ? .red : paceCV > 10 ? .orange : .green))
                            
                            // 효율성 지수 (심박수와 페이스가 모두 있을 때)
                            if realtimeData.heartRate > 0 && realtimeData.currentPace > 0 {
                                let efficiency = (3600 / realtimeData.currentPace) / realtimeData.heartRate
                                HStack {
                                    Text("현재 효율성")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    Text(String(format: "%.3f", efficiency))
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.purple)
                                }
                            }
                        }
                        .padding(8)
                        .background(Color.purple.opacity(0.05))
                        .cornerRadius(6)
                    }
                }
            }
        }
        .padding()
        .background(Color.purple.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.purple.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func getCadenceColor(_ cadence: Double) -> Color {
        let targetRange: ClosedRange<Double> = 170...180
        if cadence > 0 && !targetRange.contains(cadence) {
            return .red
        }
        return .orange
    }
    
    private func calculateCV(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
        let standardDeviation = sqrt(variance)
        return (standardDeviation / mean) * 100
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

struct RealtimeMetricView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.caption)
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            HStack {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
                
                Spacer()
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(6)
    }
}

struct GoalProgressView: View {
    @EnvironmentObject var dataManager: RunningDataManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("10km 달리기 목표")
                .font(.headline)
                .fontWeight(.bold)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("최고 기록")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.2f km", dataManager.bestDistance))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("목표까지")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.2f km", max(0, 10.0 - dataManager.bestDistance)))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                }
            }
            
            // 진행률 바
            ProgressView(value: min(dataManager.bestDistance / 10.0, 1.0))
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .scaleEffect(x: 1, y: 2, anchor: .center)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
}

struct RecentWorkoutView: View {
    @EnvironmentObject var dataManager: RunningDataManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("최근 운동")
                .font(.headline)
                .fontWeight(.bold)
            
            if let recentWorkout = dataManager.workouts.first {
                VStack(spacing: 10) {
                    HStack {
                        Text(recentWorkout.date, style: .date)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(timeString(from: recentWorkout.duration))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        MetricView(title: "거리", value: String(format: "%.2f km", recentWorkout.distance), color: .green)
                        MetricView(title: "평균 페이스", value: paceString(from: recentWorkout.averagePace), color: .blue)
                        MetricView(title: "평균 심박수", value: "\(Int(recentWorkout.averageHeartRate)) bpm", color: .red)
                    }
                }
            } else {
                Text("아직 운동 기록이 없습니다.")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
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
