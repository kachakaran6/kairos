package com.samyukt.kairos.widgets

import android.content.Context
import android.graphics.*

/**
 * Renders an ultra-clean, high-resolution progress ring per metric for Kairos home widgets.
 * Replaces unreadable overlapping concentric circles with a confident progress ring
 * featuring thick rounded caps, a smooth accent gradient stroke, a soft background track,
 * and bold centered metric typography.
 */
object WidgetProgressRenderer {

    fun createProgressRingBitmap(
        context: Context,
        sizeDp: Int,
        progressPercent: Float, // 0.0f to 1.0f
        centerValue: String,
        centerLabel: String? = null,
        accentColor: Int,
        textColor: Int,
        secondaryTextColor: Int
    ): Bitmap {
        val density = context.resources.displayMetrics.density
        val sizePx = (sizeDp * density).toInt().coerceAtLeast(64)
        val strokeWidth = (6.5f * density)

        val bitmap = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)

        val center = sizePx / 2f
        val radius = center - (strokeWidth / 2f) - (2f * density)
        val oval = RectF(center - radius, center - radius, center + radius, center + radius)

        // 1. Soft background track
        val trackPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            this.strokeWidth = strokeWidth
            strokeCap = Paint.Cap.ROUND
            color = Color.argb(32, Color.red(textColor), Color.green(textColor), Color.blue(textColor))
        }
        canvas.drawCircle(center, center, radius, trackPaint)

        // 2. Glowing progress arc with rounded caps and gradient
        val clampedProgress = progressPercent.coerceIn(0.0f, 1.0f)
        if (clampedProgress > 0.01f) {
            val sweepAngle = clampedProgress * 360f

            // Create accent color gradient (slightly brighter start to deep accent end)
            val hsv = FloatArray(3)
            Color.colorToHSV(accentColor, hsv)
            hsv[1] = (hsv[1] * 0.75f).coerceIn(0f, 1f) // slightly desaturated start
            val startGradientColor = Color.HSVToColor(hsv)

            val midPos = (clampedProgress * 0.95f).coerceIn(0.05f, 0.95f)
            val arcPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.STROKE
                this.strokeWidth = strokeWidth
                strokeCap = Paint.Cap.ROUND
                shader = SweepGradient(
                    center, center,
                    intArrayOf(startGradientColor, accentColor, startGradientColor),
                    floatArrayOf(0.0f, midPos, 1.0f)
                )
            }

            canvas.save()
            // Start at top (-90 degrees)
            canvas.rotate(-90f, center, center)
            canvas.drawArc(oval, 0f, sweepAngle, false, arcPaint)
            canvas.restore()
        }

        // 3. Crisp centered typography
        val valuePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            textAlign = Paint.Align.CENTER
            color = textColor
            textSize = 14f * density
            typeface = Typeface.create(Typeface.SANS_SERIF, Typeface.BOLD)
        }

        if (centerLabel.isNullOrEmpty()) {
            val yOffset = center - ((valuePaint.descent() + valuePaint.ascent()) / 2f)
            canvas.drawText(centerValue, center, yOffset, valuePaint)
        } else {
            valuePaint.textSize = 12f * density
            val labelPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                textAlign = Paint.Align.CENTER
                color = secondaryTextColor
                textSize = 8.5f * density
                typeface = Typeface.create(Typeface.SANS_SERIF, Typeface.NORMAL)
            }
            val yValue = center - (1f * density)
            val yLabel = center + (10f * density)
            canvas.drawText(centerValue, center, yValue, valuePaint)
            canvas.drawText(centerLabel, center, yLabel, labelPaint)
        }

        return bitmap
    }
}
