//
//  KeyboardAdaptive.swift
//  MapPulse
//
//  Created by Rachit Prajapati on 4/26/25.
//

import SwiftUI
import UIKit

/// A ViewModifier that watches UIKit keyboard notifications
/// and adjusts bottom padding accordingly.
struct KeyboardAdaptive: ViewModifier {
    @State private var bottomPadding: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .padding(.bottom, bottomPadding)
            .onAppear {
                NotificationCenter.default.addObserver(
                    forName: UIResponder.keyboardWillShowNotification,
                    object: nil,
                    queue: .main
                ) { note in
                    guard let frame = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
                    bottomPadding = frame.height
                }
                NotificationCenter.default.addObserver(
                    forName: UIResponder.keyboardWillHideNotification,
                    object: nil,
                    queue: .main
                ) { _ in
                    bottomPadding = 0
                }
            }
            .onDisappear {
                NotificationCenter.default.removeObserver(
                    self,
                    name: UIResponder.keyboardWillShowNotification,
                    object: nil
                )
                NotificationCenter.default.removeObserver(
                    self,
                    name: UIResponder.keyboardWillHideNotification,
                    object: nil
                )
            }
    }
}

extension View {
    /// Convenience to apply our keyboard‐adaptive padding
    func keyboardAdaptive() -> some View {
        self.modifier(KeyboardAdaptive())
    }
}
