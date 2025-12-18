import 'dart:async';
import 'package:flutter/material.dart';

/// A reusable, always-visible search bar widget for the top of screens.
///
/// Provides debounced text input, clear button, and Material 3 styling.
class SearchBarHeader extends StatefulWidget {
  /// Callback when the search query changes (debounced).
  final ValueChanged<String> onQueryChanged;

  /// Placeholder text for the search bar.
  final String hintText;

  /// Initial query value.
  final String? initialQuery;

  /// Debounce duration for search input.
  final Duration debounceDuration;

  const SearchBarHeader({
    super.key,
    required this.onQueryChanged,
    this.hintText = 'Search...',
    this.initialQuery,
    this.debounceDuration = const Duration(milliseconds: 400),
  });

  @override
  State<SearchBarHeader> createState() => _SearchBarHeaderState();
}

class _SearchBarHeaderState extends State<SearchBarHeader> {
  late final TextEditingController _controller;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounceDuration, () {
      widget.onQueryChanged(value.trim());
    });
  }

  void _clearQuery() {
    _controller.clear();
    widget.onQueryChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: SearchBar(
        controller: _controller,
        hintText: widget.hintText,
        onChanged: _onTextChanged,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
        ),
        trailing: [
          if (_controller.text.isNotEmpty)
            IconButton(icon: const Icon(Icons.clear), onPressed: _clearQuery),
        ],
        elevation: WidgetStateProperty.all(0),
        backgroundColor: WidgetStateProperty.all(
          colorScheme.surfaceContainerHighest,
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        ),
      ),
    );
  }
}
