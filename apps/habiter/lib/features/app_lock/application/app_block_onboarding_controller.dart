import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../models/locked_app.dart';
import '../domain/app_block_candidate.dart';
import '../domain/app_block_rule.dart';
import '../domain/app_lock_gateway.dart';
import '../infrastructure/app_block_onboarding_repository.dart';
import '../infrastructure/local_distraction_catalog.dart';
import 'app_block_onboarding_state.dart';
import 'app_block_recommendation_service.dart';

final class AppBlockOnboardingController extends ChangeNotifier {
  AppBlockOnboardingController({
    required AppBlockOnboardingRepository repository,
    required AppLockGateway gateway,
    required Future<LocalDistractionCatalog> Function() loadCatalog,
    AppBlockRecommendationService recommendations =
        const AppBlockRecommendationService(),
    DateTime Function()? now,
    this.discoveryTimeout = const Duration(seconds: 20),
    Future<bool> Function(List<AppBlockRule> rules)? activate,
  }) : _repository = repository,
       _gateway = gateway,
       _loadCatalog = loadCatalog,
       _recommendations = recommendations,
       _now = now ?? DateTime.now,
       _activate = activate ?? _defaultActivate;

  final Duration discoveryTimeout;
  int _discoveryGeneration = 0;

  final AppBlockOnboardingRepository _repository;
  final AppLockGateway _gateway;
  final Future<LocalDistractionCatalog> Function() _loadCatalog;
  final AppBlockRecommendationService _recommendations;
  final DateTime Function() _now;
  final Future<bool> Function(List<AppBlockRule> rules) _activate;

  AppBlockOnboardingState _state = const AppBlockOnboardingState();
  List<AppBlockCandidate> _candidates = const <AppBlockCandidate>[];
  List<LockedApp> _installedApps = const <LockedApp>[];
  bool _initialized = false;
  bool _loading = false;
  String? _diagnostic;

