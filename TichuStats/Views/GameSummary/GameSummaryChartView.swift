//
// GameSummaryChartView.swift
//  TichuStats
//
//  Created by Leon on 02.05.2026.
//

import SwiftUI
import Charts

struct ScorePoint: Identifiable {
    let round: Int
    let value: Int
    let team: String

    var id: String { "\(team)-\(round)" }
}

struct GameSummaryChartView: View {
    var currentGameId: Int?

    @ObservedObject private var network = NetworkService.shared

    // Only rounds that count toward the win (boolWinRound == true), ordered
    private var winRounds: [Round] {
        (network.roundsByGame[currentGameId ?? 0] ?? [])
            .filter { $0.gameId == currentGameId && $0.boolWinRound }
            .sorted { $0.roundOrder < $1.roundOrder }
    }

    // MARK: - Build cumulative score
    private func cumulativePoints(forTeam teamNumber: Int, rounds: [Round]) -> [Int] {
        var list: [Int] = [0]
        var counter = 0
        for round in rounds {
            if teamNumber == 1 {
                counter += round.tichuPointsTeam1 + round.roundPointsTeam1
            } else {
                counter += round.tichuPointsTeam2 + round.roundPointsTeam2
            }
            list.append(counter)
        }
        return list
    }

    // MARK: - Chart Data
    private var chartData: [ScorePoint] {
        let rounds = winRounds
        let team1Points = cumulativePoints(forTeam: 1, rounds: rounds)
        let team2Points = cumulativePoints(forTeam: 2, rounds: rounds)

        let team1Data = team1Points.enumerated().map {
            ScorePoint(round: $0.offset, value: $0.element, team: "Team 1")
        }

        let team2Data = team2Points.enumerated().map {
            ScorePoint(round: $0.offset, value: $0.element, team: "Team 2")
        }

        return team1Data + team2Data
    }

    // MARK: - Y-Axis Domain
    private func yDomain(for data: [ScorePoint]) -> ClosedRange<Int> {
        let values = data.map { $0.value }
        guard let minVal = values.min(), let maxVal = values.max() else {
            return 0...100
        }
        // Avoid a zero-height domain (e.g. all scores still 0)
        return minVal == maxVal ? minVal...(maxVal + 100) : minVal...maxVal
    }

    var body: some View {
        let data = chartData

        Chart(data) { point in
            LineMark(
                x: .value("Round", point.round),
                y: .value("Score", point.value)
            )
            .interpolationMethod(.catmullRom)
            .lineStyle(StrokeStyle(lineWidth: 3))
            .foregroundStyle(by: .value("Team", point.team))

            PointMark(
                x: .value("Round", point.round),
                y: .value("Score", point.value)
            )
            .symbolSize(40)
            .foregroundStyle(by: .value("Team", point.team))
        }
        .chartYScale(domain: yDomain(for: data))
        .chartForegroundStyleScale([
            "Team 1": .accent,
            "Team 2": .primary
        ])
        .chartXAxis {
            AxisMarks(values: .stride(by: 1)) { _ in
                AxisTick()
                AxisValueLabel()
            }
        }
        .chartYAxis {
            AxisMarks { _ in
                AxisTick()
                AxisValueLabel()
                AxisGridLine()
            }
        }
        .animation(.easeInOut, value: data.count)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal)
    }
}
