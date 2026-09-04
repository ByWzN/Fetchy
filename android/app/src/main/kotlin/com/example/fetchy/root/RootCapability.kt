// android/app/src/main/kotlin/com/example/fetchy/root/RootCapability.kt
package com.example.fetchy.root

import java.io.IOException

enum class RootStatus { AVAILABLE, UNAVAILABLE, DENIED, UNKNOWN }

/// A real root-capability check: attempts to actually execute a command
/// through `su`, rather than checking for the mere existence of a file
/// like `/system/xbin/su` — that file's presence proves nothing about
/// whether root access is actually grantable, and its absence proves
/// nothing either on devices that relocate or hide it.
///
/// This is deliberately the ONLY thing Fetchy's root support does
/// automatically-adjacent: it still only ever runs when explicitly invoked
/// (see [com.example.fetchy.root.RootChannelHandler]), never at app
/// startup and never as a side effect of any other action. Running `su`
/// for the first time is itself what triggers the root manager's (Magisk/
/// KernelSU/etc.) own grant prompt on the device — Android has no separate
/// "request root" API to call instead.
object RootCapability {
    fun checkStatus(): RootStatus {
        return try {
            val process = Runtime.getRuntime().exec(arrayOf("su", "-c", "id"))
            val output = process.inputStream.bufferedReader().use { it.readText() }
            val exitCode = process.waitFor()

            when {
                exitCode == 0 && output.contains("uid=0") -> RootStatus.AVAILABLE
                exitCode == 0 -> RootStatus.UNKNOWN
                else -> RootStatus.DENIED
            }
        } catch (notFound: IOException) {
            // No `su` binary reachable at all — not a rooted device, or the
            // root manager doesn't expose one on the PATH this process sees.
            RootStatus.UNAVAILABLE
        } catch (throwable: Throwable) {
            RootStatus.UNKNOWN
        }
    }
}
