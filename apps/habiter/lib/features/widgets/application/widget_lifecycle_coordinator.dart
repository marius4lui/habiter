import 'package:flutter/widgets.dart';

typedef WidgetLifecycleOperation = Future<void> Function();
typedef WidgetLifecycleErrorHandler =
    void Function(Object error, StackTrace stackTrace);

final class WidgetLifecycleCoordinator {
  WidgetLifecycleCoordinator({
    required WidgetLifecycleOperation reconcileForeground,
    required WidgetLifecycleOperation publishBackground,
    WidgetLifecycleErrorHandler? onError,
  }) : _reconcileForeground = reconcileForeground,
       _publishBackground = publishBackground,
       _onError = onError;

  final WidgetLifecycleOperation _reconcileForeground;
  final WidgetLifecycleOperation _publishBackground;
  final WidgetLifecycleErrorHandler? _onError;

  Future<void> _queue = Future<void>.value();
  AppLifecycleState? _lastState;
  bool _backgroundPublished = false;

  Future<void> handle(AppLifecycleState state) {
    if (state == _lastState) return _queue;
    _lastState = state;
    switch (state) {
      case AppLifecycleState.resumed:
        _backgroundPublished = false;
        return _enqueue(_reconcileForeground);
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        if (_backgroundPublished) return _queue;
        _backgroundPublished = true;
        return _enqueue(_publishBackground);
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        return _queue;
    }
  }

  Future<void> _enqueue(WidgetLifecycleOperation operation) {
    _queue = _queue.then((_) async {
      try {
        await operation();
      } catch (error, stackTrace) {
        _onError?.call(error, stackTrace);
      }
    });
    return _queue;
  }
}
