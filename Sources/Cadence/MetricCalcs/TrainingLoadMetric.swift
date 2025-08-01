//
//  TrainingLoadMetric.swift
//  Cadence
//
//  Created by Nicholas Hartman on 7/31/25.
//

import Foundation

/// Training Load metric calculating Acute:Chronic workload ratio with gender-specific TRIMP
///
/// This implementation calculates the ratio between acute load (7-day average TRIMP) 
/// and chronic load (28-day average TRIMP) using gender-specific Banister's TRIMP formulas.
/// Ratios between 0.8-1.3 are considered optimal training zones.
///
/// Uses gender-specific coefficients:
/// - Male: Duration × HRr × 0.64 × e^(1.92 × HRr)
/// - Female: Duration × HRr × 0.86 × e^(1.67 × HRr)
public struct TrainingLoadMetric: CadenceMetricCalc {
    public typealias Result = SampleMetricContainer<UnitTRIMP>
    public var id: UUID = .init()
    public var description: String { "Gender-Specific Training Load (A:C Ratio)" }
    
    public var activities: ActivityOptions { [.running, .cycling] }
    public var metrics: MetricOptions { .heartRate }
    
    private let athlete: CadenceAthlete?
    private let acuteDays: Int = 7
    private let chronicDays: Int = 28
    
    /// Initialize with athlete profile (fetches HR data and gender from athlete's stores)
    public init(athlete: CadenceAthlete) {
        self.athlete = athlete
    }
    
    public func compute(from store: [CadenceStore], in season: CadenceTrainingSeason) async throws -> Result {
        let supported = store.compactMap { store in
            if (store.supportedActivityTypes.contains(activities) && store.supportedMetricTypes.contains(metrics)) {
                return store
            } else {
                return nil
            }
        }
        
        guard !supported.isEmpty else {
            throw CadenceError.noSupportedActivities(activities)
        }
        
        // Fetch from athlete profile (athlete is always non-nil)
        guard let athlete = athlete else {
            throw CadenceError.missingRequiredParameter("Athlete required for TrainingLoadMetric")
        }
        
        guard let restingHR = try await athlete.restingHeartRate,
              let maxHR = try await athlete.maxHeartRate else {
            throw CadenceError.missingRequiredParameter("Athlete missing resting or max heart rate data")
        }
        
        let biologicalGender = athlete.biologicalGender
        
        // Calculate daily TRIMP values for the chronic period
        let endDate = season.endDate
        let chronicStart = Calendar.current.date(byAdding: .day, value: -chronicDays, to: endDate)!
        var dailyTRIMPs: [Double] = []
        
        // Calculate TRIMP for each day in the chronic period
        for dayOffset in 0..<chronicDays {
            let dayStart = Calendar.current.date(byAdding: .day, value: dayOffset, to: chronicStart)!
            let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart)!
            
            let daySeason = CadenceTrainingSeason(seasonInterval: CadenceTrainingWeekRange(startDate: dayStart, endDate: dayEnd)) {}
            
            var dayTRIMP = 0.0
            
            // Fetch heart rate data for this day
            for store in supported {
                do {
                    let dayMetrics: [any SampleMetric<UnitFrequency>] = try await store.fetch(activities, metrics: metrics, in: daySeason)
                    
                    if !dayMetrics.isEmpty {
                        // Calculate gender-specific Banister TRIMP for this day
                        let totalDuration = dayMetrics.last!.endDate.timeIntervalSince(dayMetrics.first!.startDate) / 60.0
                        let totalHR = dayMetrics.reduce(0.0) { sum, sample in
                            sum + sample.measurment.converted(to: .beatsPerMinute).value
                        }
                        let avgHR = totalHR / Double(dayMetrics.count)
                        let hrReserve = (avgHR - restingHR) / (maxHR - restingHR)
                        
                        // Validate heart rate reserve
                        guard hrReserve >= 0 && hrReserve <= 1 else {
                            continue // Skip invalid data for this day
                        }
                        
                        // Apply gender-specific Banister TRIMP formula
                        let dayTRIMPValue: Double
                        switch biologicalGender {
                        case .female:
                            // Female formula: Duration × HRr × 0.86 × e^(1.67 × HRr)
                            dayTRIMPValue = totalDuration * hrReserve * 0.86 * exp(1.67 * hrReserve)
                        case .male:
                            // Male formula: Duration × HRr × 0.64 × e^(1.92 × HRr)
                            dayTRIMPValue = totalDuration * hrReserve * 0.64 * exp(1.92 * hrReserve)
                        case .other, .notSet, .none:
                            // Default to male formula when gender is unknown
                            dayTRIMPValue = totalDuration * hrReserve * 0.64 * exp(1.92 * hrReserve)
                        }
                        
                        dayTRIMP += dayTRIMPValue
                    }
                } catch {
                    // No data for this day, TRIMP = 0
                }
            }
            
            dailyTRIMPs.append(dayTRIMP)
        }
        
        // Calculate acute and chronic loads
        let acuteTRIMPs = Array(dailyTRIMPs.suffix(acuteDays))
        let acuteLoad = acuteTRIMPs.reduce(0, +) / Double(acuteDays)
        let chronicLoad = dailyTRIMPs.reduce(0, +) / Double(chronicDays)
        
        // Calculate Acute:Chronic ratio
        let acuteChronicRatio = chronicLoad > 0 ? acuteLoad / chronicLoad : 0.0
        
        return SampleMetricContainer<UnitTRIMP>(
            activity: activities,
            metric: .trimp,
            startDate: season.startDate,
            endDate: season.endDate,
            measurment: Measurement(value: acuteChronicRatio, unit: UnitTRIMP.BaseUnit())
        )
    }
}