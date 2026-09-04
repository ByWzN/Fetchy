package com.example.fetchy.quickfetch

import android.content.Context
import android.content.SharedPreferences

/// How the quick action is presented to the user.
enum class QuickFetchActionStyle {
    NOTIFICATION,
    FLOATING_DOT;

    companion object {
        fun fromName(raw: String?): QuickFetchActionStyle = when (raw) {
            "floatingDot" -> FLOATING_DOT
            else -> NOTIFICATION
        }

        fun toName(style: QuickFetchActionStyle): String = when (style) {
            FLOATING_DOT -> "floatingDot"
            NOTIFICATION -> "notification"
        }
    }
}

/// Native-side persistence for Quick Fetch. Kept separate from Flutter's
/// SharedPreferences file so the service can read its own configuration on
/// restart without booting a Flutter engine.
///
/// Only feature configuration is stored here — never clipboard content.
object QuickFetchPrefs {

    private const val FILE = "fetchy_quick_fetch"
    private const val KEY_ENABLED = "enabled"
    private const val KEY_ACTION_STYLE = "actionStyle"

    private fun prefs(context: Context): SharedPreferences =
        context.applicationContext.getSharedPreferences(FILE, Context.MODE_PRIVATE)

    fun isEnabled(context: Context): Boolean =
        prefs(context).getBoolean(KEY_ENABLED, false)

    fun setEnabled(context: Context, enabled: Boolean) {
        prefs(context).edit().putBoolean(KEY_ENABLED, enabled).apply()
    }

    fun actionStyle(context: Context): QuickFetchActionStyle =
        QuickFetchActionStyle.fromName(prefs(context).getString(KEY_ACTION_STYLE, null))

    fun setActionStyle(context: Context, style: QuickFetchActionStyle) {
        prefs(context)
            .edit()
            .putString(KEY_ACTION_STYLE, QuickFetchActionStyle.toName(style))
            .apply()
    }
}
