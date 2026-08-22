package com.habiter.app.widget

import android.content.Context
import android.content.SharedPreferences

internal interface HabiterWidgetConfigurationStore {
    val keys: Set<String>

    fun read(key: String): String?

    fun write(key: String, value: String): Boolean

    fun remove(keys: Set<String>): Boolean
}

private class SharedPreferencesWidgetConfigurationStore(
    private val preferences: SharedPreferences,
) : HabiterWidgetConfigurationStore {
    override val keys: Set<String>
        get() = preferences.all.keys

    override fun read(key: String): String? = preferences.getString(key, null)

    override fun write(key: String, value: String): Boolean =
        preferences.edit().putString(key, value).commit()

    override fun remove(keys: Set<String>): Boolean {
        if (keys.isEmpty()) return true
        return preferences.edit().also { editor -> keys.forEach(editor::remove) }.commit()
    }
}

internal object HabiterWidgetConfigurationRepository {
    const val PREFERENCES = "habiter_widget_configurations"
    private const val KEY_PREFIX = "configuration_"

    fun read(context: Context, widgetId: Int): HabiterWidgetConfiguration =
        read(store(context), widgetId)

    fun read(
        store: HabiterWidgetConfigurationStore,
        widgetId: Int,
    ): HabiterWidgetConfiguration = HabiterWidgetConfiguration.parseOrDefaults(
        store.read(key(widgetId)),
        widgetId,
    )

    fun save(context: Context, configuration: HabiterWidgetConfiguration): Boolean =
        save(store(context), configuration)

    fun save(
        store: HabiterWidgetConfigurationStore,
        configuration: HabiterWidgetConfiguration,
    ): Boolean = store.write(key(configuration.widgetId), configuration.toJson())

    fun delete(context: Context, widgetIds: IntArray): Boolean =
        delete(store(context), widgetIds.toSet())

    fun delete(store: HabiterWidgetConfigurationStore, widgetIds: Set<Int>): Boolean =
        store.remove(widgetIds.map(::key).toSet())

    fun prune(context: Context, installedWidgetIds: Set<Int>): Boolean =
        prune(store(context), installedWidgetIds)

    fun prune(
        store: HabiterWidgetConfigurationStore,
        installedWidgetIds: Set<Int>,
    ): Boolean {
        val installedKeys = installedWidgetIds.map(::key).toSet()
        val staleKeys = store.keys.filterTo(mutableSetOf()) {
            it.startsWith(KEY_PREFIX) && it !in installedKeys
        }
        return store.remove(staleKeys)
    }

    private fun store(context: Context): HabiterWidgetConfigurationStore =
        SharedPreferencesWidgetConfigurationStore(
            context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE),
        )

    internal fun key(widgetId: Int): String = "$KEY_PREFIX$widgetId"
}
