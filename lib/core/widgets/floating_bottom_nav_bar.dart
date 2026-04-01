import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:seekarr/core/app_radius.dart';
import 'package:seekarr/core/app_spacing.dart';

/// A destination for the [FloatingBottomNavBar].
class FloatingNavDestination {
  /// The icon to display when this destination is not selected.
  final IconData icon;

  /// The icon to display when this destination is selected.
  final IconData selectedIcon;

  /// The label for this destination.
  final String label;

  const FloatingNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
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
  static const double bottomPadding = AppSpacing.md; // 12dp

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

/// A custom floating bottom navigation bar with rounded corners and modern styling.
///
/// Features:
/// - Floating design with margins on all sides
/// - Rounded corners using [AppRadius.xl]
/// - Scale animation for selected item
/// - Elastic drag animation (rubber band effect)
/// - No background indicator (only icon color changes)
/// - Subtle shadow for elevated appearance
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

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
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
          offset: _dragOffset,
          child: Container(
            height: FloatingNavBarMetrics.barHeight,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              borderRadius: AppRadius.borderRadiusXl,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              children: List.generate(widget.destinations.length, (index) {
                return Expanded(
                  child: _NavBarItem(
                    destination: widget.destinations[index],
                    isSelected: index == widget.selectedIndex,
                    onTap: () => widget.onDestinationSelected(index),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final FloatingNavDestination destination;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.destination,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final iconColor = isSelected
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;

    final labelColor = isSelected
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;

    final fontWeight = isSelected ? FontWeight.w600 : FontWeight.w500;

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.borderRadiusLg,
      splashColor: colorScheme.primary.withValues(alpha: 0.1),
      highlightColor: colorScheme.primary.withValues(alpha: 0.05),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with scale animation
          AnimatedScale(
            scale: isSelected ? 1.15 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? destination.selectedIcon : destination.icon,
                key: ValueKey(isSelected),
                color: iconColor,
                size: 24,
              ),
            ),
          ),
          const SizedBox(height: 2),
          // Label
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: fontWeight,
              color: labelColor,
            ),
            child: Text(
              destination.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
