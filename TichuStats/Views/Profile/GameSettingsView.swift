//
//  GameSettingsView.swift
//  TichuStats
//
//  Created by Leon on 12.10.2026.
//

import SwiftUI

// MARK: - Game Settings View
struct GameSettingsView: View {
    //MARK: Vars
    @AppStorage("defaultTarget") private var defaultTarget: Int = 1000
    @AppStorage("defaultAllowPingus") private var defaultAllowPingus: Bool = true
    @AppStorage("dragMode") var dragMode: Bool = false
    @AppStorage("userId") private var userId: Int = -69420
    @AppStorage("showAllPlayers") private var showAllPlayers: Bool = false
    @AppStorage("sortByProfiles") var sortByProfiles: sortBy = .nameDown
    @AppStorage("sortByStats") var sortByStats: sortBy = .valueDown
    @ObservedObject private var network = NetworkService.shared
    

    private func sendSettingsUpdate() {
        Task {
            await network.updateProfileSettings(
                profileId: userId,
                target: defaultTarget,
                showPingu: defaultAllowPingus,
                dragMode: dragMode,
                showAllPlayers: showAllPlayers,
                sortByProfiles: sortByProfiles,
                sortByStats: sortByStats
            )
        }
    }

    //MARK: Body
    var body: some View {
        List {
            
            //MARK: Games
            Section {
                Picker(String(localized: "gamesettings.section.games.defaultTarget"), selection: $defaultTarget) {
                    Text("250").tag(250)
                    Text("500").tag(500)
                    Text("1000").tag(1000)
                    Text("2000").tag(2000)
                    Text("10000").tag(10000)
                }.disabled(!network.isOnline)
                Toggle(String(localized: "gamesettings.section.games.showPingus"), isOn: $defaultAllowPingus).disabled(!network.isOnline)
                Toggle(String(localized: "gamesettings.section.games.dragMode"), isOn: $dragMode).disabled(!network.isOnline)
            } header: {
                Text(String(localized: "gamesettings.section.games"))
            } footer: {
                Text(String(localized: "gamesettings.section.games.footer"))
            }

            //MARK: Players
            Section {
                Toggle(String(localized: "gamesettings.section.players.showAll"), isOn: $showAllPlayers).disabled(!network.isOnline)
                Picker(String(localized: "gamesettings.section.players.sortBy"), selection: $sortByProfiles) {
                    Label(String(localized:"statistics.sort.abcdown"), image: "ABC.down").tag(sortBy.nameDown)
                    Label(String(localized:"statistics.sort.abcup"), image: "ABC.up").tag(sortBy.nameUp)
                    Label(String(localized:"statistics.sort.rankingdown"), image: "123.down").tag(sortBy.valueDown)
                    Label(String(localized:"statistics.sort.rankingup"), image: "123.up").tag(sortBy.valueUp)
                }.disabled(!network.isOnline)
            } header: {
                Text(String(localized: "gamesettings.section.players"))
            } footer: {
                Text(String(localized: "gamesettings.section.players.footer"))
            }
            
            //MARK: Statistics
            Section {
                Picker(String(localized: "gamesettings.section.statistics.sortBy"), selection: $sortByStats) {
                    Label(String(localized:"statistics.sort.abcdown"), image: "ABC.down").tag(sortBy.nameDown)
                    Label(String(localized:"statistics.sort.abcup"), image: "ABC.up").tag(sortBy.nameUp)
                    Label(String(localized:"statistics.sort.123down"), image: "123.down").tag(sortBy.valueDown)
                    Label(String(localized:"statistics.sort.123up"), image: "123.up").tag(sortBy.valueUp)
                }.disabled(!network.isOnline)
            } header: {
                Text(String(localized: "gamesettings.section.statistics"))
            }
            
            //MARK: How to Play?
            Section(String(localized: "gamesettings.section.howToPlay")) {
                NavigationLink {
                        TichuRulesPDFView()
                } label: {
                    Label(String(localized: "gamesettings.section.howToPlay.officialRules"), systemImage: "book.fill")
                        .labelStyle(ColorfulIconLabelStyle(color: .green, fontSize: 14))
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(String(localized: "gamesettings.title"))
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: defaultTarget) {
            sendSettingsUpdate()
        }
        .onChange(of: defaultAllowPingus) {
            sendSettingsUpdate()
        }
        .onChange(of: dragMode) {
            sendSettingsUpdate()
        }
        .onChange(of: showAllPlayers) {
            sendSettingsUpdate()
        }
        .onChange(of: sortByProfiles) {
            sendSettingsUpdate()
        }
        .onChange(of: sortByStats) {
            sendSettingsUpdate()
        }
        
        
    }
}
