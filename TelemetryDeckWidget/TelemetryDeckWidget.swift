//
//  TelemetryDeckWidget.swift
//  TelemetryDeckWidget
//
//  Created by Charlotte Böhm on 05.10.21.
//

import WidgetKit
import SwiftUI
import Intents

struct Provider: IntentTimelineProvider {

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationIntent(), insightCalculationResult: .init(id: UUID.empty, insight: DTOsWithIdentifiers.Insight.init(id: UUID.empty, groupID: UUID.empty, title: "foo", uniqueUser: true, filters: [:], displayMode: .raw, isExpanded: false), data: [], calculatedAt: Date(), calculationDuration: 0))
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), configuration: configuration, insightCalculationResult: .init(id: UUID.empty, insight: DTOsWithIdentifiers.Insight.init(id: UUID.empty, groupID: UUID.empty, title: "foo", uniqueUser: true, filters: [:], displayMode: .raw, isExpanded: false), data: [], calculatedAt: Date(), calculationDuration: 0))
        completion(entry)
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, configuration: configuration, insightCalculationResult: .init(id: UUID.empty, insight: DTOsWithIdentifiers.Insight.init(id: UUID.empty, groupID: UUID.empty, title: "foo", uniqueUser: true, filters: [:], displayMode: .raw, isExpanded: false), data: [], calculatedAt: Date(), calculationDuration: 0))
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationIntent
    let insightCalculationResult: DTOsWithIdentifiers.InsightCalculationResult
}

struct TelemetryDeckWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        Text(entry.date, style: .time)
    }
}

@main
struct TelemetryDeckWidget: Widget {
    let kind: String = "TelemetryDeckWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            TelemetryDeckWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
    }
}

struct TelemetryDeckWidget_Previews: PreviewProvider {
    static var previews: some View {
        TelemetryDeckWidgetEntryView(entry: SimpleEntry(date: Date(), configuration: ConfigurationIntent(), insightCalculationResult: .init(id: UUID.empty, insight: DTOsWithIdentifiers.Insight.init(id: UUID.empty, groupID: UUID.empty, title: "foo", uniqueUser: true, filters: [:], displayMode: .raw, isExpanded: false), data: [], calculatedAt: Date(), calculationDuration: 0)))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}