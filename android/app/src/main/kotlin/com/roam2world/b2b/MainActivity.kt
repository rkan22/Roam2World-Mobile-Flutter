package com.roam2world.b2b

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.telephony.euicc.DownloadableSubscription
import android.telephony.euicc.EuiccManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import im.nfc.ccid.CcidPlugin
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val LPA_CHANNEL = "com.roam2world.mobile/lpa"
        private const val ACTION_ESIM_DOWNLOAD = "com.roam2world.mobile.ESIM_DOWNLOAD_RESULT"
        private const val RESOLUTION_REQUEST_CODE = 4107
        private const val NEKOKO_PACKAGE = "ee.nekoko.nlpa2"
    }

    private val omapiBridge by lazy { OmapiEuiccBridge(this) }
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
        omapiBridge.shutdown()
        super.onDestroy()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Some cached/add-to-app engine states can skip generated plugin
        // registration. Register CCID explicitly without adding it twice.
        if (!flutterEngine.plugins.has(CcidPlugin::class.java)) {
            flutterEngine.plugins.add(CcidPlugin())
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LPA_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getCapability" -> result.success(getLpaCapability())
                    "getEmbeddedApduCapability" -> omapiBridge.capability(result)
                    "openEuiccChannel" -> omapiBridge.open(result)
                    "transmitEuiccApdu" -> omapiBridge.transmit(call.argument<ByteArray>("apdu"), result)
                    "closeEuiccChannel" -> omapiBridge.close(result)
                    "openNekoko" -> openNekoko(result)
                    "installActivationCode" -> {
                        val activationCode = call.argument<String>("activationCode").orEmpty().trim()
                        val switchAfterDownload = call.argument<Boolean>("switchAfterDownload") ?: false
                        installActivationCode(activationCode, switchAfterDownload, result)
                    }
                    "handoffToNekoko" -> {
                        val activationCode = call.argument<String>("activationCode").orEmpty().trim()
                        handoffToNekoko(activationCode, result)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun getLpaCapability(): Map<String, Any> {
        val nekokoAvailable = isNekokoAvailable()
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) {
            return mapOf(
                "platform" to "android",
                "esimSupported" to false,
                "directInstallSupported" to false,
                "transport" to if (nekokoAvailable) "nekoko_deeplink" else "none",
                "nekokoAvailable" to nekokoAvailable,
                "reason" to if (nekokoAvailable)
                    "Android system LPA requires Android 9 or newer. NekokoLPA2 handoff is available."
                else
                    "Android 9 or newer is required for platform eSIM support.",
            )
        }

        val euicc = getSystemService(Context.EUICC_SERVICE) as? EuiccManager
        val enabled = euicc?.isEnabled == true
        return mapOf(
            "platform" to "android",
            "esimSupported" to enabled,
            "directInstallSupported" to enabled,
            "transport" to when {
                enabled -> "android_system_lpa"
                nekokoAvailable -> "nekoko_deeplink"
                else -> "none"
            },
            "nekokoAvailable" to nekokoAvailable,
            "reason" to when {
                enabled && nekokoAvailable -> "Android system eSIM installation is available. NekokoLPA2 is also available as an alternate transport."
                enabled -> "Android system eSIM installation is available. The system may ask for user approval."
                nekokoAvailable -> "No enabled system eUICC was detected, but NekokoLPA2 can receive this activation code."
                else -> "No enabled eUICC or NekokoLPA2 transport was detected on this device."
            },
        )
    }

    private fun isNekokoAvailable(): Boolean {
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse("lpa:1\$example.invalid\$probe"))
            .setPackage(NEKOKO_PACKAGE)
        return intent.resolveActivity(packageManager) != null
    }

    private fun openNekoko(result: MethodChannel.Result) {
        val intent = packageManager.getLaunchIntentForPackage(NEKOKO_PACKAGE)
            ?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        if (intent == null) {
            result.error(
                "NEKOKO_UNAVAILABLE",
                "NekokoLPA2 is not installed or cannot be opened.",
                null,
            )
            return
        }
        try {
            startActivity(intent)
            result.success(
                mapOf(
                    "status" to "opened",
                    "transport" to "nekoko_app",
                ),
            )
        } catch (error: Throwable) {
            result.error("NEKOKO_LAUNCH_FAILED", error.message ?: error.javaClass.simpleName, null)
        }
    }

    private fun handoffToNekoko(activationCode: String, result: MethodChannel.Result) {
        if (activationCode.isBlank()) {
            result.error("INVALID_ACTIVATION_CODE", "Activation code is empty.", null)
            return
        }
        val normalized = if (activationCode.startsWith("LPA:", ignoreCase = true)) {
            activationCode
        } else {
            "LPA:$activationCode"
        }
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(normalized))
            .setPackage(NEKOKO_PACKAGE)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        if (intent.resolveActivity(packageManager) == null) {
            result.error("NEKOKO_UNAVAILABLE", "NekokoLPA2 is not installed or cannot handle LPA links.", null)
            return
        }
        try {
            startActivity(intent)
            result.success(
                mapOf(
                    "status" to "handed_off",
                    "transport" to "nekoko_deeplink",
                ),
            )
        } catch (error: Throwable) {
            result.error("NEKOKO_LAUNCH_FAILED", error.message ?: error.javaClass.simpleName, null)
        }
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
