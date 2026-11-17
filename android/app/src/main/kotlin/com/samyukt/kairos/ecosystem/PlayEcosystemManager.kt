package com.samyukt.kairos.ecosystem

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.util.Log
import com.google.android.play.core.appupdate.AppUpdateInfo
import com.google.android.play.core.appupdate.AppUpdateManager
import com.google.android.play.core.appupdate.AppUpdateManagerFactory
import com.google.android.play.core.appupdate.AppUpdateOptions
import com.google.android.play.core.install.InstallState
import com.google.android.play.core.install.InstallStateUpdatedListener
import com.google.android.play.core.install.model.AppUpdateType
import com.google.android.play.core.install.model.InstallStatus
import com.google.android.play.core.install.model.UpdateAvailability
import com.google.android.play.core.review.ReviewException
import com.google.android.play.core.review.ReviewManager
import com.google.android.play.core.review.ReviewManagerFactory
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Production implementation of the Samyukt Android Ecosystem Standard.
 * 
 * Provides:
 * - Official Google Play In-App Updates API (Immediate & Flexible flows with lifecycle recovery)
 * - Official Google Play In-App Review API
 * - Rate Now with market:// intent and web fallback
 * - Native Android Sharesheet via Intent.ACTION_SEND
 * - Real version name and build code from PackageManager
 * - Attribution browser launcher
 */
