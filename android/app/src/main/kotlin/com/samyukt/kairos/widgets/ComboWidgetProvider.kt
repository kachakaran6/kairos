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

            // Concentric pill background for alarm container
            val alarmChipBmp = WidgetShapeHelper.createConcentricChipBitmap(
                context,
                widthDp = 96,
                heightDp = 26,
                outerRadiusDp = config.cornerRadiusDp,
                paddingDp = 16f,
                fillColor = Color.argb(24, Color.red(secondaryText), Color.green(secondaryText), Color.blue(secondaryText)),
                strokeColor = Color.argb(38, Color.red(secondaryText), Color.green(secondaryText), Color.blue(secondaryText))
            )
            views.setImageViewBitmap(R.id.combo_alarm_dot, alarmChipBmp)
        } else {
            views.setViewVisibility(R.id.combo_alarm_container, View.GONE)
        }

        // 4. Moment Data & Custom Unit formatting
        val rawTitle = widgetData.getString("next_moment_title", null)
        val momentTitle = if (rawTitle.isNullOrEmpty() || rawTitle == "Nothing ahead yet") "Trip to Kyoto" else rawTitle
        val momentValue = widgetData.getString("next_moment_value", null)
        val momentDays = widgetData.getInt("next_moment_days", 42)
        val isToday = widgetData.getBoolean("next_moment_is_today", false)
        val unitLabel = widgetData.getString("next_moment_unit_label", "days") ?: "days"

        views.setTextViewText(R.id.combo_moment_title, momentTitle)
        if (isToday) {
            views.setTextViewText(R.id.combo_moment_category, "TODAY!")
            views.setTextViewText(R.id.combo_moment_days, "Today!")
        } else {
            views.setTextViewText(R.id.combo_moment_category, "NEXT MOMENT")
            val displayCount = momentValue ?: "$momentDays $unitLabel"
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

        val pendingIntent = createDeepLinkIntent(context, "dashboard")
        views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

        return views
    }
}
