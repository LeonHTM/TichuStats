//
//  TichuStats.swift
//  Tichu
//
//  Created by Leon on 21.04.2026.
//

import SwiftUI

@main
struct TichuStats: App {
    @UIApplicationDelegateAdaptor private var appDelegate: CustomAppDelegate
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            MainView()
        }
        .onChange(of: scenePhase) {
            // If the App gets into foreground fetch
            if scenePhase == .active {
                Task {
                    let wasDisconnected = SocketService.shared.reconnectIfNeeded()
                       if wasDisconnected {
                           await NetworkService.shared.fetch(load: false)
                       }
                }
            }else{
                SocketService.shared.disconnect()
            }
        }
    }
}
