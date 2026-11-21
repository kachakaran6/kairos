package com.samyukt.kairos.widgets

import android.content.Context
import android.graphics.Color
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONObject

data class WidgetConfig(
    val themeMode: String = "dark",
    val accentHex: String = "#E8895A",
    val textColor: String = "#F4EFE8",
    val textSecondaryColor: String = "#9E968D",
    val backgroundColor: String = "#0F0D0B",
    val backgroundOpacity: Float = 1.0f,
    val backgroundType: String = "warm_paper", // "warm_paper", "dark_ink", "terracotta", "glass", "photo", "transparent", "material_you", "custom"
    val cornerRadiusDp: Float = 28.0f,
    val borderEnabled: Boolean = true,
    val borderWidthDp: Float = 1.0f,
    val fontStyle: String = "modern", // "modern", "serif", "mono", "rounded", "display"
    val lookId: String = "terracotta_paper",
    val use24Hour: Boolean = true,
    val showSeconds: Boolean = false,
    val showAmPm: Boolean = false,
    val showDate: Boolean = true,
    val showAlarm: Boolean = true,
    val timeLayout: String = "inline", // "inline", "stacked", "split", "vertical", "words"
    val timeSeparator: String = "colon", // "colon", "dot", "dash", "space", "none"
    val secondsStyle: String = "hidden", // "inline", "superscript", "hidden"
    val customFormat: String = "",
    val scaleFactor: Float = 1.0f,
    val photoPath: String? = null,
    val momentVisual: String = "ring", // "ring", "hero_number", "bar", "minimal_chip", "poster", "dots"
    val momentUnit: String = "days", // "days", "weeks", "months_days", "ymd", "hours", "minutes", "seconds", "percent", "live_countdown"
    val leadingZero: Boolean = true,
    val batterySafeMode: Boolean = true,
    val secondsScreenOnOnly: Boolean = true,
    val showHours: Boolean = true,
    val showMinutes: Boolean = true,
    val showDayName: Boolean = true,
    val showMonth: Boolean = true,
    val showYear: Boolean = false,
    val showWeekNumber: Boolean = false,
    val showDayOfYear: Boolean = false,
    val showTimeZone: Boolean = false,
    val momentDirection: String = "auto", // "auto", "countdown", "countup"
    val showMomentTitle: Boolean = true,
    val showMomentCategory: Boolean = true,
    val showMomentDate: Boolean = true,
    val showMomentProgress: Boolean = true,
    val showMomentNote: Boolean = false,
    val alignment: String = "center", // "left", "center", "right"
    val version: Int = 2
)

object ConfigRepository {

    private const val GLOBAL_CONFIG_KEY = "kairos_widget_config_global"
    private const val PER_WIDGET_CONFIG_PREFIX = "kairos_widget_config_"

