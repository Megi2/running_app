//
//  AssessmentGoalsAndReflectionPages.swift
//  running_app
//
//  평가 결과 시각화 - 페이지 3, 4 (목표 설정 및 데이터 반영)
//

import SwiftUI

// MARK: - 페이지 3: 개인 맞춤 목표
struct PersonalGoalsPageView: View {
    @EnvironmentObject var assessmentManager: FitnessAssessmentManager
    @State private var animatingGoals = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // 헤더
                VStack(spacing: 12) {
                    Text("개인 맞춤 목표 설정")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("평가 결과를 바탕으로\n당신만의 목표를 생성했습니다")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                if let goals = assessmentManager.recommendedGoals {
                    // 단계별 목표
                    VStack(spacing: 20) {
                        GoalCard(
                            phase: "단기 목표",
                            period: "4-6주",
                            distance: goals.shortTermDistance,
                            description: "첫 번째 도전할 거리",
                            color: .green,
                            isAnimating: animatingGoals
                        )
                        
                        GoalCard(
                            phase: "중기 목표",
                            period: "3-4개월",
                            distance: goals.mediumTermDistance,
                            description: "실력 향상 후 도전",
                            color: .orange,
                            isAnimating: animatingGoals
                        )
                        
                        GoalCard(
                            phase: "장기 목표",
                            period: "6-12개월",
                            distance: goals.longTermDistance,
                            description: "최종 목표 거리",
                            color: .purple,
                            isAnimating: animatingGoals
                        )
                    }
                    
                    // 세부 목표
                    DetailedGoalsSection(goals: goals)
                    
                    // 주간 계획
                    WeeklyPlanSection(goals: goals)
                }
            }
            .padding()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                    animatingGoals = true
                }
            }
        }
    }
}

// MARK: - 목표 카드
struct GoalCard: View {
    let phase: String
    let period: String
    let distance: Double
    let description: String
    let color: Color
    let isAnimating: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(phase)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(color)
                    
                    Spacer()
                    
                    Text(period)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(color.opacity(0.2))
                        .cornerRadius(8)
                        .foregroundColor(color)
                }
                
                Text("\(String(format: "%.1f", distance))km")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "target")
                .font(.title)
                .foregroundColor(color)
                .scaleEffect(isAnimating ? 1.0 : 0.8)
                .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2), value: isAnimating)
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
        .scaleEffect(isAnimating ? 1.0 : 0.9)
        .opacity(isAnimating ? 1.0 : 0.7)
        .animation(.spring(response: 0.8, dampingFraction: 0.8), value: isAnimating)
    }
}

// MARK: - 세부 목표 섹션
struct DetailedGoalsSection: View {
    let goals: Zone2Goals
    
