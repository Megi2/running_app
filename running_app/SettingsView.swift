import SwiftUI

struct SettingsView: View {
    @State private var targetDistance: Double = 10.0
    @State private var targetPace: String = "6:00"
    @State private var paceWarningEnabled = true
    @State private var heartRateWarningEnabled = true
    
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
                
                Section("분석 엔진") {
                    LocalAnalysisStatusView()
                }
                
                Section("데이터") {
                    Button("데이터 내보내기") {
                        // 데이터 내보내기 기능
                    }
                    
                    Button("데이터 초기화") {
                        // 데이터 초기화 기능
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
                        Text("개발자")
                        Spacer()
                        Text("JJH")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("설정")
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
            
            HStack {
                Text("오프라인 작동")
                Spacer()
                Text("✓")
                    .foregroundColor(.green)
            }
            .font(.caption)
            
            HStack {
                Text("실시간 분석")
                Spacer()
                Text("✓")
                    .foregroundColor(.green)
            }
            .font(.caption)
            
            HStack {
                Text("개인정보 보호")
                Spacer()
                Text("✓")
                    .foregroundColor(.green)
            }
            .font(.caption)
        }
    }
}
 
