# SolarSlice — Xcode Project Setup

## Prerequisites
- Xcode 15 or later
- iOS 16+ device or simulator
- Active Apple Developer account (for App Groups capability)

## Steps

### 1. Create the Xcode Project
1. Open Xcode → **File → New → Project**
2. Choose **iOS → App**
3. Set:
   - **Product Name:** `SolarSlice`
   - **Bundle Identifier:** `au.com.jquirke.solarslice`
   - **Interface:** SwiftUI
   - **Language:** Swift
4. Save the project inside this `ios/` directory

### 2. Add Source Files to Main Target
In Xcode, select the `SolarSlice` group in the Project Navigator and add the following files (**File → Add Files to "SolarSlice"**), ensuring they are added to the `SolarSlice` target:

```
SolarSlice/SolarSliceApp.swift
SolarSlice/Models/Models.swift
SolarSlice/API/APIClient.swift
SolarSlice/Auth/KeychainHelper.swift
SolarSlice/Auth/AuthManager.swift
SolarSlice/Auth/LoginView.swift
SolarSlice/Root/PropertyManager.swift
SolarSlice/Root/RootView.swift
SolarSlice/Root/ContentView.swift
SolarSlice/Properties/PropertyPickerView.swift
SolarSlice/Summary/SummaryViewModel.swift
SolarSlice/Summary/SummaryView.swift
SolarSlice/Trends/TrendsViewModel.swift
SolarSlice/Trends/TrendsView.swift
SolarSlice/Shared/AppGroupCache.swift
SolarSlice/Shared/ViewComponents.swift
```

### 3. Add Widget Extension Target
1. **File → New → Target**
2. Choose **Widget Extension**
3. Set:
   - **Product Name:** `SolarSliceWidget`
   - **Bundle Identifier:** `au.com.jquirke.solarslice.widget`
   - **Include Configuration App Intent:** No (uncheck)
4. When prompted "Activate SolarSliceWidget scheme?", click **Activate**

### 4. Add Widget Source File
- Delete the auto-generated widget Swift file Xcode creates
- Add `SolarSliceWidget/SolarSliceWidget.swift` to the `SolarSliceWidget` target

### 5. Add Shared File to Both Targets
Select `SolarSlice/Shared/AppGroupCache.swift` in the Project Navigator, open the **File Inspector** (right panel), and under **Target Membership** check **both** `SolarSlice` and `SolarSliceWidget`.

### 6. Enable App Groups
For **each** target (SolarSlice and SolarSliceWidget):
1. Select the target in the project settings
2. Go to **Signing & Capabilities**
3. Click **+ Capability** → **App Groups**
4. Click **+** and add: `group.au.com.jquirke.solarslice`

### 7. Set Minimum Deployment Target
For both targets, set **Minimum Deployments → iOS 16.0**.

### 8. Build and Run
Select the `SolarSlice` scheme and your target device/simulator, then press **⌘R**.

## Notes
- The app uses no third-party dependencies — no SPM packages needed
- Keychain access is scoped to service `au.com.jquirke.solarslice`
- Widget data is shared via App Group UserDefaults (`group.au.com.jquirke.solarslice`)
- The widget timeline refreshes every 15 minutes automatically
