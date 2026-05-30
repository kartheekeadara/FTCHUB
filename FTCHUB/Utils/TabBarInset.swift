//
//  TabBarInset.swift
//  FTCHUB
//
//  Provides a consistent bottom scroll inset so content never renders
//  behind the tab bar. Use .tabBarScrollInset() on any ScrollView or List.
//

import SwiftUI

extension View {
    /// Adds a transparent bottom safe-area inset that accounts for the tab bar.
    /// Use this on every scroll view / list that sits inside a tab view.
    func tabBarScrollInset() -> some View {
        self.safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear.frame(height: 8)
        }
    }
}
