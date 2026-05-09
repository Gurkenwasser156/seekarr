import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:seekarr/core/app_animation.dart';
import 'package:seekarr/core/app_radius.dart';
import 'package:seekarr/core/app_spacing.dart';
import 'package:seekarr/core/theme.dart';

/// A destination for the [FloatingBottomNavBar].
class FloatingNavDestination {
  /// The icon to display when this destination is not selected.
  final IconData icon;

  /// The icon to display when this destination is selected.
  final IconData selectedIcon;

  /// The label for this destination.
  final String label;

  /// Accent color used for the selected pill.
  final Color accentColor;

  const FloatingNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.accentColor,
  });
}

/// Constants for FloatingBottomNavBar dimensions.
///
/// Use [FloatingNavBarMetrics.totalHeight] to calculate content padding.
class FloatingNavBarMetrics {
  FloatingNavBarMetrics._();

  /// Height of the nav bar itself.
  static const double barHeight = 60.0;

  /// Top padding above the nav bar.
  static const double topPadding = AppSpacing.sm; // 8dp

  /// Bottom padding below the nav bar (excluding safe area).
  static const double bottomPadding = AppSpacing.sm; // md=12dp

  /// Total height including top/bottom padding (excluding safe area).
  /// Use this value to add bottom padding to screen content.
  static const double totalHeight =
      barHeight + topPadding + bottomPadding; // 60 + 8 + 12 = 80dp

  /// Returns the bottom padding needed for scroll views to allow content
  /// to scroll above the floating nav bar.
  ///
  /// Includes the nav bar height, margins, and device safe area.
  static double getScrollViewBottomPadding(BuildContext context) {
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;
    return totalHeight + bottomSafeArea;
  }
}

/// A custom floating bottom navigation bar with rounded corners and glass styling.
///
/// Features:
/// - Floating design with margins on all sides
/// - Rounded corners using [AppRadius.xl]
/// - Compact selected pill with per-destination accent color
/// - Elastic drag animation (rubber band effect)
/// - Glass surface with backdrop blur
///
/// Example usage:
/// ```dart
/// FloatingBottomNavBar(
///   selectedIndex: 0,
///   onDestinationSelected: (index) => print('Selected: $index'),
///   destinations: [
///     FloatingNavDestination(
///       icon: Icons.home_outlined,
///       selectedIcon: Icons.home,
///       label: 'Home',
///       accentColor: Colors.indigo,
///     ),
///   ],
/// )
/// ```
class FloatingBottomNavBar extends StatefulWidget {
  /// The index of the currently selected destination.
  final int selectedIndex;

  /// Called when one of the destinations is selected.
  final ValueChanged<int> onDestinationSelected;

  /// The list of destinations to display.
  final List<FloatingNavDestination> destinations;

  const FloatingBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  @override
  State<FloatingBottomNavBar> createState() => _FloatingBottomNavBarState();
}

