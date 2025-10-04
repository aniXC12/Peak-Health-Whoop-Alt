import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var hk: HealthKitManager
    @EnvironmentObject var engine: ReadinessEngine
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    if !hk.isAuthorized {
                        ConnectHealthCard()
                    }
                    
                    ReadinessCard()
                    MetricsGrid()
                }
                .padding()
            }
            .navigationTitle("Peak")
            .background(Color.peakBG.ignoresSafeArea())
            .task {
                if hk.isAuthorized {
                    await hk.refreshAll()
                    engine.readinessToday = engine.compute(for: hk.today)
                }
            }
        }
    }
    
    @ViewBuilder
    private func ConnectHealthCard() -> some View {
        VStack(spacing: 12) {
            Text("Connect Health")
                .font(.headline)
            Text("Grant Health access to pull HR, HRV, sleep, steps, and energy to compute your daily readiness.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
            Button {
                Task { await hk.requestAuthorization() }
            } label: {
                Text("Enable HealthKit")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color.peakCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    @ViewBuilder
    private func ReadinessCard() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Readiness")
                    .font(.headline)
                Spacer()
                Text("\(engine.readinessToday)")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
            }
            ProgressView(value: Double(engine.readinessToday), total: 100)
                .tint(.green)
            HStack(spacing: 12) {
                MetricPill(title: "HRV", value: valueText(hk.today.hrv, suffix: " ms"))
                MetricPill(title: "Resting HR", value: valueText(hk.today.restingHR, suffix: " bpm"))
                MetricPill(title: "Sleep", value: valueText(hk.today.sleepHours, suffix: " h", digits: 1))
            }
        }
        .padding()
        .background(Color.peakCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    @ViewBuilder
    private func MetricsGrid() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today")
                .font(.headline)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                MetricTile(icon: "heart.fill", title: "Avg HR", value: valueText(hk.today.avgHR, suffix: " bpm"))
                MetricTile(icon: "moon.fill", title: "Sleep", value: valueText(hk.today.sleepHours, suffix: " h", digits: 1))
                MetricTile(icon: "figure.walk", title: "Steps", value: hk.today.steps.map { "\($0)" } ?? "—")
                MetricTile(icon: "flame.fill", title: "Active", value: valueText(hk.today.activeCalories, suffix: " kcal", digits: 0))
            }
        }
        .padding()
        .background(Color.peakCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func valueText(_ v: Double?, suffix: String, digits: Int = 0) -> String {
        guard let v else { return "—" }
        return String(format: "%.*f%@", digits, v, suffix)
    }
}

private struct MetricTile: View {
    let icon: String
    let title: String
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon).font(.subheadline)
            Text(value).font(.title3).bold()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.peakBG)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct MetricPill: View {
    let title: String
    let value: String
    var body: some View {
        HStack {
            Text(title).font(.caption2).foregroundColor(.secondary)
            Text(value).font(.caption).bold()
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(Color.peakBG)
        .clipShape(Capsule())
    }
}
