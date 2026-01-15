import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/habit.dart';
import '../providers/habit_provider.dart';
import '../theme/app_theme.dart';
import '../utils/habit_utils.dart';

class AddHabitSheet extends StatefulWidget {
  const AddHabitSheet({super.key, this.habit});

  final Habit? habit;

  @override
  State<AddHabitSheet> createState() => _AddHabitSheetState();
}

class _AddHabitSheetState extends State<AddHabitSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  late String _category;
  late HabitFrequency _frequency;
  int _targetCount = 1;
  late String _color;
  late String _icon;
  final Set<int> _selectedWeekdays = {};
  bool _saving = false;

  Map<String, List<String>> get _iconSuggestions => getHabitIconSuggestions();

  @override
  void initState() {
    super.initState();
    if (widget.habit != null) {
      final h = widget.habit!;
      _nameController.text = h.name;
      if (h.description != null) _descriptionController.text = h.description!;
      _category = h.category;
      _frequency = h.frequency;
      _targetCount = h.targetCount;
      _color = h.color;
      _icon = h.icon;
      if (h.customDays != null) _selectedWeekdays.addAll(h.customDays!);
    } else {
      _category = _iconSuggestions.keys.first;
      _frequency = HabitFrequency.daily;
      _color = getRandomColor();
      _icon = _iconSuggestions[_category]?.first ?? '✅';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final provider = context.read<HabitProvider>();
    if (widget.habit != null) {
      await provider.updateHabit(
        widget.habit!.id,
        widget.habit!.copyWith(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          category: _category,
          frequency: _frequency,
          targetCount: _targetCount,
          color: _color,
          icon: _icon,
          customDays: _frequency == HabitFrequency.custom
              ? _selectedWeekdays.toList()
              : null,
        ),
      );
    } else {
      await provider.addHabit(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        category: _category,
        frequency: _frequency,
        targetCount: _targetCount,
        color: _color,
        icon: _icon,
        customDays: _frequency == HabitFrequency.custom
            ? _selectedWeekdays.toList()
            : null,
      );
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _deleteHabit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Habit?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      await context.read<HabitProvider>().deleteHabit(widget.habit!.id);
      if (!mounted) return;
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = generateHabitColors();
    final categories = _iconSuggestions.keys.toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColorsDark.surface : AppColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppBorderRadius.xl),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(widget.habit != null ? 'Edit Habit' : 'New Habit',
                      style: AppTextStyles.h2),
                  if (widget.habit != null)
                    IconButton(
                        onPressed: _deleteHabit,
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red)),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        hintText: 'e.g. Read 20 minutes',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Optional description',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text('Category', style: AppTextStyles.h3),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: categories
                          .map(
                            (c) => ChoiceChip(
                              label: Text(c),
                              selected: c == _category,
                              onSelected: (_) {
                                setState(() {
                                  _category = c;
                                  _icon = _iconSuggestions[c]?.first ?? _icon;
                                });
                              },
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Icon', style: AppTextStyles.h3),
                        Row(
                          children: [
                            // Show currently selected icon
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AppBorderRadius.md),
                                border: Border.all(color: AppColors.primary),
                              ),
                              alignment: Alignment.center,
                              child: Text(_icon, style: const TextStyle(fontSize: 20)),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'Tap below to change',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      height: 52,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (_, index) {
                          final icons = _iconSuggestions[_category] ?? _iconSuggestions.values.first;
                          if (icons.isEmpty) return const SizedBox();
                          final icon = icons[index % icons.length];
                          final selected = icon == _icon;
                          return GestureDetector(
                            onTap: () => setState(() => _icon = icon),
                            child: Container(
                              width: 52,
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.surface,
                                borderRadius:
                                    BorderRadius.circular(AppBorderRadius.full),
                                border: Border.all(
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.borderLight,
                                  width: selected ? 2 : 1,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                icon,
                                style: const TextStyle(fontSize: 22),
                              ),
                            ),
                          );
                        },
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: AppSpacing.sm),
                        itemCount: (_iconSuggestions[_category] ?? _iconSuggestions.values.first).length,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Color', style: AppTextStyles.h3),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: colors
                          .map(
                            (color) => GestureDetector(
                              onTap: () => setState(() => _color = color),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _fromHex(color),
                                  borderRadius: BorderRadius.circular(
                                      AppBorderRadius.full),
                                  border: Border.all(
                                    color: _color == color
                                        ? AppColors.text
                                        : Colors.transparent,
                                    width: 3,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Frequency', style: AppTextStyles.h3),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      children: HabitFrequency.values
                          .map(
                            (f) => ChoiceChip(
                              label: Text(f.name[0].toUpperCase() +
                                  f.name.substring(1)),
                              selected: _frequency == f,
                              onSelected: (_) => setState(() => _frequency = f),
                            ),
                          )
                          .toList(),
                    ),
                    if (_frequency == HabitFrequency.custom) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text('Select Days', style: AppTextStyles.h3),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.xs,
                        children: List.generate(7, (index) {
                          final dayIndex = index + 1; // 1 = Monday
                          final isSelected =
                              _selectedWeekdays.contains(dayIndex);
                          final dayName =
                              ['M', 'T', 'W', 'T', 'F', 'S', 'S'][index];
                          return InkWell(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedWeekdays.remove(dayIndex);
                                } else {
                                  _selectedWeekdays.add(dayIndex);
                                }
                              });
                            },
                            borderRadius:
                                BorderRadius.circular(AppBorderRadius.full),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.surface,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.borderLight,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                dayName,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Target per day', style: AppTextStyles.h3),
                        Row(
                          children: [
                            IconButton(
                              onPressed: _targetCount > 1
                                  ? () => setState(() => _targetCount--)
                                  : null,
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text(
                              '$_targetCount',
                              style: AppTextStyles.h3,
                            ),
                            IconButton(
                              onPressed: () => setState(() => _targetCount++),
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppBorderRadius.md),
                          ),
                        ),
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                widget.habit != null
                                    ? 'Update Habit'
                                    : 'Create Habit',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Color _fromHex(String hex) {
    return Color(int.parse(hex.replaceFirst('#', '0xff')));
  }
}
