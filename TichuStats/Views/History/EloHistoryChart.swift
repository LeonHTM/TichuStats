//
//  EloHistoryChart.swift
//  TichuStats
//
//  Created by Leon on 03.06.2026.
//

import SwiftUI
import Charts

struct EloPoint: Identifiable {
    let id = UUID()
    let date: Date
    let elo: Double
}

struct EloHistoryChartView: View {
    var profileId: Int
    var markedDateId: Date? = nil
    @AppStorage("isLoading") var isLoading: Bool = false

    @ObservedObject private var network = NetworkService.shared

    private var calendar: Calendar { Calendar.current }

    private var chartData: [EloPoint] {
        if isLoading {
            return [
                EloPoint(date: Date.now, elo: 1000.0),
                EloPoint(date: Date.now.addingTimeInterval(86400), elo: 1010.0)
            ]
        }

        //Build the full elo history
        var allPoints: [EloPoint] = []
        var currentElo: Double = 1000.0

        for entry in network.eloHistory.sorted(by: { ($0.changedAt ?? .distantPast) < ($1.changedAt ?? .distantPast) }) {
            currentElo += entry.eloChange
            if let date = entry.changedAt {
                allPoints.append(EloPoint(date: date, elo: currentElo))
            }
        }

        //If all potins are on same day leave them
        let distinctDays = Set(allPoints.map { calendar.startOfDay(for: $0.date) })
        guard distinctDays.count > 1 else { return allPoints }

        // Otherwise keep only the most recent point of each day
        var latestPerDay: [Date: EloPoint] = [:]
        for point in allPoints {
            latestPerDay[calendar.startOfDay(for: point.date)] = point
        }

        return latestPerDay.values.sorted { $0.date < $1.date }
    }

    //marked day is most recent for date
    private var markedPoint: EloPoint? {
        guard let markedDateId else { return nil }
        return chartData.last(where: { calendar.isDate($0.date, inSameDayAs: markedDateId) })
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
        if isLoading {
            HStack {
                Spacer()
                VStack(spacing: 10) {
                    ProgressView()
                    Text(String(localized: "history.loading"))
                }
                Spacer()
            }
            .foregroundStyle(.secondary)
        } else {
            Chart(chartData) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Elo", point.elo)
                )
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
            .onChange(of: network.games) {
                Task {
                    await network.fetchEloHistory(profileId: profileId)
                }
            }
            .task {
                await network.fetchEloHistory(profileId: profileId)
            }
        }
    }
}
