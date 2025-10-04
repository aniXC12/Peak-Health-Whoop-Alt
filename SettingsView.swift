import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var hk: HealthKitManager
    @EnvironmentObject var engine: ReadinessEngine
    
    @State private var baselineHRVText: String = ""
    @State private var sleepTargetText: String = ""
    
    var body: some View {
        Form {
            Section("Health") {
                HStack {
                    Text("Health Access")
                    Spacer()
                    Image(systemName: hk.isAuthorized ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(hk.isAuthorized ? .green : .orange)
                }
                Button("Refresh Now") {
                    Task {
                        await hk.refreshAll()
                        engine.readinessToday = engine.compute(for: hk.today)
                    }
                }
            }
            Section("Readiness Model") {
                TextField("Baseline HRV (ms)", text: $baselineHRVText)
                    .keyboardType(.decimalPad)
                TextField("Sleep Target (h)", text: $sleepTargetText)
                    .keyboardType(.decimalPad)
                Button("Save") {
                    if let b = Double(baselineHRVText) { engine.baselineHRV = b }
                    if let s = Double(sleepTargetText) { engine.sleepTarget = s }
                }
            }
            Section("About") {
                Text("Peak MVP v0.1")
                Text("Not medical advice.")
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            baselineHRVText = String(format: "%.0f", engine.baselineHRV)
            sleepTargetText = String(format: "%.1f", engine.sleepTarget)
        }
    }
}
