package com.example.project

import android.os.Handler
import android.os.Looper
import android.util.Log
import java.util.Collections
import java.util.LinkedList
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * Shares a single [MethodChannel] instance between the foreground Flutter activity
 * and the [WearableListenerService]. The watch sends JSON payloads through the
 * data layer; once they arrive here we forward them to Flutter so that the
 * existing walk posting flow can handle them just like a manual walk session.
 */
object WearBridge {

    private const val CHANNEL_NAME = "com.example.project/wear"
    private const val TAG = "WearBridge"

    private val mainHandler = Handler(Looper.getMainLooper())

    @Volatile
    private var methodChannel: MethodChannel? = null

    private val pendingEvents = Collections.synchronizedList(
        LinkedList<Pair<String, Map<String, Any>>>()
    )

    fun bind(binaryMessenger: BinaryMessenger) {
        mainHandler.post {
            methodChannel = MethodChannel(binaryMessenger, CHANNEL_NAME)
            Log.d(TAG, "MethodChannel bound to Flutter engine")
            flushPending()
        }
    }

    fun unbind() {
        mainHandler.post {
            methodChannel = null
            Log.d(TAG, "MethodChannel unbound from Flutter engine")
        }
    }

    fun sendStart(startEpochMs: Long, intensity: String) {
        dispatch(
            method = "start_walk",
            args = mapOf("startEpochMs" to startEpochMs, "intensity" to intensity),
        )
    }

    fun sendEnd(endEpochMs: Long, durationSec: Int, intensity: String) {
        dispatch(
            method = "end_walk",
            args = mapOf(
                "endEpochMs" to endEpochMs,
                "durationSec" to durationSec,
                "intensity" to intensity,
            ),
        )
    }

    private fun dispatch(method: String, args: Map<String, Any>) {
        val channel = methodChannel
        if (channel == null) {
            Log.w(TAG, "Flutter channel not ready. Queuing $method with args=$args")
            pendingEvents += method to args
            return
        }
        mainHandler.post {
            channel.invokeMethod(method, args)
        }
    }

    private fun flushPending() {
        val snapshot = mutableListOf<Pair<String, Map<String, Any>>>()
        synchronized(pendingEvents) {
            if (pendingEvents.isEmpty()) return
            snapshot += pendingEvents
            pendingEvents.clear()
        }
        snapshot.forEach { (method, args) ->
            methodChannel?.let { channel ->
                mainHandler.post { channel.invokeMethod(method, args) }
            }
        }
    }
}
