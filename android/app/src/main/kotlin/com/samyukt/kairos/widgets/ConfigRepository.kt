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
    val cornerRadiusDp: Float = 28.0f,
    val fontStyle: String = "modern", // "modern", "serif", "mono"
    val lookId: String = "midnight_ink",
    val use24Hour: Boolean = true,
    val showSeconds: Boolean = false,
    val version: Int = 1
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
            val isDark = prefs.getBoolean("is_dark", true)
            val accentHex = prefs.getString("accent_hex", "#E8895A") ?: "#E8895A"
            val use24h = prefs.getBoolean("use_24h", true)
            val showSec = prefs.getBoolean("show_seconds", false)
            return WidgetConfig(
                themeMode = if (isDark) "dark" else "light",
                accentHex = accentHex,
                textColor = if (isDark) "#F4EFE8" else "#14120E",
                textSecondaryColor = if (isDark) "#9E968D" else "#68625B",
                backgroundColor = if (isDark) "#0F0D0B" else "#FAF7F2",
                backgroundOpacity = 1.0f,
                use24Hour = use24h,
                showSeconds = showSec
            )
        }

        return try {
            val obj = JSONObject(jsonStr)
            WidgetConfig(
                themeMode = obj.optString("themeMode", "dark"),
                accentHex = obj.optString("accentHex", "#E8895A"),
                textColor = obj.optString("textColor", "#F4EFE8"),
                textSecondaryColor = obj.optString("textSecondaryColor", "#9E968D"),
                backgroundColor = obj.optString("backgroundColor", "#0F0D0B"),
                backgroundOpacity = obj.optDouble("backgroundOpacity", 1.0).toFloat().coerceIn(0.05f, 1.0f),
                cornerRadiusDp = obj.optDouble("cornerRadius", 28.0).toFloat(),
                fontStyle = obj.optString("fontStyle", "modern"),
                lookId = obj.optString("lookId", "midnight_ink"),
                use24Hour = obj.optBoolean("use24Hour", true),
                showSeconds = obj.optBoolean("showSeconds", false),
                version = obj.optInt("version", 1)
            )
        } catch (_: Exception) {
            WidgetConfig()
        }
    }

    fun getEffectiveBackgroundColor(config: WidgetConfig): Int {
        val baseColor = try {
            Color.parseColor(config.backgroundColor)
        } catch (_: Exception) {
            Color.parseColor("#0F0D0B")
        }
        val alpha = (config.backgroundOpacity * 255).toInt().coerceIn(0, 255)
        return Color.argb(alpha, Color.red(baseColor), Color.green(baseColor), Color.blue(baseColor))
    }

    fun getAutoContrastingTextColor(config: WidgetConfig): Pair<Int, Int> {
        val bg = getEffectiveBackgroundColor(config)
        val r = Color.red(bg) / 255.0
        val g = Color.green(bg) / 255.0
        val b = Color.blue(bg) / 255.0
        val lum = 0.2126 * r + 0.7152 * g + 0.0722 * b

        val primary = if (lum > 0.5) Color.parseColor("#14120E") else Color.parseColor("#F4EFE8")
        val secondary = if (lum > 0.5) Color.parseColor("#68625B") else Color.parseColor("#9E968D")
        return Pair(primary, secondary)
    }

    fun parseAccentColor(config: WidgetConfig): Int {
        return try {
            Color.parseColor(config.accentHex)
        } catch (_: Exception) {
            Color.parseColor("#E8895A")
        }
    }

    fun recordWidgetUpdate(context: Context, providerName: String, instanceCount: Int, errorMsg: String? = null) {
        try {
            val prefs = HomeWidgetPlugin.getData(context)
            prefs.edit()
                .putLong("doctor_last_update_${providerName}", System.currentTimeMillis())
                .putInt("doctor_instances_${providerName}", instanceCount)
                .putString("doctor_error_${providerName}", errorMsg ?: "OK")
                .apply()
        } catch (_: Exception) {}
    }
}
