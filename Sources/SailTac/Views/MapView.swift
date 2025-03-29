//
//  MapView.swift
//  sail-tac
//
//  Created by Bryan Aamot on 1/18/25.
//

import SwiftUI

#if !SKIP
import MapKit

struct MapView : View {
    @Binding var mapType: MyMapType
    @Binding var wind: Double
    @Binding var marks: [Mark]
    @Binding var latitude: Double
    @Binding var longitude: Double
    @Binding var showEditMark: Bool
    @Binding var editMarkIndex: Int
    @Binding var showMoveDetails: Bool
    @Binding var moveDetails: String
    var finishedDragging: (() -> Void)
    @State var errorString = ""
    @EnvironmentObject private var appData: AppData
    @State private var mapCameraPosition: MapCameraPosition
    
    init(mapType: Binding<MyMapType>, wind: Binding<Double>, marks: Binding<[Mark]>, latitude: Binding<Double>, longitude: Binding<Double>, showEditMark: Binding<Bool>, editMarkIndex: Binding<Int>, showMoveDetails: Binding<Bool>, moveDetails: Binding<String>, finishedDragging: @escaping () -> Void) {
        _mapType = mapType
        _wind = wind
        _marks = marks
        _latitude = latitude
        _longitude = longitude
        _showEditMark = showEditMark
        _editMarkIndex = editMarkIndex
        _showMoveDetails = showMoveDetails
        _moveDetails = moveDetails
        self.finishedDragging = finishedDragging
        mapCameraPosition = .region(.init(center: CLLocationCoordinate2D(latitude: latitude.wrappedValue, longitude: longitude.wrappedValue), latitudinalMeters: 10000.0, longitudinalMeters: 10000.0))
    }
    
    static func convertToCLLocationCoordinate2D(_ latLonArray: [[LatLon]]) -> [[CLLocationCoordinate2D]] {
        return latLonArray.map { innerArray in
            innerArray.map { latLon in
                CLLocationCoordinate2D(latitude: latLon.lat, longitude: latLon.lon)
            }
        }
    }
    
    /// Calculates a new coordinate using an offset on the map
    func adjustCoordinate(using proxy: MapProxy, from coordinate: CLLocationCoordinate2D, to offset: CGSize) -> CLLocationCoordinate2D? {
        if let point = proxy.convert(coordinate, to: .local) {
            let offset = CGPoint(x: offset.width, y: offset.height)
            let newPoint = CGPoint(x: point.x + offset.x, y: point.y + offset.y)
            return proxy.convert(newPoint, from: .local)
        }
        return nil
    }
    
    /// Moves a mark (and it's children) by a map offset
    func handleDrag(mapProxy: MapProxy, markIndex: Int, offset: CGSize) {
        let mark = marks[markIndex]
        let oldLocation = CLLocationCoordinate2D(latitude: mark.latitude, longitude: mark.longitude)
        if let location = adjustCoordinate(using: mapProxy, from: oldLocation, to: offset) {
            moveDetails = Bearing.markMoveDetails(mark: mark, marks: marks, wind: wind, latitude: location.latitude, longitude: location.longitude)

            marks[markIndex].latitude = location.latitude
            marks[markIndex].longitude = location.longitude
            
            if mark.type == .fixed {
                for (childIndex, child) in marks.enumerated() {
                    if child.parent == mark.id {
                        let childLocation = CLLocationCoordinate2D(latitude: child.latitude, longitude: child.longitude)
                        if let newCoord = adjustCoordinate(using: mapProxy, from: childLocation, to: offset) {
                            marks[childIndex].latitude = newCoord.latitude
                            marks[childIndex].longitude = newCoord.longitude
                        }
                    }
                }
            }
        }
    }
    
