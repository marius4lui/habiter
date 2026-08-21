package com.habiter.app.widget

import org.json.JSONArray
import org.json.JSONObject

internal enum class HabiterWidgetHabitFilter(val wireName: String) {
    ALL_TODAY("allToday"),
    OPEN_ONLY("openOnly"),
    SELECTED("selected"),
}

internal enum class HabiterWidgetSortMode(val wireName: String) {
    AS_IN_HABITER("asInHabiter"),
    OPEN_FIRST("openFirst"),
    CUSTOM("custom"),
}

internal enum class HabiterWidgetContentMode(val wireName: String) {
    AUTO("auto"),
    FOCUS("focus"),
    LIST("list"),
    MINIMAL("minimal"),
}

internal enum class HabiterWidgetThemeMode(val wireName: String) {
    SYSTEM("system"),
    LIGHT("light"),
    DARK("dark"),
    CUSTOM("custom"),
}

internal enum class HabiterWidgetProgressMode(val wireName: String) {
    AUTOMATIC("automatic"),
    HIDDEN("hidden"),
    SEGMENTS("segments"),
    COUNTER("counter"),
    BOTH("both"),
}

internal enum class HabiterWidgetElement(val wireName: String) {
    HABIT_ICON("habitIcon"),
    HABIT_NAME("habitName"),
    SCHEDULE_LABEL("scheduleLabel"),
    PROGRESS_SEGMENTS("progressSegments"),
    COUNTER("counter"),
    TODAY_HEADER("todayHeader"),
    COMPLETION_BUTTON("completionButton"),
    COMPLETED_HABITS("completedHabits"),
    COMPLETION_CHECKMARK("completionCheckmark"),
    UNDO_BUTTON("undoButton"),
    EMPTY_STATE_TEXT("emptyStateText"),
    DONE_STATE_TEXT("doneStateText"),
}

internal data class HabiterWidgetColorTokens(
    val surface: String? = null,
    val surfaceAccent: String? = null,
    val primary: String? = null,
    val text: String? = null,
    val mutedText: String? = null,
    val success: String? = null,
) {
    val isEmpty: Boolean
        get() = surface == null && surfaceAccent == null && primary == null &&
            text == null && mutedText == null && success == null

    fun toJson(): JSONObject = JSONObject().apply {
        surface?.let { put("surface", it) }
        surfaceAccent?.let { put("surfaceAccent", it) }
        primary?.let { put("primary", it) }
        text?.let { put("text", it) }
        mutedText?.let { put("mutedText", it) }
        success?.let { put("success", it) }
    }

    companion object {
        fun fromJson(source: JSONObject?): HabiterWidgetColorTokens {
            if (source == null) return HabiterWidgetColorTokens()
            return HabiterWidgetColorTokens(
                surface = source.validColor("surface"),
                surfaceAccent = source.validColor("surfaceAccent"),
                primary = source.validColor("primary"),
                text = source.validColor("text"),
                mutedText = source.validColor("mutedText"),
                success = source.validColor("success"),
            )
        }
    }
}

