package com.samyukt.kairos.widgets

import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import com.samyukt.kairos.R

class ComboWidgetProvider : BaseKairosWidget() {

    override fun buildRemoteViews(
        context: Context,
        widgetData: SharedPreferences,
        appWidgetId: Int,
        config: WidgetConfig
    ): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_combo_dashboard)

        // Dynamic background with real opacity
        val bgColor = ConfigRepository.getEffectiveBackgroundColor(config)
        views.setInt(R.id.widget_root, "setBackgroundColor", bgColor)

        // Dynamic auto-contrasting typography & colors
        val (primaryText, secondaryText) = ConfigRepository.getAutoContrastingTextColor(config)
        val accentColor = ConfigRepository.parseAccentColor(config)

        views.setTextColor(R.id.combo_clock, primaryText)
        views.setTextColor(R.id.combo_date, secondaryText)
        views.setTextColor(R.id.combo_alarm_text, primaryText)
        views.setTextColor(R.id.combo_moment_days, primaryText)
        views.setTextColor(R.id.combo_moment_title, secondaryText)

        val alarmTime = widgetData.getString("next_alarm_time", "--:--") ?: "--:--"
        views.setTextViewText(R.id.combo_alarm_text, "Alarm $alarmTime")

        val momentTitle = widgetData.getString("next_moment_title", "Nothing ahead yet") ?: "Nothing ahead yet"
        val momentDays = widgetData.getInt("next_moment_days", 0)
        views.setTextViewText(R.id.combo_moment_title, momentTitle)
        views.setTextViewText(R.id.combo_moment_days, "$momentDays days")

        // Load Life Progress concentric rings bitmap safely
        val ringsPath = widgetData.getString("life_progress_rings", null)
        val ringsBmp = loadBitmapFromFile(ringsPath)
        if (ringsBmp != null) {
            views.setImageViewBitmap(R.id.combo_life_rings, ringsBmp)
        }

        val pendingIntent = createDeepLinkIntent(context, "dashboard")
        views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

        return views
    }
}
