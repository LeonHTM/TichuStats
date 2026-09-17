//
//  StatsContainer.swift
//  Tichu
//
//  Created by Leon on 24.04.2026.
//

import SwiftUI
import WidgetKit
//MARK: - StatsContainer used in StatsView
struct StatsContainer: View {

    
    @Environment(\.colorScheme) var colorScheme

    
    //MARK: Vars
    var title: String
    var description: String
    var image: String
    var counterLeft: Int
    var counterRight: Int
    var value: Double
    var percentage: Bool
    var inTop: Double
    var stat: Profile.playerStat
    @Binding var timeframe: Timeframe 
    //MARK: Computed Vars
    var items: [Profile]
    var digits: Int = 0
    var reverse: Bool = false
    
    
    //MARK: Width tracking (so minHeight can match width)
    @State private var containerWidth: CGFloat = 0
    
    //MARK: Body
    var body: some View {
        NavigationLink{
            StatsDetailView(
                value: value,
                percentage: percentage,
                inTop:inTop,
                stat: stat,
                timeframe: $timeframe,
                items: items,
                digits: digits,
                reverse: reverse
            )
        }label:{
            VStack(alignment:.leading){
                HStack{
                    //For certain Image insteady of loading systeImage load custom Image
                    /*if image == "exclamationmark.2.circle" || image == "bomb" || image == "exclamationmark.3.circle" {
                     Image(image)
                     .font(.system(size:16))
                     .frame(width: 20, height: 20)
                     .foregroundColor(.accentColor)
                     .redactedShimmer()
                     }else{
                     Image(systemName:image)
                     .font(.system(size:16))
                     .foregroundColor(.accentColor)
                     .redactedShimmer()
                     }*/
                    Text(title)
                        .font(.system(size:20))
                        .fontWeight(.bold)
                        .redactedShimmer()
                    Spacer()
                    
                    Image(systemName:"chevron.right.circle.fill").foregroundStyle(Color.secondary)
                        .redactedShimmer()
                        .font(.system(size:16))
                    
                }.padding(.bottom,6)
                
                VStack(alignment:.leading){
                    ZStack{
                        
                        
                        if !(stat == .elo){
                            if timeframe == .day{
                                
                                Text(String(localized: "statistics.timeframe.day"))
                            }else if timeframe == .week{
                                Text(String(localized: "statistics.timeframe.week"))
                            }else if timeframe == .month{
                                Text(String(localized: "statistics.timeframe.month"))
                            }else if timeframe == .year{
                                Text(String(localized: "statistics.timeframes.year"))
                            }else{
                                Text(String(localized: "statistics.timeframes.alltime"))
                            }
                        }else{
                            Text(String(localized: "statistics.timeframes.alltime"))
                        }
                    }.animation(.easeInOut,value:timeframe).font(.system(size:14)).redactedShimmer()
                    
                    HStack{
                        if percentage == false {
                            if digits == 0{
                                Text("\(Int(value))").redactedShimmer()
                            }else{
                                Text(value, format: .number.precision(.fractionLength(digits))).fontWeight(.bold).redactedShimmer()
                            }
                            
                        }else{
                            
                            Text("\(Int(value*100))%")
                            
                            
                            
                                .fontWeight(.bold)
                                .redactedShimmer()
                        }
                        
                    }.foregroundColor(.accentColor).font(.system(size:29/*,design:.rounded*/)).fontWeight(.bold)
                }
                /*Text(description)
                 .font(.system(size:16))
                 .multilineTextAlignment(.leading)
                 .padding(.top,10)
                 .padding(.horizontal,10)
                 //.redactedShimmer()*/
                Spacer()
                if !items.isEmpty{
                    Text(String(localized:"statistics.statscontainer.comparison")).font(.system(size:14)).padding(.bottom,-5).padding(.top,1).redactedShimmer()
                    Divider()
                }else{
                    Text(String(localized:"statistics.statscontainer.explanation")).font(.system(size:14)).padding(.bottom,-5).padding(.top,1).padding(.bottom,5).redactedShimmer()
                    Text(description)
                        .font(.system(size:16))
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(.secondary)
                    
                    
                        .redactedShimmer()
                }
                
                //Automtically Load Dictionary and display it
                VStack(alignment: .leading, spacing: 8) {
                    
                    //For loop over all indices, id:value itssself,index is index
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        let itemValue = item.getStat(for: stat,timeframe:timeframe)
                        VStack(spacing: 0) {
                            HStack {
                                if itemValue > value {
                                    HStack{
                                        if reverse {
                                            Image(systemName: "chevron.down.circle.fill")
                                                .foregroundStyle(.red)
                                                .opacity(colorScheme == .dark ? 0.6 : 0.75)
                                                .font(.system(size:14))
                                                .redactedShimmer()
                                        }else{
                                            Image(systemName: "chevron.up.circle.fill")
                                                .foregroundStyle(.green)
                                                .opacity(colorScheme == .dark ? 0.6 : 0.75)
                                                .font(.system(size: 14))
                                                .redactedShimmer()
                                        }
                                        
                                        Text(item.name ?? "")
                                            .font(.system(size: 13))
                                        
                                            .redactedShimmer()
                                    }.lineLimit(1)
                                } else if itemValue.isEqual(to: value) || itemValue == value {
                                    HStack{
                                        Image(systemName: "equal.circle.fill")
                                            .foregroundStyle(.yellow)
                                            .opacity(colorScheme == .dark ? 0.6 : 0.75)
                                            .font(.system(size: 14))
                                            .redactedShimmer()
                                        Text(item.name ?? "")
                                            .font(.system(size: 13))
                                        
                                            .redactedShimmer()
                                    }.lineLimit(1)
                                } else {
                                    HStack{
                                        if reverse{
                                            Image(systemName: "chevron.up.circle.fill")
                                                .foregroundStyle(.green)
                                                .opacity(colorScheme == .dark ? 0.6 : 0.75)
                                                .font(.system(size: 14))
                                                .redactedShimmer()
                                        }else{
                                            Image(systemName: "chevron.down.circle.fill")
                                                .foregroundStyle(.red)
                                                .opacity(colorScheme == .dark ? 0.6 : 0.75)
                                                .font(.system(size:14))
                                                .redactedShimmer()
                                        }
                                        Text(item.name ?? "")
                                            .font(.system(size: 13))
                                            .redactedShimmer()
                                    }
                                    //.lineLimit(.max)
                                    .lineLimit(1)
                                }
                                Spacer()
                                Text(percentage ? "\(Int(itemValue*100))%" : "\(Int(itemValue))")
                                    .font(.system(size: 14))
                                    .redactedShimmer()
                            }.padding(.bottom,3).padding(.top,-5)
                            if index != items.count - 1 {
                                Divider()
                            }
                        }
                    }
                }
                .animation(.easeInOut, value: items)
            }
            .padding(10)
            .frame(maxHeight: .infinity)
            .frame(minHeight: max(containerWidth, 164), alignment: .topLeading)
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onAppear { containerWidth = geo.size.width }
                        .onChange(of: geo.size.width) {
                            containerWidth = geo.size.width
                        }
                }
            )
            .containerBackground(.fill.tertiary, for: .widget)
            .background(colorScheme == .dark ? Color(uiColor: .tertiarySystemFill) : .white, in: .rect(cornerRadius: 24))
            /*.background(colorScheme == .dark ? Color(uiColor: .tertiarySystemFill) : .white, in: .rect(cornerRadius: 24))*/
            
        }
        .foregroundStyle(Color.primary)
    }
}


