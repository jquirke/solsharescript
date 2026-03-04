import SwiftUI

struct PropertyPickerView: View {
    @EnvironmentObject private var propertyManager: PropertyManager

    var body: some View {
        NavigationStack {
            List(propertyManager.properties) { property in
                Button {
                    propertyManager.select(property)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(property.displayAddress)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text("NMI: \(property.NMI)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Select Property")
        }
    }
}
