//
//  WorkOrdersView.swift
//  PulseFix
//
//  Created by Michael Hany on 24/09/2026.
//

import SwiftUI
import SwiftData

struct WorkOrdersView: View {
    @Query(sort: \StoredWorkOrder.createdAt, order: .reverse) private var orders: [StoredWorkOrder]
    var body: some View {
        List(orders) { order in
            VStack(alignment: .leading, spacing: 7) {
                HStack { Text(order.title).font(.headline); Spacer(); StatusPill(text: "decision.\(order.decision.rawValue)", color: order.decision == .rejected ? .red : .green) }
                Text(order.equipment).foregroundStyle(.secondary)
                Text(order.createdAt, style: .date).font(.caption)
                if !order.supervisorNote.isEmpty { Text(order.supervisorNote).font(.caption).italic() }
            }.padding(.vertical, 6)
        }
        .overlay { if orders.isEmpty { ContentUnavailableView("no_work_orders", systemImage: "wrench.and.screwdriver", description: Text("approval.edit")) } }
        .navigationTitle("tab.work_orders")
        .toolbar { AppToolbar() }
    }
}
