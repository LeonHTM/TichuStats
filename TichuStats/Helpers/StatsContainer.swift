//
//  StatsContainer.swift
//  Tichu
//
//  Created by Leon on 24.04.2026.
//

import SwiftUI
import Charts
import Observation

//MARK: - Helpers


private func formatStat(_ v: Double, percentage: Bool, digits: Int) -> String {
    if percentage { return "\(Int(v * 100))%" }
    if digits == 0 { return "\(Int(v))" }
    return v.formatted(.number.precision(.fractionLength(digits)))
}

private extension Timeframe {
    // Key used by the server for this timeframe.
    var serverTimeframeKey: String {
        switch self {
        case .day: return "day"
        case .week: return "week"
        case .month: return "month"
        case .year: return "year"
        case .allTime: return "all_time"
        }
    }

    // Localized label shown on the stats cards.
    var cardLabel: String {
        switch self {
        case .day: return String(localized: "statistics.timeframe.day")
        case .week: return String(localized: "statistics.timeframe.week")
        case .month: return String(localized: "statistics.timeframe.month")
        case .year: return String(localized: "statistics.timeframes.year")
        case .allTime: return String(localized: "statistics.timeframes.alltime")
        }
    }
}

//MARK: - Comparison list (shared by StatsContainer and StatsDetailView)
struct ComparisonList: View {
    @Environment(\.colorScheme) private var colorScheme

    let items: [Profile]
    let stat: Profile.playerStat
    let timeframe: Timeframe
    let value: Double
    let percentage: Bool
    let reverse: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                let itemValue = item.getStat(for: stat, timeframe: timeframe)
                let icon = icon(for: itemValue)

                VStack(spacing: 0) {
                    HStack {
                        HStack {
                            Image(systemName: icon.name)
                                .foregroundStyle(icon.color)
                                .opacity(colorScheme == .dark ? 0.6 : 0.75)
                                .font(.system(size: 14))
                                .redactedShimmer()
                            Text(item.name ?? "")
                                .font(.system(size: 13))
                                .redactedShimmer()
                        }
                        .lineLimit(1)

                        Spacer()

                        Text(formatStat(itemValue, percentage: percentage, digits: 0))
                            .font(.system(size: 14))
                            .redactedShimmer()
                    }
                    .padding(.bottom, 3)
                    .padding(.top, -5)

                    if index != items.count - 1 {
                        Divider()
                    }
                }
            }
        }
        .animation(.easeInOut, value: items)
    }

    private func icon(for other: Double) -> (name: String, color: Color) {
        if other == value { return ("equal.circle.fill", .yellow) }
        let isUp = (other > value) != reverse
        return isUp ? ("chevron.up.circle.fill", .green)
                    : ("chevron.down.circle.fill", .red)
    }
}

//MARK: - StatsContainer used in StatsView
struct StatsContainer: View {
    @AppStorage("isLoading") private var isLoading = false
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

    @State private var containerWidth: CGFloat = 0

    //MARK: Body
    var body: some View {
        NavigationLink {
            StatsDetailView(
                value: value,
                percentage: percentage,
                inTop: inTop,
                stat: stat,
                timeframe: $timeframe,
                items: items,
                digits: digits,
                reverse: reverse
            )
        } label: {
            VStack(alignment: .leading) {
                HStack {
                    Text(title)
                        .font(.system(size: 20))
                        .fontWeight(.bold)
                        .redactedShimmer()
                    Spacer()

                    Image(systemName: "chevron.right.circle.fill").foregroundStyle(Color.secondary)
                        .redactedShimmer()
                        .font(.system(size: 16))
                }.padding(.bottom, 6)

                VStack(alignment: .leading) {
                    ZStack {
                        // Elo is always all-time
                        Text(stat == .elo ? Timeframe.allTime.cardLabel : timeframe.cardLabel)
                    }
                    .animation(.easeInOut, value: timeframe)
                    .font(.system(size: 14))
                    .redactedShimmer()

                    HStack {
                        Text(formatStat(value, percentage: percentage, digits: digits))
                            .redactedShimmer()
                    }
                    .foregroundColor(.accentColor)
                    .font(.system(size: 29))
                    .fontWeight(.bold)
                }

                Spacer()

                if !items.isEmpty && !isLoading {
                    Text(String(localized: "statistics.statscontainer.comparison"))
                        .font(.system(size: 14))
                        .padding(.bottom, -5)
                        .padding(.top, 1)
                        .redactedShimmer()
                    Divider()
                    ComparisonList(
                        items: items,
                        stat: stat,
                        timeframe: timeframe,
                        value: value,
                        percentage: percentage,
                        reverse: reverse
                    )
                } else {
                    Text(String(localized: "statistics.statscontainer.explanation"))
                        .font(.system(size: 14))
                        .padding(.bottom, -5)
                        .padding(.top, 1)
                        .padding(.bottom, 5)
                        .redactedShimmer()
                    Text(description)
                        .font(.system(size: 16))
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(.secondary)
                        .redactedShimmer()
                }

                
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
            .background(colorScheme == .dark ? Color(uiColor: .tertiarySystemFill) : .white, in: .rect(cornerRadius: 24))
        }
        .disabled(isLoading)
        .foregroundStyle(Color.primary)
    }
}

//MARK: - StatsDetailView
struct StatsDetailView: View {
    
