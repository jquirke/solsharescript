import SwiftUI

struct RootView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var propertyManager: PropertyManager

    var body: some View {
        Group {
            if propertyManager.isLoading {
                loadingView
            } else if let error = propertyManager.errorMessage {
                errorView(error)
            } else if propertyManager.selectedProperty != nil {
                ContentView()
            } else if propertyManager.properties.count > 1 {
                PropertyPickerView()
            } else {
                loadingView
            }
        }
        .task { await loadProperties() }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading properties…")
                .foregroundStyle(.secondary)
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Retry") {
                Task { await loadProperties() }
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }

    private func loadProperties() async {
        guard let token = authManager.token else { return }
        await propertyManager.fetchProperties(token: token)
    }
}
