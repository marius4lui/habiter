package com.habiter.app.widget

internal enum class HabiterWidgetCompletionArrangement {
    INLINE,
    STACKED,
    ICON_ONLY,
}

internal data class HabiterWidgetCompletionLayout(
    val transientArrangement: HabiterWidgetCompletionArrangement,
    val settledArrangement: HabiterWidgetCompletionArrangement,
    val horizontalPaddingDp: Int,
    val verticalPaddingDp: Int,
    val transientIconSizeSp: Int,
    val settledIconSizeSp: Int,
    val titleSizeSp: Int,
    val statusSizeSp: Int,
    val showTransientStatus: Boolean,
    val showFullUndoLabel: Boolean,
    val settledMessageSizeSp: Int,
    val settledMessageMaxLines: Int,
) {
    companion object {
        fun forLayout(layout: HabiterWidgetLayout): HabiterWidgetCompletionLayout =
            when (layout) {
                HabiterWidgetLayout.COMPACT -> HabiterWidgetCompletionLayout(
                    transientArrangement = HabiterWidgetCompletionArrangement.INLINE,
                    settledArrangement = HabiterWidgetCompletionArrangement.ICON_ONLY,
                    horizontalPaddingDp = 10,
                    verticalPaddingDp = 8,
                    transientIconSizeSp = 22,
                    settledIconSizeSp = 22,
                    titleSizeSp = 14,
                    statusSizeSp = 12,
                    showTransientStatus = false,
                    showFullUndoLabel = false,
                    settledMessageSizeSp = 13,
                    settledMessageMaxLines = 1,
                )

                HabiterWidgetLayout.COMPACT_SQUARE -> HabiterWidgetCompletionLayout(
                    transientArrangement = HabiterWidgetCompletionArrangement.STACKED,
                    settledArrangement = HabiterWidgetCompletionArrangement.STACKED,
                    horizontalPaddingDp = 10,
                    verticalPaddingDp = 8,
                    transientIconSizeSp = 22,
                    settledIconSizeSp = 26,
                    titleSizeSp = 14,
                    statusSizeSp = 12,
                    showTransientStatus = true,
                    showFullUndoLabel = true,
                    settledMessageSizeSp = 14,
                    settledMessageMaxLines = 2,
                )

                HabiterWidgetLayout.WIDE -> HabiterWidgetCompletionLayout(
                    transientArrangement = HabiterWidgetCompletionArrangement.INLINE,
                    settledArrangement = HabiterWidgetCompletionArrangement.INLINE,
                    horizontalPaddingDp = 14,
                    verticalPaddingDp = 8,
                    transientIconSizeSp = 22,
                    settledIconSizeSp = 24,
                    titleSizeSp = 15,
                    statusSizeSp = 12,
                    showTransientStatus = false,
                    showFullUndoLabel = true,
                    settledMessageSizeSp = 14,
                    settledMessageMaxLines = 1,
                )

                HabiterWidgetLayout.MEDIUM_HERO,
                HabiterWidgetLayout.LARGE,
                HabiterWidgetLayout.EXTRA_LARGE,
                -> HabiterWidgetCompletionLayout(
                    transientArrangement = HabiterWidgetCompletionArrangement.INLINE,
                    settledArrangement = HabiterWidgetCompletionArrangement.STACKED,
                    horizontalPaddingDp = 20,
                    verticalPaddingDp = 16,
                    transientIconSizeSp = 24,
                    settledIconSizeSp = 38,
                    titleSizeSp = 16,
                    statusSizeSp = 13,
                    showTransientStatus = true,
                    showFullUndoLabel = true,
                    settledMessageSizeSp = 17,
                    settledMessageMaxLines = 2,
                )
            }
    }
}
