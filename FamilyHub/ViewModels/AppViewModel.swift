import Foundation
import GoogleSignIn
import UIKit

@MainActor
final class AppViewModel: ObservableObject {

    // MARK: - Published State

    @Published var isSignedIn: Bool = false
    @Published var currentUser: GIDGoogleUser?
    @Published var spreadsheetId: String?
    @Published var budgetSpreadsheetId: String?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Services

    let authService   = GoogleAuthService()
    let sheetsService = SheetsService()
    let calendarService = CalendarService()
    let weatherService  = WeatherService()

    // MARK: - Init

    init() {
        authService.configure()
        restorePreviousSession()
    }

    // MARK: - Session Restore

    private func restorePreviousSession() {
        authService.restorePreviousSignIn()
        // Monitor auth service changes
        Task {
            // Give restorePreviousSignIn time to complete
            try? await Task.sleep(nanoseconds: 500_000_000)
            self.currentUser = self.authService.currentUser
            self.isSignedIn  = self.authService.isSignedIn
            if self.isSignedIn {
                await self.setup()
            }
        }
    }

    // MARK: - Sign In

    func signIn(presenting viewController: UIViewController) async {
        isLoading = true
        errorMessage = nil
        do {
            try await authService.signIn(presenting: viewController)
            currentUser = authService.currentUser
            isSignedIn  = authService.isSignedIn
            await setup()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Sign Out

    func signOut() {
        authService.signOut()
        currentUser = nil
        isSignedIn  = false
        spreadsheetId = nil
        budgetSpreadsheetId = nil
        // UserDefaults IDs are intentionally kept so the next sign-in reconnects
        // to the same shared spreadsheets rather than creating new ones.
    }

    // MARK: - Setup after Sign-In

    /// Finds or creates both spreadsheets. Called after sign-in and on restore.
    /// Searches Drive by name so any device signing into the same Google account
    /// connects to the same shared data — not a per-device copy.
    func setup() async {
        isLoading = true
        do {
            let token = try await authService.accessToken()
            async let mainID   = sheetsService.ensureSpreadsheet(token: token)
            async let budgetID = sheetsService.ensureBudgetSpreadsheet(token: token)
            self.spreadsheetId = try await mainID
            self.budgetSpreadsheetId = try await budgetID
        } catch {
            errorMessage = "Setup failed: \(error.localizedDescription)"
        }
        isLoading = false
    }

    // MARK: - Convenience Token

    func accessToken() async throws -> String {
        try await authService.accessToken()
    }

    // MARK: - User Info

    var userDisplayName: String {
        currentUser?.profile?.name ?? "Family"
    }

    var userEmail: String {
        currentUser?.profile?.email ?? ""
    }

    var userId: String {
        currentUser?.userID ?? ""
    }
}
