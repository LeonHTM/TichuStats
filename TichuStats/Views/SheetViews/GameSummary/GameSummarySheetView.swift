//
//  GameSummarySheetView.swift
//  Tichu
//
//  Created by Leon on 02.05.2026.
//

import SwiftUI
import UIKit

struct GameSummarySheetView: View {
    
    @AppStorage("isLoadingShare") private var isLoadingShare: Bool = false

    // MARK: - Bindings
    @Binding var showGameOverViewSheetView: Bool
    var currentGameId: Int?
    @Binding var revanche: Bool
    var tie:Bool

    // MARK: - Dependencies
    let profiles: [Profile]
    @ObservedObject var network: NetworkService

    // MARK: - State
    @Binding var selectedTab: Int
    @State private var showDeleteGameAlert: Bool = false
    @State private var shareImageToPresent: UIImage?
    @State private var renderedImage: Image?

    // MARK: - Props
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.displayScale) private var displayScale
    var showRevancheButton: Bool
    @Binding var allowEditing: Bool

    private var currentGame: Game? {
        network.games.first(where: { $0.id == currentGameId })
    }

    private var winnerName: String {
        guard let winnerId = currentGame?.winner else {if tie {return String(localized:"general.tie")} else {return String(localized: "general.unknown") }}
        
        if winnerId == 1 { return String(format:String(localized: "general.team"),String(1)) }
        if winnerId == 2 { return String(format:String(localized: "general.team"),String(2)) }
        if winnerId == 3 {return String(localized:"general.tie")}
        return String(localized: "general.unknown")
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                gameContent
                if isLoadingShare {
                    ProgressView()
                }
            }
            .sheet(isPresented: Binding(
                get: { shareImageToPresent != nil },
                set: { if !$0 { shareImageToPresent = nil } }
            )) {
                if let image = shareImageToPresent {
                    ActivityViewController(
                        title: String(format: String(localized: "gamesummary.share.activity.title"), String(currentGame?.date.formatted(date: .numeric, time: .omitted) ?? String(localized: "general.unknown"))),
                        message: String(localized: "general.madeWith"),
                        image: image
                    )
                }
            }
            .toolbar {
                bottomToolbar
                toolbarContent
            }.onChange(of: currentGame){
                showGameOverViewSheetView = false
            }
            .navigationTitle(tie || currentGame?.winner == 3 ?
                             String(winnerName):
            String(format: String(localized: "gamesummary.title.won"), String(winnerName)))
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Game Content
    private var gameContent: some View {
        Group {
            switch selectedTab {
            case 0:
                VStack {
                    GameSummaryChartView(currentGameId: currentGameId)
                        .frame(width: 350)
                    Spacer()
                }
            case 1:
                GameSummaryListView(
                    showGameSummarySheetView: $showGameOverViewSheetView,
                    currentGameId: currentGameId,
                    profiles: profiles,
                    network: network,
                    allowEditing: $allowEditing
                )
                .padding(.bottom, -50)
            default:
                EmptyView()
            }
        }
        //Share game Stuff
        .onAppear {
            let renderer = ImageRenderer(content: GameSummaryShareView(
                currentGameId: currentGameId,
                rounds: network.roundsByGame[currentGameId ?? 0] ?? [],
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .top) {
            Picker(String(localized: "gamesummary.picker.view"), selection: $selectedTab) {
                Text(String(localized: "gamesummary.tab.graph")).tag(0)
                Text(String(localized: "gamesummary.tab.list")).tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }

    // MARK: - Bottom Toolbar
    @ToolbarContentBuilder
    private var bottomToolbar: some ToolbarContent {
        GameSummaryBottomToolbar(
            renderedImage: renderedImage,
            currentGame: currentGame,
            allowEditing: $allowEditing,
            showDeleteGameAlert: $showDeleteGameAlert,
            showGameOverViewSheetView: $showGameOverViewSheetView,
            network: network,
            currentGameId: currentGameId
        )
    }

    // MARK: - Top Toolbar
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(role: .cancel) {
                showGameOverViewSheetView = false
            } label: {
                Image(systemName: "xmark")
            }
        }
        if showRevancheButton {
            ToolbarItem(placement: .confirmationAction) {
                Button(role: .confirm) {
                    revanche = true
                    showGameOverViewSheetView = false
                } label: {
                    Text(String(localized: "gamesummary.toolbar.revanche"))
                }
            }
        }
    }
}

// MARK: - GameSummaryBottomToolbar

struct GameSummaryBottomToolbar: ToolbarContent {
    //@Namespace private var ShareSheetSpace
    let renderedImage: Image?
    let currentGame: Game?
    @Binding var allowEditing: Bool
    @Binding var showDeleteGameAlert: Bool
    @Binding var showGameOverViewSheetView: Bool
    @ObservedObject var network: NetworkService
    let currentGameId: Int?

    var body: some ToolbarContent {
        ToolbarItem(placement: .bottomBar) {
            if let renderedImage {
                ShareLink(
                    item: renderedImage,
                    message: Text(String(localized: "history.share.check")),
                    preview: SharePreview(String(localized: "gamesummary.share.preview.title"), image: renderedImage)
                )
                .labelStyle(.iconOnly)
                .imageScale(.large)
                .foregroundColor(.primary)
            }
        }

        ToolbarItem(placement: .bottomBar) {
            Spacer()
        }

        ToolbarItem(placement: .bottomBar) {
            Button {} label: {
                HStack {
                    Text("\(currentGame?.currentPointsTeam1 ?? 0)")
                        .fontWeight(.bold)
                        .foregroundStyle(Color.accentColor)
                    Text(":").fontWeight(.bold).font(.title3)
                    Text("\(currentGame?.currentPointsTeam2 ?? 0)")
                        .fontWeight(.bold)
                }
            }
        }

        if allowEditing {
            ToolbarSpacer(placement:.bottomBar)
            ToolbarItem(placement: .bottomBar) {
                Button {
                    showDeleteGameAlert = true
                } label: {
                    Image(systemName: "trash")
                }
                .foregroundColor(.primary)
                .alert(String(localized: "gamesummary.delete.alert.title"), isPresented: $showDeleteGameAlert) {
                    fuckyouView(showDeleteGameAlert: $showDeleteGameAlert, currentGameId: currentGameId ?? 0, showGameOverViewSheetView: $showGameOverViewSheetView)//.navigationTransition(.zoom(sourceID: "69420", in: ShareSheetSpace))
                } message: {
                    Text(String(localized: "gamesummary.delete.alert.message"))
                }
            }//.matchedTransitionSource(id: "69420", in: ShareSheetSpace)
        }else{
            ToolbarSpacer(placement:.bottomBar)
            ToolbarItem(placement: .bottomBar) {
                Button{
                    Task{
                        await network.updateGameFavorite(gameId: currentGameId ?? 0, favorite: !currentGame!.favorite )
                    }
                }label:{
                    Image(systemName: currentGame?.favorite ?? false ? "star.slash.fill" :"star.fill")
                }.sensoryFeedback(.success,trigger:currentGame?.favorite ?? false)
            }
        }
    }
}

struct fuckyouView: View{
    @Binding var showDeleteGameAlert: Bool
    var currentGameId: Int
    @Binding var showGameOverViewSheetView: Bool
    var body: some View{
        Button(String(localized: "gamesummary.delete.alert.cancel"), role: .cancel) { showDeleteGameAlert = false }
        Button(String(localized: "gamesummary.delete.alert.confirm"), role: .destructive) {
            Task {
                await NetworkService.shared.deleteGame(gameId: currentGameId)
                showGameOverViewSheetView = false
            }
        }
    }
}
