package com.habiter.app.widget

import android.os.Build
import androidx.compose.ui.graphics.Color
import androidx.glance.color.ColorProvider as DayNightColorProvider
import androidx.glance.unit.ColorProvider
import kotlin.math.max
import kotlin.math.min
import kotlin.math.pow

internal data class HabiterWidgetColors(
    val surface: ColorProvider,
    val surfaceAccent: ColorProvider,
    val primary: ColorProvider,
    val onPrimary: ColorProvider,
    val onSurface: ColorProvider,
    val onSurfaceMuted: ColorProvider,
    val success: ColorProvider,
)

internal data class HabiterWidgetPalette(
    val surface: Int,
    val surfaceAccent: Int,
    val primary: Int,
    val onSurface: Int,
    val onSurfaceMuted: Int,
    val success: Int,
)

internal object HabiterWidgetTheme {
    private val light = HabiterWidgetPalette(
        surface = 0xFFFFFBF5.toInt(),
        surfaceAccent = 0xFFE3F2E8.toInt(),
        primary = 0xFF285943.toInt(),
        onSurface = 0xFF17211C.toInt(),
        onSurfaceMuted = 0xFF53635A.toInt(),
        success = 0xFF1D6B4B.toInt(),
    )
    private val dark = HabiterWidgetPalette(
        surface = 0xFF10231B.toInt(),
        surfaceAccent = 0xFF1B3A2C.toInt(),
        primary = 0xFF8ED8B4.toInt(),
        onSurface = 0xFFF1F7F3.toInt(),
        onSurfaceMuted = 0xFFB7C9BF.toInt(),
        success = 0xFF90E1BB.toInt(),
    )

    fun colorsFor(effective: EffectiveHabiterWidgetConfiguration): HabiterWidgetColors {
        val alpha = ((1.0 - effective.surfaceTransparency) * 255).toInt().coerceIn(153, 255)
        val base = when (effective.themeMode) {
            HabiterWidgetThemeMode.SYSTEM -> system(alpha)
            HabiterWidgetThemeMode.LIGHT -> light.withSurfaceAlpha(alpha).colors
            HabiterWidgetThemeMode.DARK -> dark.withSurfaceAlpha(alpha).colors
            HabiterWidgetThemeMode.CUSTOM -> customPalette(effective.colorTokens)
                .withSurfaceAlpha(alpha).colors
        }
        if (effective.accentMode != HabiterWidgetAccentMode.DYNAMIC_COLOR ||
            Build.VERSION.SDK_INT < Build.VERSION_CODES.S
        ) {
            return when (effective.accentMode) {
                HabiterWidgetAccentMode.CUSTOM -> customAccent(effective, base)
                HabiterWidgetAccentMode.HABITER,
                HabiterWidgetAccentMode.DYNAMIC_COLOR,
                -> base
            }
        }
        return base.copy(
            primary = ColorProvider(android.R.color.system_accent1_500),
            success = ColorProvider(android.R.color.system_accent2_500),
        )
    }

    private fun customAccent(
        effective: EffectiveHabiterWidgetConfiguration,
        base: HabiterWidgetColors,
    ): HabiterWidgetColors {
        val candidate = effective.colorTokens.primary.argbOrNull() ?: return base
        if (effective.themeMode == HabiterWidgetThemeMode.CUSTOM) return base
        if (effective.themeMode == HabiterWidgetThemeMode.SYSTEM) {
            val lightPrimary = accessibleForeground(candidate, light.surface, 4.5)
            val darkPrimary = accessibleForeground(candidate, dark.surface, 4.5)
            return base.copy(
                primary = DayNightColorProvider(Color(lightPrimary), Color(darkPrimary)),
                onPrimary = DayNightColorProvider(
                    Color(accessibleForeground(light.surface, lightPrimary, 4.5)),
                    Color(accessibleForeground(dark.surface, darkPrimary, 4.5)),
                ),
            )
        }
        val surface = if (effective.themeMode == HabiterWidgetThemeMode.DARK) dark.surface else light.surface
        val primary = accessibleForeground(candidate, surface, 4.5)
        return base.copy(
            primary = primary.provider,
            onPrimary = accessibleForeground(surface, primary, 4.5).provider,
        )
    }

