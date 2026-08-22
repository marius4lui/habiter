# Responsive layout contract

Habiter uses one responsive presentation system for compact touch displays,
phones, tablets, and desktop windows. Domain models, providers, persistence, and
navigation state do not branch by device type; only presentation changes with
the space available to a widget.

## Source of truth

The canonical API is `HabiterLayout`, defined by the Design System's
`layout.dart`. It derives a semantic class, orientation, short-height state,
page padding, and safe grid column count from a `Size`. Screens must use this
API or the reusable primitives in `core/design_system/`; they must not
introduce device-name checks or parallel breakpoint constants.

| Layout class | Width | Primary shell | Content policy |
| --- | ---: | --- | --- |
| Compact | below 600 dp | Compact top bar and Bottom Navigation where height permits | One prioritized column |
| Medium | 600–839 dp | Top bar and Bottom Navigation | One flexible column; cards may pair when their minimum width is preserved |
| Expanded | 840–1199 dp | NavigationRail | Screen-specific primary and secondary columns when local space permits |
| Large | 1200 dp and above | Extended NavigationRail with utility actions | Centered, bounded workspace; up to three safe grid columns |

These widths classify the window. A screen or grid must still use its locally
allocated width after navigation, padding, and maximum-width constraints. A
nominally Expanded window may therefore keep a section in one column when two
readable columns do not fit.

Responsive mode is automatic. There is no user preference that can force a
device class. Medium keeps Bottom Navigation, Expanded introduces the compact
rail, and Large extends the rail. Large uses rail plus centered content rather
than a persistent contextual side panel.

## Reusable presentation primitives

- `HabiterContent` applies class-aware page padding and a centered maximum
  width. Screens choose the narrow or wide content maximum deliberately.
- `HabiterAdaptiveGrid` wraps embedded page sections without shrinking a card
  below its declared minimum width.
- `showHabiterAdaptivePane` presents a full-width, height-aware sheet on
  Compact and Medium, and a bounded dialog on Expanded and Large.
- `AdaptiveAppShell` keeps one stable content slot while navigation changes
  between Bottom Navigation, NavigationRail, and the extended rail.

Screen-specific composition remains declarative:

- Today stacks its habit hero and navigation wheel until the local content area
  is Expanded, then uses proportional primary and secondary panes. The wheel is
  reparented with stable state across the change.
- Settings may pair 300 dp groups beginning in Medium.
- Analytics and Rhythm require at least 360 dp per information column and use
  at most two columns.
- Editors and reminder settings use the adaptive pane contract rather than
  selecting sheets or dialogs independently.

## Compact and accessible behavior

All interactive targets remain at least 48 dp. Compact layouts prioritize
scrolling and reachable actions instead of reducing text size. Controls that
can contain user content wrap or elide safely, and editor actions remain
available on short viewports. At 200% text scaling, information may consume
more vertical space but must not overflow horizontally or become unreachable.

Material controls use the theme's focus and hover colors. Desktop primary
destinations have `Ctrl+1`, `Ctrl+2`, and `Ctrl+3` shortcuts; the Today wheel
supports arrow keys plus Enter or Space. Navigation and utility actions remain
reachable through normal focus traversal.

## Automated reference matrix

The widget suite treats these logical sizes as the canonical matrix:

| Reference | Size | Extra condition |
| --- | ---: | --- |
| Compact smart display, portrait | 320 × 480 | 200% text |
| Compact smart display, landscape | 480 × 320 | 200% text |
| Phone | 390 × 844 | Default text |
| Tablet, portrait | 700 × 1000 | Bottom Navigation |
| Tablet, landscape | 1000 × 700 | NavigationRail |
| Desktop | 1440 × 900 | Extended NavigationRail |

`test/features/ui/mobile_ux_refactor_test.dart` renders Today, Analytics,
Rhythm, Settings, and the habit editor at every reference size. It also compares
serialized habits, entries, reminder preferences, and reminder policies before
and after the matrix. `test/app/navigation/adaptive_navigation_test.dart`
checks the matching shell form and state retention. Compact detail/editor tests,
onboarding tests, and adaptive-presentation tests cover long content, 200% text,
short height, and dialog bounds.

## Reproducible manual QA

Automated logical-size tests do not prove OEM rendering, physical touch
accuracy, platform window chrome, or assistive-technology behavior. For a
physical-device or desktop QA pass:

1. Record device/window size, pixel ratio, operating system, locale, theme, and
   text scale.
2. Exercise empty, pending, completed, long-name, paused, and archived Today
   states; open habit details and the editor.
3. Visit Analytics, Rhythm, Settings, and onboarding; open every adaptive editor
   or confirmation and scroll to its final action.
4. Rotate or resize between the paired tablet sizes after selecting a habit;
   confirm the selection and persisted data remain unchanged.
5. On desktop, traverse the rail, Today, and utility actions using only the
   keyboard, then repeat with a pointer and verify visible focus and hover.
6. At 200% text, confirm that no content clips horizontally and every primary
   action remains reachable.

Record unavailable physical-device gates as unverified. The automated reference
matrix is reproducible evidence for layout behavior, not a claim that an Echo
Show or every desktop platform was physically exercised.
