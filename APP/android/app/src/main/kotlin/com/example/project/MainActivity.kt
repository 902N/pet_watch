package com.example.project

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        WearBridge.bind(flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun detachFromFlutterEngine() {
        super.detachFromFlutterEngine()
        WearBridge.unbind()
    }
}
