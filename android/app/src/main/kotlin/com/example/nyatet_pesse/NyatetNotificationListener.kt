package com.example.nyatet_pesse

import android.app.Notification
import android.content.Intent
import android.os.Bundle
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log

class NyatetNotificationListener : NotificationListenerService() {

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        super.onNotificationPosted(sbn)
        if (sbn == null) return

        val packageName = sbn.packageName
        val notification = sbn.notification
        val extras = notification.extras

        val title = extras.getString(Notification.EXTRA_TITLE) ?: ""
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""

        // Broadcast the notification to MainActivity
        val intent = Intent(ACTION_NOTIFICATION_POSTED)
        intent.putExtra(EXTRA_PACKAGE_NAME, packageName)
        intent.putExtra(EXTRA_TITLE, title)
        intent.putExtra(EXTRA_TEXT, text)
        intent.putExtra(EXTRA_POST_TIME, sbn.postTime)
        
        sendBroadcast(intent)
        
        Log.d("NyatetNotif", "Notif received: $packageName - $title - $text")
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        super.onNotificationRemoved(sbn)
        // Not used currently, but can be implemented if needed
    }

    companion object {
        const val ACTION_NOTIFICATION_POSTED = "com.example.nyatet_pesse.NOTIFICATION_POSTED"
        const val EXTRA_PACKAGE_NAME = "package_name"
        const val EXTRA_TITLE = "title"
        const val EXTRA_TEXT = "text"
        const val EXTRA_POST_TIME = "post_time"
    }
}
