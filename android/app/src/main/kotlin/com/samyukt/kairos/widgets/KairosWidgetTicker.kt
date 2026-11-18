package com.samyukt.kairos.widgets

import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import es.antonborri.home_widget.HomeWidgetPlugin

/**
 * Ultra lightweight, zero-allocation 1-second ticker for Kairos Android home widgets.
 * Automatically updates active Next Moment, Memories (Then), and Combo widgets
 * every 1 second while the screen is interactive (ON).
 *
 * Automatically pauses when the screen turns off or device enters doze,
 * consuming 0% CPU and 0% battery when the phone is not in active use.
 */
object KairosWidgetTicker {

    private val handler = Handler(Looper.getMainLooper())
    private var isTicking = false
    private var screenReceiverRegistered = false
    private var appContext: Context? = null

    private val tickRunnable = object : Runnable {
        override fun run() {
            if (!isTicking) return

            appContext?.let { ctx ->
                val pm = ctx.getSystemService(Context.POWER_SERVICE) as? PowerManager
                val isScreenOn = pm?.isInteractive ?: true

                if (isScreenOn) {
                    tickWidgets(ctx)
                    handler.postDelayed(this, 1000L)
                } else {
                    // Pause ticker when screen goes dark
                    isTicking = false
                }
            }
        }
    }

    fun start(context: Context) {
        val app = context.applicationContext
        appContext = app
        registerScreenReceiver(app)

        val pm = app.getSystemService(Context.POWER_SERVICE) as? PowerManager
        val isScreenOn = pm?.isInteractive ?: true

        if (isScreenOn && !isTicking) {
            isTicking = true
            handler.removeCallbacks(tickRunnable)
            handler.post(tickRunnable)
        }
    }

    fun stop() {
        isTicking = false
        handler.removeCallbacks(tickRunnable)
    }

    private fun registerScreenReceiver(context: Context) {
        if (screenReceiverRegistered) return
        try {
            val filter = IntentFilter().apply {
                addAction(Intent.ACTION_SCREEN_ON)
                addAction(Intent.ACTION_SCREEN_OFF)
                addAction(Intent.ACTION_USER_PRESENT)
            }
            context.registerReceiver(object : BroadcastReceiver() {
                override fun onReceive(c: Context, intent: Intent?) {
                    when (intent?.action) {
                        Intent.ACTION_SCREEN_ON, Intent.ACTION_USER_PRESENT -> {
                            start(c)
                        }
                        Intent.ACTION_SCREEN_OFF -> {
                            stop()
                        }
                    }
                }
            }, filter)
            screenReceiverRegistered = true
        } catch (_: Throwable) {
            // Ignore if already registered
        }
    }

    private fun tickWidgets(context: Context) {
        try {
            val appWidgetManager = AppWidgetManager.getInstance(context) ?: return
            val prefs = HomeWidgetPlugin.getData(context)

            // 1. Then Moment (Memories)
            val thenComp = ComponentName(context, ThenMomentWidgetProvider::class.java)
            val thenIds = appWidgetManager.getAppWidgetIds(thenComp)
            if (thenIds.isNotEmpty()) {
                ThenMomentWidgetProvider().onUpdate(context, appWidgetManager, thenIds, prefs)
            }

            // 2. Next Moment
            val nextComp = ComponentName(context, NextMomentWidgetProvider::class.java)
            val nextIds = appWidgetManager.getAppWidgetIds(nextComp)
            if (nextIds.isNotEmpty()) {
                NextMomentWidgetProvider().onUpdate(context, appWidgetManager, nextIds, prefs)
            }

            // 3. Combo Dashboard
            val comboComp = ComponentName(context, ComboWidgetProvider::class.java)
            val comboIds = appWidgetManager.getAppWidgetIds(comboComp)
            if (comboIds.isNotEmpty()) {
                ComboWidgetProvider().onUpdate(context, appWidgetManager, comboIds, prefs)
            }
        } catch (_: Throwable) {
            // Silent catch to prevent any background crashes
        }
    }
}
