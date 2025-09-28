package com.example.project

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

import org.json.JSONObject

import com.google.android.gms.wearable.Wearable
import com.google.android.gms.wearable.Node
import com.google.android.gms.tasks.OnSuccessListener
class MainActivity: FlutterActivity() {
    private val channel = "wear_comm"
    // MethodChannel 연결
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel).setMethodCallHandler { call, result ->
            // MethodChannel 핸들러
            when (call.method) {
                "start_walk" -> { sendMessageToPhone("/walk/start", call.arguments as HashMap<String, Any>); result.success(null) }
                "end_walk"   -> { sendMessageToPhone("/walk/end",   call.arguments as HashMap<String, Any>); result.success(null) }
                else -> result.notImplemented()
            }
        }
    }
    // flutter에서 받은 데이터를 JSONObject로 직렬화
    private fun sendMessageToPhone(path: String, data: HashMap<String, Any>) {
        val json = JSONObject(data as Map<*,*>).toString().toByteArray()
        // Wearable API
        Wearable.getNodeClient(this).connectedNodes.addOnSuccessListener { nodes ->
            nodes.forEach { node ->
                Wearable.getMessageClient(this).sendMessage(node.id, path, json)
            }
        }
    }
}
