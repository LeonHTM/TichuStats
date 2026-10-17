//
//  SocketService.swift
//  TichuStats
//
//  Created by Leon on 15.05.2026.
//

import Foundation
import SocketIO
import Combine
import SwiftUI

final class SocketService: ObservableObject {

    // MARK: - Vars
    @AppStorage("userId") private var userId = -69420
    @AppStorage("userImageData") var userImageData: Data?
    @AppStorage("userName") var userName: String = "Unknown"
    @AppStorage("userElo") var userElo: Double = 1000

    static let shared = SocketService()

    private var manager: SocketManager?
    private var socket: SocketIOClient?

    @Published var connected = false

    var apiURL: String = getURL()
    var reconnectAttempts: Int = 0

    // Used to detect attempts that hang forever
    private var connectingSince: Date?

    private let stuckConnectingThreshold: TimeInterval = 4

    private init() {
        setupSocket()
    }

    // MARK: - Setup Socket Section
    private func setupSocket() {
        guard let url = URL(string: apiURL) else {
            print("SocketService: invalid URL \(apiURL)")
            return
        }

        let manager = SocketManager(
            socketURL: url,
            config: [
                //.log(true),
                .compress,
                .reconnectAttempts(-1),
                .reconnectWait(1)
            ]
        )
        self.manager = manager

        let socket = manager.defaultSocket
        self.socket = socket

        setupHandlers(socket)
        socket.connect()
    }

    // MARK: - Reconnect with new URL
    func reconnect() {
        socket?.disconnect()
        socket?.removeAllHandlers()
        manager?.disconnect()
        connectingSince = nil
        reconnectAttempts = 0

        apiURL = getURL() // pick up the new URL
        setupSocket()

        Task {
            await NetworkService.shared.fetchProfiles()
            await NetworkService.shared.fetchFriends(profileId: userId)
            await NetworkService.shared.fetchFriendRequests(profileId: userId)
        }
    }

    // MARK: - Lifecycle Handlers

    /// Reconnects only when needed.
    @discardableResult
    func reconnectIfNeeded() -> Bool {
        guard let socket else {
            setupSocket()
            return true
        }

        switch socket.status {
        case .connected:
            return false

        case .connecting:
            if let since = connectingSince,
               Date().timeIntervalSince(since) > stuckConnectingThreshold {
                print("Socket stuck in .connecting, forcing reconnect")
                forceReconnect()
                return true
            }
            return false

        default:
            socket.connect()
            return true
        }
    }