    internal fun customPalette(tokens: HabiterWidgetColorTokens): HabiterWidgetPalette {
        val surface = tokens.surface.argbOrNull() ?: light.surface
        val text = accessibleForeground(tokens.text.argbOrNull() ?: light.onSurface, surface, 4.5)
        val accentCandidate = tokens.surfaceAccent.argbOrNull() ?: light.surfaceAccent
        val accent = if (contrast(text, accentCandidate) >= 4.5) accentCandidate else surface
        return HabiterWidgetPalette(
            surface = surface,
            surfaceAccent = accent,
            primary = accessibleForeground(tokens.primary.argbOrNull() ?: light.primary, surface, 4.5),
            onSurface = text,
            onSurfaceMuted = accessibleForeground(
                tokens.mutedText.argbOrNull() ?: light.onSurfaceMuted,
                surface,
                3.0,
            ),
            success = accessibleForeground(tokens.success.argbOrNull() ?: light.success, surface, 3.0),
        )
    }

    internal fun contrast(first: Int, second: Int): Double {
        val lighter = max(luminance(first), luminance(second))
        val darker = min(luminance(first), luminance(second))
        return (lighter + 0.05) / (darker + 0.05)
    }

    private fun system(alpha: Int): HabiterWidgetColors = HabiterWidgetColors(
        surface = DayNightColorProvider(
            Color(light.surface.withAlpha(alpha)),
            Color(dark.surface.withAlpha(alpha)),
        ),
        surfaceAccent = DayNightColorProvider(Color(light.surfaceAccent), Color(dark.surfaceAccent)),
        primary = DayNightColorProvider(Color(light.primary), Color(dark.primary)),
        onPrimary = DayNightColorProvider(Color(light.surface), Color(dark.surface)),
        onSurface = DayNightColorProvider(Color(light.onSurface), Color(dark.onSurface)),
        onSurfaceMuted = DayNightColorProvider(Color(light.onSurfaceMuted), Color(dark.onSurfaceMuted)),
        success = DayNightColorProvider(Color(light.success), Color(dark.success)),
    )

    private val HabiterWidgetPalette.colors: HabiterWidgetColors
        get() = HabiterWidgetColors(
            surface = surface.provider,
            surfaceAccent = surfaceAccent.provider,
            primary = primary.provider,
            onPrimary = accessibleForeground(surface.opaque(), primary, 4.5).provider,
            onSurface = onSurface.provider,
            onSurfaceMuted = onSurfaceMuted.provider,
            success = success.provider,
        )

    private fun HabiterWidgetPalette.withSurfaceAlpha(alpha: Int): HabiterWidgetPalette =
        copy(surface = surface.withAlpha(alpha))

    private fun Int.withAlpha(alpha: Int): Int = (this and 0x00FFFFFF) or (alpha shl 24)

    private fun Int.opaque(): Int = this or 0xFF000000.toInt()

    private val Int.provider: ColorProvider
        get() = ColorProvider(Color(this))

    private fun String?.argbOrNull(): Int? {
        if (this == null) return null
        val digits = removePrefix("#")
        return runCatching {
            val value = digits.toLong(16)
            if (digits.length == 6) (0xFF000000L or value).toInt() else value.toInt()
        }.getOrNull()
    }

    private fun accessibleForeground(candidate: Int, background: Int, minimum: Double): Int {
        if (contrast(candidate, background) >= minimum) return candidate
        val black = 0xFF000000.toInt()
        val white = 0xFFFFFFFF.toInt()
        return if (contrast(black, background) >= contrast(white, background)) black else white
    }

    private fun luminance(color: Int): Double {
        fun channel(shift: Int): Double {
            val value = ((color shr shift) and 0xFF) / 255.0
            return if (value <= 0.03928) value / 12.92 else ((value + 0.055) / 1.055).pow(2.4)
        }
        return 0.2126 * channel(16) + 0.7152 * channel(8) + 0.0722 * channel(0)
    }
}
