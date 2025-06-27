//
//  AssessmentSetupView+Demo.swift
//  running_app
//
//  평가 설정 화면에 데모 기능을 추가
//  실제 달리기 없이도 바로 결과를 확인할 수 있습니다.
//

import SwiftUI

// MARK: - 데모 기능이 추가된 평가 설정 화면
struct AssessmentSetupViewWithDemo: View {
    @StateObject private var assessmentCoordinator = AssessmentCoordinator.shared
    @StateObject private var assessmentManager = FitnessAssessmentManager.shared
    @EnvironmentObject var dataManager: RunningDataManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentStep = 0
    @State private var showingDemoOptions = false
    @State private var selectedDifficulty: DemoDifficulty = .intermediate
    
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
                    DemoAssessmentProgressHeader(currentStep: currentStep, totalSteps: totalSteps) {
                        dismiss()
                    }
                    
                    // 단계별 콘텐츠
                    TabView(selection: $currentStep) {
                        AssessmentWelcomeView()
                            .tag(0)
                        
                        AssessmentInstructionView()
                            .tag(1)
                        
                        // 새로운 단계: 실제 평가 vs 데모 선택
                        DemoSelectionView(
                            onStartRealAssessment: startRealAssessment,
                            onStartDemo: { showingDemoOptions = true }
                        )
                        .tag(2)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .animation(.easeInOut, value: currentStep)
                    
                    // 네비게이션 버튼
                    DemoAssessmentNavigationButtons(
                        currentStep: $currentStep,
                        totalSteps: totalSteps
                    )
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingDemoOptions) {
                DemoOptionsSheet(
                    selectedDifficulty: $selectedDifficulty,
                    onStartDemo: startDemo,
                    onCancel: { showingDemoOptions = false }
                )
            }
        }
    }
    
    // MARK: - 액션 메서드들
    
    /// 실제 평가 시작 (기존 로직)
    private func startRealAssessment() {
        assessmentCoordinator.startAssessment()
        dismiss()
        print("📊 실제 평가 시작됨")
    }
    
    /// 데모 평가 시작 (새로운 기능)
    private func startDemo() {
        // 데모 실행
        assessmentManager.runDemoAssessment(difficulty: selectedDifficulty)
        
        // 시트 닫기
        showingDemoOptions = false
        dismiss()
        
        print("🎭 데모 평가 시작됨 (난이도: \(selectedDifficulty.rawValue))")
    }
}

// MARK: - 데모 선택 화면
struct DemoSelectionView: View {
    let onStartRealAssessment: () -> Void
    let onStartDemo: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 12) {
                Text("평가 방법 선택")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("실제 달리기를 하거나\n데모로 바로 결과를 확인하세요")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top)
            
            VStack(spacing: 20) {
                // 실제 평가 버튼
                Button(action: onStartRealAssessment) {
                    HStack(spacing: 15) {
                        Image(systemName: "figure.run.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.green)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("실제 달리기 평가")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text("Apple Watch로 실제 Zone 2 달리기")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.green, lineWidth: 2)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // 데모 평가 버튼 (눈에 띄게)
                Button(action: onStartDemo) {
                    HStack(spacing: 15) {
                        Image(systemName: "wand.and.stars.inverse")
                            .font(.system(size: 30))
                            .foregroundColor(.purple)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("데모로 바로 체험")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                Text("추천")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.red)
                                    .cornerRadius(8)
                            }
                            
                            Text("가짜 데이터로 즉시 결과 확인")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.purple, lineWidth: 2)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // 데모 설명
                VStack(alignment: .leading, spacing: 8) {
                    Text("💡 데모 평가 장점")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• 즉시 결과 확인 가능")
                        Text("• 실제 달리기 불필요")
                        Text("• 다양한 수준별 체험")
                        Text("• 언제든 실제 평가로 교체")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.blue.opacity(0.05))
                .cornerRadius(10)
            }
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - 데모 옵션 선택 시트
struct DemoOptionsSheet: View {
    @Binding var selectedDifficulty: DemoDifficulty
    let onStartDemo: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                VStack(spacing: 12) {
                    Text("데모 난이도 선택")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("원하는 수준을 선택하세요")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                VStack(spacing: 15) {
                    ForEach(DemoDifficulty.allCases, id: \.self) { difficulty in
                        DemoDifficultyCard(
                            difficulty: difficulty,
                            isSelected: selectedDifficulty == difficulty
                        ) {
                            selectedDifficulty = difficulty
                        }
                    }
                }
                
                // 시작 버튼
                Button(action: onStartDemo) {
                    HStack {
                        Text(selectedDifficulty.emoji)
                        Text("데모 시작하기")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .cornerRadius(12)
                }
                .padding(.top)
                
                Spacer()
            }
            .padding()
            .navigationTitle("데모 설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("취소", action: onCancel)
                }
            }
        }
    }
}

// MARK: - 데모 난이도 카드
struct DemoDifficultyCard: View {
    let difficulty: DemoDifficulty
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Text(difficulty.emoji)
                    .font(.system(size: 30))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(difficulty.rawValue)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(difficulty.description)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.title3)
                }
            }
            .padding()
            .background(isSelected ? Color.purple : Color.gray.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 데모용 진행률 헤더
struct DemoAssessmentProgressHeader: View {
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

// MARK: - 데모용 네비게이션 버튼
struct DemoAssessmentNavigationButtons: View {
    @Binding var currentStep: Int
    let totalSteps: Int
    
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
            // 마지막 단계에서는 선택 화면에서 직접 처리
        }
        .padding()
    }
}