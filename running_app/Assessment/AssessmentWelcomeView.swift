//
//  AssessmentWelcomeView.swift
//  running_app
//
//  Created by 전진하 on 6/1/25.
//


//
//  AssessmentWelcomeView.swift
//  running_app
//
//  Created by AI Assistant on 6/1/25.
//

import SwiftUI

// MARK: - 환영 화면
struct AssessmentWelcomeView: View {
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "figure.run.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            VStack(spacing: 16) {
                Text("체력 평가를 시작합니다")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("1km 달리기를 통해 현재 체력을 측정하고\n개인 맞춤 목표를 설정해드릴게요")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                AssessmentFeatureRow(icon: "target", title: "개인 맞춤 목표 설정", color: .blue)
                AssessmentFeatureRow(icon: "chart.line.uptrend.xyaxis", title: "체력 수준 자동 평가", color: .green)
                AssessmentFeatureRow(icon: "arrow.up.circle.fill", title: "단계별 성장 가이드", color: .orange)
                AssessmentFeatureRow(icon: "trophy.fill", title: "달성 가능한 목표 제시", color: .purple)
            }
            .padding()
            .background(Color.white.opacity(0.8))
            .cornerRadius(16)
            
            Spacer()
        }
        .padding()
    }
}

struct AssessmentFeatureRow: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}