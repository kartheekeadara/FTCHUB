//
//  LegalDocumentView.swift
//  FTCHUB
//
//  Created by GPT-5 Codex on 11/8/25.
//

import SwiftUI
import WebKit

struct LegalDocumentView: View {
    let title: String
    let resourceName: String
    /// When `true`, show a trailing Done button that calls `dismiss()` (use in sheets without a nav back affordance).
    var showDismissToolbar: Bool = false

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if let remoteURL = Self.remoteURL(for: resourceName) {
                LegalRemoteDocumentView(
                    url: remoteURL,
                    fallbackResourceName: resourceName,
                    showDismissToolbar: showDismissToolbar
                )
            } else {
                LegalBundledDocumentView(
                    resourceName: resourceName,
                    showDismissToolbar: showDismissToolbar
                )
            }
        }
        .background(DesignSystem.Colors.background)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private static func remoteURL(for resourceName: String) -> URL? {
        switch resourceName {
        case "PrivacyPolicy":
            return Config.privacyPolicyURL
        default:
            return nil
        }
    }
}

// MARK: - Remote HTML (hosted policy)

private struct LegalRemoteDocumentView: View {
    let url: URL
    let fallbackResourceName: String
    var showDismissToolbar: Bool = false

    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = true
    @State private var loadError: String?
    @State private var useBundledFallback = false

    var body: some View {
        Group {
            if useBundledFallback {
                LegalBundledDocumentView(
                    resourceName: fallbackResourceName,
                    showDismissToolbar: showDismissToolbar
                )
            } else if let loadError {
                remoteErrorView(message: loadError)
            } else {
                ZStack {
                    LegalWebView(url: url, isLoading: $isLoading, loadError: $loadError)
                    if isLoading {
                        ProgressView()
                            .scaleEffect(1.1)
                    }
                }
            }
        }
        .tabBarScrollInset()
        .toolbar {
            if showDismissToolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(DesignSystem.Colors.primary)
                }
            }
            if !useBundledFallback, loadError == nil {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Link(destination: url) {
                        Image(systemName: "safari")
                    }
                    .accessibilityLabel("Open in Safari")
                }
            }
        }
    }

    @ViewBuilder
    private func remoteErrorView(message: String) -> some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                Image(systemName: "wifi.exclamationmark")
                    .font(.system(size: 48))
                    .foregroundColor(DesignSystem.Colors.warning)

                Text("Unable to load privacy policy")
                    .font(.headline)

                Text(message)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(DesignSystem.Colors.textSecondary)

                Button("Try Again") {
                    loadError = nil
                    isLoading = true
                }
                .primaryButtonStyle()

                Link("Open in Browser", destination: url)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(DesignSystem.Colors.primary)

                Button("View Offline Copy") {
                    useBundledFallback = true
                }
                .font(.subheadline)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            .padding(DesignSystem.Spacing.xl)
        }
    }
}

private struct LegalWebView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    @Binding var loadError: String?

    func makeCoordinator() -> Coordinator {
        Coordinator(isLoading: $isLoading, loadError: $loadError)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        context.coordinator.load(url: url, in: webView)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if context.coordinator.lastLoadedURL != url {
            context.coordinator.load(url: url, in: webView)
        }
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        @Binding var isLoading: Bool
        @Binding var loadError: String?
        var lastLoadedURL: URL?

        init(isLoading: Binding<Bool>, loadError: Binding<String?>) {
            _isLoading = isLoading
            _loadError = loadError
        }

        func load(url: URL, in webView: WKWebView) {
            lastLoadedURL = url
            loadError = nil
            isLoading = true
            webView.load(URLRequest(url: url))
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isLoading = false
            loadError = nil
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            isLoading = false
            loadError = error.localizedDescription
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            isLoading = false
            loadError = error.localizedDescription
        }
    }
}

// MARK: - Bundled markdown

private struct LegalBundledDocumentView: View {
    let resourceName: String
    var showDismissToolbar: Bool = false

    @Environment(\.dismiss) private var dismiss
    @State private var documentText: AttributedString = AttributedString("Loading…")
    @State private var loadingError: String?

