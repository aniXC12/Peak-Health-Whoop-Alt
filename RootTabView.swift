import SwiftUI
import Charts

struct RootTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Dashboard", systemImage: "waveform.path.ecg") }
            TrendsView()
                .tabItem { Label("Trends", systemImage: "chart.line.uptrend.xyaxis") }
            JournalView()
                .tabItem { Label("Journal", systemImage: "square.and.pencil") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
    }
}
