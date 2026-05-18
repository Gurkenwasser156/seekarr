import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:seekarr/core/widgets/interactive_search_sheet.dart';

void main() {
  group('InteractiveSearchSheet.showAsync', () {
    testWidgets('cancels the in-flight fetch when the sheet is dismissed', (
      tester,
    ) async {
      final completer = Completer<List<dynamic>>();
      final navigatorKey = GlobalKey<NavigatorState>();
      CancelToken? capturedToken;

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: _InteractiveSearchSheetLauncher(
            fetchReleases: (token) {
              capturedToken = token;
              return completer.future;
            },
          ),
        ),
      );
      await _pumpSheetEntrance(tester);

      expect(find.text('Searching for releases...'), findsOneWidget);
      expect(capturedToken, isNotNull);
      expect(capturedToken!.isCancelled, isFalse);

      navigatorKey.currentState!.pop();
      await tester.pumpAndSettle();

      expect(capturedToken!.isCancelled, isTrue);
      expect(find.text('LauncherPage'), findsOneWidget);

      completer.complete(const []);
      await tester.pump();
    });

    testWidgets('suppresses fetch errors after the sheet is dismissed', (
      tester,
    ) async {
      final completer = Completer<List<dynamic>>();
      final navigatorKey = GlobalKey<NavigatorState>();
      CancelToken? capturedToken;

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: _InteractiveSearchSheetLauncher(
            fetchReleases: (token) {
              capturedToken = token;
              return completer.future;
            },
          ),
        ),
      );
      await _pumpSheetEntrance(tester);

      navigatorKey.currentState!.pop();
      await tester.pumpAndSettle();

      completer.completeError(Exception('boom'));
      await tester.pump();

      expect(capturedToken, isNotNull);
      expect(capturedToken!.isCancelled, isTrue);
      expect(find.textContaining('Failed to load releases'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}

Future<void> _pumpSheetEntrance(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

class _InteractiveSearchSheetLauncher extends StatefulWidget {
  const _InteractiveSearchSheetLauncher({required this.fetchReleases});

  final Future<List<dynamic>> Function(CancelToken token) fetchReleases;

  @override
  State<_InteractiveSearchSheetLauncher> createState() =>
      _InteractiveSearchSheetLauncherState();
}

class _InteractiveSearchSheetLauncherState
    extends State<_InteractiveSearchSheetLauncher> {
  bool _opened = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_opened) return;
    _opened = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      InteractiveSearchSheet.showAsync(
        context: context,
        title: 'Interactive Search',
        fetchReleases: widget.fetchReleases,
        onGrabRelease: (_, __) async {},
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('LauncherPage')));
  }
}
