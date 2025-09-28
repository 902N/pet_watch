package com.example.project

import android.os.Handler
import android.os.Looper
import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.WearableListenerService
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

class WearableListenerService : WearableListenerService() {

    private lateinit var channel: MethodChannel

    override fun onCreate() {
        super.onCreate()
        // FlutterEngine and MethodChannel setup
        val flutterEngine = FlutterEngine(this)
        flutterEngine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault()
        )
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.project/wear")
    }

    override fun onMessageReceived(messageEvent: MessageEvent) {
        when (messageEvent.path) {
            "/walk/start" -> {
                val data = JSONObject(String(messageEvent.data))
                val args = mapOf(
                    "startEpochMs" to data.getLong("startEpochMs"),
                    "intensity" to data.getString("intensity")
                )
                Handler(Looper.getMainLooper()).post {
                    channel.invokeMethod("start_walk", args)
                }
            }
            "/walk/end" -> {
                val data = JSONObject(String(messageEvent.data))
                val args = mapOf(
                    "endEpochMs" to data.getLong("endEpochMs"),
                    "durationSec" to data.getInt("durationSec"),
                    "intensity" to data.getString("intensity")
                )
                Handler(Looper.getMainLooper()).post {
                    channel.invokeMethod("end_walk", args)
                }
            }
        }
    }
}