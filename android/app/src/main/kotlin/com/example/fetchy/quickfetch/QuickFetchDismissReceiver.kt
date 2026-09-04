package com.example.fetchy.quickfetch

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/// Handles the notification's Dismiss action. Not exported — it is only ever
/// triggered by Fetchy's own PendingIntent.
///
/// Dismissing clears the candidate and every surface showing it, but leaves
/// detection running: the user dismissed one link, not the feature.
class QuickFetchDismissReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context?, intent: Intent?) {
        if (context == null) return
        if (intent?.action != QuickFetchContract.ACTION_DISMISS) return

        QuickFetchPresenter.clear(context.applicationContext)
    }
}
