//
//  OrientationHelper.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import SwiftUI

// MARK: - Orientation Environment Key
private struct OrientationKey: EnvironmentKey {
    static let defaultValue: UIDeviceOrientation = .portrait
}

extension EnvironmentValues {
    var orientation: UIDeviceOrientation {
        get { self[OrientationKey.self] }
        set { self[OrientationKey.self] = newValue }
    }
}

// MARK: - Orientation Reader View Modifier
struct OrientationReader: ViewModifier {
    @State private var orientation: UIDeviceOrientation = UIDevice.current.orientation
    
    func body(content: Content) -> some View {
        content
            .environment(\.orientation, orientation)
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                // Small delay to ensure orientation is updated
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    orientation = UIDevice.current.orientation
                }
            }
            .onAppear {
                orientation = UIDevice.current.orientation
            }
    }
}

extension View {
    func orientationReader() -> some View {
        modifier(OrientationReader())
    }
}

// MARK: - Size Class Helper
private struct IsLandscapeKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var isLandscape: Bool {
        get { self[IsLandscapeKey.self] }
        set { self[IsLandscapeKey.self] = newValue }
    }
}

// MARK: - Landscape Detector
struct LandscapeDetector: ViewModifier {
    @State private var isLandscape: Bool = false
    
    func body(content: Content) -> some View {
        content
            .environment(\.isLandscape, isLandscape)
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                updateOrientation()
            }
            .onAppear {
                updateOrientation()
            }
            .onChange(of: UIDevice.current.orientation) {
                updateOrientation()
            }
    }
    
    private func updateOrientation() {
        DispatchQueue.main.async {
            // Try window scene first (most reliable)
            if let windowScene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first {
                let newValue = windowScene.effectiveGeometry.interfaceOrientation.isLandscape
                if newValue != isLandscape {
                    isLandscape = newValue
                }
            } else {
                // Fallback to device orientation
                let orientation = UIDevice.current.orientation
                let newValue = orientation.isLandscape && orientation != .unknown
                if newValue != isLandscape {
                    isLandscape = newValue
                }
            }
        }
    }
}

extension View {
    func detectLandscape() -> some View {
        modifier(LandscapeDetector())
    }
}

// MARK: - Adaptive Layout Helper
struct AdaptiveLayout<Content: View>: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    let portraitContent: Content
    let landscapeContent: Content?
    
    init(@ViewBuilder content: () -> Content) {
        self.portraitContent = content()
        self.landscapeContent = nil
    }
    
    init(portrait: @escaping () -> Content, landscape: @escaping () -> Content) {
        self.portraitContent = portrait()
        self.landscapeContent = landscape()
    }
    
    var body: some View {
        if let landscapeContent = landscapeContent {
            Group {
                if horizontalSizeClass == .regular || verticalSizeClass == .compact {
                    landscapeContent
                } else {
                    portraitContent
                }
            }
        } else {
            portraitContent
        }
    }
}

// MARK: - Landscape Grid Helper
struct AdaptiveGrid<Content: View>: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    let columns: [GridItem]
    let landscapeColumns: [GridItem]?
    let content: Content
    
    init(columns: [GridItem], landscapeColumns: [GridItem]? = nil, @ViewBuilder content: () -> Content) {
        self.columns = columns
        self.landscapeColumns = landscapeColumns
        self.content = content()
    }
    
    var body: some View {
        LazyVGrid(columns: (horizontalSizeClass == .regular && landscapeColumns != nil) ? landscapeColumns! : columns, spacing: DesignSystem.Spacing.md) {
            content
        }
    }
}

