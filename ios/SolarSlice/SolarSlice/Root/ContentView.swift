import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var propertyManager: PropertyManager

    var body: some View {
        TabView {
            SummaryView()
                .tabItem {
                    Label("Summary", systemImage: "sun.max")
                }

            TrendsView()
                .tabItem {
                    Label("Trends", systemImage: "chart.bar")
                }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    if propertyManager.properties.count > 1 {
                        Button("Switch Property") {
                            propertyManager.clearSelection()
                        }
                    }
                    Button("Sign Out", role: .destructive) {
                        authManager.logout()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
}
