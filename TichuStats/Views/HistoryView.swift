//
//  HistoryView.swift
//  Tichu
//
//  Created by Leon on 08.05.2026
//

import SwiftUI
import Charts
import TipKit

struct RowSnappingBehavior: ScrollTargetBehavior {
    let rowHeight: CGFloat

    func updateTarget(_ target: inout ScrollTarget, context: TargetContext) {
        let y = target.rect.minY
        let snapped = (y / rowHeight).rounded() * rowHeight
        target.rect.origin.y = snapped
    }
}

struct HistoryView: View {
    @Namespace private var historySpace
    @State private var outerSize: CGSize = .zero

    // MARK: - Storage
    @AppStorage("userId") var userId: Int = -69420
    @AppStorage("selectedTab") private var selectedTab = 1
    @AppStorage("isLoading") private var isLoading = false
    @Environment(\.colorScheme) var colorScheme
    @State private var showDebugSheetView: Bool = false
    @State private var showLoader: Bool = false
    @State private var sheetSelectedTab: Int = 1
    @State private var selectedCounter: Int = 0

    @StateObject private var socket = SocketService.shared
    @ObservedObject private var network = NetworkService.shared

    // MARK: - State
    @Binding var sheetGame: Game?
    @Binding var selectedGameId: Int?
    @Binding var scrolledGameId: Int?
    @State private var showOnlyFavorites: Bool = false
    @State private var dateUp: Bool = false
    @State private var switchedGameId: Int? = nil
    @State private var switchedGameIdFav: Int? = nil
    
 

    // MARK: - Computed
    private var gameHistory: [Game] {
        network.games
            .sorted { dateUp ? $0.date < $1.date : $0.date > $1.date }
            .filter { $0.winner != nil }
            .filter { !showOnlyFavorites || $0.favorite }
    }

    // MARK: - Body
    var body: some View {
        if gameHistory.count > 0 || isLoading {
            historyView
        } else {
            emptyStateView
        }
    }