struct StatsDetailView: View {
    @ObservedObject private var network = NetworkService.shared
    @AppStorage("userId") var userId: Int = -69420
    @Environment(\.colorScheme) var colorScheme
    @State private var isLoading: Bool = false
    
    
    
    var value: Double
    var percentage: Bool
    var inTop: Double
    var stat: Profile.playerStat
    @Binding var timeframe: Timeframe
    //MARK: Computed Vars
    var items: [Profile]
    var digits: Int = 0
    var reverse: Bool = false
    
    
    private func statToString(stat: Profile.playerStat,title: Bool = true) -> String {
        if title{
            switch stat {
            case .elo:              return String(localized: "statistics.statscontainer.title.rating")
            case .winnerPercentage: return String(localized: "statistics.statscontainer.title.winner")
            case .averagePlacement: return String(localized: "statistics.statscontainer.title.climber")
            case .tichuMaster:      return String(localized: "statistics.statscontainer.title.tichumaster")
            case .visionary:        return String(localized: "statistics.statscontainer.title.visionary")
            case .addict:            return String(localized: "statistics.statscontainer.title.addict")
            case .teamplayer:       return String(localized: "statistics.statscontainer.title.teamplayer")
            case .announcer:        return String(localized: "statistics.statscontainer.title.announcer")
            case .saboteur:          return String(localized: "statistics.statscontainer.title.saboteur")
            case .gambler:           return String(localized: "statistics.statscontainer.title.gambler")
            case .bigGambler:       return String(localized: "statistics.statscontainer.title.bigGambler")
            case .pinguGambler:     return String(localized: "statistics.statscontainer.title.pinguGambler")
            case .bomber:            return String(localized: "statistics.statscontainer.title.bomber")
            default:
                return String(localized:"general.unknown")
            }
        }else{
            switch stat {
            case .elo:              return String(localized: "statistics.statscontainer.description.rating.long")
            case .winnerPercentage: return String(localized: "statistics.statscontainer.description.winner.long")
            case .averagePlacement: return String(localized: "statistics.statscontainer.description.climber.long")
            case .tichuMaster:      return String(localized: "statistics.statscontainer.description.tichumaster.long")
            case .visionary:        return String(localized: "statistics.statscontainer.description.visionary.long")
            case .addict:            return String(localized: "statistics.statscontainer.description.addict.long")
            case .teamplayer:       return String(localized: "statistics.statscontainer.description.teamplayer.long")
            case .announcer:        return String(localized: "statistics.statscontainer.description.announcer.long")
            case .saboteur:          return String(localized: "statistics.statscontainer.description.saboteur.long")
            case .gambler:           return String(localized: "statistics.statscontainer.description.gambler.long")
            case .bigGambler:       return String(localized: "statistics.statscontainer.description.bigGambler.long")
            case .pinguGambler:     return String(localized: "statistics.statscontainer.description.pinguGambler.long")
            case .bomber:            return String(localized: "statistics.statscontainer.description.bomber.long")
            default:
                return String(localized:"general.unknown")
            }
        }
    }
    
