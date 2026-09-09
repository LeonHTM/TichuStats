//
//  ProfileView.swift
//  Tichu
//
//  Created by Leon on 21.04.2026.
//

import SwiftUI
import PhotosUI

struct ProfileView: View {
    // MARK: Storage
    @AppStorage("userId") var userId: Int = -69420
    @AppStorage("userImageData") var userImageData: Data?
    @AppStorage("userName") var userName: String = "Unknown"
    @AppStorage("userElo") var userElo: Double = 404
    @AppStorage("selectedTab") private var selectedTab = 0
    
    //MARK: Observed and Environment
    @ObservedObject private var network = NetworkService.shared
    @StateObject private var socket = SocketService.shared
    @Environment(\.scenePhase) private var scenePhase
    @Namespace private var profileSpace
    
    // MARK: Photo Picker
    @State private var pickerItem: PhotosPickerItem?
    @State private var isUploadingImage: Bool = false
    
    // MARK: Sheet & Alert Presentation
    @State private var showNameSheet: Bool = false
    @State private var showFriendsSheet: Bool = false
    @State private var showPrivacyAlert: Bool = false
    @State private var showDeleteAlert: Bool = false
    @State private var showOfflineAlert: Bool = false
    @State private var showImageFailAlert: Bool = false
    @State private var isAddingPasskey: Bool = false
    @State private var showAddPasskeyError: Bool = false
    @State private var addPasskeyErrorMessage: String?
    @State private var chosenName: String = ""

    // MARK: Body
    var body: some View {
        NavigationStack {
            //MARK: Main List
            List {
                profileHeaderSection
                accountSection
                supportSection
                authSection
                deleteAccountSection
                footerSection
            }.alert(isPresented:$showOfflineAlert){
                OfflineView.offlineAlert()
            }
            .animation(.easeInOut, value: network.isOnline)
            .padding(.top, -20)
            .navigationTitle(String(localized: "profile.title"))
            .toolbarTitleDisplayMode(.inlineLarge)
        }.onReceive(NotificationCenter.default.publisher(for: .openFriendsSheet)) { _ in
            if network.isOnline{
                showFriendsSheet = true
            }
        }
        .navigationDestination(isPresented: $showFriendsSheet) {
            EditFriendsSheetView()
        }
    }

