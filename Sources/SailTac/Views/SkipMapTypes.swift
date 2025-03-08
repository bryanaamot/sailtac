//
//  SkipMapTypes.swift
//  sail-tac
//
//  Created by Bryan Aamot on 1/28/25.
//

#if SKIP
// TODO: These should really be apart of CoreLocation
public typealias CLLocationDegrees = Double
public typealias CLLocationDistance = Double

public struct CLLocationCoordinate2D {
    public var latitude: CLLocationDegrees
    public var longitude: CLLocationDegrees
    public init() {
        latitude = 0.0
        longitude = 0.0
    }
    public init(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

public struct MKCoordinateSpan {
    public var latitudeDelta: CLLocationDegrees
    public var longitudeDelta: CLLocationDegrees
    public init() {
        latitudeDelta = CLLocationDegrees(0.0)
        longitudeDelta = CLLocationDegrees(0.0)
    }
    public init(latitudeDelta: CLLocationDegrees, longitudeDelta: CLLocationDegrees) {
        self.latitudeDelta = latitudeDelta
        self.longitudeDelta = longitudeDelta
    }
}

public struct MKCoordinateRegion {
    public var center: CLLocationCoordinate2D
    public var span: MKCoordinateSpan
    public init() {
        center = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
        span = MKCoordinateSpan(latitudeDelta: 0.0, longitudeDelta: 0.0)
    }
    
    public /*not inherited*/ init(center centerCoordinate: CLLocationCoordinate2D, latitudinalMeters: CLLocationDistance, longitudinalMeters: CLLocationDistance) {
        self.center = center
        self.span = MKCoordinateSpan(latitudeDelta: latitudinalMeters, longitudeDelta: longitudinalMeters)
    }

    public init(center: CLLocationCoordinate2D, span: MKCoordinateSpan) {
        self.center = center
        self.span = span
    }
}

public struct MapCameraPosition : Equatable {
    public var mapRegion: MKCoordinateRegion?
    
    public static func region(_ region: MKCoordinateRegion) -> MapCameraPosition {
        return MapCameraPosition(mapRegion: region)
    }
}

public struct MapCameraBounds {
    var x: Double
}

public struct MapInteractionModes: OptionSet {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public static let pan = MapInteractionModes(rawValue: 1 << 0)
    public static let zoom = MapInteractionModes(rawValue: 1 << 1)
    public static let rotate = MapInteractionModes(rawValue: 1 << 2)
    public static let pinch = MapInteractionModes(rawValue: 1 << 3)
    public static let all = MapInteractionModes(rawValue: 0x0F)
}
#endif