    private func timeFrametoString(timeframe:Timeframe) -> String{
        switch timeframe{
        case .day: return "Daily"
        case .week: return "Weekly"
        case .month: return "Monthly"
        case .year: return "Yearly"
        case .allTime: return "Since you downloaded the TichuStats"
        }
    }
    
    var body: some View {
        NavigationStack{
            VStack(alignment:.leading,spacing:12){
                Picker(
                    String(localized: "gamesummary.picker.view"),
                    selection: $timeframe
                ) {
                    Text("All time").tag(Timeframe.allTime)
                    Text("Year").tag(Timeframe.year)
                    Text("Month").tag(Timeframe.month)
                    Text("Week").tag(Timeframe.week)
                    Text("Day").tag(Timeframe.day)
                }
                .pickerStyle(.segmented)
                
                
                
                
                Text("Current Value").font(.system(size:16)).foregroundStyle(Color.secondary).padding(.bottom,-15)
                HStack{
                    if percentage == false {
                        if digits == 0{
                            Text("\(Int(value))").redactedShimmer()
                        }else{
                            Text(value, format: .number.precision(.fractionLength(digits))).fontWeight(.bold).redactedShimmer()
                        }
                        
                    }else{
                        
                        Text("\(Int(value*100))%")
                        
                        
                        
                            .fontWeight(.bold)
                            .redactedShimmer()
                    }
                    
                }.foregroundColor(.accentColor).font(.system(size:29/*,design:.rounded*/)).fontWeight(.bold)
                Text(timeFrametoString(timeframe: timeframe)).font(.system(size:16)).foregroundStyle(Color.secondary).padding(.top,-15)
                
                StatsHistoryGraph(
                    timeframe: timeframe,
                    percentage:percentage,
                    inTop:inTop,
                    digits:digits,
                    reverse:reverse,
                    data: network.statsHistory,
                    stat: stat,
                    isLoading: isLoading
                ).frame(height: 250)
                
                Text("Explanation").font(.system(size:16)).foregroundStyle(Color.secondary).padding(.vertical,-15)
                Text(statToString(stat: stat,title:false))
                Text("Comparison").foregroundStyle(Color.secondary)
                //Automtically Load Dictionary and display it
                VStack(alignment: .leading, spacing: 8) {
                    
                    //For loop over all indices, id:value itssself,index is index
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        let itemValue = item.getStat(for: stat,timeframe:timeframe)
                        VStack(spacing: 0) {
                            HStack {
                                if itemValue > value {
                                    HStack{
                                        if reverse {
                                            Image(systemName: "chevron.down.circle.fill")
                                                .foregroundStyle(.red)
                                                .opacity(colorScheme == .dark ? 0.6 : 0.75)
                                                .font(.system(size:14))
                                                .redactedShimmer()
                                        }else{
                                            Image(systemName: "chevron.up.circle.fill")
                                                .foregroundStyle(.green)
                                                .opacity(colorScheme == .dark ? 0.6 : 0.75)
                                                .font(.system(size: 14))
                                                .redactedShimmer()
                                        }
                                        
                                        Text(item.name ?? "")
                                            .font(.system(size: 13))
                                        
                                            .redactedShimmer()
                                    }.lineLimit(1)
                                } else if itemValue.isEqual(to: value) || itemValue == value {
                                    HStack{
                                        Image(systemName: "equal.circle.fill")
                                            .foregroundStyle(.yellow)
                                            .opacity(colorScheme == .dark ? 0.6 : 0.75)
                                            .font(.system(size: 14))
                                            .redactedShimmer()
                                        Text(item.name ?? "")
                                            .font(.system(size: 13))
                                        
                                            .redactedShimmer()
                                    }.lineLimit(1)
                                } else {
                                    HStack{
                                        if reverse{
                                            Image(systemName: "chevron.up.circle.fill")
                                                .foregroundStyle(.green)
                                                .opacity(colorScheme == .dark ? 0.6 : 0.75)
                                                .font(.system(size: 14))
                                                .redactedShimmer()
                                        }else{
                                            Image(systemName: "chevron.down.circle.fill")
                                                .foregroundStyle(.red)
                                                .opacity(colorScheme == .dark ? 0.6 : 0.75)
                                                .font(.system(size:14))
                                                .redactedShimmer()
                                        }
                                        Text(item.name ?? "")
                                            .font(.system(size: 13))
                                            .redactedShimmer()
                                    }
                                    //.lineLimit(.max)
                                    .lineLimit(1)
                                }
                                Spacer()
                                Text(percentage ? "\(Int(itemValue*100))%" : "\(Int(itemValue))")
                                    .font(.system(size: 14))
                                    .redactedShimmer()
                            }.padding(.bottom,3).padding(.top,-5)
                            if index != items.count - 1 {
                                Divider()
                            }
                        }
                    }
                }
                .animation(.easeInOut, value: items)
                
                Spacer()
            }.padding(.horizontal)
                .animation(.easeInOut,value:timeframe)
                .toolbarTitleDisplayMode( .large)
                .navigationTitle(statToString(stat: stat))
        }.task{
            
                isLoading = true
                if network.statsHistory == [:]{
                    await network.fetchProfileStatsHistory(profileId: userId)
                }
                isLoading = false
                
            
        }
    }
}


