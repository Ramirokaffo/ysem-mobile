package com.ysem.ysem

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        creerCanalNotifications()
    }

    /** Le canal que nomme le serveur (`notifications/push.py`) : sans lui, un
     * push tomberait dans le canal « Divers » de Firebase. */
    private fun creerCanalNotifications() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val canal = NotificationChannel(
            "ysem_notifications",
            getString(R.string.canal_notifications),
            NotificationManager.IMPORTANCE_HIGH,
        )
        getSystemService(NotificationManager::class.java).createNotificationChannel(canal)
    }
}