internal data class HabiterWidgetBreakpointOverride(
    val contentMode: HabiterWidgetContentMode? = null,
    val progressMode: HabiterWidgetProgressMode? = null,
    val maximumHabits: Int? = null,
    val outerPadding: Double? = null,
    val cornerRadius: Double? = null,
    val textScale: Double? = null,
    val hiddenElements: Set<HabiterWidgetElement> = emptySet(),
) {
    val isEmpty: Boolean
        get() = contentMode == null && progressMode == null && maximumHabits == null &&
            outerPadding == null && cornerRadius == null && textScale == null &&
            hiddenElements.isEmpty()

    fun toJson(): JSONObject = JSONObject().apply {
        contentMode?.let { put("contentMode", it.wireName) }
        progressMode?.let { put("progressMode", it.wireName) }
        maximumHabits?.let { put("maximumHabits", it) }
        outerPadding?.let { put("outerPadding", it) }
        cornerRadius?.let { put("cornerRadius", it) }
        textScale?.let { put("textScale", it) }
        if (hiddenElements.isNotEmpty()) {
            put("hiddenElements", JSONArray(hiddenElements.map { it.wireName }))
        }
    }

    companion object {
        fun fromJson(source: JSONObject): HabiterWidgetBreakpointOverride =
            HabiterWidgetBreakpointOverride(
                contentMode = source.enumOrNull<HabiterWidgetContentMode>("contentMode") {
                    it.wireName
                },
                progressMode = source.enumOrNull<HabiterWidgetProgressMode>("progressMode") {
                    it.wireName
                },
                maximumHabits = source.boundedInt("maximumHabits", 1, 12),
                outerPadding = source.boundedDouble("outerPadding", 0.0, 40.0),
                cornerRadius = source.boundedDouble("cornerRadius", 0.0, 40.0),
                textScale = source.boundedDouble("textScale", 0.8, 1.4),
                hiddenElements = source.enumSet<HabiterWidgetElement>("hiddenElements") {
                    it.wireName
                },
            )
    }
}

internal data class EffectiveHabiterWidgetConfiguration(
    val contentMode: HabiterWidgetContentMode,
    val progressMode: HabiterWidgetProgressMode,
    val maximumHabits: Int?,
    val outerPadding: Double?,
    val cornerRadius: Double?,
    val textScale: Double,
    val hiddenElements: Set<HabiterWidgetElement>,
) {
    fun shows(element: HabiterWidgetElement): Boolean = element !in hiddenElements
}

