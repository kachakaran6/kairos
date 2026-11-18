package com.samyukt.kairos.widgets

import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import com.samyukt.kairos.R

class InteractiveWidgetProvider : BaseKairosWidget() {

    override fun buildRemoteViews(
        context: Context,
        widgetData: SharedPreferences,
        appWidgetId: Int,
        config: WidgetConfig
    ): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_interactive)

        // Dynamic background with real opacity
        val bgColor = ConfigRepository.getEffectiveBackgroundColor(config)
        views.setInt(R.id.widget_root, "setBackgroundColor", bgColor)

        // Dynamic auto-contrasting typography & colors
        val (primaryText, secondaryText) = ConfigRepository.getAutoContrastingTextColor(config)
        val accentColor = ConfigRepository.parseAccentColor(config)

        views.setTextColor(R.id.alarm_time, primaryText)
        views.setTextColor(R.id.alarm_label, secondaryText)

        val alarmTime = widgetData.getString("next_alarm_time", "--:--") ?: "--:--"
        val alarmLabel = widgetData.getString("next_alarm_label", "No alarm set") ?: "No alarm set"
        val alarmEnabled = widgetData.getBoolean("next_alarm_enabled", false)

        views.setTextViewText(R.id.alarm_time, alarmTime)
        views.setTextViewText(R.id.alarm_label, alarmLabel)
        views.setTextViewText(R.id.btn_alarm_toggle, if (alarmEnabled) "ON" else "OFF")

        // Button styling
        if (alarmEnabled) {
            views.setInt(R.id.btn_alarm_toggle, "setBackgroundResource", R.drawable.widget_pill_accent)
            views.setInt(R.id.btn_alarm_toggle, "setColorFilter", accentColor)
            views.setTextColor(R.id.btn_alarm_toggle, ConfigRepository.getEffectiveBackgroundColor(config))
        } else {
            views.setInt(R.id.btn_alarm_toggle, "setBackgroundResource", R.drawable.widget_chip_dark)
            views.setTextColor(R.id.btn_alarm_toggle, secondaryText)
        }

        // Load Focus streak bars bitmap safely
        val streakPath = widgetData.getString("focus_streak_bars", null)
        val streakBmp = loadBitmapFromFile(streakPath)
        if (streakBmp != null) {
            views.setImageViewBitmap(R.id.focus_streak_bars, streakBmp)
        }

        // Quick focus button styling
        views.setTextColor(R.id.btn_quick_focus, primaryText)

        // Deep links
        val alarmIntent = createDeepLinkIntent(context, "alarm")
        views.setOnClickPendingIntent(R.id.widget_root, alarmIntent)
        views.setOnClickPendingIntent(R.id.btn_alarm_toggle, alarmIntent)

        val focusIntent = createDeepLinkIntent(context, "focus")
        views.setOnClickPendingIntent(R.id.btn_quick_focus, focusIntent)

        return views
    }
}
