//
//  GameSummaryShareView.swift
//  Tichu
//
//  Created by Leon on 02.05.2026.
//

import SwiftUI

struct GameSummaryShareView: View {
    @Environment(\.colorScheme) var colorScheme
    let currentGameId: Int?
    let rounds: [Round]
    let profiles: [Profile]
    let accentCo: Color

    // MARK: - Helpers
    
    private var currentGame: Game? {
        NetworkService.shared.games.first(where:{$0.id == currentGameId})
        }

    private var allRounds: [Round] {
        rounds.filter { $0.gameId == currentGameId }
              .sorted { $0.roundOrder < $1.roundOrder }
    }

    private func profile(for id: Int?) -> Profile? {
        guard let id else { return nil }
        return profiles.first { $0.id == id }
    }

    private var team1Profiles: [Profile] {
        
        [profile(for: currentGame?.team1Player1Id ?? 0),
         profile(for: currentGame?.team1Player2Id ?? 0)].compactMap { $0 }
    }

    private var team2Profiles: [Profile] {
        [profile(for: currentGame?.team2Player1Id ?? 0),
         profile(for: currentGame?.team2Player2Id ?? 0)].compactMap { $0 }
    }

    func gameWinner() -> String {
        if let currentGame{
            if currentGame.winner == 1{
                return String(format:String(localized:"general.team"),"1")
            }else if currentGame.winner == 2{
                return String(format:String(localized:"general.team"),"2")
            }else if currentGame.winner == 3{
                return String(localized:"general.tie")
            }else{
                return String(localized:"general.unknown")
            }
        }else{
            return String(localized:"general.unknown")
        }
    }
    
    
    func profileName(profile: Profile) -> String{
        if let currentGame{
            if profile.id == -2 {
                return currentGame.guest2Name ?? String(localized:"general.unknown")
            }else if profile.id == -3{
                return currentGame.guest3Name ?? String(localized:"general.unknown")
            }else if profile.id == -4{
                return currentGame.guest4Name ?? String(localized:"general.unknown")
            }else{
                return profile.name ?? String(localized:"general.unknown")
            }
        }else{
            return String(localized:"general.unknown")
        }
    }
    

    // Returns finishing place (1–4) of a profile in a round, based on firstProfileId etc.
    private func place(of profile: Profile, in round: Round) -> String {
        if round.firstProfileId == profile.id  { return "1" }
        if round.secondProfileId == profile.id { return "2" }
        if round.thirdProfileId == profile.id  { return "3" }
        return "4"
    }

    private func bombs(of profile: Profile, in round: Round) -> Int {
        if round.firstProfileId  == profile.id { return round.firstBombs }
        if round.secondProfileId == profile.id { return round.secondBombs }
        if round.thirdProfileId  == profile.id { return round.thirdBombs }
        return round.fourthBombs
    }

    private func teamPlacement(profiles: [Profile], currentRound: Round) -> some View {
        let p0Place = profiles.count > 0 ? place(of: profiles[0], in: currentRound) : "?"
        let p1Place = profiles.count > 1 ? place(of: profiles[1], in: currentRound) : "?"
        return Text("(\(p0Place)/\(p1Place))").monospaced()
    }

    private func announcementInfo(for profile: Profile, in round: Round) -> (text: String, color: Color) {
        let won = round.firstProfileId == profile.id
        let resultColor: Color = won ? .green : .red

        if round.announcedBigTichu.contains(profile.id) {
            return ("T", resultColor)
        } else if round.announcedTichu.contains(profile.id) {
            return ("t", resultColor)
        } else if round.announcedPingu.contains(profile.id) {
            return ("P", resultColor)
        }
        return ("C", .clear)
    }

