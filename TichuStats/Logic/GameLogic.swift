//
//  GameLogic.swift
//  Tichu
//
//  Created by Leon on 27.04.2026.
//

import SwiftUI
import Foundation

//MARK: - Struct Game
nonisolated struct Game: Identifiable, Decodable, Equatable {
    //MARK: Vars
    var favorite: Bool = false
    let id: Int
    var date: Date

    var target: Int
    var allowPingus: Bool

    var team1Player1Id: Int?
    var team1Player2Id: Int?
    var team2Player1Id: Int?
    var team2Player2Id: Int?

    var guest2Name: String?
    var guest3Name: String?
    var guest4Name: String?

    var currentPointsTeam1: Int
    var currentPointsTeam2: Int

    var winner: Int?
    var calculated: Bool = false
    
    //MARK: CodingKeys
    enum CodingKeys: String, CodingKey {
        case favorite
        case id, date, target, allowPingus
        case team1Player1Id, team1Player2Id
        case team2Player1Id, team2Player2Id
        case guest2Name, guest3Name, guest4Name
        case currentPointsTeam1, currentPointsTeam2
        case winner
        case calculated
    }

    //MARK: Decoder
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        favorite           = try container.decodeIfPresent(Bool.self, forKey: .favorite)          ?? false
        id                 = try container.decode(Int.self,           forKey: .id)
        date               = try container.decode(Date.self,          forKey: .date)
        target             = try container.decode(Int.self,           forKey: .target)
        allowPingus        = try container.decode(Bool.self,          forKey: .allowPingus)
        team1Player1Id     = try container.decodeIfPresent(Int.self,  forKey: .team1Player1Id)
        team1Player2Id     = try container.decodeIfPresent(Int.self,  forKey: .team1Player2Id)
        team2Player1Id     = try container.decodeIfPresent(Int.self,  forKey: .team2Player1Id)
        team2Player2Id     = try container.decodeIfPresent(Int.self,  forKey: .team2Player2Id)
        guest2Name         = try container.decodeIfPresent(String.self, forKey: .guest2Name)
        guest3Name         = try container.decodeIfPresent(String.self, forKey: .guest3Name)
        guest4Name         = try container.decodeIfPresent(String.self, forKey: .guest4Name)
        currentPointsTeam1 = try container.decode(Int.self,           forKey: .currentPointsTeam1)
        currentPointsTeam2 = try container.decode(Int.self,           forKey: .currentPointsTeam2)
        winner             = try container.decodeIfPresent(Int.self,  forKey: .winner)
        calculated         = try container.decodeIfPresent(Bool.self, forKey: .calculated) ?? false
    }

    //MARK: Init
    init(
        favorite: Bool = false,
        id: Int,
        date: Date,
        target: Int,
        allowPingus: Bool,
        team1Player1Id: Int? = nil,
        team1Player2Id: Int? = nil,
        team2Player1Id: Int? = nil,
        team2Player2Id: Int? = nil,
        guest2Name: String? = nil,
        guest3Name: String? = nil,
        guest4Name: String? = nil,
        currentPointsTeam1: Int,
        currentPointsTeam2: Int,
        winner: Int? = nil,
        calculated: Bool = false
    ) {
        self.favorite           = favorite
        self.id                 = id
        self.date               = date
        self.target             = target
        self.allowPingus        = allowPingus
        self.team1Player1Id     = team1Player1Id
        self.team1Player2Id     = team1Player2Id
        self.team2Player1Id     = team2Player1Id
        self.team2Player2Id     = team2Player2Id
        self.guest2Name         = guest2Name
        self.guest3Name         = guest3Name
        self.guest4Name         = guest4Name
        self.currentPointsTeam1 = currentPointsTeam1
        self.currentPointsTeam2 = currentPointsTeam2
        self.winner             = winner
        self.calculated         = calculated
    }
    
    static func == (lhs: Game, rhs: Game) -> Bool {
        lhs.id == rhs.id
    }
}


//MARK: - ROUND
nonisolated struct Round: Identifiable, Decodable, Equatable {
    let id: Int
    var gameId: Int
    var roundOrder: Int

    var firstProfileId: Int?
    var secondProfileId: Int?
    var thirdProfileId: Int?
    var fourthProfileId: Int?

    var firstBombs: Int
    var secondBombs: Int
    var thirdBombs: Int
    var fourthBombs: Int

    var tichuPointsTeam1: Int
    var tichuPointsTeam2: Int

    var roundPointsTeam1: Int
    var roundPointsTeam2: Int

    var doubleWinTeam1: Bool
    var doubleWinTeam2: Bool

    var boolWinRound: Bool

    var announcedTichu: [Int]
    var announcedBigTichu: [Int]
    var announcedPingu: [Int]
    
    //MARK: Has to compare every Value or otherwise some Views won't register when a Round changes with .onChange
    static func == (lhs: Round, rhs: Round) -> Bool {
        lhs.id == rhs.id &&
        lhs.firstProfileId == rhs.firstProfileId &&
        lhs.secondProfileId == rhs.secondProfileId &&
        lhs.thirdProfileId == rhs.thirdProfileId &&
        lhs.fourthProfileId == rhs.fourthProfileId &&
        lhs.firstBombs == rhs.firstBombs &&
        lhs.secondBombs == rhs.secondBombs &&
        lhs.thirdBombs == rhs.thirdBombs &&
        lhs.fourthBombs == rhs.fourthBombs &&
        lhs.tichuPointsTeam1 == rhs.tichuPointsTeam1 &&
        lhs.tichuPointsTeam2 == rhs.tichuPointsTeam2 &&
        lhs.doubleWinTeam1 == rhs.doubleWinTeam1 &&
        lhs.doubleWinTeam2 == rhs.doubleWinTeam2 &&
        lhs.announcedTichu == rhs.announcedTichu &&
        lhs.announcedBigTichu == rhs.announcedBigTichu &&
        lhs.announcedPingu == rhs.announcedPingu
    }
}

//MARK: - Possible Targets for TichuGames
enum tichuGameTarget: Int, CaseIterable, Identifiable {
    case xs = 250
    case s = 500
    case l = 750
    case xl = 1000
    case xxl = 2000
    case xxxl = 5000
    case xxxxl = 10000
    var id: Int { self.rawValue }
}


//MARK: - EloHistoryEntry used in NetworkService
nonisolated struct EloHistoryEntry: Identifiable, Codable {
    var id: Int
    var gameId: Int?
    var eloChange: Double
    var changedAt: Date?
}