class PlayEcosystemManager(
    private val activity: Activity
) : MethodChannel.MethodCallHandler {

    companion object {
        private const val TAG = "PlayEcosystemManager"
        const val CHANNEL_NAME = "com.samyukt.kairos/ecosystem"
        const val REQUEST_CODE_IMMEDIATE_UPDATE = 8001
        const val REQUEST_CODE_FLEXIBLE_UPDATE = 8002
    }

    private var channel: MethodChannel? = null
    private val appUpdateManager: AppUpdateManager by lazy {
        AppUpdateManagerFactory.create(activity.applicationContext)
    }
    private val reviewManager: ReviewManager by lazy {
        ReviewManagerFactory.create(activity.applicationContext)
    }

    private var cachedAppUpdateInfo: AppUpdateInfo? = null
    private var pendingUpdateResult: MethodChannel.Result? = null

    private val installStateListener = InstallStateUpdatedListener { state: InstallState ->
        val status = state.installStatus()
        val bytesDownloaded = state.bytesDownloaded()
        val totalBytes = state.totalBytesToDownload()

        Log.d(TAG, "InstallState changed: status=$status ($bytesDownloaded / $totalBytes bytes)")

        val arguments = mapOf(
            "installStatus" to status,
            "bytesDownloaded" to bytesDownloaded,
            "totalBytesToDownload" to totalBytes
        )

        activity.runOnUiThread {
            channel?.invokeMethod("onInstallStateUpdated", arguments)
        }

        if (status == InstallStatus.DOWNLOADED) {
            Log.i(TAG, "Flexible update downloaded successfully. Ready for completeUpdate().")
            activity.runOnUiThread {
                channel?.invokeMethod("onFlexibleUpdateDownloaded", null)
            }
        }
    }

    fun register(messenger: BinaryMessenger) {
        channel = MethodChannel(messenger, CHANNEL_NAME)
        channel?.setMethodCallHandler(this)
        appUpdateManager.registerListener(installStateListener)
    }

    fun unregister() {
        try {
            appUpdateManager.unregisterListener(installStateListener)
        } catch (e: Exception) {
            Log.w(TAG, "Error unregistering installStateListener: ${e.message}")
        }
        channel?.setMethodCallHandler(null)
        channel = null
    }

    /**
     * Handles Activity onResume to recover from interrupted updates.
     */
    fun onResume() {
        appUpdateManager.appUpdateInfo.addOnSuccessListener { info ->
            cachedAppUpdateInfo = info

            // 1. Recover in-progress immediate update
            if (info.updateAvailability() == UpdateAvailability.DEVELOPER_TRIGGERED_UPDATE_IN_PROGRESS) {
                Log.i(TAG, "Resuming developer-triggered update in progress.")
                try {
                    val options = AppUpdateOptions.newBuilder(AppUpdateType.IMMEDIATE).build()
                    appUpdateManager.startUpdateFlowForResult(
                        info,
                        activity,
                        options,
                        REQUEST_CODE_IMMEDIATE_UPDATE
                    )
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to resume in-progress update: ${e.message}")
                }
            }

            // 2. Recover downloaded flexible update
            if (info.installStatus() == InstallStatus.DOWNLOADED) {
                Log.i(TAG, "Flexible update already downloaded. Notifying client.")
                activity.runOnUiThread {
                    channel?.invokeMethod("onFlexibleUpdateDownloaded", null)
                }
            }
        }.addOnFailureListener { e ->
            Log.d(TAG, "onResume update check skipped or failed: ${e.message}")
        }
    }

    /**
     * Handles Activity onActivityResult for update flow completion or cancellation.
     */
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == REQUEST_CODE_IMMEDIATE_UPDATE || requestCode == REQUEST_CODE_FLEXIBLE_UPDATE) {
            val success = resultCode == Activity.RESULT_OK
            val canceled = resultCode == Activity.RESULT_CANCELED
            Log.i(TAG, "Update flow result: req=$requestCode, res=$resultCode (ok=$success, canceled=$canceled)")

            val resultData = mapOf(
                "requestCode" to requestCode,
                "resultCode" to resultCode,
                "success" to success,
                "canceled" to canceled
            )

            activity.runOnUiThread {
                channel?.invokeMethod("onUpdateFlowResult", resultData)
            }

            pendingUpdateResult?.success(resultData)
            pendingUpdateResult = null
            return true
        }
        return false
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "checkForUpdate" -> handleCheckForUpdate(result)
            "startImmediateUpdate" -> handleStartImmediateUpdate(result)
            "startFlexibleUpdate" -> handleStartFlexibleUpdate(result)
            "completeFlexibleUpdate" -> handleCompleteFlexibleUpdate(result)
            "requestInAppReview" -> handleRequestInAppReview(result)
            "openPlayStoreListing" -> {
                val pkg = call.argument<String>("packageName") ?: activity.packageName
                handleOpenPlayStoreListing(pkg, result)
            }
            "shareApp" -> {
                val text = call.argument<String>("text") ?: ""
                val subject = call.argument<String>("subject") ?: "Kairos"
                handleShareApp(text, subject, result)
            }
            "getAppVersionInfo" -> handleGetAppVersionInfo(result)
            "openUrl" -> {
                val url = call.argument<String>("url") ?: "https://samyukt.pro"
                handleOpenUrl(url, result)
            }
            else -> result.notImplemented()
        }
    }

    private fun handleCheckForUpdate(result: MethodChannel.Result) {
        appUpdateManager.appUpdateInfo.addOnSuccessListener { info ->
            cachedAppUpdateInfo = info

            val isAvailable = info.updateAvailability() == UpdateAvailability.UPDATE_AVAILABLE
            val isInProgress = info.updateAvailability() == UpdateAvailability.DEVELOPER_TRIGGERED_UPDATE_IN_PROGRESS
            val isImmediateAllowed = info.isUpdateTypeAllowed(AppUpdateType.IMMEDIATE)
            val isFlexibleAllowed = info.isUpdateTypeAllowed(AppUpdateType.FLEXIBLE)

            val response = mapOf(
                "available" to isAvailable,
                "inProgress" to isInProgress,
                "updateAvailability" to info.updateAvailability(),
                "availableVersionCode" to info.availableVersionCode(),
                "updatePriority" to info.updatePriority(),
                "clientVersionStalenessDays" to info.clientVersionStalenessDays(),
                "immediateAllowed" to isImmediateAllowed,
                "flexibleAllowed" to isFlexibleAllowed,
                "installStatus" to info.installStatus()
            )

            Log.i(TAG, "Update check result: available=$isAvailable, priority=${info.updatePriority()}, immediate=$isImmediateAllowed, flexible=$isFlexibleAllowed")
            result.success(response)
        }.addOnFailureListener { exception ->
            Log.w(TAG, "Failed to check for in-app updates: ${exception.message}")
            result.error(
                "UPDATE_CHECK_FAILED",
                exception.message ?: "Google Play Store unavailable or offline",
                null
            )
        }
    }

    private fun handleStartImmediateUpdate(result: MethodChannel.Result) {
        val info = cachedAppUpdateInfo
        if (info == null) {
            result.error("NO_UPDATE_INFO", "Check for update before initiating flow", null)
            return
        }

        if (!info.isUpdateTypeAllowed(AppUpdateType.IMMEDIATE)) {
            result.error("IMMEDIATE_NOT_ALLOWED", "Immediate update is not allowed for this update", null)
            return
        }

        try {
            pendingUpdateResult = result
            val options = AppUpdateOptions.newBuilder(AppUpdateType.IMMEDIATE).build()
            appUpdateManager.startUpdateFlowForResult(
                info,
                activity,
                options,
                REQUEST_CODE_IMMEDIATE_UPDATE
            )
        } catch (e: Exception) {
            Log.e(TAG, "Error starting immediate update flow: ${e.message}")
            pendingUpdateResult = null
            result.error("START_UPDATE_FAILED", e.message, null)
        }
    }

    private fun handleStartFlexibleUpdate(result: MethodChannel.Result) {
        val info = cachedAppUpdateInfo
        if (info == null) {
            result.error("NO_UPDATE_INFO", "Check for update before initiating flow", null)
            return
        }

        if (!info.isUpdateTypeAllowed(AppUpdateType.FLEXIBLE)) {
            result.error("FLEXIBLE_NOT_ALLOWED", "Flexible update is not allowed for this update", null)
            return
        }

        try {
            pendingUpdateResult = result
            val options = AppUpdateOptions.newBuilder(AppUpdateType.FLEXIBLE).build()
            appUpdateManager.startUpdateFlowForResult(
                info,
                activity,
                options,
                REQUEST_CODE_FLEXIBLE_UPDATE
            )
        } catch (e: Exception) {
            Log.e(TAG, "Error starting flexible update flow: ${e.message}")
            pendingUpdateResult = null
            result.error("START_UPDATE_FAILED", e.message, null)
        }
    }

    private fun handleCompleteFlexibleUpdate(result: MethodChannel.Result) {
        try {
            appUpdateManager.completeUpdate().addOnSuccessListener {
                Log.i(TAG, "completeUpdate() successfully triggered app restart.")
                result.success(true)
            }.addOnFailureListener { e ->
                Log.e(TAG, "completeUpdate() failed: ${e.message}")
                result.error("COMPLETE_UPDATE_FAILED", e.message, null)
            }
        } catch (e: Exception) {
            result.error("COMPLETE_UPDATE_ERROR", e.message, null)
        }
    }

    private fun handleRequestInAppReview(result: MethodChannel.Result) {
        val request = reviewManager.requestReviewFlow()
        request.addOnCompleteListener { task ->
            if (task.isSuccessful) {
                val reviewInfo = task.result
                val flow = reviewManager.launchReviewFlow(activity, reviewInfo)
                flow.addOnCompleteListener { flowTask ->
                    // Google Play docs: "The flow has finished. The API does not indicate whether the user
                    // reviewed or not, or even whether the review dialog was shown."
                    Log.i(TAG, "In-app review flow finished successfully.")
                    result.success(mapOf("completed" to true))
                }
            } else {
                val ex = task.exception
                Log.w(TAG, "In-app review request failed: ${ex?.message}")
                result.error(
                    "REVIEW_REQUEST_FAILED",
                    ex?.message ?: "In-app review flow request failed",
                    null
                )
            }
        }
    }

    private fun handleOpenPlayStoreListing(packageName: String, result: MethodChannel.Result) {
        val marketUri = Uri.parse("market://details?id=$packageName")
        val webUri = Uri.parse("https://play.google.com/store/apps/details?id=$packageName")

        val marketIntent = Intent(Intent.ACTION_VIEW, marketUri).apply {
            addFlags(Intent.FLAG_ACTIVITY_NO_HISTORY or Intent.FLAG_ACTIVITY_NEW_DOCUMENT or Intent.FLAG_ACTIVITY_MULTIPLE_TASK)
        }

        try {
            activity.startActivity(marketIntent)
            result.success(true)
        } catch (e: ActivityNotFoundException) {
            try {
                activity.startActivity(Intent(Intent.ACTION_VIEW, webUri))
                result.success(true)
            } catch (ex: Exception) {
                Log.e(TAG, "Failed to open Play Store listing in browser: ${ex.message}")
                result.error("OPEN_LISTING_FAILED", ex.message, null)
            }
        }
    }

    private fun handleShareApp(text: String, subject: String, result: MethodChannel.Result) {
        val shareIntent = Intent(Intent.ACTION_SEND).apply {
            type = "text/plain"
            putExtra(Intent.EXTRA_SUBJECT, subject)
            putExtra(Intent.EXTRA_TEXT, text)
        }

        val chooser = Intent.createChooser(shareIntent, "Share Kairos")
        try {
            activity.startActivity(chooser)
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Error opening share chooser: ${e.message}")
            result.error("SHARE_FAILED", e.message, null)
        }
    }

    private fun handleGetAppVersionInfo(result: MethodChannel.Result) {
        try {
            val pInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                activity.packageManager.getPackageInfo(
                    activity.packageName,
                    PackageManager.PackageInfoFlags.of(0)
                )
            } else {
                @Suppress("DEPRECATION")
                activity.packageManager.getPackageInfo(activity.packageName, 0)
            }

            val versionName = pInfo.versionName ?: "1.0.0"
            val versionCode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                pInfo.longVersionCode
            } else {
                @Suppress("DEPRECATION")
                pInfo.versionCode.toLong()
            }

            result.success(
                mapOf(
                    "versionName" to versionName,
                    "versionCode" to versionCode,
                    "packageName" to activity.packageName
                )
            )
        } catch (e: Exception) {
            Log.e(TAG, "Failed to read package info: ${e.message}")
            result.success(
                mapOf(
                    "versionName" to "1.0.0",
                    "versionCode" to 1L,
                    "packageName" to activity.packageName
                )
            )
        }
    }

    private fun handleOpenUrl(url: String, result: MethodChannel.Result) {
        try {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url)).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            activity.startActivity(intent)
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to open url: ${e.message}")
            result.error("OPEN_URL_FAILED", e.message, null)
        }
    }
}
