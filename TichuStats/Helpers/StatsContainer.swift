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
    var apiKey: String {
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
                    Text(timeFrametoString(timeframe: timeframe))
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

    @Bindable var selection: StatsSelection

    //Server should handle data
    private var chartData: [StatPoint] {
        (data[timeframe.apiKey] ?? [])
            .map { entry in
                let v = entry.getStat(for: stat)
                return StatPoint(date: entry.calculatedAt, value: percentage ? v * 100 : v)
            }
            .sorted { $0.date < $1.date }
    }

    private func nearestPoint(to date: Date?) -> StatPoint? {
        guard let date else { return nil }
        return chartData.min {
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
            let points = chartData

            Chart {

                if let selected = selection.selectedPoint {
                    RuleMark(x: .value("Date", selected.date))
                        .offset(y:-15)
                        .foregroundStyle(Color.accentColor)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .annotation(
                            position: .top,
                            spacing: -8,
                            overflowResolution: .init(x: .fit(to: .plot), y: .disabled)
                        ) {
                            selectionBox(for: selected)
                        }
                    //Bar should be on top of Rulemark but doesnt seem to work
                        .zIndex(0)
                }

                ForEach(points) { point in
                    let isHighlighted = selection.selectedPoint == nil || selection.selectedPoint?.id == point.id
                    let labelOpacity: Double = selection.selectedPoint == nil ? 1 : (isHighlighted ? 1 : 0.5)

                    BarMark(
                        x: .value("Date", point.date),
                        y: .value("Value", point.value)
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
                    .annotation(position: .top) {
                        Text(formattedValue(point.value))
                        .font(.caption)
                        .opacity(labelOpacity)
                    }
                }
            }
            .chartXAxis {
                let dayCount = max(points.count, 1)
                let strideCount = max(1, dayCount / 6)
                AxisMarks(values: .stride(by: .day, count: strideCount)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(date, format: .dateTime.day(.twoDigits).month(.twoDigits))
                        }
                    }
                }
            }

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
                Text(timeFrametoString(timeframe: timeframe))
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
