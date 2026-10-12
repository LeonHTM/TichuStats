//
//  EloHistoryChart.swift
//  Tichu
//
//  Created by Leon on 03.06.2026.
//

import SwiftUI
import Charts

struct EloPoint: Identifiable {
    let id = UUID()
    let date: Date
    let elo: Double
    let gameId: Int?
}

struct EloHistoryChartView: View {
    var profileId: Int
    var markedGameId: Int? = nil
    @AppStorage("isLoading") var isLoading: Bool = false

    @ObservedObject private var network = NetworkService.shared

    private var chartData: [EloPoint] {
        var points: [EloPoint] = []
        var currentElo: Double = 1000.0
        
        if isLoading{
                points.append(EloPoint(date:Date.now,elo:1000.0,gameId:-69420))
                points.append(EloPoint(date:Date.now.addingTimeInterval(86400),elo:1010.0,gameId:-69421))
        }else{
            for entry in network.eloHistory.sorted(by: { ($0.changedAt ?? .distantPast) < ($1.changedAt ?? .distantPast) }) {
                currentElo += entry.eloChange
                if let date = entry.changedAt {
                    points.append(EloPoint(date: date, elo: currentElo, gameId: entry.gameId))
                }
            }
        }

        return points
    }

    private var markedPoint: EloPoint? {
        guard let markedGameId else { return nil }
        return chartData.first(where: { $0.gameId == markedGameId })
    }

    private var yDomain: ClosedRange<Double> {
        let values = chartData.map { $0.elo }
        guard let minVal = values.min(), let maxVal = values.max() else {
            return 900...1100
        }
        let padding = (maxVal - minVal) * 0.1
        return (minVal - padding)...(maxVal + padding)
    }

    var body: some View {
        Chart(chartData) { point in
            LineMark(
                x: .value("Date", point.date),
                y: .value("Elo", point.elo)
            )
            //.interpolationMethod(.catmullRom)
            .interpolationMethod(.monotone)
            .lineStyle(StrokeStyle(lineWidth: 3))
            .foregroundStyle(Color.accent)

            PointMark(
                x: .value("Date", point.date),
                y: .value("Elo", point.elo)
            )
            .symbolSize(40)
            .foregroundStyle(Color.accent)

            if let marked = markedPoint {
                RuleMark(x: .value("Date", marked.date))
                    .foregroundStyle(Color.primary)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))

                PointMark(
                    x: .value("Date", marked.date),
                    y: .value("Elo", marked.elo)
                )
                //.symbolSize(150)
                .foregroundStyle(Color.primary)
                .annotation(position: .top) {
                    Text(String(format: "%.0f", marked.elo))
                        .font(.caption)
                        .bold()
                        .foregroundStyle(Color.primary)
                }
            }
        }
        .chartYScale(domain: yDomain)
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisTick()
                AxisValueLabel(format: .dateTime.month().day())
                AxisGridLine()
            }
        }
        .chartYAxis {
            AxisMarks { _ in
                AxisTick()
                AxisValueLabel()
                AxisGridLine()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal)
        .onChange(of:network.games){
            Task{
                await network.fetchEloHistory(profileId: profileId)
            }
        }
        .task {
            await network.fetchEloHistory(profileId: profileId)
        }
    }
}
