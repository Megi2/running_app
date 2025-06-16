//
//  MockAssessmentHandler.swift
//  running_app
//
//  Created by 전진하 on 6/16/25.
//


//
//  MockAssessmentHandler.swift
//  running_app
//
//  임시 평가 처리기 - 워치 없이 평가 완료 시뮬레이션
//

import Foundation
import SwiftUI

// MARK: - 임시 평가 처리 클래스
class MockAssessmentHandler: ObservableObject {
    static let shared = MockAssessmentHandler()
    
    @Published var isProcessing = false
    @Published var showingResult = false
    @Published var assessmentWorkout: WorkoutSummary?
    @Published var zone2CapacityScore: Zone2CapacityScore?
    @Published var recommendedGoals: RunningGoals?
    @Published var zone2Profile: Zone2Profile?
    
    private init() {}
    
    // MARK: - 임시 평가 시작 (3초 후 완료)
    func startMockAssessment() {
        print("🎭 임시 Zone 2 평가 시작...")
        
        isProcessing = true
        
        // 3초 후에 평가 완료 시뮬레이션
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.completeMockAssessment()
        }
    }
    
    // MARK: - 임시 평가 완료 처리
    private func completeMockAssessment() {
        print("🎯 임시 Zone 2 평가 완료 처리 중...")
        
        // 임시 데이터 생성
        let mockData = MockDataGenerator.shared.generateCompleteAssessmentData()
        
        // 데이터 설정
        assessmentWorkout = mockData.assessmentWorkout
        zone2CapacityScore = mockData.zone2CapacityScore
        recommendedGoals = mockData.goals
        zone2Profile = mockData.zone2Profile
        
        // FitnessAssessmentManager에 데이터 적용
        let assessmentManager = FitnessAssessmentManager.shared
        assessmentManager.hasCompletedAssessment = true
        assessmentManager.currentFitnessLevel = .beginner
        assessmentManager.recommendedGoals = mockData.goals
        assessmentManager.progressTracker = mockData.tracker
        assessmentManager.assessmentWorkout = mockData.assessmentWorkout
        
        // 처리 완료
        isProcessing = false
        showingResult = true
        
        print("✅ 임시 평가 데이터 적용 완료!")
        print("   체력 수준: \(assessmentManager.currentFitnessLevel.rawValue)")
        print("   단기 목표: \(mockData.goals?.shortTermDistance ?? 0)km")
        print("   Zone 2 능력 점수: \(mockData.zone2CapacityScore?.totalScore ?? 0)/100")
        
        // 완료 알림 발송
        NotificationCenter.default.post(
            name: NSNotification.Name("MockAssessmentCompleted"),
            object: mockData
        )
    }
    
    // MARK: - 결과 화면 닫기
    func dismissResult() {
        showingResult = false
        
        // 메인 화면으로 데이터 전파
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: NSNotification.Name("RefreshMainScreen"),
                object: nil
            )
        }
    }
    
    // MARK: - 리셋 (테스트용)
    func resetMockData() {
        isProcessing = false
        showingResult = false
        assessmentWorkout = nil
        zone2CapacityScore = nil
        recommendedGoals = nil
        zone2Profile = nil
        
        // FitnessAssessmentManager도 리셋
        FitnessAssessmentManager.shared.resetAssessment()
        
        print("🔄 임시 평가 데이터 리셋 완료")
    }
}

// MARK: - 임시 평가 시작 뷰
struct MockAssessmentStartView: View {
    @StateObject private var mockHandler = MockAssessmentHandler.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                if mockHandler.isProcessing {
                    // 평가 진행 중 화면
                    VStack(spacing: 30) {
                        ProgressView()
                            .scaleEffect(2)
                            .progressViewStyle(CircularProgressViewStyle(tint: .red))
                        
                        VStack(spacing: 12) {
                            Text("Zone 2 평가 진행 중...")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("최대한 오래 Zone 2 심박수를\n유지하며 달리고 있습니다")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        // 가짜 실시간 데이터
                        MockRealtimeDataView()
                    }
                } else {
                    // 평가 시작 전 화면
                    VStack(spacing: 30) {
                        Image(systemName: "heart.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.red)
                        
                        VStack(spacing: 16) {
                            Text("Zone 2 평가 준비 완료")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text("모든 준비가 완료되었습니다.\n평가를 시작하시겠습니까?")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        VStack(spacing: 16) {
                            Button("Zone 2 평가 시작") {
                                mockHandler.startMockAssessment()
                            }
                            .buttonStyle(.borderedProminent)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            
                            Button("나중에 하기") {
                                dismiss()
                            }
                            .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Zone 2 평가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !mockHandler.isProcessing {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("닫기") {
                            dismiss()
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $mockHandler.showingResult) {
            if let workout = mockHandler.assessmentWorkout,
               let score = mockHandler.zone2CapacityScore,
               let goals = mockHandler.recommendedGoals,
               let profile = mockHandler.zone2Profile {
                
                MockAssessmentResultView(
                    assessmentWorkout: workout,
                    zone2CapacityScore: score,
                    recommendedGoals: goals,
                    zone2Profile: profile
                )
            }
        }
    }
}

// MARK: - 가짜 실시간 데이터 표시
struct MockRealtimeDataView: View {
    @State private var currentTime: TimeInterval = 0
    @State private var currentDistance: Double = 0
    @State private var currentHeartRate: Double = 145
    @State private var currentPace: Double = 375
    @State private var timer: Timer?
    
    var body: some View {
        VStack(spacing: 16) {
            Text("실시간 데이터")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                MockDataCard(title: "시간", value: timeString(from: currentTime), color: .primary)
                MockDataCard(title: "거리", value: "\(String(format: "%.2f", currentDistance))km", color: .green)
                MockDataCard(title: "심박수", value: "\(Int(currentHeartRate)) bpm", color: .red)
                MockDataCard(title: "페이스", value: paceString(from: currentPace), color: .blue)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .onAppear {
            startMockTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func startMockTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            currentTime += 1
            currentDistance = currentTime / 3600 * 7.5 // 7.5km/h 속도
            currentHeartRate = 145 + sin(currentTime * 0.1) * 5 + Double.random(in: -2...2)
            currentPace = 375 + sin(currentTime * 0.05) * 15 + Double.random(in: -5...5)
        }
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func paceString(from pace: Double) -> String {
        let minutes = Int(pace) / 60
        let seconds = Int(pace) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct MockDataCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .padding(8)
        .background(Color.white.opacity(0.8))
        .cornerRadius(8)
    }
}