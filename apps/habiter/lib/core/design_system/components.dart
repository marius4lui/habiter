import 'package:flutter/material.dart';

import 'tokens.dart';

/// Keeps phone layouts comfortably readable and prevents tablet layouts from
/// becoming a single, over-stretched column.
class HabiterContent extends StatelessWidget {
  const HabiterContent({
    super.key,
    required this.child,
    this.maxWidth = HabiterSize.contentMax,
    this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 112),
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Padding(padding: padding, child: child),
    ),
  );
}

class HabiterSectionHeader extends StatelessWidget {
  const HabiterSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleLarge),
              if (subtitle != null) ...[
                const SizedBox(height: HabiterSpace.xs),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

class HabiterSurface extends StatelessWidget {
  const HabiterSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(HabiterSpace.md),
    this.color,
    this.borderRadius = HabiterRadius.card,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final double borderRadius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .7)),
    );
    return Material(
      color: color ?? scheme.surfaceContainerLow,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class HabiterPageIntro extends StatelessWidget {
  const HabiterPageIntro({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow.toUpperCase(),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: HabiterSpace.sm),
              Text(title, style: theme.textTheme.headlineLarge),
              const SizedBox(height: HabiterSpace.sm),
              Text(
                subtitle,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: HabiterSpace.sm),
          trailing!,
        ],
      ],
    );
  }
}

class HabiterEmptyState extends StatelessWidget {
  const HabiterEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.action,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return HabiterSurface(
      padding: const EdgeInsets.all(HabiterSpace.xl),
      child: Column(
        children: [
          Icon(icon, size: 42, color: theme.colorScheme.primary),
          const SizedBox(height: HabiterSpace.md),
          Text(
            title,
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: HabiterSpace.sm),
          Text(
            body,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[
            const SizedBox(height: HabiterSpace.lg),
            action!,
          ],
        ],
      ),
    );
  }
}

extension HabiterColorParsing on String {
  Color get asHabiterColor {
    final normalized = replaceFirst('#', '');
    final value = normalized.length == 6 ? 'ff$normalized' : normalized;
    return Color(int.tryParse(value, radix: 16) ?? 0xff356859);
  }
}
