//
//  AddPlayersSheetView.swift
//  Tichu
//
//  Created by Leon on 23.04.2026.
//

import SwiftUI

struct AddPlayersSheetView: View {

    // MARK: - Bindings
    @Binding var showAddPlayersSheet: Bool
    @Binding var addPlayerId: Int?
    var alreadyAdded: [Int]
    @Binding var showGuest: Bool
    @Binding var showPlayers: Bool
    @Binding var showFriends: Bool
    @Binding var guestName: String
    
    var guestIndex: Int
    var showMenu: Bool
    @AppStorage("userId") var userId: Int = -69420
    @AppStorage("showAllPlayers") private var showAllPlayers: Bool = false
    @AppStorage("sortByProfiles") var sortByProfiles: sortBy = .nameDown
    @StateObject private var socket = SocketService.shared

    // MARK: - State
    @ObservedObject private var network = NetworkService.shared
    
    @State private var searchText: String = ""
    @State private var sortByFriends: sortBy = .nameDown
    @State private var sortByPlayers: sortBy = .nameDown
    @State private var showPlayerInGameAlert: Bool = false
    @State private var inGameStatus: [Int: Bool] = [:]
    @State private var isLoadingStatus: Bool = true
    @State private var hideUnavailableFriends: Bool = true
    @State private var hideUnavailablePlayers: Bool = true
    @State private var showNameAlert: Bool = false

    // MARK: - Computed
    var friendsFilterActive: Bool { sortByFriends != sortByProfiles || hideUnavailableFriends }
    var playersFilterActive: Bool { sortByPlayers != sortByProfiles || hideUnavailablePlayers }

    var query: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var sortedFriends: [Friend] {
        makeItems(
            from: network.friends.filter {
                if hideUnavailableFriends {
                    let isAdded = alreadyAdded.contains($0.id)
                    let inGame = inGameStatus[$0.id] ?? false
                    if showGuest && (isAdded || inGame) { return false }
                    if !showGuest && isAdded { return false }
                }
                guard !query.isEmpty else { return true }
                return ($0.profile.name ?? "").range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil
            },
            stat: .elo,
            sortBy: sortByFriends
        )
    }

    var sortedPlayers: [Profile] {
        makeItems(
            from: network.profiles.filter {
                guard $0.id > 0 else { return false }
                guard $0.id != userId else { return false }
                if hideUnavailablePlayers {
                    let isAdded = alreadyAdded.contains($0.id)
                    let inGame = inGameStatus[$0.id] ?? false
                    if showGuest && (isAdded || inGame) { return false }
                    if !showGuest && isAdded { return false }
                }
                guard !query.isEmpty else { return true }
                return ($0.name ?? "")
                    .range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil
            },
            stat: .elo,
            sortBy: sortByPlayers
        )
    }

