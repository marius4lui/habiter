final class WidgetHabitItem {
  const WidgetHabitItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.isCompleted,
    required this.scheduleLabel,
  });

  factory WidgetHabitItem.fromMap(Map<String, Object?> map) => WidgetHabitItem(
    id: map['id']! as String,
    name: map['name']! as String,
    icon: map['icon']! as String,
    isCompleted: map['isCompleted'] as bool? ?? false,
    scheduleLabel: map['scheduleLabel'] as String? ?? '',
  );

  final String id;
  final String name;
  final String icon;
  final bool isCompleted;
  final String scheduleLabel;

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'name': name,
    'icon': icon,
    'isCompleted': isCompleted,
    'scheduleLabel': scheduleLabel,
  };
}
