import Foundation
import CoreMotion

final class MotionManager {
    private let pedometer = CMPedometer()
    
    func getTodaySteps(completion: @escaping (Int?) -> Void) {
        guard CMPedometer.isStepCountingAvailable() else { completion(nil); return }
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        pedometer.queryPedometerData(from: start, to: Date()) { data, _ in
            completion(data?.numberOfSteps.intValue)
        }
    }
}