    @State private var selection = StatsSelection()
    @ObservedObject private var network = NetworkService.shared
    @AppStorage("userId") var userId: Int = -69420
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

    var selectedPointDateInterval: String {
        let end = selection.selectedPoint?.date ?? Date.now

        let dayFormatter = DateFormatter()
        dayFormatter.setLocalizedDateFormatFromTemplate("d MMM")
        let yearFormatter = DateFormatter()
        yearFormatter.setLocalizedDateFormatFromTemplate("MMM YY")
        
        let currentProfile = network.profiles.first(where:{$0.id == userId})
        let days: Double
        let formatter: DateFormatter
        if stat == .elo{
            return dayFormatter.string(from: end)
        }else{
            switch timeframe {
            case .day:
                return dayFormatter.string(from: end)
            case .week:
                days = 7; formatter = dayFormatter
            case .month:
                days = 30; formatter = dayFormatter
            case .year:
                days = 365; formatter = yearFormatter
            case .allTime:
                let since = currentProfile?.createdAt ?? end
                return "\(yearFormatter.string(from: since)) - \(yearFormatter.string(from: end))"
            }
            let since = currentProfile?.createdAt ?? end
            var start = end.addingTimeInterval(-days * 24 * 3600)
            if (start < since){
                start = since
            }
            return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
        }
    }

    private func statToString(stat: Profile.playerStat, title: Bool = true) -> String {
        if title {
            switch stat {
            case .elo:              return String(localized: "statistics.statscontainer.title.rating")
            case .winnerPercentage: return String(localized: "statistics.statscontainer.title.winner")
            case .averagePlacement: return String(localized: "statistics.statscontainer.title.climber")
            case .tichuMaster:      return String(localized: "statistics.statscontainer.title.tichumaster")
            case .visionary:        return String(localized: "statistics.statscontainer.title.visionary")
            case .addict:           return String(localized: "statistics.statscontainer.title.addict")
            case .teamplayer:       return String(localized: "statistics.statscontainer.title.teamplayer")
            case .announcer:        return String(localized: "statistics.statscontainer.title.announcer")
            case .saboteur:         return String(localized: "statistics.statscontainer.title.saboteur")
            case .gambler:          return String(localized: "statistics.statscontainer.title.gambler")
            case .bigGambler:       return String(localized: "statistics.statscontainer.title.bigGambler")
            case .pinguGambler:     return String(localized: "statistics.statscontainer.title.pinguGambler")
            case .bomber:           return String(localized: "statistics.statscontainer.title.bomber")
            default:                return String(localized: "general.unknown")
            }
        } else {
            switch stat {
            case .elo:              return String(localized: "statistics.statscontainer.description.rating.long")
            case .winnerPercentage: return String(localized: "statistics.statscontainer.description.winner.long")
            case .averagePlacement: return String(localized: "statistics.statscontainer.description.climber.long")
            case .tichuMaster:      return String(localized: "statistics.statscontainer.description.tichumaster.long")
            case .visionary:        return String(localized: "statistics.statscontainer.description.visionary.long")
            case .addict:           return String(localized: "statistics.statscontainer.description.addict.long")
            case .teamplayer:       return String(localized: "statistics.statscontainer.description.teamplayer.long")
            case .announcer:        return String(localized: "statistics.statscontainer.description.announcer.long")
            case .saboteur:         return String(localized: "statistics.statscontainer.description.saboteur.long")
            case .gambler:          return String(localized: "statistics.statscontainer.description.gambler.long")
            case .bigGambler:       return String(localized: "statistics.statscontainer.description.bigGambler.long")
            case .pinguGambler:     return String(localized: "statistics.statscontainer.description.pinguGambler.long")
            case .bomber:           return String(localized: "statistics.statscontainer.description.bomber.long")
            default:                return String(localized: "general.unknown")
            }
        }
    }

