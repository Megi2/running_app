//
//  AssessmentResultView.swift
//  running_app
//
//  Created by 전진하 on 6/1/25.
//


//
//  AssessmentResultView.swift
//  running_app
//
//  Created by AI Assistant on 6/1/25.
//

import SwiftUI

// MARK: - 평가 결과 화면
struct AssessmentResultView: View {
    let assessmentWorkout: WorkoutSummary
    let fitnessLevel: FitnessLevel
    let recommendedGoals: RunningGoals
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // 축하 메시지
                    VStack(spacing: 16) {
                        Image(systemName: "trophy.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.gold)
                        
                        Text("평가 완료!")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("1km 달리기를 완주하셨습니다")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    
                    // 평가 결과
                    VStack(spacing: 20) {
                        Text("평가 결과")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        // 체력 수준
                        FitnessLevelCard(level: fitnessLevel)
                        
                        // 운동 결과
                        AssessmentSummaryCard(workout: assessmentWorkout)
                        
                        // 추천 목표
                        RecommendedGoalsCard(goals: recommendedGoals)
                    }
                    
                    // 시작하기 버튼
                    Button("목표와 함께 시작하기") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .font(.headline)
                    .padding(.horizontal, 40)
                }
                .padding()
            }
            .navigationTitle("평가 결과")
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

struct FitnessLevelCard: View {
    let level: FitnessLevel
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: level.icon)
                    .font(.title)
                    .foregroundColor(level.color)
                
                VStack(alignment: .leading) {
                    Text("현재 체력 수준")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(level.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(level.color)
                }
                
                Spacer()
            }
            
            Text(getLevelDescription(level))
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .background(level.color.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func getLevelDescription(_ level: FitnessLevel) -> String {
        switch level {
        case .novice:
            return "달리기를 막 시작하신 분이에요. 천천히 꾸준히 하면 금방 늘어날 거예요!"
        case .beginner:
            return "기초 체력이 갖춰져 있어요. 조금 더 훈련하면 중급자가 될 수 있어요."
        case .intermediate:
            return "꽤 좋은 체력을 가지고 계시네요! 이제 더 긴 거리에 도전해보세요."
        case .advanced:
            return "상당한 실력자시네요! 마라톤 완주도 충분히 가능한 수준입니다."
        case .elite:
            return "엘리트 러너 수준입니다! 경기 참가도 고려해보시는 건 어떨까요?"
        }
    }
}

extension Color {
    static let gold = Color(red: 1.0, green: 0.84, blue: 0.0)
}