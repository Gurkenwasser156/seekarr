import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Utility class for common routing operations.
class RouteUtils {
  /// Creates a CupertinoPage that supports iOS swipe-back gesture.
  /// This is the preferred way to enable back gesture on detail screens.
  static Page<void> cupertinoPage({
    required LocalKey key,
    required Widget child,
  }) {
    return CupertinoPage(key: key, child: child);
  }

  /// Creates a MaterialPage for standard Material navigation.
  static Page<void> materialPage({
    required LocalKey key,
    required Widget child,
  }) {
    return MaterialPage(key: key, child: child);
  }

  /// Creates a custom transition page with fade animation.
  /// NOTE: This transition does NOT support swipe-back gesture.
  static CustomTransitionPage<void> fadeTransitionPage({
    required LocalKey key,
    required Widget child,
  }) {
    return CustomTransitionPage(
      key: key,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }
}
