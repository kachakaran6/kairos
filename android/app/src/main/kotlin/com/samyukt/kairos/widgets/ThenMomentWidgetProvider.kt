package com.samyukt.kairos.widgets

import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import com.samyukt.kairos.R

class ThenMomentWidgetProvider : BaseKairosWidget() {

    override fun buildRemoteViews(
        context: Context,
        widgetData: SharedPreferences,
        appWidgetId: Int,
        config: WidgetConfig
    ): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_then_moment)

        // Dynamic background with real opacity
        val bgColor = ConfigRepository.getEffectiveBackgroundColor(config)
        views.setInt(R.id.widget_root, "setBackgroundColor", bgColor)

        // Dynamic typography & colors
        val (primaryText, secondaryText) = ConfigRepository.getAutoContrastingTextColor(config)
        val accentColor = ConfigRepository.parseAccentColor(config)

        views.setTextColor(R.id.then_header, secondaryText)
        views.setTextColor(R.id.then_days, primaryText)
        views.setTextColor(R.id.then_title, accentColor)

        val title = widgetData.getString("then_moment_title", "No memories yet") ?: "No memories yet"
        val days = widgetData.getInt("then_moment_days", 0)

        views.setTextViewText(R.id.then_title, title)
        views.setTextViewText(R.id.then_days, "$days")

        val pendingIntent = createDeepLinkIntent(context, "moments/then")
        views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

        return views
    }
}
