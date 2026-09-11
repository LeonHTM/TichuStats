//
//  StatsView.swift
//  Tichu
//
//  Created by Leon on 21.04.2026.
//

import SwiftUI

struct StatsView: View {
    @State private var renderedImage: Image?
    @ObservedObject private var network = NetworkService.shared
    @StateObject private var socket = SocketService.shared
    // MARK: - Storage
    @AppStorage("userId") var userId: Int = -69420
    @AppStorage("userName") var userName: String = "Unknown"
    @AppStorage("isLoading") private var isLoading = false
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("defaultAllowPingus") private var defaultAllowPingus: Bool = true
    
    @State private var showDebugSheetView: Bool = false
    
    // MARK: - State
    @State private var showAddPlayersSheet: Bool = false
    @State private var timeTags: [String] = [
        String(localized: "statistics.timeframes.alltime"),
        String(localized: "statistics.timeframes.year"),
        String(localized: "statistics.timeframe.month"),
        String(localized: "statistics.timeframe.week"),
        String(localized: "statistics.timeframe.day")
    ]
    @State private var selectedTags: [String] = [String(localized: "statistics.timeframes.alltime")]
    @State private var sortStat: Profile.playerStat = .elo
    @State private var sortBy: sortBy = .valueDown
    @AppStorage("statsList") private var compareList: [Int] = []
    @AppStorage("sortByStats") var sortByStats: sortBy = .valueDown
    @State private var addPlayerId: Int?
    @State private var showOfflineAlert: Bool = false
    
    // MARK: - Computed
    var filterActive: Bool { sortBy != sortByStats }

