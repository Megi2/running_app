//
//  WorkoutHistoryView.swift
//  running_app
//
//  Created by 전진하 on 6/1/25.
//


import SwiftUI

struct WorkoutHistoryView: View {
    @EnvironmentObject var dataManager: RunningDataManager
    
    var body: some View {
        NavigationView {
            List {
                ForEach(dataManager.workouts) { workout in
                    NavigationLink(destination: WorkoutDetailView(workout: workout)) {
                        WorkoutRowView(workout: workout)
                    }
                }
            }
            .navigationTitle("운동 기록")
        }
    }
}

struct WorkoutRowView: View {
    let workout: WorkoutSummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(workout.date, style: .date)
                    .font(.headline)
                Spacer()
                Text(String(format: "%.2f km", workout.distance))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            }
            
            HStack {
                Text(timeString(from: workout.duration))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("평균 페이스: \(paceString(from: workout.averagePace))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(workout.averageHeartRate)) bpm")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func paceString(from pace: Double) -> String {
        if pace == 0 { return "--:--" }
        let minutes = Int(pace) / 60
        let seconds = Int(pace) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}