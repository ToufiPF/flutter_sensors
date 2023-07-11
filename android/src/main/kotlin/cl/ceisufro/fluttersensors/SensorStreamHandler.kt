package cl.ceisufro.fluttersensors

import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink
import java.util.*


class SensorStreamHandler(
    private val sensorManager: SensorManager, 
    private val sensorId: Int, 
    interval: Int?,
) : EventChannel.StreamHandler {
    private var delayUs: Int = interval ?: SensorManager.SENSOR_DELAY_NORMAL
    private val sensor: Sensor? = sensorManager.getDefaultSensor(sensorId)
    private var eventSink: EventSink? = null
    private var sensorListener: SensorEventListener? = null

    override fun onListen(arguments: Any?, eventSink: EventSink?) {
        if (sensor != null) {
            this.eventSink = eventSink
            createListener()
        }
    }

    override fun onCancel(arguments: Any?) {
        stopListener()
        eventSink = null
    }

    private fun createListener() {
        eventSink?.let {
            sensorListener = createSensorEventListener(it, sensorId, delayUs)
            sensorManager.registerListener(sensorListener, sensor, delayUs)
        }
    }

    fun stopListener() {
        sensorManager.unregisterListener(sensorListener)
        sensorListener = null
    }

    fun updateInterval(interval: Int?) {
        if (interval != null) {
            delayUs = interval
            stopListener()
            createListener()
        }
    }

    companion object {
        private fun createSensorEventListener(sink: EventSink, sensorId: Int, delayUs: Int) = object : SensorEventListener {
            private var lastUpdate: Calendar = Calendar.getInstance()
            private val customDelay = delayUs > SensorManager.SENSOR_DELAY_NORMAL

            override fun onAccuracyChanged(sensor: Sensor, accuracy: Int) {}
    
            override fun onSensorChanged(event: SensorEvent?) {
                if (event != null && shouldNotify()) {
                    val data = FloatArray(event.values.size)
                    event.values.forEachIndexed { index, value ->
                        data[index] = value.toFloat()
                    }
                    val resultMap = mutableMapOf<String, Any?>(
                        "sensorId" to sensorId,
                        "data" to data,
                        "accuracy" to event.accuracy,
                    )
                    sink.success(resultMap)
                }
            }

            private fun shouldNotify(): Boolean {
                if (customDelay) {
                    val now = Calendar.getInstance()
                    val diff = (now.timeInMillis - lastUpdate.timeInMillis) * 1000

                    if (diff > delayUs) {
                        lastUpdate = now
                        return true
                    }
                    return false
                }
                return true
            }
        }
    }
}
