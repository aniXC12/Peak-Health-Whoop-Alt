import SwiftUI

@main
struct PeakApp: App {
    @StateObject private var hk = HealthKitManager()
    @StateObject private var engine = ReadinessEngine()
    
    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(hk)
                .environmentObject(engine)
        }
    }
}
