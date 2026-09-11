//
//  AppIntent.swift
//  TichuWidgets
//
//  Created by Leon on 03.06.2026.
//

import WidgetKit
import AppIntents

// MARK: - Stats

enum PlayerStat: String, AppEnum {
    case elo
    case winnerPercentage
    case averagePlacement
    case tichuMaster
    case visionary
    case addict
    case teamplayer
    case announcer
    case saboteur
    case gambler
    case bigGambler
    case pinguGambler
    case bomber

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: LocalizedStringResource("statistics.stat.chooseStat"))

    static var caseDisplayRepresentations: [PlayerStat: DisplayRepresentation] = [
        .elo:              DisplayRepresentation(title: LocalizedStringResource("statistics.stat.elo")),
        .winnerPercentage: DisplayRepresentation(title: LocalizedStringResource("statistics.stat.winnerPercentage")),
        .averagePlacement: DisplayRepresentation(title: LocalizedStringResource("statistics.stat.climber")),
        .tichuMaster:      DisplayRepresentation(title: LocalizedStringResource("statistics.stat.tichuMaster")),
        .visionary:        DisplayRepresentation(title: LocalizedStringResource("statistics.stat.visionary")),
        .addict:           DisplayRepresentation(title: LocalizedStringResource("statistics.stat.addict")),
        .teamplayer:       DisplayRepresentation(title: LocalizedStringResource("statistics.stat.teamPlayer")),
        .announcer:        DisplayRepresentation(title: LocalizedStringResource("statistics.stat.announcer")),
        .saboteur:         DisplayRepresentation(title: LocalizedStringResource("statistics.stat.saboteur")),
        .gambler:          DisplayRepresentation(title: LocalizedStringResource("statistics.stat.gambler")),
        .bigGambler:       DisplayRepresentation(title: LocalizedStringResource("statistics.stat.bigGambler")),
        .pinguGambler:     DisplayRepresentation(title: LocalizedStringResource("statistics.stat.pinguGambler")),
        .bomber:           DisplayRepresentation(title: LocalizedStringResource("statistics.stat.bomber"))
    ]
}

enum PlayerStatsTimeFrameD: String, AppEnum {
    case allTime
    case year
    case month
    case week
    case day

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: LocalizedStringResource("statistics.timeframe.chooseTimeframe"))

    static var caseDisplayRepresentations: [PlayerStatsTimeFrameD: DisplayRepresentation] = [
        .allTime: DisplayRepresentation(title: LocalizedStringResource("statistics.timeframe.allTime")),
        .year:    DisplayRepresentation(title: LocalizedStringResource("statistics.timeframe.year")),
        .month:   DisplayRepresentation(title: LocalizedStringResource("statistics.timeframe.month")),
        .week:    DisplayRepresentation(title: LocalizedStringResource("statistics.timeframe.week")),
        .day:     DisplayRepresentation(title: LocalizedStringResource("statistics.timeframe.day")),
    ]
}

struct GraphConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource {"statistics.title"}

    @Parameter(title: LocalizedStringResource ("statistics.title.statistic"), default: .elo)
    var stat: PlayerStat?

    @Parameter(title: LocalizedStringResource("statistics.title.timeframe"), default: .allTime)
    var timeframe: PlayerStatsTimeFrameD?
}

// MARK: - Shared Models

struct WidgetRound: Codable, Identifiable {
    let id: Int
    let roundOrder: Int
    let tichuPointsTeam1: Int
    let tichuPointsTeam2: Int
    let roundPointsTeam1: Int
    let roundPointsTeam2: Int
    let boolWinRound: Bool
}

struct WidgetGameData: Codable {
    let winner: Int?
    var favorite: Bool
    let id: Int
    let date: Date
    let team1Score: Int
    let team2Score: Int
    let rounds: [WidgetRound]
}

// MARK: - Game Entity

struct GameEntity: AppEntity {
    let winner: Int?
    let id: Int
    let date: Date
    let team1Score: Int
    let team2Score: Int
    let favorite: Bool

    static var typeDisplayRepresentation: TypeDisplayRepresentation = TypeDisplayRepresentation(name: LocalizedStringResource("game.chooseGame"))
    static var defaultQuery = GameEntityQuery()

    var displayRepresentation: DisplayRepresentation {
        let formatted = date.formatted(date: .numeric, time: .omitted)
        let title = favorite
            ? "\(formatted) (\(team1Score) : \(team2Score)) ★"
            : "\(formatted) (\(team1Score) : \(team2Score))"
        return DisplayRepresentation(
            title: "\(title)",
            /*image: favorite ? .init(systemName: "star.fill") : nil*/
        )
    }
}

struct GameEntityQuery: EntityQuery {
    private func loadGames() -> [GameEntity] {
        guard let data = UserDefaults(suiteName: "group.com.drakynem.tichu")?.data(forKey: "widgetGames"),
              let games = try? JSONDecoder().decode([WidgetGameData].self, from: data) else { return [] }
        return games.map {
            GameEntity(winner: $0.winner,id: $0.id, date: $0.date, team1Score: $0.team1Score, team2Score: $0.team2Score, favorite: $0.favorite)
        }
    }

    func entities(for identifiers: [Int]) async throws -> [GameEntity] {
        loadGames().filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [GameEntity] {
        loadGames().filter{$0.favorite == true}.filter{$0.winner != nil}//.sorted { $0.favorite && !$1.favorite }
    }
}

// MARK: - Game Intent

struct GameConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource {"game.title"}
    //static var description: IntentDescription {"game.widgetDescription"}

    @Parameter(title: LocalizedStringResource("game.title.game"))
    var game: GameEntity?
}
