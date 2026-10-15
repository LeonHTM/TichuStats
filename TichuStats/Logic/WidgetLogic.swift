//
//  WidgetLogic.swift
//  TichuStats
//
//  Created by Leon on 05.06.2026.
//

import WidgetKit

//MARK: WidgetRound used in NetworkService and AppIntents
struct WidgetRound: Codable, Identifiable {
    let id: Int
    let roundOrder: Int
    let tichuPointsTeam1: Int
    let tichuPointsTeam2: Int
    let roundPointsTeam1: Int
    let roundPointsTeam2: Int
    let boolWinRound: Bool

    init(from round: Round) {
        self.id = round.id
        self.roundOrder = round.roundOrder
        self.tichuPointsTeam1 = round.tichuPointsTeam1
        self.tichuPointsTeam2 = round.tichuPointsTeam2
        self.roundPointsTeam1 = round.roundPointsTeam1
        self.roundPointsTeam2 = round.roundPointsTeam2
        self.boolWinRound = round.boolWinRound
    }
}

//MARK: - WidgetGameData used in NetWorkService, AppIntent and FavGameWidget
struct WidgetGameData: Codable {
    let winner: Int?
    var favorite: Bool
    let id: Int
    let date: Date
    let team1Score: Int
    let team2Score: Int
    let rounds: [WidgetRound]
}


