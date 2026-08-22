package com.habiter.app.widget

import org.json.JSONArray
import org.json.JSONObject

internal enum class HabiterWidgetPreset(val wireName: String) {
    DEFAULTS("defaults"), MINIMAL("minimal"), FOCUS("focus"),
    DENSE_LIST("denseList"), DASHBOARD("dashboard"),
}

internal enum class HabiterWidgetAccentMode(val wireName: String) {
    HABITER("habiter"), DYNAMIC_COLOR("dynamicColor"), CUSTOM("custom"),
}

internal enum class HabiterWidgetDensity(val wireName: String) {
    COMPACT("compact"), COMFORTABLE("comfortable"),
}

internal enum class HabiterWidgetBackgroundAction(val wireName: String) {
    TODAY("today"), NEXT_HABIT("nextHabit"), APP("app"),
}

internal enum class HabiterWidgetHabitRowAction(val wireName: String) {
    OPEN_HABIT("openHabit"), COMPLETE("complete"), NONE("none"),
}

internal enum class HabiterWidgetCompletionAction(val wireName: String) {
    COMPLETE("complete"), OPEN_HABIT("openHabit"),
}

internal enum class HabiterWidgetCompletionButtonStyle(val wireName: String) {
    AUTOMATIC("automatic"), CHECK_ONLY("checkOnly"), TEXT_ONLY("textOnly"),
    CHECK_AND_TEXT("checkAndText"), WHOLE_ROW("wholeRow"),
}

internal enum class HabiterWidgetCompletionFeedback(val wireName: String) {
    MINIMAL("minimal"), NORMAL("normal"), DETAILED("detailed"),
}

internal enum class HabiterWidgetOverflowBehavior(val wireName: String) {
    TRUNCATE("truncate"), OPEN_ONLY("openOnly"), SWITCH_TO_FOCUS("switchToFocus"),
}

internal enum class HabiterWidgetCompletedPlacement(val wireName: String) {
    AS_IN_HABITER("asInHabiter"), END("end"),
}

internal enum class HabiterWidgetProgressCompletedStyle(val wireName: String) {
    SOLID("solid"), MUTED("muted"), HIDDEN("hidden"),
}

internal enum class HabiterWidgetProgressRemainingStyle(val wireName: String) {
    TRACK("track"), OUTLINE("outline"), HIDDEN("hidden"),
}

internal enum class HabiterWidgetFontWeight(val wireName: String) {
    SYSTEM("system"), REGULAR("regular"), MEDIUM("medium"), BOLD("bold"),
}

internal enum class HabiterWidgetJustCompletedStyle(val wireName: String) {
    FULL("full"), COMPACT("compact"), CHECK_ONLY("checkOnly"), NEXT_HABIT("nextHabit"),
}

internal enum class HabiterWidgetAllCompleteStyle(val wireName: String) {
    CARD("card"), MESSAGE("message"), MINIMAL("minimal"), ICON_ONLY("iconOnly"),
}

internal enum class HabiterWidgetFreeTodayStyle(val wireName: String) {
    TEXT_AND_ICON("textAndIcon"), TEXT_ONLY("textOnly"), ICON_ONLY("iconOnly"), MINIMAL("minimal"),
}

internal enum class HabiterWidgetNoHabitsStyle(val wireName: String) {
    DEFAULT_STATE("defaultState"), COMPACT("compact"),
}

internal enum class HabiterWidgetMissingStaleStyle(val wireName: String) {
    SYNC_MESSAGE("syncMessage"), COMPACT("compact"),
}

internal data class HabiterWidgetListSettings(
    val completedPlacement: HabiterWidgetCompletedPlacement = HabiterWidgetCompletedPlacement.AS_IN_HABITER,
    val pinnedHabitIds: List<String> = emptyList(),
    val overflowBehavior: HabiterWidgetOverflowBehavior = HabiterWidgetOverflowBehavior.TRUNCATE,
) {
    fun toJson(): JSONObject = JSONObject().apply {
        put("completedPlacement", completedPlacement.wireName)
        put("pinnedHabitIds", JSONArray(pinnedHabitIds))
        put("overflowBehavior", overflowBehavior.wireName)
    }

    companion object {
        fun fromJson(source: JSONObject): HabiterWidgetListSettings = HabiterWidgetListSettings(
            completedPlacement = source.optionEnum(
                "completedPlacement",
                HabiterWidgetCompletedPlacement.AS_IN_HABITER,
            ) { it.wireName },
            pinnedHabitIds = source.optionStringList("pinnedHabitIds"),
            overflowBehavior = source.optionEnum(
                "overflowBehavior",
                HabiterWidgetOverflowBehavior.TRUNCATE,
            ) { it.wireName },
        )
    }
}

