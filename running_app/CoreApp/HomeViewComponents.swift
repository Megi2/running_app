//
//  HomeViewComponents.swift
//  running_app
//
//  Zone2 타입으로 완전히 수정된 HomeView 컴포넌트들
//

import SwiftUI
import Foundation

// MARK: - 현재 목표 진행상황 (평가 완료된 경우)
struct CurrentGoalProgressView: View {
    @EnvironmentObject var assessmentManager: FitnessAssessmentManager
    @EnvironmentObject var dataManager: RunningDataManager
    
    var body: some View {
        if let goals = assessmentManager.recommendedGoals,  // Zone2Goals 타입
           let tracker = assessmentManager.progressTracker { // Zone2ProgressTracker 타입
            
            let nextGoal = getNextGoal(goals: goals, tracker: tracker)
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("현재 목표")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    NavigationLink("전체보기") {
                        GoalsDashboardView()
                            .environmentObject(dataManager)
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                
                // 다음 목표 (미달성된 가장 가까운 목표)
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(nextGoal.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text("\(String(format: "%.1f", nextGoal.targetDistance))km 목표")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(nextGoal.color)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("현재 최고")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("\(String(format: "%.1f", tracker.bestDistance))km")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                    }
                    
                    let progress = min(tracker.bestDistance / nextGoal.targetDistance, 1.0)
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: nextGoal.color))
                        .scaleEffect(y: 2)
                    
                    HStack {
                        Text("남은 거리: \(String(format: "%.1f", max(0, nextGoal.targetDistance - tracker.bestDistance)))km")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int(progress * 100))% 달성")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(nextGoal.color)
                    }
                }
            }
            .padding()
            .background(nextGoal.color.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    // Zone2Goals와 Zone2ProgressTracker를 사용하도록 수정
    private func getNextGoal(goals: Zone2Goals, tracker: Zone2ProgressTracker) -> NextGoalInfo {
        if !tracker.achievedShortTermDistance {
            return NextGoalInfo(title: "단기 목표", targetDistance: goals.shortTermDistance, color: .green)
        } else if !tracker.achievedMediumTermDistance {
            return NextGoalInfo(title: "중기 목표", targetDistance: goals.mediumTermDistance, color: .orange)
        } else {
            return NextGoalInfo(title: "장기 목표", targetDistance: goals.longTermDistance, color: .purple)
        }
    }
}

// MARK: - 기본 목표 진행상황 (평가 미완료)
struct BasicGoalProgressView: View {
    @EnvironmentObject var dataManager: RunningDataManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("10km 목표")
                .font(.headline)
                .fontWeight(.bold)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("최고 기록")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.2f km", $dataManager.bestDistance as! CVarArg))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("목표까지")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.2f km", max(0, 10.0 - dataManager.bestDistance)))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                }
            }
            
            // 진행률 바
            ProgressView(value: min(dataManager.bestDistance / 10.0, 1.0))
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .scaleEffect(x: 1, y: 2, anchor: .center)
            
            Text("체력 평가를 완료하면 개인 맞춤 목표를 설정해드려요!")
                .font(.caption)
                .foregroundColor(.blue)
                .padding(.top, 4)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - 오늘의 운동 추천
