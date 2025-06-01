import Foundation
import CoreMotion

extension WorkoutManager {
    
    func startCadenceTracking() {
        // 1. CMPedometer로 걸음 수 추적
        if CMPedometer.isStepCountingAvailable() {
            pedometer.startUpdates(from: Date()) { [weak self] pedometerData, error in
                guard let self = self, let data = pedometerData else { return }
                
                DispatchQueue.main.async {
                    let newStepCount = data.numberOfSteps.intValue
                    self.updateStepCountFromPedometer(newStepCount)
                }
            }
        }
        
        // 2. 가속도계로 실시간 스텝 감지 (보조)
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.1 // 10Hz
            motionManager.startAccelerometerUpdates(to: .main) { [weak self] accelerometerData, error in
                guard let self = self, let data = accelerometerData else { return }
                self.detectStepFromAccelerometer(data)
            }
        }
    }
    
    func stopCadenceTracking() {
        pedometer.stopUpdates()
        motionManager.stopAccelerometerUpdates()
        stepTimestamps.removeAll()
    }
    
    private func updateStepCountFromPedometer(_ newStepCount: Int) {
        let currentTime = Date()
        let timeSinceLastUpdate = currentTime.timeIntervalSince(lastStepCountUpdate)
        
        // 2초마다 케이던스 계산 (더 빠른 업데이트)
        if timeSinceLastUpdate >= 2.0 {
            let stepDiff = newStepCount - stepCount
            if stepDiff > 0 && timeSinceLastUpdate > 0 {
                let stepsPerMinute = Double(stepDiff) / (timeSinceLastUpdate / 60)
                
                // 합리적인 달리기 케이던스 범위
                if stepsPerMinute >= 140 && stepsPerMinute <= 220 {
                    // 기존 케이던스와 부드럽게 평균화
                    if self.cadence > 0 && self.cadence >= 140 && self.cadence <= 220 {
                        self.cadence = (self.cadence * 0.7) + (stepsPerMinute * 0.3)
                    } else {
                        self.cadence = stepsPerMinute
                    }
                    
                    print("🦶 CMPedometer 케이던스: \(stepDiff)걸음/\(String(format: "%.1f", timeSinceLastUpdate))초 = \(String(format: "%.0f", stepsPerMinute)) spm → 평균: \(String(format: "%.0f", self.cadence)) spm")
                } else {
                    print("⚠️ 비정상적인 케이던스: \(String(format: "%.0f", stepsPerMinute)) spm (\(stepDiff)걸음/\(String(format: "%.1f", timeSinceLastUpdate))초)")
                }
            }
            
            stepCount = newStepCount
            lastStepCountUpdate = currentTime
        }
    }
    
    private func detectStepFromAccelerometer(_ data: CMAccelerometerData) {
        // 가속도 벡터의 크기 계산
        let acceleration = data.acceleration
        let magnitude = sqrt(acceleration.x * acceleration.x +
                           acceleration.y * acceleration.y +
                           acceleration.z * acceleration.z)
        
        // 스텝 감지 (threshold crossing 방식)
        if magnitude > stepDetectionThreshold && lastAccelerationMagnitude <= stepDetectionThreshold {
            let currentTime = Date()
            stepTimestamps.append(currentTime)
            
            // 최근 30초간의 스텝만 유지
            stepTimestamps = stepTimestamps.filter {
                currentTime.timeIntervalSince($0) <= 30
            }
            
            // 최소 10개 스텝이 있을 때 케이던스 계산
            if stepTimestamps.count >= 10 {
                let timeSpan = currentTime.timeIntervalSince(stepTimestamps.first!)
                if timeSpan > 0 {
                    let stepsPerMinute = Double(stepTimestamps.count - 1) / (timeSpan / 60)
                    
                    // 합리적인 범위에서만 업데이트
                    if stepsPerMinute >= 140 && stepsPerMinute <= 220 {
                        // CMPedometer 데이터가 없을 때만 사용
                        if !CMPedometer.isStepCountingAvailable() {
                            DispatchQueue.main.async {
                                self.cadence = stepsPerMinute
                                print("📱 가속도계 케이던스: \(String(format: "%.0f", stepsPerMinute)) spm")
                            }
                        }
                    }
                }
            }
        }
        
        lastAccelerationMagnitude = magnitude
    }
}
