//
//  Bearing.swift
//  sail-tac
//
//  Created by Bryan Aamot on 1/12/25.
//
import Foundation

let knotsToMetersPerSecond = 0.514444 // 1 knot = 0.514444 m/s
let earthRadiusMeters = 6371009.0 // Earth's radius in meters

struct Bearing {
    
    static func minus180To180(_ angle: Double) -> Int {
        let intAngle = Int(angle)
        return ((intAngle + 180) % 360 + 360) % 360 - 180
    }
    
    /// distance from (lat1, lon1) to (lat2, lon2)
    static func distanceToLocation(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        // Convert degrees to radians
        let φ1 = lat1 * .pi / 180.0
        let φ2 = lat2 * .pi / 180.0
        let Δφ = (lat2 - lat1) * .pi / 180.0
        let Δλ = (lon2 - lon1) * .pi / 180.0
        
        // Haversine formula
        let a = sin(Δφ / 2.0) * sin(Δφ / 2.0) + cos(φ1) * cos(φ2) * sin(Δλ / 2.0) * sin(Δλ / 2.0)
        let c = 2 * atan2(sqrt(a), sqrt(1.0 - a))
        
        let distance = earthRadiusMeters * c // Distance in meters
        return distance
    }
    
    /// bearing from (lat1, lon1) to (lat2, lon2)
    static func bearingToLocation(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let φ1 = lat1 * .pi / 180.0
        let φ2 = lat2 * .pi / 180.0
        let Δλ = (lon2 - lon1) * .pi / 180.0
        
        let y = sin(Δλ) * cos(φ2)
        let x = cos(φ1) * sin(φ2) - sin(φ1) * cos(φ2) * cos(Δλ)
        let bearing = atan2(y, x) // Result in radians
        return bearing * 180.0 / .pi
    }
    
    /// (lat, lon)  from (lat, lon) using distance and angle
    static func locationUsingBearing(lat: Double, lon: Double, distance: Double, angle: Double) -> (lat: Double, lon: Double) {
        let φ1 = lat * .pi / 180.0
        let λ1 = lon * .pi / 180.0
        
        let θ = angle * .pi / 180.0 // Convert angle to radians
        let δ = distance / earthRadiusMeters // Angular distance in radians
        
        // Correct formula for latitude
        let φ2 = asin(sin(φ1) * cos(δ) + cos(φ1) * sin(δ) * cos(θ))
        
        // Correct formula for longitude
        let λ2 = λ1 + atan2(sin(θ) * sin(δ) * cos(φ1), cos(δ) - sin(φ1) * sin(φ2))
        
        // Convert back to degrees
        let newLat = φ2 * 180.0 / .pi
        let newLon = λ2 * 180.0 / .pi
        return (lat: newLat, lon: newLon)
    }
    
    static func lines(wind: Double, marks: [Mark]) -> [[LatLon]] {
        var lines = [[LatLon]]()
        for mark in marks {
            if let parent = marks.first(where: { $0.id == mark.parent }) {
                let distance = Bearing.distanceToLocation(lat1: parent.latitude, lon1: parent.longitude, lat2: mark.latitude, lon2: mark.longitude)
                let angle = Bearing.bearingToLocation(lat1: parent.latitude, lon1: parent.longitude, lat2: mark.latitude, lon2: mark.longitude)
                let relativeBearing = angle - wind
                let (lat, _) = Bearing.locationUsingBearing(lat: parent.latitude, lon: parent.longitude, distance: distance, angle: relativeBearing)
                let d1 = Bearing.distanceToLocation(lat1: parent.latitude, lon1: parent.longitude, lat2: lat, lon2: parent.longitude)
                let normalizedBearing = ((Int(relativeBearing) + 180) % 360 + 360) % 360 - 180
                let bearing = normalizedBearing > -90 && normalizedBearing < 90 ? wind : wind + 180.0
                let (lat1, lon1) = Bearing.locationUsingBearing(lat: parent.latitude, lon: parent.longitude, distance: d1, angle: bearing)
                
                let parentCoord = LatLon(lat: parent.latitude, lon: parent.longitude)
                let legCoord = LatLon(lat: lat1, lon: lon1)
                let markCoord = LatLon(lat: mark.latitude, lon: mark.longitude)
                lines.append([parentCoord, legCoord])
                lines.append([legCoord, markCoord])
            }
        }
        return lines
    }
    
    static func markMoveDetails(mark: Mark, marks: [Mark], wind: Double, latitude: Double, longitude: Double) -> String {
        var moveDetails = ""
        if mark.type == .fixed {
            moveDetails = """
            \(String(format: "%.4f", latitude)), \(String(format: "%.4f", longitude))
            """
        } else {
            let meters = AppData.markDistance(marks: marks, parentId: mark.parent, wind: wind, latitude: latitude, longitude: longitude)
            let normalizedBearing = AppData.markBearing(marks: marks, parentId: mark.parent, wind: wind, latitude: latitude, longitude: longitude)
            let measurement = Measurement(value: meters, unit: UnitLength.meters)
            let feet = measurement.converted(to: UnitLength.feet).value
            let distanceString: String
            if feet > 550 {
                let km = String(format: "%.2f", meters / 1000.0)
                let miles = String(format: "%.2f", feet / 5280.0)
                distanceString = "\(miles)\(UnitLength.miles.symbol) (\(km)\(UnitLength.kilometers.symbol))"
            } else {
                let metersString = String(format: "%.2f", meters)
                let feetString = String(format: "%.2f", feet)
                distanceString = "\(feetString)\(UnitLength.feet.symbol) (\(metersString)\(UnitLength.meters.symbol))"
            }
            
            moveDetails = """
            \(normalizedBearing)º
            \(distanceString)
            \(String(format: "%.4f", latitude)), \(String(format: "%.4f", longitude))
            """
        }
        return moveDetails
    }
}
