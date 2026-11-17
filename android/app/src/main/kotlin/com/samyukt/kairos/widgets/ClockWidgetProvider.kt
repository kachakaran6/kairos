package com.samyukt.kairos.widgets

import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import com.samyukt.kairos.R

class ClockWidgetProvider : BaseKairosWidget() {

    override fun buildRemoteViews(
        context: Context,
        widgetData: SharedPreferences,
        appWidgetId: Int
    ): RemoteViews {
        val isDark = widgetData.getBoolean("is_dark", true)
        val style = widgetData.getString("clock_style_$appWidgetId", "monolith")

        val layoutId = when (style) {
            "stacked" -> R.layout.widget_clock_stacked
            else -> R.layout.widget_clock_monolith
        }

        val views = RemoteViews(context.packageName, layoutId)

        // Background styling
        views.setInt(
            R.id.widget_root,
            "setBackgroundResource",
            if (isDark) R.drawable.widget_background_dark else R.drawable.widget_background_light
        )

        // Deep link to Now tab
        val pendingIntent = createDeepLinkIntent(context, "now")
        views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

        return views
    }
}
