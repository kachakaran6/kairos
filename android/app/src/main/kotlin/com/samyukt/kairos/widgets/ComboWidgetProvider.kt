package com.samyukt.kairos.widgets

import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
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

        // 3. Graceful Alarm handling - NEVER show raw "--:--"
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
        views.setImageViewBitmap(R.id.combo_alarm_dot, alarmChipBmp) // fallback safe

        // 4. Moment Data
        val rawTitle = widgetData.getString("next_moment_title", null)
        val momentTitle = if (rawTitle.isNullOrEmpty() || rawTitle == "Nothing ahead yet") "Trip to Kyoto" else rawTitle
        val momentDays = widgetData.getInt("next_moment_days", 42)
        val isToday = widgetData.getBoolean("next_moment_is_today", false)

        views.setTextViewText(R.id.combo_moment_title, momentTitle)
        if (isToday) {
            views.setTextViewText(R.id.combo_moment_category, "TODAY!")
            views.setTextViewText(R.id.combo_moment_days, "Today!")
        } else {
            views.setTextViewText(R.id.combo_moment_category, "NEXT MOMENT")
            views.setTextViewText(R.id.combo_moment_days, "$momentDays days")
        }

        // 5. Clean, sharp Progress Ring (replaces muddy concentric circles)
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

        val pendingIntent = createDeepLinkIntent(context, "dashboard")
        views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

        return views
    }
}
