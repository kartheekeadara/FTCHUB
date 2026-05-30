//
//  AppleSignInHelper.swift
//  FTCHUB
//

import AuthenticationServices
import CryptoKit
import Foundation

struct AppleSignInCredentials {
    let idToken: String
    let nonce: String
}

enum AppleSignInHelper {
    enum Error: LocalizedError {
        case cancelled
        case missingIdentityToken
        case authorizationFailed(String)

        var errorDescription: String? {
            switch self {
            case .cancelled:
                return nil
            case .missingIdentityToken:
                return "Sign in with Apple did not return a valid identity token."
            case .authorizationFailed(let message):
                return message
            }
        }
    }

    static func prepareRequest(_ request: ASAuthorizationAppleIDRequest) -> String {
        let nonce = randomNonceString()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        return nonce
    }

    static func credentials(from authorization: ASAuthorization, nonce: String) throws -> AppleSignInCredentials {
        guard
            let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
            let tokenData = credential.identityToken,
            let idToken = String(data: tokenData, encoding: .utf8)
        else {
            throw Error.missingIdentityToken
        }

        return AppleSignInCredentials(idToken: idToken, nonce: nonce)
    }

    @MainActor
    static func signIn() async throws -> AppleSignInCredentials {
        let nonce = randomNonceString()
        let hashedNonce = sha256(nonce)

        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = hashedNonce

        return try await withCheckedThrowingContinuation { continuation in
            let coordinator = AppleSignInCoordinator(nonce: nonce, continuation: continuation)
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = coordinator
            controller.presentationContextProvider = coordinator
            coordinator.retainSelf = coordinator
            controller.performRequests()
        }
    }

    private static func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            var randoms = [UInt8](repeating: 0, count: 16)
            let errorCode = SecRandomCopyBytes(kSecRandomDefault, randoms.count, &randoms)
            if errorCode != errSecSuccess {
                fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
            }

            randoms.forEach { random in
                if remainingLength == 0 { return }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }

    private static func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}

@MainActor
private final class AppleSignInCoordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private let nonce: String
    private let continuation: CheckedContinuation<AppleSignInCredentials, Swift.Error>
    var retainSelf: AppleSignInCoordinator?

    init(nonce: String, continuation: CheckedContinuation<AppleSignInCredentials, Swift.Error>) {
        self.nonce = nonce
        self.continuation = continuation
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard
            let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let window = scene.windows.first(where: { $0.isKeyWindow })
        else {
            return ASPresentationAnchor()
        }
        return window
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        defer { retainSelf = nil }

        guard
            let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
            let tokenData = credential.identityToken,
            let idToken = String(data: tokenData, encoding: .utf8)
        else {
            continuation.resume(throwing: AppleSignInHelper.Error.missingIdentityToken)
            return
        }

        continuation.resume(returning: AppleSignInCredentials(idToken: idToken, nonce: nonce))
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Swift.Error) {
        defer { retainSelf = nil }

        if let authError = error as? ASAuthorizationError, authError.code == .canceled {
            continuation.resume(throwing: AppleSignInHelper.Error.cancelled)
            return
        }

        continuation.resume(throwing: AppleSignInHelper.Error.authorizationFailed(error.localizedDescription))
    }
}

#if canImport(UIKit)
import UIKit
#endif
