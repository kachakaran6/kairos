package com.samyukt.kairos.widgets

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import androidx.core.app.NotificationCompat
import com.samyukt.kairos.MainActivity
import com.samyukt.kairos.R
import es.antonborri.home_widget.HomeWidgetPlugin

class KairosWidgetTickerService : Service() {

    companion object {
        private const val CHANNEL_ID = "kairos_widget_ticker_channel"
        private const val NOTIFICATION_ID = 8801

        fun start(context: Context) {
            val intent = Intent(context, KairosWidgetTickerService::class.java)
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
            } catch (_: Throwable) {
                // If background start is restricted, fall back to in-memory ticker
                KairosWidgetTicker.start(context)
            }
        }

        fun stop(context: Context) {
            val intent = Intent(context, KairosWidgetTickerService::class.java)
            try {
                context.stopService(intent)
            } catch (_: Throwable) {}
        }
    }

    private val handler = Handler(Looper.getMainLooper())
    private var isTicking = false
    private var screenReceiver: BroadcastReceiver? = null

    private val tickRunnable = object : Runnable {
        override fun run() {
            val pm = getSystemService(Context.POWER_SERVICE) as? PowerManager
            val isScreenOn = pm?.isInteractive ?: true

            if (isScreenOn) {
                tickActiveWidgets()
                handler.postDelayed(this, 1000L)
            } else {
                isTicking = false
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, buildSilentNotification())
        registerScreenReceiver()
        startTicking()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startTicking()
        return START_STICKY
    }

    private fun startTicking() {
        val pm = getSystemService(Context.POWER_SERVICE) as? PowerManager
        val isScreenOn = pm?.isInteractive ?: true

        if (isScreenOn && !isTicking) {
            isTicking = true
            handler.removeCallbacks(tickRunnable)
            handler.post(tickRunnable)
        }
    }

    private fun stopTicking() {
        isTicking = false
        handler.removeCallbacks(tickRunnable)
    }

    private fun registerScreenReceiver() {
        screenReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent?) {
                when (intent?.action) {
                    Intent.ACTION_SCREEN_ON, Intent.ACTION_USER_PRESENT -> {
                        startTicking()
                    }
                    Intent.ACTION_SCREEN_OFF -> {
                        stopTicking()
                    }
                }
            }
        }
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction(Intent.ACTION_USER_PRESENT)
        }
        registerReceiver(screenReceiver, filter)
    }

    private fun tickActiveWidgets() {
        try {
            val appWidgetManager = AppWidgetManager.getInstance(applicationContext) ?: return
            val prefs = HomeWidgetPlugin.getData(applicationContext)

            val thenComp = ComponentName(applicationContext, ThenMomentWidgetProvider::class.java)
            val thenIds = appWidgetManager.getAppWidgetIds(thenComp)
            if (thenIds.isNotEmpty()) {
                ThenMomentWidgetProvider().onUpdate(applicationContext, appWidgetManager, thenIds, prefs)
            }

            val nextComp = ComponentName(applicationContext, NextMomentWidgetProvider::class.java)
            val nextIds = appWidgetManager.getAppWidgetIds(nextComp)
            if (nextIds.isNotEmpty()) {
                NextMomentWidgetProvider().onUpdate(applicationContext, appWidgetManager, nextIds, prefs)
            }

            val comboComp = ComponentName(applicationContext, ComboWidgetProvider::class.java)
            val comboIds = appWidgetManager.getAppWidgetIds(comboComp)
            if (comboIds.isNotEmpty()) {
                ComboWidgetProvider().onUpdate(applicationContext, appWidgetManager, comboIds, prefs)
            }

            // If user has removed all widgets, self-terminate
            if (thenIds.isEmpty() && nextIds.isEmpty() && comboIds.isEmpty()) {
                stopSelf()
            }
        } catch (_: Throwable) {}
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Kairos Live Widgets",
                NotificationManager.IMPORTANCE_MIN
            ).apply {
                description = "Keeps home screen countdown widgets ticking live"
                setShowBadge(false)
                enableLights(false)
                enableVibration(false)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
        }
    }

    private fun buildSilentNotification(): Notification {
        val launchIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("Kairos Live Counter")
            .setContentText("Home screen countdown active")
            .setPriority(NotificationCompat.PRIORITY_MIN)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setOngoing(true)
            .setContentIntent(pendingIntent)
            .build()
    }

    override fun onDestroy() {
        stopTicking()
        screenReceiver?.let {
            try { unregisterReceiver(it) } catch (_: Throwable) {}
        }
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
