//
//  EditFriendsSheetView.swift
//  Tichu
//
//  Created by Leon on 23.04.2026.
//

import SwiftUI
import TipKit

struct EditFriendsSheetView: View {
    @Namespace private var FriendsSpace
    @Environment(\.dismiss) private var dismiss


    // MARK: - Storage
    @AppStorage("userName") var userName: String = ""
    @ObservedObject private var network = NetworkService.shared
    @StateObject private var socket = SocketService.shared
    @AppStorage("userId") private var userId: Int = -69420

    // MARK: - State
    @State private var friendsFilterActive: Bool = false

    @State private var sortByFriends: sortBy = .nameDown
    @State private var sortByRequests: sortBy = .nameDown
    @State private var sortBySentRequests: sortBy = .nameDown

    @State private var friendsListCopy: [Friend] = []
    @State private var requestedFriendsListCopy: [Int] = []
    @State private var sentRequestsListCopy: [Int] = []

    @State private var showAddPlayerSheet: Bool = false
    @State private var currentProfileId: Int?

    // MARK: - Computed

    var sortedFriendsList: [Friend] {
        makeItems(from: friendsListCopy, stat: .dateAdded, sortBy: sortByFriends)
    }

    var sortedRequestsList: [Profile] {
        let profiles = requestedFriendsListCopy.compactMap { id in
            network.profiles.first { $0.id == id }
        }
        return makeItems(from: profiles, stat: .dateAdded, sortBy: sortByRequests)
    }

    var sortedSentRequestsList: [Profile] {
        let profiles = sentRequestsListCopy.compactMap { id in
            network.profiles.first { $0.id == id }
        }
        return makeItems(from: profiles, stat: .dateAdded, sortBy: sortBySentRequests)
    }

   

    // MARK: - Body
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    if requestedFriendsListCopy.count > 0 {
                        friendRequestsHeader
                        friendRequestsRows
                    }
                    friendsHeader
                    friendsRows

