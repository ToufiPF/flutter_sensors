package cl.ceisufro.fluttersensors

import android.content.Context
import android.hardware.SensorManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.*
import io.flutter.plugin.common.MethodChannel.MethodCallHandler


class FlutterSensorsPlugin() : FlutterPlugin, MethodCallHandler {
    companion object {
        private const val CHANNEL_NAME = "flutter_sensors"
        
        // Flutter plugin binding api v1
        @Suppress("deprecation")
        @JvmStatic
        fun registerWith(registrar: PluginRegistry.Registrar) {
            val messenger = registrar.messenger()
            val instance = FlutterSensorsPlugin(registrar.context(), messenger)

            val methodChannel = MethodChannel(messenger, CHANNEL_NAME)
            methodChannel.setMethodCallHandler(instance)
            registrar.addViewDestroyListener {
                instance.removeAllListeners()
                false
            }
        }
    }

    constructor(context: Context, binaryMessenger: BinaryMessenger) : this() {
        messenger = binaryMessenger
        sensorManager = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
    }

    private val eventChannels = hashMapOf<Int, EventChannel>()
    private val streamHandlers = hashMapOf<Int, SensorStreamHandler>()
    private lateinit var messenger: BinaryMessenger
    private lateinit var sensorManager: SensorManager

    // Flutter plugin binding api v2
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val context = binding.applicationContext
        messenger = binding.binaryMessenger
        sensorManager = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager

        val methodChannel = MethodChannel(messenger, CHANNEL_NAME)
        methodChannel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(p0: FlutterPlugin.FlutterPluginBinding) {
        removeAllListeners()
    }

    private fun removeAllListeners() {
        eventChannels.values.forEach { it.setStreamHandler(null) }
        streamHandlers.values.forEach { it.stopListener() }

        eventChannels.clear()
        streamHandlers.clear()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "is_sensor_available" -> isSensorAvailable(call.arguments, result)
            "update_sensor_interval" -> updateSensorInterval(call.arguments, result)
            "start_event_channel" -> startEventChannel(call.arguments, result)
            else -> result.notImplemented()
        }
    }

    private fun isSensorAvailable(arguments: Any, result: MethodChannel.Result) {
        val dataMap = arguments as Map<*, *>
        val sensorId: Int = dataMap["sensorId"] as Int
        val isAvailable = sensorManager.getSensorList(sensorId).isNotEmpty()
        result.success(isAvailable)
        return
    }

    private fun updateSensorInterval(arguments: Any, result: MethodChannel.Result) {
        try {
            val dataMap = arguments as Map<*, *>
            val sensorId: Int = dataMap["sensorId"] as Int
            val interval: Int? = dataMap["interval"] as Int?
            streamHandlers[sensorId]?.updateInterval(interval)
            result.success(true)
        } catch (e: Exception) {
            e.printStackTrace()
            result.success(false)
        }
    }

    private fun startEventChannel(arguments: Any, result: MethodChannel.Result) {
        try {
            val dataMap = arguments as Map<*, *>
            val sensorId: Int = dataMap["sensorId"] as Int
            val interval: Int? = dataMap["interval"] as Int?
            if (!eventChannels.containsKey(sensorId)) {
                val eventChannel = EventChannel(messenger, "flutter_sensors/$sensorId")
                val sensorStreamHandler = SensorStreamHandler(sensorManager, sensorId, interval)
                eventChannel.setStreamHandler(sensorStreamHandler)
                eventChannels[sensorId] = eventChannel
                streamHandlers[sensorId] = sensorStreamHandler
            }
            result.success(true)
        } catch (e: Exception) {
            e.printStackTrace()
            result.success(false)
        }
    }
}
