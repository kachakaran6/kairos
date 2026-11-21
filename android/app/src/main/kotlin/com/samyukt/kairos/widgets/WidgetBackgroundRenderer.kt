package com.samyukt.kairos.widgets

import android.content.Context
import android.graphics.*
import android.util.DisplayMetrics
import kotlin.math.cos
import kotlin.math.sin

/**
 * High-performance hardware-accelerated background renderer for Kairos home widgets.
 * Renders anti-aliased rounded rectangle backgrounds with customizable corner radius (0-40dp),
 * refined luxury gradients (Warm Paper, Dark Ink, Terracotta, Glass, Photo scrim, Transparent),
 * hairline borders, and soft inner top highlights.
 *
 * Eliminates the Android RemoteViews limitation where calling setBackgroundColor strips corner radii
 * on Xiaomi HyperOS / MIUI and standard Android launchers.
 */
object WidgetBackgroundRenderer {

    // Simple cache to prevent excessive bitmap allocations on update loops
    private var cachedBitmap: Bitmap? = null
    private var lastCacheKey: String = ""

    /**
     * Renders a custom anti-aliased rounded background bitmap matching the widget dimensions and look.
     */
    fun createBackgroundBitmap(
        context: Context,
        widthPx: Int,
        heightPx: Int,
        config: WidgetConfig,
        photoBitmap: Bitmap? = null
    ): Bitmap {
        val w = if (widthPx > 0) widthPx else 480
        val h = if (heightPx > 0) heightPx else 260

        val density = context.resources.displayMetrics.density
        val radiusPx = (config.cornerRadiusDp * density).coerceIn(0f, (Math.min(w, h) / 2f))

        val bgType = config.backgroundType.lowercase()
        val opacity = config.backgroundOpacity.coerceIn(0.0f, 1.0f)
        val cacheKey = "${w}x${h}_${radiusPx}_${bgType}_${config.backgroundColor}_${opacity}_${config.borderEnabled}"

        if (photoBitmap == null && cacheKey == lastCacheKey && cachedBitmap != null && !cachedBitmap!!.isRecycled) {
            return cachedBitmap!!
        }

        val bitmap = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)