struct TodaysWorkoutRecommendationView: View {
    @EnvironmentObject var assessmentManager: FitnessAssessmentManager
    @EnvironmentObject var dataManager: RunningDataManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("오늘의 추천 운동")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
            }
            
            let recommendation = generateRecommendation()
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: recommendation.icon)
                        .font(.title2)
                        .foregroundColor(recommendation.color)
                        .frame(width: 40, height: 40)
                        .background(recommendation.color.opacity(0.1))
                        .cornerRadius(10)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(recommendation.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text(recommendation.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Spacer()
                }
                
                if let targetDistance = recommendation.targetDistance {
                    HStack {
                        Text("추천 거리:")
                        Text("\(String(format: "%.1f", targetDistance))km")
                            .fontWeight(.medium)
                            .foregroundColor(recommendation.color)
                        
                        Spacer()
                        
                        if let targetPace = recommendation.targetPace {
                            Text("목표 페이스:")
                            Text(paceString(from: targetPace))
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                        }
                    }
                    .font(.caption)
                }
            }
        }
        .padding()
        .background(Color.purple.opacity(0.05))
        .cornerRadius(12)
    }
    
    private func generateRecommendation() -> WorkoutRecommendation {
        // 마지막 운동으로부터 경과된 시간
        let daysSinceLastWorkout = getDaysSinceLastWorkout()
        
        // 평가 완료 여부에 따른 추천 (Zone2Goals와 Zone2ProgressTracker 사용)
        if assessmentManager.hasCompletedAssessment,
           let goals = assessmentManager.recommendedGoals,      // Zone2Goals
           let tracker = assessmentManager.progressTracker {   // Zone2ProgressTracker
            
            // 주간 운동량 체크
            let weeklyStats = dataManager.getWeeklyStats()
            let weeklyProgress = Double(weeklyStats.workoutCount) / Double(goals.weeklyGoal.runs)
            
            if daysSinceLastWorkout >= 3 {
                return WorkoutRecommendation(
                    title: "복귀 운동",
                    description: "휴식이 길었으니 가벼운 운동으로 시작하세요",
                    icon: "return.left",
                    color: .orange,
                    targetDistance: max(1.0, tracker.bestDistance * 0.6),
                    targetPace: goals.targetPace + 30 // 30초 여유
                )
            } else if weeklyProgress < 0.5 {
                return WorkoutRecommendation(
                    title: "주간 목표 달성",
                    description: "이번 주 목표에 조금 더 가까워져보세요",
                    icon: "target",
                    color: .green,
                    targetDistance: goals.shortTermDistance * 0.8,
                    targetPace: goals.targetPace
                )
            } else if !tracker.achievedShortTermDistance {
                return WorkoutRecommendation(
                    title: "목표 도전",
                    description: "단기 목표 달성을 위한 도전 운동",
                    icon: "flag.fill",
                    color: .blue,
                    targetDistance: goals.shortTermDistance,
                    targetPace: goals.targetPace
                )
            } else {
                return WorkoutRecommendation(
                    title: "실력 유지",
                    description: "현재 실력을 유지하며 꾸준히 달려보세요",
                    icon: "figure.run",
                    color: .purple,
                    targetDistance: tracker.bestDistance * 0.9,
                    targetPace: goals.targetPace
                )
            }
        } else {
            // 평가 미완료 - 기본 추천
            if daysSinceLastWorkout >= 3 {
                return WorkoutRecommendation(
                    title: "가벼운 시작",
                    description: "1-2km로 가볍게 시작해보세요",
                    icon: "play.circle",
                    color: .green,
                    targetDistance: 1.5,
                    targetPace: 420 // 7분/km
                )
            } else {
                return WorkoutRecommendation(
                    title: "꾸준한 운동",
                    description: "자신의 페이스로 편안하게 달려보세요",
                    icon: "figure.run",
                    color: .blue,
                    targetDistance: min(5.0, $dataManager.bestDistance + 0.5),
                    targetPace: 360 // 6분/km
                )
            }
        }
    }
    
    private func getDaysSinceLastWorkout() -> Int {
        guard let lastWorkout = dataManager.workouts.first else { return 7 }
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: lastWorkout.date, to: Date()).day ?? 7
    }
    
    private func paceString(from pace: Double) -> String {
        let minutes = Int(pace) / 60
        let seconds = Int(pace) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - 최근 운동
struct RecentWorkoutView: View {
    @EnvironmentObject var dataManager: RunningDataManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("최근 운동")
                .font(.headline)
                .fontWeight(.bold)
            
            if let recentWorkout = dataManager.workouts.first {
                VStack(spacing: 10) {
                    HStack {
                        Text(recentWorkout.date, style: .date)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(timeString(from: recentWorkout.duration))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        MetricView(title: "거리", value: String(format: "%.2f km", recentWorkout.distance), color: .green)
                        MetricView(title: "평균 페이스", value: paceString(from: recentWorkout.averagePace), color: .blue)
                        MetricView(title: "평균 심박수", value: "\(Int(recentWorkout.averageHeartRate)) bpm", color: .red)
                    }
                }
            } else {
                Text("아직 운동 기록이 없습니다.")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
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

// MARK: - 주간 통계
struct WeeklyStatsView: View {
    @EnvironmentObject var dataManager: RunningDataManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("이번 주 통계")
                .font(.headline)
                .fontWeight(.bold)
            
            let weeklyStats = dataManager.getWeeklyStats()
            
            HStack {
                VStack(alignment: .leading) {
                    Text("총 거리")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f km", weeklyStats.totalDistance))
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .center) {
                    Text("운동 횟수")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(weeklyStats.workoutCount)회")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("평균 효율성")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.3f", weeklyStats.averageEfficiency))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.purple)
                }
            }
        }
        .padding()
        .background(Color.purple.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - 동기부여 메시지
struct MotivationalMessageView: View {
    let tracker: Zone2ProgressTracker  // Zone2ProgressTracker 타입으로 변경
    
    var body: some View {
        let message = generateMotivationalMessage()
        
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: message.icon)
                    .foregroundColor(message.color)
                Text("동기부여")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
            }
            
            Text(message.text)
                .font(.subheadline)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(message.color.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func generateMotivationalMessage() -> (text: String, icon: String, color: Color) {
        let totalWorkouts = tracker.totalWorkouts
        let recentAchievements = tracker.achievements.filter {
            Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .weekOfYear)
        }
        
        if !recentAchievements.isEmpty {
            return (
                "이번 주에 새로운 성취를 달성하셨네요! 🎉 계속해서 목표를 향해 나아가세요.",
                "trophy.fill",
                .yellow
            )
        } else if totalWorkouts >= 10 {
            return (
                "벌써 \(totalWorkouts)번째 운동이에요! 꾸준함이 가장 큰 힘입니다. 💪",
                "flame.fill",
                .orange
            )
        } else if totalWorkouts >= 5 {
            return (
                "좋은 습관이 만들어지고 있어요! 조금만 더 힘내면 러닝이 일상이 될 거예요.",
                "heart.fill",
                .red
            )
        } else {
            return (
                "새로운 시작, 정말 멋져요! 작은 걸음이 큰 변화를 만들어냅니다. ✨",
                "star.fill",
                .blue
            )
        }
    }
}

// MARK: - 공통 컴포넌트들
struct MetricView: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
}
struct NextGoalInfo {
    let title: String
    let targetDistance: Double
    let color: Color
}

// MARK: - 운동 추천 정보 (이 파일 내에서 정의)
struct WorkoutRecommendation {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let targetDistance: Double?
    let targetPace: Double?
    
    init(title: String, description: String, icon: String, color: Color, targetDistance: Double? = nil, targetPace: Double? = nil) {
        self.title = title
        self.description = description
        self.icon = icon
        self.color = color
        self.targetDistance = targetDistance
        self.targetPace = targetPace
    }
}