    var body: some View {
        let headerOpacity: Double = selection.selectedPoint == nil ? 1 : 0

        NavigationStack {
            ScrollView{
            VStack(alignment: .leading, spacing: 12) {
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
                
                VStack(alignment: .leading, spacing: 12) {
                    Text(timeFrametoString(timeframe: timeframe,elo: stat == .elo))
                        .font(.system(size: 16))
                        .foregroundStyle(Color.secondary)
                        .padding(.bottom, -15)
                        .opacity(headerOpacity)
                    
                    HStack {
                        Text(formatStat(value, percentage: percentage, digits: digits))
                            .opacity(headerOpacity)
                            .redactedShimmer()
                    }
                    .foregroundColor(.accentColor)
                    .font(.system(size: 29))
                    .fontWeight(.bold)
                    
                    Text(selectedPointDateInterval)
                        .opacity(headerOpacity)
                        .font(.system(size: 16))
                        .foregroundStyle(Color.secondary)
                        .padding(.top, -15)
                }
                    StatsHistoryGraph(
                            timeframe: timeframe,
                            percentage: percentage,
                            inTop: inTop,
                            digits: digits,
                            reverse: reverse,
                            data: network.statsHistory,
                            stat: stat,
                            isLoading: isLoading,
                            selectedPointDateInterval: selectedPointDateInterval,
                            selection: selection
                        )
                    
                
                    .frame(height: 250)
                
                Text("Explanation")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.secondary)
                    .padding(.vertical, -15)
                Text(statToString(stat: stat, title: false))
                Text("Comparison").foregroundStyle(Color.secondary)
                
                ComparisonList(
                    items: items,
                    stat: stat,
                    timeframe: timeframe,
                    value: value,
                    percentage: percentage,
                    reverse: reverse
                )
                
                Spacer()
            }
            .padding(.horizontal)
            .animation(.easeInOut, value: timeframe)
            .toolbarTitleDisplayMode(.large)
            .navigationTitle(statToString(stat: stat))
        }
        }
        .task {
            isLoading = true
            if network.statsHistory.isEmpty {
                await network.fetchProfileStatsHistory(profileId: userId)
            }
            isLoading = false
        }
    }
}

//MARK: - Selection model
@Observable
final class StatsSelection {
    var selectedDate: Date?
    var selectedPoint: StatPoint?
}

struct StatPoint: Identifiable, Equatable {
    let date: Date
    let value: Double
    var id: Date { date }

    static func == (lhs: StatPoint, rhs: StatPoint) -> Bool {
        lhs.id == rhs.id
    }
}

//MARK: - History graph
struct StatsHistoryGraph: View {
    @Environment(\.colorScheme) var colorScheme
    let timeframe: Timeframe
    let percentage: Bool
    let inTop: Double
    let digits: Int
    let reverse: Bool

    let data: [String: [ProfileStats]]
    let stat: Profile.playerStat
    let isLoading: Bool
    let selectedPointDateInterval: String
    
    private var points: [StatPoint] {
        stat == .elo ? chartDataElo : chartData
    }

    @Bindable var selection: StatsSelection

    //Server handles data so no logic needed
    private var chartData: [StatPoint] {
        (data[timeframe.serverTimeframeKey] ?? [])
            .map { entry in
                let v = entry.getStat(for: stat)
                return StatPoint(date: entry.calculatedAt, value: percentage ? v * 100 : v)
            }
            .sorted { $0.date < $1.date }
    }
    
    //In this case we need to handle the data
    private var chartDataElo: [StatPoint] {
        let calendar = Calendar.current
        var currentElo: Double = 1000.0
        var latestPerDay: [Date: StatPoint] = [:]

        let sortedHistory = NetworkService.shared.eloHistory
            .sorted { ($0.changedAt ?? .distantPast) < ($1.changedAt ?? .distantPast) }

        for entry in sortedHistory {
            currentElo += entry.eloChange
            if let date = entry.changedAt {
                // Later entries overwrite earlier ones such that the newest of day wins
                latestPerDay[calendar.startOfDay(for: date)] = StatPoint(date: date, value: currentElo)
            }
        }

        return Array(
            latestPerDay.values
                .sorted { $0.date < $1.date }
                .suffix(14)
        )
    }

    private func nearestPoint(to date: Date?) -> StatPoint? {
        guard let date else { return nil }
        var data: [StatPoint] = []
        if stat == .elo{
            data = chartDataElo
        }else{
            data = chartData
        }

        return data.min {
            abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
        }
    }

    private func formattedValue(_ value: Double) -> String {
        if percentage {
            return "\(Int(value))%"
        } else if digits == 0 {
            return "\(Int(value))"
        } else {
            return String(format: "%.\(digits)f", value)
        }
    }
    
