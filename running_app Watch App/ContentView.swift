import SwiftUI
import CoreMotion

struct ContentView: View {
    @StateObject private var workoutManager = WorkoutManager()
    
    var body: some View {
        TabView {
            // 메인 달리기 화면
            RunningView()
                .environmentObject(workoutManager)
                .tabItem {
                    Image(systemName: "figure.run")
                    Text("달리기")
                }
            
            // 설정 화면
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("설정")
                }
        }
    }
}

struct RunningView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @State private var isRunning = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                if !isRunning {
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
        .onReceive(workoutManager.$isActive) { active in
            isRunning = active
        }
    }
    
    private func startWorkout() {
        workoutManager.startWorkout()
    }
    
    private func stopWorkout() {
        workoutManager.endWorkout()
    }
}

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
            
            // 시간
            HStack {
                Text("시간")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text(timeString(from: workoutManager.elapsedTime))
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            
            // 페이스
            HStack {
                Text("페이스")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text(paceString(from: workoutManager.currentPace))
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }
            
            // 심박수
            HStack {
                Text("심박수")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(Int(workoutManager.heartRate)) bpm")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
            }
            
            // 거리
            HStack {
                Text("거리")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text(String(format: "%.2f km", workoutManager.distance))
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }
            
            // 케이던스 (경고 상태일 때 색상 변경)
            HStack {
                Text("케이던스")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(Int(workoutManager.cadence)) spm")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(getCadenceColor())
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

struct SettingsView: View {
    var body: some View {
        List {
            Section("목표 설정") {
                HStack {
                    Text("목표 거리")
                    Spacer()
                    Text("10km")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("목표 페이스")
                    Spacer()
                    Text("6:00/km")
                        .foregroundColor(.secondary)
                }
            }
            
            Section("알림") {
                Toggle("페이스 경고", isOn: .constant(true))
                Toggle("심박수 알림", isOn: .constant(true))
            }
            
            Section("센서") {
                HStack {
                    Text("CMPedometer")
                    Spacer()
                    Text(CMPedometer.isStepCountingAvailable() ? "사용 가능" : "사용 불가")
                        .foregroundColor(CMPedometer.isStepCountingAvailable() ? .green : .red)
                        .font(.caption)
                }
                
                HStack {
                    Text("가속도계")
                    Spacer()
                    Text("활성화됨")
                        .foregroundColor(.green)
                        .font(.caption)
                }
            }
        }
        .navigationTitle("설정")
    }
}
