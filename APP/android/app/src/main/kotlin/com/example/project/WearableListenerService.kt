package com.example.project

import android.util.Log
import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.WearableListenerService
import org.json.JSONObject

class WearableListenerService : WearableListenerService() {
    override fun onMessageReceived(messageEvent: MessageEvent) {
        when (messageEvent.path) {
            "/walk/start" -> {
                val data = JSONObject(String(messageEvent.data))
                val startEpochMs = data.getLong("startEpochMs")
                val intensity = data.getString("intensity")
                WearBridge.sendStart(startEpochMs = startEpochMs, intensity = intensity)
            }
            "/walk/end" -> {
                val data = JSONObject(String(messageEvent.data))
                val endEpochMs = data.getLong("endEpochMs")
                val durationSec = data.getInt("durationSec")
                val intensity = data.getString("intensity")
                WearBridge.sendEnd(
                    endEpochMs = endEpochMs,
                    durationSec = durationSec,
                    intensity = intensity,
                )
            }
            else -> {
                Log.w(
                    "WearListener",
                    "Unhandled wear message path=${messageEvent.path}",
                )
                super.onMessageReceived(messageEvent)
            }
        }
    }
}