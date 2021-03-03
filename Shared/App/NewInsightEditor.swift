//
//  NewInsightEditor.swift
//  Telemetry Viewer
//
//  Created by Daniel Jilg on 17.02.21.
//

import SwiftUI

struct NewInsightEditorContent {
    var order: Double
    var title: String

    /// Which signal types are we interested in? If empty, do not filter by signal type
    var signalType: String

    /// If true, only include at the newest signal from each user
    var uniqueUser: Bool

    /// Only include signals that match all of these key-values in the payload
    var filters: [String: String]

    /// How far to go back to aggregate signals
    var rollingWindowSize: TimeInterval

    /// If set, break down the values in this key
    var breakdownKey: String

    /// If set, group and count found signals by this time interval. Incompatible with breakdownKey
    var groupBy: InsightGroupByInterval

    /// How should this insight's data be displayed?
    var displayMode: InsightDisplayMode

    /// Which group should the insight belong to? (Only use this in update mode)
    var groupID: UUID

    /// The ID of the insight
    var id: UUID

    /// If true, the insight will be displayed bigger
    var isExpanded: Bool

    static func from(insight: Insight) -> NewInsightEditorContent {
        let requestBody = Self(
            order: insight.order ?? -1,
            title: insight.title,
            signalType: insight.signalType ?? "",
            uniqueUser: insight.uniqueUser,
            filters: insight.filters,
            rollingWindowSize: insight.rollingWindowSize,
            breakdownKey: insight.breakdownKey ?? "",
            groupBy: insight.groupBy ?? .day,
            displayMode: insight.displayMode,
            groupID: insight.group["id"]!,
            id: insight.id,
            isExpanded: insight.isExpanded
        )

        return requestBody
    }

    func insightDefinitionRequestBody() -> InsightDefinitionRequestBody {
        return InsightDefinitionRequestBody(
            order: self.order, title: self.title,
            subtitle: nil,
            signalType: self.signalType.isEmpty ? nil : self.signalType,
            uniqueUser: self.uniqueUser,
            filters: self.filters,
            rollingWindowSize: self.rollingWindowSize,
            breakdownKey: self.breakdownKey.isEmpty ? nil : self.breakdownKey,
            groupBy: self.breakdownKey.isEmpty ? self.groupBy : nil,
            displayMode: self.displayMode,
            groupID: self.groupID, id: self.id, isExpanded: self.isExpanded
        )
    }
}

struct NewInsightEditor: View {
    @Environment(\.presentationMode) var presentation
    @EnvironmentObject var api: APIRepresentative
    let app: TelemetryApp
    let insightGroup: InsightGroup
    let insight: Insight

    @State var insightDRB: NewInsightEditorContent

    init(app: TelemetryApp, insightGroup: InsightGroup, insight: Insight) {
        self.app = app
        self.insightGroup = insightGroup
        self.insight = insight
        self._insightDRB = State(initialValue: NewInsightEditorContent.from(insight: insight))
    }

    func save() {
        self.api.update(insight: self.insight, in: self.insightGroup, in: self.app, with: self.insightDRB.insightDefinitionRequestBody())
    }

    func updatePayloadKeys() {
        self.api.getPayloadKeys(for: self.app)
        self.api.getSignalTypes(for: self.app)
    }

    var chartTypeExplanationText: String {
        switch self.insightDRB.displayMode {
        case .number:
            return "Currently, 'Number' is the selected Chart Type. This chart type is no longer supported, and you should choose the 'Raw' instead."
        case .raw:
            return "Displays the insight's data directly as numbers."
        case .barChart:
            return "Displays a bar chart for the insight's data."
        case .lineChart:
            return "Displays a line chart for the insight's data."
        case .pieChart:
            return "Displays a pie chart for the insight's data. This is especially helpful in combination with the 'breakdown' function."
        }
    }

    var chartImage: Image {
        switch self.insightDRB.displayMode {
        case .raw:
            return Image(systemName: "number.square.fill")
        case .barChart:
            return Image(systemName: "chart.bar.fill")
        case .lineChart:
            return Image(systemName: "squares.below.rectangle")
        case .pieChart:
            return Image(systemName: "chart.pie.fill")
        default:
            return Image("omsn")
        }
    }

    var filterAutocompletionOptions: [String] {
        return self.api.lexiconPayloadKeys[self.app, default: []].filter { !$0.isHidden }.map(\.payloadKey)
    }

    var signalTypeAutocompletionOptions: [String] {
        return self.api.lexiconSignalTypes[self.app, default: []].map(\.type)
    }

