import SwiftUI
import Charts

struct TrendsView: View {
    @EnvironmentObject var hk: HealthKitManager
    @EnvironmentObject var engine: ReadinessEngine
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    ChartCard(title: "HRV (ms)", data: hk.last7, keyPath: \.hrv)
                    ChartCard(title: "Resting HR (bpm)", data: hk.last7, keyPath: \.restingHR)
                    ChartCard(title: "Sleep (h)", data: hk.last7, keyPath: \.sleepHours)
                    ChartCard(title: "Steps", data: hk.last7.map { m in m.steps.map(Double.init) ?? 0 }, dates: hk.last7.map(\.(\.date)))
                }
                .padding()
            }
            .navigationTitle("Trends")
            .background(Color.peakBG.ignoresSafeArea())
        }
    }
}

private struct ChartCard<T: BinaryFloatingPoint>: View {
    let title: String
    let data: [DayMetrics]
    let keyPath: KeyPath<DayMetrics, Double?>
    
    init(title: String, data: [DayMetrics], keyPath: KeyPath<DayMetrics, Double?>) {
        self.title = title
        self.data = data
        self.keyPath = keyPath
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            Chart {
                ForEach(data) { m in
                    if let v = m[keyPath: keyPath] {
                        LineMark(x: .value("Date", m.date), y: .value("Value", v))
                        PointMark(x: .value("Date", m.date), y: .value("Value", v))
                    }
                }
            }
            .frame(height: 180)
        }
        .padding()
        .background(Color.peakCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