    fun getConfig(context: Context, appWidgetId: Int): WidgetConfig {
        val prefs = HomeWidgetPlugin.getData(context)
        val globalJsonStr = prefs.getString(GLOBAL_CONFIG_KEY, null)
        val perWidgetJsonStr = prefs.getString("$PER_WIDGET_CONFIG_PREFIX$appWidgetId", null)

        val jsonStr = perWidgetJsonStr ?: globalJsonStr
        if (jsonStr.isNullOrEmpty()) {
            val isDark = prefs.getBoolean("is_dark", false)
            val accentHex = prefs.getString("accent_hex", "#E8895A") ?: "#E8895A"
            val use24h = prefs.getBoolean("use_24h", true)
            val showSec = prefs.getBoolean("show_seconds", false)
            return WidgetConfig(
                themeMode = if (isDark) "dark" else "light",
                accentHex = accentHex,
                textColor = if (isDark) "#F4EFE8" else "#14120E",
                textSecondaryColor = if (isDark) "#9E968D" else "#68625B",
                backgroundColor = if (isDark) "#0F0D0B" else "#FAF7F2",
                backgroundType = if (isDark) "dark_ink" else "warm_paper",
                backgroundOpacity = 1.0f,
                use24Hour = use24h,
                showSeconds = showSec
            )
        }

        return try {
            val obj = JSONObject(jsonStr)
            val look = obj.optString("lookId", "terracotta_paper")
            val defaultBgType = when (look) {
                "midnight_ink", "mono_graphite" -> "dark_ink"
                "terracotta_paper", "poster" -> "terracotta"
                "sunset_glass" -> "glass"
                else -> "warm_paper"
            }

            WidgetConfig(
                themeMode = obj.optString("themeMode", "light"),
                accentHex = obj.optString("accentHex", "#E8895A"),
                textColor = obj.optString("textColor", "#14120E"),
                textSecondaryColor = obj.optString("textSecondaryColor", "#68625B"),
                backgroundColor = obj.optString("backgroundColor", "#FAF7F2"),
                backgroundOpacity = obj.optDouble("backgroundOpacity", 1.0).toFloat().coerceIn(0.05f, 1.0f),
                backgroundType = obj.optString("backgroundType", defaultBgType),
                cornerRadiusDp = obj.optDouble("cornerRadius", 28.0).toFloat().coerceIn(0f, 40f),
                borderEnabled = obj.optBoolean("borderEnabled", true),
                borderWidthDp = obj.optDouble("borderWidthDp", 1.0).toFloat().coerceIn(0.5f, 3.0f),
                fontStyle = obj.optString("fontStyle", "modern"),
                lookId = look,
                use24Hour = obj.optBoolean("use24Hour", true),
                showSeconds = obj.optBoolean("showSeconds", false),
                showAmPm = obj.optBoolean("showAmPm", false),
                showDate = obj.optBoolean("showDate", true),
                showAlarm = obj.optBoolean("showAlarm", true),
                timeLayout = obj.optString("timeLayout", "inline"),
                timeSeparator = obj.optString("timeSeparator", "colon"),
                secondsStyle = obj.optString("secondsStyle", "hidden"),
                customFormat = obj.optString("customFormat", ""),
                scaleFactor = obj.optDouble("scaleFactor", 1.0).toFloat().coerceIn(0.6f, 1.6f),
                photoPath = if (obj.has("photoPath") && !obj.isNull("photoPath")) obj.getString("photoPath") else null,
                momentVisual = obj.optString("momentVisual", "ring"),
                momentUnit = obj.optString("momentUnit", "days"),
                leadingZero = obj.optBoolean("leadingZero", true),
                batterySafeMode = obj.optBoolean("batterySafeMode", true),
                secondsScreenOnOnly = obj.optBoolean("secondsScreenOnOnly", true),
                showHours = obj.optBoolean("showHours", true),
                showMinutes = obj.optBoolean("showMinutes", true),
                showDayName = obj.optBoolean("showDayName", true),
                showMonth = obj.optBoolean("showMonth", true),
                showYear = obj.optBoolean("showYear", false),
                showWeekNumber = obj.optBoolean("showWeekNumber", false),
                showDayOfYear = obj.optBoolean("showDayOfYear", false),
                showTimeZone = obj.optBoolean("showTimeZone", false),
                momentDirection = obj.optString("momentDirection", "auto"),
                showMomentTitle = obj.optBoolean("showMomentTitle", true),
                showMomentCategory = obj.optBoolean("showMomentCategory", true),
                showMomentDate = obj.optBoolean("showMomentDate", true),
                showMomentProgress = obj.optBoolean("showMomentProgress", true),
                showMomentNote = obj.optBoolean("showMomentNote", false),
                alignment = obj.optString("alignment", "center"),
                version = obj.optInt("version", 2)
            )
        } catch (e: Exception) {
            WidgetConfig()
        }
    }

    fun getAutoContrastingTextColor(config: WidgetConfig): Pair<Int, Int> {
        return when (config.backgroundType.lowercase()) {
            "warm_paper" -> Pair(Color.parseColor("#14120E"), Color.parseColor("#68625B"))
            "dark_ink" -> Pair(Color.parseColor("#F4EFE8"), Color.parseColor("#9E968D"))
            "terracotta" -> Pair(Color.parseColor("#FFFFFF"), Color.parseColor("#FDE7DE"))
            "photo" -> Pair(Color.parseColor("#F4EFE8"), Color.parseColor("#C4BCB3"))
            "glass" -> {
                if (config.themeMode == "dark") {
                    Pair(Color.parseColor("#F4EFE8"), Color.parseColor("#9E968D"))
                } else {
                    Pair(Color.parseColor("#14120E"), Color.parseColor("#68625B"))
                }
            }
            else -> {
                val bg = try {
                    Color.parseColor(config.backgroundColor)
                } catch (_: Exception) {
                    Color.parseColor("#0F0D0B")
                }
                val r = Color.red(bg) / 255.0
                val g = Color.green(bg) / 255.0
                val b = Color.blue(bg) / 255.0
                val lum = 0.2126 * r + 0.7152 * g + 0.0722 * b
                if (lum > 0.5) {
                    Pair(Color.parseColor("#14120E"), Color.parseColor("#68625B"))
                } else {
                    Pair(Color.parseColor("#F4EFE8"), Color.parseColor("#9E968D"))
                }
            }
        }
    }

    fun parseAccentColor(config: WidgetConfig): Int {
        return try {
            Color.parseColor(config.accentHex)
        } catch (_: Exception) {
            Color.parseColor("#E8895A")
        }
    }

    fun recordWidgetUpdate(
        context: Context,
        providerName: String,
        instanceCount: Int,
        lastError: String?
    ) {
        try {
            val prefs = es.antonborri.home_widget.HomeWidgetPlugin.getData(context)
            prefs.edit()
                .putInt("doctor_${providerName}_instances", instanceCount)
                .putLong("doctor_${providerName}_last_update", System.currentTimeMillis())
                .putString("doctor_${providerName}_last_error", lastError ?: "None")
                .apply()
        } catch (e: Exception) {}
    }
}
