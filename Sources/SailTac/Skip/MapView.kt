package sail.tac

import skip.lib.*
import skip.lib.Array
import skip.ui.*
import com.google.maps.android.compose.*
import com.google.maps.android.compose.GoogleMap
import com.google.maps.android.compose.Marker
import com.google.maps.android.compose.MarkerState
import com.google.maps.android.compose.rememberCameraPositionState
import com.google.android.gms.maps.model.BitmapDescriptorFactory
import com.google.android.gms.maps.model.CameraPosition
import com.google.android.gms.maps.model.LatLng
import com.google.android.gms.maps.model.Marker as MapMarker
import android.graphics.Bitmap
import android.graphics.Canvas
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.core.content.ContextCompat
import com.google.android.gms.maps.GoogleMap
import com.google.android.gms.maps.model.Dash
import com.google.android.gms.maps.model.Gap
import com.google.android.gms.maps.model.MapStyleOptions
import com.google.android.gms.maps.model.PatternItem
import skip.foundation.*

val dashedPattern1 = listOf<PatternItem>(Dash(30f), Gap(20f))
val dashedPattern2 = listOf<PatternItem>(Gap(20f), Dash(30f))

internal class MapView(
    mapType: Binding<MyMapType>,
    wind: Binding<Double>,
    marks: Binding<Array<Mark>>,
    latitude: Binding<Double>,
    longitude: Binding<Double>,
    showEditMark: Binding<Boolean>,
    editMarkIndex: Binding<Int>,
    showMoveDetails: Binding<Boolean>,
    moveDetails: Binding<String>,
    private val finishedDragging: () -> Unit
) : View {
    private var mapType: MyMapType
        get() = _mapType.wrappedValue
        set(newValue) { _mapType.wrappedValue = newValue }
    private var _mapType: Binding<MyMapType> = mapType

    private var wind: Double
        get() = _wind.wrappedValue
        set(newValue) { _wind.wrappedValue = newValue }
    private var _wind: Binding<Double> = wind

    private var marks: Array<Mark>
        get() = _marks.wrappedValue.sref { this.marks = it }
        set(newValue) { _marks.wrappedValue = newValue.sref() }
    private var _marks: Binding<Array<Mark>> = marks

    private var latitude: Double
        get() = _latitude.wrappedValue
        set(newValue) { _latitude.wrappedValue = newValue }
    private var _latitude: Binding<Double> = latitude

    private var longitude: Double
        get() = _longitude.wrappedValue
        set(newValue) { _longitude.wrappedValue = newValue }
    private var _longitude: Binding<Double> = longitude

    private var showEditMark: Boolean
        get() = _showEditMark.wrappedValue
        set(newValue) { _showEditMark.wrappedValue = newValue }
    private var _showEditMark: Binding<Boolean> = showEditMark

    private var editMarkIndex: Int
        get() = _editMarkIndex.wrappedValue
        set(newValue) { _editMarkIndex.wrappedValue = newValue }
    private var _editMarkIndex: Binding<Int> = editMarkIndex

    private var showMoveDetails: Boolean
        get() = _showMoveDetails.wrappedValue
        set(newValue) { _showMoveDetails.wrappedValue = newValue }
    private var _showMoveDetails: Binding<Boolean> = showMoveDetails

    private var moveDetails: String
        get() = _moveDetails.wrappedValue
        set(newValue) { _moveDetails.wrappedValue = newValue }
    private var _moveDetails: Binding<String> = moveDetails

    val darkModeStyleJson = """
        [
          {
            "elementType": "geometry",
            "stylers": [
              { "color": "#086E6E" }
            ]
          },
          {
            "elementType": "labels.text.stroke",
            "stylers": [
              { "color": "#666666" }
            ]
          },
          {
            "elementType": "labels.text.fill",
            "stylers": [
              { "color": "#CCCCCC" }
            ]
          },
          {
            "featureType": "water",
            "elementType": "geometry",
            "stylers": [
              { "color": "#1D3377" }
            ]
          }
        ]
    """.trimIndent()

    @OptIn(MapsComposeExperimentalApi::class)
    override fun body(): View {
        return ComposeBuilder { compose: ComposeContext ->
            ComposeView {
                val cameraPositionState: CameraPositionState = rememberCameraPositionState {
                    position = CameraPosition.fromLatLngZoom(LatLng(latitude, longitude), 12.0f)
                }
                val mapProperties: MapProperties = remember(mapType) {
                    MapProperties(
                        mapType = when (mapType) {
                            MyMapType.standard -> MapType.NORMAL
                            MyMapType.hybrid -> MapType.HYBRID
                            else -> MapType.SATELLITE
                        },
                        mapStyleOptions = MapStyleOptions(darkModeStyleJson)
                    )
                }
                GoogleMap(
                    cameraPositionState = cameraPositionState,
                    uiSettings = MapUiSettings(
                        zoomControlsEnabled = true,
                        myLocationButtonEnabled = true,
                        compassEnabled = true,
                        rotationGesturesEnabled = false,
                    ),
                    properties = mapProperties
                ) {
                    marks.forEach { mark ->
                        Marker(
                            state = MarkerState(position = LatLng(mark.latitude, mark.longitude)),
                            icon = BitmapDescriptorFactory.fromBitmap(
                                        getBitmapFromDrawable("circle_marker", 120, 120)
                                    ),
                            title = mark.name,
                            draggable = true,
                            tag = mark.id,
                            anchor = Offset(0.5f, 0.5f)
                        )
                    }

                    val lines = Bearing.lines(wind = wind, marks = marks)
                    lines.forEach { line ->
                        val points = line.toList().map { LatLng(it.lat, it.lon) }
                        Polyline(
                            points = points,
                            color = Color.White,
                            width = 10f,
                            pattern = dashedPattern1
                        )
                        Polyline(
                            points = points,
                            color = Color.Black,
                            width = 10f,
                            pattern = dashedPattern2
                        )
                    }

                    val marksArray = Array(marks.count) { index -> marks[index] }
                    MapEffect(keys = marksArray) { googleMap ->
                        googleMap.setOnMarkerDragListener(object : GoogleMap.OnMarkerDragListener {
                            override fun onMarkerDragStart(marker: MapMarker) {
                                marker.position = marker.position
                                showMoveDetails = true
                            }

                            override fun onMarkerDrag(marker: MapMarker) {
                                // Optional: Handle during drag
                                val markId = marker.tag as? String
                                markId?.let { id ->
                                    val index = marks.indexOfFirst { it.id == id }
                                    if (index >= 0) {
                                        handleDrag(marks = marks, index = index, marker = marker)
                                    }
                                }
                            }

                            override fun onMarkerDragEnd(marker: MapMarker) {
                                showMoveDetails = false
                                moveDetails = ""
                                val markId = marker.tag as? String
                                markId?.let { id ->
                                    val index = marks.indexOfFirst { it.id == id }
                                    if (index >= 0) {
                                        handleDrag(marks = marks, index = index, marker = marker)
                                        finishedDragging()
                                    }
                                }
                            }
                        })
                        // Handle marker click events to trigger edit mode
                        googleMap.setOnMarkerClickListener { marker ->
                            val markId = marker.tag as? String
                            markId?.let { id ->
                                val index = marks.indexOfFirst { it.id == id }
                                if (index >= 0) {
                                    editMarkIndex = index
                                    showEditMark = true
                                }
                            }
                            true // Return true to indicate the event was handled
                        }

                        // Handle map clicks to close edit mode
                        googleMap.setOnMapClickListener { latLng ->
                            showEditMark = false
                        }
                    }
                }
                LaunchedEffect(cameraPositionState.position) {
                    val position = cameraPositionState.position
                    latitude = position.target.latitude
                    longitude = position.target.longitude
                }

            }.Compose(compose)
        }
    }
    
    private fun handleDrag(marks: Array<Mark>, index: Int, marker: MapMarker) {
        val mark = marks[index]
        moveDetails = Bearing.markMoveDetails(
            mark = marks[index],
            marks = marks,
            wind = wind,
            latitude = marker.position.latitude,
            longitude = marker.position.longitude)

        val deltaLat = marker.position.latitude - marks[index].latitude
        val deltaLng = marker.position.longitude - marks[index].longitude
        marks[index] =
            Mark(id = mark.id,
                type = mark.type,
                name = mark.name,
                latitude = marker.position.latitude,
                longitude = marker.position.longitude,
                parent = mark.parent,
            )

        marks.forEachIndexed { childIndex, child ->
            if (child.parent == mark.id) {
                marks[childIndex] =
                    Mark(id = child.id,
                        type = child.type,
                        name = child.name,
                        latitude = child.latitude + deltaLat,
                        longitude = child.longitude + deltaLng,
                        parent = child.parent,
                    )
            }
        }
    }

    private fun getBitmapFromDrawable(name: String, width: Int, height: Int): Bitmap {
        val activity = UIApplication.shared.androidActivity!!.sref()
        val packageName = activity.application.packageName
        val resId = activity.application.resources.getIdentifier(name, "drawable", packageName)
        val applicationContext = ProcessInfo.processInfo.androidContext.sref()
        val drawable = ContextCompat.getDrawable(applicationContext, resId)
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        drawable?.run {
            setBounds(0, 0, canvas.width, canvas.height)
            draw(canvas)
        }
        return bitmap.sref()
    }

}
