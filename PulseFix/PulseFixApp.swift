//
//  PulseFixApp.swift
//  PulseFix
//
//  Created by Michael Hany on 19/09/2026.
//

import SwiftUI
import SwiftData

@main
struct PulseFixApp: App {
    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appModel)
                .environment(\.locale, appModel.locale)
                .environment(\.layoutDirection, appModel.language == .arabic ? .rightToLeft : .leftToRight)
        }
        .modelContainer(for: [StoredManual.self, StoredChunk.self, StoredWorkOrder.self])
    }
}

