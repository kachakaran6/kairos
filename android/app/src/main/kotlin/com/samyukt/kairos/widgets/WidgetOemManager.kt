package com.samyukt.kairos.widgets

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import es.antonborri.home_widget.HomeWidgetPlugin
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class WidgetOemManager(private val activity: Activity) : MethodChannel.MethodCallHandler {

    private var channel: MethodChannel? = null

    companion object {
        private const val CHANNEL_NAME = "com.samyukt.kairos/widget_oem"
    }

    fun register(messenger: BinaryMessenger) {
        channel = MethodChannel(messenger, CHANNEL_NAME)
        channel?.setMethodCallHandler(this)
    }

    fun unregister() {
        channel?.setMethodCallHandler(null)
        channel = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getManufacturer" -> {
                val data = mapOf(
                    "manufacturer" to Build.MANUFACTURER.lowercase(),
                    "brand" to Build.BRAND.lowercase(),
                    "model" to Build.MODEL,
                    "sdk" to Build.VERSION.SDK_INT
                )
                result.success(data)
            }
            "openAutostartSettings" -> {
                val opened = launchAutostartSettings(activity)
                result.success(opened)
            }
            "openBatterySettings" -> {
                val opened = launchBatterySettings(activity)
                result.success(opened)
            }
            "getWidgetDoctorStatus" -> {
                val statusList = getDoctorStatus(activity)
                result.success(statusList)
            }
            else -> result.notImplemented()
        }
    }

    private fun launchAutostartSettings(context: Context): Boolean {
        val pkg = context.packageName
        val intents = mutableListOf<Intent>()

        val mfg = Build.MANUFACTURER.lowercase()
        when {
            mfg.contains("xiaomi") || mfg.contains("redmi") || mfg.contains("poco") -> {
                intents.add(Intent().setComponent(ComponentName("com.miui.securitycenter", "com.miui.permcenter.autostart.AutoStartManagementActivity")))
                intents.add(Intent("miui.intent.action.OP_AUTO_START").addCategory(Intent.CATEGORY_DEFAULT))
            }
            mfg.contains("vivo") || mfg.contains("iqoo") -> {
                intents.add(Intent().setComponent(ComponentName("com.iqoo.secure", "com.iqoo.secure.ui.phoneoptimize.AddWhiteListActivity")))
                intents.add(Intent().setComponent(ComponentName("com.vivo.permissionmanager", "com.vivo.permissionmanager.activity.PurviewTabActivity")))
                intents.add(Intent().setComponent(ComponentName("com.iqoo.secure", "com.iqoo.secure.MainGuideActivity")))
            }
            mfg.contains("oppo") || mfg.contains("realme") || mfg.contains("oneplus") -> {
                intents.add(Intent().setComponent(ComponentName("com.coloros.safecenter", "com.coloros.safecenter.permission.startup.StartupAppListActivity")))
                intents.add(Intent().setComponent(ComponentName("com.coloros.safecenter", "com.coloros.safecenter.startupapp.StartupAppListActivity")))
                intents.add(Intent().setComponent(ComponentName("com.oppo.safe", "com.oppo.safe.permission.startup.StartupAppListActivity")))
            }
            mfg.contains("samsung") -> {
                intents.add(Intent().setComponent(ComponentName("com.samsung.android.lool", "com.samsung.android.sm.battery.ui.BatteryActivity")))
                intents.add(Intent().setComponent(ComponentName("com.samsung.android.sm", "com.samsung.android.sm.ui.battery.BatteryActivity")))
            }
        }

        // Generic fallback to application details
        intents.add(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = Uri.parse("package:$pkg")
        })

        for (intent in intents) {
            try {
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                context.startActivity(intent)
                return true
            } catch (_: Exception) {}
        }
        return false
    }

    private fun launchBatterySettings(context: Context): Boolean {
        val pkg = context.packageName
        val intents = listOf(
            Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS),
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.parse("package:$pkg")
            }
        )
        for (intent in intents) {
            try {
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                context.startActivity(intent)
                return true
            } catch (_: Exception) {}
        }
        return false
    }

    private fun getDoctorStatus(context: Context): List<Map<String, Any>> {
        val providers = listOf(
            "ClockWidgetProvider" to "Kairos Clock",
            "WorldClockWidgetProvider" to "Kairos World Clock",
            "NextMomentWidgetProvider" to "Kairos Next Moment",
            "ThenMomentWidgetProvider" to "Kairos Memories",
            "InteractiveWidgetProvider" to "Kairos Instruments",
            "ComboWidgetProvider" to "Kairos Dashboard"
        )

        val appWidgetManager = AppWidgetManager.getInstance(context)
        val pm = context.packageManager
        val prefs = HomeWidgetPlugin.getData(context)
        val result = mutableListOf<Map<String, Any>>()

        for ((className, label) in providers) {
            val component = ComponentName(context, "com.samyukt.kairos.widgets.$className")
            var isRegistered = false
            try {
                val info = pm.getReceiverInfo(component, PackageManager.GET_META_DATA)
                isRegistered = info != null
            } catch (_: Exception) {}

            val ids = try {
                appWidgetManager.getAppWidgetIds(component)
            } catch (_: Exception) {
                intArrayOf()
            }

            val lastUpdate = prefs.getLong("doctor_last_update_${className}", 0L)
            val lastError = prefs.getString("doctor_error_${className}", "OK") ?: "OK"

            result.add(
                mapOf(
                    "className" to className,
                    "label" to label,
                    "isRegistered" to isRegistered,
                    "instancesCount" to ids.size,
                    "lastUpdateMillis" to lastUpdate,
                    "lastError" to lastError
                )
            )
        }
        return result
    }
}
