import '../../../../l10n/app_localizations.dart';
import '../../../../models/habit.dart';

abstract final class HabitCategories {
  static const health = 'Health';
  static const learning = 'Learning';
  static const productivity = 'Productivity';
  static const social = 'Social';
  static const creative = 'Creative';
  static const fitness = 'Fitness';
  static const mindfulness = 'Mindfulness';
  static const finance = 'Finance';
  static const home = 'Home';

  static const values = <String>[
    health,
    fitness,
    mindfulness,
    learning,
    productivity,
    home,
    social,
    creative,
    finance,
  ];
}

String localizedHabitCategory(AppLocalizations l10n, String category) =>
    switch (category) {
      HabitCategories.health => l10n.categoryHealth,
      HabitCategories.learning => l10n.categoryLearning,
      HabitCategories.productivity => l10n.categoryProductivity,
      HabitCategories.social => l10n.categorySocial,
      HabitCategories.creative => l10n.categoryCreative,
      HabitCategories.fitness => l10n.categoryFitness,
      HabitCategories.mindfulness => l10n.categoryMindfulness,
      HabitCategories.finance => l10n.categoryFinance,
      HabitCategories.home => l10n.categoryHome,
      _ => category,
    };

enum HabitTemplateGroup {
  popular,
  health,
  fitness,
  mindfulness,
  learning,
  productivity,
  home,
  finance,
}

String localizedTemplateGroup(
  AppLocalizations l10n,
  HabitTemplateGroup group,
) => switch (group) {
  HabitTemplateGroup.popular => l10n.templateGroupPopular,
  HabitTemplateGroup.health => l10n.categoryHealth,
  HabitTemplateGroup.fitness => l10n.categoryFitness,
  HabitTemplateGroup.mindfulness => l10n.categoryMindfulness,
  HabitTemplateGroup.learning => l10n.categoryLearning,
  HabitTemplateGroup.productivity => l10n.categoryProductivity,
  HabitTemplateGroup.home => l10n.categoryHome,
  HabitTemplateGroup.finance => l10n.categoryFinance,
};

final class HabitTemplate {
  const HabitTemplate({
    required this.id,
    required this.category,
    required this.icon,
    required this.color,
    required this.frequency,
    this.targetCount = 1,
    this.customDays = const <int>[],
    this.groups = const <HabitTemplateGroup>{},
  });

  final String id;
  final String category;
  final String icon;
  final String color;
  final HabitFrequency frequency;
  final int targetCount;
  final List<int> customDays;
  final Set<HabitTemplateGroup> groups;

  String localizedName(AppLocalizations l10n) => switch (id) {
    'water' => l10n.templateWater,
    'workout' => l10n.templateWorkout,
    'read' => l10n.templateRead,
    'meditate' => l10n.templateMeditate,
    'walk' => l10n.templateWalk,
    'sleep' => l10n.templateSleep,
    'write' => l10n.templateWrite,
    'tidy' => l10n.templateTidy,
    'healthy_meal' => l10n.templateHealthyMeal,
    'medicine' => l10n.templateMedicine,
    'floss' => l10n.templateFloss,
    'screen_free' => l10n.templateScreenFree,
    'finances' => l10n.templateFinances,
    'instrument' => l10n.templateInstrument,
    'language' => l10n.templateLanguage,
    'run' => l10n.templateRun,
    _ => id,
  };

  static const catalog = <HabitTemplate>[
    HabitTemplate(
      id: 'water',
      category: HabitCategories.health,
      icon: '💧',
      color: '#3E7CB1',
      frequency: HabitFrequency.daily,
      groups: {HabitTemplateGroup.popular, HabitTemplateGroup.health},
    ),
    HabitTemplate(
      id: 'workout',
      category: HabitCategories.fitness,
      icon: '🏋️',
      color: '#C45B42',
      frequency: HabitFrequency.weekly,
      targetCount: 3,
      groups: {HabitTemplateGroup.popular, HabitTemplateGroup.fitness},
    ),
    HabitTemplate(
      id: 'read',
      category: HabitCategories.learning,
      icon: '📚',
      color: '#7B61A8',
      frequency: HabitFrequency.daily,
      groups: {HabitTemplateGroup.popular, HabitTemplateGroup.learning},
    ),
    HabitTemplate(
      id: 'meditate',
      category: HabitCategories.mindfulness,
      icon: '🧘',
      color: '#467B68',
      frequency: HabitFrequency.daily,
      groups: {HabitTemplateGroup.popular, HabitTemplateGroup.mindfulness},
    ),
    HabitTemplate(
      id: 'walk',
      category: HabitCategories.health,
      icon: '🚶',
      color: '#4C8065',
      frequency: HabitFrequency.daily,
      groups: {HabitTemplateGroup.popular, HabitTemplateGroup.health},
    ),
    HabitTemplate(
      id: 'sleep',
      category: HabitCategories.health,
      icon: '🛏️',
      color: '#53699A',
      frequency: HabitFrequency.daily,
      groups: {HabitTemplateGroup.health},
    ),
    HabitTemplate(
      id: 'write',
      category: HabitCategories.creative,
      icon: '✍️',
      color: '#A66E3F',
      frequency: HabitFrequency.daily,
      groups: {HabitTemplateGroup.productivity},
    ),
    HabitTemplate(
      id: 'tidy',
      category: HabitCategories.home,
      icon: '🧹',
      color: '#397A77',
      frequency: HabitFrequency.weekly,
      targetCount: 3,
      groups: {HabitTemplateGroup.home},
    ),
    HabitTemplate(
      id: 'healthy_meal',
      category: HabitCategories.health,
      icon: '🥗',
      color: '#4F7D3A',
      frequency: HabitFrequency.daily,
      groups: {HabitTemplateGroup.health},
    ),
    HabitTemplate(
      id: 'medicine',
      category: HabitCategories.health,
      icon: '💊',
      color: '#3D748F',
      frequency: HabitFrequency.daily,
      groups: {HabitTemplateGroup.health},
    ),
    HabitTemplate(
      id: 'floss',
      category: HabitCategories.health,
      icon: '🪥',
      color: '#508094',
      frequency: HabitFrequency.daily,
      groups: {HabitTemplateGroup.health},
    ),
    HabitTemplate(
      id: 'screen_free',
      category: HabitCategories.mindfulness,
      icon: '📵',
      color: '#596C7A',
      frequency: HabitFrequency.daily,
      groups: {HabitTemplateGroup.mindfulness},
    ),
    HabitTemplate(
      id: 'finances',
      category: HabitCategories.finance,
      icon: '💰',
      color: '#92712E',
      frequency: HabitFrequency.weekly,
      groups: {HabitTemplateGroup.finance},
    ),
    HabitTemplate(
      id: 'instrument',
      category: HabitCategories.creative,
      icon: '🎸',
      color: '#A04D78',
      frequency: HabitFrequency.weekly,
      targetCount: 3,
      groups: {HabitTemplateGroup.learning},
    ),
    HabitTemplate(
      id: 'language',
      category: HabitCategories.learning,
      icon: '🗣️',
      color: '#5E64A6',
      frequency: HabitFrequency.weekly,
      targetCount: 4,
      groups: {HabitTemplateGroup.learning},
    ),
    HabitTemplate(
      id: 'run',
      category: HabitCategories.fitness,
      icon: '🏃',
      color: '#B45D38',
      frequency: HabitFrequency.weekly,
      targetCount: 3,
      groups: {HabitTemplateGroup.fitness},
    ),
  ];
}
