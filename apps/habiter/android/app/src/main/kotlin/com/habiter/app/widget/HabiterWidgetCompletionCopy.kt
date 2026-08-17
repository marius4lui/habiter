package com.habiter.app.widget

internal object HabiterWidgetCompletionCopy {
    fun status(isGerman: Boolean): String = if (isGerman) "Erledigt" else "Completed"

    fun undoLabel(isGerman: Boolean, full: Boolean): String = when {
        !full -> "↶"
        isGerman -> "Rückgängig"
        else -> "Undo"
    }

    fun undoDescription(habitName: String, isGerman: Boolean): String =
        if (isGerman) "$habitName rückgängig machen" else "Undo $habitName"

    fun settledMessage(isGerman: Boolean): String =
        if (isGerman) "Alles für heute erledigt." else "Everything for today is done."
}
