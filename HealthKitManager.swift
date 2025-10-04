import Foundation
import HealthKit

@MainActor
final class HealthKitManager: ObservableObject {
    private let healthStore = HKHealthStore()
    
    @Published var isAuthorized: Bool = false
    @Published var today = DayMetrics(date: Date())
    @Published var last7: [DayMetrics] = []
    
    private let calendar = Calendar.current
    
    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let readTypes: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]
        
        do {
            try await healthStore.requestAuthorization(toShare: [], read: readTypes)
            isAuthorized = true
            await refreshAll()
        } catch {
            print("HealthKit auth error: \(error)")
        }
    }
    
    func refreshAll() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadToday() }
            group.addTask { await self.loadLast7() }
        }
    }
    
    private func loadToday() async {
        let start = calendar.startOfDay(for: Date())
        let end = Date()
        async let hrv = self.fetchLatestAverage(.heartRateVariabilitySDNN, unit: .secondUnit(with: .milli), start: start, end: end) // returns in ms
        async let rhr = self.fetchLatestAverage(.restingHeartRate, unit: HKUnit.count().unitDivided(by: .minute()), start: start, end: end)
        async let avgHR = self.fetchAverage(.heartRate, unit: HKUnit.count().unitDivided(by: .minute()), start: start, end: end)
        async let sleep = self.fetchSleepHours(start: start, end: end)
        async let steps = self.fetchSum(.stepCount, unit: .count(), start: start, end: end).map { Int($0) }
        async let active = self.fetchSum(.activeEnergyBurned, unit: .kilocalorie(), start: start, end: end)
        
        let todayMetrics = DayMetrics(date: Date(),
                                      hrv: await hrv,
                                      restingHR: await rhr,
                                      avgHR: await avgHR,
                                      sleepHours: await sleep,
                                      steps: await steps,
                                      activeCalories: await active,
                                      readiness: nil)
        await MainActor.run { self.today = todayMetrics }
    }
    
    private func loadLast7() async {
        var days: [DayMetrics] = []
        for i in 0..<7 {
            let day = calendar.date(byAdding: .day, value: -i, to: Date())!
            let start = calendar.startOfDay(for: day)
            let end = calendar.date(byAdding: .day, value: 1, to: start)!
            
            async let hrv = self.fetchAverage(.heartRateVariabilitySDNN, unit: .secondUnit(with: .milli), start: start, end: end)
            async let rhr = self.fetchAverage(.restingHeartRate, unit: HKUnit.count().unitDivided(by: .minute()), start: start, end: end)
            async let avgHR = self.fetchAverage(.heartRate, unit: HKUnit.count().unitDivided(by: .minute()), start: start, end: end)
            async let sleep = self.fetchSleepHours(start: start, end: end)
            async let steps = self.fetchSum(.stepCount, unit: .count(), start: start, end: end).map { Int($0) }
            async let active = self.fetchSum(.activeEnergyBurned, unit: .kilocalorie(), start: start, end: end)
            
            let m = DayMetrics(date: start,
                               hrv: await hrv,
                               restingHR: await rhr,
                               avgHR: await avgHR,
                               sleepHours: await sleep,
                               steps: await steps,
                               activeCalories: await active,
                               readiness: nil)
            days.append(m)
        }
        await MainActor.run { self.last7 = days.sorted { $0.date < $1.date } }
    }
    
    // MARK: - Queries
    
    private func fetchAverage(_ id: HKQuantityTypeIdentifier, unit: HKUnit, start: Date, end: Date) async -> Double? {
        guard let qt = HKObjectType.quantityType(forIdentifier: id) else { return nil }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        return await withCheckedContinuation { cont in
            let query = HKStatisticsQuery(quantityType: qt, quantitySamplePredicate: predicate, options: .discreteAverage) { _, stats, _ in
                if let avg = stats?.averageQuantity()?.doubleValue(for: unit) {
                    cont.resume(returning: avg)
                } else {
                    cont.resume(returning: nil)
                }
            }
            healthStore.execute(query)
        }
    }
    
    private func fetchLatestAverage(_ id: HKQuantityTypeIdentifier, unit: HKUnit, start: Date, end: Date) async -> Double? {
        await fetchAverage(id, unit: unit, start: start, end: end)
    }
    
    private func fetchSum(_ id: HKQuantityTypeIdentifier, unit: HKUnit, start: Date, end: Date) async -> Double {
        guard let qt = HKObjectType.quantityType(forIdentifier: id) else { return 0 }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        return await withCheckedContinuation { cont in
            let query = HKStatisticsQuery(quantityType: qt, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, _ in
                let sum = stats?.sumQuantity()?.doubleValue(for: unit) ?? 0
                cont.resume(returning: sum)
            }
            healthStore.execute(query)
        }
    }
    
    private func fetchSleepHours(start: Date, end: Date) async -> Double? {
        guard let ct = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return nil }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        return await withCheckedContinuation { cont in
            let query = HKSampleQuery(sampleType: ct, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                guard let samples = samples as? [HKCategorySample], !samples.isEmpty else {
                    cont.resume(returning: nil); return
                }
                let total = samples.reduce(0.0) { acc, s in
                    if s.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                       s.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                       s.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue ||
                       s.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue {
                        return acc + s.endDate.timeIntervalSince(s.startDate)
                    }
                    return acc
                }
                cont.resume(returning: total / 3600.0)
            }
            healthStore.execute(query)
        }
    }
}