    var selectedTimeframe: Timeframe {
        withAnimation(.easeInOut){
            switch selectedTags.first {
            case String(localized: "statistics.timeframes.year"):  return .year
            case String(localized: "statistics.timeframe.month"): return .month
            case String(localized: "statistics.timeframe.week"):  return .week
            case String(localized: "statistics.timeframe.day"): return .day
            default:      return .allTime
            }
        }
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            
            ScrollView {
                statsGrid
                    .animation(.easeInOut, value: selectedTags)
                    .animation(.easeInOut, value: isLoading)
                    .animation(.easeInOut, value: compareList.map { $0 })
                    .padding()
            }.scrollEdgeEffectStyle(.soft, for: .all)
            .sheet(isPresented: $showAddPlayersSheet, onDismiss: {
                withAnimation(.easeInOut) {
                    if !compareList.contains(where: { $0 == addPlayerId }) && addPlayerId != nil {
                        compareList.append(addPlayerId!)
                    }
                }
            }) {
                AddPlayersSheetView(
                    showAddPlayersSheet: $showAddPlayersSheet,
                    addPlayerId: $addPlayerId,
                    alreadyAdded: compareList,
                    showGuest: .constant(false),
                    showPlayers: .constant(true),
                    showFriends: .constant(true),
                    guestName: .constant(String(localized:"play.guest")),
                    guestIndex: 2,
                    showMenu: true
                )
                .presentationDetents(UIDevice.current.userInterfaceIdiom == .pad ? [.large] : [.medium, .large])
            }
           
            .onChange(of: network.isOnline) {
                if !network.isOnline {
                    showAddPlayersSheet = false
                }
            }
            .onFirstAppear{
                sortBy = sortByStats
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .refreshable {
                if network.isOnline {
                    Task {
                        await network.fetchSelectedProfilesStats()
                    }
                }
            }
            .navigationTitle(String(localized: "general.title.statistics"))
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                if network.profiles.first(where: { $0.id == userId })?.isAdmin == true{
                    ToolbarItem {
                        Button { showDebugSheetView = true } label: {
                            Image(systemName: "ant").foregroundStyle(socket.connected && network.apiURL == getURL() ? Color.green : network.apiURL == getURL(dev:true) && socket.connected ? Color.orange : Color.red)
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationProfileImage()
                }
                .sharedBackgroundVisibility(.hidden)
            }
            .sheet(isPresented: $showDebugSheetView) {
                DebugSheetView(
                    currentGame: Binding(
                        get: { network.games.first(where: { $0.id == network.currentGameId }) ?? Game(favorite: false,id: 0, date: Date(), target: 1000, allowPingus: true, currentPointsTeam1: 0, currentPointsTeam2: 0) },
                        set: { network.currentGameId = $0.id }
                    ),
                    showDebugSheetView: $showDebugSheetView
                )
            }
            .safeAreaInset(edge: .top) { timeFilterChips }
            .safeAreaInset(edge: .bottom) { bottomBar }
        }
    }
    
    // MARK: - Stats Grid
    private var statsGrid: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 170), spacing: 8, alignment: .top)],
            spacing: 8
        ) {
            StatsContainer(
                title: String(localized: "statistics.statscontainer.title.rating"),
                description: String(localized: "statistics.statscontainer.description.rating"),
                image: "chart.line.uptrend.xyaxis",
                counterLeft: 1,
                counterRight: 500,
                value: network.profiles.first { $0.id == userId }?.elo ?? 1000,
                percentage: false,
                inTop: 0.025,
                stat: .elo,
                timeframe: selectedTimeframe,
                items: makeItems(from: compareList, stat: .elo, sortBy: sortBy, timeframe: selectedTimeframe)
            )
            .transition(.opacity.combined(with: .scale))
            .contextMenu { shareContextMenu }

            StatsContainer(
                title: String(localized: "statistics.statscontainer.title.winner"),
                description: String(localized: "statistics.statscontainer.description.winner"),
                image: "trophy",
                counterLeft: 1,
                counterRight: 500,
                value: network.profiles.first { $0.id == userId }?.getStat(for: .winnerPercentage, timeframe: selectedTimeframe) ?? 0,
                percentage: true,
                inTop: 0.1,
                stat: .winnerPercentage,
                timeframe: selectedTimeframe,
                items: makeItems(from: compareList, stat: .winnerPercentage, sortBy: sortBy, timeframe: selectedTimeframe)
            )
            .transition(.opacity.combined(with: .scale))
            .contextMenu { shareContextMenu }
            
            StatsContainer(
                title: String(localized: "statistics.statscontainer.title.climber"),
                description: String(localized: "statistics.statscontainer.description.climber"),
                image: "trophy",
                counterLeft: 1,
                counterRight: 500,
                value: network.profiles.first { $0.id == userId }?.getStat(for: .averagePlacement, timeframe: selectedTimeframe) ?? 0,
                percentage: false,
                inTop: 0.1,
                stat: .averagePlacement,
                timeframe: selectedTimeframe,
                items: makeItems(from: compareList, stat: .averagePlacement, sortBy: sortBy, timeframe: selectedTimeframe),
                digits:2
            )
            .transition(.opacity.combined(with: .scale))
            .contextMenu { shareContextMenu }

            StatsContainer(
                title: String(localized: "statistics.statscontainer.title.tichumaster"),
                description: String(localized: "statistics.statscontainer.description.tichumaster"),
                image: "number",
                counterLeft: 1,
                counterRight: 500,
                value: network.profiles.first { $0.id == userId }?.getStat(for: .tichuMaster, timeframe: selectedTimeframe) ?? 0,
                percentage: false,
                inTop: 0.75,
                stat: .tichuMaster,
                timeframe: selectedTimeframe,
                items: makeItems(from: compareList, stat: .tichuMaster, sortBy: sortBy, timeframe: selectedTimeframe)
            )
            .transition(.opacity.combined(with: .scale))
            .contextMenu { shareContextMenu }

            StatsContainer(
                title: String(localized: "statistics.statscontainer.title.visionary"),
                description: String(localized: "statistics.statscontainer.description.visionary"),
                image: "checkmark.circle",
                counterLeft: 1,
                counterRight: 500,
                value: network.profiles.first { $0.id == userId }?.getStat(for: .visionary, timeframe: selectedTimeframe) ?? 0,
                percentage: true,
                inTop: 0.025,
                stat: .visionary,
                timeframe: selectedTimeframe,
                items: makeItems(from: compareList, stat: .visionary, sortBy: sortBy, timeframe: selectedTimeframe)
            )
            .transition(.opacity.combined(with: .scale))
            .contextMenu { shareContextMenu }

            StatsContainer(
                title: String(localized: "statistics.statscontainer.title.addict"),
                description: String(localized: "statistics.statscontainer.description.addict"),
                image: "pill",
                counterLeft: 1,
                counterRight: 500,
                value: network.profiles.first { $0.id == userId }?.getStat(for: .addict, timeframe: selectedTimeframe) ?? 0,
                percentage: false,
                inTop: 0.9,
                stat: .addict,
                timeframe: selectedTimeframe,
                items: makeItems(from: compareList, stat: .addict, sortBy: sortBy, timeframe: selectedTimeframe)
            )
            .transition(.opacity.combined(with: .scale))
            .contextMenu { shareContextMenu }

            StatsContainer(
                title: String(localized: "statistics.statscontainer.title.teamplayer"),
                description: String(localized: "statistics.statscontainer.description.teamplayer"),
                image: "hands.clap",
                counterLeft: 1,
                counterRight: 500,
                value: network.profiles.first { $0.id == userId }?.getStat(for: .teamplayer, timeframe: selectedTimeframe) ?? 0,
                percentage: true,
                inTop: 0.06,
                stat: .teamplayer,
                timeframe: selectedTimeframe,
                items: makeItems(from: compareList, stat: .teamplayer, sortBy: sortBy, timeframe: selectedTimeframe)
            )
            .transition(.opacity.combined(with: .scale))
            .contextMenu { shareContextMenu }

            StatsContainer(
                title: String(localized: "statistics.statscontainer.title.announcer"),
                description: String(localized: "statistics.statscontainer.description.announcer"),
                image: "megaphone",
                counterLeft: 1,
                counterRight: 500,
                value: network.profiles.first { $0.id == userId }?.getStat(for: .announcer, timeframe: selectedTimeframe) ?? 0,
                percentage: true,
                inTop: 0.76,
                stat: .announcer,
                timeframe: selectedTimeframe,
                items: makeItems(from: compareList, stat: .announcer, sortBy: sortBy, timeframe: selectedTimeframe)
            )
            .transition(.opacity.combined(with: .scale))
            .contextMenu { shareContextMenu }

            StatsContainer(
                title: String(localized: "statistics.statscontainer.title.saboteur"),
                description: String(localized: "statistics.statscontainer.description.saboteur"),
                image: "xmark.circle",
                counterLeft: 1,
                counterRight: 500,
                value: network.profiles.first { $0.id == userId }?.getStat(for: .saboteur, timeframe: selectedTimeframe) ?? 0,
                percentage: true,
                inTop: 0.87,
                stat: .saboteur,
                timeframe: selectedTimeframe,
                items: makeItems(from: compareList, stat: .saboteur, sortBy: sortBy, timeframe: selectedTimeframe)
            )
            .transition(.opacity.combined(with: .scale))
            .contextMenu { shareContextMenu }

            StatsContainer(
                title: String(localized: "statistics.statscontainer.title.gambler"),
                description: String(localized: "statistics.statscontainer.description.gambler"),
                image: "exclamationmark.circle",
                counterLeft: 1,
                counterRight: 500,
                value: network.profiles.first { $0.id == userId }?.getStat(for: .gambler, timeframe: selectedTimeframe) ?? 0,
                percentage: true,
                inTop: 0.9,
                stat: .gambler,
                timeframe: selectedTimeframe,
                items: makeItems(from: compareList, stat: .gambler, sortBy: sortBy, timeframe: selectedTimeframe)
            )
            .transition(.opacity.combined(with: .scale))
            .contextMenu { shareContextMenu }

            StatsContainer(
                title: String(localized: "statistics.statscontainer.title.bigGambler"),
                description: String(localized: "statistics.statscontainer.description.bigGambler"),
                image: "exclamationmark.2.circle",
                counterLeft: 1,
                counterRight: 500,
                value: network.profiles.first { $0.id == userId }?.getStat(for: .bigGambler, timeframe: selectedTimeframe) ?? 0,
                percentage: true,
                inTop: 0.1,
                stat: .bigGambler,
                timeframe: selectedTimeframe,
                items: makeItems(from: compareList, stat: .bigGambler, sortBy: sortBy, timeframe: selectedTimeframe)
            )
            .transition(.opacity.combined(with: .scale))
            .contextMenu { shareContextMenu }
            if defaultAllowPingus == true{
                StatsContainer(
                    title: String(localized: "statistics.statscontainer.title.pinguGambler"),
                    description: String(localized: "statistics.statscontainer.description.pinguGambler"),
                    image: "exclamationmark.3.circle",
                    counterLeft: 1,
                    counterRight: 500,
                    value: network.profiles.first { $0.id == userId }?.getStat(for: .pinguGambler, timeframe: selectedTimeframe) ?? 0,
                    percentage: true,
                    inTop: 0.1,
                    stat: .pinguGambler,
                    timeframe: selectedTimeframe,
                    items: makeItems(from: compareList, stat: .pinguGambler, sortBy: sortBy, timeframe: selectedTimeframe)
                )
                .transition(.opacity.combined(with: .scale))
                .contextMenu { shareContextMenu }
            }

            StatsContainer(
                title: String(localized: "statistics.statscontainer.title.bomber"),
                description: String(localized: "statistics.statscontainer.description.bomber"),
                image: "bomb",
                counterLeft: 1,
                counterRight: 500,
                value: network.profiles.first { $0.id == userId }?.getStat(for: .bomber, timeframe: selectedTimeframe) ?? 0,
                percentage: true,
                inTop: 0.9,
                stat: .bomber,
                timeframe: selectedTimeframe,
                items: makeItems(from: compareList, stat: .bomber, sortBy: sortBy, timeframe: selectedTimeframe)
            )
            .transition(.opacity.combined(with: .scale))
            .contextMenu { shareContextMenu }
        }
        .task {
            let profile = network.profiles.first { $0.id == userId }
            var tags: [String] = []
            var shareTags: [String] = []

            
            tags.append("\(String(localized: "statistics.statscontainer.title.visionary")): \(profile?.getStat(for: .visionary, timeframe: selectedTimeframe) ?? 0)")
            tags.append("\(String(localized: "statistics.statscontainer.title.addict")): \(profile?.getStat(for: .addict, timeframe: selectedTimeframe) ?? 0)")
            tags.append("\(String(localized: "statistics.statscontainer.title.teamplayer")): \(profile?.getStat(for: .teamplayer, timeframe: selectedTimeframe) ?? 0)")
            tags.append("\(String(localized: "statistics.statscontainer.title.announcer")): \(profile?.getStat(for: .announcer, timeframe: selectedTimeframe) ?? 0)")
            tags.append("\(String(localized: "statistics.statscontainer.title.saboteur")): \(profile?.getStat(for: .saboteur, timeframe: selectedTimeframe) ?? 0)")
            tags.append("\(String(localized: "statistics.statscontainer.title.gambler")): \(profile?.getStat(for: .gambler, timeframe: selectedTimeframe) ?? 0)")
            tags.append("\(String(localized: "statistics.statscontainer.title.bigGambler")): \(profile?.getStat(for: .bigGambler, timeframe: selectedTimeframe) ?? 0)")
            tags.append("\(String(localized: "statistics.statscontainer.title.pinguGambler")): \(profile?.getStat(for: .pinguGambler, timeframe: selectedTimeframe) ?? 0)")
            tags.append("\(String(localized: "statistics.statscontainer.title.bomber")): \(profile?.getStat(for: .bomber, timeframe: selectedTimeframe) ?? 0)")


            shareTags.append("\(String(localized: "statistics.statscontainer.title.visionary")): \(Int((profile?.getStat(for: .visionary, timeframe: selectedTimeframe) ?? 0) * 100))%")
            shareTags.append("\(String(localized: "statistics.statscontainer.title.addict")): \(profile?.getStat(for: .addict, timeframe: selectedTimeframe) ?? 0)")
            shareTags.append("\(String(localized: "statistics.statscontainer.title.teamplayer")): \(Int((profile?.getStat(for: .teamplayer, timeframe: selectedTimeframe) ?? 0) * 100))%")
            shareTags.append("\(String(localized: "statistics.statscontainer.title.announcer")): \(Int((profile?.getStat(for: .announcer, timeframe: selectedTimeframe) ?? 0) * 100))%")
            shareTags.append("\(String(localized: "statistics.statscontainer.title.saboteur")): \(Int((profile?.getStat(for: .saboteur, timeframe: selectedTimeframe) ?? 0) * 100))%")
            shareTags.append("\(String(localized: "statistics.statscontainer.title.gambler")): \(Int((profile?.getStat(for: .gambler, timeframe: selectedTimeframe) ?? 0) * 100))%")
            shareTags.append("\(String(localized: "statistics.statscontainer.title.bigGambler")): \(Int((profile?.getStat(for: .bigGambler, timeframe: selectedTimeframe) ?? 0) * 100))%")
            shareTags.append("\(String(localized: "statistics.statscontainer.title.pinguGambler")): \(Int((profile?.getStat(for: .pinguGambler, timeframe: selectedTimeframe) ?? 0) * 100))%")
            shareTags.append("\(String(localized: "statistics.statscontainer.title.bomber")): \(Int((profile?.getStat(for: .bomber, timeframe: selectedTimeframe) ?? 0) * 100))%")
            

            let renderer = ImageRenderer(content: ShareStatsView(
                userName: profile?.name ?? String(localized: "general.unknown"),
                userImageData: network.profileImages[userId],
                elo: profile?.elo ?? 1000.0,
                winnerPercentage: profile?.getStat(for: .winnerPercentage, timeframe: selectedTimeframe) ?? 0,
                tichuMaster: profile?.getStat(for: .tichuMaster, timeframe: selectedTimeframe) ?? 0,
                accentCo: .accent,
                Tags: .constant(shareTags)
            )
            .environment(\.colorScheme, colorScheme)
            .background(colorScheme == .dark ? Color.black : Color.white))
            renderer.scale = 3
            if let image = renderer.cgImage {
                renderedImage = Image(decorative: image, scale: 1)
            }
        }
    }

    // MARK: - Share Context Menu
    @ViewBuilder
    private var shareContextMenu: some View {
        if let renderedImage {
            ShareLink(
                userName == "Luis" ? String(localized:"statistics.luis") : String(localized:"statistics.share"),
                item: renderedImage,
                message: Text(String(localized:"statistics.share.check")),
                preview: SharePreview("Tichu Statistics", image: renderedImage)
            )
            .foregroundColor(.primary)
        } else {
            Button {} label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text(String(localized:"general.share"))
                    ProgressView()
                }
            }.disabled(true)
        }
    }
    
    // MARK: - Time Filter Chips
    private var timeFilterChips: some View {
        ChipsView(tags: timeTags, onlyOne: true) { tag, isSelected in
            if !network.isOnline {
                ChipView(tag: tag, isSelected: isSelected, showAlert: true)
            } else {
                ChipView(tag: tag, isSelected: isSelected, showAlert: false)
            }
        } didChangeSelection: { selection in
            if selection.isEmpty {
                selectedTags = [String(localized: "statistics.timeframes.alltime")]
            } else {
                selectedTags = selection
            }
        }
        .padding(.leading, 10)
    }
    
    // MARK: - Bottom Bar
    private var bottomBar: some View {
        GlassEffectContainer {
            HStack {
                if compareList.count > 1 {
                    sortMenu
                }
                Spacer()
                if !isLoading {
                    compareMenu
                }
               
            }
        }
    }
    
    // MARK: - Sort Menu
    private var sortMenu: some View {
        Menu {
            Button {
                sortBy = .nameDown
            } label: {
                if sortBy == .nameDown { Image(systemName: "checkmark") } else { Image("ABC.down") }
                Text(String(localized: "statistics.sort.abcdown"))
            }
            Button {
                sortBy = .nameUp
            } label: {
                if sortBy == .nameUp { Image(systemName: "checkmark") } else { Image("ABC.up") }
                Text(String(localized: "statistics.sort.abcup"))
            }
            Divider()
            Button {
                sortBy = .valueDown
            } label: {
                if sortBy == .valueDown { Image(systemName: "checkmark") } else { Image("123.down") }
                Text(String(localized: "statistics.sort.123down"))
            }
            Button {
                sortBy = .valueUp
            } label: {
                if sortBy == .valueUp { Image(systemName: "checkmark") } else { Image("123.up") }
                Text(String(localized: "statistics.sort.123up"))
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .font(.system(size: 22))
                .foregroundColor(filterActive ? Color.accent : Color.primary)
        }
        .labelStyle(.titleAndIcon)
        .menuOrder(.fixed)
        .padding(10)
        .glassEffect(.regular.interactive(), in: Circle())
        .padding(.leading, 20)
        .padding(.bottom, 10)
    }
    
    // MARK: - Compare Menu
    private var compareMenu: some View {
        if network.isOnline  {
            return AnyView(
                Menu {
                    Button {
                        showAddPlayersSheet = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                        Text(String(localized: "statistics.compare.addPlayer"))
                    }
                    if !compareList.isEmpty {
                        Divider()
                    }
                    ForEach(compareList, id: \.self) { item in
                        Button {
                            withAnimation(.easeInOut) {
                                compareList.removeAll { $0 == item }
                            }
                        } label: {
                            Image("person.badge.remove")
                            Text(String(format:String(localized:"statistics.compare.remove"), network.profiles.first { $0.id == item }?.name ?? String(localized: "general.unknown")))
                        }
                    }
                    if compareList.count > 1 {
                        Divider()
                        Button {
                            compareList = []
                        } label: {
                            Image(systemName: "minus.circle")
                            Text(String(localized:"statistics.compare.removeAllPlayers"))
                        }
                    }
                } label: {
                    Image("person.badge.edit")
                        .font(.system(size: 20))
                        .foregroundColor(.primary)
                    Text(String(localized: "statistics.title.comparison"))
                        .foregroundColor(.primary)
                }
                .labelStyle(.titleAndIcon)
                .menuOrder(.fixed)
                .padding(10)
                .glassEffect(.regular.interactive())
                .padding(.trailing, 20)
                .padding(.bottom, 10)
            )
        } else {
            return AnyView(
                Button(action: {
                    showOfflineAlert = true
                }) {
                    HStack {
                        Image("person.badge.edit")
                            .font(.system(size: 20))
                            .foregroundColor(.primary)
                        Text(String(localized: "statistics.title.comparison"))
                            .foregroundColor(.primary)
                    }
                }
                .alert(isPresented: $showOfflineAlert) {
                    OfflineView.offlineAlert()
                }
                .padding(10)
                .glassEffect(.regular.interactive())
                .padding(.trailing, 20)
                .padding(.bottom, 10)
            )
        }
    }
}

#Preview {
    StatsView()
}
