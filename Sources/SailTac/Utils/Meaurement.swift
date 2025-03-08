//
//  Meaurement.swift
//  sail-tac
//
//  Created by Bryan Aamot on 2/9/25.
//

// Skip doesn't support Measurement or UnitLength yet
#if SKIP

struct UnitLength: Equatable {
    let symbol: String
    let conversionFactorToMeters: Double  // Conversion factor relative to meters

    static let feet = UnitLength(symbol: "ft", conversionFactorToMeters: 0.3048)
    static let meters = UnitLength(symbol: "m", conversionFactorToMeters: 1.0)
    static let miles = UnitLength(symbol: "mi", conversionFactorToMeters: 1609.34)
    static let kilometers = UnitLength(symbol: "km", conversionFactorToMeters: 1000.0)
}

struct Measurement {
    let value: Double
    let unit: UnitLength

    init(value: Double, unit: UnitLength) {
        self.value = value
        self.unit = unit
    }

    func converted(to newUnit: UnitLength) -> Measurement {
        let valueInMeters = self.value * self.unit.conversionFactorToMeters
        let convertedValue = valueInMeters / newUnit.conversionFactorToMeters
        return Measurement(value: convertedValue, unit: newUnit)
    }
}

struct MeasurementFormatter {
    enum UnitStyle {
        case short   // Symbol (e.g., "m", "ft", "km", "mi")
        case long    // Full name (e.g., "meters", "feet", "kilometers", "miles")
    }

    var unitStyle: UnitStyle = .long

    func string(from unit: UnitLength) -> String {
        switch unitStyle {
        case .short:
            return Self.unitSymbols[unit] ?? unit.symbol
        case .long:
            return Self.unitNames[unit] ?? unit.symbol
        }
    }

    private static let unitSymbols: [UnitLength: String] = [
        .meters: "m",
        .feet: "ft",
        .kilometers: "km",
        .miles: "mi"
    ]

    private static let unitNames: [UnitLength: String] = [
        .meters: "meters",
        .feet: "feet",
        .kilometers: "kilometers",
        .miles: "miles"
    ]
}
#endif
