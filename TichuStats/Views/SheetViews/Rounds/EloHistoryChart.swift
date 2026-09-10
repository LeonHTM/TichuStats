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
    
    // MARK: - Chart scrolling
    
    @State private var scrollPosition: Date = .now
    
    private let visibleTimeInterval: TimeInterval = 60 * 60 * 24 * 31*3
    private let visiblePointCount = 20
    
    // MARK: - Chart data
    
    private var chartData: [EloPoint] {
        var points: [EloPoint] = []
        var currentElo: Double = 1000.0
        
        if isLoading {
            points.append(
                EloPoint(
                    date: Date.now,
                    elo: 1000.0,
                    gameId: -69420
                )
            )
            
            points.append(
                EloPoint(
                    date: Date.now.addingTimeInterval(86400),
                    elo: 1010.0,
                    gameId: -69421
                )
            )
        } else {
            for entry in network.eloHistory.sorted(
                by: {
                    ($0.changedAt ?? .distantPast)
                    <
                    ($1.changedAt ?? .distantPast)
                }
            ) {
                currentElo += entry.eloChange
                
                if let date = entry.changedAt {
                    points.append(
                        EloPoint(
                            date: date,
                            elo: currentElo,
                            gameId: entry.gameId
                        )
                    )
                }
            }
        }
        
        return points
    }
    
    // MARK: - Marked point
    
    private var markedPoint: EloPoint? {
        guard let markedGameId else {
            return nil
        }
        
        return chartData.first {
            $0.gameId == markedGameId
        }
    }
    
    // MARK: - Y axis
    
    private var yDomain: ClosedRange<Double> {
        let values = chartData.map { $0.elo }
        
        guard
            let minVal = values.min(),
            let maxVal = values.max()
        else {
            return 900...1100
        }
        
        // Prevent a zero-sized range when all Elo values are identical.
        if minVal == maxVal {
            return (minVal - 100)...(maxVal + 100)
        }
        
        let padding = (maxVal - minVal) * 0.1
        
        return (minVal - padding)...(maxVal + padding)
    }
    
    // MARK: - Initial scroll position
    
    private var initialScrollPosition: Date {
        guard let lastDate = chartData.last?.date else {
            return .now
        }
        
        return lastDate.addingTimeInterval(-visibleTimeInterval)
    }
    
    // MARK: - Body
    
    var body: some View {
        Chart(chartData) { point in
            
            // MARK: Line
            
            LineMark(
                x: .value("Date", point.date),
                y: .value("Elo", point.elo)
            )
            .interpolationMethod(.monotone)
            .lineStyle(
                StrokeStyle(lineWidth: 3)
            )
            .foregroundStyle(Color.accent)
            
            
            // MARK: Points
            
            PointMark(
                x: .value("Date", point.date),
                y: .value("Elo", point.elo)
            )
            .symbolSize(40)
            .foregroundStyle(Color.accent)
            
            
            // MARK: Selected / marked game
            
            if let marked = markedPoint {
                
                RuleMark(
                    x: .value("Date", marked.date)
                )
                .foregroundStyle(Color.primary)
                .lineStyle(
                    StrokeStyle(
                        lineWidth: 1,
                        dash: [5]
                    )
                )
                
                PointMark(
                    x: .value("Date", marked.date),
                    y: .value("Elo", marked.elo)
                )
                .foregroundStyle(Color.primary)
                
                //Broken in iOS 27
                /*
                .annotation(position: .top) {
                    Text(
                        String(
                            format: "%.0f",
                            marked.elo
                        )
                    )
                    .font(.caption)
                    .bold()
                    .foregroundStyle(Color.primary)
                }*/
            }
        }
        
        // MARK: Y scale
        
        .chartYScale(
            domain: yDomain
        )
        
        // MARK: Horizontal scrolling
        
        .chartScrollableAxes(.horizontal)
        
        // Approximately one month visible at a time.
        .chartXVisibleDomain(
            length: visibleTimeInterval
        )
        
        // Programmatic scroll position.
        .chartScrollPosition(
            x: $scrollPosition
        )
        
        // MARK: X axis
        
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisTick()
                
                AxisValueLabel(
                    format: .dateTime
                        .month()
                        .day()
                )
                
                AxisGridLine()
            }
        }
        
        // MARK: Y axis
        
        .chartYAxis {
            AxisMarks { _ in
                AxisTick()
                AxisValueLabel()
                AxisGridLine()
            }
        }
        
        // MARK: Layout
        
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
        .padding(.horizontal)
        
        // MARK: Initial position
        
        .onAppear {
            scrollPosition = initialScrollPosition
        }
        
        // MARK: Scroll to selected game
        
        .onChange(of: markedGameId) { _, newGameId in
            scrollToMarkedGame(newGameId)
        }
        
        // MARK: Reload Elo history when games change
        
        .onChange(of: network.games) {
            Task {
                await network.fetchEloHistory(
                    profileId: profileId
                )
            }
        }
        
        // MARK: Initial data load
        
        .task {
            await network.fetchEloHistory(
                profileId: profileId
            )
            
            // Once the data has loaded, put the chart
            // at the most recent month.
            if let lastDate = chartData.last?.date {
                scrollPosition = lastDate
                    .addingTimeInterval(-visibleTimeInterval)
            }
        }
    }
    
    // MARK: - Scroll to marked game
    
    private func scrollToMarkedGame(_ gameId: Int?) {
        guard
            let gameId,
            let marked = chartData.first(where: {
                $0.gameId == gameId
            })
        else {
            return
        }

        let halfVisibleInterval = visibleTimeInterval / 2

        let newScrollPosition = marked.date
            .addingTimeInterval(-halfVisibleInterval)

        var transaction = Transaction()
        transaction.animation = nil

        withTransaction(transaction) {
            scrollPosition = newScrollPosition
        }
    }
}
