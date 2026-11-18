package com.samyukt.kairos.widgets

import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import com.samyukt.kairos.R

class ClockWidgetProvider : BaseKairosWidget() {

    override fun buildRemoteViews(
        context: Context,
        widgetData: SharedPreferences,
        appWidgetId: Int,
        config: WidgetConfig
    ): RemoteViews {
        val style = widgetData.getString("clock_style_$appWidgetId", "monolith")

        val layoutId = when {
            style == "stacked" -> R.layout.widget_clock_stacked
            config.fontStyle.equals("serif", ignoreCase = true) -> R.layout.widget_clock_monolith_serif
            config.fontStyle.equals("mono", ignoreCase = true) -> R.layout.widget_clock_monolith_mono
            else -> R.layout.widget_clock_monolith
        }

        val views = RemoteViews(context.packageName, layoutId)

        // Dynamic background with real opacity
        val bgColor = ConfigRepository.getEffectiveBackgroundColor(config)
        views.setInt(R.id.widget_root, "setBackgroundColor", bgColor)

        // Dynamic auto-contrasting typography
        val (primaryText, secondaryText) = ConfigRepository.getAutoContrastingTextColor(config)
        val accentColor = ConfigRepository.parseAccentColor(config)

        if (layoutId == R.layout.widget_clock_stacked) {
            views.setTextColor(R.id.clock_hours, primaryText)
            views.setTextColor(R.id.clock_minutes, accentColor)
        } else {
            views.setTextColor(R.id.clock_time, primaryText)
            views.setTextColor(R.id.clock_date, secondaryText)
            views.setInt(R.id.clock_dot, "setColorFilter", accentColor)
        }

        // Deep link to Now tab
        val pendingIntent = createDeepLinkIntent(context, "now")
        views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

        return views
    }
}
