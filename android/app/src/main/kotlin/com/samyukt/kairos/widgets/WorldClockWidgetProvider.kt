package com.samyukt.kairos.widgets

import android.content.Context
import android.content.SharedPreferences
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

        // Dynamic background with real opacity
        val bgColor = ConfigRepository.getEffectiveBackgroundColor(config)
        views.setInt(R.id.widget_root, "setBackgroundColor", bgColor)

        // Dynamic typography & colors
        val (primaryText, secondaryText) = ConfigRepository.getAutoContrastingTextColor(config)
        val accentColor = ConfigRepository.parseAccentColor(config)

        views.setTextColor(R.id.world_header, accentColor)

        val cityNames = listOf(R.id.city_name_1, R.id.city_name_2, R.id.city_name_3, R.id.city_name_4)
        val cityClocks = listOf(R.id.city_clock_1, R.id.city_clock_2, R.id.city_clock_3, R.id.city_clock_4)

        for (nameId in cityNames) {
            views.setTextColor(nameId, secondaryText)
        }
        for (clockId in cityClocks) {
            views.setTextColor(clockId, primaryText)
        }

        val pendingIntent = createDeepLinkIntent(context, "world_clock")
        views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

        return views
    }
}
