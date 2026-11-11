import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import 'adaptive_modal.dart';
import 'app_card.dart';
import '../ui/glow_button.dart';

/// The body of a form shown with `showAdaptiveSheet`: an icon tile, title and a line of help,
/// fields with even spacing, then the actions. Phones get full-width buttons (main action first);
/// larger windows get a right-aligned row (main action last), as each platform expects.
class FormSheet extends StatelessWidget {
  const FormSheet({
    super.key,
    required this.title,
    required this.children,
    required this.submitLabel,
    required this.onSubmit,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.submitIcon,
    this.submitKey,
    this.cancelLabel,
    this.busy = false,
    this.destructive = false,
    this.footer,
    this.showCancel = true,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final List<Widget> children;
  final String submitLabel;
  final IconData? submitIcon;
  final Key? submitKey;

  /// Null disables the main action (invalid or incomplete form).
  final VoidCallback? onSubmit;
  final String? cancelLabel;
  final bool busy;
  final bool destructive;

  /// A line under the fields (why the button is disabled, a privacy note).
  final Widget? footer;

  /// False for one-button notices ("Close").
  final bool showCancel;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final compact = AppBreakpoints.of(MediaQuery.sizeOf(context).width) == WindowSize.compact;
    final tint = destructive ? scheme.error : (iconColor ?? scheme.primary);
    final style = destructive ? FilledButton.styleFrom(backgroundColor: scheme.error, foregroundColor: scheme.onError) : null;
    final submitChild = busy
        ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: destructive ? scheme.onError : scheme.onPrimary))
        : Text(submitLabel);
    final submit = submitIcon == null || busy
        ? GlowButton(key: submitKey, style: style, onPressed: busy ? null : onSubmit, child: submitChild)
        : GlowButton.icon(key: submitKey, style: style, onPressed: onSubmit, icon: Icon(submitIcon, size: 18), label: submitChild);
    final cancel = TextButton(
      onPressed: busy ? null : () => Navigator.of(context).maybePop(),
      child: Text(cancelLabel ?? MaterialLocalizations.of(context).cancelButtonLabel),
    );
    final actions = compact
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 50, child: submit),
              if (showCancel) ...[const SizedBox(height: AppSpace.xxs), SizedBox(height: 46, child: cancel)],
            ],
          )
        : OverflowBar(
            spacing: AppSpace.xs,
            alignment: MainAxisAlignment.end,
            overflowAlignment: OverflowBarAlignment.end,
            children: [
              if (showCancel) cancel,
              submit,
            ],
          );
    // The fields scroll; the actions stay pinned under them, so the main button is always in view
    // (short windows, long forms, a phone keyboard). A hairline shows only when there's more above.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: _EdgeScroll(
            padding: EdgeInsets.fromLTRB(AppSpace.xl, compact ? 0 : AppSpace.xs, AppSpace.xl, AppSpace.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (icon != null) ...[
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: tint.withValues(alpha: context.isDark ? 0.2 : 0.12),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        alignment: Alignment.center,
                        child: Icon(icon, color: tint, size: 22),
                      ),
                      const SizedBox(width: AppSpace.md),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3, height: 1.2)),
                          if (subtitle != null) ...[
                            const SizedBox(height: 4),
                            Text(subtitle!, style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant, height: 1.4)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                if (children.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.xl),
                  Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: AppSpace.md, children: children),
                ],
                if (footer != null) ...[const SizedBox(height: AppSpace.sm), footer!],
              ],
            ),
          ),
        ),
        Padding(padding: const EdgeInsets.fromLTRB(AppSpace.xl, AppSpace.sm, AppSpace.xl, AppSpace.lg), child: actions),
      ],
    );
  }
}

/// Scrolls [child] and draws a hairline at its bottom edge while more content is below.
class _EdgeScroll extends StatefulWidget {
  const _EdgeScroll({required this.child, required this.padding});
  final Widget child;
  final EdgeInsets padding;

  @override
  State<_EdgeScroll> createState() => _EdgeScrollState();
}

class _EdgeScrollState extends State<_EdgeScroll> {
  var _more = false;

  bool _onMetrics(ScrollMetrics m) {
    final more = m.extentAfter > 0.5;
    if (more != _more) WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? setState(() => _more = more) : null);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: _more ? context.appColors.hairline : Colors.transparent)),
      ),
      child: NotificationListener<ScrollMetricsNotification>(
        onNotification: (n) => _onMetrics(n.metrics),
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) => _onMetrics(n.metrics),
          child: SingleChildScrollView(keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag, padding: widget.padding, child: widget.child),
        ),
      ),
    );
  }
}

/// A muted line that explains a disabled button or adds a note under a form.
class FormNote extends StatelessWidget {
  const FormNote(this.text, {super.key, this.icon = LucideIcons.info, this.color});
  final String text;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.colorScheme.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 16, color: c),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text, style: context.textTheme.bodySmall?.copyWith(color: c, height: 1.35)),
        ),
      ],
    );
  }
}