    //Tears the socket down and connects again
    private func forceReconnect() {
        connectingSince = nil
        socket?.disconnect()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.socket?.connect()
        }
    }


    // MARK: - Handlers
    private func setupHandlers(_ socket: SocketIOClient) {

        // MARK: Connection state
        socket.on(clientEvent: .statusChange) { [weak self] data, _ in
            guard let self, let status = data.first as? SocketIOStatus else { return }
            if status == .connecting {
                self.connectingSince = self.connectingSince ?? Date()
            } else {
                self.connectingSince = nil
            }
        }

        socket.on(clientEvent: .connect) { [weak self] _, _ in
            print("Socket connected")
            DispatchQueue.main.async {
                self?.connected = true
                self?.reconnectAttempts = 0
                NetworkService.shared.isOnline = true
            }
        }

        socket.on(clientEvent: .disconnect) { [weak self] _, _ in
            print("Socket disconnected")
            DispatchQueue.main.async { self?.connected = false }
        }

        socket.on(clientEvent: .error) { [weak self] data, _ in
            print("Socket error: \(data)")
            DispatchQueue.main.async { self?.connected = false }
        }

        // Fires for every retry. After 5 failed retries app is offline.
        /*socket.on(clientEvent: .reconnectAttempt) { [weak self] _, _ in
            DispatchQueue.main.async {
                guard let self else { return }
                self.reconnectAttempts += 1
                if self.reconnectAttempts >= 5 {
                    NetworkService.shared.isOnline = false
                    self.reconnectAttempts = 0
                }
            }
        }*/

        // MARK: - Profiles Section

        // MARK: Profile Created
        socket.on("profile_created") { _, _ in
            Task { await NetworkService.shared.fetchProfiles() }
        }

        // MARK: Profile Deleted
        socket.on("profile_deleted") { [weak self] data, _ in
            guard let self,
                  let dict = data.first as? [String: Any],
                  let id = dict["id"] as? Int else {
                print("profile_deleted: failed to parse \(data)")
                return
            }
            Task { @MainActor in
                await NetworkService.shared.fetch(load: false)
                if id == self.userId {
                    self.userId = -69420
                }
            }
        }

        // MARK: Username updated
        socket.on("username_updated") { [weak self] data, _ in
            guard let self,
                  let dict = data.first as? [String: Any],
                  let profileId = dict["profile_id"] as? Int,
                  let name = dict["name"] as? String else { return }
            DispatchQueue.main.async {
                if let index = NetworkService.shared.profiles.firstIndex(where: { $0.id == profileId }) {
                    withAnimation(.easeInOut) {
                        NetworkService.shared.profiles[index].name = name
                        if profileId == self.userId {
                            self.userName = name
                        }
                    }
                }
            }
        }

        // MARK: Admin State updated
        socket.on("admin_updated") { data, _ in
            guard let dict = data.first as? [String: Any],
                  let profileId = dict["profile_id"] as? Int,
                  let isAdmin = dict["admin"] as? Bool else {
                print("admin_updated: failed to parse \(data)")
                return
            }
            DispatchQueue.main.async {
                if let index = NetworkService.shared.profiles.firstIndex(where: { $0.id == profileId }) {
                    withAnimation(.easeInOut) {
                        NetworkService.shared.profiles[index].isAdmin = isAdmin
                    }
                }
            }
        }

        // MARK: Profile Settings updated
        socket.on("settings_updated") { data, _ in
            guard let dict = data.first as? [String: Any],
                  let profileId = dict["id"] as? Int else {
                print("settings_updated: failed to parse \(data)")
                return
            }
            Task { await NetworkService.shared.fetchProfileSettings(profileId: profileId) }
        }

        // MARK: Elo State Updated
        socket.on("elo_updated") { [weak self] data, _ in
            guard let self,
                  let dict = data.first as? [String: Any],
                  let players = dict["players"] as? [[String: Any]] else {
                print("elo_updated: failed to parse \(data)")
                return
            }

            Task { @MainActor in
                for player in players {
                    // NSNumber handles both Int and Double JSON numbers
                    guard let id = (player["id"] as? NSNumber)?.intValue,
                          let elo = (player["elo"] as? NSNumber)?.doubleValue else {
                        continue // skip instead of writing 0 into a profile
                    }

                    if let index = NetworkService.shared.profiles.firstIndex(where: { $0.id == id }) {
                        NetworkService.shared.profiles[index].elo = elo
                    }

                    if id == self.userId {
                        await NetworkService.shared.fetchEloHistory(profileId: id)
                    }
                }
                print("ELO UPDATED")
            }
        }

        // MARK: Profile Image updated
        socket.on("profile_image_updated") { data, _ in
            print("profile_image_updated: \(data)")
            Task { await NetworkService.shared.fetchProfiles() }
        }

        // MARK: Remove Friend Request Notification
        socket.on("remove_friend_request_notification") { [weak self] data, _ in
            guard let self,
                  let dict = data.first as? [String: Any],
                  let targetUserId = dict["user_id"] as? Int,
                  let senderId = dict["sender_id"] as? Int else { return }
            guard targetUserId == self.userId else {
                print("Wanted to delete Notification but couldn't")
                return
            }
            removeFriendRequestNotification(fromSenderId: senderId)
        }

        // MARK: Friend Request sent
        socket.on("friend_request_sent") { [weak self] _, _ in
            guard let self else { return }
            Task {
                await NetworkService.shared.fetchSentRequests(profileId: self.userId)
                await NetworkService.shared.fetchFriendRequests(profileId: self.userId)
            }
        }

        // MARK: Friend Request Updated
        socket.on("friend_request_updated") { [weak self] _, _ in
            guard let self else { return }
            print("friend_request_updated received")
            Task {
                await NetworkService.shared.fetchSentRequests(profileId: self.userId)
                await NetworkService.shared.fetchFriendRequests(profileId: self.userId)
                await NetworkService.shared.fetchFriends(profileId: self.userId)
            }
        }

        // MARK: Friendship added
        socket.on("friendship_added") { [weak self] data, _ in
            guard let self else { return }
            print("friendship_added: \(data)")
            Task {
                await NetworkService.shared.fetchSentRequests(profileId: self.userId)
                await NetworkService.shared.fetchFriendRequests(profileId: self.userId) // was a duplicate fetchSentRequests
                await NetworkService.shared.fetchFriends(profileId: self.userId)
            }
        }

        // MARK: Friendship removed
        socket.on("friendship_removed") { [weak self] data, _ in
            guard let self else { return }
            print("friendship_removed: \(data)")
            Task { await NetworkService.shared.fetchFriends(profileId: self.userId) }
        }

        // MARK: Auth Failed
        socket.on("auth_failed") { [weak self] _, _ in
            guard let self else { return }
            Task { await NetworkService.shared.logout(profileId: self.userId) }
        }

        // MARK: - Game and Rounds Section

        // MARK: Game created
        socket.on("game_created") { data, _ in
            guard let dict = data.first as? [String: Any],
                  let jsonData = try? JSONSerialization.data(withJSONObject: dict) else {
                print("game_created: failed to parse \(data)")
                return
            }
            let decoder = NetworkService.shared.flexibleDateDecoder
            guard let game = try? decoder.decode(Game.self, from: jsonData) else {
                print("game_created: failed to decode Game")
                return
            }
            Task { @MainActor in
                if !NetworkService.shared.games.contains(where: { $0.id == game.id }) {
                    withAnimation(.easeInOut) {
                        print("game created: appending now \(game.id)")
                        NetworkService.shared.games.append(game)
                    }
                }
            }
        }

        // MARK: Game deleted
        socket.on("game_deleted") { [weak self] data, _ in
            guard let self,
                  let dict = data.first as? [String: Any],
                  let gameId = dict["game_id"] as? Int else {
                print("game_deleted: failed to parse \(data)")
                return
            }
            let userId = self.userId
            Task { @MainActor in
                print("Game Deleted: \(gameId)")
                NetworkService.shared.games.removeAll { $0.id == gameId }
                NetworkService.shared.roundsByGame.removeValue(forKey: gameId)

                await withTaskGroup(of: Void.self) { group in
                    group.addTask { await NetworkService.shared.fetchSelectedProfilesStats() }
                    group.addTask { await NetworkService.shared.fetchProfileStatsHistory(profileId: userId) }
                    group.addTask { await NetworkService.shared.fetchEloHistory(profileId: userId) }
                    group.addTask { await NetworkService.shared.fetchProfiles() }
                }
            }
        }

        // MARK: Game recalculated
        socket.on("game_recalculated") { [weak self] data, _ in
            guard let self,
                  let dict = data.first as? [String: Any],
                  let gameId = dict["game_id"] as? Int else {
                print("game_recalculated: failed to parse \(data)")
                return
            }
            print("game_recalculated for game \(gameId)")
            let userId = self.userId
            Task {
                await withTaskGroup(of: Void.self) { group in
                    group.addTask { await NetworkService.shared.fetchGame(gameId: gameId) }
                    group.addTask { await NetworkService.shared.fetchGameRounds(gameId: gameId) }
                    group.addTask { await NetworkService.shared.fetchProfileStatsHistory(profileId: userId) }
                }
            }
        }

        // MARK: Game finished
        socket.on("game_finished") { _, _ in
            // Fetch anyway, stats of other players could have changed
            Task { await NetworkService.shared.fetchSelectedProfilesStats() }
        }

        // MARK: Game updated
        socket.on("game_updated") { data, _ in
            guard let dict = data.first as? [String: Any],
                  let gameId = dict["game_id"] as? Int else {
                print("game_updated: failed to parse \(data)")
                return
            }
            Task { await NetworkService.shared.fetchGame(gameId: gameId) }
        }

        // MARK: Round updated
        socket.on("round_updated") { [weak self] data, _ in
            guard let self,
                  let dict = data.first as? [String: Any],
                  let jsonData = try? JSONSerialization.data(withJSONObject: dict) else { return }
            let decoder = NetworkService.shared.flexibleDateDecoder
            guard let updated = try? decoder.decode(Round.self, from: jsonData) else {
                print("round_updated: failed to decode Round")
                return
            }
            let userId = self.userId
            DispatchQueue.main.async {
                let gameId = updated.gameId
                if var rounds = NetworkService.shared.roundsByGame[gameId],
                   let index = rounds.firstIndex(where: { $0.id == updated.id }) {
                    rounds[index] = updated
                    NetworkService.shared.roundsByGame[gameId] = rounds
                }
            }
            Task { await NetworkService.shared.fetchProfileGames(profileId: userId) }
        }

        // MARK: Round deleted
        socket.on("round_deleted") { data, _ in
            guard let dict = data.first as? [String: Any],
                  let gameId = dict["game_id"] as? Int else { return }
            Task { await NetworkService.shared.reCalculate(gameId: gameId) }
        }

        // MARK: Round created
        socket.on("round_created") { data, _ in
            guard let dict = data.first as? [String: Any],
                  let jsonData = try? JSONSerialization.data(withJSONObject: dict) else { return }
            let decoder = NetworkService.shared.flexibleDateDecoder
            guard let round = try? decoder.decode(Round.self, from: jsonData) else {
                print("round_created: failed to decode Round")
                return
            }
            let gameId = round.gameId
            DispatchQueue.main.async {
                var list = NetworkService.shared.roundsByGame[gameId] ?? []
                if !list.contains(where: { $0.id == round.id }) {
                    list.append(round)
                    list.sort { $0.roundOrder < $1.roundOrder }
                    NetworkService.shared.roundsByGame[gameId] = list
                }
            }
            Task { await NetworkService.shared.reCalculate(gameId: gameId) }
        }
    }

    // MARK: - Disconnect
    func disconnect() {
        connectingSince = nil
        socket?.disconnect()
    }
}
