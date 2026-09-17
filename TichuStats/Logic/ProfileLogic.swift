//
//  ProfileLogic.swift
//  Tichu
//
//  Created by Leon on 25.04.2026.
//

import SwiftUI


let placeholderProfile = Profile(
    id: -12,
    name: "Unknown",
    profileImageUrl: "https://example.com/avatar.jpg",
    imageData: nil,
    elo: 1000.0,
    isAdmin: false,
    allTime: .empty,
    year: .empty,
    month: .empty,
    week: .empty,
    day: .empty
)


// MARK: - ProfileStats used in Profiles
nonisolated struct ProfileStats: Codable,Equatable {
    // MARK: Vars

    var calculatedAt: Date
    var winnerPercentage: Double
    var averagePlacement: Double
    var tichuMaster: Double
    var visionary: Double
    var addict: Double
    var teamplayer: Double
    var announcer: Double
    var saboteur: Double
    var gambler: Double
    var bigGambler: Double
    var pinguGambler: Double
    var bomber: Double


    func getStat(for stat: Profile.playerStat) -> Double {
        switch stat {
        case .elo:
            return 0
        case .winnerPercentage:
            return winnerPercentage
        case .averagePlacement:
            return averagePlacement
        case .tichuMaster:
            return tichuMaster
        case .visionary:
            return visionary
        case .addict:
            return addict
        case .teamplayer:
            return teamplayer
        case .announcer:
            return announcer
        case .saboteur:
            return saboteur
        case .gambler:
            return gambler
        case .bigGambler:
            return bigGambler
        case .pinguGambler:
            return pinguGambler
        case .bomber:
            return bomber
        case .dateAdded:
            return 0
        }
    }
    
    // MARK: Fallback
    
    static func == (lhs: ProfileStats, rhs: ProfileStats) -> Bool {
        lhs.calculatedAt == rhs.calculatedAt &&
        lhs.winnerPercentage == rhs.winnerPercentage &&
        lhs.averagePlacement == rhs.averagePlacement &&
        lhs.tichuMaster == rhs.tichuMaster &&
        lhs.visionary == rhs.visionary &&
        lhs.addict == rhs.addict &&
        lhs.teamplayer == rhs.teamplayer &&
        lhs.announcer == rhs.announcer &&
        lhs.saboteur == rhs.saboteur &&
        lhs.gambler == rhs.gambler &&
        lhs.bigGambler == rhs.bigGambler &&
        lhs.pinguGambler == rhs.pinguGambler &&
        lhs.bomber == rhs.bomber
    }

    static var empty: ProfileStats {
        ProfileStats(
            calculatedAt: Date.now,
            winnerPercentage: 0,
            averagePlacement: 0,
            tichuMaster: 0,
            visionary: 0,
            addict: 0,
            teamplayer: 0,
            announcer: 0,
            saboteur: 0,
            gambler: 0,
            bigGambler: 0,
            pinguGambler: 0,
            bomber: 0
        )
    }
}


    




//MARK: Possible Timeframes
enum Timeframe: String, CaseIterable {
    case allTime = "All Time"
    case year    = "Year"
    case month   = "Month"
    case week    = "Week"
    case day     = "Today"
}

