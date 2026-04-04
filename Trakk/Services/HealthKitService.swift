import Foundation
import HealthKit

@MainActor
final class HealthKitService: ObservableObject {
    static let shared = HealthKitService()

    private let store = HKHealthStore()

    @Published var isAuthorized = false
    @Published var latestWeight: Double?           // kg
    @Published var todayActiveCalories: Double = 0
    @Published var todayRestingCalories: Double = 0
    @Published var todaySteps: Double = 0
    @Published var weightHistory: [(date: Date, kg: Double)] = []
    @Published var lastWorkoutDate: Date?

    var todayTotalBurned: Double { todayActiveCalories + todayRestingCalories }

    private let readTypes: Set<HKObjectType> = [
        HKQuantityType(.bodyMass),
        HKQuantityType(.activeEnergyBurned),
        HKQuantityType(.basalEnergyBurned),
        HKQuantityType(.stepCount),
        HKWorkoutType.workoutType(),
    ]

    func requestAuthorization() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else { return false }
        do {
            try await store.requestAuthorization(toShare: [], read: readTypes)
            isAuthorized = true
            return true
        } catch {
            return false
        }
    }

    func refreshAll() async {
        async let w: () = fetchLatestWeight()
        async let a: () = fetchTodayActiveCalories()
        async let r: () = fetchTodayRestingCalories()
        async let s: () = fetchTodaySteps()
        async let wh: () = fetchWeightHistory(days: 90)
        async let lw: () = fetchLastWorkoutDate()
        _ = await (w, a, r, s, wh, lw)
    }

    func fetchLatestWeight() async {
        let type = HKQuantityType(.bodyMass)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sort]) { [weak self] _, samples, _ in
            guard let sample = samples?.first as? HKQuantitySample else { return }
            let kg = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
            Task { @MainActor in
                self?.latestWeight = kg
            }
        }
        store.execute(query)
    }

    func fetchTodayActiveCalories() async {
        todayActiveCalories = await fetchTodayCumulative(type: HKQuantityType(.activeEnergyBurned), unit: .kilocalorie())
    }

    func fetchTodayRestingCalories() async {
        todayRestingCalories = await fetchTodayCumulative(type: HKQuantityType(.basalEnergyBurned), unit: .kilocalorie())
    }

    func fetchTodaySteps() async {
        todaySteps = await fetchTodayCumulative(type: HKQuantityType(.stepCount), unit: .count())
    }

    func fetchWeightHistory(days: Int) async {
        let type = HKQuantityType(.bodyMass)
        let start = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { [weak self] _, samples, _ in
            guard let samples = samples as? [HKQuantitySample] else { return }
            let history = samples.map { (date: $0.startDate, kg: $0.quantity.doubleValue(for: .gramUnit(with: .kilo))) }
            Task { @MainActor in
                self?.weightHistory = history
            }
        }
        store.execute(query)
    }

    func fetchLastWorkoutDate() async {
        let type = HKWorkoutType.workoutType()
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sort]) { [weak self] _, samples, _ in
            let date = (samples?.first as? HKWorkout)?.startDate
            Task { @MainActor in
                self?.lastWorkoutDate = date
            }
        }
        store.execute(query)
    }

    private func fetchTodayCumulative(type: HKQuantityType, unit: HKUnit) async -> Double {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                let value = result?.sumQuantity()?.doubleValue(for: unit) ?? 0
                continuation.resume(returning: value)
            }
            store.execute(query)
        }
    }
}
