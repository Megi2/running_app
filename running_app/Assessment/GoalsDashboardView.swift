//
//  UpdatedGoalsDashboardView.swift
//  running_app
//
//  임시 데이터로 동작하는 목표 대시보드
//

import SwiftUI
import Charts

struct GoalsDashboardView: View {
    @StateObject private var assessmentManager = FitnessAssessmentManager.shared
    @EnvironmentObject var dataManager: RunningDataManager
    @State private var showingAssessmentSetup = false
    @State private var showingMockAssessment = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if assessmentManager.hasCompletedAssessment {
                        // 평가 완료된 경우 - 목표 대시보드 표시
                        CompletedAssessmentDashboard()
                            .environmentObject(assessmentManager)
                            .environmentObject(dataManager)
                    } else {
                        // 평가 미완료 - 평가 시작 유도
                        AssessmentPromptView(onStartAssessment: {
                            showingMockAssessment = true
                        })
                    }
                }
                .padding()
            }
            .navigationTitle("목표 & 진행상황")
            .toolbar {
                if assessmentManager.hasCompletedAssessment {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button("목표 재설정") {
                                // 목표 재설정 로직
                                regenerateGoals()
                            }
                            
                            Button("평가 다시하기") {
                                showingMockAssessment = true
                            }
                            
                            Button("목표 초기화", role: .destructive) {
                                assessmentManager.resetAssessment()
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingMockAssessment) {
            MockAssessmentStartView()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("MockAssessmentCompleted"))) { notification in
            // 임시 평가 완료 시 화면 새로고침
            DispatchQueue.main.async {
                // 화면이 자동으로 업데이트됨
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RefreshMainScreen"))) { _ in
            // 메인 화면 새로고침 요청
        }
    }
    
    private func regenerateGoals() {
        // 기존 데이터를 기반으로 목표 재생성
        let mockData = MockDataGenerator.shared.generateCompleteAssessmentData()
        assessmentManager.recommendedGoals = mockData.goals
        assessmentManager.progressTracker = mockData.tracker
        
        print("🔄 목표 재설정 완료")
    }
}

// MARK: - 평가 유도 화면 (업데이트됨)
struct AssessmentPromptView: View {
    let onStartAssessment: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 16) {
                Image(systemName: "target")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("개인 맞춤 목표 설정")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Zone 2 평가를 통해\n당신에게 맞는 목표를 찾아드려요")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                PromptBenefit(
                    icon: "person.crop.circle.badge.checkmark",
                    title: "개인화된 목표",
                    description: "현재 체력에 맞는 현실적이고 달성 가능한 목표"
                )
                
                PromptBenefit(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "단계별 성장",
                    description: "체력 향상에 따른 자동 목표 업데이트"
                )
                
                PromptBenefit(
                    icon: "trophy.fill",
                    title: "성취감 극대화",
                    description: "달성 가능한 단계별 목표로 지속적인 동기부여"
                )
                
                PromptBenefit(
                    icon: "wand.and.stars",
                    title: "임시 모드 지원",
                    description: "워치 없이도 화면 확인 가능 (테스트 데이터)"
                )
            }
            .padding()
            .background(Color.white.opacity(0.8))
            .cornerRadius(16)
            
            Button(action: onStartAssessment) {
                HStack {
                    Image(systemName: "play.circle.fill")
                    Text("체력 평가 시작하기")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.purple]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            
            Text("임시 모드: 약 5초 소요")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(16)
    }
}

struct PromptBenefit: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
    }
}

// MARK: - 완료된 평가 대시보드 (기존과 동일하지만 임시 데이터 대응)
struct CompletedAssessmentDashboard: View {
    @EnvironmentObject var assessmentManager: FitnessAssessmentManager
    @EnvironmentObject var dataManager: RunningDataManager
    
