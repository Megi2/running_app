//
//  WorkoutDetailView.swift
//  running_app
//
//  수정된 워크아웃 상세 뷰 - 환경 객체 전달 수정
//

import SwiftUI

struct WorkoutDetailView: View {
    let workout: WorkoutSummary
    @EnvironmentObject var dataManager: RunningDataManager
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 기본 정보
                WorkoutSummaryCard(workout: workout)
                
                // 로컬 분석 결과 - 환경 객체 올바르게 전달
                LocalAnalysisView(workout: workout)
                    .environmentObject(dataManager)
                
                // 페이스 차트
                PaceChartView(dataPoints: workout.dataPoints)
                
                // 심박수 차트
                HeartRateChartView(dataPoints: workout.dataPoints)
                
                // 효율성 분석 (기존)
                EfficiencyAnalysisView(dataPoints: workout.dataPoints)
            }
            .padding()
        }
        .navigationTitle("운동 상세")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct WorkoutSummaryCard: View {
    let workout: WorkoutSummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("운동 요약")
                .font(.headline)
                .fontWeight(.bold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                SummaryMetric(title: "총 시간", value: timeString(from: workout.duration), icon: "clock")
                SummaryMetric(title: "총 거리", value: String(format: "%.2f km", workout.distance), icon: "location")
                SummaryMetric(title: "평균 페이스", value: paceString(from: workout.averagePace), icon: "speedometer")
                SummaryMetric(title: "평균 심박수", value: "\(Int(workout.averageHeartRate)) bpm", icon: "heart")
                SummaryMetric(title: "평균 케이던스", value: "\(Int(workout.averageCadence)) spm", icon: "figure.walk")
                SummaryMetric(title: "효율성 지수", value: String(format: "%.3f", calculateEfficiency()), icon: "chart.line.uptrend.xyaxis")
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func calculateEfficiency() -> Double {
        if workout.averageHeartRate > 0 && workout.averagePace > 0 {
            let speed = 3600 / workout.averagePace // km/h
            return speed / workout.averageHeartRate
        }
        return 0
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

struct SummaryMetric: View {
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
