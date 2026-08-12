package com.example.nyatet_pesse

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.provider.Settings
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val METHOD_CHANNEL = "com.example.nyatet_pesse/notification_method"
    private val EVENT_CHANNEL = "com.example.nyatet_pesse/notification_event"

    private var eventSink: EventChannel.EventSink? = null

    private val notificationReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == NyatetNotificationListener.ACTION_NOTIFICATION_POSTED) {
                val data = mapOf(
                    "packageName" to intent.getStringExtra(NyatetNotificationListener.EXTRA_PACKAGE_NAME),
                    "title" to intent.getStringExtra(NyatetNotificationListener.EXTRA_TITLE),
                    "text" to intent.getStringExtra(NyatetNotificationListener.EXTRA_TEXT),
                    "postTime" to intent.getLongExtra(NyatetNotificationListener.EXTRA_POST_TIME, 0)
                )
                eventSink?.success(data)
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Setup MethodChannel for checking and requesting permissions
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isNotificationListenerEnabled" -> {
                    result.success(isNotificationServiceEnabled())
                }
                "openNotificationSettings" -> {
                    startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // Setup EventChannel to stream notifications to Flutter
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    val filter = IntentFilter(NyatetNotificationListener.ACTION_NOTIFICATION_POSTED)
                    // For Android 13/14, we might need RECEIVER_NOT_EXPORTED or RECEIVER_EXPORTED, but since this is internal broadcast it's fine
                    context.registerReceiver(notificationReceiver, filter)
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                    try {
                        context.unregisterReceiver(notificationReceiver)
                    } catch (e: Exception) {
                        // Already unregistered
                    }
                }
            }
        )
    }

    override fun onDestroy() {
        super.onDestroy()
        try {
            unregisterReceiver(notificationReceiver)
        } catch (e: Exception) {
            // Ignore if already unregistered
        }
    }

    private fun isNotificationServiceEnabled(): Boolean {
        val packageNames = NotificationManagerCompat.getEnabledListenerPackages(this)
        return packageNames.contains(packageName)
    }
}
