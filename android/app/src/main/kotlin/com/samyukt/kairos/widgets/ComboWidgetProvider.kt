package com.samyukt.kairos.widgets

import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import com.samyukt.kairos.R

class ComboWidgetProvider : BaseKairosWidget() {

    override fun buildRemoteViews(
        context: Context,
        widgetData: SharedPreferences,
        appWidgetId: Int
    ): RemoteViews {
        val isDark = widgetData.getBoolean("is_dark", true)
        val views = RemoteViews(context.packageName, R.layout.widget_combo_dashboard)

        views.setInt(
            R.id.widget_root,
            "setBackgroundResource",
            if (isDark) R.drawable.widget_background_dark else R.drawable.widget_background_light
        )

        val alarmTime = widgetData.getString("next_alarm_time", "--:--") ?: "--:--"
        views.setTextViewText(R.id.combo_alarm_text, "Alarm $alarmTime")

        val momentTitle = widgetData.getString("next_moment_title", "Nothing ahead yet") ?: "Nothing ahead yet"
        val momentDays = widgetData.getInt("next_moment_days", 0)
        views.setTextViewText(R.id.combo_moment_title, momentTitle)
        views.setTextViewText(R.id.combo_moment_days, "$momentDays days")

        // Load Life Progress concentric rings bitmap
        val ringsPath = widgetData.getString("life_progress_rings", null)
        val ringsBmp = loadBitmapFromFile(ringsPath)
        if (ringsBmp != null) {
            views.setImageViewBitmap(R.id.combo_life_rings, ringsBmp)
        }

        val pendingIntent = createDeepLinkIntent(context, "dashboard")
        views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

        return views
    }
}
