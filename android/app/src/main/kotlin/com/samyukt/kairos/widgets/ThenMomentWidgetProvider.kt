package com.samyukt.kairos.widgets

import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import com.samyukt.kairos.R

class ThenMomentWidgetProvider : BaseKairosWidget() {

    override fun buildRemoteViews(
        context: Context,
        widgetData: SharedPreferences,
        appWidgetId: Int
    ): RemoteViews {
        val isDark = widgetData.getBoolean("is_dark", true)
        val views = RemoteViews(context.packageName, R.layout.widget_then_moment)

        views.setInt(
            R.id.widget_root,
            "setBackgroundResource",
            if (isDark) R.drawable.widget_background_dark else R.drawable.widget_background_light
        )

        val title = widgetData.getString("then_moment_title", "No memories yet") ?: "No memories yet"
        val days = widgetData.getInt("then_moment_days", 0)

        views.setTextViewText(R.id.then_title, title)
        views.setTextViewText(R.id.then_days, "$days")

        val pendingIntent = createDeepLinkIntent(context, "moments/then")
        views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

        return views
    }
}
