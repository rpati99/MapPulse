///
///  SearchBarView.swift
///  MapPulse
///
///  Created by Rachit Prajapati on 4/25/25.
///

import SwiftUI

/*
 Reusable Glassmorphic Search bar SwiftUI view
 */

struct SearchBarView: View {
    @Binding var searchText: String // Two way binding property between Search bar and main MapView for text
    @Binding var isSearchExpanded: Bool // Two way binding property between Search bar and main MapView for animation purpose
    @FocusState private var isSearchFocused: Bool // Focus property for text field once it expands (keyboard appearance)
    var onCommit: () -> Void // handler when parent view (MapView) needs to react on tapping "Search" button on keyboard

    var body: some View {
        HStack {
            ZStack(alignment: .leading) {
                // The pill background
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.thinMaterial)
                    .frame(height: 44)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                
                HStack(spacing: 8) {
                    Image(systemName: "car")
                        .foregroundColor(.white.opacity(0.9))
                    
                    // Always in the view hierarchy, but only visible when expanded
                    if isSearchExpanded {
                        TextField("Search drivers…", text: $searchText, onCommit: {
                            isSearchFocused = false
                            onCommit()
                        })
                        .keyboardType(.asciiCapable)
                        .autocorrectionDisabled()
                        .autocapitalization(.none)
                        .focused($isSearchFocused)
                        .submitLabel(.search)
                        .onSubmit { isSearchFocused = false }
                        .opacity(isSearchExpanded ? 1 : 0)
                        .frame(maxWidth: isSearchExpanded ? .infinity : 0)
                    }
                }
                .padding(.horizontal, 12)
            }
            // Animate the width from 44 → 300
            .frame(width: isSearchExpanded ? 300 : 44)
            .animation(
                .spring(response: 0.4, dampingFraction: 0.5),
                value: isSearchExpanded
            )
            .shadow(radius: 4)
            .onTapGesture {
                isSearchExpanded.toggle()
                if !isSearchExpanded {
                    // focus the field after the spring
                    DispatchQueue.main.async {
                        isSearchFocused = false
                        searchText = ""
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

#Preview {
    @Previewable @State var isSearchExpanded: Bool = false
    SearchBarView(
        searchText: .constant(""),
        isSearchExpanded: $isSearchExpanded ,
        onCommit: { isSearchExpanded.toggle()
        })
}
