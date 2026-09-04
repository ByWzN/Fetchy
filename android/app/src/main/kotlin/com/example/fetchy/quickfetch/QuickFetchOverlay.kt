package com.example.fetchy.quickfetch

import android.annotation.SuppressLint
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.provider.Settings
import android.util.Log
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.ViewConfiguration
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.ImageView
import com.example.fetchy.MainActivity
import com.example.fetchy.R
import kotlin.math.abs

/// The optional floating dot. A small, draggable circular button that only
/// exists while a detected link is pending, then removes itself.
///
/// Intentionally plain: a solid Fetchy-blue circle with a white download
/// glyph and a light elevation — no glow, no halo, no large surface.
class QuickFetchOverlay(private val context: Context) {

    private var windowManager: WindowManager? = null
    private var overlayView: View? = null

    /// True when the user has granted "display over other apps".
    fun canDrawOverlays(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(context)
        } else {
            // Below API 23 the permission is install-time and always granted.
            true
        }
    }

    /// Shows the dot for the pending candidate. Returns false when the overlay
    /// could not be shown — most often because the permission was revoked
    /// while Quick Fetch was enabled — so the caller can fall back.
    ///
    /// The dot carries no URL: tapping it opens Fetchy, and only then is the
    /// clipboard read.
    @SuppressLint("ClickableViewAccessibility")
    fun show(): Boolean {
        if (!canDrawOverlays()) return false

        // A newer candidate reuses the dot that is already on screen.
        if (overlayView != null) return true

        return try {
            val manager = context.getSystemService(WindowManager::class.java)
                ?: return false

            val view = buildDotView()
            val params = buildLayoutParams()

            attachDragAndTap(view, params, manager)

            manager.addView(view, params)
            windowManager = manager
            overlayView = view
            true
        } catch (throwable: Throwable) {
            Log.w(TAG, "Failed to show Quick Fetch overlay", throwable)
            cleanUp()
            false
        }
    }

    /// Removes the dot and clears the pending target. Safe to call when
    /// nothing is showing.
    fun hide() {
        val view = overlayView
        val manager = windowManager
        if (view != null && manager != null) {
            try {
                manager.removeView(view)
            } catch (throwable: Throwable) {
                Log.w(TAG, "Failed to remove Quick Fetch overlay", throwable)
            }
        }
        cleanUp()
    }

    private fun cleanUp() {
        overlayView = null
        windowManager = null
    }

    private fun buildDotView(): View {
        val density = context.resources.displayMetrics.density
        val padPx = (DOT_PADDING_DP * density).toInt()

        val circle = GradientDrawable().apply {
            shape = GradientDrawable.OVAL
            setColor(FETCHY_BG)
            setStroke((1 * density).toInt(), FETCHY_EDGE)
        }

        val icon = ImageView(context).apply {
            setImageResource(R.drawable.ic_launcher_foreground)
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT,
            )
            setPadding(padPx, padPx, padPx, padPx)
        }

        // The root's own layoutParams are supplied by the WindowManager, so
        // the dot's size is set there rather than here.
        return FrameLayout(context).apply {
            background = circle
            elevation = 6 * density
            contentDescription = context.getString(R.string.quick_fetch_overlay_content_description)
            addView(icon)
        }
    }

    private fun buildLayoutParams(): WindowManager.LayoutParams {
        val density = context.resources.displayMetrics.density
        val sizePx = (DOT_SIZE_DP * density).toInt()

        val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }

        return WindowManager.LayoutParams(
            sizePx,
            sizePx,
            type,
            // Not focusable: the dot must never steal keyboard input or
            // interfere with the app the user is actually looking at.
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            android.graphics.PixelFormat.TRANSLUCENT,
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = (INITIAL_X_DP * density).toInt()
            y = (INITIAL_Y_DP * density).toInt()
        }
    }

    @SuppressLint("ClickableViewAccessibility")
    private fun attachDragAndTap(
        view: View,
        params: WindowManager.LayoutParams,
        manager: WindowManager,
    ) {
        val touchSlop = ViewConfiguration.get(context).scaledTouchSlop

        var initialX = 0
        var initialY = 0
        var touchStartX = 0f
        var touchStartY = 0f
        var dragged = false

        view.setOnTouchListener { _, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    initialX = params.x
                    initialY = params.y
                    touchStartX = event.rawX
                    touchStartY = event.rawY
                    dragged = false
                    true
                }

                MotionEvent.ACTION_MOVE -> {
                    val dx = event.rawX - touchStartX
                    val dy = event.rawY - touchStartY
                    if (!dragged && (abs(dx) > touchSlop || abs(dy) > touchSlop)) {
                        dragged = true
                    }
                    if (dragged) {
                        params.x = initialX + dx.toInt()
                        params.y = initialY + dy.toInt()
                        try {
                            manager.updateViewLayout(view, params)
                        } catch (throwable: Throwable) {
                            Log.w(TAG, "Failed to move Quick Fetch overlay", throwable)
                        }
                    }
                    true
                }

                MotionEvent.ACTION_UP -> {
                    if (!dragged) onDotTapped()
                    true
                }

                else -> false
            }
        }
    }

    private fun onDotTapped() {
        val intent = Intent(context, MainActivity::class.java).apply {
            action = QuickFetchContract.ACTION_OPEN
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        }

        try {
            // Holding SYSTEM_ALERT_WINDOW is one of the documented exemptions
            // from the Android 10+ background-activity-start restriction, and
            // it is exactly the permission the user granted for this mode.
            context.startActivity(intent)
        } catch (throwable: Throwable) {
            Log.w(TAG, "Failed to open Fetchy from the overlay", throwable)
        }

        hide()
    }

    companion object {
        private const val TAG = "QuickFetchOverlay"

        private const val DOT_SIZE_DP = 52
        private const val DOT_PADDING_DP = 0
        private const val INITIAL_X_DP = 16
        private const val INITIAL_Y_DP = 220

        private const val FETCHY_BG = 0xFF050B18.toInt()
        private const val FETCHY_EDGE = 0x3338BDF8
    }
}
