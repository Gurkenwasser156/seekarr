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

  /// Safely parses an integer path parameter.
  static int? safeIntParam(GoRouterState state, String paramName) {
    return int.tryParse(state.pathParameters[paramName] ?? '');
  }

  /// Safely returns a typed extra value.
  static T? safeExtra<T>(GoRouterState state) {
    final extra = state.extra;
    return extra is T ? extra : null;
  }

  /// Creates a temporary redirect page.
  static Page<void> redirectPage({
    required LocalKey key,
    required String location,
  }) {
    return CupertinoPage(
      key: key,
      child: _RedirectWidget(location: location),
    );
  }
}

class _RedirectWidget extends StatefulWidget {
  const _RedirectWidget({required this.location});

  final String location;

  @override
  State<_RedirectWidget> createState() => _RedirectWidgetState();
}

class _RedirectWidgetState extends State<_RedirectWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.go(widget.location);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
