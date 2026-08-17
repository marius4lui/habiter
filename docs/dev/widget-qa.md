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
