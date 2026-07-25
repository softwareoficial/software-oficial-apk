package com.example.apk_webview_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.softwareoficial.bridge/command"
    private lateinit var commandChannel: MethodChannel

    private val commandReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val bundle = intent?.extras
            val args = mutableMapOf<String, Any>()
            if (bundle != null) {
                for (key in bundle.keySet()) {
                    args[key] = bundle.get(key) ?: ""
                }
            }
            // Reenviar todos los argumentos a Flutter
            commandChannel.invokeMethod("executeCommand", args)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        commandChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
    }

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        // Registrar receptor de broadcast para ADB
        val filter = IntentFilter("com.softwareoficial.CMD")
        registerReceiver(commandReceiver, filter, Context.RECEIVER_EXPORTED)
    }

    override fun onDestroy() {
        super.onDestroy()
        unregisterReceiver(commandReceiver)
    }
}
