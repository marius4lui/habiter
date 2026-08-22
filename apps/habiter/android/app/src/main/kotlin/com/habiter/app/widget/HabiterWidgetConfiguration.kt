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
    val themeMode: HabiterWidgetThemeMode? = null,
    val accentMode: HabiterWidgetAccentMode? = null,
    val density: HabiterWidgetDensity? = null,
    val progressMode: HabiterWidgetProgressMode? = null,
    val maximumHabits: Int? = null,
    val outerPadding: Double? = null,
    val cornerRadius: Double? = null,
    val textScale: Double? = null,
    val colorTokens: HabiterWidgetColorTokens? = null,
    val surfaceTransparency: Double? = null,
    val listSettings: HabiterWidgetListSettings? = null,
    val progressSettings: HabiterWidgetProgressSettings? = null,
    val completionSettings: HabiterWidgetCompletionSettings? = null,
    val geometry: HabiterWidgetGeometry? = null,
    val typography: HabiterWidgetTypography? = null,
    val stateStyles: HabiterWidgetStateStyles? = null,
    val interactions: HabiterWidgetInteractionMap? = null,
    val hiddenElements: Set<HabiterWidgetElement> = emptySet(),
) {
    val isEmpty: Boolean
        get() = contentMode == null && themeMode == null && accentMode == null && density == null &&
            progressMode == null && maximumHabits == null &&
            outerPadding == null && cornerRadius == null && textScale == null &&
            colorTokens == null && surfaceTransparency == null && listSettings == null &&
            progressSettings == null && completionSettings == null && geometry == null &&
            typography == null && stateStyles == null && interactions == null &&
            hiddenElements.isEmpty()

    fun toJson(): JSONObject = JSONObject().apply {
        contentMode?.let { put("contentMode", it.wireName) }
        themeMode?.let { put("themeMode", it.wireName) }
        accentMode?.let { put("accentMode", it.wireName) }
        density?.let { put("density", it.wireName) }
        progressMode?.let { put("progressMode", it.wireName) }
        maximumHabits?.let { put("maximumHabits", it) }
        outerPadding?.let { put("outerPadding", it) }
        cornerRadius?.let { put("cornerRadius", it) }
        textScale?.let { put("textScale", it) }
        colorTokens?.takeUnless { it.isEmpty }?.let { put("colorTokens", it.toJson()) }
        surfaceTransparency?.let { put("surfaceTransparency", it) }
        listSettings?.let { put("listSettings", it.toJson()) }
        progressSettings?.let { put("progressSettings", it.toJson()) }
        completionSettings?.let { put("completionSettings", it.toJson()) }
        geometry?.let { put("geometry", it.toJson()) }
        typography?.let { put("typography", it.toJson()) }
        stateStyles?.let { put("stateStyles", it.toJson()) }
        interactions?.let { put("interactions", it.toJson()) }
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
                themeMode = source.enumOrNull<HabiterWidgetThemeMode>("themeMode") { it.wireName },
                accentMode = source.enumOrNull<HabiterWidgetAccentMode>("accentMode") { it.wireName },
                density = source.enumOrNull<HabiterWidgetDensity>("density") { it.wireName },
                progressMode = source.enumOrNull<HabiterWidgetProgressMode>("progressMode") {
                    it.wireName
                },
                maximumHabits = source.boundedInt("maximumHabits", 1, 12),
                outerPadding = source.boundedDouble("outerPadding", 0.0, 40.0),
                cornerRadius = source.boundedDouble("cornerRadius", 0.0, 40.0),
                textScale = source.boundedDouble("textScale", 0.8, 1.4),
                colorTokens = source.optJSONObject("colorTokens")?.let(HabiterWidgetColorTokens::fromJson),
                surfaceTransparency = source.boundedDouble("surfaceTransparency", 0.0, 0.4),
                listSettings = source.optJSONObject("listSettings")?.let(HabiterWidgetListSettings::fromJson),
                progressSettings = source.optJSONObject("progressSettings")?.let(HabiterWidgetProgressSettings::fromJson),
                completionSettings = source.optJSONObject("completionSettings")?.let(HabiterWidgetCompletionSettings::fromJson),
                geometry = source.optJSONObject("geometry")?.let(HabiterWidgetGeometry::fromJson),
                typography = source.optJSONObject("typography")?.let(HabiterWidgetTypography::fromJson),
                stateStyles = source.optJSONObject("stateStyles")?.let(HabiterWidgetStateStyles::fromJson),
                interactions = source.optJSONObject("interactions")?.let(HabiterWidgetInteractionMap::fromJson),
                hiddenElements = source.enumSet<HabiterWidgetElement>("hiddenElements") {
                    it.wireName
                },
            )
    }
}

