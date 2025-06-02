//
//  AssessmentReadyView.swift
//  running_app
//
//  Zone 2 평가 준비 화면
//

import SwiftUI

struct AssessmentReadyView: View {
    let onStartAssessment: () -> Void
    @State private var isReady = false
    @StateObject private var profileManager = UserProfileManager.shared
    
    var zone2HeartRateRange: ClosedRange<Double> {
        let profile = profileManager.userProfile
        let heartRateZones = profile.heartRateZones
        return heartRateZones.zone2
    }
    
    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 12) {
                Text("Zone 2 평가 시작 준비")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("모든 준비가 완료되면\n'시작하기' 버튼을 눌러주세요")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top)
            
            // Zone 2 범위 리마인더
            VStack(spacing: 12) {
                Text("목표 심박수 범위")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                HStack {
                    Text("\(Int(zone2HeartRateRange.lowerBound))")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    
                    Text("~")
                        .font(.title)
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(zone2HeartRateRange.upperBound))")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    
                    Text("bpm")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                
                Text("이 범위를 유지하면서 최대한 오래 달려주세요")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .background(Color.red.opacity(0.1))
            .cornerRadius(12)
            
            VStack(spacing: 20) {
                Zone2ReadyCheckItem(
                    icon: "checkmark.circle.fill",
                    title: "Apple Watch 착용 완료",
                    subtitle: "심박수 모니터링 준비됨",
                    isChecked: true
                )
                
                Zone2ReadyCheckItem(
                    icon: "checkmark.circle.fill",
                    title: "야외 환경 (GPS 수신 가능)",
                    subtitle: "거리 측정을 위한 GPS 필요",
                    isChecked: true
                )
                
                Zone2ReadyCheckItem(
                    icon: "checkmark.circle.fill",
                    title: "편안한 운동복과 신발",
                    subtitle: "오래 달릴 수 있는 편안한 장비",
                    isChecked: true
                )
                
                Zone2ReadyCheckItem(
                    icon: "checkmark.circle.fill",
                    title: "충분한 수분과 에너지",
                    subtitle: "오래 달리기 위한 준비",
                    isChecked: true
                )
            }
            
            VStack(spacing: 16) {
                Toggle("Zone 2 평가 준비가 모두 완료되었습니다", isOn: $isReady)
                    .toggleStyle(SwitchToggleStyle(tint: .red))
                
                if isReady {
                    Button(action: onStartAssessment) {
                        HStack {
                            Image(systemName: "heart.circle.fill")
                            Text("Zone 2 최대 지속력 평가 시작")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(12)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding()
            .background(Color.red.opacity(0.1))
            .cornerRadius(12)
            
            Spacer()
        }
        .padding()
        .animation(.easeInOut, value: isReady)
    }
}

struct Zone2ReadyCheckItem: View {
    let icon: String
    let title: String
    let subtitle: String
    let isChecked: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(isChecked ? .green : .gray)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isChecked ? .primary : .secondary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