internal data class HabiterWidgetConfiguration(
    val schemaVersion: Int = CURRENT_SCHEMA_VERSION,
    val widgetId: Int,
    val displayName: String? = null,
    val habitFilter: HabiterWidgetHabitFilter = HabiterWidgetHabitFilter.ALL_TODAY,
    val selectedHabitIds: List<String> = emptyList(),
    val sortMode: HabiterWidgetSortMode = HabiterWidgetSortMode.AS_IN_HABITER,
    val customHabitOrder: List<String> = emptyList(),
    val contentMode: HabiterWidgetContentMode = HabiterWidgetContentMode.AUTO,
    val themeMode: HabiterWidgetThemeMode = HabiterWidgetThemeMode.SYSTEM,
    val showProgress: Boolean = true,
    val showCompleted: Boolean = true,
    val oneTapCompletion: Boolean = true,
    val progressMode: HabiterWidgetProgressMode = HabiterWidgetProgressMode.AUTOMATIC,
    val maximumHabits: Int? = null,
    val colorTokens: HabiterWidgetColorTokens = HabiterWidgetColorTokens(),
    val outerPadding: Double? = null,
    val cornerRadius: Double? = null,
    val textScale: Double = 1.0,
    val hiddenElements: Set<HabiterWidgetElement> = emptySet(),
    val breakpointOverrides: Map<HabiterWidgetLayout, HabiterWidgetBreakpointOverride> = emptyMap(),
) {
    fun effectiveFor(layout: HabiterWidgetLayout): EffectiveHabiterWidgetConfiguration {
        val override = breakpointOverrides[layout]
        return EffectiveHabiterWidgetConfiguration(
            contentMode = override?.contentMode ?: contentMode,
            progressMode = if (showProgress) {
                override?.progressMode ?: progressMode
            } else {
                HabiterWidgetProgressMode.HIDDEN
            },
            maximumHabits = override?.maximumHabits ?: maximumHabits,
            outerPadding = override?.outerPadding ?: outerPadding,
            cornerRadius = override?.cornerRadius ?: cornerRadius,
            textScale = override?.textScale ?: textScale,
            hiddenElements = buildSet {
                addAll(hiddenElements)
                addAll(override?.hiddenElements.orEmpty())
                if (!showCompleted) add(HabiterWidgetElement.COMPLETED_HABITS)
            },
        )
    }

    fun project(habits: List<HabiterWidgetHabit>): List<HabiterWidgetHabit> {
        val selected = habits.filter { habit ->
            if (!showCompleted && habit.completed) return@filter false
            when (habitFilter) {
                HabiterWidgetHabitFilter.ALL_TODAY -> true
                HabiterWidgetHabitFilter.OPEN_ONLY -> !habit.completed
                HabiterWidgetHabitFilter.SELECTED -> habit.id in selectedHabitIds
            }
        }
        return when (sortMode) {
            HabiterWidgetSortMode.AS_IN_HABITER -> selected
            HabiterWidgetSortMode.OPEN_FIRST -> selected.withIndex()
                .sortedWith(compareBy<IndexedValue<HabiterWidgetHabit>> { it.value.completed }.thenBy { it.index })
                .map { it.value }
            HabiterWidgetSortMode.CUSTOM -> {
                val order = customHabitOrder.withIndex().associate { it.value to it.index }
                selected.withIndex()
                    .sortedBy { order[it.value.id] ?: (order.size + it.index) }
                    .map { it.value }
            }
        }
    }

    fun toJson(): String = JSONObject().apply {
        put("schemaVersion", CURRENT_SCHEMA_VERSION)
        put("widgetId", widgetId)
        displayName?.let { put("displayName", it) }
        put("habitFilter", habitFilter.wireName)
        put("selectedHabitIds", JSONArray(selectedHabitIds))
        put("sortMode", sortMode.wireName)
        put("customHabitOrder", JSONArray(customHabitOrder))
        put("contentMode", contentMode.wireName)
        put("themeMode", themeMode.wireName)
        put("showProgress", showProgress)
        put("showCompleted", showCompleted)
        put("oneTapCompletion", oneTapCompletion)
        put("progressMode", progressMode.wireName)
        maximumHabits?.let { put("maximumHabits", it) }
        if (!colorTokens.isEmpty) put("colorTokens", colorTokens.toJson())
        outerPadding?.let { put("outerPadding", it) }
        cornerRadius?.let { put("cornerRadius", it) }
        put("textScale", textScale)
        put("hiddenElements", JSONArray(hiddenElements.map { it.wireName }))
        put(
            "breakpointOverrides",
            JSONObject().apply {
                breakpointOverrides.forEach { (layout, value) ->
                    if (!value.isEmpty) put(layout.wireName, value.toJson())
                }
            },
        )
    }.toString()

    companion object {
        const val CURRENT_SCHEMA_VERSION = 1

        fun defaults(widgetId: Int): HabiterWidgetConfiguration =
            HabiterWidgetConfiguration(widgetId = widgetId)

        fun parse(source: String, widgetId: Int): HabiterWidgetConfiguration {
            val root = JSONObject(source)
            val schemaVersion = root.optInt("schemaVersion", 0)
            require(schemaVersion in 0..CURRENT_SCHEMA_VERSION) { "Unsupported widget config schema." }
            if (root.has("widgetId")) {
                require(root.getInt("widgetId") == widgetId) { "Widget config id does not match." }
            }
            val overrides = buildMap {
                val sourceOverrides = root.optJSONObject("breakpointOverrides")
                if (sourceOverrides != null) {
                    HabiterWidgetLayout.entries.forEach { layout ->
                        sourceOverrides.optJSONObject(layout.wireName)?.let {
                            val override = HabiterWidgetBreakpointOverride.fromJson(it)
                            if (!override.isEmpty) put(layout, override)
                        }
                    }
                }
            }
            return HabiterWidgetConfiguration(
                widgetId = widgetId,
                displayName = root.optString("displayName").trim().take(48).ifEmpty { null },
                habitFilter = root.enumOr("habitFilter", HabiterWidgetHabitFilter.ALL_TODAY) {
                    it.wireName
                },
                selectedHabitIds = root.stringList("selectedHabitIds"),
                sortMode = root.enumOr("sortMode", HabiterWidgetSortMode.AS_IN_HABITER) {
                    it.wireName
                },
                customHabitOrder = root.stringList("customHabitOrder"),
                contentMode = root.enumOr("contentMode", HabiterWidgetContentMode.AUTO) {
                    it.wireName
                },
                themeMode = root.enumOr("themeMode", HabiterWidgetThemeMode.SYSTEM) {
                    it.wireName
                },
                showProgress = root.optBoolean("showProgress", true),
                showCompleted = root.optBoolean("showCompleted", true),
                oneTapCompletion = root.optBoolean("oneTapCompletion", true),
                progressMode = root.enumOr("progressMode", HabiterWidgetProgressMode.AUTOMATIC) {
                    it.wireName
                },
                maximumHabits = root.boundedInt("maximumHabits", 1, 12),
                colorTokens = HabiterWidgetColorTokens.fromJson(root.optJSONObject("colorTokens")),
                outerPadding = root.boundedDouble("outerPadding", 0.0, 40.0),
                cornerRadius = root.boundedDouble("cornerRadius", 0.0, 40.0),
                textScale = root.boundedDouble("textScale", 0.8, 1.4) ?: 1.0,
                hiddenElements = root.enumSet("hiddenElements") { it.wireName },
                breakpointOverrides = overrides,
            )
        }

        fun parseOrDefaults(source: String?, widgetId: Int): HabiterWidgetConfiguration =
            runCatching {
                if (source == null) defaults(widgetId) else parse(source, widgetId)
            }.getOrElse { defaults(widgetId) }
    }
}

