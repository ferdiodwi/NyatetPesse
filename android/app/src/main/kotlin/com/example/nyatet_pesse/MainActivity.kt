package com.example.nyatet_pesse

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.Uri
import android.os.Build
import android.os.CancellationSignal
import android.os.PowerManager
import android.provider.Settings
import android.widget.Toast
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.app.NotificationCompat
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

    companion object {
        const val ACTION_INBOX_SAVE = "com.example.nyatet_pesse.ACTION_INBOX_SAVE"
        const val ACTION_INBOX_DISMISS = "com.example.nyatet_pesse.ACTION_INBOX_DISMISS"
        const val EXTRA_INBOX_ID = "inboxId"
        const val INBOX_CHANNEL_ID = "inbox_channel"
    }

    private var eventSink: EventChannel.EventSink? = null
    private var biometricResult: MethodChannel.Result? = null
    private val notificationReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            when (intent?.action) {
                NyatetNotificationListener.ACTION_NOTIFICATION_POSTED -> {
                    val data = mapOf(
                        "packageName" to intent.getStringExtra(NyatetNotificationListener.EXTRA_PACKAGE_NAME),
                        "title" to intent.getStringExtra(NyatetNotificationListener.EXTRA_TITLE),
                        "text" to intent.getStringExtra(NyatetNotificationListener.EXTRA_TEXT),
                        "postTime" to intent.getLongExtra(NyatetNotificationListener.EXTRA_POST_TIME, 0)
                    )
                    eventSink?.success(data)
                }
                ACTION_INBOX_SAVE -> {
                    val inboxId = intent.getIntExtra(EXTRA_INBOX_ID, -1)
                    NotificationManagerCompat.from(this@MainActivity).cancel(inboxId)
                    eventSink?.success(mapOf("type" to "inbox_action", "action" to "save", "inboxId" to inboxId))
                }
                ACTION_INBOX_DISMISS -> {
                    val inboxId = intent.getIntExtra(EXTRA_INBOX_ID, -1)
                    NotificationManagerCompat.from(this@MainActivity).cancel(inboxId)
                    eventSink?.success(mapOf("type" to "inbox_action", "action" to "dismiss", "inboxId" to inboxId))
                }
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
                "isBatteryOptimizationIgnored" -> {
                    val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
                    result.success(pm.isIgnoringBatteryOptimizations(packageName))
                }
                "requestIgnoreBatteryOptimization" -> {
                    try {
                        val intent = Intent(
                            Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                            Uri.parse("package:$packageName")
                        )
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        // Fallback: buka daftar app yang dikecualikan.
                        startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
                        result.success(false)
                    }
                }
                "showInboxNotification" -> {
                    val id = call.argument<Int>("id") ?: -1
                    val title = call.argument<String>("title") ?: "Transaksi Terdeteksi"
                    val body = call.argument<String>("body") ?: ""
                    showInboxNotification(id, title, body)
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
                    val filter = IntentFilter().apply {
                        addAction(NyatetNotificationListener.ACTION_NOTIFICATION_POSTED)
                        addAction(ACTION_INBOX_SAVE)
                        addAction(ACTION_INBOX_DISMISS)
                    }
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

    /// Notifikasi inbox dengan aksi cepat [Simpan] / [Abaikan] — transaksi
    /// bisa dikonfirmasi tanpa membuka aplikasi.
    private fun showInboxNotification(id: Int, title: String, body: String) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                INBOX_CHANNEL_ID,
                "Transaksi Terdeteksi",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Konfirmasi cepat transaksi hasil deteksi otomatis"
            }
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }

        val contentIntent = PendingIntent.getActivity(
            this,
            id,
            packageManager.getLaunchIntentForPackage(packageName)
                ?.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP) ?: Intent(),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val saveIntent = PendingIntent.getBroadcast(
            this, id,
            Intent(ACTION_INBOX_SAVE).putExtra(EXTRA_INBOX_ID, id)
                .setPackage(packageName),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val dismissIntent = PendingIntent.getBroadcast(
            this, id,
            Intent(ACTION_INBOX_DISMISS).putExtra(EXTRA_INBOX_ID, id)
                .setPackage(packageName),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(this, INBOX_CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_menu_add)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setContentIntent(contentIntent)
            .setAutoCancel(true)
            .addAction(0, "Simpan", saveIntent)
            .addAction(0, "Abaikan", dismissIntent)
            .build()

        try {
            NotificationManagerCompat.from(this).notify(id, notification)
        } catch (e: SecurityException) {
            // POST_NOTIFICATIONS belum diberikan — abaikan.
        }
    }
}
