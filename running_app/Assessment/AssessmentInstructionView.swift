//
//  AssessmentInstructionView.swift
//  running_app
//
//  Zone 2 평가 안내 화면
//

import SwiftUI

struct AssessmentInstructionView: View {
    @StateObject private var profileManager = UserProfileManager.shared
    
    var zone2HeartRateRange: ClosedRange<Double> {
        let profile = profileManager.userProfile
        let heartRateZones = profile.heartRateZones
        return heartRateZones.zone2
    }
    
    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 12) {
                Text("Zone 2 평가 안내")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("당신의 Zone 2 최대 지속력을 측정합니다")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top)
            
            // 개인 Zone 2 범위 표시
            VStack(spacing: 16) {
                Text("당신의 Zone 2 범위")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                HStack(spacing: 20) {
                    VStack {
                        Text("\(Int(zone2HeartRateRange.lowerBound))")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                        Text("최소 심박수")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("~")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    VStack {
                        Text("\(Int(zone2HeartRateRange.upperBound))")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                        Text("최대 심박수")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
            }
            
            VStack(spacing: 20) {
                Zone2InstructionCard(
                    icon: "heart.fill",
                    title: "Zone 2 유지하기",
                    description: "심박수를 \(Int(zone2HeartRateRange.lowerBound))-\(Int(zone2HeartRateRange.upperBound)) 범위로 유지하세요\n너무 빠르거나 느리면 안됩니다",
                    color: .red
                )
                
                Zone2InstructionCard(
                    icon: "infinity",
                    title: "최대한 오래 달리기",
                    description: "Zone 2를 유지하면서 최대한 오래 달려주세요\n힘들어지면 속도를 줄이되 멈추지 마세요",
                    color: .blue
                )
                
                Zone2InstructionCard(
                    icon: "figure.run",
                    title: "편안한 대화 가능한 속도",
                    description: "달리면서 대화할 수 있을 정도의 편안한 속도\n숨이 많이 차면 너무 빠른 겁니다",
                    color: .green
                )
                
                Zone2InstructionCard(
                    icon: "applewatch",
                    title: "심박수 모니터링",
                    description: "Apple Watch를 착용하고 실시간으로\n심박수를 확인하며 달려주세요",
                    color: .orange
                )
            }
            
            Spacer()
        }
        .padding()
    }
}

struct Zone2InstructionCard: View {
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


