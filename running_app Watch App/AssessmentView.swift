//
//  AssessmentView.swift
//  running_app Watch App
//
//  Zone 2 평가 화면
//

import SwiftUI

struct AssessmentView: View {
    @StateObject private var assessmentManager = AssessmentModeManager.shared
    @EnvironmentObject var workoutManager: WorkoutManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 평가 제목
                VStack(spacing: 8) {
                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.red)
                    
                    Text("Zone 2 평가")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Text("최대 지속력 측정")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Zone 2 심박수 범위
                VStack(spacing: 12) {
                    Text("목표 심박수")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack {
                        Text("\(Int(assessmentManager.targetZone2Range.lowerBound))")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                        
                        Text("~")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        Text("\(Int(assessmentManager.targetZone2Range.upperBound))")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                        
                        Text("bpm")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("이 범위를 유지하며 최대한 오래 달려주세요")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
                
                // 평가 안내사항
                VStack(alignment: .leading, spacing: 8) {
                    Text("평가 방법")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    AssessmentInstruction(
                        icon: "heart.fill",
                        text: "목표 심박수 범위 유지",
                        color: .red
                    )
                    
                    AssessmentInstruction(
                        icon: "infinity",
                        text: "최대한 오래 달리기",
                        color: .blue
                    )
                    
                    AssessmentInstruction(
                        icon: "bubble.left.fill",
                        text: "편안한 대화 가능한 속도",
                        color: .green
                    )
                }
                
                // 시작 버튼
                Button(action: {
                    assessmentManager.startAssessmentWorkout()
                }) {
                    HStack {
                        Image(systemName: "play.circle.fill")
                        Text("Zone 2 평가 시작")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
                
                // 건너뛰기 버튼
                Button(action: {
                    assessmentManager.stopAssessmentMode()
                }) {
                    Text("나중에 하기")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
        }
        .navigationTitle("평가")
        .onAppear {
            print("📱 워치 평가 화면 표시됨")
        }
    }
}

struct AssessmentInstruction: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
                .frame(width: 16)
            
            Text(text)
                .font(.caption2)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

#Preview {
    AssessmentView()
        .environmentObject(WorkoutManager())
}