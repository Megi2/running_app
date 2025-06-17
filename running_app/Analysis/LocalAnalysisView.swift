//
//  LocalAnalysisView.swift
//  running_app
//
//  수정된 로컬 분석 뷰 - 바인딩 에러 해결
//

import SwiftUI

struct LocalAnalysisView: View {
    let workout: WorkoutSummary
    @EnvironmentObject var dataManager: RunningDataManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("분석 결과")
                .font(.headline)
                .fontWeight(.bold)
            
            let analysisResult = getAnalysisResult()
            
            VStack(spacing: 12) {
                // 페이스 안정성
                AnalysisCard(
                    title: "페이스 안정성",
                    icon: "speedometer",
                    value: String(format: "%.1f%%", analysisResult.paceStability.cv),
                    status: getStabilityStatus(analysisResult.paceStability.level),
                    description: analysisResult.paceStability.warning,
                    color: getStabilityColor(analysisResult.paceStability.level)
                )
                
                // 효율성
                AnalysisCard(
                    title: "심박수 효율성",
                    icon: "heart.circle",
                    value: String(format: "%.3f", analysisResult.efficiency.averageEfficiency),
                    status: getTrendStatus(analysisResult.efficiency.trend),
                    description: analysisResult.efficiency.recommendation,
                    color: getTrendColor(analysisResult.efficiency.trend)
                )
                
                // 케이던스 최적화
                AnalysisCard(
                    title: "케이던스 최적화",
                    icon: "figure.walk",
                    value: "\(Int(analysisResult.cadenceOptimization.optimalRange.0))-\(Int(analysisResult.cadenceOptimization.optimalRange.1)) spm",
                    status: "권장 범위",
                    description: analysisResult.cadenceOptimization.recommendation,
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color.purple.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Private 함수들
    private func getAnalysisResult() -> WorkoutAnalysisResult {
        let analysisEngine = LocalAnalysisEngine()
        
        let paces = workout.dataPoints.compactMap { $0.pace > 0 ? $0.pace : nil }
        let heartRates = workout.dataPoints.compactMap { $0.heartRate > 0 ? $0.heartRate : nil }
        let cadences = workout.dataPoints.compactMap { $0.cadence > 0 ? $0.cadence : nil }
        
        let paceStability = analysisEngine.analyzePaceStability(paces: paces)
        let efficiency = analysisEngine.analyzeEfficiency(paces: paces, heartRates: heartRates)
        let cadenceOptimization = analysisEngine.optimizeCadence(
            paces: paces,
            cadences: cadences,
            heartRates: heartRates
        )
        
        return WorkoutAnalysisResult(
            paceStability: paceStability,
            efficiency: efficiency,
            cadenceOptimization: cadenceOptimization
        )
    }
    
    private func getStabilityStatus(_ level: StabilityLevel) -> String {
        switch level {
        case .stable: return "안정적"
        case .moderate: return "보통"
        case .unstable: return "불안정"
        case .insufficient: return "데이터 부족"
        }
    }
    
    private func getStabilityColor(_ level: StabilityLevel) -> Color {
        switch level {
        case .stable: return .green
        case .moderate: return .orange
        case .unstable: return .red
        case .insufficient: return .gray
        }
    }
    
    private func getTrendStatus(_ trend: Double) -> String {
        if trend > 0.001 {
            return "개선 중"
        } else if trend < -0.001 {
            return "하락 중"
        } else {
            return "유지"
        }
    }
    
    private func getTrendColor(_ trend: Double) -> Color {
        if trend > 0.001 {
            return .green
        } else if trend < -0.001 {
            return .red
        } else {
            return .blue
        }
    }
}

struct AnalysisCard: View {
    let title: String
    let icon: String
    let value: String
    let status: String
    let description: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack {
                        Text(value)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(color)
                        
                        Spacer()
                        
                        Text(status)
                            .font(.caption)
                            .foregroundColor(color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(color.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
            }
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

struct EfficiencyAnalysisView: View {
    let dataPoints: [RunningDataPoint]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("효율성 분석")
                .font(.headline)
                .fontWeight(.bold)
            
            let efficiencyData = calculateEfficiencyMetrics()
            
            VStack(spacing: 10) {
                HStack {
                    Text("페이스 안정성 (CV)")
                        .font(.subheadline)
                    Spacer()
                    Text(String(format: "%.1f%%", efficiencyData.paceCV))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(efficiencyData.paceCV > 15 ? .red : .green)
                }
                
                HStack {
                    Text("평균 효율성 지수")
                        .font(.subheadline)
                    Spacer()
                    Text(String(format: "%.3f", efficiencyData.averageEfficiency))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.purple)
                }
                
                HStack {
                    Text("최적 케이던스 구간")
                        .font(.subheadline)
                    Spacer()
                    Text("\(Int(efficiencyData.optimalCadenceRange.0))-\(Int(efficiencyData.optimalCadenceRange.1)) spm")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                }
                
                // 권장사항
                VStack(alignment: .leading, spacing: 5) {
                    Text("권장사항")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ForEach(generateRecommendations(efficiencyData), id: \.self) { recommendation in
                        Text("• \(recommendation)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color.purple.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func calculateEfficiencyMetrics() -> EfficiencyMetrics {
        let validPaces = dataPoints.compactMap { $0.pace > 0 ? $0.pace : nil }
        let paceCV = calculateCV(values: validPaces)
        
        let efficiencies = dataPoints.compactMap { point -> Double? in
            guard point.heartRate > 0 && point.pace > 0 else { return nil }
            let speed = 3600 / point.pace // km/h
            return speed / point.heartRate
        }
        
        let averageEfficiency = efficiencies.isEmpty ? 0 : efficiencies.reduce(0, +) / Double(efficiencies.count)
        
        let validCadences = dataPoints.compactMap { $0.cadence > 0 ? $0.cadence : nil }
        let cadenceRange = (validCadences.min() ?? 170, validCadences.max() ?? 180)
        
        return EfficiencyMetrics(
            paceCV: paceCV,
            averageEfficiency: averageEfficiency,
            optimalCadenceRange: cadenceRange
        )
    }
    
    private func calculateCV(values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
        let standardDeviation = sqrt(variance)
        return (standardDeviation / mean) * 100
    }
    
    private func generateRecommendations(_ metrics: EfficiencyMetrics) -> [String] {
        var recommendations: [String] = []
        
        if metrics.paceCV > 15 {
            recommendations.append("페이스 변동이 큽니다. 일정한 속도 유지를 연습해보세요.")
        } else if metrics.paceCV < 5 {
            recommendations.append("페이스가 매우 안정적입니다. 좋은 페이싱입니다!")
        }
        
        if metrics.averageEfficiency < 0.05 {
            recommendations.append("심박수 대비 속도 효율성을 높이기 위해 유산소 운동을 늘려보세요.")
        } else if metrics.averageEfficiency > 0.08 {
            recommendations.append("효율성이 매우 좋습니다. 거리를 늘려볼 수 있습니다.")
        }
        
        recommendations.append("케이던스를 \(Int(metrics.optimalCadenceRange.0))-\(Int(metrics.optimalCadenceRange.1)) 범위로 유지해보세요.")
        
        return recommendations
    }
}
