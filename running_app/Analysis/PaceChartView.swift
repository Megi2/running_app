//
//  PaceChartView.swift
//  running_app
//
//  Created by 전진하 on 6/1/25.
//


import SwiftUI
import Charts

struct PaceChartView: View {
    let dataPoints: [RunningDataPoint]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("페이스 변화")
                .font(.headline)
                .fontWeight(.bold)
            
            if #available(iOS 16.0, *) {
                Chart(Array(dataPoints.enumerated()), id: \.offset) { index, point in
                    LineMark(
                        x: .value("시간", index),
                        y: .value("페이스", point.pace / 60) // 분 단위로 변환
                    )
                    .foregroundStyle(.blue)
                }
                .frame(height: 150)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks(position: .bottom)
                }
            } else {
                Text("차트는 iOS 16 이상에서 지원됩니다.")
                    .foregroundColor(.secondary)
                    .frame(height: 150)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
}

struct HeartRateChartView: View {
    let dataPoints: [RunningDataPoint]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("심박수 변화")
                .font(.headline)
                .fontWeight(.bold)
            
            if #available(iOS 16.0, *) {
                Chart(Array(dataPoints.enumerated()), id: \.offset) { index, point in
                    LineMark(
                        x: .value("시간", index),
                        y: .value("심박수", point.heartRate)
                    )
                    .foregroundStyle(.red)
                }
                .frame(height: 150)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks(position: .bottom)
                }
            } else {
                Text("차트는 iOS 16 이상에서 지원됩니다.")
                    .foregroundColor(.secondary)
                    .frame(height: 150)
            }
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
    }
}