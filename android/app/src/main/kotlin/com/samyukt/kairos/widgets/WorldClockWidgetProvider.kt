package com.samyukt.kairos.widgets

import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.widget.RemoteViews
import com.samyukt.kairos.R

class WorldClockWidgetProvider : BaseKairosWidget() {

    override fun buildRemoteViews(
        context: Context,
        widgetData: SharedPreferences,
        appWidgetId: Int,
        config: WidgetConfig
    ): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_world_clock)

        // 1. Pixel-perfect anti-aliased rounded background (0 to 40dp radius)
        val bgBitmap = WidgetBackgroundRenderer.createBackgroundBitmap(context, 480, 260, config)
        views.setImageViewBitmap(R.id.widget_bg, bgBitmap)

        // 2. Dynamic typography & colors
        val (primaryText, secondaryText) = ConfigRepository.getAutoContrastingTextColor(config)
        val accentColor = ConfigRepository.parseAccentColor(config)

        views.setTextColor(R.id.world_header, accentColor)

        val city1 = widgetData.getString("world_city_1", "London") ?: "London"
        val tz1 = widgetData.getString("world_tz_1", "Europe/London") ?: "Europe/London"

        val city2 = widgetData.getString("world_city_2", "New York") ?: "New York"
        val tz2 = widgetData.getString("world_tz_2", "America/New_York") ?: "America/New_York"

        val city3 = widgetData.getString("world_city_3", "Tokyo") ?: "Tokyo"
        val tz3 = widgetData.getString("world_tz_3", "Asia/Tokyo") ?: "Asia/Tokyo"

        val timePattern = WidgetTimeFormatter.getTimeFormat(config)

        views.setTextViewText(R.id.city_name_1, city1)
        views.setString(R.id.city_clock_1, "setTimeZone", tz1)
        views.setString(R.id.city_clock_1, "setFormat12Hour", timePattern)
        views.setString(R.id.city_clock_1, "setFormat24Hour", timePattern)
        views.setTextColor(R.id.city_name_1, secondaryText)
        views.setTextColor(R.id.city_clock_1, primaryText)

        views.setTextViewText(R.id.city_name_2, city2)
        views.setString(R.id.city_clock_2, "setTimeZone", tz2)
        views.setString(R.id.city_clock_2, "setFormat12Hour", timePattern)
        views.setString(R.id.city_clock_2, "setFormat24Hour", timePattern)
        views.setTextColor(R.id.city_name_2, secondaryText)
        views.setTextColor(R.id.city_clock_2, primaryText)

        views.setTextViewText(R.id.city_name_3, city3)
        views.setString(R.id.city_clock_3, "setTimeZone", tz3)
        views.setString(R.id.city_clock_3, "setFormat12Hour", timePattern)
        views.setString(R.id.city_clock_3, "setFormat24Hour", timePattern)
        views.setTextColor(R.id.city_name_3, secondaryText)
        views.setTextColor(R.id.city_clock_3, primaryText)

        val pendingIntent = createDeepLinkIntent(context, "world_clock")
        views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

        return views
    }
}
