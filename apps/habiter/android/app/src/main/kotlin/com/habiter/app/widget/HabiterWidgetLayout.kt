package com.habiter.app.widget

internal enum class HabiterWidgetLayout {
    COMPACT,
    COMPACT_SQUARE,
    WIDE,
    MEDIUM_HERO,
    LARGE,
    EXTRA_LARGE;

    companion object {
        fun forSize(widthDp: Int, heightDp: Int): HabiterWidgetLayout = when {
            widthDp >= 300 && heightDp >= 260 -> EXTRA_LARGE
            widthDp >= 230 && heightDp >= 190 -> LARGE
            widthDp >= 220 && heightDp >= 100 -> MEDIUM_HERO
            widthDp >= 220 -> WIDE
            heightDp >= 100 -> COMPACT_SQUARE
            else -> COMPACT
        }
    }
}
