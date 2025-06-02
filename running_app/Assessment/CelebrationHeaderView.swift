import SwiftUI

struct CelebrationHeaderView: View {
    let workout: WorkoutSummary
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.red)
                .symbolEffect(.bounce)
            
            Text("Zone 2 평가 완료!")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Zone 2 심박수 범위에서 최대한 달려주셨습니다")
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // 기본 운동 정보
            HStack(spacing: 30) {
                VStack {
                    Text("\(String(format: "%.2f", workout.distance))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Text("km")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text(timeString(from: workout.duration))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("시간")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(Int(workout.averageHeartRate))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    Text("평균 심박수")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
