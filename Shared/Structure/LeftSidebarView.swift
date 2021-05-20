//
//  LeftSidebarView.swift
//  Telemetry Viewer
//
//  Created by Daniel Jilg on 17.02.21.
//

import SwiftUI

enum LeftSidebarViewSelection {
    case gettingStarted
    case insights
    case lexicon
    case recentSignals
    case appSettings
    case helpAndFeedback
}

struct LeftSidebarView: View {
    @EnvironmentObject var api: APIRepresentative
    @EnvironmentObject var appService: AppService
    @State var selection: LeftSidebarViewSelection? = .insights

    #if os(macOS)
        @EnvironmentObject var updateService: UpateService
    #endif

    var body: some View {
        List {
            if appService.getTelemetryApps().isEmpty {
                Text("Hint: Click the + Button")
                    .font(.footnote)

                NavigationLink(destination: AppInfoView()) {
                    Label("Get Started", systemImage: "mustache.fill")
                }
            }

            if let app = appService.getSelectedApp() {
                Section(header: Text("App")) {
                    Picker(selection: $appService.selectedAppID, label: EmptyView()) {
                        ForEach(appService.getTelemetryApps()) { app in
                            Text(app.name).tag(app.id as UUID?)
                        }
                    }
                }

                Section(header: Text(app.name)) {
                    NavigationLink(
                        destination: AppRootView(appID: app.id),
                        tag: LeftSidebarViewSelection.insights,
                        selection: $selection,
                        label: {
                            Label("Insights", systemImage: "app")
                        }
                    )

                    NavigationLink(
                        destination: LexiconView(appID: app.id),
                        tag: LeftSidebarViewSelection.lexicon,
                        selection: $selection,
                        label: {
                            Label("Lexicon", systemImage: "book")
                        }
                    )
                    NavigationLink(
                        destination: SignalList(appID: app.id),
                        tag: LeftSidebarViewSelection.recentSignals,
                        selection: $selection,
                        label: {
                            Label("Recent Signals", systemImage: "waveform")
                        }
                    )

                    NavigationLink(
                        destination: AppEditor(appID: app.id),
                        tag: LeftSidebarViewSelection.appSettings,
                        selection: $selection,
                        label: {
                            Label("App Settings", systemImage: "gear")
                        }
                    )
                }
            }

            Section(header: Text("Meta")) {
                #if os(iOS)
                    NavigationLink(destination: OrganizationSettingsView(), label: {
                        Label(api.user?.organization?.name ?? "Organization Settings", systemImage: "app.badge")
                    })

                    NavigationLink(
                        destination: UserSettingsView(),
                        label: {
                            Label("\(api.user?.firstName ?? "User") \(api.user?.lastName ?? "Settings")", systemImage: "gear")
                        }
                    )
                #endif

                NavigationLink(
                    destination: FeedbackView(),
                    label: {
                        Label("Help & Feedback", systemImage: "ladybug.fill")
                    }
                )
            }

            if api.user?.organization?.isSuperOrg == true {
                Section(header: Text("Administration")) {
                    NavigationLink(
                        destination: AppAdminView(),
                        label: {
                            Label("Apps", systemImage: "app.badge")
                        }
                    )

                    NavigationLink(
                        destination: InsightQueryAdmin(),
                        label: {
                            Label("Insights", systemImage: "app.badge")
                        }
                    )
                }
            }
        }
        .onAppear {
            #if os(macOS)
                setupSidebars()
            #endif
        }
        .sheet(isPresented: $api.needsDecisionForMarketingEmails, content: {
            AskForMarketingEmailsView()
        })
        .listStyle(SidebarListStyle())
        .modify {
            #if os(macOS)
                $0.sheet(isPresented: $updateService.shouldShowUpdateNowScreen) {
                    AppUpdateView()
                }
            #else
                $0
            #endif
        }
        .navigationTitle("AppTelemetry")
        .toolbar {
            ToolbarItemGroup {
                #if os(macOS)
                    Button(action: toggleSidebar) {
                        Image(systemName: "sidebar.left")
                            .help("Toggle Sidebar")
                    }
                    .help("Toggle the left sidebar")

                    Spacer()
                #endif

                Button(action: {
                    appService.create(appNamed: "New App") { result in
                        switch result {
                        case .failure(let error):
                            print(error)
                        case .success(let newApp):
                            appService.selectedAppID = newApp.id
                            selection = .appSettings
                        }
                    }
                }) {
                    Label("New App", systemImage: "plus.app.fill")
                }
                .help("Create a New App")
            }
        }
    }

    #if os(macOS)
        private func toggleSidebar() {
            NSApp.keyWindow?.firstResponder?
                .tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
        }
    #endif
}
