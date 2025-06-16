//
//  UpdatedAssessmentSetupView.swift
//  running_app
//
//  기존 AssessmentSetupView를 임시 데이터로 동작하도록 수정
//

import SwiftUI

struct AssessmentSetupView: View {
    @StateObject private var assessmentManager = FitnessAssessmentManager.shared
    @EnvironmentObject var dataManager: RunningDataManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentStep = 0
    @State private var showingMockAssessment = false
    
    private let totalSteps = 3
    
    var body: some View {
        NavigationView {
            ZStack {
                // 배경
                LinearGradient(
                    gradient: Gradient(colors: [Color.green.opacity(0.1), Color.blue.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 진행률 헤더
                    AssessmentProgressHeader(currentStep: currentStep, totalSteps: totalSteps)
                    
                    // 단계별 콘텐츠
                    TabView(selection: $currentStep) {
                        AssessmentWelcomeView()
                            .tag(0)
                        
                        AssessmentInstructionView()
                            .tag(1)
                        
                        UpdatedAssessmentReadyView(onStartAssessment: {
                            startMockAssessment()
                        })
                            .tag(2)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .animation(.easeInOut, value: currentStep)
                    
                    // 네비게이션 버튼
                    AssessmentNavigationButtons(
                        currentStep: $currentStep,
                        totalSteps: totalSteps,
                        onComplete: startMockAssessment
                    )
                }
            }
            .navigationBarHidden(true)
        }
        .fullScreenCover(isPresented: $showingMockAssessment) {
            MockAssessmentStartView()
        }
    }
    
    private func startMockAssessment() {
        print("🎭 임시 평가 모드 시작")
        dismiss()
        
        // 0.5초 후에 임시 평가 화면 표시
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showingMockAssessment = true
        }
    }
}

// MARK: - 업데이트된 준비 화면
struct UpdatedAssessmentReadyView: View {
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
                MockReadyCheckItem(
                    icon: "checkmark.circle.fill",
                    title: "임시 평가 모드",
                    subtitle: "워치 연결 없이 테스트 데이터로 진행",
                    isChecked: true
                )
                
                MockReadyCheckItem(
                    icon: "checkmark.circle.fill",
                    title: "자동 평가 완료",
                    subtitle: "3초 후 자동으로 평가 결과 생성",
                    isChecked: true
                )
                
                MockReadyCheckItem(
                    icon: "checkmark.circle.fill",
                    title: "목표 설정 완료",
                    subtitle: "개인 맞춤 목표 자동 생성",
                    isChecked: true
                )
                
                MockReadyCheckItem(
                    icon: "checkmark.circle.fill",
                    title: "화면 테스트 준비",
                    subtitle: "모든 UI 컴포넌트 확인 가능",
                    isChecked: true
                )
            }
            
            VStack(spacing: 16) {
                Toggle("임시 평가 모드 준비 완료", isOn: $isReady)
                    .toggleStyle(SwitchToggleStyle(tint: .red))
                
                if isReady {
                    Button(action: onStartAssessment) {
                        HStack {
                            Image(systemName: "play.circle.fill")
                            Text("임시 Zone 2 평가 시작")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.red, Color.orange]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(12)
            
            Spacer()
        }
        .padding()
        .animation(.easeInOut, value: isReady)
    }
}

struct MockReadyCheckItem: View {
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

// MARK: - 진행률 헤더 (기존과 동일)
struct AssessmentProgressHeader: View {
    let currentStep: Int
    let totalSteps: Int
    
    var progress: Double {
        Double(currentStep) / Double(totalSteps - 1)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Button("건너뛰기") {
                    // 기본 목표로 설정
                    FitnessAssessmentManager.shared.hasCompletedAssessment = true
                }
                .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(currentStep + 1) / \(totalSteps)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .green))
                .scaleEffect(y: 2)
        }
        .padding()
    }
}

// MARK: - 네비게이션 버튼 (기존과 동일)
struct AssessmentNavigationButtons: View {
    @Binding var currentStep: Int
    let totalSteps: Int
    let onComplete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            if currentStep > 0 {
                Button("이전") {
                    withAnimation {
                        currentStep -= 1
                    }
                }
                .buttonStyle(.bordered)
            }
            
            Spacer()
            
            if currentStep < totalSteps - 1 {
                Button("다음") {
                    withAnimation {
                        currentStep += 1
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            // 마지막 단계에서는 "준비 완료" 화면에서 직접 시작
        }
        .padding()
    }
}
