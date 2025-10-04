import Foundation
import HealthKit

struct DayMetrics: Identifiable, Hashable {
    let id = UUID()
    var date: Date
    var hrv: Double?            // ms (SDNN proxy via HealthKit HRV)
    var restingHR: Double?      // bpm
    var avgHR: Double?          // bpm
    var sleepHours: Double?     // hours
    var steps: Int?
    var activeCalories: Double? // kcal
    var readiness: Int?         // 0-100
}

extension HKQuantityTypeIdentifier {
    static let hrv = HKQuantityTypeIdentifier.heartRateVariabilitySDNN
}
