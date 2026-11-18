package com.samyukt.kairos.widgets

import android.content.Context
import android.graphics.*

/**
 * Generates mathematically concentric rounded rectangle drawables for inner widget elements
 * (chips, pills, quick-action buttons) adhering to Apple and Material You concentric curvature rules:
 * r_inner = max(6dp, R_outer - padding)
 */
object WidgetShapeHelper {

    fun createConcentricChipBitmap(
        context: Context,
        widthDp: Int,
        heightDp: Int,
        outerRadiusDp: Float,
        paddingDp: Float,
        fillColor: Int,
        strokeColor: Int? = null,
        strokeWidthDp: Float = 1.0f
    ): Bitmap {
        val density = context.resources.displayMetrics.density
        val w = (widthDp * density).toInt().coerceAtLeast(32)
        val h = (heightDp * density).toInt().coerceAtLeast(24)

        val innerRadiusPx = Math.max(6f * density, (outerRadiusDp - paddingDp) * density)

        val bitmap = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val rect = RectF(0f, 0f, w.toFloat(), h.toFloat())

        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.FILL
            color = fillColor
        }
        canvas.drawRoundRect(rect, innerRadiusPx, innerRadiusPx, paint)

        if (strokeColor != null) {
            val strokePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.STROKE
                this.strokeWidth = strokeWidthDp * density
                color = strokeColor
            }
            val strokeRect = RectF(rect)
            strokeRect.inset(strokePaint.strokeWidth * 0.5f, strokePaint.strokeWidth * 0.5f)
            canvas.drawRoundRect(strokeRect, innerRadiusPx, innerRadiusPx, strokePaint)
        }

        return bitmap
    }
}
