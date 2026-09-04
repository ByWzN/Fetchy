package com.example.fetchy.quickfetch

/// Intent actions and extras shared between the Quick Fetch surfaces and
/// MainActivity. Kept in one place so the launch contract cannot drift.
object QuickFetchContract {

    /// Sent to MainActivity when the user taps a quick action. Carries no URL:
    /// the clipboard is read only once the Activity is in front and focused.
    const val ACTION_OPEN = "com.example.fetchy.quickfetch.ACTION_OPEN"

    /// Broadcast to [QuickFetchDismissReceiver] when the user dismisses a
    /// pending candidate from the notification.
    const val ACTION_DISMISS = "com.example.fetchy.quickfetch.ACTION_DISMISS"

    /// Distinct request codes so the pending intents never collide.
    const val REQUEST_OPEN = 4101
    const val REQUEST_DISMISS = 4102
}
