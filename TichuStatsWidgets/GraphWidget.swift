    //
    //  GraphWidget.swift
    //  TichuStatsWidgets
    //
    //  Created by Leon on 03.06.2026.
    //

    import WidgetKit
    import SwiftUI
    import Charts

    // MARK: - Shared model (must match your app's EloEntry, make it Codable)
    struct EloEntry: Codable, Identifiable {
        let id: Int?
        let eloChange: Double
        let changedAt: Date?
        let gameId: Int?
    }

    struct EloPoint: Identifiable {
        let id = UUID()
        let date: Date
        let elo: Double
    }

    // MARK: - Timeline Entry
    struct EloWidgetEntry: TimelineEntry {
        let date: Date
        let points: [EloPoint]
        let currentElo: Double
    }

    // MARK: - Helpers
    private func userName() -> String {
        UserDefaults(suiteName: "group.com.drakynem.tichu")?.string(forKey: "userName") ?? String(localized:"general.unknown")
    }

    private func userElo() -> Double {
        UserDefaults(suiteName: "group.com.drakynem.tichu")?.double(forKey: "userElo") ?? 1000
    }

    // MARK: - Provider
    struct EloProvider: TimelineProvider {
        func placeholder(in context: Context) -> EloWidgetEntry {
            EloWidgetEntry(date: Date(), points: samplePoints(), currentElo: 1000)
        }

        func getSnapshot(in context: Context, completion: @escaping (EloWidgetEntry) -> Void) {
            completion(entry())
        }

        func getTimeline(in context: Context, completion: @escaping (Timeline<EloWidgetEntry>) -> Void) {
            let e = entry()
            // Refresh every hour
            let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
            completion(Timeline(entries: [e], policy: .after(next)))
        }
        
        private func userName() -> String {
            return UserDefaults(suiteName: "group.com.drakynem.tichu")?.string(forKey: "userName") ?? String(localized: "general.unknown")
        }
        
        private func userElo() -> Double {
            return UserDefaults(suiteName: "group.com.drakynem.tichu")?.double(forKey: "userElo") ?? 1000
        }

        private func entry() -> EloWidgetEntry {
            let defaults = UserDefaults(suiteName: "group.com.drakynem.tichu")
            var points: [EloPoint] = []
            let baseElo: Double = 1000
            var currentElo: Double = baseElo

            if let data = defaults?.data(forKey: "eloHistory"),
               let entries = try? JSONDecoder().decode([EloEntry].self, from: data),
               !entries.isEmpty {

                let sorted = entries.sorted(by: { ($0.changedAt ?? .distantPast) < ($1.changedAt ?? .distantPast) })

                for e in sorted {
                    currentElo += e.eloChange
                    if let date = e.changedAt {
                        points.append(EloPoint(date: date, elo: currentElo))
                    }
                }
            }

            if points.isEmpty {
                points = samplePoints()
                currentElo = points.last?.elo ?? baseElo
            }

            let storedElo = defaults?.double(forKey: "userElo") ?? 1016
            let displayElo = storedElo == 0 ? currentElo : storedElo

            return EloWidgetEntry(date: Date(), points: points, currentElo: displayElo)
        }

        private func samplePoints() -> [EloPoint] {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

            let raw: [(String, Double)] = [
                ("2026-06-02 12:54:45", 0),
                ("2026-06-03 12:54:45", -7.96),
                ("2026-06-08 12:35:58",  8.53),
                ("2026-06-09 19:47:41",  7.5),
                ("2026-06-12 14:16:00",  4.22),
                ("2026-06-20 00:24:12",  0.0),
                ("2026-06-22 00:30:43",  4.1)
            ]

            var elo: Double = 1000

            return raw.compactMap { dateString, change in
                guard let date = formatter.date(from: dateString) else { return nil }
                elo += change
                return EloPoint(date: date, elo: elo)
            }
        }
    }

    // MARK: - Widget View
    struct EloWidgetView: View {
        var entry: EloWidgetEntry
        var userName: String
        var userElo: Double
        @Environment(\.widgetFamily) var family
        @Environment(\.colorScheme) var colorScheme

        
        
        private var yDomain: ClosedRange<Double> {
            let values = entry.points.map { $0.elo }
            guard let minVal = values.min(), let maxVal = values.max() else { return 900...1100 }
            let padding = max((maxVal - minVal) * 0.15, 20)
            return (minVal - padding)...(maxVal + padding)
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    if family != .systemSmall {
                        Text(String(format:String(localized:"elo.rating"), userName))
                            .font(.headline)
                            .bold()
                    }else{
                        Text(String(localized:"elo.elo"))
                        
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(Int(userElo))")
                        .font(.headline)
                        .bold()
                }
                ZStack{
                Chart(entry.points) { point in
                    
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Elo", point.elo)
                    )
                    .interpolationMethod(.monotone)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    .foregroundStyle(.accent)
                    
                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Elo", point.elo)
                    )
                    .symbolSize(40)
                    .foregroundStyle(.accent)
                }
                .opacity(entry.points.count <= 1 ? 0 : 1)
                .chartYScale(domain: yDomain)
                
                .chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisGridLine()
                        AxisTick()
                        
                        if family != .systemSmall {
                            AxisValueLabel(format: .dateTime.day().month())
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisTick()
                        
                        if let elo = value.as(Double.self) {
                            
                            if family == .systemSmall {
                                let lastTwo = Int(elo) % 100
                                AxisValueLabel(String(format: "%02d", lastTwo)).foregroundStyle(colorScheme == .dark ? Color.white : Color.black)
                            } else {
                                AxisValueLabel("\(Int(elo))").foregroundStyle(colorScheme == .dark ? Color.white : Color.black)
                            }
                        }
                    }
                }
                    if entry.points.count <= 1{
                        Text(String(localized:"elo.willAppear")).foregroundStyle(.secondary)
                    }
            }
                
                
            }

            .containerBackground(.fill.tertiary, for: .widget)
            .widgetURL(URL(string: "tichu://elo")!)
        }
    }

    // MARK: - Widget
    struct GraphWidget: Widget {
        let kind: String = "GraphWidgets"

        var body: some WidgetConfiguration {
            StaticConfiguration(kind: kind, provider: EloProvider()) { entry in
                EloWidgetView(entry: entry,userName: userName(), userElo: userElo())
            }
            .configurationDisplayName(String(localized:"elo.widgetTitle"))
            .description(String(localized:"elo.widgetDescription"))
            .supportedFamilies([.systemSmall, .systemMedium,.systemLarge,.systemExtraLarge])
        }
    }

    // MARK: - Preview
    #Preview(as: .systemMedium) {
        GraphWidget()
    } timeline: {
        EloWidgetEntry(
            date: .now,
            points: (0..<8).map { i in
                EloPoint(
                    date: Calendar.current.date(byAdding: .day, value: -7 + i, to: .now)!,
                    elo: 1000 + Double(i * 12)
                )
            },
            currentElo: 1084
        )
    }

