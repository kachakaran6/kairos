package com.samyukt.kairos.widgets

import android.content.Context
import android.content.SharedPreferences
import android.util.TypedValue
import android.view.View
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
        val category = widgetData.getString("next_moment_category", "TRAVEL")?.uppercase() ?: "TRAVEL"
        val isToday = widgetData.getBoolean("next_moment_is_today", false)

        val targetEpoch = widgetData.getLong("next_moment_target_epoch", 0L)
        val countingMode = widgetData.getString("next_moment_counting_mode", config.momentUnit) ?: config.momentUnit
        val customVal = widgetData.getString("next_moment_value", null)
        val defaultDays = widgetData.getInt("next_moment_days", 42)

        val (countText, textSizeSp) = if (isToday) {
            Pair("Today!", 42f)
        } else if (targetEpoch > 0L) {
            val nowMs = System.currentTimeMillis()
            val diffMs = targetEpoch - nowMs
            val absSec = Math.abs(diffMs) / 1000
            val d = absSec / 86400
            val totalHours = absSec / 3600
            val totalMinutes = absSec / 60

            when (countingMode.lowercase()) {
                "hours" -> Pair("${totalHours}h", 36f)
                "minutes" -> Pair("${totalMinutes}m", 36f)
                "seconds" -> Pair("${absSec}s", 34f)
                "weeks" -> Pair(String.format("%.1fw", d / 7.0), 40f)
                "months_days" -> {
                    val mo = d / 30
                    val remD = d % 30
                    val str = if (mo > 0) "${mo}m ${remD}d" else "${remD}d"
                    Pair(str, 32f)
                }
                else -> Pair("${d}d", 48f)
            }
        } else {
            val str = customVal ?: "${defaultDays}d"
            Pair(str, 44f)
        }

        if (layoutId == R.layout.widget_next_hero) {
            views.setTextColor(R.id.moment_category, accentColor)
            views.setTextColor(R.id.moment_days, primaryText)
            views.setTextColor(R.id.moment_separator, secondaryText)
            views.setTextColor(R.id.moment_chronometer, primaryText)
            views.setTextColor(R.id.moment_title, primaryText)
            views.setTextColor(R.id.moment_subtitle, secondaryText)

            views.setTextViewText(R.id.moment_title, title)

            if (isToday) {
                views.setTextViewText(R.id.moment_days, "Today!")
                views.setViewVisibility(R.id.moment_days, View.VISIBLE)
                views.setViewVisibility(R.id.moment_separator, View.GONE)
                views.setViewVisibility(R.id.moment_chronometer, View.GONE)
                val scaledSize = (42f * config.scaleFactor).coerceIn(24f, 56f)
                views.setTextViewTextSize(R.id.moment_days, TypedValue.COMPLEX_UNIT_SP, scaledSize)
            } else if (targetEpoch > 0L) {
                val nowMs = System.currentTimeMillis()
                val diffMs = targetEpoch - nowMs
                val absSec = Math.abs(diffMs) / 1000
                val d = absSec / 86400
                val dayRemainderMs = Math.abs(diffMs) % (86400 * 1000)
                val totalHours = absSec / 3600
                val totalMinutes = absSec / 60

                when (countingMode.lowercase()) {
                    "continuous", "live_countdown" -> {
                        if (d > 0) {
                            views.setTextViewText(R.id.moment_days, "${d}d")
                            views.setViewVisibility(R.id.moment_days, View.VISIBLE)
                            views.setViewVisibility(R.id.moment_separator, View.VISIBLE)

                            val base = android.os.SystemClock.elapsedRealtime() + dayRemainderMs
                            views.setChronometer(R.id.moment_chronometer, base, "%s", true)
                            views.setChronometerCountDown(R.id.moment_chronometer, true)
                            views.setViewVisibility(R.id.moment_chronometer, View.VISIBLE)

                            val scaledDays = (32f * config.scaleFactor).coerceIn(18f, 40f)
                            val scaledChrono = (24f * config.scaleFactor).coerceIn(16f, 32f)
                            views.setTextViewTextSize(R.id.moment_days, TypedValue.COMPLEX_UNIT_SP, scaledDays)
                            views.setTextViewTextSize(R.id.moment_chronometer, TypedValue.COMPLEX_UNIT_SP, scaledChrono)
                        } else {
                            views.setViewVisibility(R.id.moment_days, View.GONE)
                            views.setViewVisibility(R.id.moment_separator, View.GONE)

                            val base = android.os.SystemClock.elapsedRealtime() + Math.max(0L, diffMs)
                            views.setChronometer(R.id.moment_chronometer, base, "%s", true)
                            views.setChronometerCountDown(R.id.moment_chronometer, true)
                            views.setViewVisibility(R.id.moment_chronometer, View.VISIBLE)

                            val scaledChrono = (38f * config.scaleFactor).coerceIn(22f, 50f)
                            views.setTextViewTextSize(R.id.moment_chronometer, TypedValue.COMPLEX_UNIT_SP, scaledChrono)
                        }
                    }
                    "seconds" -> {
                        views.setViewVisibility(R.id.moment_days, View.GONE)
                        views.setViewVisibility(R.id.moment_separator, View.GONE)

                        val base = android.os.SystemClock.elapsedRealtime() + Math.max(0L, diffMs)
                        views.setChronometer(R.id.moment_chronometer, base, "%s", true)
                        views.setChronometerCountDown(R.id.moment_chronometer, true)
                        views.setViewVisibility(R.id.moment_chronometer, View.VISIBLE)

                        val scaledChrono = (36f * config.scaleFactor).coerceIn(20f, 48f)
                        views.setTextViewTextSize(R.id.moment_chronometer, TypedValue.COMPLEX_UNIT_SP, scaledChrono)
                    }
                    "hours" -> {
                        views.setViewVisibility(R.id.moment_separator, View.GONE)
                        views.setViewVisibility(R.id.moment_chronometer, View.GONE)
                        views.setTextViewText(R.id.moment_days, "${totalHours}h")
                        views.setViewVisibility(R.id.moment_days, View.VISIBLE)
                        val scaledSize = (36f * config.scaleFactor).coerceIn(20f, 44f)
                        views.setTextViewTextSize(R.id.moment_days, TypedValue.COMPLEX_UNIT_SP, scaledSize)
                    }
                    "minutes" -> {
                        views.setViewVisibility(R.id.moment_separator, View.GONE)
                        views.setViewVisibility(R.id.moment_chronometer, View.GONE)
                        views.setTextViewText(R.id.moment_days, "${totalMinutes}m")
                        views.setViewVisibility(R.id.moment_days, View.VISIBLE)
                        val scaledSize = (34f * config.scaleFactor).coerceIn(20f, 44f)
                        views.setTextViewTextSize(R.id.moment_days, TypedValue.COMPLEX_UNIT_SP, scaledSize)
                    }
                    "weeks" -> {
                        views.setViewVisibility(R.id.moment_separator, View.GONE)
                        views.setViewVisibility(R.id.moment_chronometer, View.GONE)
                        val w = d / 7.0
                        views.setTextViewText(R.id.moment_days, String.format("%.1fw", w))
                        views.setViewVisibility(R.id.moment_days, View.VISIBLE)
                        val scaledSize = (38f * config.scaleFactor).coerceIn(20f, 46f)
                        views.setTextViewTextSize(R.id.moment_days, TypedValue.COMPLEX_UNIT_SP, scaledSize)
                    }
                    "months_days" -> {
                        views.setViewVisibility(R.id.moment_separator, View.GONE)
                        views.setViewVisibility(R.id.moment_chronometer, View.GONE)
                        val mo = d / 30
                        val remD = d % 30
                        val str = if (mo > 0) "${mo}m ${remD}d" else "${remD}d"
                        views.setTextViewText(R.id.moment_days, str)
                        views.setViewVisibility(R.id.moment_days, View.VISIBLE)
                        val scaledSize = (32f * config.scaleFactor).coerceIn(18f, 42f)
                        views.setTextViewTextSize(R.id.moment_days, TypedValue.COMPLEX_UNIT_SP, scaledSize)
                    }
                    else -> {
                        views.setViewVisibility(R.id.moment_separator, View.GONE)
                        views.setViewVisibility(R.id.moment_chronometer, View.GONE)
                        views.setTextViewText(R.id.moment_days, "$d")
                        views.setViewVisibility(R.id.moment_days, View.VISIBLE)
                        val scaledSize = (48f * config.scaleFactor).coerceIn(24f, 56f)
                        views.setTextViewTextSize(R.id.moment_days, TypedValue.COMPLEX_UNIT_SP, scaledSize)
                    }
                }
            } else {
                views.setViewVisibility(R.id.moment_separator, View.GONE)
                views.setViewVisibility(R.id.moment_chronometer, View.GONE)
                views.setTextViewText(R.id.moment_days, customVal ?: "${defaultDays}d")
                views.setViewVisibility(R.id.moment_days, View.VISIBLE)
                val scaledSize = (44f * config.scaleFactor).coerceIn(24f, 56f)
                views.setTextViewTextSize(R.id.moment_days, TypedValue.COMPLEX_UNIT_SP, scaledSize)
            }

            // Category visibility
            if (config.showMomentCategory) {
                views.setViewVisibility(R.id.moment_category, View.VISIBLE)
                views.setTextViewText(R.id.moment_category, if (isToday) "TODAY!" else category)
            } else {
                views.setViewVisibility(R.id.moment_category, View.GONE)
            }

            // Subtitle / Date visibility
            if (config.showMomentDate) {
                views.setViewVisibility(R.id.moment_subtitle, View.VISIBLE)
                views.setTextViewText(R.id.moment_subtitle, subtitle)
            } else {
                views.setViewVisibility(R.id.moment_subtitle, View.GONE)
            }

            // Clean, sharp Progress Ring with rounded caps and gradient
            if (config.showMomentProgress) {
                views.setViewVisibility(R.id.moment_progress_ring, View.VISIBLE)
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
                views.setViewVisibility(R.id.moment_progress_ring, View.GONE)
            }
        } else {
            views.setTextColor(R.id.compact_title, primaryText)
            views.setTextColor(R.id.compact_time_left, secondaryText)
            views.setTextColor(R.id.compact_days, accentColor)
            views.setTextColor(R.id.compact_chronometer, accentColor)
            views.setInt(R.id.compact_dot, "setColorFilter", accentColor)

            views.setTextViewText(R.id.compact_title, title)

            if (isToday) {
                views.setTextViewText(R.id.compact_days, "Today!")
                views.setViewVisibility(R.id.compact_days, View.VISIBLE)
                views.setViewVisibility(R.id.compact_chronometer, View.GONE)
                views.setTextViewText(R.id.compact_time_left, "today")
            } else if (targetEpoch > 0L) {
                val nowMs = System.currentTimeMillis()
                val diffMs = targetEpoch - nowMs
                val absSec = Math.abs(diffMs) / 1000
                val d = absSec / 86400
                val dayRemainderMs = Math.abs(diffMs) % (86400 * 1000)

                if (countingMode.lowercase() in listOf("continuous", "live_countdown", "seconds")) {
                    if (d > 0 && countingMode.lowercase() != "seconds") {
                        views.setTextViewText(R.id.compact_days, "${d}d ")
                        views.setViewVisibility(R.id.compact_days, View.VISIBLE)
                    } else {
                        views.setViewVisibility(R.id.compact_days, View.GONE)
                    }
                    val base = android.os.SystemClock.elapsedRealtime() + (if (d > 0 && countingMode.lowercase() != "seconds") dayRemainderMs else Math.max(0L, diffMs))
                    views.setChronometer(R.id.compact_chronometer, base, "%s", true)
                    views.setChronometerCountDown(R.id.compact_chronometer, true)
                    views.setViewVisibility(R.id.compact_chronometer, View.VISIBLE)
                    views.setTextViewText(R.id.compact_time_left, if (d > 0) "in $d days" else "countdown")
                } else {
                    views.setViewVisibility(R.id.compact_chronometer, View.GONE)
                    views.setViewVisibility(R.id.compact_days, View.VISIBLE)
                    views.setTextViewText(R.id.compact_days, countText)
                    views.setTextViewText(R.id.compact_time_left, "in $countText")
                }
            } else {
                views.setViewVisibility(R.id.compact_chronometer, View.GONE)
                views.setViewVisibility(R.id.compact_days, View.VISIBLE)
                views.setTextViewText(R.id.compact_days, customVal ?: "${defaultDays}d")
                views.setTextViewText(R.id.compact_time_left, "in ${defaultDays}d")
            }
        }

        KairosWidgetTicker.start(context)

        val pendingIntent = createDeepLinkIntent(context, "moments")
        views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

        return views
    }

    /**
     * High-efficiency 1-second tick: uses partiallyUpdateAppWidget with zero bitmap allocations
     * to keep CPU at ~0% and prevent binder IPC transaction throttling.
     */
    fun tick(
        context: Context,
        appWidgetManager: android.appwidget.AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        val targetEpoch = widgetData.getLong("next_moment_target_epoch", 0L)
        if (targetEpoch <= 0L) return
        val isToday = widgetData.getBoolean("next_moment_is_today", false)
        if (isToday) return

        val nowMs = System.currentTimeMillis()
        val diffMs = targetEpoch - nowMs
        val absSec = Math.abs(diffMs) / 1000
        val d = absSec / 86400
        val totalHours = absSec / 3600
        val totalMinutes = absSec / 60

        for (appWidgetId in appWidgetIds) {
            val config = ConfigRepository.getConfig(context, appWidgetId)
            val countingMode = (widgetData.getString("next_moment_counting_mode", config.momentUnit) ?: config.momentUnit).lowercase()

            val str = when (countingMode) {
                "hours" -> "${totalHours}h"
                "minutes" -> "${totalMinutes}m"
                else -> null
            }

            if (str != null) {
                val style = widgetData.getString("next_style_$appWidgetId", "hero")
                val layoutId = if (style == "compact") R.layout.widget_next_compact else R.layout.widget_next_hero
                val partial = RemoteViews(context.packageName, layoutId)
                if (layoutId == R.layout.widget_next_compact) {
                    partial.setTextViewText(R.id.compact_days, "$str ")
                } else {
                    partial.setTextViewText(R.id.moment_days, str)
                }
                appWidgetManager.partiallyUpdateAppWidget(appWidgetId, partial)
            }
        }
    }
}
