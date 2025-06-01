//
//  AssessmentReadyView.swift
//  running_app
//
//  Created by 전진하 on 6/1/25.
//


//
//  AssessmentReadyView.swift
//  running_app
//
//  Created by AI Assistant on 6/1/25.
//

import SwiftUI

// MARK: - 준비 완료 화면
struct AssessmentReadyView: View {
    let onStartAssessment: () -> Void
    @State private var isReady = false
    
    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 12) {
                Text("평가 시작 준비")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("모든 준비가 완료되면\n'시작하기' 버튼을 눌러주세요")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top)
            
            VStack(spacing: 20) {
                ReadyCheckItem(
                    icon: "checkmark.circle.fill",
                    title: "Apple Watch 착용 완료",
                    isChecked: true
                )
                
                ReadyCheckItem(
                    icon: "checkmark.circle.fill",
                    title: "야외 환경 (GPS 수신 가능)",
                    isChecked: true
                )
                
                ReadyCheckItem(
                    icon: "checkmark.circle.fill",
                    title: "편안한 운동복 착용",
                    isChecked: true
                )
                
                ReadyCheckItem(
                    icon: "checkmark.circle.fill",
                    title: "충분한 수분 섭취",
                    isChecked: true
                )
            }
            
            VStack(spacing: 16) {
                Toggle("준비가 모두 완료되었습니다", isOn: $isReady)
                    .toggleStyle(SwitchToggleStyle(tint: .green))
                
                if isReady {
                    Button(action: onStartAssessment) {
                        HStack {
                            Image(systemName: "play.circle.fill")
                            Text("1km 평가 달리기 시작")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)
            
            Spacer()
        }
        .padding()
        .animation(.easeInOut, value: isReady)
    }
}

struct ReadyCheckItem: View {
    let icon: String
    let title: String
    let isChecked: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(isChecked ? .green : .gray)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(isChecked ? .primary : .secondary)
            
            Spacer()
        }
    }
}