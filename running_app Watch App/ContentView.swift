//
//  ContentView.swift
//  running_app Watch App
//
//  수정된 워치 앱 메인 화면 - 타입 에러 해결
//

import SwiftUI
import CoreMotion

struct ContentView: View {
    @StateObject private var workoutManager = WorkoutManager()
    @StateObject private var assessmentManager = AssessmentModeManager.shared
    
    var body: some View {
        NavigationView {
            Group {
                if assessmentManager.showAssessmentScreen {
                    // 평가 모드 화면
                    AssessmentModeView()
                        .environmentObject(workoutManager)
                } else {
                    // 일반 달리기 화면
                    RunningView()
                        .environmentObject(workoutManager)
                }
            }
        }
        .onReceive(assessmentManager.$showAssessmentScreen) { showingAssessment in
            print("⌚ 평가 화면 표시 상태: \(showingAssessment)")
        }
    }
}

// MARK: - 평가 모드 화면
struct AssessmentModeView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @StateObject private var assessmentManager = AssessmentModeManager.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                // 평가 모드 헤더
                VStack(spacing: 8) {
                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.red)
                    
                    Text("Zone 2 평가")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text("최대한 오래 달려주세요")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom, 10)
                
                if !workoutManager.isWorkoutActive {
                    // 평가 시작 버튼
                    Button(action: {
                        startAssessmentWorkout()
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 35))
                            Text("평가 시작")
                                .font(.headline)
                        }
                        .foregroundColor(.red)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(10)
                    
                    // 평가 안내
                    VStack(alignment: .leading, spacing: 6) {
                        Text("평가 방법:")
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        Text("• 편안한 속도로 시작")
                        Text("• Zone 2 심박수 유지")
                        Text("• 최대한 오래 달리기")
                        Text("• 힘들면 속도 조절")
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                } else {
                    // 평가 운동 중 화면
                    AssessmentWorkoutDataView()
                        .environmentObject(workoutManager)
                    
                    // 평가 완료 버튼
                    Button(action: {
                        stopAssessmentWorkout()
                    }) {
                        VStack(spacing: 6) {
                            Image(systemName: "stop.circle.fill")
                                .font(.system(size: 30))
                            Text("평가 완료")
                                .font(.caption)
                        }
                        .foregroundColor(.red)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(10)
                }
            }
            .padding()
        }
        .navigationTitle("Zone 2 평가")
    }
    
    private func startAssessmentWorkout() {
        workoutManager.startWorkout(isAssessment: true)
    }
    
    private func stopAssessmentWorkout() {
        workoutManager.stopWorkout()
    }
}

// MARK: - 평가 운동 중 데이터 화면
struct AssessmentWorkoutDataView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    
    var body: some View {
        VStack(spacing: 8) {
            // 경고 메시지 (평가 모드에서는 간소화)
            if workoutManager.isWarningActive {
                VStack {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                        Text("주의")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    }
                    
                    Text("페이스를 조절하세요")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
                .padding(6)
                .background(Color.orange.opacity(0.2))
                .cornerRadius(6)
            }
            
            // 상단: 시간과 거리
            HStack {
                VStack {
                    Text(timeString(from: workoutManager.elapsedTime))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Text("시간")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                VStack {
                    Text(String(format: "%.2f", workoutManager.distance))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Text("km")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.bottom, 6)
            
            // 중단: 페이스와 심박수
            HStack {
                VStack {
                    Text(paceString(from: workoutManager.currentPace))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    Text("페이스")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                VStack {
                    Text("\(Int(workoutManager.heartRate))")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                    Text("bpm")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.bottom, 6)
            
            // 하단: 케이던스와 칼로리
            HStack {
                VStack {
                    Text("\(Int(workoutManager.cadence))")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                    Text("spm")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                VStack {
                    Text("\(Int(workoutManager.currentCalories))")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.purple)
                    Text("cal")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            
            // 평가 진행 상태
            VStack(spacing: 4) {
                Text("Zone 2 평가 진행 중")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.red)
                
                Text("편안한 속도로 최대한 오래 달려주세요")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 4)
        }
        .padding(8)
        .background(Color.red.opacity(0.05))
        .cornerRadius(8)
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

// MARK: - 일반 달리기 화면
struct RunningView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                if !workoutManager.isWorkoutActive {
                    // 시작 버튼
                    Button(action: {
                        startWorkout()
                    }) {
                        VStack {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 40))
                            Text("달리기 시작")
                                .font(.headline)
                        }
                        .foregroundColor(.green)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(10)
                } else {
                    // 운동 중 데이터 표시
                    WorkoutDataView()
                        .environmentObject(workoutManager)
                    
                    // 정지 버튼
                    Button(action: {
                        stopWorkout()
                    }) {
                        VStack {
                            Image(systemName: "stop.circle.fill")
                                .font(.system(size: 30))
                            Text("운동 완료")
                                .font(.caption)
                        }
                        .foregroundColor(.red)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(10)
                }
            }
            .padding()
        }
        .navigationTitle("10km 달리기")
    }
    
    private func startWorkout() {
        workoutManager.startWorkout()
    }
    
    private func stopWorkout() {
        workoutManager.stopWorkout()
    }
}

// MARK: - 일반 운동 데이터 화면
struct WorkoutDataView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    
    var body: some View {
        VStack(spacing: 8) {
            // 경고 메시지 (최우선 표시)
            if workoutManager.isWarningActive {
                VStack {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                            .font(.title3)
                        Text("경고")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    }
                    
                    Text(workoutManager.warningMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }
                .padding(8)
                .background(Color.red.opacity(0.2))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.red, lineWidth: 2)
                )
                .scaleEffect(workoutManager.isWarningActive ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: workoutManager.isWarningActive)
            }
            
            // 상단: 시간과 거리 (큰 글씨)
            HStack {
                VStack {
                    Text(timeString(from: workoutManager.elapsedTime))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Text("시간")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                VStack {
                    Text(String(format: "%.2f", workoutManager.distance))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Text("km")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.bottom, 8)
            
            // 중단: 페이스와 심박수
            HStack {
                VStack {
                    Text(paceString(from: workoutManager.currentPace))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    Text("페이스")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                VStack {
                    Text("\(Int(workoutManager.heartRate))")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                    Text("bpm")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.bottom, 8)
            
            // 하단: 케이던스와 칼로리
            HStack {
                VStack {
                    Text("\(Int(workoutManager.cadence))")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(getCadenceColor())
                    Text("spm")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                VStack {
                    Text("\(Int(workoutManager.currentCalories))")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                    Text("cal")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(10)
        .background(Color.black.opacity(0.1))
        .cornerRadius(10)
    }
    
    private func getCadenceColor() -> Color {
        let targetRange: ClosedRange<Double> = 170...180
        if workoutManager.cadence > 0 && !targetRange.contains(workoutManager.cadence) {
            return .red
        }
        return .orange
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
