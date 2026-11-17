package com.samyukt.kairos.widgets.receivers

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import com.samyukt.kairos.widgets.ClockWidgetProvider
import com.samyukt.kairos.widgets.ComboWidgetProvider
import com.samyukt.kairos.widgets.NextMomentWidgetProvider
import com.samyukt.kairos.widgets.ThenMomentWidgetProvider
import java.util.Calendar

class MidnightRolloverReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent?) {
        // 1. Refresh all widgets whose day calculations or dates may have rolled over
        refreshWidgets(context)

        // 2. Schedule the next midnight alarm
        scheduleNextMidnight(context)
    }

    companion object {
        const val ACTION_MIDNIGHT = "app.kairos.MIDNIGHT_ROLLOVER"

        fun scheduleNextMidnight(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return

            val intent = Intent(context, MidnightRolloverReceiver::class.java).apply {
                action = ACTION_MIDNIGHT
            }
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                1001,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val calendar = Calendar.getInstance().apply {
                add(Calendar.DAY_OF_YEAR, 1)
                set(Calendar.HOUR_OF_DAY, 0)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 1)
                set(Calendar.MILLISECOND, 0)
            }

            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    alarmManager.setExactAndAllowWhileIdle(
                        AlarmManager.RTC,
                        calendar.timeInMillis,
                        pendingIntent
                    )
                } else {
                    alarmManager.setExact(
                        AlarmManager.RTC,
                        calendar.timeInMillis,
                        pendingIntent
                    )
                }
            } catch (_: SecurityException) {
                // Safe fallback for inexact alarm if exact permission is restricted
                alarmManager.set(AlarmManager.RTC, calendar.timeInMillis, pendingIntent)
            }
        }

        private fun refreshWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context) ?: return
            val providers = listOf(
                ClockWidgetProvider::class.java,
                NextMomentWidgetProvider::class.java,
                ThenMomentWidgetProvider::class.java,
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
}
