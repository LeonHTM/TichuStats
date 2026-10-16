//
//  ExportDataView.swift
//  TichuStats
//
//  Created by Leon on 16.10.2026.
//

import SwiftUI
import UniformTypeIdentifiers

struct ExportDataView: View {
    //MARK: ObservedObjects and AppStorage
    @ObservedObject private var network = NetworkService.shared
    @AppStorage("userId") var userId: Int = -69420
    
    //MARK: Alert and Sheets
    @State private var showFolderPicker = false
    @State private var errorMessage: String?
    @State private var showOfflineAlert:Bool = false
    
    //MARK: Export Data
    @Binding var exportProfile: Bool
    @Binding var exportSettings: Bool
    @Binding var exportFriends: Bool
    @Binding var exportGames: Bool
    @Binding var exportEloHistory: Bool
    @Binding var exportStatsHistory: Bool
    @Binding var fullStatsHistory: Bool
    
    //MARK: Button should be disabled when no Data selected
    private var buttonDisabled:Bool{
        return exportProfile == false && exportSettings == false && exportFriends == false && exportGames == false && exportStatsHistory == false && exportEloHistory == false
    }
    
    //MARK: Hands the chosen folder to the ExportCoordinator
    private func startExport(to folderURL: URL) {
        do {
            try ExportCoordinator.shared.submit(
                .init(userId: userId, folderURL: folderURL, exportProfile: exportProfile, exportSettings: exportSettings, exportFriends: exportFriends, exportGames: exportGames, exportEloHistory: exportEloHistory, exportStatsHistory: exportStatsHistory, fullStatsHistory: fullStatsHistory)
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    
    var body: some View {
        NavigationStack{
            VStack{
                List{
                    
                    //Profile Section
                    Section{
                        Toggle(String(localized:"export.profileData"), isOn: $exportProfile)
                        Toggle(String(localized: "export.settingsData"), isOn: $exportSettings)
                        Toggle(String(localized:"export.friendsData"), isOn: $exportFriends)
                    }header:{
                        Text(String(localized:"export.title.profileData"))
                    }footer:{
                        Text(String(localized:"export.description.profileData"))
                    }
                    
                    //Games Section
                    Section{
                        Toggle(String(localized:"export.gamesData"), isOn: $exportGames)
                    }header:{
                        Text(String(localized: "export.title.gamesData"))
                    }footer:{
                        Text(String(localized:"export.description.gamesData"))
                    }
                    
                    //Statistcs Section
                    Section{
                        Toggle(String(localized:"export.eloRating"), isOn: $exportEloHistory)
                        Toggle(String(localized:"export.statistics"),isOn: $exportStatsHistory)
                        if exportStatsHistory{
                            Toggle(String(localized:"export.fullHistory"),isOn: $fullStatsHistory)
                        }
                        
                    }header:{
                        Text(String(localized:"export.title.statistics"))
                    }footer:{
                        Text(String(localized:"export.description.statistics"))
                    }
                    
                }.animation(.easeInOut,value:exportStatsHistory)
            }.safeAreaInset(edge:.bottom){
                HStack{
                    Spacer()
                    Button{
                        if network.isOnline {
                            showFolderPicker = true
                        } else {
                            showOfflineAlert = true
                        }
                    }label:{
                        Text(String(localized:"export.export"))
                            .foregroundStyle(Color.primary)
                            .padding()
                            .glassEffect(.regular.tint(buttonDisabled ? Color.secondary : .accent).interactive())
                    }.disabled(buttonDisabled)
                        
                    Spacer()
                    
                }
                .padding(.bottom, 10)
            }
            .alert(isPresented:$showOfflineAlert){
                OfflineView.offlineAlert()
            }
            .fileImporter(
                isPresented: $showFolderPicker,
                allowedContentTypes: [.folder]
            ) { result in
                switch result {
                case .success(let folderURL):
                    startExport(to: folderURL)
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
            .alert(String(localized:"export.failed"),
                   isPresented: Binding(get: { errorMessage != nil },
                                        set: { if !$0 { errorMessage = nil } })) {
                Button(String(localized:"general.alert.ok"), role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
            .navigationTitle(String(localized:"export.title.data"))
            .toolbarTitleDisplayMode(.inline)
        }
    }
}


