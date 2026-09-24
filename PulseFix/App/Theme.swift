//
//  Theme.swift
//  PulseFix
//
//  Created by Michael Hany on 23/09/2026.
//

import SwiftUI

enum PulseTheme {
    static let navy = Color(red: 0.03, green: 0.09, blue: 0.18)
    static let blue = Color(red: 0.08, green: 0.45, blue: 0.85)
    static let cyan = Color(red: 0.12, green: 0.78, blue: 0.88)
    static let gold = Color(red: 0.93, green: 0.66, blue: 0.22)
    static let background = Color(uiColor: .systemGroupedBackground)
}

struct PulseCard<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        content.padding(16).frame(maxWidth: .infinity, alignment: .leading)
            .background(.background, in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(.quaternary))
    }
}

struct StatusPill: View {
    let text: String; let color: Color
    var body: some View { Text(text).font(.caption.bold()).padding(.horizontal, 10).padding(.vertical, 5).foregroundStyle(color).background(color.opacity(0.12), in: Capsule()) }
}

