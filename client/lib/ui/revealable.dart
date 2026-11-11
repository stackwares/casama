import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/widgets.dart';

/// A hidden field (a password, a key, a token) with an eye button to show what was typed:
/// [builder] gets whether to hide the text and the button to put at the field's end.
class Revealable extends StatefulWidget {
  const Revealable({super.key, required this.builder});
  final Widget Function(BuildContext context, bool hidden, Widget toggle) builder;

  @override
  State<Revealable> createState() => _RevealableState();
}

class _RevealableState extends State<Revealable> {
  var _hidden = true;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final toggle = IconButton(
      key: const Key('revealToggle'),
      tooltip: _hidden ? l10n.show : l10n.hide,
      icon: Icon(_hidden ? LucideIcons.eye : LucideIcons.eyeOff, size: 20),
      onPressed: () => setState(() => _hidden = !_hidden),
    );
    return widget.builder(context, _hidden, toggle);
  }
}
