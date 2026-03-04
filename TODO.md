# TODO

## iOS App

### Widget background refresh
Currently the widget only updates when the main app is opened. To enable true background refresh:
- Register a `BGAppRefreshTask` in `Info.plist` and schedule it on each successful fetch
- In the task handler: fetch today's data → write App Group cache → call `WidgetCenter.shared.reloadAllTimelines()`
- Also call `WidgetCenter.shared.reloadAllTimelines()` in `SummaryViewModel.writeWidgetCache()` so the widget updates immediately on foreground fetch

### Dryer experiment
Repeat load detection experiment with:
- Full drum load (not empty)
- Start time not straddling a 5-minute bucket boundary
- Baseline: compare against `solarConsumed` delta rather than raw demand

## General

### Weather correlation
Correlate solar generation volatility with BOM weather/clear-sky irradiance model to improve HVAC demand shedding signal quality.
