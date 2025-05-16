package com.example.mtquotes

import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.mtquotes/upi_intent"

    override fun onCreate(savedInstanceState: Bundle?) {
        installSplashScreen()
        super.onCreate(savedInstanceState)

        // Block screenshots and screen recording
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call, result ->
            if (call.method == "launchUpiApp") {
                val arguments = call.arguments as Map<*, *>
                val uriString = arguments["data"] as String
                val packageName = arguments["package"] as String

                val intent = Intent(Intent.ACTION_VIEW)
                intent.data = Uri.parse(uriString)
                intent.setPackage(packageName)

                try {
                    // Check if there's any app that can handle this intent
                    val packageManager = context.packageManager
                    val activities = packageManager.queryIntentActivities(intent, PackageManager.MATCH_DEFAULT_ONLY)

                    if (activities.size > 0) {
                        startActivity(intent)
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                } catch (e: Exception) {
                    result.error("LAUNCH_ERROR", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}