        val rect = RectF(0f, 0f, w.toFloat(), h.toFloat())
        val bgPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.FILL
        }

        // Draw background base (gradient, photo, or solid)
        when (bgType) {
            "warm_paper" -> {
                // Luxury warm paper: creamy ivory top to warm almond depth
                val startColor = Color.argb((opacity * 255).toInt(), 0xFB, 0xF9, 0xF5)
                val endColor = Color.argb((opacity * 255).toInt(), 0xF3, 0xEE, 0xE7)
                bgPaint.shader = LinearGradient(
                    0f, 0f, 0f, h.toFloat(),
                    startColor, endColor,
                    Shader.TileMode.CLAMP
                )
                canvas.drawRoundRect(rect, radiusPx, radiusPx, bgPaint)
            }
            "dark_ink" -> {
                // Deep obsidian: subtle warm charcoal gradient
                val startColor = Color.argb((opacity * 255).toInt(), 0x18, 0x16, 0x14)
                val endColor = Color.argb((opacity * 255).toInt(), 0x0C, 0x0A, 0x09)
                bgPaint.shader = LinearGradient(
                    0f, 0f, 0f, h.toFloat(),
                    startColor, endColor,
                    Shader.TileMode.CLAMP
                )
                canvas.drawRoundRect(rect, radiusPx, radiusPx, bgPaint)
            }
            "terracotta" -> {
                // Signature warm terracotta
                val startColor = Color.argb((opacity * 255).toInt(), 0xD0, 0x64, 0x3B)
                val endColor = Color.argb((opacity * 255).toInt(), 0xB0, 0x48, 0x22)
                bgPaint.shader = LinearGradient(
                    0f, 0f, w.toFloat() * 0.5f, h.toFloat(),
                    startColor, endColor,
                    Shader.TileMode.CLAMP
                )
                canvas.drawRoundRect(rect, radiusPx, radiusPx, bgPaint)
            }
            "glass" -> {
                // Translucent acrylic glass with soft frosted gradient
                val isDark = config.themeMode == "dark"
                val startAlpha = (opacity * 0.85f * 255).toInt().coerceIn(0, 255)
                val endAlpha = (opacity * 0.55f * 255).toInt().coerceIn(0, 255)
                val baseR = if (isDark) 28 else 255
                val baseG = if (isDark) 25 else 255
                val baseB = if (isDark) 23 else 255

                bgPaint.shader = LinearGradient(
                    0f, 0f, w.toFloat(), h.toFloat(),
                    Color.argb(startAlpha, baseR, baseG, baseB),
                    Color.argb(endAlpha, baseR, baseG, baseB),
                    Shader.TileMode.CLAMP
                )
                canvas.drawRoundRect(rect, radiusPx, radiusPx, bgPaint)
            }
            "photo" -> {
                if (photoBitmap != null && !photoBitmap.isRecycled) {
                    val photoShader = BitmapShader(photoBitmap, Shader.TileMode.CLAMP, Shader.TileMode.CLAMP)
                    val matrix = Matrix()
                    val scale = Math.max(w.toFloat() / photoBitmap.width, h.toFloat() / photoBitmap.height)
                    matrix.setScale(scale, scale)
                    val dx = (w - photoBitmap.width * scale) * 0.5f
                    val dy = (h - photoBitmap.height * scale) * 0.5f
                    matrix.postTranslate(dx, dy)
                    photoShader.setLocalMatrix(matrix)
                    bgPaint.shader = photoShader
                    canvas.drawRoundRect(rect, radiusPx, radiusPx, bgPaint)

                    // Draw dark vignette scrim over photo to guarantee legibility
                    val scrimPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                        style = Paint.Style.FILL
                        this.shader = LinearGradient(
                            0f, 0f, 0f, h.toFloat(),
                            Color.argb(140, 0, 0, 0),
                            Color.argb(210, 0, 0, 0),
                            Shader.TileMode.CLAMP
                        )
                    }
                    canvas.drawRoundRect(rect, radiusPx, radiusPx, scrimPaint)
                } else {
                    // Fallback to dark ink
                    bgPaint.color = Color.argb((opacity * 255).toInt(), 0x16, 0x14, 0x12)
                    canvas.drawRoundRect(rect, radiusPx, radiusPx, bgPaint)
                }
            }
            "transparent" -> {
                // Clear transparent canvas (optionally with hairline border)
                bgPaint.color = Color.TRANSPARENT
                canvas.drawRoundRect(rect, radiusPx, radiusPx, bgPaint)
            }
            else -> {
                // Custom or Look-defined color
                val baseColor = try {
                    Color.parseColor(config.backgroundColor)
                } catch (_: Exception) {
                    Color.parseColor("#0F0D0B")
                }
                val alpha = (opacity * 255).toInt().coerceIn(0, 255)
                bgPaint.color = Color.argb(alpha, Color.red(baseColor), Color.green(baseColor), Color.blue(baseColor))
                canvas.drawRoundRect(rect, radiusPx, radiusPx, bgPaint)
            }
        }

        // Soft inner top highlight rim (subtle physical lighting on top edge)
        if (radiusPx > 0 && bgType != "transparent") {
            val isDark = config.themeMode == "dark" || bgType == "dark_ink" || bgType == "photo"
            val highlightPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.STROKE
                strokeWidth = 1f * density
                color = if (isDark) Color.argb(25, 255, 255, 255) else Color.argb(90, 255, 255, 255)
            }
            val insetRect = RectF(rect)
            insetRect.inset(highlightPaint.strokeWidth * 0.5f, highlightPaint.strokeWidth * 0.5f)
            canvas.drawRoundRect(insetRect, radiusPx, radiusPx, highlightPaint)
        }

        // Hairline boundary stroke
        if (config.borderEnabled && radiusPx > 0) {
            val strokePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.STROKE
                strokeWidth = (config.borderWidthDp * density).coerceAtLeast(1f)
                val isDark = config.themeMode == "dark" || bgType == "dark_ink" || bgType == "photo"
                color = if (isDark) Color.argb(38, 255, 255, 255) else Color.argb(28, 26, 23, 20)
            }
            val strokeRect = RectF(rect)
            strokeRect.inset(strokePaint.strokeWidth * 0.5f, strokePaint.strokeWidth * 0.5f)
            canvas.drawRoundRect(strokeRect, radiusPx, radiusPx, strokePaint)
        }

        if (photoBitmap == null) {
            cachedBitmap = bitmap
            lastCacheKey = cacheKey
        }

        return bitmap
    }
}
