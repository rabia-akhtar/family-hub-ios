import Foundation
import GoogleSignIn

// MARK: - Error Types

enum GoogleAuthError: LocalizedError {
    case noClientID
    case noPresentingViewController
    case notSignedIn
    case tokenRefreshFailed
    case signInCancelled

    var errorDescription: String? {
        switch self {
        case .noClientID:                return "Google Client ID not configured."
        case .noPresentingViewController: return "No view controller available to present sign-in."
        case .notSignedIn:               return "User is not signed in."
        case .tokenRefreshFailed:        return "Failed to refresh access token."
        case .signInCancelled:           return "Sign-in was cancelled."
        }
    }
}

// MARK: - GoogleAuthService

@MainActor
final class GoogleAuthService: ObservableObject {

    @Published var isSignedIn: Bool = false
    @Published var currentUser: GIDGoogleUser?

    // MARK: - Configuration

    func configure() {
        guard let clientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String,
              !clientID.isEmpty else {
            print("[GoogleAuthService] Warning: GIDClientID not set in Info.plist.")
            return
        }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
    }

    // MARK: - Restore Previous Session

    func restorePreviousSignIn() {
        GIDSignIn.sharedInstance.restorePreviousSignIn { [weak self] user, error in
            Task { @MainActor in
                if let user = user, error == nil {
                    self?.currentUser = user
                    self?.isSignedIn = true
                } else {
                    self?.currentUser = nil
                    self?.isSignedIn = false
                }
            }
        }
    }

    // MARK: - Sign In

    func signIn(presenting viewController: UIViewController) async throws {
        guard let clientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String,
              !clientID.isEmpty else {
            throw GoogleAuthError.noClientID
        }

        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

        let result = try await GIDSignIn.sharedInstance.signIn(
            withPresenting: viewController,
            hint: nil,
            additionalScopes: AppConfig.googleScopes
        )

        self.currentUser = result.user
        self.isSignedIn = true
    }

    // MARK: - Sign Out

    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        currentUser = nil
        isSignedIn = false
    }

    // MARK: - Access Token

    /// Returns a valid access token, refreshing if expired.
    func accessToken() async throws -> String {
        guard let user = currentUser ?? GIDSignIn.sharedInstance.currentUser else {
            throw GoogleAuthError.notSignedIn
        }

        // refreshTokensIfNeeded is async in GIDSignIn v7
        let refreshedUser = try await user.refreshTokensIfNeeded()
        guard let token = refreshedUser.accessToken.tokenString as String?,
              !token.isEmpty else {
            throw GoogleAuthError.tokenRefreshFailed
        }
        return token
    }

    // MARK: - Handle URL

    func handle(_ url: URL) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}
