import Foundation

// MARK: - 데이터 처리 유틸리티
extension WorkoutManager {
    
    // MARK: - 데이터 업데이트
    func updateRunningData() {
        let dataPoint = RunningDataPoint(
            timestamp: Date().timeIntervalSince1970,
            pace: currentPace,
            heartRate: heartRate,
            cadence: cadence,
            distance: distance
        )
        
        runningData.append(dataPoint)
        updateRecentData()
        checkForWarnings()
    }
    
    // MARK: - 최근 데이터 업데이트
    private func updateRecentData() {
        // 최근 페이스 데이터
        if currentPace > 0 {
            recentPaces.append(currentPace)
            if recentPaces.count > maxRecentDataCount {
                recentPaces.removeFirst()
            }
        }
        
        // 최근 케이던스 데이터
        if cadence > 0 {
            recentCadences.append(cadence)
            if recentCadences.count > maxRecentDataCount {
                recentCadences.removeFirst()
            }
        }
        
        // 최근 심박수 데이터
        if heartRate > 0 {
            recentHeartRates.append(heartRate)
            if recentHeartRates.count > maxRecentDataCount {
                recentHeartRates.removeFirst()
            }
        }
    }
    
    // MARK: - 경고 시스템
    private func checkForWarnings() {
        // 심박수 경고
        if heartRate > 180 {
            showWarning("심박수가 너무 높습니다 (180+ bpm)")
            return
        }
        
        // 페이스 경고 (너무 빠름)
        if currentPace > 0 && currentPace < 180 { // 3분/km 미만
            showWarning("너무 빠른 페이스입니다")
            return
        }
        
        // 페이스 경고 (너무 느림)
        if currentPace > 600 { // 10분/km 초과
            showWarning("페이스가 너무 느립니다")
            return
        }
        
        // 경고 해제
        clearWarning()
    }
    
    private func showWarning(_ message: String) {
        DispatchQueue.main.async {
            self.isWarningActive = true
            self.warningMessage = message
        }
    }
    
    private func clearWarning() {
        DispatchQueue.main.async {
            if self.isWarningActive {
                self.isWarningActive = false
                self.warningMessage = ""
            }
        }
    }
    
    // MARK: - 유틸리티 메서드
    func calculateAverage(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }
    
    func resetData() {
        elapsedTime = 0
        distance = 0
        currentPace = 0
        heartRate = 0
        cadence = 0
        currentCalories = 0
        runningData.removeAll()
        recentPaces.removeAll()
        recentCadences.removeAll()
        recentHeartRates.removeAll()
        
        // 케이던스 관련 데이터 초기화
        stepCount = 0
        stepTimestamps.removeAll()
        lastStepTime = Date()
        
        clearWarning()
    }
    
    // MARK: - 수동 데이터 업데이트 (테스트용)
    func updateTestData(elapsedTime: TimeInterval, distance: Double, pace: Double, heartRate: Double, cadence: Double) {
        DispatchQueue.main.async {
            self.elapsedTime = elapsedTime
            self.distance = distance
            self.currentPace = pace
            self.heartRate = heartRate
            self.cadence = cadence
            
            self.updateRunningData()
        }
    }
}