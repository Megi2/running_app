//
//  AssessmentInstructionView.swift
//  running_app
//
//  Created by 전진하 on 6/1/25.
//


//
//  AssessmentInstructionView.swift
//  running_app
//
//  Created by AI Assistant on 6/1/25.
//

import SwiftUI

// MARK: - 평가 안내 화면
struct AssessmentInstructionView: View {
    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 12) {
                Text("평가 달리기 안내")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("정확한 평가를 위해 다음 사항을 확인해주세요")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top)
            
            VStack(spacing: 20) {
                InstructionCard(
                    icon: "figure.run",
                    title: "1km 달리기",
                    description: "편안한 속도로 1km를 완주해주세요\n무리하지 마시고 본인 페이스를 유지하세요",
                    color: .green
                )
                
                InstructionCard(
                    icon: "applewatch",
                    title: "Apple Watch 착용",
                    description: "정확한 심박수와 페이스 측정을 위해\nApple Watch를 착용해주세요",
                    color: .blue
                )
                
                InstructionCard(
                    icon: "location.fill",
                    title: "야외 환경",
                    description: "GPS 신호가 잘 잡히는 야외에서\n달리기를 진행해주세요",
                    color: .orange
                )
                
                InstructionCard(
                    icon: "heart.fill",
                    title: "컨디션 체크",
                    description: "몸상태가 좋은 날에 진행하시고\n아프거나 피곤하면 다음에 하세요",
                    color: .red
                )
            }
            
            Spacer()
        }
        .padding()
    }
}

struct InstructionCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.1))
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.8))
        .cornerRadius(12)
    }
}