internal data class HabiterWidgetProgressSettings(
    val segmentHeight: Double? = null,
    val segmentGap: Double? = null,
    val maximumSegments: Int? = null,
    val completedStyle: HabiterWidgetProgressCompletedStyle = HabiterWidgetProgressCompletedStyle.SOLID,
    val remainingStyle: HabiterWidgetProgressRemainingStyle = HabiterWidgetProgressRemainingStyle.TRACK,
) {
    fun toJson(): JSONObject = JSONObject().apply {
        segmentHeight?.let { put("segmentHeight", it) }
        segmentGap?.let { put("segmentGap", it) }
        maximumSegments?.let { put("maximumSegments", it) }
        put("completedStyle", completedStyle.wireName)
        put("remainingStyle", remainingStyle.wireName)
    }

    companion object {
        fun fromJson(source: JSONObject): HabiterWidgetProgressSettings = HabiterWidgetProgressSettings(
            segmentHeight = source.optionDouble("segmentHeight", 2.0, 12.0),
            segmentGap = source.optionDouble("segmentGap", 0.0, 12.0),
            maximumSegments = source.optionInt("maximumSegments", 1, 24),
            completedStyle = source.optionEnum(
                "completedStyle",
                HabiterWidgetProgressCompletedStyle.SOLID,
            ) { it.wireName },
            remainingStyle = source.optionEnum(
                "remainingStyle",
                HabiterWidgetProgressRemainingStyle.TRACK,
            ) { it.wireName },
        )
    }
}

internal data class HabiterWidgetCompletionSettings(
    val buttonStyle: HabiterWidgetCompletionButtonStyle = HabiterWidgetCompletionButtonStyle.AUTOMATIC,
    val showUndo: Boolean = true,
    val feedback: HabiterWidgetCompletionFeedback = HabiterWidgetCompletionFeedback.NORMAL,
    val focusNextHabit: Boolean = false,
) {
    fun toJson(): JSONObject = JSONObject().apply {
        put("buttonStyle", buttonStyle.wireName)
        put("showUndo", showUndo)
        put("feedback", feedback.wireName)
        put("focusNextHabit", focusNextHabit)
    }

    companion object {
        fun fromJson(source: JSONObject): HabiterWidgetCompletionSettings =
            HabiterWidgetCompletionSettings(
                buttonStyle = source.optionEnum(
                    "buttonStyle",
                    HabiterWidgetCompletionButtonStyle.AUTOMATIC,
                ) { it.wireName },
                showUndo = source.optBoolean("showUndo", true),
                feedback = source.optionEnum(
                    "feedback",
                    HabiterWidgetCompletionFeedback.NORMAL,
                ) { it.wireName },
                focusNextHabit = source.optBoolean("focusNextHabit", false),
            )
    }
}

internal data class HabiterWidgetGeometry(
    val habitRowRadius: Double? = null,
    val buttonRadius: Double? = null,
    val horizontalPadding: Double? = null,
    val verticalPadding: Double? = null,
    val rowGap: Double? = null,
    val sectionGap: Double? = null,
) {
    fun merge(override: HabiterWidgetGeometry?): HabiterWidgetGeometry = HabiterWidgetGeometry(
        habitRowRadius = override?.habitRowRadius ?: habitRowRadius,
        buttonRadius = override?.buttonRadius ?: buttonRadius,
        horizontalPadding = override?.horizontalPadding ?: horizontalPadding,
        verticalPadding = override?.verticalPadding ?: verticalPadding,
        rowGap = override?.rowGap ?: rowGap,
        sectionGap = override?.sectionGap ?: sectionGap,
    )

    fun toJson(): JSONObject = JSONObject().apply {
        habitRowRadius?.let { put("habitRowRadius", it) }
        buttonRadius?.let { put("buttonRadius", it) }
        horizontalPadding?.let { put("horizontalPadding", it) }
        verticalPadding?.let { put("verticalPadding", it) }
        rowGap?.let { put("rowGap", it) }
        sectionGap?.let { put("sectionGap", it) }
    }

    companion object {
        fun fromJson(source: JSONObject): HabiterWidgetGeometry = HabiterWidgetGeometry(
            habitRowRadius = source.optionDouble("habitRowRadius", 0.0, 40.0),
            buttonRadius = source.optionDouble("buttonRadius", 0.0, 40.0),
            horizontalPadding = source.optionDouble("horizontalPadding", 0.0, 40.0),
            verticalPadding = source.optionDouble("verticalPadding", 0.0, 40.0),
            rowGap = source.optionDouble("rowGap", 0.0, 24.0),
            sectionGap = source.optionDouble("sectionGap", 0.0, 32.0),
        )
    }
}