    // MARK: - History View
    private var historyView: some View {
        NavigationStack {
            GlassEffectContainer {
                GeometryReader { outerGeo in
                    let rowHeight: CGFloat = 75
                    let centerY = outerGeo.size.height / 2 - 5
                    let topPadding = centerY - rowHeight / 2 - 10
                    let bottomPadding = centerY - rowHeight / 2 + 20

                    ScrollView(.vertical) {
                        LazyVStack(spacing: 0) {
                            Color.clear.frame(height: topPadding)
                            if isLoading {
                                let game = Game(favorite: false, id: 0, date: Date(), target: 1000, allowPingus: true, currentPointsTeam1: 0, currentPointsTeam2: 0)
                                ForEach(0..<10, id: \.self) { _ in
                                    GameRow(
                                        game: game,
                                        isSelected: selectedGameId == game.id,
                                        userId: userId,
                                        profiles: network.profiles,
                                        network: network,
                                        historySpace: historySpace,
                                        colorScheme: colorScheme,
                                        selectedCounter: selectedCounter,
                                        sheetGame: $sheetGame,
                                        scrolledGameId: $scrolledGameId
                                    )
                                    .padding(.horizontal, 10)
                                    .frame(height: rowHeight)
                                    .disabled(true)
                                }
                            } else {
                                ForEach(gameHistory, id: \.id) { game in
                                    GameRow(
                                        game: game,
                                        isSelected: selectedGameId == game.id,
                                        userId: userId,
                                        profiles: network.profiles,
                                        network: network,
                                        historySpace: historySpace,
                                        colorScheme: colorScheme,
                                        selectedCounter: selectedCounter,
                                        sheetGame: $sheetGame,
                                        scrolledGameId: $scrolledGameId
                                    )
                                    //Forces View to redraw when favorite status has changed because otherwise it wont update view
                                    .id("\(game.id)-\(game.favorite)")
                                    .padding(.horizontal, 10)
                                    .frame(height: rowHeight)
                                }
                                .task {
                                    do {
                                        try Tips.configure()
                                    } catch {
                                        print("Error initializing TipKit \(error.localizedDescription)")
                                    }
                                }

                                Color.clear.frame(height: bottomPadding)
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollDisabled(isLoading)
                    .animation(.easeInOut, value: isLoading)
                    .scrollEdgeEffectStyle(.soft, for: .all)
                    .scrollPosition(id: $scrolledGameId, anchor: .center)
                    .scrollTargetBehavior(RowSnappingBehavior(rowHeight: rowHeight))
                    .background(Color(uiColor: .systemGroupedBackground))
                    .onChange(of: scrolledGameId) { _, newId in
                        guard let newId, selectedGameId != newId else { return }
                        selectedGameId = newId
                        selectedCounter += 1
                    }
                    .onAppear { outerSize = outerGeo.size }
                    .onChange(of: outerGeo.size) { _, s in outerSize = s }
                }
            }
            .sheet(isPresented: $showDebugSheetView) {
                DebugSheetView(
                    currentGame: .constant(network.games[0]),
                    showDebugSheetView: $showDebugSheetView
                )
            }
            .refreshable {
                Task {
                    await network.fetchGamesHistory(load: false)
                }
            }
            .sheet(item: $sheetGame) { game in
                GameSummarySheetView(
                    showGameOverViewSheetView: Binding(
                        get: { sheetGame != nil },
                        set: { if !$0 { sheetGame = nil } }
                    ),
                    currentGameId: game.id,
                    revanche: .constant(false),
                    tie:false,
                    profiles: network.profiles,
                    network: network,
                    selectedTab: $sheetSelectedTab,
                    showRevancheButton: false,
                    allowEditing: .constant(false)
                ).navigationTransition(.zoom(sourceID: "\(game.id)", in: historySpace))
            }
            .toolbarTitleDisplayMode(.inlineLarge)
            .navigationTitle(String(localized: "general.title.history"))
            .toolbar {
                if network.profiles.first(where: { $0.id == userId })?.isAdmin == true {
                    ToolbarItem {
                        Button { showDebugSheetView = true } label: {
                            Image(systemName: "ant").foregroundStyle(socket.connected && network.apiURL == getURL() ? Color.green : network.apiURL == getURL(dev: true) && socket.connected ? Color.orange : Color.red)
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationProfileImage()
                }
                .sharedBackgroundVisibility(.hidden)
            }
        }
        .safeAreaInset(edge: .top) {
            if isLoading {
                ZStack() {
                    EloHistoryChartView(profileId: userId, markedGameId: -69420)
                        .animation(.easeInOut, value: isLoading)
                        .opacity(0)
                        .frame(height: outerSize.height / 2 - 125)
                        .padding(.vertical)
                        .glassEffect(
                            .regular.tint(
                                colorScheme == .dark
                                ? Color(uiColor: .tertiarySystemFill)
                                : .white
                            ).interactive(),
                            in: .rect(cornerRadius: 20)
                        )
                        .padding(.top, 50)
                        .padding(.horizontal, 10)
                        .padding(.top, 5)

                    VStack(spacing: 10) {
                        ProgressView()
                        Text(String(localized: "history.loading"))
                    }
                    .foregroundStyle(.secondary)
                    .offset(y: 30)
                }
            } else {
                if let selectedId = selectedGameId {
                    EloHistoryChartView(profileId: userId, markedGameId: selectedId)
                        .frame(height: outerSize.height / 2 - 125)
                        .padding(.vertical)
                        .glassEffect(
                            .regular.tint(
                                colorScheme == .dark
                                ? Color(uiColor: .tertiarySystemFill)
                                : .white
                            ).interactive(),
                            in: .rect(cornerRadius: 20)
                        )
                        .padding(.top, 50)
                        .padding(.horizontal, 10)
                        .padding(.top, 5)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            bottomBar
        }
        .onAppear {
            if selectedGameId == nil, let first = gameHistory.first {
                selectedGameId = first.id
                scrolledGameId = first.id
            }

            Task {
                showLoader = true
                await withTaskGroup(of: Void.self) { group in
                    for game in gameHistory {
                        group.addTask {
                            await network.fetchGameRounds(gameId: game.id)
                        }
                    }
                }
                showLoader = false
            }
        }
    }

    // MARK: - Empty State View
    private var emptyStateView: some View {
        NavigationStack {
            VStack {
                Text(String(localized: "history.willAppear.title")).font(.title2).fontWeight(.bold)
                Text(String(localized: "history.willAppear.description"))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .sheet(isPresented: $showDebugSheetView) {
                        DebugSheetView(
                            currentGame: .constant(
                                network.games.first ??
                                Game(
                                    favorite: false,
                                    id: 0,
                                    date: Date(),
                                    target: 1000,
                                    allowPingus: true,
                                    currentPointsTeam1: 0,
                                    currentPointsTeam2: 0
                                )
                            ),
                            showDebugSheetView: $showDebugSheetView
                        )
                    }

                Button {
                    selectedTab = 0
                } label: {
                    Text(String(localized: "tichu.play"))
                }
                .padding(13)
                .glassEffect(.regular.tint(.accentColor).interactive())
                .foregroundStyle(.primary)
            }
            .toolbarTitleDisplayMode(.inlineLarge)
            .navigationTitle("History")
            .toolbar {
                if network.profiles.first(where: { $0.id == userId })?.isAdmin == true {
                    ToolbarItem {
                        Button { showDebugSheetView = true } label: {
                            Image(systemName: "ant").foregroundStyle(socket.connected && network.apiURL == getURL() ? Color.green : network.apiURL == getURL(dev: true) && socket.connected ? Color.orange : Color.red)
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationProfileImage()
                }
                .sharedBackgroundVisibility(.hidden)
            }
        }
    }

    private var bottomBar: some View {
        GlassEffectContainer {
            HStack {
                if gameHistory.count > 1 || showOnlyFavorites == true {
                    sortMenu
                }
                Spacer()
            }
        }
    }

    private func switchToFav() {
        withAnimation(.easeInOut) {
            if switchedGameIdFav != nil {
                showOnlyFavorites = true
                switchedGameId = selectedGameId
                selectedGameId = switchedGameIdFav
                scrolledGameId = switchedGameIdFav
            } else {
                showOnlyFavorites = true
                switchedGameId = selectedGameId
                let firstId = gameHistory.first?.id
                selectedGameId = firstId
                scrolledGameId = firstId
            }
        }
    }

    private func switchToAll() {
        withAnimation(.easeInOut) {
            showOnlyFavorites = false
            switchedGameIdFav = selectedGameId
            selectedGameId = switchedGameId
            scrolledGameId = switchedGameId
            
        }
    }

    private var sortMenu: some View {
        Menu {
            Button {
                switchToAll()
            } label: {
                if showOnlyFavorites == false { Image(systemName: "checkmark") } else { Image(systemName: "list.bullet") }
                Text(String(localized: "history.sortBy.allRounds"))
            }.disabled(network.games.sorted { $0.date > $1.date }.filter { $0.winner != nil }.filter { $0.favorite }.count == 0)
            Button {
                switchToFav()
            } label: {
                if showOnlyFavorites == true { Image(systemName: "checkmark") } else { Image(systemName: "star.fill") }
                Text(String(localized: "history.sortBy.favorites"))
            }.disabled(network.games.sorted { $0.date > $1.date }.filter { $0.winner != nil }.filter { $0.favorite }.count == 0)

            Divider()
            Button {
                withAnimation(.easeInOut) {
                    dateUp = false
                    selectedGameId = gameHistory.first?.id
                }
            } label: {
                if dateUp == false { Image(systemName: "checkmark") } else { Image("clock.down") }
                Text(String(localized: "history.sortBy.byDateDown"))
            }
            Button {
                withAnimation(.easeInOut) {
                    dateUp = true
                    selectedGameId = gameHistory.first?.id
                }
            } label: {
                if dateUp == true { Image(systemName: "checkmark") } else { Image("clock.up") }
                Text(String(localized: "history.sortBy.byDateUp"))
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .font(.system(size: 22))
                .foregroundColor(showOnlyFavorites == true ? Color.accent : Color.primary)
        }
        .labelStyle(.titleAndIcon)
        .menuOrder(.fixed)
        .padding(10)
        .glassEffect(.regular.interactive(), in: Circle())
        .padding(.leading, 20)
        .padding(.bottom, 10)
    }
}

// MARK: - GameRow

struct GameRow: View {
    let game: Game
    let isSelected: Bool
    let userId: Int
    let profiles: [Profile]
    let network: NetworkService
    let historySpace: Namespace.ID
    let colorScheme: ColorScheme
    let selectedCounter: Int

    @Binding var sheetGame: Game?
    @Binding var scrolledGameId: Int?

    @State private var renderedImage: Image?

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("d")
        f.locale = Locale.current
        return f
    }()

    private static let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("MMM")
        f.locale = Locale.current
        return f
    }()

    private func playerName(_ id: Int?) -> String {
        guard let id else { return String(localized: "general.unknown") }
        return profiles.first { $0.id == id }?.name ?? String(localized: "general.unknown")
    }

    private func isWinner(player_id: Int, game: Game) -> Bool {
        var team = 0
        if player_id == game.team1Player1Id || player_id == game.team1Player2Id {
            team = 1
        } else if player_id == game.team2Player1Id || player_id == game.team2Player2Id {
            team = 2
        }
        return team == game.winner
    }

    var body: some View {
        let languageCode = Locale.current.language.languageCode?.identifier ?? "en"
        let day = Self.dayFormatter.string(from: game.date)
        let month = Self.monthFormatter.string(from: game.date)

        Button {
            sheetGame = game
        } label: {
            HStack(alignment: .center) {
                ZStack {
                    VStack {
                        if languageCode == "de" {
                            Text("\(day).").redactedShimmer()
                            Text("\(month).").redactedShimmer()
                        } else {
                            Text(day).redactedShimmer()
                            Text(month).redactedShimmer()
                        }
                    }
                    .font(.system(size: 15))
                    .multilineTextAlignment(.center)
                    .padding(.trailing, 15)
                    .padding(.leading, 10)

                    if game.favorite {
                        Image(systemName: "star.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(.secondary)
                            .offset(x: -25)
                    }
                }

                VStack(alignment: .leading) {
                    HStack {
                        if isWinner(player_id: userId, game: game) {
                            Image(systemName: "trophy.fill").font(.system(size: 15)).redactedShimmer()
                        } else {
                            Image("trophy.slash.fill").font(.system(size: 15)).offset(x: -3).redactedShimmer()
                        }
                        Text("\(game.currentPointsTeam1) : \(game.currentPointsTeam2)")
                            .redactedShimmer()
                            .font(.system(size: 20))
                            .fontWeight(.bold)
                    }
                    HStack(spacing: 3) {
                        let player1Name = playerName(game.team1Player1Id)
                        let player2Name = game.team1Player2Id == -2
                            ? (game.guest2Name ?? String(localized: "play.guest"))
                            : playerName(game.team1Player2Id)
                        let player3Name = game.team2Player1Id == -3
                            ? (game.guest3Name ?? String(localized: "play.guest"))
                            : playerName(game.team2Player1Id)
                        let player4Name = game.team2Player2Id == -4
                            ? (game.guest4Name ?? String(localized: "play.guest"))
                            : playerName(game.team2Player2Id)

                        Text("\(player1Name) & \(player2Name)").foregroundStyle(Color.accent).redactedShimmer()
                        Text(":").redactedShimmer()
                        Text("\(player3Name) & \(player4Name)").redactedShimmer()
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.tertiary)
                    .padding(.trailing, 10)
            }
            .padding(8)
            .padding(.vertical, 5)
            .background(
                colorScheme == .dark ? Color(uiColor: .tertiarySystemFill) : .white,
                in: .rect(cornerRadius: 24)
            )
            .foregroundColor(.primary)
            .overlay {
                RoundedRectangle(cornerRadius: 24)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            }
        }
        .matchedTransitionSource(id: "\(game.id)", in: historySpace)
        .sensoryFeedback(.selection, trigger: isSelected && selectedCounter > 0)
        .popoverTip(HistoryTapTip(), arrowEdge: .bottom)
        .contextMenu {
            Button {
                sheetGame = game
            } label: {
                Image(systemName: "arrow.up.right.square")
                Text(String(localized: "history.context.openGame"))
                Text("\(game.currentPointsTeam1) : \(game.currentPointsTeam2)")
            }
            Button {
                
                Task {
                    //This is the only way i got the view to update the Star on the left side of the GameRow
                    //Delay becaue wait till the conextmenu close animaiton has finished before forcing a redraw on line 114
                    try? await Task.sleep(nanoseconds: 275_000_000) // 0.275s
                    await network.updateGameFavorite(gameId: game.id, favorite: !game.favorite)
                }
            } label: {
                Text(game.favorite ? String(localized: "history.context.unfavorite") : String(localized: "history.context.favorite"))
                Image(systemName: game.favorite ? "star.slash.fill" : "star.fill")
            }.sensoryFeedback(.success, trigger: game.favorite)
            if let renderedImage {
                ShareLink(
                    item: renderedImage,
                    message: Text(String(localized: "history.share.check")),
                    preview: SharePreview("Tichu game", image: renderedImage)
                )
                .foregroundColor(.primary)
            } else {
                Button {} label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text(String(localized: "general.share"))
                        ProgressView()
                    }
                }.disabled(true)
            }
        } preview: {
            GameSummaryListView(
                showGameSummarySheetView: .constant(true),
                currentGameId: game.id,
                profiles: profiles,
                network: network,
                allowEditing: .constant(false)
            )
            .onAppear {
                let renderer = ImageRenderer(content: GameSummaryShareView(
                    currentGameId: game.id,
                    rounds: network.roundsByGame[game.id] ?? [],
                    profiles: profiles,
                    accentCo: .accent
                )
                .environment(\.colorScheme, colorScheme)
                .background(colorScheme == .dark ? Color.black : Color.white))
                renderer.scale = 3
                if let image = renderer.cgImage {
                    renderedImage = Image(decorative: image, scale: 1)
                }
            }
        }
        .id(game.id)
    }
}

#Preview {
    HistoryView(sheetGame: .constant(nil), selectedGameId: .constant(nil), scrolledGameId: .constant(nil))
}