import Charts

struct StatPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct StatsHistoryGraph: View {
    let timeframe: Timeframe
    let percentage: Bool
    let inTop: Double
    let digits: Int
    let reverse: Bool

    
    let data: [String: [ProfileStats]]
    let stat: Profile.playerStat
    let isLoading: Bool

    private func stringforTimeframe(timeframe: Timeframe) -> String {
        switch timeframe {
        case .day:
            return "day"
        case .week:
            return "week"
        case .month:
            return "month"
        case .year:
            return "year"
        case .allTime:
            return "all_time"
        }
    }

    private var selectedData: [ProfileStats] {
        data[stringforTimeframe(timeframe: timeframe)] ?? []
    }

    private var chartData: [StatPoint] {
        var calendar = Calendar.current
        calendar.timeZone = .current

        let latestPerDay = Dictionary(grouping: selectedData) { entry -> Date in
            calendar.startOfDay(for: entry.calculatedAt)
        }
        .compactMapValues { entries in
            entries.max { $0.calculatedAt < $1.calculatedAt }
        }

        return latestPerDay.values.map { entry in
            StatPoint(
                date: entry.calculatedAt,
                value: percentage ? entry.getStat(for: stat) * 100 : entry.getStat(for: stat)
            )
        }
        .sorted { $0.date < $1.date }
    }

    var body: some View {
        
        if isLoading{
                   VStack{
                       Spacer()
                       HStack{
                           Spacer()
                           ProgressView()
                           Spacer()
                       }
                       Spacer()
                   }
        }else{
            VStack(alignment: .leading) {
                
                Chart {
                    ForEach(chartData) { point in
                        BarMark(
                            x: .value("Date", point.date),
                            y: .value("Value", point.value)
                            
                        )
                        .annotation(position: .top) {
                            if percentage {
                                Text("\(point.value, specifier: "%.0f")%")
                                    .font(.caption)
                            } else {
                                Text("\(point.value, specifier: "%.\(digits)f")")
                                    .font(.caption)
                            }
                        }
                    }
                }.chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(date, format: .dateTime.day().month(.abbreviated))
                            }
                        }
                    }
                }
                .frame(height: 250)
            }
        }
    }
}


//MARK: - Sortby enum

    enum sortBy: String, CaseIterable {
        case valueUp
        case valueDown
        case nameUp
        case nameDown
    }
