//
//  DebugSheetView.swift
//  Tichu
//
//  Created by Leon on 06.05.2026.
//

import SwiftUI

struct DebugSheetView: View {
    //MARK: Bindings
    @Binding var currentGame:Game
    @Binding var showDebugSheetView:Bool
    
    //MARK: Vars and Objects
    @State private var selectedTab: Int = 0
    
    var body: some View {
        NavigationStack{
            Group{
                switch selectedTab{
                case 0:
                    DebugNetworkView()
                case 1:
                    DebugProfileView()
                case 2:
                    DebugGameView()
                case 3:
                    DebugNotificationView()
                default:
                    EmptyView()
                }
                
                
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle(selectedTab == 0 ? "Debug: Networking" : selectedTab == 1 ? "Debug: Profie" : selectedTab == 2 ? "Debug: Games" : selectedTab == 3 ? "Debug: Notifications" : "Debug")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .top) {
                Picker(String(localized: "gamesummary.picker.view"), selection: $selectedTab) {
                    Text("Networking").tag(0)
                    Text("Profile").tag(1)
                    Text("Games").tag(2)
                    Text("Notifications").tag(3)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark") {
                        showDebugSheetView = false
                    }
                }
            }
            
        }
    }
}


struct DebugNetworkView: View{
    @ObservedObject private var network = NetworkService.shared
    @State private var switchApi: String = getURL(dev:true)
    var body: some View{
        VStack {
            Text(network.apiURL).font(.title3).fontWeight(.bold)
            TextField("Switch Api",text:$switchApi).padding().glassEffect(.regular.tint(.secondary.opacity(0.2)).interactive()).padding(.horizontal)
        
            Button(action: {
                network.apiURL = switchApi
            }) {
                VStack{
                    Text("Switch API to \(switchApi)")
                }
            }.buttonStyle(GlassButtonStyle())
            
            Button(action: {
                network.apiURL = getURL()
            }) {
                VStack{
                    Text("Reset API")
                }
            }.buttonStyle(.glassProminent)
            Spacer()
        }
    }
}

struct DebugProfileView: View{
    @ObservedObject private var network = NetworkService.shared
    @AppStorage("userId") var userId: Int = -69420
    @AppStorage("userImageData") var userImageData: Data?
    @AppStorage("userName") var userName: String = "Storage - Unknown"
    @AppStorage("userElo") var userElo: Double = 404
    @AppStorage("statsList") private var statsList: [Int] = []
    @AppStorage("defaultTarget") private var defaultTarget: Int = 1000
    @AppStorage("defaultAllowPingus") private var defaultAllowPingus: Bool = true
    @AppStorage("dragMode") var dragMode: Bool = false
    @AppStorage("favDic") var favDic: [Int:Int] = [:]
    var body: some View{
        VStack {
            HStack{
                Text("Id:\(userId)")
                Text("Name: \(userName)")
                Text("Elo: \(userElo)")
                ProfileImage(data:userImageData,size:44)
            }
            ScrollView{
                let elo = network.eloHistory
                Text(String(describing: elo))
                EloHistoryChartView(profileId: userId)
            }
            Spacer()
        }
    }
}

struct DebugGameView: View{
    @ObservedObject private var network = NetworkService.shared
    @State private var reCalculate: String = "0"
    var body: some View{
        VStack {
            TextField("Game to recalculate", text: $reCalculate).padding().glassEffect(.regular.tint(.secondary.opacity(0.2)).interactive()).padding(.horizontal)
            Button{
                Task{
                    guard let gameId = Int(reCalculate) else { return }
                    await network.reCalculate(gameId: gameId)
                }
            } label: {
                Text("Manually recalculate Game \(reCalculate)")
            }
            
            //Text("\(network.favDic)")
            Spacer()
        }
    }
}

struct DebugNotificationView: View{
    var body: some View{
        VStack {
            Button{
                UNUserNotificationCenter.current().removeAllDeliveredNotifications()
                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                Task{
                    try? await UNUserNotificationCenter.current().setBadgeCount(0)
                }
            }label:{
                Text("Reset Badges")
            }
            Spacer()
        }
    }
}
