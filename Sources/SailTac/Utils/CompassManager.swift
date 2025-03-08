//
//  CompassManager.swift
//  sail-tac
//
//  Created by Bryan Aamot on 2/2/25.
//
import SwiftUI

#if !SKIP
import CoreLocation

class CompassManager: NSObject, CLLocationManagerDelegate {
    var heading: Binding<Double>
    var latitude: Binding<Double>
    var longitude: Binding<Double>
    var lastLocationUpdateDate = Date()
    var lastHeadingUpdateDate = Date()
    var lastHeading = 0.0

    private var locationManager = CLLocationManager()

    init(heading: Binding<Double>, latitude: Binding<Double>, longitude: Binding<Double>) {
        self.heading = heading
        self.latitude = latitude
        self.longitude = longitude
        super.init()
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingHeading()
        locationManager.startUpdatingLocation()
        locationManager.distanceFilter = 5 // make sure user moves at least 5 meters before sending an update
    }

    /// Send heading if the user changes it quickly or send small changes no more than once a second.
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let timeInterval = Date().timeIntervalSince(lastHeadingUpdateDate)
        let heading = newHeading.trueHeading
        let headingChange = abs(heading - self.heading.wrappedValue)
        if (timeInterval > 0.5 &&  headingChange > 1) || headingChange > 5 {
            lastHeadingUpdateDate = Date()
            DispatchQueue.main.async {
                self.heading.wrappedValue = heading
//                print("heading: \(heading)")
            }
        }
    }
    
    // Send location updates but not too often
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            let timeInterval = Date().timeIntervalSince(lastLocationUpdateDate)
            if timeInterval > 2 {
                lastLocationUpdateDate = Date()
                DispatchQueue.main.async {
                    self.latitude.wrappedValue = location.coordinate.latitude
                    self.longitude.wrappedValue = location.coordinate.longitude
//                    print("location: \(location.coordinate)")
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.startUpdatingLocation()
            locationManager.startUpdatingHeading()
            
        }
    }
}
#endif