/// A switch row styled like the form's fields: hairline border, title, help line.
class FormSwitch extends StatelessWidget {
  const FormSwitch({super.key, required this.title, required this.value, required this.onChanged, this.subtitle, this.icon});
  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(color: context.appColors.hairline),
    );
    return Material(
      color: context.isDark ? scheme.surfaceContainer : scheme.surfaceContainerLowest,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        shape: shape,
        contentPadding: const EdgeInsets.fromLTRB(16, 4, 12, 4),
        secondary: icon == null ? null : Icon(icon, color: scheme.onSurfaceVariant),
        title: Text(title, style: context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: subtitle == null ? null : Text(subtitle!, style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant, height: 1.35)),
      ),
    );
  }
}

/// Asks for one line of text (rename, invite by email) in an adaptive form.
Future<String?> showTextPrompt(
  BuildContext context, {
  required String title,
  required String label,
  required String submitLabel,
  String initial = '',
  String? subtitle,
  String? hint,
  IconData? icon,
  IconData? fieldIcon,
  TextInputType? keyboardType,
  Key? fieldKey,
}) {
  return showAdaptiveSheet<String>(
    context: context,
    builder: (_) => _TextPrompt(
      title: title,
      label: label,
      submitLabel: submitLabel,
      initial: initial,
      subtitle: subtitle,
      hint: hint,
      icon: icon,
      fieldIcon: fieldIcon,
      keyboardType: keyboardType,
      fieldKey: fieldKey,
    ),
  );
}

class _TextPrompt extends StatefulWidget {
  const _TextPrompt({
    required this.title,
    required this.label,
    required this.submitLabel,
    required this.initial,
    this.subtitle,
    this.hint,
    this.icon,
    this.fieldIcon,
    this.keyboardType,
    this.fieldKey,
  });
  final String title;
  final String label;
  final String submitLabel;
  final String initial;
  final String? subtitle;
  final String? hint;
  final IconData? icon;
  final IconData? fieldIcon;
  final TextInputType? keyboardType;
  final Key? fieldKey;

  @override
  State<_TextPrompt> createState() => _TextPromptState();
}

class _TextPromptState extends State<_TextPrompt> {
  late final _c = TextEditingController(text: widget.initial);

  @override
  void initState() {
    super.initState();
    // Typing through the controller (including a paste) has to enable the button. onChanged
    // alone misses some of those updates.
    _c.addListener(_onText);
  }

  void _onText() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _c.removeListener(_onText);
    _c.dispose();
    super.dispose();
  }

  void _submit() {
    if (_c.text.trim().isNotEmpty) Navigator.pop(context, _c.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return FormSheet(
      icon: widget.icon,
      title: widget.title,
      subtitle: widget.subtitle,
      submitLabel: widget.submitLabel,
      onSubmit: _c.text.trim().isEmpty ? null : _submit,
      children: [
        TextField(
          key: widget.fieldKey,
          controller: _c,
          autofocus: true,
          keyboardType: widget.keyboardType,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            prefixIcon: widget.fieldIcon == null ? null : Icon(widget.fieldIcon, size: 20),
          ),
          onSubmitted: (_) => _submit(),
        ),
      ],
    );
  }
}

/// One option in [showChoiceSheet].
class Choice<T> {
  const Choice({required this.value, required this.label, this.subtitle, this.icon});
  final T value;
  final String label;
  final String? subtitle;
  final IconData? icon;
}

/// Picks one of a few options in an adaptive sheet (a dialog on larger windows), with the current
/// one checked. Returns the chosen [Choice], or null when dismissed (so a null value can be chosen).
Future<Choice<T>?> showChoiceSheet<T>(
  BuildContext context, {
  required String title,
  required List<Choice<T>> choices,
  required T selected,
  String? subtitle,
  IconData? icon,
}) {
  return showAdaptiveSheet<Choice<T>>(
    context: context,
    builder: (context) {
      final scheme = context.colorScheme;
      return SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(AppSpace.xl, 0, AppSpace.xl, AppSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (icon != null) ...[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: context.isDark ? 0.2 : 0.12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, color: scheme.primary, size: 22),
                  ),
                  const SizedBox(width: AppSpace.md),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3, height: 1.2)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(subtitle, style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant, height: 1.4)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.lg),
            GroupedCard(
              children: [
                for (final c in choices)
                  GroupedTile(
                    icon: c.icon ?? LucideIcons.circle,
                    title: c.label,
                    subtitle: c.subtitle,
                    onTap: () => Navigator.of(context).pop(c),
                    trailing: c.value == selected ? Icon(LucideIcons.check, color: scheme.primary) : const SizedBox(width: 24),
                  ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
