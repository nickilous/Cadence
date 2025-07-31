# Cadence

A Swift package for fitness metric calculations and training data analysis, with built-in support for HealthKit integration and App Intents.

## Features

- 🏃‍♂️ **Activity Tracking**: Support for running, cycling, swimming, strength training, and more
- 📊 **Metric Calculations**: Heart rate, power, distance, energy, and performance metrics
- 👤 **Athlete Profiles**: Centralized athlete data with automatic physiological parameter fetching
- 🧮 **TRIMP Calculations**: Multiple scientifically-validated Training Impulse methods with conversions
- 🗓️ **Training Seasons**: Organize workouts into phases (base, building, peak)
- 🔗 **HealthKit Integration**: Seamless data fetching from Apple Health
- 📱 **App Intents Support**: Siri shortcuts and iOS automation
- ⚡ **Swift 6 Ready**: Full concurrency safety and modern Swift features

## Requirements

- **iOS 16.0+** / **macOS 13.0+**
- **Swift 6.1+**
- **Xcode 15.0+**

## Installation

### Swift Package Manager

Add Cadence to your project using Xcode or by adding it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/your-username/Cadence.git", from: "0.0.1")
]
```

## Quick Start

### 1. Import the Framework

```swift
import Cadence
```

### 2. Define Activity and Metric Types

```swift
// Activity types
let activities: ActivityOptions = [.running, .cycling]

// Metrics to track
let metrics: MetricOptions = [.heartRate, .runningPower, .activeEnergyBurned]
```

### 3. Create a Training Season

```swift
let season = CadenceTrainingSeason(seasonInterval: CadenceTrainingWeekRange(
    startDate: Date().addingTimeInterval(-30 * 24 * 3600), // 30 days ago
    endDate: Date()
)) {
    CadenceTrainingPhase(id: UUID(),
                  activityType: .running,
                  phaseType: .building,
                  trainingWeekRange: CadenceTrainingWeekRange(startDate: startDate, endDate: endDate))
}
```

### 4. Calculate Metrics

```swift
let averagePowerMetric = AveragePowerMetric()

do {
    let result = try await averagePowerMetric.compute(
        from: [HKHealthStore()], // Your data stores
        in: season
    )
    
    print("Average Power: \(result.measurment)")
} catch {
    print("Calculation failed: \(error)")
}
```

## Core Components

### Activity Options

Supported activity types:

```swift
ActivityOptions.running
ActivityOptions.cycling
ActivityOptions.swimming
ActivityOptions.strength
ActivityOptions.functional
ActivityOptions.yoga
ActivityOptions.core
```

### Metric Options

Available metrics:

```swift
// Vitals
MetricOptions.heartRate
MetricOptions.restingHeartRate
MetricOptions.heartVariability

// Activity Performance
MetricOptions.runningPower
MetricOptions.runningSpeed
MetricOptions.runningStrideLength
MetricOptions.distanceWalkingRunning

// Energy
MetricOptions.activeEnergyBurned
MetricOptions.basalEnergyBurned

// Training Load
MetricOptions.trimp
```

### Training Query System

Build complex queries using the training query builder:

```swift
let query = TrainingQuery(id: UUID()) {
    CadenceTrainingSeason(seasonInterval: interval) {
        CadenceTrainingPhase(id: UUID(), activityType: .running, phaseType: .peak, trainingWeekRange: range)
    }
    ActivityTargetComponent(id: UUID(), activityTarget: .running) {
        MetricTargetComponent(id: UUID(), metricTarget: .heartRate)
        MetricTargetComponent(metricTarget: .runningPower)
    }
}
```

#### Fetching Query Results

Use queries with any CadenceStore to fetch data in two formats:

**Flat Array Results:**
```swift
let healthStore = HKHealthStore()
let results: [SampleMetricContainer<UnitPower>] = try await healthStore.fetch(query: query)

// Access individual samples
for sample in results {
    print("\(sample.activity): \(sample.metric) = \(sample.measurment)")
}
```

**Organized Hierarchical Results:**
```swift
let organizedResults = try await healthStore.fetchOrganized(query: query)

// Access data by season → activity → metric
if let runningHeartRate = organizedResults[season]?[.running]?[.heartRate] {
    for sample in runningHeartRate {
        print("Heart Rate: \(sample.measurment)")
    }
}