    // MARK: - Hide unavailable label depending on mode
    var hideUnavailableLabel: String {
        if showGuest { return String(localized:"addPlayers.hidePlayers") }
        if showFriends { return String(localized:"addPlayers.hideExisting") }
        return String(localized:"addPlayers.hideComparing")
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            List {
                if isLoadingStatus && showGuest {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    }
                    .listRowBackground(Color.clear)
                } else {
                    if query.isEmpty {
                        if showGuest { guestRow }
                    } else if sortedFriends.isEmpty && sortedPlayers.isEmpty {
                        noResultsRow
                    }

                    if showFriends {
                        if !sortedFriends.isEmpty { friendsHeader }
                        friendsRows
                    }

                    if showPlayers {
                        if !sortedPlayers.isEmpty { playersHeader }
                        playersRows
                    }
                }
            }.onAppear{
                sortByPlayers = sortByProfiles
                sortByFriends = sortByProfiles
            }
            .listSectionSpacing(0)
            .animation(.easeInOut, value: searchText)
            .animation(.easeInOut, value: isLoadingStatus)
            .navigationTitle(
                showMenu == false ? "" : showPlayers && showFriends ? String(localized:"addPlayers.title.addPlayers") :
                        !showFriends ? String(localized:"addPlayers.title.requestFriend") : String(localized:"addPlayers.title.editFriends")
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if showMenu == true {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel", systemImage: "xmark") {
                            showAddPlayersSheet = false
                        }.searchable(text: $searchText)
                    }
                }
            }
            .task {
                hideUnavailableFriends = !showAllPlayers
                hideUnavailablePlayers = !showAllPlayers
                guard showGuest else {
                    isLoadingStatus = false
                    return
                }
                await preloadInGameStatus()
            }
        }
    }

    // MARK: - Preload in-game status (only for round-adding mode)
    private func preloadInGameStatus() async {
        let ids = network.profiles.map { $0.id } + network.friends.map { $0.id }
        let uniqueIds = Array(Set(ids)).filter { $0 > 0 && $0 != userId }

        await withTaskGroup(of: (Int, Bool).self) { group in
            for id in uniqueIds {
                group.addTask {
                    let status = await network.isInOpenGame(profileId: id)
                    return (id, status)
                }
            }
            for await (id, status) in group {
                await MainActor.run {
                    inGameStatus[id] = status
                }
            }
        }

        await MainActor.run {
            isLoadingStatus = false
        }
    }

    // MARK: - Guest Row
    private var guestRow: some View {
        Section {
            HStack {
                ProfileImage(data: nil, size: 44)
                Button(String(localized:"addPlayers.guest")) {
                    showNameAlert = true
                    
                    
                }.alert(String(format:String(localized:"play.alert.enterName")), isPresented: $showNameAlert) {
                    TextField(String(localized:"play.guestName"), text: $guestName)
                    Button(String(localized: "general.alert.save"),role:.confirm) {
                        if guestIndex == 2 {
                                                addPlayerId = -2
                                            } else if guestIndex == 3 {
                                                addPlayerId = -3
                                            } else {
                                                addPlayerId = -4
                                            }
                        showNameAlert = false
                        showAddPlayersSheet = false
                    }

                    Button(String(localized:"general.alert.cancel"), role: .cancel) {
                        showNameAlert = false
                    }
                }
                
                .foregroundColor(.primary)
                Spacer()
            }
        }
    }

    // MARK: - No Results Row
    private var noResultsRow: some View {
        VStack(alignment: .center) {
            Spacer()
            HStack {
                Image(systemName: "magnifyingglass")
                Text(String(format:String(localized:"addPlayers.couldnotfind"), String(query)))
            }
            Spacer()
        }
    }

    // MARK: - Friends Header
    private var friendsHeader: some View {
        Section {
            HStack {
                Text(String(localized:"addPlayers.friends")).fontWeight(.bold)
                Spacer()
                if sortedFriends.count != 1 {
                    sortMenu(
                        active: friendsFilterActive,
                        binding: $sortByFriends,
                        hideUnavailable: $hideUnavailableFriends,
                        showDateOptions: false
                    )
                }
            }
        }
        .listRowBackground(Color.clear)
    }

    // MARK: - Friends Rows
    private var friendsRows: some View {
        Section {
            ForEach(sortedFriends) { friend in
                playerButton(profileId: friend.id)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    // MARK: - Players Header
    private var playersHeader: some View {
        Section {
            HStack {
                Text(String(localized:"addPlayers.allPlayers")).fontWeight(.bold)
                Spacer()
                if sortedPlayers.count != 1 {
                    sortMenu(
                        active: playersFilterActive,
                        binding: $sortByPlayers,
                        hideUnavailable: $hideUnavailablePlayers,
                        showDateOptions: false
                    )
                }
            }
        }
        .listRowBackground(Color.clear)
    }

    // MARK: - Players Rows
    private var playersRows: some View {
        ForEach(sortedPlayers) { profile in
            playerButton(profileId: profile.id)
                .alert(String(localized:"addPlayers.alert.inGame.title"), isPresented: $showPlayerInGameAlert) {
                    Button("Cancel", role: .cancel) {
                        showPlayerInGameAlert = false
                    }
                } message: {
                    Text(String(localized:"addPlayers.alert.inGame.description"))
                }
                .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    // MARK: - Player Button
    private func playerButton(profileId: Int) -> some View {
        let isAdded = alreadyAdded.contains(where: { $0 == profileId })
        let profile = network.profiles.first(where: { $0.id == profileId })
        let inGame = inGameStatus[profileId] ?? false

        return Button {
            if showGuest == false {
                Task {
                    await network.fetchProfilesStats(profileId: profileId)
                    addPlayerId = profileId
                    showAddPlayersSheet = false
                }
            } else {
                guard !inGame else {
                    showPlayerInGameAlert = true
                    return
                }
                addPlayerId = profileId
                showAddPlayersSheet = false
            }
        } label: {
            HStack {
                ProfileImage(
                    data: network.profileImages[profileId],
                    size: 44
                )
                Text(profile?.name ?? String(localized: "general.unknown"))
                Spacer()
                if (inGame || isAdded) && showGuest {
                    Text(String(localized:"addPlayers.currentlyInGame"))
                        .foregroundStyle(.secondary)
                        .font(.system(size: 16))
                } else if showGuest == false && showFriends == true && isAdded {
                    Text(String(localized:"addPlayers.currentlyComparing"))
                        .foregroundStyle(.secondary)
                        .font(.system(size: 16))
                } else if showGuest == false && showFriends == false && isAdded {
                    Text(String(localized:"addPlayers.alreadyFriend"))
                        .foregroundStyle(.secondary)
                        .font(.system(size: 16))
                } else if let elo = profile?.elo {
                    Text("\(Int(elo))")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 16))
                }
            }
        }
        .disabled(isAdded || (showGuest == true && inGame == true))
        .contextMenu {
            if network.isOnline {
                if isFriend(profileId: profileId) == true {
                    Button(role: .destructive) {
                        Task {
                            await network.removeFriend(profileId: userId, friendId: profileId)
                        }
                    } label: {
                        Image(systemName: "person.badge.minus")
                        Text(String(localized:"friends.remove.friend"))
                    }
                } else {
                    Button {
                        Task {
                            await network.sendFriendRequest(senderId: userId, receiverId: profileId)
                        }
                    } label: {
                        Image(systemName: "person.badge.plus")
                        Text(String(localized:"play.sendFriend"))
                    }
                    .disabled(profileId == userId)
                }
            }
        }
        .foregroundColor(((isAdded && showGuest) || (inGame && showGuest)) ? .secondary : .primary)
    }

    // MARK: - Sort Menu
    private func sortMenu(active: Bool, binding: Binding<sortBy>, hideUnavailable: Binding<Bool>, showDateOptions: Bool) -> some View {
        Menu {
            Button {
                withAnimation(.easeInOut) { binding.wrappedValue = .nameDown }
            } label: {
                if binding.wrappedValue == .nameDown { Image(systemName: "checkmark") } else { Image("ABC.down") }
                Text(String(localized:"statistics.sort.abcdown"))
            }
            Button {
                withAnimation(.easeInOut) { binding.wrappedValue = .nameUp }
            } label: {
                if binding.wrappedValue == .nameUp { Image(systemName: "checkmark") } else { Image("ABC.up") }
                Text(String(localized:"statistics.sort.abcup"))
                
            }
            Divider()
            Button {
                withAnimation(.easeInOut) { binding.wrappedValue = .valueDown }
            } label: {
                if binding.wrappedValue == .valueDown { Image(systemName: "checkmark") } else { Image("123.down") }
                Text(String(localized:"statistics.sort.rankingdown"))
            }
            Button {
                withAnimation(.easeInOut) { binding.wrappedValue = .valueUp }
            } label: {
                if binding.wrappedValue == .valueUp { Image(systemName: "checkmark") } else { Image("123.up") }
                Text(String(localized:"statistics.sort.rankingup"))
            }
            Divider()
            Button {
                withAnimation(.easeInOut) { hideUnavailable.wrappedValue.toggle() }
            } label: {
                if hideUnavailable.wrappedValue { Image(systemName: "checkmark") } else { Image(systemName: "list.bullet") }
                Text(hideUnavailableLabel)
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle").font(.system(size: 20))
        }
        .foregroundColor(active ? .accentColor : .primary)
    }
}
