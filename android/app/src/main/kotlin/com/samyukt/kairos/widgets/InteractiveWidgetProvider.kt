package com.samyukt.kairos.widgets

import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import com.samyukt.kairos.R

class InteractiveWidgetProvider : BaseKairosWidget() {

    override fun buildRemoteViews(
        context: Context,
        widgetData: SharedPreferences,
        appWidgetId: Int
    ): RemoteViews {
        val isDark = widgetData.getBoolean("is_dark", true)
        val views = RemoteViews(context.packageName, R.layout.widget_interactive)

        views.setInt(
            R.id.widget_root,
            "setBackgroundResource",
            if (isDark) R.drawable.widget_background_dark else R.drawable.widget_background_light
        )

        val alarmTime = widgetData.getString("next_alarm_time", "--:--") ?: "--:--"
        val alarmLabel = widgetData.getString("next_alarm_label", "No alarm set") ?: "No alarm set"
        val alarmEnabled = widgetData.getBoolean("next_alarm_enabled", false)

        views.setTextViewText(R.id.alarm_time, alarmTime)
        views.setTextViewText(R.id.alarm_label, alarmLabel)
        views.setTextViewText(R.id.btn_alarm_toggle, if (alarmEnabled) "ON" else "OFF")

        // Load Focus streak bars bitmap
        val streakPath = widgetData.getString("focus_streak_bars", null)
        val streakBmp = loadBitmapFromFile(streakPath)
        if (streakBmp != null) {
            views.setImageViewBitmap(R.id.focus_streak_bars, streakBmp)
        }

        // Deep links
        val alarmIntent = createDeepLinkIntent(context, "alarm")
        views.setOnClickPendingIntent(R.id.widget_root, alarmIntent)
        views.setOnClickPendingIntent(R.id.btn_alarm_toggle, alarmIntent)

        val focusIntent = createDeepLinkIntent(context, "focus")
        views.setOnClickPendingIntent(R.id.btn_quick_focus, focusIntent)

        return views
    }
}
