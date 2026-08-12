package com.example.nyatet_pesse

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.CancellationSignal
import android.provider.Settings
import android.widget.Toast
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val METHOD_CHANNEL = "com.example.nyatet_pesse/notification_method"
    private val EVENT_CHANNEL = "com.example.nyatet_pesse/notification_event"
    private val BIOMETRIC_CHANNEL = "com.example.nyatet_pesse/biometric"

    private var eventSink: EventChannel.EventSink? = null
    private var biometricResult: MethodChannel.Result? = null

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

        // ── Notification Method Channel ──────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isNotificationListenerEnabled" -> result.success(isNotificationServiceEnabled())
                "openNotificationSettings" -> {
                    startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // ── Notification Event Channel ───────────────────────────────
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    val filter = IntentFilter(NyatetNotificationListener.ACTION_NOTIFICATION_POSTED)
                    this@MainActivity.registerReceiver(notificationReceiver, filter)
                }
                override fun onCancel(arguments: Any?) {
                    eventSink = null
                    try { this@MainActivity.unregisterReceiver(notificationReceiver) } catch (e: Exception) {}
                }
            }
        )

        // ── Fingerprint-Only Biometric Channel ───────────────────────
        // Ini memastikan hanya SIDIK JARI yang muncul, bukan Wajah
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BIOMETRIC_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isFingerprintAvailable" -> {
                    val biometricManager = BiometricManager.from(this)
                    // BIOMETRIC_STRONG = hanya hardware biometric (sidik jari), bukan software face
                    val canAuthenticate = biometricManager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_STRONG)
                    result.success(canAuthenticate == BiometricManager.BIOMETRIC_SUCCESS)
                }
                "authenticateFingerprint" -> {
                    val title = call.argument<String>("title") ?: "Sidik Jari NyatetPesse"
                    val subtitle = call.argument<String>("subtitle") ?: "Pindai sidik jari."
                    val cancel = call.argument<String>("cancel") ?: "Batalkan"
                    biometricResult = result
                    showFingerprintPrompt(title, subtitle, cancel)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun showFingerprintPrompt(title: String, subtitle: String, cancelText: String) {
        val executor = ContextCompat.getMainExecutor(this)

        val callback = object : BiometricPrompt.AuthenticationCallback() {
            override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                super.onAuthenticationSucceeded(result)
                biometricResult?.success("success")
                biometricResult = null
            }

            override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                super.onAuthenticationError(errorCode, errString)
                // errorCode 10 = user pressed cancel, 13 = device credential used, etc.
                biometricResult?.success("cancelled")
                biometricResult = null
            }

            override fun onAuthenticationFailed() {
                super.onAuthenticationFailed()
                // Sidik jari tidak dikenali — dialog tetap terbuka, jangan close
            }
        }

        val biometricPrompt = BiometricPrompt(this, executor, callback)

        val promptInfo = BiometricPrompt.PromptInfo.Builder()
            .setTitle(title)
            .setSubtitle(subtitle)
            .setNegativeButtonText(cancelText) // Tombol "Batalkan" untuk fallback ke PIN
            // KUNCI: hanya BIOMETRIC_STRONG = hanya sidik jari hardware, tanpa tab Wajah
            .setAllowedAuthenticators(BiometricManager.Authenticators.BIOMETRIC_STRONG)
            .build()

        biometricPrompt.authenticate(promptInfo)
    }

    override fun onDestroy() {
        super.onDestroy()
        try { unregisterReceiver(notificationReceiver) } catch (e: Exception) {}
    }

    private fun isNotificationServiceEnabled(): Boolean {
        val packageNames = NotificationManagerCompat.getEnabledListenerPackages(this)
        return packageNames.contains(packageName)
    }
}