//MARK: - Profile
nonisolated struct Profile: Identifiable, Equatable, Codable {
    //MARK: Vars
    var id: Int
    var name: String?
    var profileImageUrl: String?
    var imageData: Data?
    var elo: Double?
    var isAdmin: Bool?

    var allTime: ProfileStats
    var year:    ProfileStats
    var month:   ProfileStats
    var week:    ProfileStats
    var day:     ProfileStats
    
    
    //Mark: Possible PlayerStats
    enum playerStat {
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
        case dateAdded
    }
    
    //MARK: Init
    init(
        id: Int = 0,
        name: String? = nil,
        profileImageUrl: String? = nil,
        imageData: Data? = nil,
        elo: Double? = nil,
        isAdmin: Bool? = nil,
        allTime: ProfileStats = .empty,
        year:    ProfileStats = .empty,
        month:   ProfileStats = .empty,
        week:    ProfileStats = .empty,
        day:     ProfileStats = .empty
    ) {
        self.id = id
        self.name = name
        self.profileImageUrl = profileImageUrl
        self.imageData = imageData
        self.elo = elo
        self.isAdmin = isAdmin
        self.allTime = allTime
        self.year    = year
        self.month   = month
        self.week    = week
        self.day     = day
    }

    //MARK: Decoder
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id              = try c.decode(Int.self, forKey: .id)
        name            = try c.decodeIfPresent(String.self, forKey: .name)
        profileImageUrl = try c.decodeIfPresent(String.self, forKey: .profileImageUrl)
        elo             = try c.decodeIfPresent(Double.self, forKey: .elo)
        isAdmin         = try c.decodeIfPresent(Bool.self, forKey: .isAdmin)
        allTime         = try c.decodeIfPresent(ProfileStats.self, forKey: .allTime) ?? .empty
        year            = try c.decodeIfPresent(ProfileStats.self, forKey: .year)    ?? .empty
        month           = try c.decodeIfPresent(ProfileStats.self, forKey: .month)   ?? .empty
        week            = try c.decodeIfPresent(ProfileStats.self, forKey: .week)    ?? .empty
        day             = try c.decodeIfPresent(ProfileStats.self, forKey: .day)     ?? .empty
        imageData       = nil
    }

    //MARK: returns ProfileStats for given TimeFrame
    func stats(for timeframe: Timeframe) -> ProfileStats {
        switch timeframe {
        case .allTime: return allTime
        case .year:    return year
        case .month:   return month
        case .week:    return week
        case .day:     return day
        }
    }

    func getStat(for stat: playerStat, timeframe: Timeframe = .allTime) -> Double {
        let s = stats(for: timeframe)
        switch stat {
        case .elo:              return elo ?? 0
        case .winnerPercentage: return s.winnerPercentage
        case .averagePlacement: return s.averagePlacement
        case .tichuMaster:      return s.tichuMaster
        case .visionary:        return s.visionary
        case .addict:           return s.addict
        case .teamplayer:       return s.teamplayer
        case .announcer:        return s.announcer
        case .saboteur:         return s.saboteur
        case .gambler:          return s.gambler
        case .bigGambler:       return s.bigGambler
        case .pinguGambler:     return s.pinguGambler
        case .bomber:           return s.bomber
        case .dateAdded:        return 0
        }
    }

    static func == (lhs: Profile, rhs: Profile) -> Bool {
        lhs.id == rhs.id
    }
}


// MARK: - makeItems

func makeItems(
    from compareList: [Profile],
    stat: Profile.playerStat,
    sortBy: sortBy,
    timeframe: Timeframe = .allTime
) -> [Profile] {
    switch sortBy {
    case .valueUp:
        return compareList.sorted { $0.getStat(for: stat, timeframe: timeframe) < $1.getStat(for: stat, timeframe: timeframe) }
    case .valueDown:
        return compareList.sorted { $0.getStat(for: stat, timeframe: timeframe) > $1.getStat(for: stat, timeframe: timeframe) }
    case .nameUp:
        return compareList.sorted { ($0.name ?? "").lowercased() > ($1.name ?? "").lowercased() }
    case .nameDown:
        return compareList.sorted { ($0.name ?? "").lowercased() < ($1.name ?? "").lowercased() }
    }
}

//MARK: - MakeItem Function and overloads to create Items for StatsContainer in StatsView
func makeItems(
    from compareList: [Int],
    stat: Profile.playerStat,
    sortBy: sortBy,
    timeframe: Timeframe = .allTime,
    reverse: Bool = false
) -> [Profile] {
    let profiles = NetworkService.shared.profiles.filter { compareList.contains($0.id) }
    switch sortBy {
    case .valueUp:
       if reverse{
           return profiles.sorted { $0.getStat(for: stat, timeframe: timeframe) > $1.getStat(for: stat, timeframe: timeframe) }
        }
        return profiles.sorted { $0.getStat(for: stat, timeframe: timeframe) < $1.getStat(for: stat, timeframe: timeframe) }
    case .valueDown:
      if reverse{
          return profiles.sorted { $0.getStat(for: stat, timeframe: timeframe) < $1.getStat(for: stat, timeframe: timeframe) }
        }
        return profiles.sorted { $0.getStat(for: stat, timeframe: timeframe) > $1.getStat(for: stat, timeframe: timeframe) }
    case .nameUp:
        return profiles.sorted { ($0.name ?? "").lowercased() < ($1.name ?? "").lowercased() }
    case .nameDown:
        return profiles.sorted { ($0.name ?? "").lowercased() > ($1.name ?? "").lowercased() }
    }
}

