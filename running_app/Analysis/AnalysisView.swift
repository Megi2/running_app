//
//  AnalysisView.swift
//  running_app
//
//  수정된 분석 화면 - 환경 객체 에러 해결
//

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
            
            let trendData = calculateTrendData()
            
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
    
    private func calculateTrendData() -> LongTermTrends {
        guard dataManager.workouts.count >= 3 else {
            return LongTermTrends(
                efficiencyImprovement: 0,
                distanceImprovement: 0,
                recoveryPattern: "데이터 부족"
            )
        }
        
        // 최근 5회와 그 이전 5회 비교
        let recentWorkouts = Array(dataManager.workouts.prefix(5))
        let previousWorkouts = Array(dataManager.workouts.dropFirst(5).prefix(5))
        
        // 효율성 개선율 계산
        let recentEfficiency = calculateAverageEfficiency(recentWorkouts)
        let previousEfficiency = calculateAverageEfficiency(previousWorkouts)
        let efficiencyImprovement = previousEfficiency > 0 ?
            ((recentEfficiency - previousEfficiency) / previousEfficiency) * 100 : 0
        
        // 거리 개선 계산
        let recentDistance = recentWorkouts.map { $0.distance }.reduce(0, +) / Double(recentWorkouts.count)
        let previousDistance = previousWorkouts.isEmpty ? 0 :
            previousWorkouts.map { $0.distance }.reduce(0, +) / Double(previousWorkouts.count)
        let distanceImprovement = recentDistance - previousDistance
        
        // 회복 패턴 분석
        let recoveryPattern = analyzeRecoveryPattern()
        
        return LongTermTrends(
            efficiencyImprovement: efficiencyImprovement,
            distanceImprovement: distanceImprovement,
            recoveryPattern: recoveryPattern
        )
    }
    
    private func calculateAverageEfficiency(_ workouts: [WorkoutSummary]) -> Double {
        guard !workouts.isEmpty else { return 0 }
        
        let efficiencies = workouts.compactMap { workout -> Double? in
            guard workout.averageHeartRate > 0 && workout.averagePace > 0 else { return nil }
            let speed = 3600 / workout.averagePace
            return speed / workout.averageHeartRate
        }
        
        return efficiencies.isEmpty ? 0 : efficiencies.reduce(0, +) / Double(efficiencies.count)
    }
    
    private func analyzeRecoveryPattern() -> String {
        guard dataManager.workouts.count >= 5 else { return "데이터 부족" }
        
        let recentWorkouts = Array(dataManager.workouts.prefix(5))
        let intervals = zip(recentWorkouts.dropFirst(), recentWorkouts).map { current, previous in
            current.date.timeIntervalSince(previous.date) / (24 * 3600) // 일 단위
        }
        
        let averageInterval = intervals.reduce(0, +) / Double(intervals.count)
        
        switch averageInterval {
        case 0..<1: return "매일 운동"
        case 1..<2: return "하루 걸러 운동"
        case 2..<3: return "이틀 간격"
        case 3..<5: return "3-4일 간격"
        default: return "불규칙한 패턴"
        }
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
        let overtrainingAssessment = assessOvertrainingRisk()
        
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
    
    private func assessOvertrainingRisk() -> OvertrainingAssessment {
        let analysisEngine = LocalAnalysisEngine()
        let result = analysisEngine.assessOvertrainingRisk(workouts: dataManager.workouts)
        
        let recommendedRestDays: Int
        switch result.level {
        case .high: recommendedRestDays = 3
        case .medium: recommendedRestDays = 2
        case .low: recommendedRestDays = 1
        }
        
        return OvertrainingAssessment(
            level: result.level,
            recommendedRestDays: recommendedRestDays,
            recommendations: result.recommendations
        )
    }
}

struct CadenceOptimizationView: View {
    @EnvironmentObject var dataManager: RunningDataManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("개인 최적 케이던스")
                .font(.headline)
                .fontWeight(.bold)
            
            let cadenceData = calculateOptimalCadence()
            
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
    
    private func calculateOptimalCadence() -> CadenceData {
        guard !dataManager.workouts.isEmpty else {
            return CadenceData(
                currentAverage: 0,
                optimalRange: (170, 180),
                inRangePercentage: 0
            )
        }
        
        let analysisEngine = LocalAnalysisEngine()
        
        // 모든 워크아웃의 데이터를 수집
        let allPaces = dataManager.workouts.flatMap { workout in
            workout.dataPoints.compactMap { $0.pace > 0 ? $0.pace : nil }
        }
        let allCadences = dataManager.workouts.flatMap { workout in
            workout.dataPoints.compactMap { $0.cadence > 0 ? $0.cadence : nil }
        }
        let allHeartRates = dataManager.workouts.flatMap { workout in
            workout.dataPoints.compactMap { $0.heartRate > 0 ? $0.heartRate : nil }
        }
        
        let result = analysisEngine.optimizeCadence(
            paces: allPaces,
            cadences: allCadences,
            heartRates: allHeartRates
        )
        
        // 최적 범위 내 비율 계산
        let inRangeCount = allCadences.filter {
            $0 >= result.optimalRange.0 && $0 <= result.optimalRange.1
        }.count
        let inRangePercentage = allCadences.isEmpty ? 0 :
            Double(inRangeCount) / Double(allCadences.count) * 100
        
        return CadenceData(
            currentAverage: result.currentAverage,
            optimalRange: result.optimalRange,
            inRangePercentage: inRangePercentage
        )
    }
}
