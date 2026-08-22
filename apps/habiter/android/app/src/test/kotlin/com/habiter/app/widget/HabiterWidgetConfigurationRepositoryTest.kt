package com.habiter.app.widget

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class HabiterWidgetConfigurationRepositoryTest {
    @Test
    fun `widget configurations remain isolated by app widget id`() {
        val store = MemoryWidgetConfigurationStore()
        val first = HabiterWidgetConfiguration(
            widgetId = 17,
            contentMode = HabiterWidgetContentMode.FOCUS,
        )
        val second = HabiterWidgetConfiguration(
            widgetId = 18,
            contentMode = HabiterWidgetContentMode.LIST,
        )

        assertTrue(HabiterWidgetConfigurationRepository.save(store, first))
        assertTrue(HabiterWidgetConfigurationRepository.save(store, second))

        assertEquals(
            HabiterWidgetContentMode.FOCUS,
            HabiterWidgetConfigurationRepository.read(store, 17).contentMode,
        )
        assertEquals(
            HabiterWidgetContentMode.LIST,
            HabiterWidgetConfigurationRepository.read(store, 18).contentMode,
        )
    }

    @Test
    fun `delete and prune remove only configurations without instances`() {
        val store = MemoryWidgetConfigurationStore()
        setOf(17, 18, 19).forEach {
            HabiterWidgetConfigurationRepository.save(
                store,
                HabiterWidgetConfiguration(widgetId = it),
            )
        }

        assertTrue(HabiterWidgetConfigurationRepository.delete(store, setOf(17)))
        assertFalse(store.keys.contains(HabiterWidgetConfigurationRepository.key(17)))
        assertTrue(store.keys.contains(HabiterWidgetConfigurationRepository.key(18)))

        assertTrue(HabiterWidgetConfigurationRepository.prune(store, setOf(18)))
        assertEquals(
            setOf(HabiterWidgetConfigurationRepository.key(18)),
            store.keys,
        )
    }
}

private class MemoryWidgetConfigurationStore : HabiterWidgetConfigurationStore {
    private val values = mutableMapOf<String, String>()

    override val keys: Set<String>
        get() = values.keys

    override fun read(key: String): String? = values[key]

    override fun write(key: String, value: String): Boolean {
        values[key] = value
        return true
    }

    override fun remove(keys: Set<String>): Boolean {
        keys.forEach(values::remove)
        return true
    }
}
