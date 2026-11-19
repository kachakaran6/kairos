package com.samyukt.kairos.widgets

import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.util.TypedValue
import android.view.View
import android.widget.RemoteViews
import com.samyukt.kairos.R

class ComboWidgetProvider : BaseKairosWidget() {

    override fun buildRemoteViews(
        context: Context,
        widgetData: SharedPreferences,
        appWidgetId: Int,
        config: WidgetConfig
    ): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_combo_dashboard)

        // 1. Pixel-perfect anti-aliased rounded background (0 to 40dp radius)
        val bgBitmap = WidgetBackgroundRenderer.createBackgroundBitmap(context, 540, 260, config)
        views.setImageViewBitmap(R.id.widget_bg, bgBitmap)

        // 2. Dynamic auto-contrasting typography & luxury colors
        val (primaryText, secondaryText) = ConfigRepository.getAutoContrastingTextColor(config)
        val accentColor = ConfigRepository.parseAccentColor(config)

        views.setTextColor(R.id.combo_clock, primaryText)
        views.setTextColor(R.id.combo_date, secondaryText)
        views.setTextColor(R.id.combo_alarm_text, primaryText)
        views.setTextColor(R.id.combo_moment_category, accentColor)
        views.setTextColor(R.id.combo_moment_days, primaryText)
        views.setTextColor(R.id.combo_moment_title, secondaryText)

        views.setInt(R.id.combo_divider, "setColorFilter", Color.argb(32, Color.red(secondaryText), Color.green(secondaryText), Color.blue(secondaryText)))
        views.setInt(R.id.combo_alarm_dot, "setColorFilter", accentColor)

        // Apply dynamic clock & date format
        WidgetTimeFormatter.applyClockFormatting(
            views = views,
            config = config,
            timeViewId = R.id.combo_clock,
            dateViewId = R.id.combo_date,
            dotViewId = 0,
            baseTimeSizeSp = 44f
        )

        // 3. Graceful Alarm handling - respect config.showAlarm
        if (config.showAlarm) {
            views.setViewVisibility(R.id.combo_alarm_container, View.VISIBLE)
            val rawAlarmTime = widgetData.getString("next_alarm_time", null)
            if (rawAlarmTime.isNullOrEmpty() || rawAlarmTime == "--:--") {
                views.setTextViewText(R.id.combo_alarm_text, "Set alarm")
            } else {
                views.setTextViewText(R.id.combo_alarm_text, "Alarm $rawAlarmTime")
            }
        } else {
            views.setViewVisibility(R.id.combo_alarm_container, View.GONE)
        }

        // 4. Moment Data & Custom Unit formatting
        val rawTitle = widgetData.getString("next_moment_title", null)
        val momentTitle = if (rawTitle.isNullOrEmpty() || rawTitle == "Nothing ahead yet") "Trip to Kyoto" else rawTitle
        val isToday = widgetData.getBoolean("next_moment_is_today", false)
        val targetEpoch = widgetData.getLong("next_moment_target_epoch", 0L)
        val countingMode = widgetData.getString("next_moment_counting_mode", config.momentUnit) ?: config.momentUnit
        val customVal = widgetData.getString("next_moment_value", null)
        val momentDays = widgetData.getInt("next_moment_days", 42)

        views.setTextViewText(R.id.combo_moment_title, momentTitle)
        if (isToday) {
            views.setTextViewText(R.id.combo_moment_category, "TODAY!")
            views.setTextViewText(R.id.combo_moment_days, "Today!")
        } else {
            views.setTextViewText(R.id.combo_moment_category, "NEXT MOMENT")
            val displayCount = if (targetEpoch > 0L) {
                val nowMs = System.currentTimeMillis()
                val diffMs = targetEpoch - nowMs
                val absSec = Math.abs(diffMs) / 1000
                val d = absSec / 86400
                val h = (absSec % 86400) / 3600
                val m = (absSec % 3600) / 60
                val s = absSec % 60
                val totalHours = absSec / 3600
                val totalMinutes = absSec / 60

                when (countingMode.lowercase()) {
                    "continuous", "live_countdown" -> if (d > 0) "${d}d ${h}h ${m}m" else "${h}h ${m}m ${s}s"
                    "hours" -> "${totalHours}h left"
                    "minutes" -> "${totalMinutes}m left"
                    "seconds" -> "${absSec}s left"
                    else -> "${d}d left"
                }
            } else {
                customVal ?: "$momentDays days left"
            }
            views.setTextViewText(R.id.combo_moment_days, displayCount)
        }

        // 5. Clean, sharp Progress Ring (replaces muddy concentric circles)
        if (config.showMomentProgress) {
            views.setViewVisibility(R.id.combo_life_rings, View.VISIBLE)
            val progress = widgetData.getFloat("next_moment_progress", 0.68f).coerceIn(0.05f, 1.0f)
            val progressPct = (progress * 100).toInt()
            val ringBmp = WidgetProgressRenderer.createProgressRingBitmap(
                context = context,
                sizeDp = 56,
                progressPercent = progress,
                centerValue = "$progressPct%",
                centerLabel = null,
                accentColor = accentColor,
                textColor = primaryText,
                secondaryTextColor = secondaryText
            )
            views.setImageViewBitmap(R.id.combo_life_rings, ringBmp)
        } else {
            views.setViewVisibility(R.id.combo_life_rings, View.GONE)
        }

        KairosWidgetTicker.start(context)

        val pendingIntent = createDeepLinkIntent(context, "dashboard")
        views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

        return views
    }

    /**
     * High-efficiency 1-second tick: uses partiallyUpdateAppWidget with zero bitmap allocations.
     */
    fun tick(
        context: Context,
        appWidgetManager: android.appwidget.AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        val targetEpoch = widgetData.getLong("next_moment_target_epoch", 0L)
        if (targetEpoch <= 0L) return

        val nowMs = System.currentTimeMillis()
        val diffMs = targetEpoch - nowMs
        val absSec = Math.abs(diffMs) / 1000
        val d = absSec / 86400
        val h = (absSec % 86400) / 3600
        val m = (absSec % 3600) / 60
        val s = absSec % 60

        for (appWidgetId in appWidgetIds) {
            val config = ConfigRepository.getConfig(context, appWidgetId)
            val countingMode = (widgetData.getString("next_moment_counting_mode", config.momentUnit) ?: config.momentUnit).lowercase()

            val displayCount = when (countingMode) {
                "continuous", "live_countdown" -> if (d > 0) "${d}d ${h}h ${m}m" else "${h}h ${m}m ${s}s"
                "seconds" -> "${absSec}s left"
                else -> null
            }

            if (displayCount != null) {
                val partial = RemoteViews(context.packageName, R.layout.widget_combo_dashboard)
                partial.setTextViewText(R.id.combo_moment_days, displayCount)
                appWidgetManager.partiallyUpdateAppWidget(appWidgetId, partial)
            }
        }
    }
}
