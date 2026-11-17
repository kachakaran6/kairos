package com.samyukt.kairos.widgets.receivers

import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import com.samyukt.kairos.widgets.ClockWidgetProvider
import com.samyukt.kairos.widgets.ComboWidgetProvider
import com.samyukt.kairos.widgets.InteractiveWidgetProvider
import com.samyukt.kairos.widgets.NextMomentWidgetProvider
import com.samyukt.kairos.widgets.ThenMomentWidgetProvider
import com.samyukt.kairos.widgets.WorldClockWidgetProvider
import com.samyukt.kairos.widgets.workers.WidgetSyncWorker

class SystemEventReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent?) {
        // 1. Reschedule midnight alarm on boot or time/timezone change
        MidnightRolloverReceiver.scheduleNextMidnight(context)

        // 2. Schedule WorkManager periodic sync fallback
        WidgetSyncWorker.enqueuePeriodic(context)

        // 3. Notify all widgets
        val appWidgetManager = AppWidgetManager.getInstance(context) ?: return
        val providers = listOf(
            ClockWidgetProvider::class.java,
            WorldClockWidgetProvider::class.java,
            NextMomentWidgetProvider::class.java,
            ThenMomentWidgetProvider::class.java,
            InteractiveWidgetProvider::class.java,
            ComboWidgetProvider::class.java
        )

        for (p in providers) {
            val component = ComponentName(context, p)
            val ids = appWidgetManager.getAppWidgetIds(component)
            if (ids.isNotEmpty()) {
                val updateIntent = Intent(context, p).apply {
                    action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
                }
                context.sendBroadcast(updateIntent)
            }
        }
    }
}