    var body: some View {
        let form = Form {
            CustomSection(header: Text("Name"), summary: Text(insight.title), footer: Text("The Title of This Insight")) {
                TextField("Title e.g. 'Daily Active Users'", text: $insightDRB.title, onEditingChanged: { _ in save() }, onCommit: { save() })

                Toggle(isOn: $insightDRB.isExpanded, label: {
                    Text("Show Expanded")
                })
                .onChange(of: insightDRB.isExpanded) { _ in save() }
            }

            CustomSection(header: Text("Chart Type"), summary: chartImage, footer: Text(chartTypeExplanationText), startCollapsed: true) {
                Picker(selection: $insightDRB.displayMode, label: Text("")) {
                    Image(systemName: "number.square.fill").tag(InsightDisplayMode.raw)
                    Image(systemName: "chart.bar.fill").tag(InsightDisplayMode.barChart)
                    Image(systemName: "squares.below.rectangle").tag(InsightDisplayMode.lineChart)
                    Image(systemName: "chart.pie.fill").tag(InsightDisplayMode.pieChart)
                }
                .onChange(of: insightDRB.displayMode) { _ in save() }
                .pickerStyle(SegmentedPickerStyle())
            }

            CustomSection(header: Text("Group Values by"), summary: Text(insightDRB.groupBy.rawValue), footer: Text("Group signals by time interval. The more fine-grained the grouping, the more separate values you'll receive."), startCollapsed: true) {
                Picker(selection: $insightDRB.groupBy, label: Text("")) {
                    Text("Hour").tag(InsightGroupByInterval.hour)
                    Text("Day").tag(InsightGroupByInterval.day)
                    Text("Week").tag(InsightGroupByInterval.week)
                    Text("Month").tag(InsightGroupByInterval.month)
                }
                .onChange(of: insightDRB.groupBy) { _ in save() }
                .pickerStyle(SegmentedPickerStyle())
            }

            let signalText = insightDRB.signalType.isEmpty ? "All Signals" : insightDRB.signalType
            let uniqueText = insightDRB.uniqueUser ? ", unique" : ""

            CustomSection(header: Text("Signal Type"), summary: Text(signalText + uniqueText), footer: Text("What signal type are you interested in (e.g. appLaunchedRegularly)? Leave blank for any"), startCollapsed: true) {
                AutoCompletingTextField(
                    title: "All Signals",
                    text: $insightDRB.signalType,
                    autocompletionOptions: signalTypeAutocompletionOptions,
                    onEditingChanged: { save() }
                )

                Toggle(isOn: $insightDRB.uniqueUser) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Unique by User")
                            Text("Check to count each user only once")
                                .font(.footnote)
                                .foregroundColor(.grayColor)
                        }
                        Spacer()
                    }
                }
                .onChange(of: insightDRB.uniqueUser) { _ in save() }
            }

            CustomSection(header: Text("Breakdown"), summary: Text(insightDRB.breakdownKey.isEmpty ? "No Breakdown" : insightDRB.breakdownKey), footer: Text("If you enter a key for the metadata payload here, you'll get a breakdown of its values."), startCollapsed: true) {
                AutoCompletingTextField(
                    title: "Payload Key",
                    text: $insightDRB.breakdownKey,
                    autocompletionOptions: filterAutocompletionOptions,
                    onEditingChanged: { save() }
                )
            }

            CustomSection(header: Text("Ordering"), summary: Text(String(format: "%.0f", insightDRB.order)), footer: Text("Insights are ordered by this number, ascending"), startCollapsed: true) {
                OrderSetter(order: $insightDRB.order)
                    .onChange(of: insightDRB.order) { _ in save() }
            }

//            CustomSection(header: Text("Insight Group"), summary: Text(insightDRB.insightGroup?.title ?? "..."), footer: Text("All insights belong to an insight group."), startCollapsed: true) {
//                Picker(selection: $.selectedInsightGroupIndex, label: EmptyView()) {
//                    ForEach(0 ..< viewModel.allInsightGroups.count) {
//                        Text(viewModel.allInsightGroups[$0].title)
//                    }
//                }
//                .pickerStyle(DefaultPickerStyle())
//            }

            CustomSection(header: Text("Meta Information"), summary: EmptyView(), footer: EmptyView(), startCollapsed: true) {
                if let dto = api.insightData[insight.id] {
                    Group {
                        Text("This Insight was last updated ")
                            + Text(dto.calculatedAt, style: .relative).bold()
                            + Text(" ago. The server needed ")
                            + Text("\(dto.calculationDuration) seconds").bold()
                            + Text(" to calculate it.")
                    }
                    .opacity(0.4)
                    .padding(.vertical, 2)

                    Group {
                        Text("The Insight will automatically be updated once it's ")
                            + Text("5 Minutes").bold()
                            + Text(" old.")
                    }
                    .opacity(0.4)
                    .padding(.bottom, 4)
                }

                if insight.shouldUseDruid {
                    Text("This Insight's data is calculated using Druid 🧙‍♂️")
                        .bold()
                        .opacity(0.4)
                        .padding(.bottom, 4)
                }

                Button("Copy Insight ID") {
                    saveToClipBoard(insight.id.uuidString)
                }
                .buttonStyle(SmallSecondaryButtonStyle())
            }

            CustomSection(header: Text("Delete"), summary: EmptyView(), footer: EmptyView(), startCollapsed: true) {
                Button("Delete this Insight", action: {
                    api.delete(insight: insight, in: insightGroup, in: app) { _ in
                        self.presentation.wrappedValue.dismiss()
                    }
                })
                    .buttonStyle(SmallSecondaryButtonStyle())
                    .accentColor(.red)
            }
        }
        .navigationTitle("Edit Insight")
        .onAppear { updatePayloadKeys() }

        #if os(macOS)
        ScrollView {
            form.padding()
        }
        #else
        form
        #endif
    }
}