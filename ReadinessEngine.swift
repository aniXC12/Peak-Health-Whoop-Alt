import Foundation
import Combine

@MainActor
final class ReadinessEngine: ObservableObject {
    @Published var readinessToday: Int = 50
    @Published var baselineHRV: Double = 55 // ms, naive default; ideally personalized rolling 28d
    @Published var sleepTarget: Double = 8.0 // hrs
    
    private var cancellables = Set<AnyCancellable>()
    
    func compute(for metrics: DayMetrics) -> Int {
        var score = 50
        
        if let hrv = metrics.hrv {
            // HRV vs baseline (higher is better)
            let ratio = max(0.0, min(2.0, hrv / max(20.0, baselineHRV)))
            score += Int((ratio - 1.0) * 25.0) // ±25
        }
        if let rhr = metrics.restingHR {
            // Resting HR – lower is better
            let delta = 60.0 - rhr // center at 60 bpm
            score += Int(delta * 0.5) // ±~20
        }
        if let sleep = metrics.sleepHours {
            let sleepDelta = sleep - sleepTarget
            score += Int(min(20.0, max(-20.0, sleepDelta * 5.0))) // ±20
        }
        
        return max(0, min(100, score))
    }
}
