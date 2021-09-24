//
//  InsightsList.swift
//  Telemetry Viewer
//
//  Created by Daniel Jilg on 24.09.21.
//

import SwiftUI

struct InsightsList: View {
    let groupID: DTOsWithIdentifiers.Group.ID
    let isSelectable: Bool
    
    @Binding var selectedInsightID: DTOsWithIdentifiers.Insight.ID?
    @Binding var sidebarVisible: Bool
    @EnvironmentObject var groupService: GroupService
    
    var body: some View {
        Group {
            if let insightGroup = groupService.group(withID: groupID) {
                if !insightGroup.insightIDs.isEmpty {
                    InsightsGrid(selectedInsightID: $selectedInsightID, sidebarVisible: $sidebarVisible, insightGroup: insightGroup, showBottomPooper: true, isSelectable: isSelectable)
                } else {
                    EmptyInsightGroupView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }

            } else {
                loadingStateIndicator
            }
        }
        .padding(.vertical, spacing)
    }
    
    var loadingStateIndicator: some View {
        LoadingStateIndicator(loadingState: groupService.loadingState(for: groupID), title: groupService.group(withID: groupID)?.title)
    }
}