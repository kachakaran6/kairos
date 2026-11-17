package com.samyukt.kairos.widgets.workers

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import androidx.work.Constraints
import androidx.work.CoroutineWorker
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import com.samyukt.kairos.widgets.ClockWidgetProvider
import com.samyukt.kairos.widgets.ComboWidgetProvider
import com.samyukt.kairos.widgets.InteractiveWidgetProvider
import com.samyukt.kairos.widgets.NextMomentWidgetProvider
import com.samyukt.kairos.widgets.ThenMomentWidgetProvider
import com.samyukt.kairos.widgets.WorldClockWidgetProvider
import java.util.concurrent.TimeUnit

class WidgetSyncWorker(
    appContext: Context,
    params: WorkerParameters
) : CoroutineWorker(appContext, params) {

    override suspend fun doWork(): Result {
        val appWidgetManager = AppWidgetManager.getInstance(applicationContext) ?: return Result.success()
        val providers = listOf(
            ClockWidgetProvider::class.java,
            WorldClockWidgetProvider::class.java,
            NextMomentWidgetProvider::class.java,
            ThenMomentWidgetProvider::class.java,
            InteractiveWidgetProvider::class.java,
            ComboWidgetProvider::class.java
        )

        for (p in providers) {
            val component = ComponentName(applicationContext, p)
            val ids = appWidgetManager.getAppWidgetIds(component)
            if (ids.isNotEmpty()) {
                val updateIntent = Intent(applicationContext, p).apply {
                    action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
                }
                applicationContext.sendBroadcast(updateIntent)
            }
        }

        return Result.success()
    }

    companion object {
        private const val WORK_NAME = "KairosWidgetPeriodicSync"

        fun enqueuePeriodic(context: Context) {
            val constraints = Constraints.Builder()
                .setRequiresBatteryNotLow(true)
                .build()

            val request = PeriodicWorkRequestBuilder<WidgetSyncWorker>(2, TimeUnit.HOURS)
                .setConstraints(constraints)
                .build()

            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                WORK_NAME,
                ExistingPeriodicWorkPolicy.KEEP,
                request
            )
        }
    }
}
