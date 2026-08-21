abstract final class HabiterSpace {
  static const xxs = 2.0;
  static const xs = 4.0;
  static const sm = 8.0;
  static const sm2 = 12.0;
  static const md = 16.0;
  static const md2 = 20.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
  static const xxxl = 64.0;
}

abstract final class HabiterRadius {
  static const compact = 10.0;
  static const control = 14.0;
  static const card = 20.0;
  static const prominent = 28.0;
  static const sheet = 30.0;
  static const pill = 999.0;
}

abstract final class HabiterSize {
  static const contentMax = 720.0;
  static const wideContentMax = 1120.0;
  // TODO(issue-26): remove these compatibility aliases when the adaptive shell
  // and Today layout consume HabiterLayout in their dedicated batches.
  static const compactBreakpoint = 600.0;
  static const expandedBreakpoint = 840.0;
  static const desktopBreakpoint = 1024.0;
}

abstract final class HabiterState {
  static const disabledOpacity = 0.42;
  static const hoverOpacity = 0.08;
  static const focusWidth = 3.0;
  static const minimumTarget = 48.0;
}
