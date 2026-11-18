package com.samyukt.kairos.widgets

import android.content.Context
import android.content.SharedPreferences
import android.util.TypedValue
import android.widget.RemoteViews
import com.samyukt.kairos.R

class ClockWidgetProvider : BaseKairosWidget() {

    override fun buildRemoteViews(
        context: Context,
        widgetData: SharedPreferences,
        appWidgetId: Int,
        config: WidgetConfig
    ): RemoteViews {
        val style = widgetData.getString("clock_style_$appWidgetId", config.timeLayout)

        val layoutId = when {
            style == "stacked" || config.timeLayout == "stacked" -> R.layout.widget_clock_stacked
            config.fontStyle.equals("serif", ignoreCase = true) -> R.layout.widget_clock_monolith_serif
            config.fontStyle.equals("mono", ignoreCase = true) -> R.layout.widget_clock_monolith_mono
            else -> R.layout.widget_clock_monolith
        }

        val views = RemoteViews(context.packageName, layoutId)

        // 1. Pixel-perfect anti-aliased rounded background (0 to 40dp radius)
        val bgBitmap = WidgetBackgroundRenderer.createBackgroundBitmap(context, 480, 260, config)
        views.setImageViewBitmap(R.id.widget_bg, bgBitmap)

        // 2. Dynamic auto-contrasting typography & colors
        val (primaryText, secondaryText) = ConfigRepository.getAutoContrastingTextColor(config)
        val accentColor = ConfigRepository.parseAccentColor(config)

        if (layoutId == R.layout.widget_clock_stacked) {
            views.setTextColor(R.id.clock_hours, primaryText)
            views.setTextColor(R.id.clock_minutes, accentColor)

            val hourFmt = if (config.use24Hour) {
                if (config.leadingZero) "HH" else "H"
            } else {
                if (config.leadingZero) "hh" else "h"
            }
            views.setString(R.id.clock_hours, "setFormat12Hour", hourFmt)
            views.setString(R.id.clock_hours, "setFormat24Hour", hourFmt)
            views.setString(R.id.clock_minutes, "setFormat12Hour", "mm")
            views.setString(R.id.clock_minutes, "setFormat24Hour", "mm")

            if (config.scaleFactor != 1.0f) {
                val scaledSize = (52f * config.scaleFactor).coerceIn(28f, 68f)
                views.setTextViewTextSize(R.id.clock_hours, TypedValue.COMPLEX_UNIT_SP, scaledSize)
                views.setTextViewTextSize(R.id.clock_minutes, TypedValue.COMPLEX_UNIT_SP, scaledSize)
            }
        } else {
            views.setTextColor(R.id.clock_time, primaryText)
            views.setTextColor(R.id.clock_date, secondaryText)
            views.setInt(R.id.clock_dot, "setColorFilter", accentColor)

            // Comprehensive time, date, seconds, AM/PM, and scale formatting
            WidgetTimeFormatter.applyClockFormatting(
                views = views,
                config = config,
                timeViewId = R.id.clock_time,
                dateViewId = R.id.clock_date,
                dotViewId = R.id.clock_dot,
                baseTimeSizeSp = 56f
            )
        }

        // Deep link to Now tab
        val pendingIntent = createDeepLinkIntent(context, "now")
        views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

        return views
    }
}
