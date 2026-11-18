import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:intl/intl.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/widgets.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';
import '../../integrations/app_logo.dart';
import '../../../core/link_browser.dart';

/// What a card's own button does: an event with its values, and the label the chat shows for it.
typedef CardAction = void Function(
  String name,
  Map<String, Object?> values,
  String label,
);

/// One of Casama's own A2UI cards (D-337). Its props are read loosely (the server checks them,
/// D-337 `checkCard`), and a card with nothing valid to show draws nothing.
ComponentImplementation casamaCard(
  String name,
  List<String> props,
  Widget? Function(
    BuildContext context,
    Map<String, Object?> props,
    CardAction act,
  )
  build,
) => ComponentImplementation(
  name: name,
  schema: Schema.fromMap(<String, Object?>{
    'type': 'object',
    'properties': <String, Object?>{
      'component': <String, Object?>{'const': name},
      for (final p in props) p: const <String, Object?>{},
    },
    'required': const <Object?>['component'],
  }),
  builder: (context, node, resolved, buildChild) =>
      build(
        context,
        {for (final p in props) p: resolved.value(p)},
        (event, values, label) => node.context?.dispatchAction({
          'event': {'name': event, 'context': values, 'userMessage': label},
        }),
      ) ??
      const SizedBox.shrink(),
);

/// Text from a bot's value: trimmed, numbers as written, empty as null.
String? cardText(Object? v) {
  final s = switch (v) {
    final String s => s.trim(),
    final num n => n.toString(),
    _ => null,
  };
  return s == null || s.isEmpty ? null : s;
}

/// A list of rows (objects) from a bot's value.
List<Map<Object?, Object?>> cardRows(Object? v) => [
  if (v is List) ...v.whereType<Map<Object?, Object?>>(),
];

/// A list of strings from a bot's value.
List<String> cardTexts(Object? v) => [
  if (v is List)
    for (final x in v) ?cardText(x),
];

/// A bot's ISO time, in local time. One without a zone is already the person's own time.
DateTime? cardTime(Object? v) {
  final s = cardText(v);
  if (s == null) return null;
  final d = DateTime.tryParse(s);
  return d != null && d.isUtc ? d.toLocal() : d;
}

/// Whether [v] is a date with no time ("2026-11-20").
bool cardIsDateOnly(Object? v) => cardText(v)?.length == 10;

String cardClock(BuildContext context, DateTime d) =>
    TimeOfDay.fromDateTime(d).format(context);

String cardDay(BuildContext context, DateTime d) =>
    DateFormat.MMMEd(context.l10n.localeName).format(d);

/// "Thu, Nov 20" for another day, the time for today.
String cardWhen(BuildContext context, DateTime d) {
  final now = DateTime.now();
  final today = d.year == now.year && d.month == now.month && d.day == now.day;
  return today
      ? cardClock(context, d)
      : DateFormat.MMMd(context.l10n.localeName).format(d);
}

bool cardSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Opens a web address from a card in the browser; anything else is ignored.
Future<void> cardOpenUrl(String? url) async {
  final uri = url == null ? null : Uri.tryParse(url);
  if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) return;
  await openWebLink(uri);
}

/// A card's top line: an app mark or icon, the title, and a status pill.
class CardHeader extends StatelessWidget {
  const CardHeader({
    super.key,
    required this.title,
    this.app,
    this.icon,
    this.pill,
    this.pillColor,
  });
  final String title;
  final String? app;
  final IconData? icon;
  final String? pill;
  final Color? pillColor;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Row(
      children: [
        if (hasBundledAppLogo(app)) ...[
          AppLogo(appId: app, name: app!, size: 20),
          const SizedBox(width: AppSpace.xs),
        ] else if (icon != null) ...[
          Icon(icon, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: AppSpace.xs),
        ],
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.titleSmall?.copyWith(
              fontFamily: AppFonts.sans,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (pill != null) ...[
          const SizedBox(width: AppSpace.xs),
          CardPill(text: pill!, dot: pillColor ?? scheme.onSurfaceVariant),
        ],
      ],
    );
  }
}