if let runningPower = organizedResults[season]?[.running]?[.runningPower] {
    for sample in runningPower {
        print("Power: \(sample.measurment)")
    }
}
```

The hierarchical format makes it easy to organize results when working with complex queries that span multiple activities and metrics.

## HealthKit Integration

Cadence provides automatic HealthKit integration when available:

```swift
import HealthKit

let healthStore = HKHealthStore()

// Request authorization
try await healthStore.requestAuthorization(
    for: [.heartRate, .runningPower], 
    options: [.read]
)

// Use in metric calculations
let metric = AveragePowerMetric()
let result = try await metric.compute(from: [healthStore], in: season)
```

## App Intents Support

Create Siri shortcuts and iOS automations:

```swift
import AppIntents

struct AveragePowerMetricIntent: AppIntent {
    @Parameter(title: "Start Date")
    var startDate: Date
    
    @Parameter(title: "End Date") 
    var endDate: Date
    
    static let title: LocalizedStringResource = "Calculate Average Power"
    
    func perform() async throws -> some IntentResult {
        let metric = AveragePowerMetric()
        let season = CadenceTrainingSeason(seasonInterval: .init(startDate: startDate, endDate: endDate)) {}
        
        let result = try await metric.compute(from: [], in: season)
        return .result(value: result.convertToAppEntity())
    }
}
```

## Athlete Profiles

Cadence provides a centralized athlete model that automatically fetches physiological data from connected stores, making fitness calculations more personalized and easier to use.

### Creating an Athlete Profile

```swift
let athlete = CadenceAthlete(
    name: "Sarah Runner",
    biologicalGender: .female,
    dateOfBirth: Date(timeIntervalSince1970: 646704000), // June 1990
    height: Measurement(value: 168, unit: .centimeters),
    weight: Measurement(value: 62, unit: .kilograms),
    stores: [healthStore, garminStore] // Your data sources
)

// Computed properties
print("Age: \(athlete.age ?? 0) years")
print("BMI: \(athlete.bmi ?? 0.0) (\(athlete.bmiCategory?.description ?? "Unknown"))")
```

### Automatic Physiological Data Fetching

```swift
// Automatically fetched from connected stores
let restingHR = try await athlete.restingHeartRate  // From .restingHeartRate metric
let maxHR = try await athlete.maxHeartRate          // From historical .heartRate analysis
let zones = try await athlete.heartRateZones()     // 5-zone training system

// Fallback to age-based estimates when store data unavailable
let estimatedMaxHR = athlete.estimatedMaxHeartRate // 220 - age formula
```

### Training Zones

```swift
if let zones = try await athlete.heartRateZones() {
    print("Zone 1 (\(zones.zone1.name)): \(Int(zones.zone1.lowerBound))-\(Int(zones.zone1.upperBound)) bpm")
    print("Zone 2 (\(zones.zone2.name)): \(Int(zones.zone2.lowerBound))-\(Int(zones.zone2.upperBound)) bpm")
    // ... zones 3-5
    
    // Check which zone a heart rate falls into
    if let zone = zones.zoneFor(heartRate: 150) {
        print("150 bpm is in \(zone.name)")
    }
}
```

## TRIMP (Training Impulse) Metrics

Cadence includes comprehensive TRIMP calculation support with multiple scientific methods, unit conversions between them, and seamless athlete profile integration.

### Available TRIMP Methods

```swift
// Using athlete profiles (recommended)
let athlete = CadenceAthlete(name: "John", stores: [healthStore])

let banisterTRIMP = BanisterTRIMPMetric(athlete: athlete)    // Exponential formula
let edwardsTRIMP = EdwardsTRIMPMetric(athlete: athlete)      // 5-zone approach  
let trainingLoad = TrainingLoadMetric(athlete: athlete)     // Acute:Chronic ratio

// Manual parameters (backwards compatible)
let luciaTRIMP = LuciaTRIMPMetric(lactateThreshold1: 150, lactateThreshold2: 170) // Requires lab data
let manualBanister = BanisterTRIMPMetric(restingHeartRate: 50, maxHeartRate: 185)

// Calculate TRIMP for a training season
let result = try await banisterTRIMP.compute(from: stores, in: season)
print("Banister TRIMP: \(result.measurment.value)")
```

### TRIMP Method Conversions

Convert between different TRIMP calculation methods using built-in unit conversions:

```swift
// Create measurements using method-specific units
let banisterValue = Measurement(value: 150.0, unit: UnitTRIMP.banisterTRIMP)
let edwardsValue = Measurement(value: 100.0, unit: UnitTRIMP.edwardsTRIMP)

