import SwiftUI

struct AssessmentSetupView: View {
    @StateObject private var assessmentCoordinator = AssessmentCoordinator.shared
    @EnvironmentObject var dataManager: RunningDataManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentStep = 0
    
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
                    AssessmentProgressHeader(currentStep: currentStep, totalSteps: totalSteps) {
                        dismiss()
                    }
                    
                    // 단계별 콘텐츠
                    TabView(selection: $currentStep) {
                        AssessmentWelcomeView()
                            .tag(0)
                        
                        AssessmentInstructionView()
                            .tag(1)
                        
                        AssessmentReadyView(onStartAssessment: {
                            startAssessmentRun()
                        })
                            .tag(2)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .animation(.easeInOut, value: currentStep)
                    
                    // 네비게이션 버튼
                    AssessmentNavigationButtons(
                        currentStep: $currentStep,
                        totalSteps: totalSteps,
                        onComplete: startAssessmentRun
                    )
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private func startAssessmentRun() {
        // 평가 모드 시작
        assessmentCoordinator.startAssessment()
        
        // 현재 시트 닫기
        dismiss()
        
        print("📊 평가 달리기 시작됨")
    }
}

// MARK: - 진행률 헤더 (수정된 버전)
struct AssessmentProgressHeader: View {
    let currentStep: Int
    let totalSteps: Int
    let onSkip: () -> Void
    
    var progress: Double {
        Double(currentStep) / Double(totalSteps - 1)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Button("건너뛰기") {
                    // 기본 목표로 설정하고 평가 건너뛰기
                    FitnessAssessmentManager.shared.hasCompletedAssessment = true
                    onSkip()
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

// MARK: - 네비게이션 버튼 (수정된 버전)
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
