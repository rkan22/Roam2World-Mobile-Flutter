package com.roam2world.b2b

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Bundle
import android.telephony.euicc.DownloadableSubscription
import android.telephony.euicc.EuiccManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val LPA_CHANNEL = "com.roam2world.mobile/lpa"
        private const val ACTION_ESIM_DOWNLOAD = "com.roam2world.mobile.ESIM_DOWNLOAD_RESULT"
        private const val RESOLUTION_REQUEST_CODE = 4107
    }

    private var pendingInstallResult: MethodChannel.Result? = null
    private var callbackPendingIntent: PendingIntent? = null

    private val downloadReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action != ACTION_ESIM_DOWNLOAD) return
            handleDownloadResult(resultCode, intent)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val filter = IntentFilter(ACTION_ESIM_DOWNLOAD)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(downloadReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("DEPRECATION")
            registerReceiver(downloadReceiver, filter)
        }
    }

    override fun onDestroy() {
        runCatching { unregisterReceiver(downloadReceiver) }
        pendingInstallResult?.error("ACTIVITY_CLOSED", "The installation activity was closed.", null)
        pendingInstallResult = null
        callbackPendingIntent = null
        super.onDestroy()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LPA_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getCapability" -> result.success(getLpaCapability())
                    "installActivationCode" -> {
                        val activationCode = call.argument<String>("activationCode").orEmpty().trim()
                        val switchAfterDownload = call.argument<Boolean>("switchAfterDownload") ?: false
                        installActivationCode(activationCode, switchAfterDownload, result)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun getLpaCapability(): Map<String, Any> {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) {
            return mapOf(
                "platform" to "android",
                "esimSupported" to false,
                "directInstallSupported" to false,
                "transport" to "none",
                "reason" to "Android 9 or newer is required for platform eSIM support.",
            )
        }

        val euicc = getSystemService(Context.EUICC_SERVICE) as? EuiccManager
        val enabled = euicc?.isEnabled == true
        return mapOf(
            "platform" to "android",
            "esimSupported" to enabled,
            "directInstallSupported" to enabled,
            "transport" to if (enabled) "android_system_lpa" else "none",
            "reason" to if (enabled)
                "Android system eSIM installation is available. The system may ask for user approval."
            else
                "No enabled eUICC was detected on this device.",
        )
    }

    private fun installActivationCode(
        activationCode: String,
        switchAfterDownload: Boolean,
        result: MethodChannel.Result,
    ) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) {
            result.error("UNSUPPORTED", "Android 9 or newer is required for eSIM installation.", null)
            return
        }
        if (activationCode.isBlank()) {
            result.error("INVALID_ACTIVATION_CODE", "Activation code is empty.", null)
            return
        }
        if (pendingInstallResult != null) {
            result.error("INSTALL_IN_PROGRESS", "Another eSIM installation is already in progress.", null)
            return
        }

        val euicc = getSystemService(Context.EUICC_SERVICE) as? EuiccManager
        if (euicc?.isEnabled != true) {
            result.error("ESIM_UNAVAILABLE", "No enabled eUICC was detected on this device.", null)
            return
        }

        try {
            val subscription = DownloadableSubscription.forActivationCode(activationCode)
            val callbackIntent = Intent(ACTION_ESIM_DOWNLOAD).setPackage(packageName)
            val flags = PendingIntent.FLAG_UPDATE_CURRENT or
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) PendingIntent.FLAG_MUTABLE else 0
            val pendingIntent = PendingIntent.getBroadcast(this, RESOLUTION_REQUEST_CODE, callbackIntent, flags)

            pendingInstallResult = result
            callbackPendingIntent = pendingIntent
            euicc.downloadSubscription(subscription, switchAfterDownload, pendingIntent)
        } catch (security: SecurityException) {
            clearPendingInstall()
            result.error("NOT_AUTHORIZED", security.message ?: "Android did not authorize the eSIM download request.", null)
        } catch (unsupported: UnsupportedOperationException) {
            clearPendingInstall()
            result.error("UNSUPPORTED", unsupported.message ?: "eSIM installation is not supported on this device.", null)
        } catch (error: Throwable) {
            clearPendingInstall()
            result.error("INSTALL_START_FAILED", error.message ?: error.javaClass.simpleName, null)
        }
    }

    private fun handleDownloadResult(code: Int, intent: Intent) {
        val result = pendingInstallResult ?: return
        val euicc = getSystemService(Context.EUICC_SERVICE) as? EuiccManager

        when (code) {
            EuiccManager.EMBEDDED_SUBSCRIPTION_RESULT_OK -> {
                clearPendingInstall()
                result.success(
                    mapOf(
                        "status" to "installed",
                        "transport" to "android_system_lpa",
                    ),
                )
            }
            EuiccManager.EMBEDDED_SUBSCRIPTION_RESULT_RESOLVABLE_ERROR -> {
                val callback = callbackPendingIntent
                if (euicc == null || callback == null) {
                    clearPendingInstall()
                    result.error("RESOLUTION_UNAVAILABLE", "Android requested user resolution but no callback was available.", null)
                    return
                }
                try {
                    euicc.startResolutionActivity(this, RESOLUTION_REQUEST_CODE, intent, callback)
                } catch (error: Throwable) {
                    clearPendingInstall()
                    result.error("RESOLUTION_FAILED", error.message ?: error.javaClass.simpleName, null)
                }
            }
            else -> {
                val detailedCode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    intent.getIntExtra(EuiccManager.EXTRA_EMBEDDED_SUBSCRIPTION_DETAILED_CODE, 0)
                } else {
                    0
                }
                clearPendingInstall()
                result.error(
                    "INSTALL_FAILED",
                    "Android system LPA could not install the eSIM profile.",
                    mapOf("resultCode" to code, "detailedCode" to detailedCode),
                )
            }
        }
    }

    private fun clearPendingInstall() {
        pendingInstallResult = null
        callbackPendingIntent = null
    }
}
