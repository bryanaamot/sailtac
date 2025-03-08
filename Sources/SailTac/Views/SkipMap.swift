//
//  SkipMap.swift
//  sail-tac
//
//  Created by Bryan Aamot on 1/28/25.
//


//
//  Map.swift
//  skip-map
//
//  Created by Bryan Aamot on 1/25/25.
//

import SwiftUI

#if SKIP
import com.google.maps.android.compose.__
import com.google.android.gms.maps.model.__

public struct Marker: View {
    let title: String
    let coordinate: CLLocationCoordinate2D
    let onClick: (() -> Void)?
    public init(_ title: String, coordinate: CLLocationCoordinate2D, onClick: @escaping (() -> Void)? = nil) {
        self.title = title
        self.onClick = onClick
        self.coordinate = coordinate
    }
    
    public var body: some View {
        ComposeView(content: { _ in
            com.google.maps.android.compose.Marker(
                title = title,
                state = MarkerState(position = LatLng(coordinate.latitude, coordinate.longitude)),
                onClick = { marker in
                    guard let onClick else { return false }
                    onClick()
                    return true
                }
            )
        })
    }
}

public struct Annotation<Content> : View where Content : View {
    let title: String
    let coordinate: CLLocationCoordinate2D
    let content: () -> Content

    public init(_ title: String, coordinate: CLLocationCoordinate2D, @ViewBuilder content: () -> Content) {
        self.title = title
        self.coordinate = coordinate
        self.content = content
    }

    public var body: some View {
        ComposeView(content: { _ in
            content().Compose(composectx)
        })
    }
}

public struct Map<Content> : View where Content: View {
    @Binding var mapCameraPosition: MapCameraPosition
    var bounds: MapCameraBounds?
    var interactionModes: MapInteractionModes
    
    let content: () -> Content
    
    public init(position: Binding<MapCameraPosition>, interactionModes: MapInteractionModes = MapInteractionModes.all, @ViewBuilder content: () -> Content) {
        _mapCameraPosition = position
        self.interactionModes = interactionModes
        self.content = content
    }
    
    public var body: some View {
        let latitude = mapCameraPosition.mapRegion!.center.latitude
        let longitude = mapCameraPosition.mapRegion!.center.longitude
        let cameraPositionState: CameraPositionState = rememberCameraPositionState {
            position = CameraPosition.fromLatLngZoom(LatLng(latitude, longitude), Float(12.0)) // TODO: pass zoom
        }
        let mapProperties: MapProperties = remember {
            MapProperties(mapType = MapType.TERRAIN) // TODO: pass maptype
        }
        let zoomControlsEnabled = interactionModes.contains(MapInteractionModes.zoom)
        let rotationGesturesEnabled = interactionModes.contains(MapInteractionModes.rotate)
        let settings = MapUiSettings(
            zoomControlsEnabled = zoomControlsEnabled,
            myLocationButtonEnabled = true, // TODO: pass this instead?
            compassEnabled = true, // TODO: pass this instead?
            rotationGesturesEnabled = rotationGesturesEnabled
        )
        
        ComposeView { _ in
            GoogleMap(
                cameraPositionState = cameraPositionState,
                uiSettings = settings,
                properties = mapProperties
            ) {
                content().Compose(composectx)
            }
        }
    }
}
#endif