    private func teamAnnounced(profiles: [Profile], round: Round, lead: String) -> some View {
        let p0 = profiles.count > 0 ? profiles[0] : nil
        let p1 = profiles.count > 1 ? profiles[1] : nil

        let info0 = p0.map { announcementInfo(for: $0, in: round) }
        let info1 = p1.map { announcementInfo(for: $0, in: round) }

        let bomb0 = p0.map { bombs(of: $0, in: round) } ?? 0
        let bomb1 = p1.map { bombs(of: $0, in: round) } ?? 0

        let name0 = p0?.name.flatMap { String($0.prefix(2)) } ?? "Uk"
        let name1 = p1?.name.flatMap { String($0.prefix(2)) } ?? "Uk"

        return HStack {
            if let info0, info0.text != "C" {
                HStack {
                    if lead == "leading" {
                        Text(name0).foregroundStyle(info0.color).lineLimit(1)
                        Text("\(bomb0)")
                        Text(info0.text).foregroundStyle(info0.color).lineLimit(1)
                    } else {
                        Text(info0.text).foregroundStyle(info0.color).lineLimit(1)
                        Text(name0).foregroundStyle(info0.color).lineLimit(1)
                        Text("\(bomb0)")
                    }
                }
                .font(.system(size: 17))
                .frame(width: 60, alignment: lead == "trailing" ? .trailing : .leading)
            } else {
                HStack {
                    Text(name0).lineLimit(1)
                    Text("\(bomb0)")
                }
                .font(.system(size: 17))
                .frame(width: 60, alignment: lead == "trailing" ? .trailing : .leading)
                .monospaced()
            }

            if let info1, info1.text != "C" {
                HStack {
                    if lead == "leading" {
                        Text(name1).foregroundStyle(info1.color).lineLimit(1)
                        Text("\(bomb1)")
                        Text(info1.text).foregroundStyle(info1.color).lineLimit(1)
                    } else {
                        Text(info1.text).foregroundStyle(info1.color).lineLimit(1)
                        Text(name1).foregroundStyle(info1.color).lineLimit(1)
                        Text("\(bomb1)")
                    }
                }
                .font(.system(size: 17))
                .frame(width: 60, alignment: lead == "trailing" ? .trailing : .leading)
                .monospaced()
            } else {
                HStack {
                    Text(name1).lineLimit(1)
                    Text("\(bomb1)")
                }
                .font(.system(size: 17))
                .frame(width: 60, alignment: lead == "trailing" ? .trailing : .leading)
            }
        }
        .opacity(colorScheme == .dark ? 0.66 : 1)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 24) {
            //Was I high when i wrote this? what kinda dark wizard magic shit is this
            Text(String(localized: "gamesummaryshare.title"))
                .font(.largeTitle)
                .fontWeight(.bold)

            HStack {
                VStack {
                    Text(String(format:String(localized: "general.team.double"), String(1))).fontWeight(.bold)
                    Text(team1Profiles.count > 0 ? profileName(profile: team1Profiles[0]) : String(localized: "general.unknown"))
                        .font(.title).fontWeight(.bold)
                    Text(team1Profiles.count > 0 ? profileName(profile: team1Profiles[1]) : String(localized: "general.unknown"))
                        .font(.title).fontWeight(.bold)
                        .font(.title).fontWeight(.bold)
                }.foregroundStyle(accentCo)
                Spacer()
                VStack {
                    Text(String(format:String(localized: "general.team.double"), String(2))).fontWeight(.bold)
                    Text(team1Profiles.count > 0 ? profileName(profile: team2Profiles[0]) : String(localized: "general.unknown"))
                        .font(.title).fontWeight(.bold)
                        .font(.title).fontWeight(.bold)
                    Text(team1Profiles.count > 0 ? profileName(profile: team2Profiles[1]) : String(localized: "general.unknown"))
                        .font(.title).fontWeight(.bold)
                        .font(.title).fontWeight(.bold)
                }
            }.padding(.horizontal, 30)

            GameSummaryChartView(
                currentGameId: currentGameId
            )
            .frame(height: 250)

            HStack {
                VStack {
                    Text(String(format:String(localized: "general.team"), String(1)))
                        .font(.headline)
                        .foregroundStyle(accentCo)
                    Text("\(currentGame?.currentPointsTeam1 ?? 0)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(accentCo)
                }
                Spacer()
                VStack {
                    Text(String(format: String(localized: "gamesummaryshare.target"), String(currentGame?.target ?? 1000))).fontWeight(.bold)
                    Text(String(format: String(localized: "gamesummaryshare.winner"), String(gameWinner()))).fontWeight(.bold)
                        .foregroundStyle(gameWinner() == String(format:String(localized: "general.team"), String(1)) ? accentCo : Color.primary)
                }
                Spacer()
                VStack {
                    Text(String(format:String(localized: "general.team"), String(2))).font(.headline)
                    Text("\(currentGame?.currentPointsTeam2 ?? 0)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
            }.padding(.horizontal, 30)

            Text(String(localized: "gamesummaryshare.details")).fontWeight(.bold).font(.title)
            HStack {
                Text(String(format:String(localized: "general.team"), String(1))).padding(.trailing, 23).foregroundStyle(accentCo)
                Text(String(localized: "gamesummaryshare.rounds")).fontWeight(.bold)
                Text(String(format:String(localized: "general.team"), String(2))).padding(.leading, 20)
            }

            HStack(alignment: .top) {
                VStack {
                    ForEach(allRounds) { currentRound in
                        HStack {
                            teamPlacement(profiles: team1Profiles, currentRound: currentRound)
                                .frame(width: 60, alignment: .trailing)
                                .padding(.trailing, 60)

                            teamAnnounced(profiles: team1Profiles, round: currentRound, lead: "trailing")
                                .frame(width: 65, alignment: .trailing)

                            Text("\(currentRound.tichuPointsTeam1)")
                                .fontWeight(.bold)
                                .frame(width: 50, alignment: .trailing)
                                .monospaced()
                        }
                    }
                }

                VStack {
                    ForEach(allRounds) { currentRound in
                        HStack {
                            Text("\(currentRound.tichuPointsTeam2)")
                                .fontWeight(.bold)
                                .frame(width: 50, alignment: .leading)
                                .monospaced()

                            teamAnnounced(profiles: team2Profiles, round: currentRound, lead: "leading")
                                .frame(width: 65, alignment: .leading)

                            teamPlacement(profiles: team2Profiles, currentRound: currentRound)
                                .frame(width: 60, alignment: .leading)
                                .padding(.leading, 60)
                        }
                    }
                }
            }

            HStack {
                Text(String(localized: "general.madeWith")).fontWeight(.bold)
                Image("AppLogo").resizable().frame(width: 45, height: 45)
            }

        }.frame(width: 500).background(colorScheme == .dark ? Color.black : Color.white)
    }
}

#Preview{
    GameSummaryShareView(currentGameId:20,rounds:[],profiles: [],accentCo: .accentColor,)
}
