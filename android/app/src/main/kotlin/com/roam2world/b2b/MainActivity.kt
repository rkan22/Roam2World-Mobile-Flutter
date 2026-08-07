package com.roam2world.b2b

import android.content.Context
import android.os.Build
import android.telephony.euicc.EuiccManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val LPA_CHANNEL = "com.roam2world.mobile/lpa"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LPA_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getCapability" -> result.success(getLpaCapability())
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
                "reason" to "Android 9 or newer is required for platform eSIM support.",
            )
        }

        val euicc = getSystemService(Context.EUICC_SERVICE) as? EuiccManager
        val enabled = euicc?.isEnabled == true
        return mapOf(
            "platform" to "android",
            "esimSupported" to enabled,
            // Public EuiccManager download APIs are carrier/LPA privileged. Do not claim
            // direct install until the Nekoko transport path is explicitly available.
            "directInstallSupported" to false,
            "reason" to if (enabled)
                "eSIM is available. Direct LPA installation requires an authorized Nekoko transport."
            else
                "No enabled eUICC was detected on this device.",
        )
    }
}
