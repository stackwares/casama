import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/theme/app_theme.dart';
import 'package:casama_app/theme/appearance.dart';

void main() {
  void expectAccentSelection(ThemeData theme) {
    final primary = theme.colorScheme.primary;
    expect(theme.textSelectionTheme.cursorColor, primary);
    expect(theme.textSelectionTheme.selectionHandleColor, primary);
    expect(theme.textSelectionTheme.selectionColor, primary.withValues(alpha: 0.3));
  }

  testWidgets('text selection follows the accent in light and dark', (tester) async {
    expectAccentSelection(AppTheme.light());
    expectAccentSelection(AppTheme.dark());
    const blackWhite = Appearance(schemeId: 'blackWhite');
    expectAccentSelection(AppTheme.light(blackWhite));
    expectAccentSelection(AppTheme.dark(blackWhite));
  });

  testWidgets('selectable text gets the theme selection colour', (tester) async {
    final theme = AppTheme.dark();
    late Color selection;
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Builder(
          builder: (context) {
            selection = DefaultSelectionStyle.of(context).selectionColor!;
            return const SelectableText('hello');
          },
        ),
      ),
    );
    expect(selection, theme.colorScheme.primary.withValues(alpha: 0.3));
  });
}