  AppBlockOnboardingState get state => _state;
  List<AppBlockCandidate> get candidates => _candidates;
  List<LockedApp> get installedApps => _installedApps;
  bool get initialized => _initialized;
  bool get loading => _loading;
  String? get diagnostic => _diagnostic;
  AppLockGateway get gateway => _gateway;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      _state = await _repository.load() ?? const AppBlockOnboardingState();
      _diagnostic = _state.stage == AppBlockOnboardingStage.discovery
          ? 'App analysis was interrupted. Try again or continue later.'
          : null;
    } on FormatException {
      _state = const AppBlockOnboardingState();
      _diagnostic = 'Saved App Block setup could not be restored.';
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> acceptOffer() => _move(AppBlockOnboardingStage.usageEducation);
  Future<void> reconsider() => _move(AppBlockOnboardingStage.reconsider);
  Future<void> skip() => _leaveDiscovery(AppBlockOnboardingStage.skipped);
  Future<void> defer() => _leaveDiscovery(AppBlockOnboardingStage.deferred);

  Future<void> _leaveDiscovery(AppBlockOnboardingStage stage) {
    _discoveryGeneration++;
    _loading = false;
    return _move(stage);
  }

  @override
  void dispose() {
    _discoveryGeneration++;
    super.dispose();
  }

  Future<void> requestUsageAccess() async {
    await _replace(_state.copyWith(usagePermissionSeen: true));
    await _gateway.requestUsageAccess();
  }

  Future<void> requestOverlay() async {
    await _replace(_state.copyWith(overlayPermissionSeen: true));
    await _gateway.requestOverlay();
  }

  Future<void> reconcilePermissions() async {
    final result = await _gateway.permissions();
    if (result case AppLockSuccess<AppLockPermissionSnapshot>(:final value)) {
      if (_state.stage == AppBlockOnboardingStage.usageEducation &&
          value.usageAccess) {
        await discover();
      } else if (_state.stage == AppBlockOnboardingStage.overlayEducation &&
          value.overlay) {
        await _move(AppBlockOnboardingStage.review);
      }
    }
  }

  Future<void> discover() async {
    if (_loading) return;
    final generation = ++_discoveryGeneration;
    _loading = true;
    _diagnostic = null;
    // Discovery is transient: a restart must not restore an idle spinner.
    _state = _state.copyWith(stage: AppBlockOnboardingStage.discovery);
    notifyListeners();
    try {
      final result = await _loadDiscovery().timeout(discoveryTimeout);
      if (generation != _discoveryGeneration) return;
      final next = _state.copyWith(stage: AppBlockOnboardingStage.selection);
      await _repository.save(next).timeout(discoveryTimeout);
      if (generation != _discoveryGeneration) return;
      _installedApps = result.apps;
      _candidates = result.candidates;
      _diagnostic = result.diagnostic;
      _state = next;
    } on TimeoutException {
      if (generation == _discoveryGeneration) {
        _diagnostic = 'App analysis timed out. Try again or continue later.';
      }
    } catch (_) {
      if (generation == _discoveryGeneration) {
        _diagnostic =
            'App analysis could not finish. Try again or continue later.';
      }
    } finally {
      if (generation == _discoveryGeneration) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  Future<
    ({
      List<LockedApp> apps,
      List<AppBlockCandidate> candidates,
      String? diagnostic,
    })
  >
  _loadDiscovery() async {
    final usage = await _gateway.recentUsage();
    final apps = await _gateway.installedApps();
    if (apps is! AppLockSuccess<List<LockedApp>>) {
      throw StateError('Installed apps could not be loaded.');
    }
    if (usage case AppLockSuccess<List<AppUsageRecord>>(:final value)) {
      return (
        apps: apps.value,
        candidates: _recommendations.rank(
          usage: value,
          catalog: await _loadCatalog(),
          now: _now(),
        ),
        diagnostic: null,
      );
    }
    return (
      apps: apps.value,
      candidates: const <AppBlockCandidate>[],
      diagnostic: (usage as AppLockFailure<List<AppUsageRecord>>).safeMessage,
    );
  }

  Future<void> setSelectedPackages(Set<String> packages) =>
      _replace(_state.copyWith(selectedPackages: packages));

  Future<void> bindAll(AppBlockRequirement requirement) {
    final names = <String, String>{
      for (final app in _installedApps) app.packageName: app.appName,
      for (final candidate in _candidates)
        candidate.packageName: candidate.appName,
    };
    return _replace(
      _state.copyWith(
        stage: AppBlockOnboardingStage.binding,
        rules: _state.selectedPackages
            .map(
              (packageName) => AppBlockRule(
                packageName: packageName,
                appName: names[packageName] ?? packageName,
                requirement: requirement,
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  Future<void> overrideRule(
    String packageName,
    AppBlockRequirement requirement,
  ) => _replace(
    _state.copyWith(
      rules: _state.rules
          .map(
            (rule) => rule.packageName == packageName
                ? rule.copyWith(requirement: requirement)
                : rule,
          )
          .toList(growable: false),
    ),
  );

  Future<void> showBehaviorEducation() =>
      _move(AppBlockOnboardingStage.behaviorEducation);
  Future<void> showOverlayEducation() =>
      _move(AppBlockOnboardingStage.overlayEducation);
  Future<void> complete() async {
    _loading = true;
    notifyListeners();
    final activated = await _activate(_state.rules);
    _loading = false;
    if (activated) {
      await _move(AppBlockOnboardingStage.completed);
    } else {
      _diagnostic = 'App Block could not be activated. Check both permissions.';
      notifyListeners();
    }
  }

  Future<void> _move(AppBlockOnboardingStage stage) =>
      _replace(_state.copyWith(stage: stage));

  Future<void> _replace(AppBlockOnboardingState next) async {
    await _repository.save(next);
    _state = next;
    notifyListeners();
  }
}

Future<bool> _defaultActivate(List<AppBlockRule> rules) async => true;
