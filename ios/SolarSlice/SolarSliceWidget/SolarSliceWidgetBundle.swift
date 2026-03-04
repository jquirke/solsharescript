import WidgetKit
import SwiftUI

@main
struct SolarSliceWidgetBundle: WidgetBundle {
    var body: some Widget {
        SolarSliceWidget()
    }
}

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
