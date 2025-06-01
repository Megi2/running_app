import Foundation

// iPhone에서 직접 수행하는 분석 엔진
class LocalAnalysisEngine: ObservableObject {
    
    // MARK: - 페이스 안정성 분석
    func analyzePaceStability(paces: [Double]) -> PaceStabilityResult {
        guard paces.count >= 10 else {
            return PaceStabilityResult(cv: 0, level: .insufficient, warning: "데이터가 부족합니다")
        }
        
        let validPaces = paces.filter { $0 > 0 }
        guard validPaces.count >= 5 else {
            return PaceStabilityResult(cv: 0, level: .insufficient, warning: "유효한 데이터가 부족합니다")
        }
        
        let cv = calculateCoefficientOfVariation(validPaces)
        
        let level: StabilityLevel
        let warning: String
        
        if cv > 15 {
            level = .unstable
            warning = "페이스 변동이 큽니다. 일정한 속도 유지를 연습해보세요."
        } else if cv > 10 {
            level = .moderate
            warning = "페이스가 약간 불안정합니다."
        } else {
            level = .stable
            warning = "페이스가 안정적입니다!"
        }
        
        return PaceStabilityResult(cv: cv, level: level, warning: warning)
    }
    
    // MARK: - 효율성 분석
    func analyzeEfficiency(paces: [Double], heartRates: [Double]) -> EfficiencyResult {
        guard paces.count == heartRates.count && paces.count > 0 else {
            return EfficiencyResult(averageEfficiency: 0, trend: 0, recommendation: "데이터가 부족합니다")
        }
        
        let efficiencies = zip(paces, heartRates).compactMap { pace, hr -> Double? in
            guard pace > 0 && hr > 0 else { return nil }
            let speedKmh = 3600 / pace
            return speedKmh / hr
        }
        
        guard efficiencies.count >= 5 else {
            return EfficiencyResult(averageEfficiency: 0, trend: 0, recommendation: "유효한 데이터가 부족합니다")
        }
        
        let averageEfficiency = efficiencies.reduce(0, +) / Double(efficiencies.count)
        let trend = calculateTrend(efficiencies)
        
        let recommendation: String
        if averageEfficiency < 0.05 {
            recommendation = "심박수 대비 속도 효율성을 높이기 위해 유산소 운동을 늘려보세요."
        } else if averageEfficiency > 0.08 {
            recommendation = "효율성이 매우 좋습니다. 거리를 늘려볼 수 있습니다."
        } else {
            recommendation = "현재 효율성이 양호합니다. 꾸준히 유지하세요."
        }
        
        return EfficiencyResult(
            averageEfficiency: averageEfficiency,
            trend: trend,
            recommendation: recommendation
        )
    }
    
    // MARK: - 케이던스 최적화
    func optimizeCadence(paces: [Double], cadences: [Double], heartRates: [Double]) -> CadenceOptimizationResult {
        guard paces.count == cadences.count && paces.count == heartRates.count else {
            return CadenceOptimizationResult(
                optimalRange: (170, 180),
                currentAverage: 175,
                recommendation: "데이터가 부족합니다"
            )
        }
        
        // 효율성이 높은 케이던스 구간 찾기
        let data = zip3(paces, cadences, heartRates).compactMap { pace, cadence, hr -> (cadence: Double, efficiency: Double)? in
            guard pace > 0 && cadence > 0 && hr > 0 else { return nil }
            let speedKmh = 3600 / pace
            let efficiency = speedKmh / hr
            return (cadence, efficiency)
        }
        
        guard data.count >= 10 else {
            let validCadences = cadences.filter { $0 > 0 }
            let currentAverage = validCadences.isEmpty ? 175 : validCadences.reduce(0, +) / Double(validCadences.count)
            return CadenceOptimizationResult(
                optimalRange: (170, 180),
                currentAverage: currentAverage,
                recommendation: "더 많은 데이터가 필요합니다"
            )
        }
        
        // 케이던스를 5 단위로 그룹화
        let groupedData = Dictionary(grouping: data) { datum in
            Int(datum.cadence / 5) * 5
        }
        
        let avgEfficiencyByCadence = groupedData.mapValues { group in
            let efficiencies = group.map { $0.efficiency }
            return efficiencies.reduce(0, +) / Double(efficiencies.count)
        }
        
        let bestCadence = avgEfficiencyByCadence.max { $0.value < $1.value }?.key ?? 175
        let optimalRange = (Double(bestCadence - 5), Double(bestCadence + 5))
        let currentAverage = cadences.filter { $0 > 0 }.reduce(0, +) / Double(cadences.filter { $0 > 0 }.count)
        
        let recommendation = "최적 케이던스는 \(Int(optimalRange.0))-\(Int(optimalRange.1)) spm입니다. 현재 평균은 \(Int(currentAverage)) spm입니다."
        
        return CadenceOptimizationResult(
            optimalRange: optimalRange,
            currentAverage: currentAverage,
            recommendation: recommendation
        )
    }
    
    // MARK: - 과훈련 위험도 평가
    func assessOvertrainingRisk(workouts: [WorkoutSummary]) -> OvertrainingRiskResult {
        guard workouts.count >= 3 else {
            return OvertrainingRiskResult(
                level: .low,
                riskScore: 0,
                recommendations: ["더 많은 운동 데이터가 필요합니다"]
            )
        }
        
        // 최근 5회 운동의 효율성 변화 분석
        let recentWorkouts = Array(workouts.prefix(5))
        let efficiencies = recentWorkouts.map { workout in
            let speed = 3600 / workout.averagePace
            return speed / workout.averageHeartRate
        }
        
        // 효율성 감소 추세 분석
        var decliningCount = 0
        for i in 1..<efficiencies.count {
            if efficiencies[i] < efficiencies[i-1] {
                decliningCount += 1
            }
        }
        
        let riskScore = Double(decliningCount) / Double(efficiencies.count - 1)
        
        let level: OvertrainingLevel
        var recommendations: [String] = []
        
        if riskScore >= 0.7 { // 70% 이상 감소
            level = .high
            recommendations = [
                "3일간 완전 휴식을 권장합니다",
                "가벼운 스트레칭만 진행하세요",
                "충분한 수면과 영양 섭취에 집중하세요"
            ]
        } else if riskScore >= 0.4 { // 40% 이상 감소
            level = .medium
            recommendations = [
                "2일간 휴식 또는 저강도 운동을 권장합니다",
                "운동 강도를 70%로 낮춰보세요"
            ]
        } else {
            level = .low
            recommendations = ["현재 컨디션이 양호합니다"]
        }
        
        return OvertrainingRiskResult(
            level: level,
            riskScore: riskScore,
            recommendations: recommendations
        )
    }
    
    // MARK: - 헬퍼 함수들
    private func calculateCoefficientOfVariation(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
        let standardDeviation = sqrt(variance)
        return (standardDeviation / mean) * 100
    }
    
    private func calculateTrend(_ values: [Double]) -> Double {
        guard values.count >= 2 else { return 0 }
        
        let n = Double(values.count)
        let sumX = (0..<values.count).reduce(0, +)
        let sumY = values.reduce(0, +)
        let sumXY = zip(0..<values.count, values).reduce(0) { sum, pair in
            sum + Double(pair.0) * pair.1
        }
        let sumX2 = (0..<values.count).reduce(0) { sum, x in
            sum + x * x
        }
        
        // 선형 회귀의 기울기 계산
        let slope = (n * sumXY - Double(sumX) * sumY) / (n * Double(sumX2) - Double(sumX) * Double(sumX))
        return slope
    }
}