    var body: some View {
        ScrollView {
            if let error = loadingError {
                VStack(spacing: DesignSystem.Spacing.md) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(DesignSystem.Colors.error)
                    Text("Unable to load document.")
                        .font(.headline)
                    Text(error)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                .padding()
            } else {
                Text(documentText)
                    .font(.body)
                    .lineSpacing(8)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.vertical, DesignSystem.Spacing.xl)
                    .padding(.bottom, DesignSystem.Spacing.xxl)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .tabBarScrollInset()
        .toolbar {
            if showDismissToolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(DesignSystem.Colors.primary)
                }
            }
        }
        .task {
            await loadDocument()
        }
        .refreshable {
            await loadDocument()
        }
    }

    private static func normalizedMarkdown(_ raw: String) -> String {
        var t = raw.replacingOccurrences(of: "\r\n", with: "\n")
        t = t.replacingOccurrences(of: ".##", with: ".\n\n##")
        t = t.replacingOccurrences(of: "\n##", with: "\n\n##")
        while t.contains("\n\n\n") {
            t = t.replacingOccurrences(of: "\n\n\n", with: "\n\n")
        }
        return t.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func loadDocument() async {
        do {
            let text: String
            if let url = Bundle.main.url(forResource: resourceName, withExtension: "md", subdirectory: "Legal") {
                text = try String(contentsOf: url, encoding: .utf8)
            } else if let fallback = LegalDocumentLibrary.fallbackText(for: resourceName) {
                text = fallback
                await MainActor.run {
                    TelemetryService.shared.logEvent("legal_document_fallback", parameters: ["resource": resourceName])
                }
            } else {
                throw NSError(domain: "LegalDocument", code: 404, userInfo: [NSLocalizedDescriptionKey: "Document not found in bundle."])
            }
            let normalized = Self.normalizedMarkdown(text)
            if let attributed = try? AttributedString(markdown: normalized) {
                await MainActor.run {
                    documentText = attributed
                    loadingError = nil
                }
            } else {
                await MainActor.run {
                    documentText = AttributedString(normalized)
                    loadingError = nil
                }
            }
        } catch {
            await MainActor.run {
                loadingError = error.localizedDescription
            }
        }
    }
}

#if DEBUG
struct LegalDocumentView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            LegalDocumentView(title: "Privacy Policy", resourceName: "PrivacyPolicy")
        }
    }
}
#endif

private enum LegalDocumentLibrary {
    static func fallbackText(for resourceName: String) -> String? {
        switch resourceName {
        case "PrivacyPolicy":
            return """
# FTC HUB Privacy Policy

_Last updated: November 27, 2025_

FTC HUB is a team management application for FIRST Tech Challenge teams. Visit https://uninetx.github.io/Email-Verification/privacy-policy for the full policy when online.

## Contact Us

Email: kartheek.eadara@gmail.com
"""
        case "TermsOfService":
            return """
# FTC HUB Terms of Service

_Last updated: November 8, 2025_

By installing or using FTC HUB ("the App"), you agree to these Terms.

## 1. Eligibility

You must be at least 13 years old to use this App. Team mentors are responsible for inviting and managing members and ensuring compliance with applicable regulations.

## 2. License

We grant you a non-exclusive, non-transferable license to use the App for FTC team management. You may not reverse engineer, resell, or misuse the App.

## 3. User Content

You retain ownership of the data you enter (match schedules, scouting reports, inventory, etc.). You grant us a limited license to store and process that data to operate the service.

You are responsible for obtaining any necessary permissions from team members, guardians, or schools before storing personal information.

## 4. Acceptable Use

You agree not to:

- Upload malicious code or attempt to breach security.
- Share offensive, discriminatory, or unlawful content.
- Misrepresent your identity or affiliation.

We reserve the right to suspend or terminate accounts that violate these terms.

## 5. Data & Privacy

See the FTC HUB Privacy Policy for details on data collection and use. By using the App, you consent to that policy.

## 6. Third-Party Services

The App integrates with Supabase for authentication, database, and file storage. Your use of those services is subject to their respective terms.

## 7. Updates & Availability

We may release updates that change or remove features. We strive for high availability but do not guarantee uninterrupted access.

## 8. Disclaimer & Limitation of Liability

The App is provided “as is.” We disclaim all warranties, express or implied. We are not liable for indirect, incidental, or consequential damages arising from your use of the App.

Some jurisdictions do not allow certain disclaimers; in such cases, our liability is limited to the maximum extent permitted by law.

## 9. Indemnification

You agree to indemnify and hold us harmless from claims arising out of your misuse of the App or violation of these Terms.

## 10. Governing Law

These Terms are governed by the laws of the State of California, USA, without regard to conflict of law principles.

## 11. Changes to Terms

We may update these Terms and will post the latest version in the App. Continued use constitutes acceptance of the revised Terms.

## 12. Contact

Email: kartheek.eadara@gmail.com  
Mail: 11636 Elizabeth Madison Court, Charlotte, NC 28277, USA
"""
        case "SupportGuide":
            return """
# FTC HUB Support Guide

Need help? Choose any of the options below.

## Self-Service Resources
- **Help Center:** Tutorials, FAQs, and troubleshooting guides.  
  URL: https://uninetx.github.io/Email-Verification/support
- **Release Notes:** What’s new in each version.  
  URL: https://ftchub.app/releases

## Contact Support
- **Email:** kartheek.eadara@gmail.com  
  Expect a response within around a week.

## When Contacting Support
Please include:
1. App version (Settings → About).
2. Device model and iOS version.
3. Steps to reproduce the issue and screenshots if possible.

## Data & Privacy Requests
To request data export or deletion, email kartheek.eadara@gmail.com with "Privacy Request" in the subject line. We will respond within 30 days.
"""
        default:
            return nil
        }
    }
}
