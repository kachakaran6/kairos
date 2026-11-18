package com.samyukt.kairos.widgets

import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import com.samyukt.kairos.R

class NextMomentWidgetProvider : BaseKairosWidget() {

    override fun buildRemoteViews(
        context: Context,
        widgetData: SharedPreferences,
        appWidgetId: Int,
        config: WidgetConfig
    ): RemoteViews {
        val style = widgetData.getString("next_style_$appWidgetId", "hero")

        val layoutId = when (style) {
            "compact" -> R.layout.widget_next_compact
            else -> R.layout.widget_next_hero
        }

        val views = RemoteViews(context.packageName, layoutId)

        // Dynamic background with real opacity
        val bgColor = ConfigRepository.getEffectiveBackgroundColor(config)
        views.setInt(R.id.widget_root, "setBackgroundColor", bgColor)

        // Dynamic typography & colors
        val (primaryText, secondaryText) = ConfigRepository.getAutoContrastingTextColor(config)
        val accentColor = ConfigRepository.parseAccentColor(config)

        val title = widgetData.getString("next_moment_title", "Nothing ahead yet") ?: "Nothing ahead yet"
        val subtitle = widgetData.getString("next_moment_subtitle", "") ?: ""
        val days = widgetData.getInt("next_moment_days", 0)
        val category = widgetData.getString("next_moment_category", "EVENT")?.uppercase() ?: "EVENT"
        val isToday = widgetData.getBoolean("next_moment_is_today", false)

        if (layoutId == R.layout.widget_next_hero) {
            views.setTextColor(R.id.moment_category, accentColor)
            views.setTextColor(R.id.moment_days, primaryText)
            views.setTextColor(R.id.moment_title, primaryText)
            views.setTextColor(R.id.moment_subtitle, secondaryText)

            views.setTextViewText(R.id.moment_title, title)
            views.setTextViewText(R.id.moment_subtitle, subtitle)
            views.setTextViewText(R.id.moment_category, if (isToday) "TODAY!" else category)
            views.setTextViewText(R.id.moment_days, if (isToday) "0" else "$days")

            // Load progress ring artwork if available
            val ringPath = widgetData.getString("next_moment_ring", null)
            val bitmap = loadBitmapFromFile(ringPath)
            if (bitmap != null) {
                views.setImageViewBitmap(R.id.moment_progress_ring, bitmap)
            }
        } else {
            views.setInt(R.id.compact_dot, "setColorFilter", accentColor)
            views.setTextColor(R.id.compact_title, primaryText)
            views.setTextColor(R.id.compact_time_left, secondaryText)
            views.setTextColor(R.id.compact_days, accentColor)

            views.setTextViewText(R.id.compact_title, title)
            views.setTextViewText(R.id.compact_time_left, if (isToday) "today!" else "in $days days")
            views.setTextViewText(R.id.compact_days, "${days}d")
        }

        val pendingIntent = createDeepLinkIntent(context, "moments/next")
        views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

        return views
    }
}