    var body: some View {
        VStack(spacing: 20) {
            // 체력 수준 카드
            CurrentFitnessLevelCard(level: assessmentManager.currentFitnessLevel)
            
            // 목표 진행상황
            if let goals = assessmentManager.recommendedGoals,
               let tracker = assessmentManager.progressTracker {
                
                GoalsProgressCard(goals: goals, tracker: tracker)
                    .environmentObject(dataManager)
                
                // 주간 진행상황
                WeeklyProgressCard(goals: goals, tracker: tracker)
                    .environmentObject(dataManager)
                
                // 개인 기록
                PersonalRecordsCard(tracker: tracker)
                
                // 성취 목록
                if !tracker.achievements.isEmpty {
                    AchievementsCard(achievements: tracker.achievements)
                }
                
                // 임시 데이터 표시 배너
                MockDataBanner()
            }
        }
    }
}

// MARK: - 임시 데이터 표시 배너
struct MockDataBanner: View {
    var body: some View {
        HStack {
            Image(systemName: "info.circle.fill")
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("임시 데이터 모드")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.orange)
                
                Text("현재 테스트 데이터로 화면을 표시하고 있습니다")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - 현재 체력 수준 카드 (기존과 동일)
struct CurrentFitnessLevelCard: View {
    let level: FitnessLevel
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: level.icon)
                .font(.system(size: 40))
                .foregroundColor(level.color)
                .frame(width: 60, height: 60)
                .background(level.color.opacity(0.1))
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("현재 체력 수준")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(level.displayName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(level.color)
                
                Text("꾸준히 운동해서 다음 단계로!")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - 목표 진행상황 카드 (기존과 동일)
struct GoalsProgressCard: View {
    let goals: RunningGoals
    let tracker: ProgressTracker
    @EnvironmentObject var dataManager: RunningDataManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("목표 진행상황")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                // 단기 목표
                GoalProgressRow(
                    title: "단기 목표",
                    targetDistance: goals.shortTermDistance,
                    currentBest: tracker.bestDistance,
                    isAchieved: tracker.achievedShortTermDistance,
                    color: .green
                )
                
                // 중기 목표
                GoalProgressRow(
                    title: "중기 목표",
                    targetDistance: goals.mediumTermDistance,
                    currentBest: tracker.bestDistance,
                    isAchieved: tracker.achievedMediumTermDistance,
                    color: .orange
                )
                
                // 장기 목표
                GoalProgressRow(
                    title: "장기 목표",
                    targetDistance: goals.longTermDistance,
                    currentBest: tracker.bestDistance,
                    isAchieved: false, // 장기 목표는 별도 처리
                    color: .purple
                )
                
                Divider()
                
                // 페이스 목표
                PaceGoalRow(
                    title: "목표 페이스",
                    targetPace: goals.targetPace,
                    currentBest: tracker.bestPace,
                    isAchieved: tracker.achievedTargetPace
                )
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
    }
}

struct GoalProgressRow: View {
    let title: String
    let targetDistance: Double
    let currentBest: Double
    let isAchieved: Bool
    let color: Color
    
    var progress: Double {
        min(currentBest / targetDistance, 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                if isAchieved {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("달성!")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                } else {
                    Text("\(String(format: "%.1f", currentBest))/\(String(format: "%.1f", targetDistance))km")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: isAchieved ? .green : color))
                .scaleEffect(y: 1.5)
                .animation(.easeInOut(duration: 1.0), value: progress)
            
            if !isAchieved {
                Text("남은 거리: \(String(format: "%.1f", max(0, targetDistance - currentBest)))km")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct PaceGoalRow: View {
    let title: String
    let targetPace: Double
    let currentBest: Double
    let isAchieved: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("목표: \(paceString(from: targetPace))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if isAchieved {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("달성!")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                } else {
                    Text("현재: \(paceString(from: currentBest))")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    let improvement = currentBest - targetPace
                    if improvement > 0 {
                        Text("\(String(format: "%.0f", improvement))초 단축 필요")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    private func paceString(from pace: Double) -> String {
        guard pace > 0 && pace < 9999 else { return "--:--" }
        let minutes = Int(pace) / 60
        let seconds = Int(pace) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - 주간 진행상황 카드
struct WeeklyProgressCard: View {
    let goals: RunningGoals
    let tracker: ProgressTracker
    @EnvironmentObject var dataManager: RunningDataManager
    
    var weeklyStats: WeeklyStats {
        // 임시 데이터 사용
        WeeklyStats(
            totalDistance: 4.8, // 이번 주 1회 운동
            workoutCount: 1,     // 1회 완료
            averageEfficiency: 0.65
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("이번 주 진행상황")
                .font(.headline)
                .fontWeight(.bold)
            
            HStack(spacing: 20) {
                WeeklyMetric(
                    title: "운동 횟수",
                    current: weeklyStats.workoutCount,
                    target: goals.weeklyGoal.runs,
                    unit: "회",
                    color: .blue
                )
                
                WeeklyMetric(
                    title: "총 거리",
                    current: Int(weeklyStats.totalDistance * 10), // 0.1km 단위
                    target: Int(goals.weeklyGoal.totalDistance * 10),
                    unit: "km",
                    color: .green,
                    isDistance: true
                )
            }
            
            // 주간 목표 달성률
            let runsProgress = Double(weeklyStats.workoutCount) / Double(goals.weeklyGoal.runs)
            let distanceProgress = weeklyStats.totalDistance / goals.weeklyGoal.totalDistance
            let overallProgress = (runsProgress + distanceProgress) / 2
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("주간 목표 달성률")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("\(Int(overallProgress * 100))%")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(overallProgress >= 1.0 ? .green : .orange)
                }
                
                ProgressView(value: min(overallProgress, 1.0))
                    .progressViewStyle(LinearProgressViewStyle(tint: overallProgress >= 1.0 ? .green : .orange))
                    .scaleEffect(y: 1.5)
                    .animation(.easeInOut(duration: 1.0), value: overallProgress)
            }
        }
        .padding()
        .background(Color.green.opacity(0.05))
        .cornerRadius(12)
    }
}

struct WeeklyMetric: View {
    let title: String
    let current: Int
    let target: Int
    let unit: String
    let color: Color
    let isDistance: Bool
    
    init(title: String, current: Int, target: Int, unit: String, color: Color, isDistance: Bool = false) {
        self.title = title
        self.current = current
        self.target = target
        self.unit = unit
        self.color = color
        self.isDistance = isDistance
    }
    
    var displayCurrent: String {
        if isDistance {
            return String(format: "%.1f", Double(current) / 10)
        }
        return "\(current)"
    }
    
    var displayTarget: String {
        if isDistance {
            return String(format: "%.1f", Double(target) / 10)
        }
        return "\(target)"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(alignment: .bottom, spacing: 4) {
                Text(displayCurrent)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text("/")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(displayTarget)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            let progress = Double(current) / Double(target)
            ProgressView(value: min(progress, 1.0))
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .scaleEffect(y: 1.2)
                .animation(.easeInOut(duration: 1.0), value: progress)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - 개인 기록 카드
struct PersonalRecordsCard: View {
    let tracker: ProgressTracker
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("개인 기록")
                .font(.headline)
                .fontWeight(.bold)
            
            HStack(spacing: 20) {
                RecordMetric(
                    title: "최장 거리",
                    value: String(format: "%.1f km", tracker.bestDistance),
                    icon: "location.fill",
                    color: .blue
                )
                
                RecordMetric(
                    title: "최고 페이스",
                    value: paceString(from: tracker.bestPace),
                    icon: "speedometer",
                    color: .green
                )
                
                RecordMetric(
                    title: "총 운동",
                    value: "\(tracker.totalWorkouts)회",
                    icon: "figure.run",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color.purple.opacity(0.05))
        .cornerRadius(12)
    }
    
    private func paceString(from pace: Double) -> String {
        guard pace > 0 && pace < 9999 else { return "--:--" }
        let minutes = Int(pace) / 60
        let seconds = Int(pace) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct RecordMetric: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 성취 카드
struct AchievementsCard: View {
    let achievements: [Achievement]
    
    var recentAchievements: [Achievement] {
        Array(achievements.suffix(3))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("최근 성취")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                if achievements.count > 3 {
                    Text("총 \(achievements.count)개")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(spacing: 12) {
                ForEach(recentAchievements) { achievement in
                    AchievementRow(achievement: achievement)
                }
            }
        }
        .padding()
        .background(Color.yellow.opacity(0.05))
        .cornerRadius(12)
    }
}

struct AchievementRow: View {
    let achievement: Achievement
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "trophy.fill")
                .font(.title3)
                .foregroundColor(.yellow)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(achievement.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(achievement.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(achievement.date, style: .date)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}
