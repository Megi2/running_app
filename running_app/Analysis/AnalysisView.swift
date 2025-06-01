import SwiftUI

struct AnalysisView: View {
    @EnvironmentObject var dataManager: RunningDataManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 장기 트렌드 분석
                    LongTermTrendView()
                        .environmentObject(dataManager)
                    
                    // 과훈련 모니터링
                    OvertrainingMonitorView()
                        .environmentObject(dataManager)
                    
                    // 개인 최적 케이던스 분석
                    CadenceOptimizationView()
                        .environmentObject(dataManager)
                }
                .padding()
            }
            .navigationTitle("분석")
        }
    }
}

struct LongTermTrendView: View {
    @EnvironmentObject var dataManager: RunningDataManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("장기 트렌드 분석")
                .font(.headline)
                .fontWeight(.bold)
            
            let trendData = dataManager.calculateLongTermTrends()
            
            VStack(spacing: 12) {
                TrendRow(title: "효율성 개선율",
                        value: String(format: "%.1f%%", trendData.efficiencyImprovement),
                        trend: trendData.efficiencyImprovement > 0 ? .improving : .declining)
                
                TrendRow(title: "평균 거리 증가",
                        value: String(format: "%.2f km", trendData.distanceImprovement),
                        trend: trendData.distanceImprovement > 0 ? .improving : .stable)
                
                TrendRow(title: "회복 패턴",
                        value: trendData.recoveryPattern,
                        trend: .stable)
            }
            
            if trendData.efficiencyImprovement > 10 {
                Text("💡 효율성이 크게 향상되었습니다. 목표 거리를 늘려볼 시점입니다!")
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding(.top, 5)
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }
}

struct TrendRow: View {
    let title: String
    let value: String
    let trend: TrendDirection
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            HStack(spacing: 5) {
                Image(systemName: trend.iconName)
                    .foregroundColor(trend.color)
                    .font(.caption)
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(trend.color)
            }
        }
    }
}

struct OvertrainingMonitorView: View {
    @EnvironmentObject var dataManager: RunningDataManager
    
    var body: some View {
        let overtrainingAssessment = dataManager.assessOvertrainingRisk()
        
        VStack(alignment: .leading, spacing: 15) {
            Text("과훈련 모니터링")
                .font(.headline)
                .fontWeight(.bold)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("위험도")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(overtrainingAssessment.level.rawValue)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(overtrainingAssessment.level.color)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("권장 휴식")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(overtrainingAssessment.recommendedRestDays)일")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
            }
            
            if !overtrainingAssessment.recommendations.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    Text("권장사항")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ForEach(overtrainingAssessment.recommendations, id: \.self) { recommendation in
                        Text("• \(recommendation)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(overtrainingAssessment.level.color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct CadenceOptimizationView: View {
    @EnvironmentObject var dataManager: RunningDataManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("개인 최적 케이던스")
                .font(.headline)
                .fontWeight(.bold)
            
            let cadenceData = dataManager.calculateOptimalCadence()
            
            VStack(spacing: 10) {
                HStack {
                    Text("현재 평균 케이던스")
                        .font(.subheadline)
                    Spacer()
                    Text("\(Int(cadenceData.currentAverage)) spm")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("최적 케이던스 범위")
                        .font(.subheadline)
                    Spacer()
                    Text("\(Int(cadenceData.optimalRange.0))-\(Int(cadenceData.optimalRange.1)) spm")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
                
                HStack {
                    Text("최적 범위 유지율")
                        .font(.subheadline)
                    Spacer()
                    Text(String(format: "%.1f%%", cadenceData.inRangePercentage))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(cadenceData.inRangePercentage > 85 ? .green : .orange)
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
}
