//
//  AssessmentWelcomeView.swift
//  running_app
//
//  Zone 2 평가 환영 화면
//

import SwiftUI

struct AssessmentWelcomeView: View {
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.red)
            
            VStack(spacing: 16) {
                Text("Zone 2 최대 지속력 평가")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Zone 2 심박수 범위에서 최대한 오래\n달릴 수 있는 능력을 측정합니다")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Zone2FeatureRow(
                    icon: "heart.fill",
                    title: "개인 맞춤 Zone 2 계산",
                    description: "나이와 안정시 심박수로 정확한 Zone 2 설정",
                    color: .red
                )
                Zone2FeatureRow(
                    icon: "timer",
                    title: "최대 지속 시간 측정",
                    description: "Zone 2에서 얼마나 오래 달릴 수 있는지 평가",
                    color: .blue
                )
                Zone2FeatureRow(
                    icon: "location.fill",
                    title: "최대 지속 거리 측정",
                    description: "Zone 2에서 달릴 수 있는 최대 거리 측정",
                    color: .green
                )
                Zone2FeatureRow(
                    icon: "target",
                    title: "맞춤형 유산소 목표",
                    description: "Zone 2 능력에 맞는 개인화된 목표 설정",
                    color: .purple
                )
            }
            .padding()
            .background(Color.white.opacity(0.8))
            .cornerRadius(16)
            
            Spacer()
        }
        .padding()
    }
}

struct Zone2FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
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
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
    }
}
