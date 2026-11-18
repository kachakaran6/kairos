package com.samyukt.kairos.widgets

import android.content.Context
import android.util.TypedValue
import android.view.View
import android.widget.RemoteViews
import com.samyukt.kairos.R

/**
 * Centralized time and date formatting engine for Kairos Android home widgets.
 * Accurately maps all WidgetConfig properties (12/24h, leading zeros, separators,
 * seconds, AM/PM, dynamic date tokens, custom format strings, and font scaling)
 * to Android RemoteViews TextClock widgets.
 */
object WidgetTimeFormatter {

    /**
     * Builds the exact time format pattern from the configuration.
     */
    fun getTimeFormat(config: WidgetConfig): String {
        if (config.customFormat.isNotBlank()) {
            return config.customFormat.trim()
        }

        val separator = when (config.timeSeparator.lowercase()) {
            "dot" -> "."
            "dash" -> "-"
            "space" -> " "
            "none" -> ""
            else -> ":"
        }

        val hourToken = if (config.showHours) {
            if (config.use24Hour) {
                if (config.leadingZero) "HH" else "H"
            } else {
                if (config.leadingZero) "hh" else "h"
            }
        } else {
            ""
        }

        val minuteToken = if (config.showMinutes) "mm" else ""

        val secondsToken = if (config.showSeconds || config.secondsStyle.equals("inline", ignoreCase = true)) {
            "ss"
        } else {
            ""
        }

        val timeParts = mutableListOf<String>()
        if (hourToken.isNotEmpty()) timeParts.add(hourToken)
        if (minuteToken.isNotEmpty()) timeParts.add(minuteToken)
        if (secondsToken.isNotEmpty()) timeParts.add(secondsToken)

        val basePattern = if (timeParts.isNotEmpty()) {
            timeParts.joinToString(separator)
        } else {
            if (config.use24Hour) "HH:mm" else "hh:mm"
        }

        val amPmToken = if (!config.use24Hour && config.showAmPm) {
            " a"
        } else {
            ""
        }

        return "$basePattern$amPmToken"
    }

    /**
     * Builds the exact date format pattern from the configuration.
     */
    fun getDateFormat(config: WidgetConfig): String {
        val parts = mutableListOf<String>()

        if (config.showDayName) {
            parts.add("EEE,")
        }

        if (config.showMonth) {
            parts.add("MMM d")
        } else {
            parts.add("d")
        }

        if (config.showYear) {
            parts.add("yyyy")
        }

        if (config.showWeekNumber) {
            parts.add("'Wk' w")
        }

        if (config.showDayOfYear) {
            parts.add("'Day' D")
        }

        if (config.showTimeZone) {
            parts.add("z")
        }

        val pattern = parts.joinToString(" ").trim()
        return if (pattern.isNotEmpty()) pattern else "EEE, MMM d"
    }

    /**
     * Applies time, date, visibility, and typography scaling to a standard clock widget views.
     */
    fun applyClockFormatting(
        views: RemoteViews,
        config: WidgetConfig,
        timeViewId: Int = R.id.clock_time,
        dateViewId: Int = R.id.clock_date,
        dotViewId: Int = R.id.clock_dot,
        baseTimeSizeSp: Float = 56f
    ) {
        val timePattern = getTimeFormat(config)
        views.setString(timeViewId, "setFormat12Hour", timePattern)
        views.setString(timeViewId, "setFormat24Hour", timePattern)

        // Dynamic text size scaling based on scaleFactor (0.6x - 1.6x)
        if (config.scaleFactor != 1.0f) {
            val scaledSize = (baseTimeSizeSp * config.scaleFactor).coerceIn(24f, 72f)
            views.setTextViewTextSize(timeViewId, TypedValue.COMPLEX_UNIT_SP, scaledSize)
        }

        // Date visibility and dynamic format
        if (config.showDate) {
            views.setViewVisibility(dateViewId, View.VISIBLE)
            if (dotViewId != 0) views.setViewVisibility(dotViewId, View.VISIBLE)

            val datePattern = getDateFormat(config)
            views.setString(dateViewId, "setFormat12Hour", datePattern)
            views.setString(dateViewId, "setFormat24Hour", datePattern)
        } else {
            views.setViewVisibility(dateViewId, View.GONE)
            if (dotViewId != 0) views.setViewVisibility(dotViewId, View.GONE)
        }
    }
}
