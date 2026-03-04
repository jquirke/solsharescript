import SwiftUI

@main
struct SolarSliceApp: App {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var propertyManager = PropertyManager.shared

    var body: some Scene {
        WindowGroup {
            if authManager.isLoggedIn {
                RootView()
                    .environmentObject(authManager)
                    .environmentObject(propertyManager)
            } else {
                LoginView()
                    .environmentObject(authManager)
            }
        }
    }
}