// Convert between methods
let banisterToEdwards = banisterValue.converted(to: .edwardsTRIMP)
let edwardsToBanister = edwardsValue.converted(to: .banisterTRIMP)

print("Banister 150 → Edwards: \(banisterToEdwards.formatted())")
print("Edwards 100 → Banister: \(edwardsToBanister.formatted())")

// Convert to common base unit (intensity-weighted minutes)
let baseUnit = banisterValue.converted(to: .trimp)
print("Base intensity: \(baseUnit.formatted())")
```

### Advanced TRIMP Conversions

Use polynomial fitting for more accurate conversions based on your specific data:

```swift
// Create polynomial converter with custom coefficients
let polynomialConverter = PolynomialTRIMPConverter(
    method: .banister,
    coefficients: [10.0, 1.3, 0.002] // y = 10 + 1.3x + 0.002x²
)

let customUnit = UnitTRIMP(symbol: "Custom-TRIMP", converter: polynomialConverter)
let measurement = Measurement(value: 100.0, unit: customUnit)
let converted = measurement.converted(to: .banisterTRIMP)
```

### Training Analysis with TRIMP

Compare training loads across different calculation methods:

```swift
// Weekly training analysis
let weeklyEdwardsTRIMP = [120.0, 95.0, 140.0, 110.0, 130.0, 85.0, 160.0]

for (day, value) in weeklyEdwardsTRIMP.enumerated() {
    let edwardsMeasurement = Measurement(value: value, unit: UnitTRIMP.edwardsTRIMP)
    let banisterEquivalent = edwardsMeasurement.converted(to: .banisterTRIMP)
    
    print("Day \(day + 1): Edwards \(edwardsMeasurement.formatted()) → Banister \(banisterEquivalent.formatted())")
}

// Training load ratio analysis
let trainingLoadResult = try await trainingLoad.compute(from: stores, in: season)
let ratio = trainingLoadResult.measurment.value

if ratio < 0.8 {
    print("Low training stress - can increase load")
} else if ratio > 1.3 {
    print("High training stress - consider recovery")
} else {
    print("Optimal training stress zone")
}
```

### App Intents with TRIMP

Create Siri shortcuts for TRIMP calculations:

```swift
// Convert TRIMP results to App Intent entities
let trimpResult = try await banisterTRIMP.compute(from: stores, in: season)
let entity = trimpResult.convertToTRIMPAppEntity(trimpType: .banister)

// Use in App Intent responses
return .result(value: entity)
```

## Custom Metric Calculations

Implement your own metrics by conforming to `CadenceMetricCalc`:

```swift
struct CustomHeartRateMetric: CadenceMetricCalc {
    let id = UUID()
    var description: String { "Custom Heart Rate Analysis" }
    
    var activities: ActivityOptions { .running }
    var metrics: MetricOptions { .heartRate }
    
    func compute(from stores: [CadenceStore], in season: CadenceTrainingSeason) async throws -> some SampleMetric<UnitFrequency> {
        // Your custom calculation logic here
        let heartRateData = try await fetchData(from: stores, in: season)
        let customValue = performAnalysis(on: heartRateData)
        
        return .result(
            activity: activities,
            metric: metrics,
            startDate: season.startDate,
            endDate: season.endDate,
            value: customValue,
            unit: UnitFrequency.beatsPerMinute
        )
    }
}
```

## Error Handling

Cadence provides specific error types for different failure scenarios:

```swift
do {
    let result = try await metric.compute(from: stores, in: season)
} catch CadenceError.noSupportedActivities(let activities) {
    print("No stores support activities: \(activities)")
} catch CadenceError.noSupportedMetrics(let metrics) {
    print("No stores support metrics: \(metrics)")
} catch {
    print("Other error: \(error)")
}
```

## Testing

Run the test suite:

```bash
swift test
```

## Platform Compatibility

Cadence uses conditional compilation to ensure compatibility across platforms:

- **HealthKit**: Only available on iOS/macOS
- **App Intents**: iOS 16.0+ / macOS 13.0+
- **Core Framework**: Works on all supported platforms

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes with tests
4. Run `swift test` to ensure everything passes
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For questions, issues, or feature requests, please open an issue on GitHub.