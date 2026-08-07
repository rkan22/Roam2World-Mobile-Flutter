package com.roam2world.b2b

import android.content.Context
import android.os.Build
import android.se.omapi.Channel
import android.se.omapi.Reader
import android.se.omapi.SEService
import android.se.omapi.Session
import io.flutter.plugin.common.MethodChannel

class OmapiEuiccBridge(private val context: Context) {
    companion object {
        // GSMA ISD-R AID, also used as NekokoLPA2's minimal fallback.
        private const val ISD_R_AID = "A0000005591010FFFFFFFF8900000100"
    }

    private var service: SEService? = null
    private var session: Session? = null
    private var channel: Channel? = null
    private var connectedReader: String? = null
    private var connecting = false
    private val pending = mutableListOf<(Result<SEService>) -> Unit>()

    fun capability(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) {
            result.success(capabilityMap(false, null, "Android 9 or newer is required for OMAPI."))
            return
        }
        withService { serviceResult ->
            serviceResult.fold(
                onSuccess = { se ->
                    val probe = probeReader(se)
                    if (probe != null) {
                        result.success(capabilityMap(true, probe, "Public OMAPI can open the eUICC ISD-R logical channel."))
                    } else {
                        result.success(capabilityMap(false, null, "No OMAPI reader granted access to the eUICC ISD-R application."))
                    }
                },
                onFailure = { error ->
                    result.success(capabilityMap(false, null, error.message ?: "OMAPI service is unavailable."))
                },
            )
        }
    }

    fun open(result: MethodChannel.Result) {
        if (channel?.isOpen == true) {
            result.success(mapOf("reader" to (connectedReader ?: "unknown"), "aid" to ISD_R_AID))
            return
        }
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) {
            result.error("OMAPI_UNSUPPORTED", "Android 9 or newer is required for OMAPI.", null)
            return
        }
        withService { serviceResult ->
            serviceResult.fold(
                onSuccess = { se ->
                    try {
                        val opened = openFirstAllowedChannel(se)
                        if (!opened) {
                            result.error("OMAPI_ACCESS_DENIED", "No OMAPI reader allowed access to the eUICC ISD-R application.", null)
                        } else {
                            result.success(mapOf("reader" to (connectedReader ?: "unknown"), "aid" to ISD_R_AID))
                        }
                    } catch (error: Throwable) {
                        closeChannel()
                        result.error("OMAPI_OPEN_FAILED", error.message ?: error.javaClass.simpleName, null)
                    }
                },
                onFailure = { error -> result.error("OMAPI_CONNECT_FAILED", error.message, null) },
            )
        }
    }

    fun transmit(apdu: ByteArray?, result: MethodChannel.Result) {
        if (apdu == null || apdu.size < 4) {
            result.error("INVALID_APDU", "APDU must contain at least CLA, INS, P1 and P2.", null)
            return
        }
        val active = channel
        if (active?.isOpen != true) {
            result.error("OMAPI_CHANNEL_CLOSED", "Open the eUICC logical channel before transmitting APDUs.", null)
            return
        }
        try {
            result.success(active.transmit(apdu))
        } catch (security: SecurityException) {
            closeChannel()
            result.error("OMAPI_ACCESS_DENIED", security.message ?: "Secure-element access was denied.", null)
        } catch (error: Throwable) {
            result.error("OMAPI_TRANSMIT_FAILED", error.message ?: error.javaClass.simpleName, null)
        }
    }

    fun close(result: MethodChannel.Result? = null) {
        closeChannel()
        result?.success(null)
    }

    fun shutdown() {
        closeChannel()
        runCatching { service?.shutdown() }
        service = null
        pending.clear()
        connecting = false
    }

    private fun capabilityMap(available: Boolean, reader: String?, reason: String) = mapOf(
        "available" to available,
        "transport" to "android_omapi",
        "reader" to (reader ?: ""),
        "aid" to ISD_R_AID,
        "reason" to reason,
    )

    private fun withService(callback: (Result<SEService>) -> Unit) {
        val current = service
        if (current?.isConnected == true) {
            callback(Result.success(current))
            return
        }
        pending.add(callback)
        if (connecting) return
        connecting = true
        try {
            lateinit var created: SEService
            created = SEService(context.applicationContext, context.mainExecutor) {
                service = created
                connecting = false
                val callbacks = pending.toList()
                pending.clear()
                val value = if (created.isConnected) Result.success(created)
                else Result.failure(IllegalStateException("OMAPI service did not connect."))
                callbacks.forEach { it(value) }
            }
            service = created
        } catch (error: Throwable) {
            connecting = false
            val callbacks = pending.toList()
            pending.clear()
            callbacks.forEach { it(Result.failure(error)) }
        }
    }

    private fun probeReader(se: SEService): String? {
        for (reader in orderedReaders(se.readers)) {
            var probeSession: Session? = null
            var probeChannel: Channel? = null
            try {
                probeSession = reader.openSession()
                probeChannel = probeSession.openLogicalChannel(hexToBytes(ISD_R_AID))
                if (probeChannel != null && probeChannel.isOpen) return reader.name
            } catch (_: Throwable) {
                // Reader access is governed by Android secure-element access control.
            } finally {
                runCatching { probeChannel?.close() }
                runCatching { probeSession?.close() }
            }
        }
        return null
    }

    private fun openFirstAllowedChannel(se: SEService): Boolean {
        closeChannel()
        for (reader in orderedReaders(se.readers)) {
            var candidateSession: Session? = null
            try {
                candidateSession = reader.openSession()
                val candidateChannel = candidateSession.openLogicalChannel(hexToBytes(ISD_R_AID))
                if (candidateChannel != null && candidateChannel.isOpen) {
                    session = candidateSession
                    channel = candidateChannel
                    connectedReader = reader.name
                    return true
                }
                runCatching { candidateSession.close() }
            } catch (_: Throwable) {
                runCatching { candidateSession?.close() }
            }
        }
        return false
    }

    private fun orderedReaders(readers: Array<Reader>): List<Reader> = readers.sortedBy { reader ->
        val name = reader.name.uppercase()
        when {
            name.startsWith("SIM") || name.contains("UICC") -> 0
            name.startsWith("ESE") -> 1
            else -> 2
        }
    }

    private fun closeChannel() {
        runCatching { channel?.close() }
        runCatching { session?.close() }
        channel = null
        session = null
        connectedReader = null
    }

    private fun hexToBytes(value: String): ByteArray {
        require(value.length % 2 == 0)
        return ByteArray(value.length / 2) { index ->
            value.substring(index * 2, index * 2 + 2).toInt(16).toByte()
        }
    }
}
