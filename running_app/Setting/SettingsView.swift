import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var dataManager: RunningDataManager
    @StateObject private var profileManager = UserProfileManager.shared
    
    @State private var targetDistance: Double = 10.0
    @State private var targetPace: String = "6:00"
    @State private var paceWarningEnabled = true
    @State private var heartRateWarningEnabled = true
    @State private var showingDeleteAlert = false
    @State private var showingExportSheet = false
    @State private var showingProfileSetup = false
    @State private var exportedData: Data?
    
    var body: some View {
        NavigationView {
            Form {
                Section("목표 설정") {
                    HStack {
                        Text("목표 거리")
                        Spacer()
                        Text("\(String(format: "%.1f", targetDistance))km")
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(value: $targetDistance, in: 1...15, step: 0.5)
                    
                    HStack {
                        Text("목표 페이스")
                        Spacer()
                        TextField("6:00", text: $targetPace)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("알림 설정") {
                    Toggle("페이스 경고", isOn: $paceWarningEnabled)
                    Toggle("심박수 알림", isOn: $heartRateWarningEnabled)
                }
                
                Section("사용자 정보") {
                    if profileManager.isProfileCompleted {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("사용자 프로필")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Spacer()
                                Button("수정") {
                                    showingProfileSetup = true
                                }
                                .font(.caption)
                                .buttonStyle(.bordered)
                            }
                            
                            let profile = profileManager.userProfile
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(profile.gender.rawValue), \(profile.age)세")
                                Text("\(Int(profile.weight))kg, \(Int(profile.height))cm")
                                Text("최대심박수: \(Int(profile.maxHeartRate)) bpm")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                    } else {
                        Button("사용자 정보 설정") {
                            showingProfileSetup = true
                        }
                    }
                }
                
                Section("분석 엔진") {
                    LocalAnalysisStatusView()
                }
                
                Section("데이터 관리") {
                    DataStatsView()
                        .environmentObject(dataManager)
                    
                    Button("데이터 새로고침") {
                        dataManager.refreshData()
                    }
                    
                    Button("데이터 내보내기") {
                        exportData()
                    }
                    
                    Button("데이터 초기화") {
                        showingDeleteAlert = true
                    }
                    .foregroundColor(.red)
                }
                
                Section("정보") {
                    HStack {
                        Text("앱 버전")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("분석 엔진")
                        Spacer()
                        Text("로컬 AI")
                            .foregroundColor(.green)
                    }
                    
                    HStack {
                        Text("저장 방식")
                        Spacer()
                        Text("Core Data")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                    
                    HStack {
                        Text("개발자")
                        Spacer()
                        Text("JJH")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("설정")
        }
        .alert("데이터 초기화", isPresented: $showingDeleteAlert) {
            Button("취소", role: .cancel) { }
            Button("삭제", role: .destructive) {
                dataManager.deleteAllWorkouts()
            }
        } message: {
            Text("모든 운동 기록이 삭제됩니다. 이 작업은 되돌릴 수 없습니다.")
        }
        .sheet(isPresented: $showingExportSheet) {
            if let data = exportedData {
                ExportDataView(data: data)
            }
        }
        .sheet(isPresented: $showingProfileSetup) {
            ProfileSetupView()
                .environmentObject(profileManager)
        }
    }
    
    private func exportData() {
        if let data = dataManager.exportData() {
            exportedData = data
            showingExportSheet = true
        }
    }
}

struct DataStatsView: View {
    @EnvironmentObject var dataManager: RunningDataManager
    
    var body: some View {
        let stats = dataManager.getDataStats()
        
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("저장된 운동")
                Spacer()
                Text("\(stats.workoutCount)개")
                    .foregroundColor(.blue)
            }
            
            HStack {
                Text("총 누적 거리")
                Spacer()
                Text(String(format: "%.1f km", stats.totalDistance))
                    .foregroundColor(.green)
            }
            
            if let oldestDate = stats.oldestDate {
                HStack {
                    Text("첫 기록")
                    Spacer()
                    Text(oldestDate, style: .date)
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            
            HStack {
                Text("저장 상태")
                Spacer()
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("Core Data")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
    }
}

struct LocalAnalysisStatusView: View {
    @StateObject private var analysisEngine = LocalAnalysisEngine()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("로컬 AI 분석")
                Spacer()
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("활성화됨")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            Text("실시간 페이스 안정성, 효율성, 케이던스 최적화 분석")
                .font(.caption)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 4) {
                FeatureStatusRow(title: "오프라인 작동", isEnabled: true)
                FeatureStatusRow(title: "실시간 분석", isEnabled: true)
                FeatureStatusRow(title: "개인정보 보호", isEnabled: true)
                FeatureStatusRow(title: "로컬 저장", isEnabled: true)
            }
        }
    }
}

struct FeatureStatusRow: View {
    let title: String
    let isEnabled: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption2)
            Spacer()
            Text(isEnabled ? "✓" : "✗")
                .foregroundColor(isEnabled ? .green : .red)
                .font(.caption2)
        }
    }
}

struct ExportDataView: View {
    let data: Data
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
                
                Text("데이터 내보내기")
                    .font(.headline)
                
                Text("운동 데이터가 JSON 형식으로 준비되었습니다.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("포함된 정보:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("• 모든 운동 기록")
                    Text("• 상세 데이터 포인트")
                    Text("• 내보내기 날짜")
                    Text("• 앱 버전 정보")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                ShareLink(
                    item: data,
                    preview: SharePreview("러닝 데이터", image: Image(systemName: "figure.run"))
                ) {
                    Label("공유하기", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
            }
            .padding()
            .navigationTitle("데이터 내보내기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("완료") {
                        dismiss()
                    }
                }
            }
        }
    }
}
