package com.samyukt.kairos.widgets

import android.content.Context
import android.content.SharedPreferences
import android.util.TypedValue
import android.view.View
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
        
        val targetEpoch = widgetData.getLong("then_moment_target_epoch", 0L)
        val countingMode = widgetData.getString("then_moment_counting_mode", config.momentUnit) ?: config.momentUnit
        val customVal = widgetData.getString("then_moment_value", null)
        val defaultDays = widgetData.getInt("then_moment_days", 520)

        views.setTextColor(R.id.then_header, accentColor)
        views.setTextColor(R.id.then_days, primaryText)
        views.setTextColor(R.id.then_unit_label, secondaryText)
        views.setTextColor(R.id.then_title, primaryText)
        views.setTextColor(R.id.then_date_subtitle, secondaryText)

        views.setTextViewText(R.id.then_title, title)

        if (targetEpoch > 0L) {
            val nowMs = System.currentTimeMillis()
            val diffMs = Math.abs(nowMs - targetEpoch)
            val diffSec = diffMs / 1000
            val d = diffSec / 86400
            val h = (diffSec % 86400) / 3600
            val m = (diffSec % 3600) / 60
            val s = diffSec % 60
            val totalHours = diffSec / 3600
            val totalMinutes = diffSec / 60

            when (countingMode.lowercase()) {
                "continuous", "live_countdown" -> {
                    val str = if (d > 0) "${d}d ${h}h ${m}m ${s}s" else if (h > 0) "${h}h ${m}m ${s}s" else if (m > 0) "${m}m ${s}s" else "${s}s"
                    views.setTextViewText(R.id.then_days, str)
                    views.setViewVisibility(R.id.then_unit_label, View.GONE)
                    views.setTextViewText(R.id.then_date_subtitle, "$d days since this moment")
                    views.setViewVisibility(R.id.then_date_subtitle, View.VISIBLE)

                    val scaledSize = (22f * config.scaleFactor).coerceIn(16f, 30f)
                    views.setTextViewTextSize(R.id.then_days, TypedValue.COMPLEX_UNIT_SP, scaledSize)
                }
                "hours" -> {
                    views.setTextViewText(R.id.then_days, "${totalHours}h")
                    views.setTextViewText(R.id.then_unit_label, " ago")
                    views.setViewVisibility(R.id.then_unit_label, View.VISIBLE)
                    views.setTextViewText(R.id.then_date_subtitle, "$d days elapsed")
                    views.setViewVisibility(R.id.then_date_subtitle, View.VISIBLE)

                    val scaledSize = (36f * config.scaleFactor).coerceIn(20f, 44f)
                    views.setTextViewTextSize(R.id.then_days, TypedValue.COMPLEX_UNIT_SP, scaledSize)
                }
                "minutes" -> {
                    views.setTextViewText(R.id.then_days, "${totalMinutes}m")
                    views.setTextViewText(R.id.then_unit_label, " ago")
                    views.setViewVisibility(R.id.then_unit_label, View.VISIBLE)
                    views.setTextViewText(R.id.then_date_subtitle, "$d days elapsed")
                    views.setViewVisibility(R.id.then_date_subtitle, View.VISIBLE)

                    val scaledSize = (34f * config.scaleFactor).coerceIn(20f, 44f)
                    views.setTextViewTextSize(R.id.then_days, TypedValue.COMPLEX_UNIT_SP, scaledSize)
                }
                "seconds" -> {
                    views.setTextViewText(R.id.then_days, "${diffSec}s")
                    views.setTextViewText(R.id.then_unit_label, " ago")
                    views.setViewVisibility(R.id.then_unit_label, View.VISIBLE)
                    views.setTextViewText(R.id.then_date_subtitle, "$d days elapsed")
                    views.setViewVisibility(R.id.then_date_subtitle, View.VISIBLE)

                    val scaledSize = (32f * config.scaleFactor).coerceIn(18f, 40f)
                    views.setTextViewTextSize(R.id.then_days, TypedValue.COMPLEX_UNIT_SP, scaledSize)
                }
                "weeks" -> {
                    val w = d / 7.0
                    views.setTextViewText(R.id.then_days, String.format("%.1fw", w))
                    views.setTextViewText(R.id.then_unit_label, " ago")
                    views.setViewVisibility(R.id.then_unit_label, View.VISIBLE)
                    views.setTextViewText(R.id.then_date_subtitle, "$d days ago")
                    views.setViewVisibility(R.id.then_date_subtitle, View.VISIBLE)

                    val scaledSize = (38f * config.scaleFactor).coerceIn(20f, 46f)
                    views.setTextViewTextSize(R.id.then_days, TypedValue.COMPLEX_UNIT_SP, scaledSize)
                }
                else -> {
                    views.setTextViewText(R.id.then_days, "$d")
                    views.setTextViewText(R.id.then_unit_label, " days ago")
                    views.setViewVisibility(R.id.then_unit_label, View.VISIBLE)
                    views.setViewVisibility(R.id.then_date_subtitle, View.GONE)

                    val scaledSize = (48f * config.scaleFactor).coerceIn(24f, 56f)
                    views.setTextViewTextSize(R.id.then_days, TypedValue.COMPLEX_UNIT_SP, scaledSize)
                }
            }
        } else {
            views.setTextViewText(R.id.then_days, customVal ?: "$defaultDays")
            views.setTextViewText(R.id.then_unit_label, " days ago")
            views.setViewVisibility(R.id.then_unit_label, View.VISIBLE)
            views.setViewVisibility(R.id.then_date_subtitle, View.GONE)

            val scaledSize = (46f * config.scaleFactor).coerceIn(24f, 56f)
            views.setTextViewTextSize(R.id.then_days, TypedValue.COMPLEX_UNIT_SP, scaledSize)
        }

        // Start live ticker when a widget instance is rendered
        KairosWidgetTickerService.start(context)

        val pendingIntent = createDeepLinkIntent(context, "moments")
        views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

        return views
    }
}
