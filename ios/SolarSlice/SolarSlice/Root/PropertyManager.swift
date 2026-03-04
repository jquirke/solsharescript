import Foundation
import Combine

@MainActor
final class PropertyManager: ObservableObject {
    static let shared = PropertyManager()

    @Published private(set) var properties: [SolProperty] = []
    @Published private(set) var selectedProperty: SolProperty?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let selectedPropertyIdKey = "selectedPropertyId"

    private init() {}

    func fetchProperties(token: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await APIClient.shared.fetchProperties(token: token)
            properties = response.properties

            // Auto-select: restore persisted selection, or auto-select if only one property
            let savedId = UserDefaults.standard.integer(forKey: selectedPropertyIdKey)
            if savedId != 0, let match = properties.first(where: { $0.id == savedId }) {
                selectedProperty = match
            } else if properties.count == 1 {
                select(properties[0])
            }
        } catch let error as APIError where error == .invalidToken {
            AuthManager.shared.handleTokenExpiry()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func select(_ property: SolProperty) {
        selectedProperty = property
        UserDefaults.standard.set(property.id, forKey: selectedPropertyIdKey)
    }

    func clearSelection() {
        selectedProperty = nil
        UserDefaults.standard.removeObject(forKey: selectedPropertyIdKey)
    }
}

extension APIError: Equatable {
    static func == (lhs: APIError, rhs: APIError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidToken, .invalidToken):     return true
        case (.invalidResponse, .invalidResponse): return true
        case (.serverError(let a), .serverError(let b)): return a == b
        default: return false
        }
    }
}