    // MARK: - Profile Header
    private var profileHeaderSection: some View {
        HStack {
            Spacer()
            VStack {
                ZStack {
                    ZStack{
                        ProfileImage(data: userImageData, size: 100)
                            .shadow(radius: 10)
                            .allowsHitTesting(false)
                        if isUploadingImage{
                            ProgressView().scaleEffect(2)
                        }
                    }
                    
                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        Image(systemName: "camera.fill")
                            .frame(width: 30, height: 30)
                            .clipShape(Circle())
                            .foregroundColor(.primary)
                            .glassEffect(.regular.interactive())
                            .offset(y: 32)
                    }.disabled(!network.isOnline).onChange(of: pickerItem) {
                        isUploadingImage = true
                        Task {
                            guard let pickerItem else {
                                showImageFailAlert = true
                                isUploadingImage = false
                                return
                            }
                            if let data = try? await pickerItem.loadTransferable(type: Data.self) {
                                await network.uploadProfileImage(profileId: userId, imageData: data)
                            } else {
                                showImageFailAlert = true
                                isUploadingImage = false
                            }
                            isUploadingImage = false
                        }
                    }.alert(isPresented:$showImageFailAlert){
                        Alert(
                            title: Text(String(localized: "profile.header.imageUploadFail.title")),
                            message: Text(String(localized: "profile.header.imageUploadFail.message")),
                            dismissButton: .default(Text(String(localized: "profile.header.imageUploadFail.dismiss")))
                        )
                    }
                }
                Text("\(userName)")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .allowsHitTesting(false)
                Text("\(Int(userElo))")
                    .foregroundStyle(.gray)
                    .fontWeight(.bold)
                    .allowsHitTesting(false)
            }
            Spacer()
        }
        .listRowBackground(Color.clear)
    }

    // MARK: - Account Section
    private var accountSection: some View {
        Section {
            
            //MARK: General
            NavigationLink {
                    GameSettingsView()
            } label: {
                Label(String(localized: "profile.section.account.general"), systemImage: "gear")
                    .labelStyle(ColorfulIconLabelStyle(color: .gray, fontSize: 14))
            }
            //MARK: Edit Username
            NavigationLink {
    
                        EditNameSheetView(editMode: true,showLoginSheet:.constant(false),signIn:.constant(false),chosenName:$chosenName)
                    
                
            } label: {
                HStack {
                    Label(String(localized: "profile.section.account.editUsername"), systemImage: "person.fill")
                        .labelStyle(ColorfulIconLabelStyle(color: .accent, fontSize: 17))
                    Spacer()
                }
            }
            .disabled(!network.isOnline)
            .foregroundColor(network.isOnline ? .primary : .secondary)
            
            //MARK: Manage Friends
            NavigationLink {
                EditFriendsSheetView().onDisappear {
                    Task {
                        Task {
                            try? await UNUserNotificationCenter.current().setBadgeCount(network.friendRequests.count)
                        }
                        let delivered = await UNUserNotificationCenter.current().deliveredNotifications()
                        let toRemove = delivered
                            .compactMap { $0.request.content.userInfo["notification_id"] as? String }
                            .filter { $0.hasPrefix("friend-request-accepted-") }
                        
                        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: toRemove)
                        try? await UNUserNotificationCenter.current().setBadgeCount(network.friendRequests.count)
                    }
                }
                        
                    
            } label: {
                HStack {
                    Label(String(localized: "profile.section.account.manageFriends"), systemImage: "person.2.fill")
                        .labelStyle(ColorfulIconLabelStyle(color: .accent, fontSize: 13))
                    Spacer()
                    if network.friendRequestProfiles.count > 0 {
                        Text("\(network.friendRequestProfiles.count)")
                            .foregroundStyle(.white)
                            .background {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 24, height: 24)
                            }
                            .padding(.trailing)
                    }
                }
            }.disabled(!network.isOnline)
            .foregroundColor(network.isOnline ? .primary : .secondary)
            
        }
    }

    // MARK: - Support Section
    private var supportSection: some View {
        Section {
            //MARK: Privacy
            
            Button {
                withAnimation(.easeInOut(duration: 0.285)) {
                    showPrivacyAlert = true
                }
            } label: {
                HStack {
                    Label(String(localized: "profile.section.support.privacy"), systemImage: "hand.raised.fill")
                        .labelStyle(ColorfulIconLabelStyle(color: .blue, fontSize: 15))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.tertiary)
                            .padding(.trailing,1.2)
                        .rotationEffect(.degrees(showPrivacyAlert ? 90 : 0))
                }
            }
            .foregroundColor(.primary)
            .alert(String(localized: "profile.section.support.privacy.alert.title"), isPresented: $showPrivacyAlert) {
                Button(role: .cancel) {
                    withAnimation(.easeInOut(duration: 0.285)) {
                        showPrivacyAlert = false
                    }
                } label: {
                    Text(String(localized: "profile.section.support.privacy.alert.dismiss"))
                }
            } message: {
                Text(String(localized: "profile.section.support.privacy.alert.message"))
            }
            
            //MARK: Contact
            Button {
                let subject = String(localized:"profile.tichuStatsSupport")
                let osVersion = ProcessInfo.processInfo.operatingSystemVersion
                let iosVersion = "\(osVersion.majorVersion).\(osVersion.minorVersion)"
                let iosBuild = ProcessInfo.processInfo.operatingSystemVersionString
                    .components(separatedBy: " ")
                    .last?
                    .trimmingCharacters(in: CharacterSet(charactersIn: "()")) ?? String(localized: "general.unknown")
                let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? String(localized: "general.unknown")
                let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? String(localized: "general.unknown")

                let body = """
                    
                    
                    
                    App Version: \(appVersion) (\(buildNumber))
                    iOS: \(iosVersion) (\(iosBuild))
                    Device: \(DeviceModelName())
                    User ID: \(userId)356af6d-ec96-49e1-a7e8-e372ce3c6363
                    """
                let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                if let url = URL(string: "mailto:leon@tichu.dev?subject=\(encodedSubject)&body=\(encodedBody)") {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack {
                    Label(String(localized: "profile.section.support.contact"), systemImage: "envelope.fill")
                        .labelStyle(ColorfulIconLabelStyle(color: .blue, fontSize: 14))
                }
                .foregroundStyle(Color.primary)
            }.foregroundColor(.primary)

            Button {
                if let url = URL(string: "https://github.com/LeonHTM/Tichu") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label(String(localized: "profile.section.support.sourceCode"), image: "github")
                    .labelStyle(ColorfulIconLabelStyle(color: .black, fontSize: 17))
            }
            .foregroundColor(.primary)
            Button{
                Task {
                    isAddingPasskey = true
                    defer { isAddingPasskey = false }
                    do {
                        try await network.addPasskeyToAccount()
                    } catch PasskeyError.cancelled {
                        // backed out of Face ID sheet — no-op
                    } catch PasskeyError.server(let code) {
                        addPasskeyErrorMessage = code == "challenge_expired"
                        ? String(localized:"passKeyError.expired")
                        : String(localized:"passKeyError.notAdd")
                        showAddPasskeyError = true
                    } catch {
                        addPasskeyErrorMessage = String(localized:"passKeyError.expired")
                        showAddPasskeyError = true
                    }
                }
            }label:{
                HStack {
                    
                    Label(String(localized:"profile.section.support.passKey"), systemImage:"person.badge.key.fill")
                            .labelStyle(ColorfulIconLabelStyle(color: .black, fontSize: 13))
                    Spacer()
                    if isAddingPasskey {
                        ProgressView()
                    }
                    
                }
            }
            .disabled(!network.isOnline || isAddingPasskey)
            .foregroundStyle(Color.primary)
            .alert(String(localized:"passKeyError.general"), isPresented: $showAddPasskeyError, presenting: addPasskeyErrorMessage) { _ in
                Button("OK", role: .cancel) {}
            } message: { message in
                Text(message)
            }
        }
    }

    // MARK: - Auth Section
    private var authSection: some View {
        Section {
            //MARK: Log Out
            Button {
                withAnimation(.easeInOut(duration: 0.285)) {
                    if network.isOnline {
                        Task {
                            await network.logout(profileId: userId)
                        }
                    } else {
                        showOfflineAlert = true
                    }
                }
            } label: {
                HStack {
                    Label(String(localized: "profile.section.auth.logOut"), systemImage: "rectangle.portrait.and.arrow.right.fill")
                        .labelStyle(ColorfulIconLabelStyle(color: .accentColor, fontSize: 13))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.tertiary)
                            .padding(.trailing,1.2)
                      
                }
                .foregroundColor(network.isOnline ? .primary : .secondary)
            }
        }
    }

    // MARK: - Delete Account Section
    private var deleteAccountSection: some View {
        Section {
            Button {
                withAnimation(.easeInOut(duration: 0.285)) {
                    if network.isOnline {
                        showDeleteAlert = true
                    } else {
                        showOfflineAlert = true
                    }
                }
            } label: {
                HStack {
                    Label(String(localized: "profile.section.deleteAccount.delete"), systemImage: "trash.fill")
                        .labelStyle(ColorfulIconLabelStyle(color: .red, fontSize: 14))
                        .foregroundStyle(.red)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.tertiary)
                            .padding(.trailing,1.2)
                        .rotationEffect(.degrees(showFriendsSheet ? 90 : 0))
                }
            }
            .foregroundStyle(.secondary)
            .alert(String(localized: "profile.section.deleteAccount.alert.title"), isPresented: $showDeleteAlert) {
                Button(role: .destructive) {
                    withAnimation(.easeInOut(duration: 0.285)) {
                        Task {
                            await network.deleteProfile(profileId: userId)
                        }
                        showDeleteAlert = false
                    }
                } label: {
                    Text(String(localized: "profile.section.deleteAccount.alert.confirm"))
                }
                Button(role: .cancel) {
                    withAnimation(.easeInOut(duration: 0.285)) {
                        showDeleteAlert = false
                    }
                }
            } message: {
                Text(String(localized: "profile.section.deleteAccount.alert.message"))
            }
        }
    }

    // MARK: Footer
    private var footerSection: some View {
        HStack {
            Spacer()
            VStack {
                if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                   let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                    Text(String(localized: "profile.footer.madeWith"))
                    Text(String(format: String(localized: "profile.footer.version"), version, build))
                        .foregroundStyle(.gray)
                }
            }
            Spacer()
        }
        .listRowBackground(Color.clear)
    }
}

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
                    Label(String(localized:"statistics.sort.rankingdown"), image: "123.down").tag(sortBy.valueUp)
                    Label(String(localized:"statistics.sort.rankingup"), image: "123.up").tag(sortBy.valueDown)
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



#Preview {
    ProfileView()
}
