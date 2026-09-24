//
//  RootView.swift
//  PulseFix
//
//  Created by Michael Hany on 23/09/2026.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct RootView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.modelContext) private var context
    @State private var importedOnce = false

    var body: some View {
        @Bindable var app = app
        TabView(selection: $app.selectedTab) {
            NavigationStack { ManualLibraryView() }.tabItem { Label("Manuals", systemImage: "books.vertical") }.tag(AppModel.Tab.manuals)
            NavigationStack { DiagnosisWorkspaceView() }.tabItem { Label("Diagnose", systemImage: "waveform.path.ecg") }.tag(AppModel.Tab.diagnose)
            NavigationStack { WorkOrdersView() }.tabItem { Label("Work Orders", systemImage: "wrench.and.screwdriver") }.tag(AppModel.Tab.orders)
            NavigationStack { TraceInspectorView() }.tabItem { Label("Trace", systemImage: "point.3.connected.trianglepath.dotted") }.tag(AppModel.Tab.trace)
        }
        .tint(PulseTheme.blue)
        .task {
            guard !importedOnce else { return }; importedOnce = true
            do { try app.restore(from: context); await app.loadSeedManuals(context: context) }
            catch { app.errorMessage = error.localizedDescription }
        }
        .alert("Error", isPresented: Binding(get: { app.errorMessage != nil }, set: { if !$0 { app.errorMessage = nil } })) {
            Button("OK") { app.errorMessage = nil }
        } message: { Text(app.errorMessage ?? "") }
    }
}

struct AppToolbar: ToolbarContent {
    @Environment(AppModel.self) private var app
    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                ForEach(AppLanguage.allCases) { language in Button(language.title) { app.language = language } }
            } label: { Label(app.language.title, systemImage: "globe") }
        }
    }
}
