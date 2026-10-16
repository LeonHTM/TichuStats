//
//  Tips.swift
//  TichuStats
//
//  Created by Leon on 13.05.2026.
//

import SwiftUI
import TipKit


//MARK: - Tip to indicate that user can swipe left to edit or remove a Round used in EditRoundsSheetView
struct ListSwipeTip: Tip {
    var title: Text {
        Text(String(localized:"tips.listSwipe.title"))
    }
    var message: Text? {
        Text(String(localized:"tips.listSwipe.message"))
    }
    var image: Image? {
        Image(systemName: "arrow.left.circle")
    }
}
//MARK: - Tip to indicate that user can swipe left to remove a Friend used in EditFriendsSheetView
struct ListSwipeFriendTip: Tip {
    var title: Text {
        Text(String(localized:"tips.listSwipeFriend.title"))
    }
    var message: Text? {
        Text(String(localized:"tips.listSwipeFriend.message"))
    }
    var image: Image? {
        Image(systemName: "arrow.left.circle")
    }
}

//MARK: - Tip to indicate that user can tap on rows the show more Information used in HistoryView (Not in use anymore)
struct HistoryTapTip: Tip {
    var title: Text {
        Text(String(localized:"tips.historyTap.title"))
    }
    var message: Text? {
        Text(String(localized:"tips.historyTap.message"))
    }
    var image: Image? {
        Image(systemName: "hand.tap")
    }
    
}

//MARK: - Tip to indicate that a user should favorize a game to be able to pick it in favorite game widget used in GameSummarySheetView
struct FavoriteGameTip : Tip{
    var title:Text{
        Text(String(localized:"tips.favoriteGameTip.title"))
    }
    var message: Text? {
        Text(String(localized:"tips.favoriteGameTip.message"))
    }
    var image: Image? {
        Image(systemName: "widget.small")
    }
}
