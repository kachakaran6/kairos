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

        // 1. Pixel-perfect anti-aliased rounded background (0 to 40dp radius)
        val bgBitmap = WidgetBackgroundRenderer.createBackgroundBitmap(context, 480, 260, config)
        views.setImageViewBitmap(R.id.widget_bg, bgBitmap)

        // 2. Dynamic typography & colors
        val (primaryText, secondaryText) = ConfigRepository.getAutoContrastingTextColor(config)
        val accentColor = ConfigRepository.parseAccentColor(config)

        val rawTitle = widgetData.getString("next_moment_title", null)
        val title = if (rawTitle.isNullOrEmpty() || rawTitle == "Nothing ahead yet") "Trip to Kyoto" else rawTitle
        val subtitle = widgetData.getString("next_moment_subtitle", "Autumn exploration") ?: "Autumn exploration"
        val days = widgetData.getInt("next_moment_days", 42)
        val category = widgetData.getString("next_moment_category", "TRAVEL")?.uppercase() ?: "TRAVEL"
        val isToday = widgetData.getBoolean("next_moment_is_today", false)

        if (layoutId == R.layout.widget_next_hero) {
            views.setTextColor(R.id.moment_category, accentColor)
            views.setTextColor(R.id.moment_days, primaryText)
            views.setTextColor(R.id.moment_title, primaryText)
            views.setTextColor(R.id.moment_subtitle, secondaryText)

            views.setTextViewText(R.id.moment_title, title)
            views.setTextViewText(R.id.moment_subtitle, subtitle)
            views.setTextViewText(R.id.moment_category, if (isToday) "TODAY!" else category)
            views.setTextViewText(R.id.moment_days, if (isToday) "Today!" else "$days")

            // Clean, sharp Progress Ring with rounded caps and gradient
            val progress = widgetData.getFloat("next_moment_progress", 0.68f).coerceIn(0.05f, 1.0f)
            val ringBmp = WidgetProgressRenderer.createProgressRingBitmap(
                context = context,
                sizeDp = 80,
                progressPercent = progress,
                centerValue = "${(progress * 100).toInt()}%",
                centerLabel = "progress",
                accentColor = accentColor,
                textColor = primaryText,
                secondaryTextColor = secondaryText
            )
            views.setImageViewBitmap(R.id.moment_progress_ring, ringBmp)
        } else {
            views.setTextColor(R.id.compact_title, primaryText)
            views.setTextColor(R.id.compact_time_left, secondaryText)
            views.setTextColor(R.id.compact_days, accentColor)
            views.setInt(R.id.compact_dot, "setColorFilter", accentColor)

            views.setTextViewText(R.id.compact_title, title)
            views.setTextViewText(R.id.compact_time_left, if (isToday) "today" else "in $days days")
            views.setTextViewText(R.id.compact_days, if (isToday) "0d" else "${days}d")
        }

        val pendingIntent = createDeepLinkIntent(context, "next")
        views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

        return views
    }
}
