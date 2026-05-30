//
//  GoogleSignInHelper.swift
//  FTCHUB
//

import Foundation
#if canImport(UIKit)
import UIKit
import GoogleSignIn
#endif

enum GoogleSignInHelper {
    struct Credentials: Sendable {
        let idToken: String
        let accessToken: String
    }

    enum Error: LocalizedError {
        case missingClientID
        case missingWebClientID
        case missingIDToken
        case cancelled

        var errorDescription: String? {
            switch self {
            case .missingClientID:
                return "Google Sign-In is not configured. Add GOOGLE_IOS_CLIENT_ID to Secrets.plist and the reversed client ID URL scheme in Xcode."
            case .missingWebClientID:
                return "Google Sign-In is not fully configured. Add GOOGLE_WEB_CLIENT_ID (Web OAuth client) to Secrets.plist and enable Google in Supabase."
            case .missingIDToken:
                return "Google Sign-In did not return a valid identity token."
            case .cancelled:
                return nil
            }
        }
    }

    #if canImport(UIKit)
    @MainActor
    static func configureIfNeeded() {
        guard let clientID = Config.googleIOSClientID, !clientID.isEmpty else { return }

        if let serverClientID = Config.googleWebClientID, !serverClientID.isEmpty {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(
                clientID: clientID,
                serverClientID: serverClientID
            )
        } else {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        }
    }

    @MainActor
    static func handleURL(_ url: URL) -> Bool {
        GIDSignIn.sharedInstance.handle(url)
    }

    @MainActor
    static func signIn(presenting viewController: UIViewController) async throws -> Credentials {
        guard let clientID = Config.googleIOSClientID, !clientID.isEmpty else {
            throw Error.missingClientID
        }

        guard let serverClientID = Config.googleWebClientID, !serverClientID.isEmpty else {
            throw Error.missingWebClientID
        }

        configureIfNeeded()

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: viewController)
            guard let idToken = result.user.idToken?.tokenString else {
                throw Error.missingIDToken
            }

            let accessToken = result.user.accessToken.tokenString
            guard !accessToken.isEmpty else {
                throw Error.missingIDToken
            }

            return Credentials(idToken: idToken, accessToken: accessToken)
        } catch let error as GIDSignInError where error.code == .canceled {
            throw Error.cancelled
        }
    }
    #endif
}
