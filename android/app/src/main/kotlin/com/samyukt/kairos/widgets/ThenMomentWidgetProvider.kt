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
        
        val targetEpoch = widgetData.getLong("then_moment_target_epoch", 0L)
        val countingMode = widgetData.getString("then_moment_counting_mode", config.momentUnit) ?: config.momentUnit
        val customVal = widgetData.getString("then_moment_value", null)
        val defaultDays = widgetData.getInt("then_moment_days", 520)

        val (countText, unitText, textSizeSp) = if (targetEpoch > 0L) {
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
                    Triple(str, "ago", 24f)
                }
                "hours" -> Triple("${totalHours}h", "ago", 36f)
                "minutes" -> Triple("${totalMinutes}m", "ago", 36f)
                "seconds" -> Triple("${diffSec}s", "ago", 34f)
                "weeks" -> {
                    val w = d / 7.0
                    Triple(String.format("%.1fw", w), "ago", 38f)
                }
                "months_days" -> {
                    val mo = d / 30
                    val remD = d % 30
                    val str = if (mo > 0) "${mo}m ${remD}d" else "${remD}d"
                    Triple(str, "ago", 32f)
                }
                else -> Triple("$d", "days ago", 50f)
            }
        } else {
            val count = customVal ?: "$defaultDays"
            val label = widgetData.getString("then_moment_unit_label", "days ago") ?: "days ago"
            Triple(count, label, 44f)
        }

        views.setTextColor(R.id.then_header, accentColor)
        views.setTextColor(R.id.then_days, primaryText)
        views.setTextColor(R.id.then_unit_label, secondaryText)
        views.setTextColor(R.id.then_title, primaryText)

        views.setTextViewText(R.id.then_title, title)
        views.setTextViewText(R.id.then_days, countText)
        views.setTextViewText(R.id.then_unit_label, " $unitText")

        val scaledSize = (textSizeSp * config.scaleFactor).coerceIn(18f, 64f)
        views.setTextViewTextSize(R.id.then_days, TypedValue.COMPLEX_UNIT_SP, scaledSize)

        val pendingIntent = createDeepLinkIntent(context, "moments")
        views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

        return views
    }
}
