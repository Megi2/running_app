import SwiftUI
import Charts

struct AssessmentResultVisualizationView: View {
    let assessmentWorkout: WorkoutSummary
    let zone2CapacityScore: Zone2CapacityScore
    let recommendedGoals: Zone2Goals
    let zone2Profile: Zone2Profile
    @EnvironmentObject var assessmentManager: FitnessAssessmentManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentPage = 0
    @State private var showingNextSteps = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 상단 진행률
                ProgressIndicator(currentPage: currentPage, totalPages: 4)
                
                // 메인 콘텐츠
                TabView(selection: $currentPage) {
                    // 페이지 1: 축하 & 기본 결과
                    CelebrationPage(workout: assessmentWorkout)
                        .tag(0)
                    
                    // 페이지 2: Zone 2 능력 점수
                    CapacityScorePage(score: zone2CapacityScore, profile: zone2Profile)
                        .tag(1)
                    
                    // 페이지 3: 개인 맞춤 목표
                    PersonalizedGoalsPage(goals: recommendedGoals, currentDistance: assessmentWorkout.distance)
                        .tag(2)
                    
                    // 페이지 4: 데이터 반영 현황
                    DataReflectionPage(workout: assessmentWorkout, goals: recommendedGoals)
                        .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)
                
                // 하단 네비게이션
                HStack(spacing: 20) {
                    if currentPage > 0 {
                        Button("이전") {
                            withAnimation {
                                currentPage -= 1
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Spacer()
                    
                    if currentPage < 3 {
                        Button("다음") {
                            withAnimation {
                                currentPage += 1
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        Button("시작하기") {
                            showingNextSteps = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
            }
            .navigationTitle("평가 결과")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("건너뛰기") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
        .sheet(isPresented: $showingNextSteps) {
            NextStepsView(goals: recommendedGoals)
        }
    }
}

// MARK: - 진행률 표시기
struct ProgressIndicator: View {
    let currentPage: Int
    let totalPages: Int
    
    var body: some View {
        HStack {
            ForEach(0..<totalPages, id: \.self) { index in
                Circle()
                    .fill(index <= currentPage ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .scaleEffect(index == currentPage ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: currentPage)
                
                if index < totalPages - 1 {
                    Rectangle()
                        .fill(index < currentPage ? Color.blue : Color.gray.opacity(0.3))
                        .frame(height: 2)
                        .animation(.easeInOut(duration: 0.3), value: currentPage)
                }
            }
        }
        .padding()
    }
}

// MARK: - 페이지 1: 축하 화면
struct CelebrationPage: View {
    let workout: WorkoutSummary
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                Spacer()
                
                // 축하 애니메이션
                VStack(spacing: 20) {
                    Image(systemName: "trophy.circle.fill")
                        .font(.system(size: 100))
                        .foregroundColor(.yellow)
                        .symbolEffect(.bounce)
                    
                    Text("평가 완료!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Zone 2 최대 지속력 측정이 완료되었습니다")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // 기본 결과 카드
                VStack(spacing: 16) {
                    HStack(spacing: 30) {
                        ResultMetric(
                            title: "거리",
                            value: String(format: "%.2f", workout.distance),
                            unit: "km",
                            color: .green,
                            icon: "location.fill"
                        )
                        
                        ResultMetric(
                            title: "시간",
                            value: timeString(from: workout.duration),
                            unit: "",
                            color: .blue,
                            icon: "clock.fill"
                        )
                    }
                    
                    HStack(spacing: 30) {
                        ResultMetric(
                            title: "평균 페이스",
                            value: paceString(from: workout.averagePace),
                            unit: "/km",
                            color: .purple,
                            icon: "speedometer"
                        )
                        
                        ResultMetric(
                            title: "평균 심박수",
                            value: String(Int(workout.averageHeartRate)),
                            unit: "bpm",
                            color: .red,
                            icon: "heart.fill"
                        )
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(16)
                
                Text("이 데이터를 바탕으로 개인 맞춤 목표를 설정했습니다")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Spacer()
            }
            .padding()
        }
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func paceString(from pace: Double) -> String {
        let minutes = Int(pace) / 60
        let seconds = Int(pace) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct ResultMetric: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(alignment: .bottom, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 페이지 2: Zone 2 능력 점수
struct CapacityScorePage: View {
    let score: Zone2CapacityScore
    let profile: Zone2Profile
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // 총 점수 원형 그래프
                VStack(spacing: 16) {
                    Text("Zone 2 능력 점수")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                            .frame(width: 150, height: 150)
                        
                        Circle()
                            .trim(from: 0, to: score.totalScore / 100)
                            .stroke(score.scoreColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                            .frame(width: 150, height: 150)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 1.5), value: score.totalScore)
                        
                        VStack {
                            Text("\(Int(score.totalScore))")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(score.scoreColor)
                            
                            Text("/ 100")
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Text(score.scoreColor == .green ? "우수" : score.scoreColor == .blue ? "양호" : score.scoreColor == .orange ? "보통" : "개선 필요")
                        .font(.headline)
                        .foregroundColor(score.scoreColor)
                }
                
                // 세부 점수들
                VStack(spacing: 12) {
                    Text("세부 능력")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    ScoreDetailRow(title: "거리 지속력", score: score.distanceScore, color: .green)
                    ScoreDetailRow(title: "시간 지속력", score: score.timeScore, color: .blue)
                    ScoreDetailRow(title: "Zone 2 일관성", score: score.consistencyScore, color: .red)
                    ScoreDetailRow(title: "유산소 효율성", score: score.efficiencyScore, color: .purple)
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
                
                // 강점과 개선점
                HStack(spacing: 16) {
                    if !score.strengthAreas.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("강점", systemImage: "star.fill")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                            
                            ForEach(score.strengthAreas, id: \.self) { strength in
                                Text("• \(strength)")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    if !score.improvementAreas.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("개선점", systemImage: "arrow.up.circle.fill")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.orange)
                            
                            ForEach(score.improvementAreas, id: \.self) { improvement in
                                Text("• \(improvement)")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
            .padding()
        }
    }
}

struct ScoreDetailRow: View {
    let title: String
    let score: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(title)
                    .font(.subheadline)
                Spacer()
                Text("\(Int(score))")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)
                        .cornerRadius(3)
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * (score / 100), height: 6)
                        .cornerRadius(3)
                        .animation(.easeInOut(duration: 1.0), value: score)
                }
            }
            .frame(height: 6)
        }
    }
}

// MARK: - 페이지 3: 개인 맞춤 목표
struct PersonalizedGoalsPage: View {
    let goals: Zone2Goals
    let currentDistance: Double
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                VStack(spacing: 16) {
                    Image(systemName: "target")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("개인 맞춤 목표")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("현재 능력을 바탕으로 설정된 단계별 목표입니다")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 16) {
                    GoalCard(
                        title: "단기 목표 (4-6주)",
                        distance: goals.shortTermDistance,
                        currentDistance: currentDistance,
                        color: .green,
                        description: "첫 번째 도전할 거리"
                    )
                    
                    GoalCard(
                        title: "중기 목표 (3-4개월)",
                        distance: goals.mediumTermDistance,
                        currentDistance: currentDistance,
                        color: .orange,
                        description: "꾸준한 훈련 후 달성할 거리"
                    )
                    
                    GoalCard(
                        title: "장기 목표 (6-12개월)",
                        distance: goals.longTermDistance,
                        currentDistance: currentDistance,
                        color: .purple,
                        description: "최종 목표 거리"
                    )
                }
                
                VStack(spacing: 12) {
                    Text("추가 목표")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    AdditionalGoalRow(
                        title: "목표 페이스",
                        value: paceString(from: goals.targetPace),
                        icon: "speedometer",
                        color: .blue
                    )
                    
                    AdditionalGoalRow(
                        title: "주간 운동",
                        value: "\(goals.weeklyGoal.runs)회, \(String(format: "%.1f", goals.weeklyGoal.totalDistance))km",
                        icon: "calendar",
                        color: .green
                    )
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
            }
            .padding()
        }
    }
    
    private func paceString(from pace: Double) -> String {
        let minutes = Int(pace) / 60
        let seconds = Int(pace) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct GoalCard: View {
    let title: String
    let distance: Double
    let currentDistance: Double
    let color: Color
    let description: String
    
    var progress: Double {
        min(currentDistance / distance, 1.0)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(String(format: "%.1f", distance))km")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(color)
                    
                    Text("목표")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(spacing: 6) {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: color))
                    .scaleEffect(y: 2)
                
                HStack {
                    Text("현재: \(String(format: "%.2f", currentDistance))km")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(progress * 100))% 달성")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(color)
                }
            }
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct AdditionalGoalRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
}

// MARK: - 페이지 4: 데이터 반영 현황
struct DataReflectionPage: View {
    let workout: WorkoutSummary
    let goals: Zone2Goals
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    
                    Text("데이터가 반영되었습니다")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("평가 결과가 앱 전체에 적용되어 개인화된 경험을 제공합니다")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 16) {
                    ReflectionCard(
                        icon: "list.bullet",
                        title: "기록 탭",
                        description: "평가 운동이 기록에 추가되었습니다",
                        details: [
                            "거리: \(String(format: "%.2f", workout.distance))km",
                            "시간: \(timeString(from: workout.duration))",
                            "평균 심박수: \(Int(workout.averageHeartRate))bpm"
                        ],
                        color: .blue
                    )
                    
                    ReflectionCard(
                        icon: "target",
                        title: "목표 탭",
                        description: "개인 맞춤 목표가 설정되었습니다",
                        details: [
                            "단기 목표: \(String(format: "%.1f", goals.shortTermDistance))km",
                            "중기 목표: \(String(format: "%.1f", goals.mediumTermDistance))km",
                            "장기 목표: \(String(format: "%.1f", goals.longTermDistance))km"
                        ],
                        color: .green
                    )
                    
                    ReflectionCard(
                        icon: "house.fill",
                        title: "홈 탭",
                        description: "개인화된 운동 추천이 시작됩니다",
                        details: [
                            "현재 진행상황 추적",
                            "맞춤형 운동 추천",
                            "동기부여 메시지"
                        ],
                        color: .purple
                    )
                    
                    ReflectionCard(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "분석 탭",
                        description: "Zone 2 기반 분석이 활성화되었습니다",
                        details: [
                            "Zone 2 유지율 분석",
                            "개인 효율성 추적",
                            "장기 트렌드 분석"
                        ],
                        color: .orange
                    )
                }
            }
            .padding()
        }
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct ReflectionCard: View {
    let icon: String
    let title: String
    let description: String
    let details: [String]
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title3)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(details, id: \.self) { detail in
                    HStack {
                        Circle()
                            .fill(color)
                            .frame(width: 4, height: 4)
                        
                        Text(detail)
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                }
            }
            .padding(.leading, 34)
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - 다음 단계 안내
struct NextStepsView: View {
    let goals: Zone2Goals
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Image(systemName: "figure.run.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                VStack(spacing: 16) {
                    Text("이제 시작해보세요!")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("설정된 목표를 향해 꾸준히 달려보세요")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 16) {
                    NextStepItem(
                        icon: "1.circle.fill",
                        title: "첫 번째 목표: \(String(format: "%.1f", goals.shortTermDistance))km",
                        description: "4-6주 안에 달성 가능한 거리입니다"
                    )
                    
                    NextStepItem(
                        icon: "calendar.circle.fill",
                        title: "주간 목표: 주 \(goals.weeklyGoal.runs)회 운동",
                        description: "꾸준한 운동 습관을 만들어보세요"
                    )
                    
                    NextStepItem(
                        icon: "heart.circle.fill",
                        title: "Zone 2 유지하기",
                        description: "편안한 심박수로 오래 달리는 연습을 하세요"
                    )
                }
                
                Button("앱 둘러보기") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .font(.headline)
                .frame(maxWidth: .infinity)
                
                Spacer()
            }
            .padding()
            .navigationTitle("다음 단계")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("완료") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct NextStepItem: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
}