    private var yDomain: ClosedRange<Double> {
        guard let minV = points.map(\.value).min(),
              let maxV = points.map(\.value).max() else { return 0...1 }

        let padding = max((maxV - minV) * 0.15, 1)
        return (minV - padding)...(maxV + padding)
    }
    
    //The elo graph should not start at zero rather at the min Value all other grpahs start at zero
    private var yBaseline: Double { stat == .elo ? yDomain.lowerBound : 0 }
    
    private var minBarHeight: Double {
        let maxValue = points.map(\.value).max() ?? 0
        return maxValue / 100
    }

    private func plottedValue(_ value: Double) -> Double {
        max(value, yBaseline + minBarHeight)
    }
    

    var body: some View {
        if isLoading {
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                Spacer()
            }
        } else {
           
            Chart {

                if let selected = selection.selectedPoint {
                    RuleMark(x: .value("Date", selected.date))
                        //.offset(y:-5)
                        .foregroundStyle(Color.accentColor)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .annotation(
                            position: .top,
                            spacing: 10,
                            overflowResolution: .init(x: .fit(to: .chart), y: .disabled)
                        ) {
                            selectionBox(for: selected)
                        }
                    //Bar should be on top of Rulemark but doesnt seem to work
                        .zIndex(0)
                }
                    

                ForEach(points) { point in
                    let isHighlighted = selection.selectedPoint == nil || selection.selectedPoint?.id == point.id
                    //let labelOpacity: Double = selection.selectedPoint == nil ? 1 : (isHighlighted ? 1 : 0.5)

                    BarMark(
                        x: .value("Date", point.date),
                        yStart: .value("Baseline", yBaseline),
                        yEnd: .value("Value", plottedValue(point.value))
                    )
                    //ZIndex Part 2
                    .zIndex(1)
                    .foregroundStyle(
                        LinearGradient(
                            colors: isHighlighted
                                ? [Color.accentColor, Color.accentColor.opacity(0.8)]
                                : [Color.accentColor.opacity(0.3), Color.accentColor.opacity(0.25)],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    /*.annotation(position: .top) {
                        Text(formattedValue(point.value))
                        .font(.caption)
                        .opacity(labelOpacity)
                    }*/
                }
            }
            .chartBackground { proxy in
                GeometryReader { geo in
                    if let selected = selection.selectedPoint,
                       let plotFrame = proxy.plotFrame,          // iOS 17+; use proxy.plotAreaFrame on iOS 16
                       let x = proxy.position(forX: selected.date) {
                        let frame = geo[plotFrame]
                        let extra: CGFloat = 20                  // how far above the chart it extends

                        Rectangle()
                            .fill(Color.accentColor)
                            .frame(width: 2, height: frame.height + extra)
                            .position(x: frame.minX + x,
                                      y: frame.minY - extra / 2 + frame.height / 2)
                            .allowsHitTesting(false)
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .trailing)

                
                //MAKES SPACE TO THE LEFT FOR THE BOX TO CONNECT PROEPRY
                AxisMarks(position: .leading) { _ in
                    AxisValueLabel {
                        Color.clear.frame(width: 1, height: 1)
                    }
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: Date.FormatStyle(date: .numeric, time: .omitted))
                }
            }
            .chartYScale(domain: stat == .elo ? yDomain : 0...(points.map(\.value).max() ?? 1) * 1.15)
            .chartXSelection(value: $selection.selectedDate)
            .onChange(of: selection.selectedDate) { _, newDate in
                selection.selectedPoint = nearestPoint(to: newDate)
            }
            .onChange(of: points) { _, _ in
                selection.selectedPoint = nearestPoint(to: selection.selectedDate)
            }
        }
    }

    @ViewBuilder
    private func selectionBox(for point: StatPoint) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 12) {
                Text(timeFrametoString(timeframe: timeframe, elo: stat == .elo))
                    .font(.system(size: 16))
                    .foregroundStyle(Color.secondary)
                    .padding(.bottom, -15)
                Text(formattedValue(point.value))
                    .foregroundColor(colorScheme == .dark ? .black : .white)
                    .font(.system(size: 29))
                    .fontWeight(.bold)
                Text(selectedPointDateInterval)
                    .font(.system(size: 16))
                    .foregroundStyle(Color.secondary)
                    .padding(.top, -15)
            }
        }
        .frame(minWidth: 50)
        .padding(.vertical, 4)
        .padding(.horizontal, 5)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.accentColor)
                .shadow(radius: 2)
        )
    }
}

//MARK: - Sortby enum

enum sortBy: String, CaseIterable {
    case valueUp
    case valueDown
    case nameUp
    case nameDown
}
