import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/habit.dart';
import 'add_habit_sheet.dart';
import '../providers/habit_provider.dart';
import '../theme/app_theme.dart';
import '../utils/habit_utils.dart';
import 'visuals/particle_burst.dart';

class HabitCard extends StatefulWidget {
  const HabitCard({
    super.key,
    required this.habit,
  });

  final Habit habit;

  @override
  State<HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends State<HabitCard> {
  bool _localIsCompleted = false;
  bool _isProcessingCompletion = false;
  bool _isDismissed = false;
  bool _showParticles = false;
  bool _isPressed = false;

  Future<void> _handleCompletion() async {
    // 1. Immediate Haptic & Visual Feedback
    await HapticFeedback.heavyImpact();

    // Update local state to trigger "complete" animation & Particles
    setState(() {
      _isProcessingCompletion = true;
      _localIsCompleted = true;
      _showParticles = true;
    });

    // 2. Wait for the "Glow & Scale" animation (approx 400ms)
    await Future.delayed(400.ms);

    if (!mounted) return;

    // 3. Start dismissal/exit animation
    setState(() {
      _isDismissed = true;
    });

    // 4. Wait for exit animation to finish before updating data
    await Future.delayed(300.ms);

    if (mounted) {
      final provider = context.read<HabitProvider>();
      final today = getTodayString();
      await provider.toggleHabitCompletion(widget.habit.id, today);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch for external updates
    final provider = context.watch<HabitProvider>();
    final entries = provider.habitEntries;
    final isCompletedInStore = isHabitCompletedToday(widget.habit.id, entries);

    // Sync local state if we are not currently animating a user action
    if (!_isProcessingCompletion) {
      _localIsCompleted = isCompletedInStore;
    }

    // If we have visually dismissed it, hide it to prevent layout jumps
    // Note: If the store updates and says "not completed" (e.g. undo), we should reappear?
    // For now, if dismissed locally, we stay hidden until parent rebuilds with new list order or we get recycled.
    // Ideally, the parent List would remove this item from the tree once the provider updates.
    if (_isDismissed) return const SizedBox.shrink();

    return Animate(
      key: ValueKey('habit_${widget.habit.id}'),
      effects: const [
        FadeEffect(
            duration: Duration(milliseconds: 600), curve: Curves.easeOutQuad),
        SlideEffect(
            begin: Offset(0, 0.1),
            end: Offset.zero,
            duration: Duration(milliseconds: 600),
            curve: Curves.easeOutCubic), // Smoother, less cartoonish
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (_) => AddHabitSheet(habit: widget.habit),
            );
          },
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedScale(
            scale: _isPressed ? 0.96 : 1.0,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeInOut,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                _SwipeableGlassCard(
                  habit: widget.habit,
                  isCompleted: _localIsCompleted,
                  onComplete: _handleCompletion,
                ),
                if (_showParticles)
                  Positioned(
                    right: 40,
                    child: ParticleBurst(
                      color: _fromHex(widget.habit.color),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SwipeableGlassCard extends StatefulWidget {
  const _SwipeableGlassCard({
    required this.habit,
    required this.isCompleted,
    required this.onComplete,
  });

  final Habit habit;
  final bool isCompleted;
  final VoidCallback onComplete;

  @override
  State<_SwipeableGlassCard> createState() => _SwipeableGlassCardState();
}

class _SwipeableGlassCardState extends State<_SwipeableGlassCard> {
  double _dragExtent = 0.0;
  final double _threshold = 100.0;

  int _lastHapticStep = 0;

  void _onDragUpdate(DragUpdateDetails details) {
    if (widget.isCompleted) return; // No dragging if already done

    setState(() {
      _dragExtent += details.delta.dx;
      // Clamp: allow some resistance on left (<0) but mainly right (>0)
      _dragExtent = _dragExtent.clamp(-20.0, 200.0);
    });

    // Haptics during drag
    final step = (_dragExtent / 20).floor();
    if (step > 0 && step != _lastHapticStep) {
      if (!widget.isCompleted) HapticFeedback.selectionClick();
      _lastHapticStep = step;
    }
  }

  void _onDragEnd(DragEndDetails details) {
    if (widget.isCompleted) return;

    if (_dragExtent >= _threshold) {
      // Swipe Successful
      widget.onComplete();
      // Visually keep it snapped to the right while we animate out
      setState(() {
        _dragExtent = 200.0;
      });
    } else {
      // Swipe Cancelled - Snap Back
      HapticFeedback.lightImpact();
      setState(() {
        _dragExtent = 0.0;
        _lastHapticStep = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _fromHex(widget.habit.color);

    return LayoutBuilder(builder: (context, constraints) {
      // Calculate progress 0.0 -> 1.0 based on drag
      final double opacity = (_dragExtent / _threshold).clamp(0.0, 1.0);

      return Stack(
        alignment: Alignment.centerLeft,
        children: [
          // BACKGROUND LAYER (The "Reveal" area)
          Container(
            height: 70, // Matches compact card height
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.transparent, // Fix "brown" field artifact
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  // Gradient Fill that follows the swipe
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: (constraints.maxWidth * opacity)
                        .clamp(0.0, constraints.maxWidth),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            accentColor.withOpacity(0.4),
                            accentColor.withOpacity(0.1),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Check Icon fixed on the left
                  Positioned(
                    left: 32,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Icon(
                        Icons.check_rounded,
                        color: accentColor.withOpacity(opacity.clamp(0.2, 1.0)),
                        size: 32 + (8 * opacity),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // FOREGROUND CARD (The Draggable)
          Transform.translate(
            offset: Offset(_dragExtent, 0),
            child: GestureDetector(
              onHorizontalDragStart: (_) {
                if (!widget.isCompleted) HapticFeedback.lightImpact();
              },
              onHorizontalDragUpdate: _onDragUpdate,
              onHorizontalDragEnd: _onDragEnd,
              child: Stack(
                children: [
                  // Hint Text behind the card (revealed by glass transparency or just visible on right)
                  if (!widget.isCompleted && _dragExtent == 0)
                    Positioned(
                      right: 16,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Text(
                          'Slide >>',
                          style: TextStyle(
                            color: AppColors.textSecondary.withOpacity(0.4),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                  _GlassHabitCardContent(
                    habit: widget.habit,
                    isCompleted: widget.isCompleted,
                  ).animate(target: widget.isCompleted ? 1 : 0).scale(
                        end: const Offset(0.98,
                            0.98), // Very subtle scale, or 1.0 if we want "normal"
                        curve: Curves.easeInOut,
                      ),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _GlassHabitCardContent extends StatelessWidget {
  const _GlassHabitCardContent({
    required this.habit,
    required this.isCompleted,
  });

  final Habit habit;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final accentColor = _fromHex(habit.color);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          // Card dimensions and padding - more compact
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.90),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.6),
              width: 1.0,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.95),
                Colors.white.withOpacity(0.85),
              ],
            ),
          ),
          child: Row(
            children: [
              // ICON
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  habit.icon,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
              const SizedBox(width: 12),

              // TEXT + META
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      habit.name,
                      style: AppTextStyles.h3.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.repeat_rounded,
                            size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          _getFrequencyLabel(habit),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          habit.category.toUpperCase(),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textTertiary,
                            fontSize: 9,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    if (isCompleted)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle,
                                size: 12, color: AppColors.success),
                            const SizedBox(width: 4),
                            Text(
                              'COMPLETED',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassChip extends StatelessWidget {
  const _GlassChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// Utility to parse color safely
Color _fromHex(String hex) {
  try {
    return Color(int.parse(hex.replaceFirst('#', '0xff')));
  } catch (e) {
    return AppColors.primary;
  }
}

String _getFrequencyLabel(Habit habit) {
  final count = habit.targetCount;
  switch (habit.frequency) {
    case HabitFrequency.daily:
      return '$count/day';
    case HabitFrequency.weekly:
      return '$count/week';
    case HabitFrequency.custom:
      if (habit.customDays != null && habit.customDays!.isNotEmpty) {
        return '$count on ${habit.customDays!.length} days';
      }
      return '$count x Custom';
  }
}
