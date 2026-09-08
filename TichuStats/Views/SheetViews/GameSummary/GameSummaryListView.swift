//
//  gameOverViewListView.swift
//  Tichu
//
//  Created by Leon on 02.05.2026.
//

import SwiftUI
import TipKit

struct GameSummaryListView: View {
    @Binding var showGameSummarySheetView: Bool
    var currentGameId: Int?

    let profiles: [Profile]
    @ObservedObject var network: NetworkService

    @State private var expandedRows: Set<Int> = []
    @State private var showDeleteGameAlert: Bool = false
    @State private var showAddRoundSheet: Bool = false
    @State private var showList: Bool = false
    @State private var editingRoundIndex: Int = 0

    @Environment(\.colorScheme) var colorScheme
    @Binding var allowEditing: Bool

    // MARK: - Computed

    private var currentGame: Game? {
        network.games.first(where: { $0.id == currentGameId })
    }

    private var allRounds: [Round] {
        (network.roundsByGame[currentGameId ?? 0] ?? [])
            .sorted { $0.roundOrder < $1.roundOrder }
    }

    private var winRounds: [Round] {
        allRounds.filter { $0.boolWinRound }
    }

    private func profile(for id: Int?) -> Profile? {
        guard let id else { return nil }
        return profiles.first { $0.id == id }
    }

    private var team1Profiles: [Profile] {
        [profile(for: currentGame?.team1Player1Id ?? -1),
         profile(for: currentGame?.team1Player2Id ?? -2)].compactMap { $0 }
    }

    private var team2Profiles: [Profile] {
        [profile(for: currentGame?.team2Player1Id ?? -3),
         profile(for: currentGame?.team2Player2Id ?? -4)].compactMap { $0 }
    }

    var gameDone: Bool {
        if currentGame?.currentPointsTeam1 ?? 0 >= currentGame?.target ?? 1000 || currentGame?.currentPointsTeam2 ?? 0 >= currentGame?.target ?? 1000 {
            if currentGame?.currentPointsTeam1 ?? 0 > currentGame?.currentPointsTeam2 ?? 0 { return true }
            if currentGame?.currentPointsTeam2 ?? 0 > currentGame?.currentPointsTeam1 ?? 0 { return true }
        }
        return false
    }

    // MARK: - Helpers

    
    private func place(of profile: Profile, in round: Round) -> Int {
        if round.doubleWinTeam1 {
            if round.firstProfileId == profile.id {
                return 1
            }

            if round.secondProfileId == profile.id {
                return 2
            }

            if round.thirdProfileId == profile.id {
                return 3
            }

            if round.fourthProfileId == profile.id {
                return 3
            }
        }

        if round.doubleWinTeam2 {
            if round.firstProfileId == profile.id {
                return 1
            }

            if round.secondProfileId == profile.id {
                return 2
            }

            if round.thirdProfileId == profile.id {
                return 3
            }

            if round.fourthProfileId == profile.id {
                return 3
            }
        }

        // Normal placement
        if round.firstProfileId == profile.id {
            return 1
        }

        if round.secondProfileId == profile.id {
            return 2
        }

        if round.thirdProfileId == profile.id {
            return 3
        }

        if round.fourthProfileId == profile.id {
            return 4
        }

        // Guest players
        if profile.id == -1 || profile.id == -2 || profile.id == -3 || profile.id == -4 {
            if network.profiles.first(where: { $0.id == round.firstProfileId }) == nil {
                return 1
            }

            if network.profiles.first(where: { $0.id == round.secondProfileId }) == nil {
                return 2
            }

            if network.profiles.first(where: { $0.id == round.thirdProfileId }) == nil {
                return 3
            }

            if network.profiles.first(where: { $0.id == round.fourthProfileId }) == nil {
                return round.doubleWinTeam1 || round.doubleWinTeam2 ? 3 : 4
            }
        }

        return 0
    }
    


