package com.samyukt.kairos.widgets

import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import com.samyukt.kairos.R

class WorldClockWidgetProvider : BaseKairosWidget() {

    override fun buildRemoteViews(
        context: Context,
        widgetData: SharedPreferences,
        appWidgetId: Int
    ): RemoteViews {
        val isDark = widgetData.getBoolean("is_dark", true)
        val views = RemoteViews(context.packageName, R.layout.widget_world_clock)

        views.setInt(
            R.id.widget_root,
            "setBackgroundResource",
            if (isDark) R.drawable.widget_background_dark else R.drawable.widget_background_light
        )

        val pendingIntent = createDeepLinkIntent(context, "world_clock")
        views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

        return views
    }
}
