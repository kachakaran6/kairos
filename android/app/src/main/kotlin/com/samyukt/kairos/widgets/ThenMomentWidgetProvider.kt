package com.samyukt.kairos.widgets

import android.content.Context
import android.content.SharedPreferences
import android.util.TypedValue
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

        // 1. Pixel-perfect anti-aliased rounded background (0 to 40dp radius)
        val bgBitmap = WidgetBackgroundRenderer.createBackgroundBitmap(context, 480, 260, config)
        views.setImageViewBitmap(R.id.widget_bg, bgBitmap)

        // 2. Dynamic typography & colors
        val (primaryText, secondaryText) = ConfigRepository.getAutoContrastingTextColor(config)
        val accentColor = ConfigRepository.parseAccentColor(config)

        val rawTitle = widgetData.getString("then_moment_title", null)
        val title = if (rawTitle.isNullOrEmpty() || rawTitle == "Nothing behind yet") "Graduation Day" else rawTitle
        val customVal = widgetData.getString("then_moment_value", null)
        val days = widgetData.getInt("then_moment_days", 520)

        views.setTextColor(R.id.then_header, accentColor)
        views.setTextColor(R.id.then_days, primaryText)
        views.setTextColor(R.id.then_title, primaryText)

        views.setTextViewText(R.id.then_title, title)
        views.setTextViewText(R.id.then_days, customVal ?: "$days")

        if (config.scaleFactor != 1.0f) {
            val scaledSize = (44f * config.scaleFactor).coerceIn(24f, 64f)
            views.setTextViewTextSize(R.id.then_days, TypedValue.COMPLEX_UNIT_SP, scaledSize)
        }

        val pendingIntent = createDeepLinkIntent(context, "moments")
        views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

        return views
    }
}
