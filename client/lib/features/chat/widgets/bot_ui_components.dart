import 'package:a2ui_core/a2ui_core.dart';
import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:a2ui_flutter/basic_catalog.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/widgets.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';
import '../../integrations/app_logo.dart';
import 'chat_markdown.dart';

/// The basic A2UI catalog (D-086) with Casama's own look for the parts bots use most: buttons,
/// rows of buttons, text, choice chips and dividers. Everything else is the basic catalog's.
CatalogImplementation casamaUiCatalog({OpenUrlCallback? openUrl}) {
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
    'Column': swap(BasicComponents.column, _column),
  };
  return base.copyWith(components: [for (final c in base.components.values) own[c.name] ?? c]);
}

// Buttons: compact pills sized to their label.
Widget _button(BuildContext context, ComponentNode<ComponentImplementation> node, ComponentProps props, ChildWidgetBuilder buildChild) {
  final child = props.child('child');
  final scheme = context.colorScheme;
  final text0 = child == null ? const SizedBox.shrink() : buildChild(child);
  // A button that connects an app (D-256) carries the app's mark, tinted like the label.
  final app = _connectApp(node);
  final label = app == null
      ? text0
      : Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Builder(
              builder: (context) => SvgPicture.asset(
                'assets/apps/$app.svg',
                width: 17,
                height: 17,
                colorFilter: ColorFilter.mode(
                  IconTheme.of(context).color ?? DefaultTextStyle.of(context).style.color ?? scheme.onSurface,
                  BlendMode.srcIn,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(child: text0),
          ],
        );
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

/// The app a button connects ("app:connect" with an `app` in its context), when its mark is bundled.
String? _connectApp(ComponentNode<ComponentImplementation> node) {
  // The resolved props hold the action as a callback; its definition is on the component model.
  final raw = node.context?.componentModel.properties;
  if (raw case {'action': {'event': {'name': 'app:connect', 'context': {'app': final String app}}}}) {
    return hasBundledAppLogo(app) ? app : null;
  }
  return null;
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

// Choice chips get Casama's pill chips; lists get lettered rows (A, B, C…, D-256). Filterable
// pickers keep the basic look.
Widget _choicePicker(BuildContext context, ComponentNode<ComponentImplementation> node, ComponentProps props, ChildWidgetBuilder buildChild) {
  if (props.boolean('filterable') ?? false) {
    return BasicComponents.choicePicker.builder(context, node, props, buildChild);
  }
  final chips = props.string('displayStyle') == 'chips';
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
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      if (label != null) ...[
        chips
            ? Text(label, style: context.textTheme.labelLarge?.copyWith(color: context.colorScheme.onSurfaceVariant))
            // A list is a question: its label reads as the card's title.
            : Text(label, style: context.textTheme.titleMedium?.copyWith(fontFamily: AppFonts.sans, fontWeight: FontWeight.w700, height: 1.3)),
        SizedBox(height: chips ? AppSpace.xs : AppSpace.sm),
      ],
      if (chips)
        Wrap(
          spacing: AppSpace.xs,
          runSpacing: AppSpace.xs,
          children: [
            for (final (i, o) in options.indexed)
              _Chip(key: ValueKey(i), label: o.label, selected: selected.contains(o.value), onTap: binding == null ? null : () => toggle(o.value)),
          ],
        )
      else
        for (final (i, o) in options.indexed)
          _LetterOption(
            key: ValueKey(i),
            letter: String.fromCharCode(65 + i % 26),
            label: o.label,
            selected: selected.contains(o.value),
            onTap: binding == null ? null : () => toggle(o.value),
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


/// One answer in a list question (D-256): a letter in a small rounded square, then the answer.
/// Picked: the square fills with the accent.
class _LetterOption extends StatelessWidget {
  const _LetterOption({super.key, required this.letter, required this.label, required this.selected, required this.onTap});
  final String letter;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
          child: Row(
            children: [
              AnimatedContainer(
                duration: AppMotion.fast,
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? scheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: selected ? scheme.primary : scheme.outlineVariant),
                ),
                child: Text(
                  letter,
                  style: context.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: context.textTheme.bodyLarge?.copyWith(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// A column that asks two or more questions (choice lists or text fields) shows them one at a time
// (D-256): the question, dots for where you are, Skip and Next. Whatever comes after the last
// question (the submit button) shows on the last step. Anything else keeps the basic column.
Widget _column(BuildContext context, ComponentNode<ComponentImplementation> node, ComponentProps props, ChildWidgetBuilder buildChild) {
  final children = props.children('children').where((c) => !c.isPlaceholder).toList();
  final questions = [
    for (final (i, c) in children.indexed)
      if (c.type == 'ChoicePicker' || c.type == 'TextField') i,
  ];
  if (questions.length < 2) return BasicComponents.column.builder(context, node, props, buildChild);
  return _Steps(
    pages: [
      for (final (k, q) in questions.indexed)
        [for (var i = k == 0 ? 0 : questions[k - 1] + 1; i <= q; i++) children[i]],
    ],
    after: children.sublist(questions.last + 1),
    buildChild: buildChild,
  );
}

class _Steps extends StatefulWidget {
  const _Steps({required this.pages, required this.after, required this.buildChild});
  final List<List<ComponentNode<ComponentImplementation>>> pages;
  final List<ComponentNode<ComponentImplementation>> after;
  final ChildWidgetBuilder buildChild;

  @override
  State<_Steps> createState() => _StepsState();
}

class _StepsState extends State<_Steps> {
  var _page = 0;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final page = _page.clamp(0, widget.pages.length - 1);
    final last = page == widget.pages.length - 1;
    Widget node(ComponentNode<ComponentImplementation> c) => KeyedSubtree(key: NodeKey(c.instanceId), child: widget.buildChild(c));
    final dots = Semantics(
      label: context.l10n.formStep(page + 1, widget.pages.length),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          for (var i = 0; i < widget.pages.length; i++)
            AnimatedContainer(
              duration: AppMotion.fast,
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i == page ? scheme.onSurface : scheme.onSurfaceVariant.withValues(alpha: 0.35),
              ),
            ),
        ],
      ),
    );
    void go(int to) => setState(() => _page = to.clamp(0, widget.pages.length - 1));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: AppMotion.fast,
          child: Column(
            key: ValueKey(page),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpace.sm,
            children: [for (final c in widget.pages[page]) node(c)],
          ),
        ),
        const SizedBox(height: AppSpace.md),
        if (!last)
          Row(
            children: [
              dots,
              const Spacer(),
              FilledButton.tonal(
                key: const Key('formSkip'),
                onPressed: () => go(page + 1),
                style: const ButtonStyle(shape: WidgetStatePropertyAll(StadiumBorder())),
                child: Text(context.l10n.formSkip),
              ),
              const SizedBox(width: AppSpace.xs),
              FilledButton(
                key: const Key('formNext'),
                onPressed: () => go(page + 1),
                style: ButtonStyle(
                  shape: const WidgetStatePropertyAll(StadiumBorder()),
                  backgroundColor: WidgetStatePropertyAll(scheme.onSurface),
                  foregroundColor: WidgetStatePropertyAll(scheme.surface),
                ),
                child: Text(context.l10n.formNext),
              ),
            ],
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              dots,
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  spacing: AppSpace.xs,
                  children: [for (final c in widget.after) node(c)],
                ),
              ),
            ],
          ),
      ],
    );
  }
}
