//
//  SortMenuView.swift
//  MapPulse
//
//  Created by Rachit Prajapati on 4/25/25.
//

import SwiftUI

// State driven sort menu toggle
enum SortOption: String, CaseIterable {
    case none, altitude, driveStatus, speed
}

/*
 SortMenuView is a compact, glassmorphic reusable SwiftUI view that lets user pick a sort option and toggle visibility of hidden devices
    via bindings to parent state.
*/

struct SortMenuView: View {
    @Binding var sortOption: SortOption // two way binding with parent View
    @Binding var showHidden: Bool // two way binding for indicating hidden device option

    var body: some View {
        HStack {
            // Sort menu
            Menu {
                Picker("Sort by", selection: $sortOption) {
                    ForEach(SortOption.allCases, id: \.self) { opt in
                        Text(opt.rawValue.capitalized)
                            .tag(opt)
                    }
                }
                Divider()
                Toggle("Show Hidden", isOn: $showHidden)   // Hidden device option toogle
            } label: {
                // Icon
                Image(systemName: "arrow.up.arrow.down.circle")
                    .font(.title2)
                    .padding(8)
                    .tint(.white)
                    .background(.ultraThinMaterial, in:
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.white.opacity(0.25), lineWidth: 1)
                    )
            }
            .shadow(radius: 4)
            .padding(.horizontal)
            Spacer()
        }
    }
}

// Preview setup
#Preview {
    SortMenuView(sortOption: .constant(.none), showHidden: .constant(false))
}
