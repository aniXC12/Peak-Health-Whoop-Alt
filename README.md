# Peak (Whoop/Bevel‑style iOS Health MVP)

A SwiftUI MVP that mirrors core loops from Whoop/Oura/Bevel: ingest HealthKit (HR, HRV, sleep, steps), compute a simple **Readiness** score, display day & trend dashboards, and collect a **daily check‑in**. BLE wearables can be integrated later via CoreBluetooth.

## Quick Start (Xcode 15+, iOS 17+)

1. **Create a new SwiftUI App** in Xcode named `Peak` (or any name).
2. Add the files in this repo into your project (drag the `App`, `Models`, `Services`, `Views`, `Utilities` folders into Xcode – *Copy items if needed*).
3. In your app target:
   - **Signing & Capabilities → + Capability → HealthKit**
   - Under *Background Modes*, enable **Background fetch** (optional for future).
4. **Info.plist** – ensure usage descriptions exist (Xcode usually generates these):
   - `NSHealthShareUsageDescription`: “Peak uses HealthKit to read heart rate, HRV, sleep, steps, and calories to compute insights.”
   - `NSHealthUpdateUsageDescription`: “Peak writes optional wellness check‑ins.” (we’re not writing to HealthKit in MVP)
5. On first launch, tap **Connect Health** to request permissions (Apple Watch data for HR/HRV/Sleep).

## Architecture

- **SwiftUI + MVVM-ish**
- **HealthKitManager**: auth + reads (HR, HRV, Resting HR, Sleep, Steps, Active Energy).
- **MotionManager**: CoreMotion step fallbacks.
- **ReadinessEngine**: single‑number daily score (0–100) from HRV vs baseline, sleep duration vs target, and resting HR.
- **Views**: Dashboard, Trends, Journal, Settings.
- **Charts**: Swift Charts for simple trendlines.

## Roadmap

- CoreBluetooth to ingest raw PPG/ECG from third‑party bands (if provided SDK).
- Sleep staging and strain/load modeling (TRIMP/HR‑based).
- Personalized baselines (rolling 28‑day windows).
- Notifications and weekly report PDF export.
