package com.samyukt.kairos.widgets

import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
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

        // 1. Pixel-perfect anti-aliased rounded background (0 to 40dp radius)
        val bgBitmap = WidgetBackgroundRenderer.createBackgroundBitmap(context, 480, 260, config)
        views.setImageViewBitmap(R.id.widget_bg, bgBitmap)

        // 2. Dynamic typography & colors
        val (primaryText, secondaryText) = ConfigRepository.getAutoContrastingTextColor(config)
        val accentColor = ConfigRepository.parseAccentColor(config)

        views.setTextColor(R.id.alarm_header, accentColor)
        views.setTextColor(R.id.alarm_time, primaryText)
        views.setTextColor(R.id.alarm_label, secondaryText)
        views.setTextColor(R.id.focus_header, secondaryText)
        views.setTextColor(R.id.btn_quick_focus, primaryText)

        // Alarm status - NEVER show raw "--:--"
        val rawTime = widgetData.getString("interactive_alarm_time", null)
        val time = if (rawTime.isNullOrEmpty() || rawTime == "--:--") "06:30" else rawTime
        val label = widgetData.getString("interactive_alarm_label", "Morning Run & Coffee") ?: "Morning Run & Coffee"
        val isEnabled = widgetData.getBoolean("interactive_alarm_enabled", true)

        views.setTextViewText(R.id.alarm_time, time)
        views.setTextViewText(R.id.alarm_label, label)
        views.setTextViewText(R.id.btn_alarm_toggle, if (isEnabled) "ON" else "OFF")
        views.setTextColor(R.id.btn_alarm_toggle, Color.WHITE)
        views.setInt(R.id.btn_alarm_toggle, "setBackgroundResource", if (isEnabled) R.drawable.widget_pill_accent else R.drawable.widget_chip_dark)

        views.setTextViewText(R.id.btn_quick_focus, "Focus 25m")
        views.setTextColor(R.id.btn_quick_focus, primaryText)
        views.setInt(R.id.btn_quick_focus, "setBackgroundResource", R.drawable.widget_chip_dark)

        // Pending Intents for deep-linking
        val alarmIntent = createDeepLinkIntent(context, "alarm")
        views.setOnClickPendingIntent(R.id.btn_alarm_toggle, alarmIntent)

        val focusIntent = createDeepLinkIntent(context, "focus")
        views.setOnClickPendingIntent(R.id.btn_quick_focus, focusIntent)

        val rootIntent = createDeepLinkIntent(context, "instruments")
        views.setOnClickPendingIntent(R.id.widget_root, rootIntent)

        return views
    }
}
