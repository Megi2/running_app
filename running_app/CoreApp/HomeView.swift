import SwiftUI

struct HomeView: View {
    @EnvironmentObject var dataManager: RunningDataManager
    @EnvironmentObject var assessmentManager: FitnessAssessmentManager
    @StateObject private var assessmentCoordinator = AssessmentCoordinator.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 평가 모드 진행 상황 (평가 진행 중일 때만 표시)
                if assessmentCoordinator.isAssessmentModeActive {
                    AssessmentProgressCard()
                        .environmentObject(assessmentCoordinator)
                }
                
                // 실시간 모니터링 (운동 중일 때만 표시)
                if dataManager.isReceivingRealtimeData {
                    RealtimeMonitoringCardView()
                        .environmentObject(dataManager)
                }
                
                // 목표 진행상황 (평가 완료된 경우)
                if assessmentManager.hasCompletedAssessment {
                    CurrentGoalProgressView()
                        .environmentObject(assessmentManager)
                        .environmentObject(dataManager)
                } else {
                    // 평가 미완료 시 기본 진행상황
                    BasicGoalProgressView()
                        .environmentObject(dataManager)
                }
                
                // 오늘의 운동 추천
                TodaysWorkoutRecommendationView()
                    .environmentObject(assessmentManager)
                    .environmentObject(dataManager)
                
                // 최근 운동
                RecentWorkoutView()
                    .environmentObject(dataManager)
                
                // 주간 통계
                WeeklyStatsView()
                    .environmentObject(dataManager)
                
                // 동기부여 메시지
                if assessmentManager.hasCompletedAssessment,
                   let tracker = assessmentManager.progressTracker {
                    MotivationalMessageView(tracker: tracker)
                }
            }
            .padding()
        }
        .navigationTitle("홈")
        .refreshable {
            // 당겨서 새로고침
            dataManager.refreshData()
        }
        .sheet(isPresented: $assessmentCoordinator.showingAssessmentResult) {
            if let result = assessmentCoordinator.assessmentResult {
                AssessmentCompletedView(result: result)
                    .environmentObject(assessmentManager)
            }
        }
    }
}

// MARK: - 평가 진행 상황 카드
struct AssessmentProgressCard: View {
    @EnvironmentObject var assessmentCoordinator: AssessmentCoordinator
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "heart.circle.fill")
                    .font(.title2)
                    .foregroundColor(.red)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Zone 2 평가 진행 중")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    if assessmentCoordinator.isWaitingForAssessmentStart {
                        Text("Apple Watch에서 달리기를 시작해주세요")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("평가 운동을 완료할 때까지 기다려주세요")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            // 진행 상태 표시
            HStack {
                if assessmentCoordinator.isWaitingForAssessmentStart {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Watch 연결 대기 중...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Image(systemName: "figure.run")
                        .foregroundColor(.green)
                    Text("평가 운동 진행 중")
                        .font(.caption)
                        .foregroundColor(.green)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                Button("취소") {
                    assessmentCoordinator.resetAssessmentState()
                }
                .font(.caption)
                .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - 평가 완료 화면
struct AssessmentCompletedView: View {
    let result: AssessmentResult
    @EnvironmentObject var assessmentManager: FitnessAssessmentManager
    @StateObject private var assessmentCoordinator = AssessmentCoordinator.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                
                // 축하 메시지
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.green)
                    
                    Text("평가 완료!")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("훌륭합니다! \(String(format: "%.2f", result.workout.distance))km를 완주하셨습니다.")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // 기본 통계
                VStack(spacing: 12) {
                    HStack {
                        StatView(title: "거리", value: "\(String(format: "%.2f", result.workout.distance))km", color: .green)
                        StatView(title: "시간", value: timeString(from: result.workout.duration), color: .blue)
                    }
                    
                    HStack {
                        StatView(title: "평균 페이스", value: paceString(from: result.workout.averagePace), color: .purple)
                        StatView(title: "평균 심박수", value: "\(Int(result.workout.averageHeartRate))bpm", color: .red)
                    }
                }
                
                Text("이제 개인 맞춤 목표가 설정되었습니다!\n목표 탭에서 확인해보세요.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Button("확인") {
                    assessmentCoordinator.resetAssessmentState()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .font(.headline)
                
                Spacer()
            }
            .padding()
            .navigationTitle("평가 결과")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") {
                        assessmentCoordinator.resetAssessmentState()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func paceString(from pace: Double) -> String {
        let minutes = Int(pace) / 60
        let seconds = Int(pace) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct StatView: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// 기존 HomeView의 다른 컴포넌트들은 그대로 유지...
// (CurrentGoalProgressView, BasicGoalProgressView, TodaysWorkoutRecommendationView 등)
