import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct SolarEntry: TimelineEntry {
    let date: Date
    let cache: WidgetCacheData?
}

// MARK: - Timeline Provider

struct SolarProvider: TimelineProvider {
    func placeholder(in context: Context) -> SolarEntry {
        SolarEntry(date: Date(), cache: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (SolarEntry) -> Void) {
        let entry = SolarEntry(date: Date(), cache: AppGroupCache.loadWidgetData())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SolarEntry>) -> Void) {
        let entry = SolarEntry(date: Date(), cache: AppGroupCache.loadWidgetData())
        // Refresh every 15 minutes
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextRefresh))
        completion(timeline)
    }
}

// MARK: - Widget View

struct SolarWidgetView: View {
    let entry: SolarEntry

    @Environment(\.widgetFamily) var family

    var body: some View {
        if let data = entry.cache {
            filledView(data: data)
        } else {
            placeholderView
        }
    }

    private func filledView(data: WidgetCacheData) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "sun.max.fill")
                    .foregroundStyle(.yellow)
                    .font(.caption)
                Text("SolarSlice")
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .leading, spacing: 2) {
                Text(formattedEnergy(data.solarUsedToday))
                    .font(.title2.bold())
                    .minimumScaleFactor(0.7)
                Text("solar today")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Label(
                    String(format: "%.0f%%", data.solarPercentToday * 100),
                    systemImage: "percent"
                )
                .font(.caption2)
                .foregroundStyle(.green)

                Spacer()

                Text(updatedText(data.updatedAt))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var placeholderView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "sun.max.fill")
                    .foregroundStyle(.yellow)
                    .font(.caption)
                Text("SolarSlice")
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("Open app to load data")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private func formattedEnergy(_ wh: Double) -> String {
        if wh >= 1000 {
            return String(format: "%.2f kWh", wh / 1000)
        }
        return String(format: "%.0f Wh", wh)
    }

    private func updatedText(_ date: Date) -> String {
        let elapsed = Date().timeIntervalSince(date)
        if elapsed < 60 { return "just now" }
        let minutes = Int(elapsed / 60)
        if minutes < 60 { return "\(minutes)m ago" }
        let hours = Int(elapsed / 3600)
        return "\(hours)h ago"
    }
}

// MARK: - Widget Configuration

struct SolarSliceWidget: Widget {
    let kind = "SolarSliceWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SolarProvider()) { entry in
            SolarWidgetView(entry: entry)
        }
        .configurationDisplayName("SolarSlice")
        .description("Today's solar usage at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Widget Bundle

@main
struct SolarSliceWidgetBundle: WidgetBundle {
    var body: some Widget {
        SolarSliceWidget()
    }
}
