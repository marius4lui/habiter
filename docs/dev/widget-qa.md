# Android widget QA

Habiter's Android home-screen widget uses responsive Glance layouts. Completion
feedback is especially sensitive to launcher-provided dimensions because the
habit name and Undo action must remain usable without overlapping.

## Automated contracts

- Every supported widget size maps to an explicit responsive layout bucket.
- Narrow square completion feedback stacks its content and action vertically.
- Short wide completion feedback stays horizontal.
- Compact completion feedback uses an icon-only Undo control with a localized
  accessibility description.
- German and English status, Undo, completion, and accessibility copy remain
  covered by unit tests.
- The transient completion projection expires into the settled all-complete
  state after the configured Undo window.

## Manual launcher matrix

Exercise all responsive sizes declared by `HabiterWidget.sizeMode` on at least
one supported Android launcher:

| Size (dp) | Expected layout | Completion check |
| --- | --- | --- |
| 110 × 60 | compact | Habit remains one line; Undo icon is visible. |
| 110 × 110 | compact square | Summary and Undo stack without overlap. |
| 180 × 110 | compact square | German Undo label does not squeeze the habit name. |
| 180 × 180 | compact square | Both transient and settled messages remain visible. |
| 250 × 60 | wide | Check, one-line message, and control fit horizontally. |
| 250 × 120 | medium hero | Full Undo label and status remain visible. |
| 250 × 180 | medium hero | Full completion feedback remains centered. |
| 250 × 250 | large | Completion feedback remains centered and readable. |
| 320 × 300 | extra large | Completion feedback remains centered and readable. |

For each size, verify both German and English with a long habit name, increased
system font size, light and dark launcher themes, and these state transitions:

1. Complete the final pending habit from the widget.
2. Confirm that the check, habit name, status, and Undo affordance are not
   clipped or overlapping.
3. Activate Undo and confirm that the pending state returns exactly once.
4. Complete again and let the Undo window expire.
5. Confirm that the settled completion message fits without clipping.
6. With TalkBack enabled, confirm that the compact Undo icon announces the
   habit-specific localized action.

This matrix is the regression gate for GitHub issue #9.

## Lifecycle convergence

The app and widget can run in separate Flutter isolates. A widget action writes
the canonical repository first, while a running app may still hold an older
controller snapshot. Foreground reconciliation must therefore follow this
order:

1. Load one versioned repository snapshot.
2. Rehydrate habits and history from that same revision.
3. Reconcile reminder and App Lock consumers from the fresh provider state.
4. Publish the final widget snapshot.
5. Re-read the repository after a short settle window and repeat when its
   revision advanced during reconciliation.

Automated tests cover external completion state, an overlapping write during
resume, coalesced lifecycle requests, background publication, and safe recovery
after a failed lifecycle operation.

Manual Android regression checks:

- Complete and undo from the widget while the app is backgrounded, then resume
  the app and verify Today, analytics, Reminder state, and App Lock immediately.
- Open the app immediately after tapping the widget and confirm the final state
  does not jump backwards.
- Complete in the app and immediately return to the launcher; confirm every
  installed widget instance updates without a manual refresh.
- Repeat across midnight and after date, timezone, locale, boot, and process
  recreation events.
- Confirm repeated `inactive`, `hidden`, `paused`, and `resumed` transitions do
  not create refresh storms.

This lifecycle matrix is the regression gate for GitHub issue #11.