                    if sentRequestsListCopy.count > 0 {
                        sentRequestsHeader
                        sentRequestsRows
                    }
                }
                .safeAreaInset(edge: .bottom) { addFriendButton }
                .task {
                    await network.fetchFriends(profileId: userId)
                    await network.fetchFriendRequests(profileId: userId)
                    await network.fetchSentRequests(profileId: userId)
                }
                .onChange(of: network.isOnline) {
                    if !network.isOnline { dismiss() }
                }
                .onAppear {
                    withAnimation(.easeInOut) {
                        friendsListCopy = network.friends
                        sentRequestsListCopy = network.sentRequests.map { $0.receiverId }
                        requestedFriendsListCopy = network.friendRequests.map { $0.senderId }
                    }
                }
                .onChange(of: network.friends) {
                    withAnimation(.easeInOut) {
                        friendsListCopy = network.friends
                    }
                }
                .onChange(of: network.sentRequests.map { $0.receiverId }) {
                    withAnimation(.easeInOut) {
                        sentRequestsListCopy = network.sentRequests.map { $0.receiverId }
                    }
                }
                .onChange(of: network.friendRequests.map { $0.id }) {
                    withAnimation(.easeInOut) {
                        requestedFriendsListCopy = network.friendRequests.map { $0.senderId }
                    }
                }
                .listSectionSpacing(0)
                .navigationTitle(String(localized: "friends.manage"))
                .navigationBarTitleDisplayMode(.inline)

                .sheet(isPresented: $showAddPlayerSheet, onDismiss: {
                    if let profileId = currentProfileId {
                        if !sentRequestsListCopy.contains(profileId)
                            && !friendsListCopy.contains(where: { $0.id == profileId }) {
                            withAnimation(.easeInOut) {
                                sentRequestsListCopy.append(profileId)
                            }
                            Task {
                                await network.sendFriendRequest(senderId: userId, receiverId: profileId)
                                await network.fetchSentRequests(profileId: userId)
                            }
                        }
                    }
                }) {
                    AddPlayersSheetView(
                        showAddPlayersSheet: $showAddPlayerSheet,
                        addPlayerId: $currentProfileId,
                        alreadyAdded: friendsListCopy.map { $0.id } + sentRequestsListCopy,
                        showGuest: .constant(false),
                        showPlayers: .constant(true),
                        showFriends: .constant(false),
                        guestName: .constant(""),
                        guestIndex: 0,
                        showMenu: true
                    ).presentationDetents(UIDevice.current.userInterfaceIdiom == .pad ? [.large] : [.medium, .large]).navigationTransition(.zoom(sourceID:"69420",in:FriendsSpace))
                }
               
            }
            .task {
                await network.fetchSentRequests(profileId: userId)
            }
        }
    }

    // MARK: - Friend Requests Header
    private var friendRequestsHeader: some View {
        Section {
            HStack {
                Text(String(localized: "friends.recieved")).fontWeight(.bold)
                Spacer()
                if requestedFriendsListCopy.count > 1 {
                    Menu {
                        Button {
                            withAnimation(.easeInOut) { sortByRequests = .nameDown; friendsFilterActive = false }
                        } label: {
                            if sortByRequests == .nameDown { Image(systemName: "checkmark") } else { Image("ABC.down") }
                            Text(String(localized:"statistics.sort.abcdown"))
                        }
                        Button {
                            withAnimation(.easeInOut) { sortByRequests = .nameUp; friendsFilterActive = true }
                        } label: {
                            if sortByRequests == .nameUp { Image(systemName: "checkmark") } else { Image("ABC.up") }
                            Text(String(localized:"statistics.sort.abcup"))
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle").font(.system(size: 20))
                    }
                    .foregroundColor(friendsFilterActive ? .accentColor : .primary)
                }
            }
        }
        .listRowBackground(Color.clear)
    }

    // MARK: - Friend Requests Rows
    private var friendRequestsRows: some View {
        Section {
            ForEach(sortedRequestsList, id: \.id) { profile in
                HStack {
                    ProfileImage(data: network.friendRequestImages[profile.id], size: 44)
                    VStack(alignment: .leading) {
                        Text(profile.name ?? String(localized: "general.unknown"))
                    }
                    Spacer()
                    GlassEffectContainer {
                        HStack {
                            // Reject — instant
                            Button {
                                let senderId = profile.id
                                withAnimation(.easeInOut) {
                                    requestedFriendsListCopy.removeAll { $0 == senderId }
                                }
                                Task {
                                    await network.respondToFriendRequest(
                                        receiverId: userId, senderId: senderId, action: "rejected"
                                    )
                                    try? await UNUserNotificationCenter.current()
                                        .setBadgeCount(network.friendRequests.count)
                                }
                            } label: {
                                Image(systemName: "xmark")
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            .foregroundStyle(Color.primary)
                            .padding(13)
                            .glassEffect(.regular.interactive(), in: Circle())

                            // Accept — instant
                            Button {
                                let senderId = profile.id
                                withAnimation(.easeInOut) {
                                    requestedFriendsListCopy.removeAll { $0 == senderId }
                                    let newFriend = Friend(id: profile.id, profile: profile, friendsSince: Date())
                                    friendsListCopy.append(newFriend)
                                }
                                Task {
                                    await network.respondToFriendRequest(
                                        receiverId: userId, senderId: senderId, action: "accepted"
                                    )
                                    try? await UNUserNotificationCenter.current()
                                        .setBadgeCount(network.friendRequests.count)
                                }
                            } label: {
                                Image(systemName: "checkmark")
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            .foregroundStyle(Color.white)
                            .padding(13)
                            .glassEffect(.regular.tint(.accentColor).interactive(), in: Circle())
                        }
                    }
                }
            }
        }
    }

    // MARK: - Friends Header
    private var friendsHeader: some View {
        Section {
            if friendsListCopy.count > 0 {
                HStack {
                    Text(String(localized: "friends.friends")).fontWeight(.bold)
                    Spacer()
                    if friendsListCopy.count > 1 {
                        Menu {
                            Button {
                                withAnimation(.easeInOut) { sortByFriends = .nameDown; friendsFilterActive = false }
                            } label: {
                                if sortByFriends == .nameDown { Image(systemName: "checkmark") } else { Image("ABC.down") }
                                Text(String(localized:"statistics.sort.abcdown"))
                            }
                            Button {
                                withAnimation(.easeInOut) { sortByFriends = .nameUp; friendsFilterActive = true }
                            } label: {
                                if sortByFriends == .nameUp { Image(systemName: "checkmark") } else { Image("ABC.up") }
                                Text(String(localized:"statistics.sort.abcup"))
                            }
                            Divider()
                            Button {
                                withAnimation(.easeInOut) { sortByFriends = .valueDown; friendsFilterActive = true }
                            } label: {
                                if sortByFriends == .valueDown { Image(systemName: "checkmark") } else { Image("date.down") }
                                Text(String(localized:"statistics.sort.dateDown"))
                            }
                            Button {
                                withAnimation(.easeInOut) { sortByFriends = .valueUp; friendsFilterActive = true }
                            } label: {
                                if sortByFriends == .valueUp { Image(systemName: "checkmark") } else { Image("date.up") }
                                Text(String(localized:"statistics.sort.dateUp"))
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease.circle").font(.system(size: 20))
                        }
                        .foregroundColor(friendsFilterActive ? .accentColor : .primary)
                    }
                }
            } else {
                if sentRequestsListCopy.count == 0 && requestedFriendsListCopy.count == 0 {
                    Text(String(localized: "friends.nofriends"))
                        .listRowBackground(Color.clear)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .listRowBackground(Color.clear)
    }

    // MARK: - Friends Rows
    private var friendsRows: some View {
        Section {
            ForEach(sortedFriendsList) { friend in
                HStack {
                    ProfileImage(data: network.profileImages[friend.id], size: 44)
                    VStack(alignment: .leading) {
                        Text(friend.profile.name ?? String(localized: "general.unknown"))
                        if let date = friend.friendsSince {
                            Text(String(format:String(localized: "friends.since"),String(date.formatted(date: .complete, time: .omitted))))
                                .foregroundStyle(.secondary)
                                .font(.system(size: 16))
                        } else {
                            Text(String(localized: "general.unknown"))
                                .foregroundStyle(.secondary)
                                .font(.system(size: 16))
                        }
                    }
                }
                .swipeActions(edge: .trailing) {
                    // Remove friend — instant
                    Button(role: .destructive) {
                        let friendId = friend.id
                        withAnimation(.easeInOut) {
                            friendsListCopy.removeAll { $0.id == friendId }
                        }
                        Task {
                            await network.removeFriend(profileId: userId, friendId: friendId)
                        }
                    } label: {
                        Image(systemName: "person.badge.minus")
                        Text(String(localized: "friends.remove.friend"))
                    }
                    .tint(.red)
                }
            }
            if friendsListCopy.count > 0 {
                TipView(ListSwipeFriendTip()).tipBackground(Color.clear)
            }
        }
        .task {
            do { try Tips.configure() } catch {
                print("Error initializing TipKit \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Sent Requests Header
    private var sentRequestsHeader: some View {
        Section {
            HStack {
                Text(String(localized: "friends.requested")).fontWeight(.bold)
                Spacer()
                if sentRequestsListCopy.count > 1 {
                    Menu {
                        Button {
                            withAnimation(.easeInOut) { sortBySentRequests = .nameDown; friendsFilterActive = false }
                        } label: {
                            if sortBySentRequests == .nameDown { Image(systemName: "checkmark") } else { Image("ABC.down") }
                            Text(String(localized:"statistics.sort.abcdown"))
                        }
                        Button {
                            withAnimation(.easeInOut) { sortBySentRequests = .nameUp; friendsFilterActive = true }
                        } label: {
                            if sortBySentRequests == .nameUp { Image(systemName: "checkmark") } else { Image("ABC.up") }
                            Text(String(localized:"statistics.sort.abcup"))
                        }
                        Divider()
                        Button {
                            withAnimation(.easeInOut) { sortBySentRequests = .valueDown; friendsFilterActive = true }
                        } label: {
                            if sortBySentRequests == .valueDown { Image(systemName: "checkmark") } else { Image("date.down") }
                            Text(String(localized:"statistics.sort.dateDown"))
                        }
                        Button {
                            withAnimation(.easeInOut) { sortBySentRequests = .valueUp; friendsFilterActive = true }
                        } label: {
                            if sortBySentRequests == .valueUp { Image(systemName: "checkmark") } else { Image("date.up") }
                            Text(String(localized:"statistics.sort.dateUp"))
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle").font(.system(size: 20))
                    }
                    .foregroundColor(friendsFilterActive ? .accentColor : .primary)
                }
            }
        }
        .listRowBackground(Color.clear)
    }

    // MARK: - Sent Requests Rows
    private var sentRequestsRows: some View {
        Section {
            ForEach(sortedSentRequestsList) { request in
                HStack {
                    ProfileImage(data: network.profileImages[request.id], size: 44)
                    VStack(alignment: .leading) {
                        Text(request.name ?? String(localized: "general.unknown"))
                        Text(String(localized: "friends.sent"))
                            .foregroundStyle(.secondary)
                            .font(.system(size: 16))
                    }
                }
                .swipeActions(edge: .trailing) {
                    // Cancel sent request — instant
                    Button(role: .destructive) {
                        let receiverId = request.id
                        withAnimation(.easeInOut) {
                            sentRequestsListCopy.removeAll { $0 == receiverId }
                        }
                        Task {
                            await network.respondToFriendRequest(
                                receiverId: receiverId, senderId: userId, action: "rejected"
                            )
                        }
                    } label: {
                        Image(systemName: "person.badge.minus")
                        Text(String(localized: "friends.remove.request"))
                    }
                }
            }
        }
        .task {
            do { try Tips.configure() } catch {
                print("Error initializing TipKit \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Add Friend Button
    private var addFriendButton: some View {
        HStack {
            Spacer()
            Button {
                showAddPlayerSheet = true
            } label: {
                Image(systemName: "plus").font(.system(size: 20))
                Text(String(localized: "friends.request"))
            }.matchedTransitionSource(id: "69420", in: FriendsSpace)
            .foregroundStyle(Color.primary)
            .padding(13)
            .glassEffect(.regular.interactive())
            .padding(.trailing, 20)
            .padding(.bottom, 10)
        }
        
    }
}

#Preview {
    EditFriendsSheetView()
}
