//
//  compassManager.kt
//  sail-tac
//
//  Created by Bryan Aamot on 2/2/25.
//

package sail.tac

import android.hardware.*
import skip.lib.*
import skip.ui.*
import android.content.Context
import skip.foundation.ProcessInfo

class CompassManager(
        var heading: Binding<Double>,
        var latitude: Binding<Double>,
        var longitude: Binding<Double>
    ) : SensorEventListener {
    private val sensorManager: SensorManager = ProcessInfo.processInfo.androidContext.sref().getSystemService(Context.SENSOR_SERVICE) as SensorManager
    private var accelerometerReading = FloatArray(3)
    private var magnetometerReading = FloatArray(3)
    private val accelerometer: Sensor? = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
    private val magnetometer: Sensor? = sensorManager.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD)

    fun start() {
        accelerometer?.let { sensorManager.registerListener(this, it, SensorManager.SENSOR_DELAY_UI) }
        magnetometer?.let { sensorManager.registerListener(this, it, SensorManager.SENSOR_DELAY_UI) }
    }

    fun stop() {
        sensorManager.unregisterListener(this)
    }

    override fun onSensorChanged(event: SensorEvent?) {
        if (event == null) return

        when (event.sensor.type) {
            Sensor.TYPE_ACCELEROMETER -> accelerometerReading = event.values.clone()
            Sensor.TYPE_MAGNETIC_FIELD -> magnetometerReading = event.values.clone()
        }

        val rotationMatrix = FloatArray(9)
        val orientationAngles = FloatArray(3)

        if (SensorManager.getRotationMatrix(rotationMatrix, null, accelerometerReading, magnetometerReading)) {
            SensorManager.getOrientation(rotationMatrix, orientationAngles)
            val azimuth = Math.toDegrees(orientationAngles[0].toDouble()).toFloat()
            heading.wrappedValue = Double((azimuth + 360) % 360) // Ensure 0-360 degrees
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
}
