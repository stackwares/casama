import 'package:a2ui_core/a2ui_core.dart';
import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:a2ui_flutter/basic_catalog.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';
import 'chat_markdown.dart';

/// The basic A2UI catalog (D-086) with Kasama's own look for the parts bots use most: buttons,
/// rows of buttons, text, choice chips and dividers. Everything else is the basic catalog's.
CatalogImplementation kasamaUiCatalog({OpenUrlCallback? openUrl}) {
  final base = basicCatalog(openUrl: openUrl);
  ComponentImplementation swap(ComponentImplementation c, ComponentWidgetBuilder builder) => ComponentImplementation(
    name: c.name,
    schema: c.schema,
    allowedParents: c.allowedParents,
    allowedChildren: c.allowedChildren,
    builder: builder,
  );
  final own = <String, ComponentImplementation>{
    'Button': swap(BasicComponents.button, _button),
    'Row': swap(BasicComponents.row, _row),
    'Text': swap(BasicComponents.text, _text),
    'ChoicePicker': swap(BasicComponents.choicePicker, _choicePicker),
    'Divider': swap(BasicComponents.divider, _divider),
  };
  return base.copyWith(components: [for (final c in base.components.values) own[c.name] ?? c]);
}

// Buttons: compact pills sized to their label.
Widget _button(BuildContext context, ComponentNode<ComponentImplementation> node, ComponentProps props, ChildWidgetBuilder buildChild) {
  final child = props.child('child');
  final scheme = context.colorScheme;
  final label = child == null ? const SizedBox.shrink() : buildChild(child);
  final VoidCallback? onPressed = props.isValid ? props.action('action') : null;
  final variant = props.string('variant');
  final text = context.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, height: 1.2);
  final style = ButtonStyle(
    minimumSize: const WidgetStatePropertyAll(Size(0, 38)),
    padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: variant == 'borderless' ? AppSpace.sm : AppSpace.md, vertical: AppSpace.xs)),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    visualDensity: VisualDensity.standard,
    shape: const WidgetStatePropertyAll(StadiumBorder()),
    textStyle: WidgetStatePropertyAll(text),
    elevation: const WidgetStatePropertyAll(0),
  );
  final Widget button = switch (variant) {
    'primary' => FilledButton(onPressed: onPressed, style: style, child: label),
    'borderless' => TextButton(onPressed: onPressed, style: style, child: label),
    _ => OutlinedButton(
      onPressed: onPressed,
      style: style.copyWith(
        foregroundColor: WidgetStatePropertyAll(scheme.onSurface),
        side: WidgetStatePropertyAll(BorderSide(color: scheme.outlineVariant)),
      ),
      child: label,
    ),
  };
  final reason = props.isValid ? null : props.validationErrors.firstOrNull;
  return reason == null ? button : Tooltip(message: reason, child: button);
}

// A row of only buttons wraps onto more lines instead of squeezing each label into an equal share.
Widget _row(BuildContext context, ComponentNode<ComponentImplementation> node, ComponentProps props, ChildWidgetBuilder buildChild) {
  final children = props.children('children').where((c) => !c.isPlaceholder).toList();
  final onlyButtons = children.isNotEmpty && children.every((c) => c.type == 'Button' && (ComponentProps(c.props.peek()).number('weight') ?? 0) <= 0);
  if (!onlyButtons) return BasicComponents.row.builder(context, node, props, buildChild);
  return Wrap(
    spacing: AppSpace.xs,
    runSpacing: AppSpace.xs,
    crossAxisAlignment: WrapCrossAlignment.center,
    alignment: switch (props.string('justify')) {
      'center' => WrapAlignment.center,
      'end' => WrapAlignment.end,
      'spaceBetween' => WrapAlignment.spaceBetween,
      _ => WrapAlignment.start,
    },
    children: [for (final c in children) KeyedSubtree(key: NodeKey(c.instanceId), child: buildChild(c))],
  );
}

final _headingLine = RegExp(r'^ {0,3}(#{1,6})[ \t]+(.*?)[ \t#]*$');
final _markdownSyntax = RegExp(r'[*_`\[>|]|^\s*[-+] |^\s*\d+\. ', multiLine: true);