internal data class HabiterWidgetTypography(
    val habitTitleSize: Double? = null,
    val secondaryTextSize: Double? = null,
    val counterSize: Double? = null,
    val fontWeight: HabiterWidgetFontWeight = HabiterWidgetFontWeight.SYSTEM,
) {
    fun merge(override: HabiterWidgetTypography?): HabiterWidgetTypography = HabiterWidgetTypography(
        habitTitleSize = override?.habitTitleSize ?: habitTitleSize,
        secondaryTextSize = override?.secondaryTextSize ?: secondaryTextSize,
        counterSize = override?.counterSize ?: counterSize,
        fontWeight = override?.fontWeight ?: fontWeight,
    )

    fun toJson(): JSONObject = JSONObject().apply {
        habitTitleSize?.let { put("habitTitleSize", it) }
        secondaryTextSize?.let { put("secondaryTextSize", it) }
        counterSize?.let { put("counterSize", it) }
        put("fontWeight", fontWeight.wireName)
    }

    companion object {
        fun fromJson(source: JSONObject): HabiterWidgetTypography = HabiterWidgetTypography(
            habitTitleSize = source.optionDouble("habitTitleSize", 10.0, 28.0),
            secondaryTextSize = source.optionDouble("secondaryTextSize", 9.0, 22.0),
            counterSize = source.optionDouble("counterSize", 9.0, 24.0),
            fontWeight = source.optionEnum("fontWeight", HabiterWidgetFontWeight.SYSTEM) {
                it.wireName
            },
        )
    }
}

internal data class HabiterWidgetStateStyles(
    val justCompleted: HabiterWidgetJustCompletedStyle = HabiterWidgetJustCompletedStyle.FULL,
    val allComplete: HabiterWidgetAllCompleteStyle = HabiterWidgetAllCompleteStyle.CARD,
    val freeToday: HabiterWidgetFreeTodayStyle = HabiterWidgetFreeTodayStyle.TEXT_AND_ICON,
    val noHabits: HabiterWidgetNoHabitsStyle = HabiterWidgetNoHabitsStyle.DEFAULT_STATE,
    val missingStale: HabiterWidgetMissingStaleStyle = HabiterWidgetMissingStaleStyle.SYNC_MESSAGE,
) {
    fun toJson(): JSONObject = JSONObject().apply {
        put("justCompleted", justCompleted.wireName)
        put("allComplete", allComplete.wireName)
        put("freeToday", freeToday.wireName)
        put("noHabits", noHabits.wireName)
        put("missingStale", missingStale.wireName)
    }

    companion object {
        fun fromJson(source: JSONObject): HabiterWidgetStateStyles = HabiterWidgetStateStyles(
            justCompleted = source.optionEnum(
                "justCompleted",
                HabiterWidgetJustCompletedStyle.FULL,
            ) { it.wireName },
            allComplete = source.optionEnum(
                "allComplete",
                HabiterWidgetAllCompleteStyle.CARD,
            ) { it.wireName },
            freeToday = source.optionEnum(
                "freeToday",
                HabiterWidgetFreeTodayStyle.TEXT_AND_ICON,
            ) { it.wireName },
            noHabits = source.optionEnum(
                "noHabits",
                HabiterWidgetNoHabitsStyle.DEFAULT_STATE,
            ) { it.wireName },
            missingStale = source.optionEnum(
                "missingStale",
                HabiterWidgetMissingStaleStyle.SYNC_MESSAGE,
            ) { it.wireName },
        )
    }
}

internal data class HabiterWidgetInteractionMap(
    val background: HabiterWidgetBackgroundAction = HabiterWidgetBackgroundAction.TODAY,
    val habitRow: HabiterWidgetHabitRowAction = HabiterWidgetHabitRowAction.NONE,
    val completionControl: HabiterWidgetCompletionAction = HabiterWidgetCompletionAction.COMPLETE,
) {
    fun toJson(): JSONObject = JSONObject().apply {
        put("background", background.wireName)
        put("habitRow", habitRow.wireName)
        put("completionControl", completionControl.wireName)
    }

    companion object {
        fun fromJson(source: JSONObject): HabiterWidgetInteractionMap = HabiterWidgetInteractionMap(
            background = source.optionEnum(
                "background",
                HabiterWidgetBackgroundAction.TODAY,
            ) { it.wireName },
            habitRow = source.optionEnum(
                "habitRow",
                HabiterWidgetHabitRowAction.NONE,
            ) { it.wireName },
            completionControl = source.optionEnum(
                "completionControl",
                HabiterWidgetCompletionAction.COMPLETE,
            ) { it.wireName },
        )
    }
}

private fun JSONObject.optionStringList(key: String): List<String> {
    val source = optJSONArray(key) ?: return emptyList()
    return buildList {
        for (index in 0 until source.length()) {
            source.optString(index).takeIf { it.isNotEmpty() && it !in this }?.let(::add)
        }
    }
}

private fun JSONObject.optionInt(key: String, minimum: Int, maximum: Int): Int? =
    if (!has(key) || isNull(key)) null else optInt(key).takeIf { it in minimum..maximum }

private fun JSONObject.optionDouble(key: String, minimum: Double, maximum: Double): Double? =
    if (!has(key) || isNull(key)) null else optDouble(key).takeIf { it.isFinite() && it in minimum..maximum }

private inline fun <reified T : Enum<T>> JSONObject.optionEnum(
    key: String,
    fallback: T,
    wireName: (T) -> String,
): T {
    val source = optString(key)
    return enumValues<T>().firstOrNull { wireName(it) == source } ?: fallback
}
