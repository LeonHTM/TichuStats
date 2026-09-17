//
//  StatsShareView.swift
//  Tichu
//
// Created by Leon on 01.06.2026.
//

import SwiftUI

struct ShareStatsView: View{
    
    @Environment(\.colorScheme) var colorScheme
    var userName: String
    var userImageData: Data?
    var elo: Double?
    var winnerPercentage: Double
    var tichuMaster: Double
    let accentCo: Color
    
    @Binding var Tags:[String]
    
    

    var body: some View{
        VStack{
            VStack(alignment: .center){
                ProfileImage(data:userImageData,size:100).shadow(radius: 10)
                Text("\(userName)")
                    .font(.largeTitle)
                    .fontWeight(.bold).frame(width:500)
                Text("\(String(localized:"statistics.statscontainer.title.rating")):\(String(format: "%.2f", elo ?? 1000.00))")
                    .fontWeight(.bold)
                    .foregroundStyle(accentCo)
            }
            Divider()
            VStack(alignment: .leading){
                
                /*Text("Elo Graph").foregroundStyle(Color.secondary).fontWeight(.bold).padding(.vertical,7)
                
                Image(systemName: "graph.2d").resizable()
                    .scaledToFill()
                    .frame(width:300,height:300)*/
                
                
                
                
                
                
                Text(String(localized:"shareStatistics.performance")).foregroundStyle(Color.secondary).fontWeight(.bold).padding(.vertical,7)
                
                HStack{
                    Text(String(localized:"statistics.statscontainer.title.winner")).foregroundStyle(.secondary)
                    Spacer()
                    Text("\(winnerPercentage*100)%").fontWeight(.bold).foregroundStyle(accentCo)
                }
                Divider()
                HStack{
                    Text(String(localized:"statistics.statscontainer.title.tichumaster")).foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(tichuMaster))").fontWeight(.bold)
                }
               
                
                Text(String(localized:"general.title.statistics")).foregroundStyle(Color.secondary).fontWeight(.bold).padding(.vertical,7)
                ChipsView(tags: Tags,selectedTags: .constant([]), onlyOne:true) { tag, isSelected in
                   
                    ChipViewShare(tag:tag, isSelected: isSelected,showAlert:true,accentCo:accentCo)
                    }
                Divider()
                HStack{
                    Spacer()
                    Text(String(format:String(localized:"statistics.share.captured"),Date().formatted(date: .complete, time: .shortened)))
                    Spacer()
                }.foregroundStyle(Color.secondary).font(.system(size:16))
            }.padding(.horizontal)
            HStack {
                Text(String(localized:"general.madeWith")).fontWeight(.bold)
                Image("AppLogo").resizable().frame(width: 45, height: 45)
            }
                
        }.frame(height:700)
            
        }
    }




struct ChipViewShare: View {
    let tag: String
    let isSelected: Bool
    let showAlert: Bool
    let accentCo: Color
    @State private var showOfflineAlert: Bool = false

    var body: some View {
        HStack(spacing: 10) {
            Text(tag)
                .font(.callout)
                .foregroundStyle(.white)
                .alert(isPresented: $showOfflineAlert) {
                    OfflineView.offlineAlert()
                }
                .onChange(of: isSelected) { _, _ in
                    if showAlert == true {
                        showOfflineAlert = true
                    }
                }

            if isSelected && (showAlert == false) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.red)
            }
        }
        .padding(12)
        .glassEffect(.regular.tint(accentCo).interactive())
    }
}
