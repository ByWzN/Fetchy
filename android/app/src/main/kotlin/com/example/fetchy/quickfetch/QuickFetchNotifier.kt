package com.example.fetchy.quickfetch

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import com.example.fetchy.MainActivity
import com.example.fetchy.R

/// The notification surface for a pending Quick Fetch candidate.
///
/// The text never contains clipboard content or any text taken from the source
/// app — at this point Fetchy does not know what was copied. Only the platform
/// name, derived from the source package, is shown.
class QuickFetchNotifier(context: Context) {

    private val context: Context = context.applicationContext

    /// Safe to call repeatedly; the platform ignores re-creation of an
    /// existing channel and never resets the user's own changes.
    fun ensureChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val manager = context.getSystemService(NotificationManager::class.java) ?: return

        val channel = NotificationChannel(
            CHANNEL_CANDIDATE,
            context.getString(R.string.quick_fetch_channel_name),
            NotificationManager.IMPORTANCE_DEFAULT,
        ).apply {
            description = context.getString(R.string.quick_fetch_channel_description)
            setShowBadge(true)
        }

        manager.createNotificationChannel(channel)
    }

    /// Posts the quick action. Returns false when the platform refused — for
    /// example POST_NOTIFICATIONS denied on Android 13+ — so the caller can
    /// fall back instead of assuming it worked.
    fun showCandidate(candidate: QuickFetchPendingCandidate): Boolean {
        if (!areNotificationsAllowed()) return false

        ensureChannel()

        val openPending = PendingIntent.getActivity(
            context,
            QuickFetchContract.REQUEST_OPEN,
            Intent(context, MainActivity::class.java).apply {
                action = QuickFetchContract.ACTION_OPEN
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val dismissPending = PendingIntent.getBroadcast(
            context,
            QuickFetchContract.REQUEST_DISMISS,
            Intent(context, QuickFetchDismissReceiver::class.java).apply {
                action = QuickFetchContract.ACTION_DISMISS
                // Explicit component: an implicit broadcast would be blocked.
                setPackage(context.packageName)
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, CHANNEL_CANDIDATE)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context)
        }

        // Android already shows the app name and timestamp in the
        // notification header ("Fetchy • now"), so the content here never
        // repeats "Fetchy" — it only says what happened.
        val notification = builder
            .setContentTitle(
                context.getString(R.string.quick_fetch_notification_title, candidate.platform),
            )
            .setContentText(context.getString(R.string.quick_fetch_notification_text))
            .setSmallIcon(R.drawable.ic_quick_fetch)
            .setAutoCancel(true)
            .setContentIntent(openPending)
            .addAction(buildAction(context.getString(R.string.quick_fetch_action_fetch), openPending))
            .addAction(buildAction(context.getString(R.string.quick_fetch_action_dismiss), dismissPending))
            .apply {
                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
                    @Suppress("DEPRECATION")
                    setPriority(Notification.PRIORITY_DEFAULT)
                }
            }
            .build()

        return try {
            val manager = context.getSystemService(NotificationManager::class.java)
                ?: return false
            manager.notify(NOTIFICATION_CANDIDATE, notification)
            true
        } catch (throwable: Throwable) {
            Log.w(TAG, "Failed to post the Quick Fetch notification", throwable)
            false
        }
    }

    fun cancelCandidate() {
        try {
            context.getSystemService(NotificationManager::class.java)
                ?.cancel(NOTIFICATION_CANDIDATE)
        } catch (throwable: Throwable) {
            Log.w(TAG, "Failed to cancel the Quick Fetch notification", throwable)
        }
    }

    /// True when the app may post notifications the user will actually see.
    /// On Android 13+ this reflects the POST_NOTIFICATIONS runtime grant.
    fun areNotificationsAllowed(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            val granted = context.checkSelfPermission(
                android.Manifest.permission.POST_NOTIFICATIONS,
            ) == PackageManager.PERMISSION_GRANTED
            if (!granted) return false
        }

        return try {
            context.getSystemService(NotificationManager::class.java)
                ?.areNotificationsEnabled() ?: false
        } catch (throwable: Throwable) {
            false
        }
    }

    @Suppress("DEPRECATION")
    private fun buildAction(title: String, intent: PendingIntent): Notification.Action {
        return Notification.Action.Builder(
            android.graphics.drawable.Icon.createWithResource(
                context,
                R.drawable.ic_quick_fetch,
            ),
            title,
            intent,
        ).build()
    }

    companion object {
        private const val TAG = "QuickFetchNotifier"

        const val CHANNEL_CANDIDATE = "fetchy_quick_fetch_candidate"
        const val NOTIFICATION_CANDIDATE = 4202
    }
}