internal val HabiterWidgetLayout.wireName: String
    get() = when (this) {
        HabiterWidgetLayout.COMPACT -> "compact"
        HabiterWidgetLayout.COMPACT_SQUARE -> "compactSquare"
        HabiterWidgetLayout.WIDE -> "wide"
        HabiterWidgetLayout.MEDIUM_HERO -> "mediumHero"
        HabiterWidgetLayout.LARGE -> "large"
        HabiterWidgetLayout.EXTRA_LARGE -> "extraLarge"
    }

private val widgetColorPattern = Regex("^#[0-9A-F]{6}([0-9A-F]{2})?$")

private fun JSONObject.validColor(key: String): String? =
    optString(key).trim().uppercase().takeIf { widgetColorPattern.matches(it) }

private fun JSONObject.stringList(key: String): List<String> {
    val source = optJSONArray(key) ?: return emptyList()
    return buildList {
        for (index in 0 until source.length()) {
            source.optString(index).takeIf { it.isNotEmpty() && it !in this }?.let(::add)
        }
    }
}

private fun JSONObject.boundedInt(key: String, minimum: Int, maximum: Int): Int? =
    if (!has(key) || isNull(key)) null else optInt(key).takeIf { it in minimum..maximum }

private fun JSONObject.boundedDouble(key: String, minimum: Double, maximum: Double): Double? =
    if (!has(key) || isNull(key)) {
        null
    } else {
        optDouble(key).takeIf { it.isFinite() && it in minimum..maximum }
    }

private inline fun <reified T : Enum<T>> JSONObject.enumOr(
    key: String,
    fallback: T,
    wireName: (T) -> String,
): T = enumOrNull(key, wireName) ?: fallback

private inline fun <reified T : Enum<T>> JSONObject.enumOrNull(
    key: String,
    wireName: (T) -> String,
): T? {
    val source = optString(key)
    return enumValues<T>().firstOrNull { wireName(it) == source }
}

private inline fun <reified T : Enum<T>> JSONObject.enumSet(
    key: String,
    wireName: (T) -> String,
): Set<T> {
    val source = optJSONArray(key) ?: return emptySet()
    return buildSet {
        for (index in 0 until source.length()) {
            val value = source.optString(index)
            enumValues<T>().firstOrNull { wireName(it) == value }?.let(::add)
        }
    }
}