    var body: some View {
        // on Darwin platforms, we use the new SwiftUI Map type
        if #available(iOS 17.0, macOS 14.0, *) {
            if errorString != "" {
                Text(errorString)
                    .foregroundStyle(Color.red)
            }
            MapReader { mapProxy in
                Map(position: $mapCameraPosition) {
                    // Draw lines under marks
                    let latLonArray = Bearing.lines(wind: wind, marks: marks)
                    let lines = Self.convertToCLLocationCoordinate2D(latLonArray)
                    ForEach(lines.indices, id: \.self) { index in
                        MapPolyline(coordinates: lines[index])
                            .stroke(.white, style: StrokeStyle(lineWidth: 1, dash: [3]))
                        MapPolyline(coordinates: lines[index])
                            .stroke(.black, style: StrokeStyle(lineWidth: 1, dash: [3], dashPhase: 3))
                    }
                    
                    // Draw marks
                    ForEach(marks.indices, id: \.self) { index in
                        let mark = marks[index]
                        let markCoord = CLLocationCoordinate2D(latitude: mark.latitude, longitude: mark.longitude)
                        Annotation(mark.name, coordinate: markCoord, anchor: .center) {
                            MarkAnnotation(
                                tap: {
                                    editMarkIndex = index
                                    showEditMark = true
                                },
                                drag: { dragOffset in
                                    showMoveDetails = true
                                    handleDrag(mapProxy: mapProxy, markIndex: index, offset: dragOffset)
                                },
                                update: { dragOffset in
                                    showMoveDetails = false
                                    handleDrag(mapProxy: mapProxy, markIndex: index, offset: dragOffset)
                                    finishedDragging()
                                }
                            )
                        }
                    }

                    // Draw boats
                    ForEach(Array(appData.locations), id: \.key) { id, location in
                        let coordinate = CLLocationCoordinate2D(latitude: location.coordinate.lat, longitude: location.coordinate.lon)
                        Annotation(location.name, coordinate: coordinate, anchor: .center) {
                            Path { path in
                                // Define a triangle pointing upwards
                                path.move(to: CGPoint(x: 0, y: -10)) // Top point
                                path.addLine(to: CGPoint(x: -5, y: 5)) // Bottom-left point
                                path.addLine(to: CGPoint(x: 5, y: 5)) // Bottom-right point
                                path.closeSubpath()
                            }
                            .fill(Color.blue)
                            .rotationEffect(.degrees(location.heading))
                        }
                    }
                }
                .mapControls {
                    MapUserLocationButton()
                    MapScaleView()
                }
                .mapStyle(
                    mapType == .standard ? .standard(elevation: .realistic, emphasis: .automatic) :
                    mapType == .satellite ? .imagery :
                            .hybrid)
                .onMapCameraChange(frequency: .continuous) { context in
                    latitude = context.region.center.latitude
                    longitude = context.region.center.longitude
                }
//                .onChange(of: latitude) { oldLat, newLat in
//                    updateMapCenter(lat: newLat)
//                }
//                .onChange(of: longitude) { oldLon, newLon in
//                    updateMapCenter(lon: newLon)
//                }
            }
        } else {
            Text("Map requires iOS 17")
                .font(.title)
        }
    }
    
//    func updateMapCenter(lat: Double = 0.0, lon: Double = 0.0) {
//        if abs(lat) > 1E-05 || abs(lon) > 1E-05 {
//            let point = CLLocationCoordinate2D(
//                latitude: lat != 0 ? lat : latitude,
//                longitude: lon != 0 ? lon : longitude)
//            let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
//            mapCameraPosition = .region(
//                .init(center: point, span: span))
//        }
//    }
}


@available(iOS 17.0, *)
struct MarkAnnotation: View {
    var tap: (() -> Void)
    var drag: ((_ dragOffset: CGSize) -> Void)
    var update: ((_ dragOffset: CGSize) -> Void)
    let size = 30.0
    
    @State var isDragging = false
    @State var dragOffset = CGSize.zero
    @State private var animationScale: CGFloat = 1.0

    var body: some View {
        ZStack(alignment: .center) {
            Circle()
                .stroke(Color.orange, lineWidth: 4) // Orange stroke
                .background(Circle().fill(Color.orange.opacity(0.3)))
                .frame(width: size, height: size)
                .padding(30) // Expands touchable area without changing visible size
                .contentShape(Circle())
//                .animation(.snappy, body: { content in
//                    content
//                        .scaleEffect (isDragging ? 3.0 : 1, anchor: .center)
//                })
                .offset(dragOffset)
                .gesture (
                    LongPressGesture(minimumDuration: 0.25)
                        .onEnded {
                            isDragging = $0
                        }
                        .simultaneously(with: DragGesture (minimumDistance: 0)
                            .onChanged { value in
                                if isDragging {
                                    dragOffset = value.translation
                                    drag(dragOffset)
                                }
                            }
                            .onEnded { value in
                                if isDragging {
                                    isDragging = false
                                    update(dragOffset)
                                    dragOffset = .zero
                                }
                            }
                        )
                        .simultaneously(with: TapGesture()
                            .onEnded {
                               tap()
                            }
                        )
                )
            if isDragging {
                RadarCircle()
            }
        }
    }
}


#endif

struct RadarCircle: View {
    @State private var scale = 0.0
    let size = 50.0
    
    var size1: Double {
        scale * size
    }

    var size2: Double {
        return (scale + 1.0) * size
    }

    var size3: Double {
        return (scale + 2.0) * size
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.orange, lineWidth: 2.0)
                .frame(width: size1, height: size1)
                .opacity(1.0 - (size1/size/3.0))
            Circle()
                .stroke(Color.orange, lineWidth: 2.0)
                .frame(width: size2, height: size2)
                .opacity(0.666 - (size1/size/3.0))
            Circle()
                .stroke(Color.orange, lineWidth: 2.0)
                .frame(width: size3, height: size3)
                .opacity(0.333 - (size1/size/3.0))
        }
        .animation(Animation.linear(duration: 0.75).repeatForever(autoreverses: false), value: scale)
        .onAppear {
            scale = 1.0
        }
    }
}

#Preview(body: {
    RadarCircle()
})
