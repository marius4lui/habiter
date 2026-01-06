# State Management

We use `Provider` for Dependency Injection and State Management.

## Providers

### HabitProvider
The central store for habit data.
- **Methods**: `addHabit()`, `completeHabit()`, `deleteHabit()`.
- **Logic**: Calculates streaks and completion stats.
- **Persistence**: automatically saves changes to storage.

### AppLockProvider
Manages the locking logic.
- Listens to `HabitProvider` changes.
- Updates the locked state of external apps based on habit completion.

### monitoring
``` mermaid
sequenceDiagram
    participant UI
    participant HabitProvider
    participant AppLockProvider
    
    UI->>HabitProvider: completeHabit(id)
    HabitProvider-->>AppLockProvider: notifyListeners()
    AppLockProvider->>AppLockProvider: checkConditions()
    Note over AppLockProvider: If all habits done
    AppLockProvider->>System: unlockApps()
```