    private func sortedTeamProfiles(_ teamProfiles: [Profile], in round: Round) -> [Profile] {
        teamProfiles.sorted { place(of: $0, in: round) < place(of: $1, in: round) }
    }

    private func bombCounter(profile: Profile, round: Round) -> Int {
        if round.firstProfileId  == profile.id { return round.firstBombs }
        if round.secondProfileId == profile.id { return round.secondBombs }
        if round.thirdProfileId  == profile.id { return round.thirdBombs }
        if round.fourthProfileId == profile.id { return round.fourthBombs }
        return 0
    }

    private func bindingForExpanded(row index: Int, disabled: Bool = false) -> Binding<Bool> {
        Binding(
            get: { expandedRows.contains(index) },
            set: { newValue in
                guard !disabled else { return }
                if newValue { expandedRows.insert(index) } else { expandedRows.remove(index) }
            }
        )
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            if !showList {
                List {
                    let cumulative = allRounds.enumerated().map { (index, round) -> (index: Int, round: Round, cum1: Int, cum2: Int) in
                        let sum1 = allRounds.prefix(index + 1).reduce(0) { $0 + $1.tichuPointsTeam1 + $1.roundPointsTeam1 }
                        let sum2 = allRounds.prefix(index + 1).reduce(0) { $0 + $1.tichuPointsTeam2 + $1.roundPointsTeam2 }
                        return (index, round, sum1, sum2)
                    }
                    if allowEditing {
                        TipView(ListSwipeTip()).tipBackground(Color.clear)
                    }
                    
                    ForEach(cumulative, id: \.round.id) { item in
                        Section{
                        let index = item.index
                        let currentRound = item.round
                        let hasExpanded = expandedRows.contains(index)
                        let isWinningRound = winRounds.contains { $0.id == currentRound.id }
                        let isLocked = !isWinningRound
                        
                        let sortedTeam1 = sortedTeamProfiles(team1Profiles, in: currentRound)
                        let sortedTeam2 = sortedTeamProfiles(team2Profiles, in: currentRound)
                        
                        DisclosureGroup(isExpanded: bindingForExpanded(row: index, disabled: isLocked)) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading) {
                                    HStack {
                                        Text(String(format:String(localized:"general.team"),String(1))).fontWeight(.bold).foregroundStyle(Color.accentColor)
                                        Spacer()
                                    }
                                    .padding(.top)
                                    .padding(.horizontal)
                                    
                                    playerRows(players: sortedTeam1, round: currentRound, teamProfileIds: (currentGame!.team1Player1Id, currentGame!.team1Player2Id))
                                    
                                    HStack {
                                        Text(String(format:String(localized:"general.team"),String(2))).fontWeight(.bold)
                                        Spacer()
                                    }
                                    .padding(.top)
                                    .padding(.horizontal)
                                    
                                    playerRows(players: sortedTeam2, round: currentRound, teamProfileIds: (currentGame!.team2Player1Id, currentGame!.team2Player2Id))
                                }
                                Spacer()
                            }
                            .padding(.leading, -20)
                            .padding(.trailing, 5)
                            
                        } label: {
                            HStack {
                                if !hasExpanded {
                                    // Team 1 indicators
                                    VStack(alignment: .leading, spacing: 2) {
                                        let allPlayers = sortedTeam1
                                        ForEach(allPlayers, id: \.id) { player in
                                            let isFirst = currentRound.firstProfileId == player.id
                                            let tichu = currentRound.announcedTichu.contains(player.id)
                                            let bigTichu = currentRound.announcedBigTichu.contains(player.id)
                                            let pingu = currentRound.announcedPingu.contains(player.id)
                                            
                                            if tichu || bigTichu || pingu {
                                                Text(bigTichu ? "T" : pingu ? "P" : "t")
                                                    .fontWeight(.bold)
                                                    .foregroundStyle(isFirst ? .green : .red)
                                            }
                                        }
                                    }
                                    .frame(width: 20)

                                    VStack(alignment: .center, spacing: 0) {
                                        let delta1 = item.round.tichuPointsTeam1 + item.round.roundPointsTeam1
                                        if delta1 >= 0 {
                                            Text("+\(delta1) ")
                                        } else {
                                            Text("\(delta1)")
                                        }
                                        Divider().background(Color.primary).frame(width: 40).frame(height: 2)
                                        Text("\(item.cum1)")
                                    }
                                    .frame(width: 50, alignment: .leading)
                                    .foregroundStyle(item.round.doubleWinTeam1 ? .green : .primary)
                                    
                                }

                                if !hasExpanded {
                                    Spacer()
                                }

                                Text(String(format:String(localized:"round.round"), String(item.index + 1)))
                                    .fontWeight(.bold)
                                Spacer()

                                if !hasExpanded {
                                    VStack(alignment: .center, spacing: 0) {
                                        let delta2 = item.round.tichuPointsTeam2 + item.round.roundPointsTeam2
                                        if delta2 >= 0 {
                                            Text("+\(delta2) ")
                                        } else {
                                            Text("\(delta2)")
                                        }
                                        Divider().frame(width: 40).background(Color.primary).frame(height: 2)
                                        Text("\(item.cum2)")
                                    }
                                    .frame(width: 50, alignment: .leading)
                                    .foregroundStyle(item.round.doubleWinTeam2 ? .green : .primary)

                                    // Team 2 indicators
                                    VStack(alignment: .trailing, spacing: 2) {
                                        let allPlayers = sortedTeam2
                                        ForEach(allPlayers, id: \.id) { player in
                                            let isFirst = currentRound.firstProfileId == player.id
                                            let tichu = currentRound.announcedTichu.contains(player.id)
                                            let bigTichu = currentRound.announcedBigTichu.contains(player.id)
                                            let pingu = currentRound.announcedPingu.contains(player.id)
                                            
                                            if tichu || bigTichu || pingu {
                                                Text(bigTichu ? "T" : pingu ? "P" : "t")
                                                    .fontWeight(.bold)
                                                    .foregroundStyle(isFirst ? .green : .red)
                                            }
                                        }
                                    }
                                    .frame(width: 20)
                                }
                            }
                        }
                        .opacity(isLocked ? 0.5 : 1.0)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            if allowEditing {
                                Button(role: .destructive) {
                                   
                                    Task {
                                        guard let gameId = currentGame?.id else {
                                            print("no game id")
                                            return
                                        }
                                            await network.deleteRound(gameId: gameId, roundId: currentRound.id)
                                            await network.reCalculate(gameId: gameId)
                                        }
                                    
                                } label: {
                                    Label(String(localized:"general.delete"), systemImage: "trash")
                                }
                                
                                if !isLocked {
                                    Button {
                                        editingRoundIndex = index
                                        showAddRoundSheet = true
                                    } label: {
                                        Label(String(localized:"general.edit"), systemImage: "pencil")
                                    }
                                    .tint(.accentColor)
                                }
                            }
                        }
                    }
                    }
                    

                    if allRounds.count != winRounds.count {
                        Section {
                            Text(
                                String(format: String(localized: "rounds.notCounted"),"\(allRounds.count - winRounds.count)","\(winRounds.count)"))
                        }
                        .listRowBackground(Color.clear)
                        .foregroundStyle(.secondary)
                    }

                    if !allowEditing {
                        Section {
                            HStack {
                                Spacer()
                                Text(String(format:String(localized:"gameSummary.playedOn"),"\(currentGame?.date.formatted(date: .complete, time: .omitted) ?? String(localized:"general.unknown"))"))
                             
                                Spacer()
                            }
                            .foregroundStyle(Color.secondary)
                        }
                        .listRowBackground(Color.clear)
                
                    }
                }
                .task {
                    do { try Tips.configure() } catch {
                        print("Error initializing TipKit \(error.localizedDescription)")
                    }
                }
                .sheet(isPresented: $showAddRoundSheet, onDismiss: {
                    Task {
                        await network.fetchGameRounds(gameId: currentGame?.id ?? 0)
                        await network.reCalculate(gameId: currentGame?.id ?? 0)
                    }
                }) {
                    AddRoundSheetView(
                                    showAddRoundsSheet: $showAddRoundSheet,
                                    currentGameId: currentGame?.id ?? 0,
                                    profiles: profiles,
                                    network: network,
                                    editMode: true,
                                    roundIndex: editingRoundIndex + 1,
                                    editingRound: allRounds[safe: editingRoundIndex]
                                )
                }
                .id(editingRoundIndex)
                .listSectionSpacing(5)
                .animation(.spring(duration: 0.25), value: expandedRows)
                .animation(.easeInOut(duration: 0.25), value: showList)

            } else {
                Text(" ")
            }
        }.onChange(of:allowEditing){
            if allowEditing == false{
                showAddRoundSheet = false
            }
        }
        .onAppear {
            if network.roundsByGame[currentGameId ?? 0] == nil {
                Task {
                    await network.fetchGameRounds(gameId: currentGameId ?? 0)
                }
            }
        }
        .alert(String(localized:"gameSummary.alert.delete.title"), isPresented: $showDeleteGameAlert) {
            Button(String(localized:"gamesummary.delete.alert.cancel"), role: .cancel) {
                showDeleteGameAlert = false
                showList = false
            }
            Button(String(localized:"gamesummary.delete.alert.confirm"), role: .destructive) {
                Task {
                    await network.deleteGame(gameId: currentGame?.id ?? 0)
                    showGameSummarySheetView = false
                }
            }
        } message: {
            Text(String(localized:"gamesummary.delete.alert.description"))
        }
    }

    // MARK: - Player Rows

    private func playerRows(players: [Profile], round: Round, teamProfileIds: (Int?, Int?)) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(players, id: \.id) { player in
                let playerPlace = place(of: player, in: round)
                let isFirst = round.firstProfileId == player.id

                let firstId  = round.firstProfileId
                let secondId = round.secondProfileId
                let teamIds  = [teamProfileIds.0, teamProfileIds.1]
                let isDoubleWin = firstId != nil && secondId != nil &&
                    teamIds.contains(firstId) && teamIds.contains(secondId)
                let placeColor: Color = isDoubleWin
                    ? .green.opacity(colorScheme == .dark ? 0.66 : 1)
                    : .primary

                let tichu    = round.announcedTichu.contains(player.id)
                let bigTichu = round.announcedBigTichu.contains(player.id)
                let pingu    = round.announcedPingu.contains(player.id)
                let bomb     = bombCounter(profile: player, round: round)

                HStack {
                    Text("\(playerPlace).").fontWeight(.bold).foregroundStyle(placeColor)
                    
                    
                    if player.id == -2{
                        Text(currentGame?.guest2Name ?? String(localized:"play.guest"))
                    }else if player.id == -3{
                        Text(currentGame?.guest3Name ?? String(localized:"play.guest"))
                    }else if player.id == -4{
                        Text(currentGame?.guest4Name ?? String(localized:"play.guest"))
                    }else{
                        Text(player.name ?? String(localized: "general.unknown"))
                    }
                  
                    Spacer()

                    if tichu || bigTichu || pingu {
                        HStack {
                            Image(systemName: isFirst ? "checkmark" : "xmark")
                            Text(bigTichu ? "Big Tichu" : pingu ? "Pingu" : "Tichu")
                        }
                        .foregroundStyle(isFirst ? .green : .red)
                        .opacity(colorScheme == .dark ? 0.66 : 1)
                        .offset(x: bomb > 0 ? 40 : 0)
                    }

                    if bomb > 0 {
                        bombView(bomb:bomb)
                    }
                }
            }
            
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 20).fill(Color(uiColor: .systemGroupedBackground)))
    }
}
