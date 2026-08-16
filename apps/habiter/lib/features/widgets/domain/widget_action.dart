enum WidgetActionType { completeHabit, undoCompletion, refresh }

final class WidgetAction {
  const WidgetAction({
    required this.type,
    required this.habitId,
    required this.localDate,
    required this.actionId,
    this.sourceActionId,
  });

  factory WidgetAction.completeHabit({
    required String habitId,
    required String localDate,
    required String actionId,
  }) => WidgetAction(
    type: WidgetActionType.completeHabit,
    habitId: habitId,
    localDate: localDate,
    actionId: actionId,
  );

  factory WidgetAction.undoCompletion({
    required String habitId,
    required String localDate,
    required String actionId,
    required String sourceActionId,
  }) => WidgetAction(
    type: WidgetActionType.undoCompletion,
    habitId: habitId,
    localDate: localDate,
    actionId: actionId,
    sourceActionId: sourceActionId,
  );

  factory WidgetAction.refresh({
    required String localDate,
    required String actionId,
  }) => WidgetAction(
    type: WidgetActionType.refresh,
    habitId: '',
    localDate: localDate,
    actionId: actionId,
  );

  factory WidgetAction.fromUri(Uri uri) {
    if (uri.scheme != 'habiter-widget') {
      throw const FormatException('Unexpected widget action scheme.');
    }
    final type = WidgetActionType.values.firstWhere(
      (value) => value.name.toLowerCase() == uri.host.toLowerCase(),
      orElse: () =>
          throw const FormatException('Unexpected widget action type.'),
    );
    final habitId = uri.queryParameters['habitId'];
    final localDate = uri.queryParameters['localDate'];
    final actionId = uri.queryParameters['actionId'];
    final sourceActionId = uri.queryParameters['sourceActionId'];
    if (habitId == null || localDate == null || actionId == null) {
      throw const FormatException('Widget action parameters are incomplete.');
    }
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(localDate)) {
      throw const FormatException('Widget action date is invalid.');
    }
    if (type == WidgetActionType.undoCompletion && sourceActionId == null) {
      throw const FormatException('Undo source action is missing.');
    }
    return WidgetAction(
      type: type,
      habitId: habitId,
      localDate: localDate,
      actionId: actionId,
      sourceActionId: sourceActionId,
    );
  }

  final WidgetActionType type;
  final String habitId;
  final String localDate;
  final String actionId;
  final String? sourceActionId;

  Uri toUri() => Uri(
    scheme: 'habiter-widget',
    host: type.name,
    queryParameters: <String, String>{
      'habitId': habitId,
      'localDate': localDate,
      'actionId': actionId,
      if (sourceActionId != null) 'sourceActionId': sourceActionId!,
    },
  );
}
