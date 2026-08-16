enum WidgetActionType { completeHabit, undoCompletion }

final class WidgetAction {
  const WidgetAction({
    required this.type,
    required this.habitId,
    required this.localDate,
    required this.actionId,
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
    if (habitId == null || localDate == null || actionId == null) {
      throw const FormatException('Widget action parameters are incomplete.');
    }
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(localDate)) {
      throw const FormatException('Widget action date is invalid.');
    }
    return WidgetAction(
      type: type,
      habitId: habitId,
      localDate: localDate,
      actionId: actionId,
    );
  }

  final WidgetActionType type;
  final String habitId;
  final String localDate;
  final String actionId;

  Uri toUri() => Uri(
    scheme: 'habiter-widget',
    host: type.name,
    queryParameters: <String, String>{
      'habitId': habitId,
      'localDate': localDate,
      'actionId': actionId,
    },
  );
}
