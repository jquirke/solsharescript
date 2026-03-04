import Foundation

enum AppGroupCache {
    static let suiteName = "group.au.com.jquirke.solarslice"
    static let widgetDataKey = "widgetCacheData"

    static func saveWidgetData(_ data: WidgetCacheData) {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return }
        if let encoded = try? JSONEncoder().encode(data) {
            defaults.set(encoded, forKey: widgetDataKey)
        }
    }

    static func loadWidgetData() -> WidgetCacheData? {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let data = defaults.data(forKey: widgetDataKey),
              let decoded = try? JSONDecoder().decode(WidgetCacheData.self, from: data)
        else { return nil }
        return decoded
    }
}
