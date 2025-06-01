import SwiftUI

struct ProfileSetupView: View {
    @StateObject private var profileManager = UserProfileManager.shared
    @State private var currentProfile = UserProfile()
    @State private var currentStep = 0
    
    private let totalSteps = 5
    
    var body: some View {
        NavigationView {
            ZStack {
                // 배경 그라데이션
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 진행률 표시
                    ProgressHeaderView(currentStep: currentStep, totalSteps: totalSteps)
                    
                    // 단계별 콘텐츠
                    TabView(selection: $currentStep) {
                        WelcomeStepView()
                            .tag(0)
                        
                        GenderStepView(profile: $currentProfile)
                            .tag(1)
                        
                        AgeStepView(profile: $currentProfile)
                            .tag(2)
                        
                        PhysicalStepView(profile: $currentProfile)
                            .tag(3)
                        
                        SummaryStepView(profile: currentProfile)
                            .tag(4)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .animation(.easeInOut, value: currentStep)
                    
                    // 네비게이션 버튼
                    NavigationButtonsView(
                        currentStep: $currentStep,
                        totalSteps: totalSteps,
                        profile: currentProfile,
                        onComplete: completeSetup
                    )
                }
                
                // 완료 화면 오버레이
                if profileManager.showingCompletionView {
                    CompletionOverlayView(profile: currentProfile)
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private func completeSetup() {
        profileManager.updateProfile(currentProfile)
    }
}

// MARK: - 완료 화면 오버레이
struct CompletionOverlayView: View {
    let profile: UserProfile
    @StateObject private var profileManager = UserProfileManager.shared
    
    var body: some View {
        ZStack {
            // 반투명 배경
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            // 완료 카드
            VStack(spacing: 30) {
                Spacer()
                
                VStack(spacing: 30) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.green)
                    
                    VStack(spacing: 16) {
                        Text("설정 완료!")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("이제 개인화된 러닝 분석을\n시작할 수 있습니다")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    // 설정 요약
                    VStack(spacing: 8) {
                        Text("설정된 정보")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 20) {
                            VStack {
                                Text("\(profile.age)세")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                Text("나이")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack {
                                Text("\(Int(profile.weight))kg")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                Text("몸무게")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack {
                                Text("\(Int(profile.maxHeartRate))")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.red)
                                Text("최대심박수")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    
                    Button("시작하기") {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            profileManager.completeProfileSetup()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .font(.headline)
                    .padding(.horizontal, 40)
                }
                .padding(30)
                .background(Color(.systemBackground))
                .cornerRadius(20)
                .shadow(radius: 20)
                
                Spacer()
            }
            .padding()
        }
        .transition(.opacity)
    }
}

// MARK: - 진행률 헤더
struct ProgressHeaderView: View {
    let currentStep: Int
    let totalSteps: Int
    @StateObject private var profileManager = UserProfileManager.shared
    
    var progress: Double {
        Double(currentStep) / Double(totalSteps - 1)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Button("건너뛰기") {
                    // 기본값으로 설정하고 완료 화면 표시
                    var defaultProfile = UserProfile()
                    defaultProfile.isCompleted = true
                    profileManager.updateProfile(defaultProfile)
                }
                .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(currentStep + 1) / \(totalSteps)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .scaleEffect(y: 2)
        }
        .padding()
    }
}

// MARK: - 환영 단계
struct WelcomeStepView: View {
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "figure.run.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            VStack(spacing: 16) {
                Text("10km 러닝에 오신 것을\n환영합니다!")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("개인 맞춤 분석을 위해\n기본 정보를 입력해 주세요")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                FeatureRow(icon: "heart.fill", title: "정확한 심박수 존 계산", color: .red)
                FeatureRow(icon: "flame.fill", title: "실시간 칼로리 소모량", color: .orange)
                FeatureRow(icon: "chart.line.uptrend.xyaxis", title: "개인화된 운동 분석", color: .green)
                FeatureRow(icon: "target", title: "맞춤형 목표 설정", color: .blue)
            }
            .padding()
            .background(Color.white.opacity(0.8))
            .cornerRadius(16)
            
            Spacer()
        }
        .padding()
    }
}

struct FeatureRow: View {
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

// MARK: - 성별 선택 단계
struct GenderStepView: View {
    @Binding var profile: UserProfile
    
    var body: some View {
        StepContainerView(
            title: "성별을 선택해 주세요",
            subtitle: "성별에 따른 최대심박수와\n칼로리 소모량을 정확히 계산합니다"
        ) {
            VStack(spacing: 20) {
                ForEach(Gender.allCases, id: \.self) { gender in
                    SelectionCard(
                        icon: gender.icon,
                        title: gender.rawValue,
                        isSelected: profile.gender == gender,
                        color: gender.color
                    ) {
                        profile.gender = gender
                    }
                }
            }
        }
    }
}

// MARK: - 나이 입력 단계 (피커 휠 방식)
struct AgeStepView: View {
    @Binding var profile: UserProfile
    
    var body: some View {
        StepContainerView(
            title: "나이를 선택해 주세요",
            subtitle: "최대심박수 계산을 위해 필요합니다"
        ) {
            VStack(spacing: 30) {
                // 현재 선택된 나이 크게 표시
                Text("\(profile.age)세")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.blue)
                
                // 피커 휠
                Picker("나이", selection: $profile.age) {
                    ForEach(15...80, id: \.self) { age in
                        Text("\(age)세")
                            .tag(age)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(height: 120)
                .padding()
                .background(Color.white.opacity(0.8))
                .cornerRadius(12)
                
                // 계산된 최대심박수 표시
                VStack(spacing: 8) {
                    Text("예상 최대심박수")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(profile.maxHeartRate)) bpm")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
}

// MARK: - 신체 정보 단계 (숫자 입력만)
struct PhysicalStepView: View {
    @Binding var profile: UserProfile
    @State private var weightText: String = ""
    @State private var heightText: String = ""
    @FocusState private var focusedField: Field?
    
    enum Field {
        case weight, height
    }
    
    var body: some View {
        StepContainerView(
            title: "신체 정보를 입력해 주세요",
            subtitle: "정확한 칼로리 소모량 계산을 위해\n몸무게와 키가 필요합니다"
        ) {
            VStack(spacing: 25) {
                // 몸무게 입력
                SimpleInputCard(
                    title: "몸무게",
                    text: $weightText,
                    unit: "kg",
                    icon: "scalemass.fill",
                    color: .green,
                    currentValue: Int(profile.weight),
                    focusedField: $focusedField,
                    fieldType: .weight,
                    range: 30...150
                ) { newValue in
                    if let weight = Double(newValue), weight >= 30 && weight <= 150 {
                        profile.weight = weight
                    }
                }
                
                // 키 입력
                SimpleInputCard(
                    title: "키",
                    text: $heightText,
                    unit: "cm",
                    icon: "figure.stand",
                    color: .blue,
                    currentValue: Int(profile.height),
                    focusedField: $focusedField,
                    fieldType: .height,
                    range: 140...220
                ) { newValue in
                    if let height = Double(newValue), height >= 140 && height <= 220 {
                        profile.height = height
                    }
                }
                
                // BMI 표시
                BMIDisplayView(bmi: profile.bmi, category: profile.bmiCategory)
            }
        }
        .onAppear {
            weightText = String(Int(profile.weight))
            heightText = String(Int(profile.height))
        }
        .onTapGesture {
            focusedField = nil
        }
    }
}

// MARK: - 간단한 입력 카드
struct SimpleInputCard: View {
    let title: String
    @Binding var text: String
    let unit: String
    let icon: String
    let color: Color
    let currentValue: Int
    @FocusState.Binding var focusedField: PhysicalStepView.Field?
    let fieldType: PhysicalStepView.Field
    let range: ClosedRange<Double>
    let onValueChange: (String) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // 제목과 현재 값
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.headline)
                
                Spacer()
                
                Text("\(currentValue)\(unit)")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
            }
            
            // 입력 필드
            VStack(spacing: 8) {
                HStack {
                    TextField("\(title) 입력", text: $text)
                        .keyboardType(.numberPad)
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .focused($focusedField, equals: fieldType)
                        .onChange(of: text) { newValue in
                            onValueChange(newValue)
                        }
                    
                    Text(unit)
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .frame(width: 30)
                }
                
                // 유효 범위 표시
                Text("\(Int(range.lowerBound)) - \(Int(range.upperBound))\(unit)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.white.opacity(0.8))
        .cornerRadius(12)
    }
}

struct BMIDisplayView: View {
    let bmi: Double
    let category: String
    
    var bmiColor: Color {
        switch bmi {
        case ..<18.5: return .blue
        case 18.5..<25: return .green
        case 25..<30: return .orange
        default: return .red
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text("BMI")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 16) {
                Text(String(format: "%.1f", bmi))
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(bmiColor)
                
                Text(category)
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(bmiColor.opacity(0.2))
                    .foregroundColor(bmiColor)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(bmiColor.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - 요약 단계
struct SummaryStepView: View {
    let profile: UserProfile
    
    var body: some View {
        StepContainerView(
            title: "설정을 확인해 주세요",
            subtitle: "입력하신 정보를 바탕으로\n개인화된 분석을 제공합니다"
        ) {
            VStack(spacing: 16) {
                SummaryRow(title: "성별", value: profile.gender.rawValue, icon: "person.fill")
                SummaryRow(title: "나이", value: "\(profile.age)세", icon: "calendar")
                SummaryRow(title: "몸무게", value: "\(Int(profile.weight))kg", icon: "scalemass.fill")
                SummaryRow(title: "키", value: "\(Int(profile.height))cm", icon: "figure.stand")
                
                Divider()
                
                // 계산된 정보
                VStack(spacing: 12) {
                    Text("계산된 정보")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack {
                        VStack {
                            Text("\(Int(profile.maxHeartRate))")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                            Text("최대심박수")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        
                        VStack {
                            Text(String(format: "%.1f", profile.bmi))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                            Text("BMI")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        
                        VStack {
                            Text("\(Int(profile.caloriesPerMinute(pace: 360)))")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                            Text("칼로리/분*")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    
                    Text("* 6분/km 페이스 기준")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
}

struct SummaryRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 공통 컴포넌트들
struct StepContainerView<Content: View>: View {
    let title: String
    let subtitle: String
    let content: Content
    
    init(title: String, subtitle: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 12) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top)
            
            content
            
            Spacer()
        }
        .padding()
    }
}

struct SelectionCard: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : color)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(isSelected ? color : Color.white.opacity(0.8))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color, lineWidth: isSelected ? 0 : 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct NavigationButtonsView: View {
    @Binding var currentStep: Int
    let totalSteps: Int
    let profile: UserProfile
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
                .disabled(!canProceed)
            } else {
                Button("완료") {
                    onComplete()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case 1: return true // 성별은 기본값 있음
        case 2: return profile.age >= 15 && profile.age <= 80
        case 3: return profile.weight >= 30 && profile.height >= 140
        default: return true
        }
    }
}

struct CompletionView: View {
    let profile: UserProfile
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            VStack(spacing: 16) {
                Text("설정 완료!")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("이제 개인화된 러닝 분석을\n시작할 수 있습니다")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("시작하기") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .font(.headline)
            
            Spacer()
        }
        .padding()
    }
}
