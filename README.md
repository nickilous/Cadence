# Cadence

A Swift package for fitness metric calculations and training data analysis, with built-in support for HealthKit integration and App Intents.

## Features

- 🏃‍♂️ **Activity Tracking**: Support for running, cycling, swimming, strength training, and more
- 📊 **Metric Calculations**: Heart rate, power, distance, energy, and performance metrics
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
    .package(url: "https://github.com/your-username/Cadence.git", from: "1.0.0")
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
let season = TrainingSeason(seasonInterval: TrainingWeekRange(
    startDate: Date().addingTimeInterval(-30 * 24 * 3600), // 30 days ago
    endDate: Date()
)) {
    TrainingPhase(id: UUID(),
                  activityType: .running,
                  phaseType: .building,
                  trainingWeekRange: TrainingWeekRange(startDate: startDate, endDate: endDate))
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
```

### Training Query System

Build complex queries using the training query builder:

```swift
let query = TrainingQuery(id: UUID()) {
    TrainingSeason(seasonInterval: interval) {
        TrainingPhase(id: UUID(), activityType: .running, phaseType: .peak, trainingWeekRange: range)
    }
    ActivityTargetComponent(id: UUID(), activityTarget: .running) {
        MetricTargetComponent(id: UUID(), metricTarget: .heartRate)
        MetricTargetComponent(metricTarget: .runningPower)
    }
}
```

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
        let season = TrainingSeason(seasonInterval: .init(startDate: startDate, endDate: endDate)) {}
        
        let result = try await metric.compute(from: [], in: season)
        return .result(value: result.convertToAppEntity())
    }
}
```

## Custom Metric Calculations

Implement your own metrics by conforming to `MetricCalc`:

```swift
struct CustomHeartRateMetric: MetricCalc {
    let id = UUID()
    var description: String { "Custom Heart Rate Analysis" }
    
    var activities: ActivityOptions { .running }
    var metrics: MetricOptions { .heartRate }
    
    func compute(from stores: [Store], in season: TrainingSeason) async throws -> some SampleMetric<UnitFrequency> {
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