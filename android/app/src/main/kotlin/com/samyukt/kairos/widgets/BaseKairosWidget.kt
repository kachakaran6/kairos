package com.samyukt.kairos.widgets

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.util.Log
import android.widget.RemoteViews
import com.samyukt.kairos.MainActivity
import com.samyukt.kairos.R
import es.antonborri.home_widget.HomeWidgetProvider
import java.io.File

abstract class BaseKairosWidget : HomeWidgetProvider() {

    companion object {
        private const val TAG = "BaseKairosWidget"
        private const val MAX_BITMAP_DIMENSION = 800
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences
    ) {
        val providerName = this::class.java.simpleName
        var hasError = false
        var lastErrorMsg: String? = null

        for (appWidgetId in appWidgetIds) {
            try {
                val config = ConfigRepository.getConfig(context, appWidgetId)
                val views = buildRemoteViews(context, widgetData, appWidgetId, config)
                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (e: Throwable) {
                hasError = true
                lastErrorMsg = e.message ?: "Unknown error"
                Log.e(TAG, "[$providerName] Error updating widget instance $appWidgetId: ${e.message}", e)
                try {
                    val fallback = createFallbackViews(context)
                    appWidgetManager.updateAppWidget(appWidgetId, fallback)
                } catch (fallbackError: Throwable) {
                    Log.e(TAG, "[$providerName] Failed to set fallback view: ${fallbackError.message}")
                }
            }
        }

        ConfigRepository.recordWidgetUpdate(
            context,
            providerName,
            appWidgetIds.size,
            if (hasError) lastErrorMsg else null
        )
    }

    abstract fun buildRemoteViews(
        context: Context,
        widgetData: android.content.SharedPreferences,
        appWidgetId: Int,
        config: WidgetConfig
    ): RemoteViews

    protected fun createFallbackViews(context: Context): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_fallback)
        val pendingIntent = createDeepLinkIntent(context, "now")
        views.setOnClickPendingIntent(R.id.fallback_root, pendingIntent)
        return views
    }

    protected fun createDeepLinkIntent(context: Context, deepLinkPath: String): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            data = Uri.parse("kairos://$deepLinkPath")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        return PendingIntent.getActivity(
            context,
            deepLinkPath.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    /**
     * Safely load a bitmap with bounds checking and downsampling to keep binder transactions under 512KB.
     */
    protected fun loadBitmapFromFile(path: String?): Bitmap? {
        if (path.isNullOrEmpty()) return null
        return try {
            val file = File(path)
            if (!file.exists() || file.length() == 0L) return null

            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeFile(file.absolutePath, bounds)

            if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return null

            var sample = 1
            while ((bounds.outWidth / sample) > MAX_BITMAP_DIMENSION ||
                   (bounds.outHeight / sample) > MAX_BITMAP_DIMENSION) {
                sample *= 2
            }

            val opts = BitmapFactory.Options().apply {
                inSampleSize = sample
                inPreferredConfig = Bitmap.Config.ARGB_8888
            }
            BitmapFactory.decodeFile(file.absolutePath, opts)
        } catch (e: Throwable) {
            Log.w(TAG, "Failed to decode bitmap from $path: ${e.message}")
            null
        }
    }
}