func makeItems(
    from compareList: [Int],
    stat: Profile.playerStat,
    sortBy: sortBy,
    timeframe: Timeframe = .allTime,

) -> [Friend] {
    let friends = NetworkService.shared.friends.filter { compareList.contains($0.id) }
    switch sortBy {
    case .valueUp:
        if stat == .dateAdded {
            return friends.sorted { ($0.friendsSince ?? .distantPast) < ($1.friendsSince ?? .distantPast) }
        }
        
        return friends.sorted { $0.profile.getStat(for: stat, timeframe: timeframe) < $1.profile.getStat(for: stat, timeframe: timeframe) }
    case .valueDown:
        if stat == .dateAdded {
            return friends.sorted { ($0.friendsSince ?? .distantPast) > ($1.friendsSince ?? .distantPast) }
        }
        return friends.sorted { $0.profile.getStat(for: stat, timeframe: timeframe) > $1.profile.getStat(for: stat, timeframe: timeframe) }
    case .nameUp:
        return friends.sorted { ($0.profile.name ?? "").lowercased() > ($1.profile.name ?? "").lowercased() }
    case .nameDown:
        return friends.sorted { ($0.profile.name ?? "").lowercased() < ($1.profile.name ?? "").lowercased() }
    }
}

func makeItems(
    from compareList: [Friend],
    stat: Profile.playerStat,
    sortBy: sortBy,
    timeframe: Timeframe = .allTime
) -> [Friend] {
    switch sortBy {
    case .valueUp:
        if stat == .dateAdded {
            return compareList.sorted { ($0.friendsSince ?? .distantPast) < ($1.friendsSince ?? .distantPast) }
        }
        return compareList.sorted { $0.profile.getStat(for: stat, timeframe: timeframe) < $1.profile.getStat(for: stat, timeframe: timeframe) }
    case .valueDown:
        if stat == .dateAdded {
            return compareList.sorted { ($0.friendsSince ?? .distantPast) > ($1.friendsSince ?? .distantPast) }
        }
        return compareList.sorted { $0.profile.getStat(for: stat, timeframe: timeframe) > $1.profile.getStat(for: stat, timeframe: timeframe) }
    case .nameUp:
        return compareList.sorted { ($0.profile.name ?? "").lowercased() < ($1.profile.name ?? "").lowercased() }
    case .nameDown:
        return compareList.sorted { ($0.profile.name ?? "").lowercased() > ($1.profile.name ?? "").lowercased() }
    }
}


// MARK: - Friend used to Store Friends
nonisolated struct Friend: Identifiable, Equatable {
    //MARK: Vars
    let id: Int
    let profile: Profile
    let friendsSince: Date?
    //MARK: Compare
    static func == (lhs: Friend, rhs: Friend) -> Bool {
        lhs.id == rhs.id
    }
}


//MARK: Used to translate Int to enum in NetWorkServcice fetchProfileSettings
func PickerSettingsEncoder(x:Int) -> sortBy{
    if x == 0{
        return sortBy.nameDown
    }else if x == 1{
        return sortBy.nameUp
    }else if x == 2{
        return sortBy.valueDown
    }else{
        return sortBy.valueUp
    }
}

func PickerSettingsEncoder(x:sortBy) -> Int{
    if x == sortBy.nameDown{
        return 0
    }else if x == sortBy.nameUp{
        return 1
    }else if x == sortBy.valueDown{
        return 2
    }else{
        return 3
    }
}