    var body: some View {
        VStack(spacing: 16) {
            Text("세부 목표")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                DetailGoalRow(
                    title: "목표 페이스",
                    value: paceString(from: goals.targetPace),
                    icon: "speedometer",
                    color: .blue,
                    description: "달성하고 싶은 페이스"
                )
                
                DetailGoalRow(
                    title: "개선 목표 페이스",
                    value: paceString(from: goals.improvementPace),
                    icon: "arrow.up.circle",
                    color: .green,
                    description: "장기적 개선 목표"
                )
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func paceString(from pace: Double) -> String {
        let minutes = Int(pace) / 60
        let seconds = Int(pace) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - 세부 목표 행
struct DetailGoalRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let description: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 주간 계획 섹션
struct WeeklyPlanSection: View {
    let goals: Zone2Goals
    
    var body: some View {
        VStack(spacing: 16) {
            Text("주간 훈련 계획")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                WeeklyPlanCard(
                    title: "주간 운동 횟수",
                    value: "\(goals.weeklyGoal.runs)회",
                    icon: "calendar",
                    color: .blue
                )
                
                WeeklyPlanCard(
                    title: "주간 총 거리",
                    value: "\(String(format: "%.1f", goals.weeklyGoal.totalDistance))km",
                    icon: "location",
                    color: .green
                )
                
                WeeklyPlanCard(
                    title: "권장 평균 페이스",
                    value: paceString(from: goals.weeklyGoal.averagePace),
                    icon: "speedometer",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func paceString(from pace: Double) -> String {
        let minutes = Int(pace) / 60
        let seconds = Int(pace) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - 주간 계획 카드
struct WeeklyPlanCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 30)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - 페이지 4: 데이터 반영 현황
struct DataReflectionPageView: View {
    @State private var animatingCards = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // 헤더
                VStack(spacing: 12) {
                    Text("데이터 반영 현황")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("평가 결과가 앱 전체에\n어떻게 반영되는지 확인하세요")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // 탭별 반영 현황
                VStack(spacing: 16) {
                    TabReflectionCard(
                        tabName: "홈",
                        icon: "house.fill",
                        color: .blue,
                        features: [
                            "개인 맞춤 목표 진행상황 표시",
                            "Zone 2 기반 운동 추천",
                            "실시간 능력 점수 추적"
                        ],
                        isAnimating: animatingCards
                    )
                    
                    TabReflectionCard(
                        tabName: "목표",
                        icon: "target",
                        color: .green,
                        features: [
                            "단기/중기/장기 목표 설정 완료",
                            "개인 맞춤 주간 계획 적용",
                            "목표 달성률 추적 시작"
                        ],
                        isAnimating: animatingCards
                    )
                    
                    TabReflectionCard(
                        tabName: "기록",
                        icon: "list.bullet",
                        color: .orange,
                        features: [
                            "평가 운동이 기록에 추가됨",
                            "Zone 2 특화 기록 추적",
                            "개인 최고 기록 갱신 알림"
                        ],
                        isAnimating: animatingCards
                    )
                    
                    TabReflectionCard(
                        tabName: "분석",
                        icon: "chart.line.uptrend.xyaxis",
                        color: .purple,
                        features: [
                            "Zone 2 기반 분석 활성화",
                            "개인화된 효율성 분석",
                            "능력 향상 추세 분석"
                        ],
                        isAnimating: animatingCards
                    )
                }
                
                // 다음 단계 안내
                NextStepsSection()
            }
            .padding()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                    animatingCards = true
                }
            }
        }
    }
}

// MARK: - 탭 반영 카드
struct TabReflectionCard: View {
    let tabName: String
    let icon: String
    let color: Color
    let features: [String]
    let isAnimating: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 헤더
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text("\(tabName) 탭")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Spacer()
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.green)
                    .scaleEffect(isAnimating ? 1.0 : 0.0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3), value: isAnimating)
            }
            
            // 기능 목록
            VStack(alignment: .leading, spacing: 6) {
                ForEach(features.indices, id: \.self) { index in
                    HStack(alignment: .top) {
                        Text("✓")
                            .foregroundColor(color)
                            .font(.caption)
                            .fontWeight(.bold)
                        
                        Text(features[index])
                            .font(.caption)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Spacer()
                    }
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .animation(.easeInOut.delay(Double(index) * 0.1 + 0.5), value: isAnimating)
                }
            }
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
        .scaleEffect(isAnimating ? 1.0 : 0.95)
        .animation(.spring(response: 0.8, dampingFraction: 0.8), value: isAnimating)
    }
}

// MARK: - 다음 단계 섹션
struct NextStepsSection: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("다음 단계")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                NextStepItem(
                    number: "1",
                    title: "목표 탭에서 진행상황 확인",
                    description: "설정된 목표와 현재 진행률을 확인하세요"
                )
                
                NextStepItem(
                    number: "2",
                    title: "홈 탭에서 오늘의 운동 확인",
                    description: "개인 맞춤 운동 추천을 받아보세요"
                )
                
                NextStepItem(
                    number: "3",
                    title: "꾸준한 Zone 2 훈련",
                    description: "주간 계획에 따라 꾸준히 운동하세요"
                )
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - 다음 단계 아이템
struct NextStepItem: View {
    let number: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Color.blue)
                .clipShape(Circle())
            
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
    }
}