internal data class EffectiveHabiterWidgetConfiguration(
    val contentMode: HabiterWidgetContentMode,
    val themeMode: HabiterWidgetThemeMode,
    val accentMode: HabiterWidgetAccentMode,
    val density: HabiterWidgetDensity,
    val progressMode: HabiterWidgetProgressMode,
    val maximumHabits: Int?,
    val outerPadding: Double?,
    val cornerRadius: Double?,
    val textScale: Double,
    val colorTokens: HabiterWidgetColorTokens,
    val surfaceTransparency: Double,
    val listSettings: HabiterWidgetListSettings,
    val progressSettings: HabiterWidgetProgressSettings,
    val completionSettings: HabiterWidgetCompletionSettings,
    val geometry: HabiterWidgetGeometry,
    val typography: HabiterWidgetTypography,
    val stateStyles: HabiterWidgetStateStyles,
    val interactions: HabiterWidgetInteractionMap,
    val hiddenElements: Set<HabiterWidgetElement>,
) {
    fun shows(element: HabiterWidgetElement): Boolean = element !in hiddenElements
}

internal data class HabiterWidgetConfiguration(
    val schemaVersion: Int = CURRENT_SCHEMA_VERSION,
    val widgetId: Int,
    val displayName: String? = null,
    val preset: HabiterWidgetPreset = HabiterWidgetPreset.DEFAULTS,
    val habitFilter: HabiterWidgetHabitFilter = HabiterWidgetHabitFilter.ALL_TODAY,
    val selectedHabitIds: List<String> = emptyList(),
    val sortMode: HabiterWidgetSortMode = HabiterWidgetSortMode.AS_IN_HABITER,
    val customHabitOrder: List<String> = emptyList(),
    val contentMode: HabiterWidgetContentMode = HabiterWidgetContentMode.AUTO,
    val themeMode: HabiterWidgetThemeMode = HabiterWidgetThemeMode.SYSTEM,
    val accentMode: HabiterWidgetAccentMode = HabiterWidgetAccentMode.HABITER,
    val density: HabiterWidgetDensity = HabiterWidgetDensity.COMFORTABLE,
    val showProgress: Boolean = true,
    val showCompleted: Boolean = true,
    val oneTapCompletion: Boolean = true,
    val progressMode: HabiterWidgetProgressMode = HabiterWidgetProgressMode.AUTOMATIC,
    val maximumHabits: Int? = null,
    val colorTokens: HabiterWidgetColorTokens = HabiterWidgetColorTokens(),
    val surfaceTransparency: Double = 0.0,
    val listSettings: HabiterWidgetListSettings = HabiterWidgetListSettings(),
    val progressSettings: HabiterWidgetProgressSettings = HabiterWidgetProgressSettings(),
    val completionSettings: HabiterWidgetCompletionSettings = HabiterWidgetCompletionSettings(),
    val outerPadding: Double? = null,
    val cornerRadius: Double? = null,
    val textScale: Double = 1.0,
    val geometry: HabiterWidgetGeometry = HabiterWidgetGeometry(),
    val typography: HabiterWidgetTypography = HabiterWidgetTypography(),
    val stateStyles: HabiterWidgetStateStyles = HabiterWidgetStateStyles(),
    val interactions: HabiterWidgetInteractionMap = HabiterWidgetInteractionMap(),
    val hiddenElements: Set<HabiterWidgetElement> = emptySet(),
    val breakpointOverrides: Map<HabiterWidgetLayout, HabiterWidgetBreakpointOverride> = emptyMap(),
) {
    fun effectiveFor(layout: HabiterWidgetLayout): EffectiveHabiterWidgetConfiguration {
        val override = breakpointOverrides[layout]
        val effectiveInteractions = override?.interactions ?: interactions
        return EffectiveHabiterWidgetConfiguration(
            contentMode = override?.contentMode ?: contentMode,
            themeMode = override?.themeMode ?: themeMode,
            accentMode = override?.accentMode ?: accentMode,
            density = override?.density ?: density,
            progressMode = if (showProgress) {
                override?.progressMode ?: progressMode
            } else {
                HabiterWidgetProgressMode.HIDDEN
            },
            maximumHabits = override?.maximumHabits ?: maximumHabits,
            outerPadding = override?.outerPadding ?: outerPadding,
            cornerRadius = override?.cornerRadius ?: cornerRadius,
            textScale = override?.textScale ?: textScale,
            colorTokens = override?.colorTokens ?: colorTokens,
            surfaceTransparency = override?.surfaceTransparency ?: surfaceTransparency,
            listSettings = override?.listSettings ?: listSettings,
            progressSettings = override?.progressSettings ?: progressSettings,
            completionSettings = override?.completionSettings ?: completionSettings,
            geometry = geometry.merge(override?.geometry),
            typography = typography.merge(override?.typography),
            stateStyles = override?.stateStyles ?: stateStyles,
            interactions = if (oneTapCompletion) {
                effectiveInteractions
            } else {
                effectiveInteractions.copy(
                    completionControl = HabiterWidgetCompletionAction.OPEN_HABIT,
                )
            },
            hiddenElements = buildSet {
                addAll(hiddenElements)
                addAll(override?.hiddenElements.orEmpty())
                if (!showCompleted) add(HabiterWidgetElement.COMPLETED_HABITS)
            },
        )
    }

    fun project(habits: List<HabiterWidgetHabit>): List<HabiterWidgetHabit> {
        val selected = select(habits)
        return if (showCompleted) selected else selected.filterNot { it.completed }
    }

    fun select(habits: List<HabiterWidgetHabit>): List<HabiterWidgetHabit> {
        val selected = habits.filter { habit ->
            when (habitFilter) {
                HabiterWidgetHabitFilter.ALL_TODAY -> true
                HabiterWidgetHabitFilter.OPEN_ONLY -> !habit.completed
                HabiterWidgetHabitFilter.SELECTED -> habit.id in selectedHabitIds
            }
        }
        var ordered = when (sortMode) {
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
        val pinned = listSettings.pinnedHabitIds.toSet()
        if (pinned.isNotEmpty()) {
            ordered = ordered.filter { it.id in pinned } + ordered.filterNot { it.id in pinned }
        }
        if (listSettings.completedPlacement == HabiterWidgetCompletedPlacement.END) {
            ordered = ordered.filterNot { it.completed } + ordered.filter { it.completed }
        }
        return ordered
    }

    fun toJson(): String = JSONObject().apply {
        put("schemaVersion", CURRENT_SCHEMA_VERSION)
        put("widgetId", widgetId)
        displayName?.let { put("displayName", it) }
        put("preset", preset.wireName)
        put("habitFilter", habitFilter.wireName)
        put("selectedHabitIds", JSONArray(selectedHabitIds))
        put("sortMode", sortMode.wireName)
        put("customHabitOrder", JSONArray(customHabitOrder))
        put("contentMode", contentMode.wireName)
        put("themeMode", themeMode.wireName)
        put("accentMode", accentMode.wireName)
        put("density", density.wireName)
        put("showProgress", showProgress)
        put("showCompleted", showCompleted)
        put("oneTapCompletion", oneTapCompletion)
        put("progressMode", progressMode.wireName)
        maximumHabits?.let { put("maximumHabits", it) }
        if (!colorTokens.isEmpty) put("colorTokens", colorTokens.toJson())
        put("surfaceTransparency", surfaceTransparency)
        put("listSettings", listSettings.toJson())
        put("progressSettings", progressSettings.toJson())
        put("completionSettings", completionSettings.toJson())
        outerPadding?.let { put("outerPadding", it) }
        cornerRadius?.let { put("cornerRadius", it) }
        put("textScale", textScale)
        put("geometry", geometry.toJson())
        put("typography", typography.toJson())
        put("stateStyles", stateStyles.toJson())
        put("interactions", interactions.toJson())
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

        fun forPreset(
            widgetId: Int,
            preset: HabiterWidgetPreset,
            displayName: String? = null,
        ): HabiterWidgetConfiguration = when (preset) {
            HabiterWidgetPreset.DEFAULTS -> HabiterWidgetConfiguration(
                widgetId = widgetId,
                displayName = displayName,
            )
            HabiterWidgetPreset.MINIMAL -> HabiterWidgetConfiguration(
                widgetId = widgetId,
                displayName = displayName,
                preset = preset,
                contentMode = HabiterWidgetContentMode.MINIMAL,
                showProgress = false,
                showCompleted = false,
                density = HabiterWidgetDensity.COMPACT,
                maximumHabits = 1,
                hiddenElements = setOf(
                    HabiterWidgetElement.SCHEDULE_LABEL,
                    HabiterWidgetElement.TODAY_HEADER,
                    HabiterWidgetElement.COUNTER,
                ),
            )
            HabiterWidgetPreset.FOCUS -> HabiterWidgetConfiguration(
                widgetId = widgetId,
                displayName = displayName,
                preset = preset,
                contentMode = HabiterWidgetContentMode.FOCUS,
                showCompleted = false,
                maximumHabits = 1,
            )
            HabiterWidgetPreset.DENSE_LIST -> HabiterWidgetConfiguration(
                widgetId = widgetId,
                displayName = displayName,
                preset = preset,
                contentMode = HabiterWidgetContentMode.LIST,
                sortMode = HabiterWidgetSortMode.OPEN_FIRST,
                density = HabiterWidgetDensity.COMPACT,
                maximumHabits = 8,
                completionSettings = HabiterWidgetCompletionSettings(
                    buttonStyle = HabiterWidgetCompletionButtonStyle.CHECK_ONLY,
                ),
            )
            HabiterWidgetPreset.DASHBOARD -> HabiterWidgetConfiguration(
                widgetId = widgetId,
                displayName = displayName,
                preset = preset,
                contentMode = HabiterWidgetContentMode.LIST,
                progressMode = HabiterWidgetProgressMode.BOTH,
                maximumHabits = 6,
            )
        }

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
            val preset = root.enumOr("preset", HabiterWidgetPreset.DEFAULTS) { it.wireName }
            val baseline = forPreset(widgetId, preset)
            return HabiterWidgetConfiguration(
                widgetId = widgetId,
                displayName = root.optString("displayName").trim().take(48).ifEmpty { null },
                preset = preset,
                habitFilter = root.enumOr("habitFilter", baseline.habitFilter) {
                    it.wireName
                },
                selectedHabitIds = root.stringList("selectedHabitIds"),
                sortMode = root.enumOr("sortMode", baseline.sortMode) {
                    it.wireName
                },
                customHabitOrder = root.stringList("customHabitOrder"),
                contentMode = root.enumOr("contentMode", baseline.contentMode) {
                    it.wireName
                },
                themeMode = root.enumOr("themeMode", baseline.themeMode) {
                    it.wireName
                },
                accentMode = root.enumOr("accentMode", baseline.accentMode) { it.wireName },
                density = root.enumOr("density", baseline.density) { it.wireName },
                showProgress = root.optBoolean("showProgress", baseline.showProgress),
                showCompleted = root.optBoolean("showCompleted", baseline.showCompleted),
                oneTapCompletion = root.optBoolean("oneTapCompletion", baseline.oneTapCompletion),
                progressMode = root.enumOr("progressMode", baseline.progressMode) {
                    it.wireName
                },
                maximumHabits = root.boundedInt("maximumHabits", 1, 12) ?: baseline.maximumHabits,
                colorTokens = root.optJSONObject("colorTokens")?.let(
                    HabiterWidgetColorTokens::fromJson,
                ) ?: baseline.colorTokens,
                surfaceTransparency = root.boundedDouble("surfaceTransparency", 0.0, 0.4)
                    ?: baseline.surfaceTransparency,
                listSettings = root.optJSONObject("listSettings")?.let(
                    HabiterWidgetListSettings::fromJson,
                ) ?: baseline.listSettings,
                progressSettings = root.optJSONObject("progressSettings")?.let(
                    HabiterWidgetProgressSettings::fromJson,
                ) ?: baseline.progressSettings,
                completionSettings = root.optJSONObject("completionSettings")?.let(
                    HabiterWidgetCompletionSettings::fromJson,
                ) ?: baseline.completionSettings,
                outerPadding = root.boundedDouble("outerPadding", 0.0, 40.0),
                cornerRadius = root.boundedDouble("cornerRadius", 0.0, 40.0),
                textScale = root.boundedDouble("textScale", 0.8, 1.4) ?: baseline.textScale,
                geometry = root.optJSONObject("geometry")?.let(HabiterWidgetGeometry::fromJson)
                    ?: baseline.geometry,
                typography = root.optJSONObject("typography")?.let(HabiterWidgetTypography::fromJson)
                    ?: baseline.typography,
                stateStyles = root.optJSONObject("stateStyles")?.let(HabiterWidgetStateStyles::fromJson)
                    ?: baseline.stateStyles,
                interactions = root.optJSONObject("interactions")?.let(HabiterWidgetInteractionMap::fromJson)
                    ?: baseline.interactions,
                hiddenElements = if (root.has("hiddenElements")) {
                    root.enumSet("hiddenElements") { it.wireName }
                } else {
                    baseline.hiddenElements
                },
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