// Text: card titles in the sans title style (no serif, no rule under them), body text sized for a
// card. Plain text inside a button keeps the button's own label style.
Widget _text(BuildContext context, ComponentNode<ComponentImplementation> node, ComponentProps props, ChildWidgetBuilder buildChild) {
  final text = (props.string('text') ?? '').trim();
  final tt = context.textTheme;
  final scheme = context.colorScheme;
  final title = tt.titleMedium?.copyWith(fontFamily: AppFonts.sans, fontWeight: FontWeight.w600, height: 1.3, color: scheme.onSurface);
  final variant = props.string('variant');
  switch (variant) {
    case 'h1' || 'h2' || 'h3':
      return Text(text, style: title?.copyWith(fontSize: 17));
    case 'h4' || 'h5':
      return Text(text, style: title);
    case 'caption':
      return Text(text, style: tt.bodySmall?.copyWith(color: scheme.onSurfaceVariant));
  }
  final lines = text.split('\n');
  final heading = _headingLine.firstMatch(lines.first);
  final rest = (heading == null ? text : lines.skip(1).join('\n')).trim();
  Widget body(String s) => _markdownSyntax.hasMatch(s)
      ? ChatMarkdown(data: s, selectable: false)
      // Null style: inherits the card's body style, or the label style inside a button.
      : Text(s);
  if (heading == null) return body(rest);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(heading[2]!, style: title),
      if (rest.isNotEmpty) ...[
        const SizedBox(height: 2),
        DefaultTextStyle.merge(style: TextStyle(color: scheme.onSurfaceVariant), child: body(rest)),
      ],
    ],
  );
}

Widget _divider(BuildContext context, ComponentNode<ComponentImplementation> node, ComponentProps props, ChildWidgetBuilder buildChild) =>
    props.string('axis') == 'vertical'
        ? LimitedBox(maxHeight: 24, child: VerticalDivider(width: 1, color: context.appColors.hairline))
        : Divider(height: AppSpace.sm, thickness: 1, color: context.appColors.hairline);

// Choice chips get Kasama's pill chips; checkbox and radio lists keep the basic look.
Widget _choicePicker(BuildContext context, ComponentNode<ComponentImplementation> node, ComponentProps props, ChildWidgetBuilder buildChild) {
  if (props.string('displayStyle') != 'chips' || (props.boolean('filterable') ?? false)) {
    return BasicComponents.choicePicker.builder(context, node, props, buildChild);
  }
  final options = <({String value, String label})>[
    for (final item in props.list('options'))
      if (item case final Map<Object?, Object?> o)
        if (o['value'] case final String value) (value: value, label: ComponentProps.asString(o['label']) ?? value),
  ];
  final selected = switch (props.value('value')) {
    final List<Object?> v => v.whereType<String>().toList(),
    final String v => [v],
    _ => const <String>[],
  };
  final binding = props.writable('value');
  final multiple = props.string('variant') == 'multipleSelection';
  void toggle(String value) {
    final next = !multiple
        ? [value]
        : selected.contains(value)
        ? [for (final v in selected) if (v != value) v]
        : [...selected, value];
    try {
      binding?.set(next);
    } on A2uiDataError catch (e) {
      debugPrint('bot ui choice: ${e.message}');
    }
  }

  final label = props.string('label');
  final error = props.validationErrors.firstOrNull;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      if (label != null) ...[
        Text(label, style: context.textTheme.labelLarge?.copyWith(color: context.colorScheme.onSurfaceVariant)),
        const SizedBox(height: AppSpace.xs),
      ],
      Wrap(
        spacing: AppSpace.xs,
        runSpacing: AppSpace.xs,
        children: [
          for (final (i, o) in options.indexed)
            _Chip(key: ValueKey(i), label: o.label, selected: selected.contains(o.value), onTap: binding == null ? null : () => toggle(o.value)),
        ],
      ),
      if (error != null) ...[
        const SizedBox(height: AppSpace.xxs),
        Text(error, style: context.textTheme.bodySmall?.copyWith(color: context.colorScheme.error)),
      ],
    ],
  );
}

class _Chip extends StatelessWidget {
  const _Chip({super.key, required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final fg = selected ? scheme.onPrimaryContainer : scheme.onSurface;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? scheme.primaryContainer : Colors.transparent,
        shape: StadiumBorder(side: BorderSide(color: selected ? scheme.primary.withValues(alpha: 0.5) : scheme.outlineVariant)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: AnimatedPadding(
            duration: AppMotion.fast,
            curve: AppMotion.curve,
            padding: EdgeInsetsDirectional.only(start: selected ? 10 : 14, end: 14, top: 8, bottom: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) ...[Icon(LucideIcons.check, size: 15, color: fg), const SizedBox(width: 6)],
                Text(label, style: context.textTheme.labelLarge?.copyWith(color: fg, fontWeight: selected ? FontWeight.w600 : FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
