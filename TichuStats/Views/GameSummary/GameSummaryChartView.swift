//
// GameSummaryChartView.swift
//  Tichu
//
//  Created by Leon on 02.05.2026.
//

import SwiftUI
import Charts

struct ScorePoint: Identifiable {
    let id = UUID()
    let round: Int
    let value: Int
    let team: String
}


struct GameSummaryChartView: View {
    var currentGameId: Int?

    // Only rounds that count toward the win (boolWinRound == true), ordered
   
    
    private var currentGame: Game? {
        NetworkService.shared.games.first(where:{$0.id == currentGameId})
        }
    
    private var rounds: [Round]? {
        NetworkService.shared.roundsByGame[currentGameId ?? 0]
    }
    
    private var winRounds: [Round] {
        rounds ?? []
            .filter { $0.gameId == currentGameId && $0.boolWinRound }
            .sorted { $0.roundOrder < $1.roundOrder }
    }
    
    // MARK: - Build cumulative score
    private func cumulativePoints(forTeam teamNumber: Int) -> [Int] {
        var list: [Int] = [0]
        var counter = 0
        for round in winRounds {
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
        let team1Points = cumulativePoints(forTeam: 1)
        let team2Points = cumulativePoints(forTeam: 2)

        let team1Data = team1Points.enumerated().map {
            ScorePoint(round: $0.offset, value: $0.element, team: "Team 1")
        }

        let team2Data = team2Points.enumerated().map {
            ScorePoint(round: $0.offset, value: $0.element, team: "Team 2")
        }

        return team1Data + team2Data
    }

    // MARK: - Y-Axis Domain
    private var yDomain: ClosedRange<Int> {
        let values = chartData.map { $0.value }
        guard let minVal = values.min(), let maxVal = values.max() else {
            return 0...100
        }
        return minVal...maxVal
    }

    var body: some View {
        Chart(chartData) { point in

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
        .chartYScale(domain: yDomain)
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal)
    }
}


