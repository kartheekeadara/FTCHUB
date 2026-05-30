//
//  ToastView.swift
//  FTCHUB
//
//  Created for Phase 6: Error Handling & User Feedback Improvements
//

import SwiftUI
import Combine

/// Toast notification types
enum ToastType {
    case success
    case error
    case warning
    case info
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .success: return DesignSystem.Colors.success
        case .error: return DesignSystem.Colors.error
        case .warning: return DesignSystem.Colors.warning
        case .info: return DesignSystem.Colors.primary
        }
    }
}

/// Toast notification model
struct Toast: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let type: ToastType
    let duration: TimeInterval
    
    init(_ message: String, type: ToastType = .info, duration: TimeInterval = 3.0) {
        self.message = message
        self.type = type
        self.duration = duration
    }
    
    static func == (lhs: Toast, rhs: Toast) -> Bool {
        lhs.id == rhs.id
    }
}

/// Toast manager for displaying toast notifications
@MainActor
class ToastManager: ObservableObject {
    /// At most one toast is visible at a time; additional messages queue (Phase 1 toast density cap).
    @Published private(set) var toasts: [Toast] = []
    
    private var pendingQueue: [Toast] = []
    private let maxQueued = 12
    
    func show(_ message: String, type: ToastType = .info, duration: TimeInterval = 3.0) {
        let toast = Toast(message, type: type, duration: duration)
        if toasts.isEmpty {
            withAnimation(DesignSystem.Motion.standard) {
                toasts = [toast]
            }
            scheduleAutoDismiss(for: toast)
        } else {
            guard pendingQueue.count < maxQueued else { return }
            pendingQueue.append(toast)
        }
    }
    
    private func scheduleAutoDismiss(for toast: Toast) {
        let id = toast.id
        let nanos = UInt64(toast.duration * 1_000_000_000)
        Task {
            try? await Task.sleep(nanoseconds: nanos)
            await MainActor.run {
                if toasts.count == 1, toasts.first?.id == id {
                    dismissToast(id: id)
                }
            }
        }
    }
    
    private func dismissToast(id: UUID) {
        withAnimation(DesignSystem.Motion.standard) {
            toasts.removeAll { $0.id == id }
        }
        promoteNextIfNeeded()
    }
    
    private func promoteNextIfNeeded() {
        guard toasts.isEmpty, !pendingQueue.isEmpty else { return }
        let next = pendingQueue.removeFirst()
        withAnimation(DesignSystem.Motion.standard) {
            toasts = [next]
        }
        scheduleAutoDismiss(for: next)
    }
    
    func showSuccess(_ message: String, duration: TimeInterval = 2.5) {
        DesignSystem.Haptics.notify(.success)
        show(message, type: .success, duration: duration)
    }
    
    func showError(_ message: String, duration: TimeInterval = 4.0) {
        DesignSystem.Haptics.notify(.error)
        show(message, type: .error, duration: duration)
    }
    
    func showWarning(_ message: String, duration: TimeInterval = 3.5) {
        DesignSystem.Haptics.notify(.warning)
        show(message, type: .warning, duration: duration)
    }
    
    func showInfo(_ message: String, duration: TimeInterval = 3.0) {
        show(message, type: .info, duration: duration)
    }
    
    func dismiss(_ toast: Toast) {
        dismissToast(id: toast.id)
    }
}

/// Toast container view that displays toasts
struct ToastContainer: View {
    @ObservedObject var toastManager: ToastManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(toastManager.toasts) { toast in
                ToastView(toast: toast) {
                    toastManager.dismiss(toast)
                }
                .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.top, DesignSystem.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .top)
        .animation(DesignSystem.Motion.standard, value: toastManager.toasts.count)
    }
}

/// Individual toast view
struct ToastView: View {
    let toast: Toast
    let onDismiss: () -> Void
    @State private var isVisible = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: toast.type.icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(toast.type.color)
            
            // Message
            Text(toast.message)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            // Dismiss button
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            .accessibilityLabel(Text("Dismiss notification"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .fill(DesignSystem.Colors.cardBackground)
                .shadow(color: DesignSystem.Colors.shadow, radius: 12, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .stroke(toast.type.color.opacity(0.3), lineWidth: 1)
        )
        .opacity(isVisible ? 1 : 0)
        .offset(y: reduceMotion ? 0 : (isVisible ? 0 : -20))
        .onAppear {
            if reduceMotion {
                isVisible = true
            } else {
                withAnimation(DesignSystem.Motion.standard) {
                    isVisible = true
                }
            }
        }
    }
}

/// View modifier to add toast support
struct ToastModifier: ViewModifier {
    @StateObject private var toastManager = ToastManager()
    
    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
            
            ToastContainer(toastManager: toastManager)
        }
        .environmentObject(toastManager)
    }
}

extension View {
    /// Add toast notification support to a view
    func withToast() -> some View {
        modifier(ToastModifier())
    }
}