class _FloatingBottomNavBarState extends State<FloatingBottomNavBar>
    with SingleTickerProviderStateMixin {
  /// Current drag offset from original position.
  Offset _dragOffset = Offset.zero;

  /// Animation controller for spring-back animation.
  late AnimationController _springController;

  /// Animation for returning to original position.
  Animation<Offset>? _springAnimation;

  // === Elastic drag physics parameters ===

  /// Maximum allowed drag distance in any direction.
  static const double _maxDragDistance = 15.0;

  /// Base resistance factor (lower = more rigid).
  static const double _baseResistance = 0.15;

  /// Controls how quickly resistance increases with distance.
  static const double _resistanceFalloff = 30.0;

  static const double _barHorizontalPadding = 6.0;
  static const double _barVerticalPadding = 6.0;
  static const double _blurSigma = 24.0;

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: AppAnimation.durationXl,
    );
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  /// Applies elastic resistance to drag delta.
  ///
  /// Resistance increases as offset grows, creating a "rubber band" feel.
  double _applyElasticResistance(double delta, double currentOffset) {
    // Resistance increases exponentially as we get further from origin
    final resistance =
        _baseResistance / (1 + (currentOffset.abs() / _resistanceFalloff));
    return delta * resistance;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    // Stop any running spring animation
    if (_springController.isAnimating) {
      _springController.stop();
    }

    setState(() {
      // Apply elastic resistance to both axes
      final dx = _applyElasticResistance(details.delta.dx, _dragOffset.dx);
      final dy = _applyElasticResistance(details.delta.dy, _dragOffset.dy);

      _dragOffset += Offset(dx, dy);

      // Clamp to maximum drag distance
      _dragOffset = Offset(
        _dragOffset.dx.clamp(-_maxDragDistance, _maxDragDistance),
        _dragOffset.dy.clamp(-_maxDragDistance, _maxDragDistance),
      );
    });
  }

  void _onPanEnd(DragEndDetails details) {
    // Animate back to original position with elastic curve
    _springAnimation = Tween<Offset>(begin: _dragOffset, end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _springController, curve: Curves.elasticOut),
        );

    _springAnimation!.addListener(_onSpringAnimation);
    _springController.forward(from: 0).whenComplete(() {
      _springAnimation?.removeListener(_onSpringAnimation);
    });
  }

  void _onSpringAnimation() {
    if (_springAnimation != null) {
      setState(() {
        _dragOffset = _springAnimation!.value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isDark = colorScheme.brightness == Brightness.dark;
    final glassColor = colorScheme.surfaceContainer.withValues(
      alpha: isDark ? 0.72 : 0.55,
    );
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : colorScheme.outline.withValues(alpha: 0.85);
    final selectedDestination =
        widget.selectedIndex >= 0 &&
            widget.selectedIndex < widget.destinations.length
        ? widget.destinations[widget.selectedIndex]
        : null;

    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      behavior: HitTestBehavior.opaque,
      child: Container(
        // Outer padding to make it float
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          bottom: bottomPadding + FloatingNavBarMetrics.bottomPadding,
          top: FloatingNavBarMetrics.topPadding,
        ),
        child: Transform.translate(
          key: const ValueKey('floating-nav-drag-transform'),
          offset: _dragOffset,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: AppRadius.borderRadiusXl,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.18),
                  blurRadius: 32,
                  offset: const Offset(0, 8),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: isDark ? 0.07 : 0.55),
                  blurRadius: 0,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: AppRadius.borderRadiusXl,
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: _blurSigma,
                  sigmaY: _blurSigma,
                ),
                child: Container(
                  height: FloatingNavBarMetrics.barHeight,
                  decoration: BoxDecoration(
                    color: glassColor,
                    borderRadius: AppRadius.borderRadiusXl,
                    border: Border.all(color: borderColor),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: _barHorizontalPadding,
                    vertical: _barVerticalPadding,
                  ),
                  child: SizedBox.expand(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (selectedDestination != null)
                          IgnorePointer(
                            child: _NavBarIndicator(
                              selectedIndex: widget.selectedIndex,
                              destinations: widget.destinations,
                              selectedDestination: selectedDestination,
                            ),
                          ),
                        Row(
                          children: List.generate(widget.destinations.length, (
                            index,
                          ) {
                            return Expanded(
                              child: _NavBarItem(
                                destination: widget.destinations[index],
                                isSelected: index == widget.selectedIndex,
                                onTap: () =>
                                    widget.onDestinationSelected(index),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarIndicator extends StatelessWidget {
  final int selectedIndex;
  final List<FloatingNavDestination> destinations;
  final FloatingNavDestination selectedDestination;

  const _NavBarIndicator({
    required this.selectedIndex,
    required this.destinations,
    required this.selectedDestination,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final accentColor = selectedDestination.accentColor;
    final activeBackground = accentColor.withValues(
      alpha: isDark ? 0.16 : 0.13,
    );
    final activeBorder = accentColor.withValues(alpha: 0.27);

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth / destinations.length;
        // Cap the pill width to the slot width so it never bleeds outside its
        // slot and always aligns with the item content (which is also capped to
        // slot_width by the Expanded + Center layout constraints).
        final indicatorWidth = _NavBarItem.indicatorWidthFor(
          selectedDestination,
        ).clamp(0.0, itemWidth);
        final left =
            (itemWidth * selectedIndex) + ((itemWidth - indicatorWidth) / 2);

        return Stack(
          children: [
            AnimatedPositioned(
              duration: AppAnimation.durationSm,
              curve: AppAnimation.emphasizedCurve,
              left: left,
              top: (constraints.maxHeight - _NavBarItem._pillHeight) / 2,
              width: indicatorWidth,
              height: _NavBarItem._pillHeight,
              child: DecoratedBox(
                key: const ValueKey('floating-nav-indicator'),
                decoration: BoxDecoration(
                  color: activeBackground,
                  borderRadius: BorderRadius.circular(_NavBarItem.itemRadius),
                  border: Border.all(color: activeBorder),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _NavBarItem extends StatelessWidget {
  static const double _iconSize = 20.0;
  static const double _itemHorizontalPadding = 14.0;
  static const double itemRadius = 20.0;
  static const double _labelGap = 6.0;
  static const double _selectedLabelFontSize = 12.0;

  /// Height of the animated selection pill — shorter than the full inner bar
  /// height so the highlight feels proportionate rather than filling the bar.
  static const double _pillHeight = 36.0;

  final FloatingNavDestination destination;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.destination,
    required this.isSelected,
    required this.onTap,
  });

  static double indicatorWidthFor(FloatingNavDestination destination) {
    final painter = TextPainter(
      text: TextSpan(
        text: destination.label,
        style: const TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: _selectedLabelFontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.12,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();

    return _itemHorizontalPadding * 2 + _iconSize + _labelGap + painter.width;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = destination.accentColor;

    final itemColor = isSelected ? accentColor : colorScheme.onSurfaceVariant;

    return Semantics(
      key: ValueKey('floating-nav-item-${destination.label.toLowerCase()}'),
      button: true,
      container: true,
      excludeSemantics: true,
      label: destination.label,
      selected: isSelected,
      enabled: true,
      onTap: onTap,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: Center(
            child: AnimatedScale(
              scale: isSelected ? 1.02 : 1.0,
              duration: AppAnimation.durationXs,
              curve: AppAnimation.emphasizedCurve,
              child: AnimatedContainer(
                duration: AppAnimation.durationSm,
                curve: AppAnimation.emphasizedCurve,
                constraints: const BoxConstraints(minWidth: 48),
                padding: const EdgeInsets.symmetric(
                  horizontal: _itemHorizontalPadding,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(itemRadius),
                  border: Border.all(color: Colors.transparent),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedSwitcher(
                      duration: AppAnimation.durationSm,
                      child: Icon(
                        isSelected
                            ? destination.selectedIcon
                            : destination.icon,
                        key: ValueKey(isSelected),
                        color: itemColor,
                        size: _iconSize,
                      ),
                    ),
                    AnimatedSize(
                      duration: AppAnimation.durationSm,
                      curve: AppAnimation.emphasizedCurve,
                      alignment: Alignment.centerLeft,
                      child: isSelected
                          ? Padding(
                              padding: const EdgeInsets.only(left: _labelGap),
                              child: AnimatedDefaultTextStyle(
                                duration: AppAnimation.durationSm,
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: _selectedLabelFontSize,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.12,
                                  color: itemColor,
                                ),
                                child: Text(
                                  destination.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