/// A small rounded label with a dot, like "Ready to send".
class CardPill extends StatelessWidget {
  const CardPill({super.key, required this.text, this.dot});
  final String text;
  final Color? dot;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot != null) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: context.textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// The plain panel a card's content sits on, inside the chat card's fill.
class CardPanel extends StatelessWidget {
  const CardPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 14),
  });
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: context.colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.tile),
      border: Border.all(color: context.appColors.hairline),
    ),
    child: child,
  );
}

/// Rows on a panel with hairlines between them.
class CardRows extends StatelessWidget {
  const CardRows({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final (i, c) in children.indexed) ...[
        if (i > 0)
          Divider(height: 1, thickness: 1, color: context.appColors.hairline),
        c,
      ],
    ],
  );
}

enum CardButtonKind { primary, outlined, quiet }

/// A card's button: a compact pill like the chat's own buttons.
class CardButton extends StatelessWidget {
  const CardButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = CardButtonKind.outlined,
  });
  final String label;
  final VoidCallback? onPressed;
  final CardButtonKind kind;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(0, 38)),
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(
          horizontal: kind == CardButtonKind.quiet ? AppSpace.sm : AppSpace.md,
          vertical: AppSpace.xs,
        ),
      ),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: const WidgetStatePropertyAll(StadiumBorder()),
      textStyle: WidgetStatePropertyAll(
        context.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
      ),
      elevation: const WidgetStatePropertyAll(0),
    );
    final text = Text(label);
    return switch (kind) {
      CardButtonKind.primary => FilledButton(
        onPressed: onPressed,
        style: style,
        child: text,
      ),
      CardButtonKind.quiet => TextButton(
        onPressed: onPressed,
        style: style,
        child: text,
      ),
      CardButtonKind.outlined => OutlinedButton(
        onPressed: onPressed,
        style: style.copyWith(
          foregroundColor: WidgetStatePropertyAll(scheme.onSurface),
          side: WidgetStatePropertyAll(
            BorderSide(color: scheme.outlineVariant),
          ),
        ),
        child: text,
      ),
    };
  }
}

/// A row of card buttons that wraps on narrow screens.
class CardButtons extends StatelessWidget {
  const CardButtons({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpace.xs,
    runSpacing: AppSpace.xs,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: children,
  );
}

/// A card laid out the usual way: header, panel, then buttons, with even gaps.
class CardLayout extends StatelessWidget {
  const CardLayout({
    super.key,
    this.header,
    required this.body,
    this.buttons = const [],
  });
  final Widget? header;
  final Widget body;
  final List<Widget> buttons;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      if (header != null) ...[header!, const SizedBox(height: AppSpace.sm)],
      body,
      if (buttons.isNotEmpty) ...[
        const SizedBox(height: AppSpace.sm),
        CardButtons(children: buttons),
      ],
    ],
  );
}

/// An avatar: the picture when there is one, else the first letter of the name.
class CardAvatar extends StatelessWidget {
  const CardAvatar({super.key, required this.name, this.url, this.size = 32});
  final String name;
  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final letter = Text(
      name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase(),
      style: context.textTheme.labelLarge?.copyWith(
        color: scheme.onSecondaryContainer,
        fontWeight: FontWeight.w600,
      ),
    );
    final fallback = CircleAvatar(
      radius: size / 2,
      backgroundColor: scheme.secondaryContainer,
      child: letter,
    );
    final u = url;
    if (u == null || !u.startsWith('https://')) return fallback;
    return ClipOval(
      child: Image.network(
        u,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}

/// An icon and text on one line, for an event's time, place and guests.
class CardFact extends StatelessWidget {
  const CardFact({
    super.key,
    required this.icon,
    required this.text,
    this.maxLines = 2,
  });
  final IconData icon;
  final String text;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 15, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(width: AppSpace.xs),
          Expanded(
            child: Text(
              text,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
