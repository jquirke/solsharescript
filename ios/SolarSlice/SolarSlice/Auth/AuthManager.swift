import Foundation
import Combine

@MainActor
final class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published private(set) var token: String?
    @Published private(set) var isLoggedIn = false

    private init() {
        token = KeychainHelper.loadToken()
        isLoggedIn = token != nil
    }

    func login(email: String, password: String) async throws {
        let response = try await APIClient.shared.login(email: email, password: password)
        KeychainHelper.saveToken(response.accessToken)
        token = response.accessToken
        isLoggedIn = true
    }

    func logout() {
        KeychainHelper.deleteToken()
        token = nil
        isLoggedIn = false
    }

    /// Called when any API call receives a 401/403; clears credentials and returns to login.
    func handleTokenExpiry() {
        logout()
    }
}
