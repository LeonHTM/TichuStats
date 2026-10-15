//
//  TichuWidgetsBundle.swift
//  TichuStatsWidgets
//
//  Created by Leon on 03.06.2026.
//

import WidgetKit
import SwiftUI

@main
struct TichuWidgetsBundle: WidgetBundle {
    var body: some Widget {
        GraphWidget()
        TichuWidgets()
        GameWidget()
    }
}
