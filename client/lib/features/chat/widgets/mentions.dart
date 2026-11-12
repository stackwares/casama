import 'package:casama_sdk/casama_sdk.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:markdown_widget/markdown_widget.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/widgets.dart';
import '../../../theme/app_colors.dart';
import '../../../ui/bot_avatar.dart';
import '../../groups/group_chats.dart' show GroupAvatar;

/// The bots a group chat (D-118) can @mention, for the messages in it: `@Name` and `@everyone`
/// show bold in a soft pill with the bot's icon, and tapping a bot's opens its profile. Only
/// members' names count, so an email address or a stray "@" stays plain text.
class MentionScope extends InheritedWidget {
  MentionScope({
    super.key,
    required List<Bot> bots,
    this.onOpen,
    required super.child,
  }) : bots = List.unmodifiable(bots);

  final List<Bot> bots;

  /// Opens a mentioned bot (its profile).
  final ValueChanged<Bot>? onOpen;

  static MentionScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MentionScope>();

  /// The words that mean the whole group, as the server reads them.
  static const everyoneWords = {'everyone', 'all', 'team'};

  late final RegExp pattern = mentionPattern(bots.map((b) => b.name));

  /// The member [name] names (any case), or null for everyone.
  Bot? botNamed(String name) {
    final lower = name.toLowerCase();
    return bots.where((b) => b.name.toLowerCase() == lower).firstOrNull;
  }

  /// A key that changes when what the mentions look like changes.
  String get signature =>
      [for (final b in bots) '${b.id}|${b.name}|${b.avatarUrl}'].join(',');

  @override
  bool updateShouldNotify(MentionScope old) => old.signature != signature;
}

/// `@everyone`, `@all`, `@team` or `@<name>` for these names: not inside a word or an email
/// address, and not followed by more of a word. Longer names first, so "@Ada Lovelace" wins over
/// "@Ada".
RegExp mentionPattern(Iterable<String> names) {
  final words = {
    ...MentionScope.everyoneWords,
    for (final n in names)
      if (n.trim().isNotEmpty) n.trim(),
  }.toList()..sort((a, b) => b.length - a.length);
  return RegExp(
    '(?<![\\w@.])@(${words.map(RegExp.escape).join('|')})(?![\\w])',
    caseSensitive: false,
  );
}

/// [text] with each mention as a pill, for a plain-text message.
List<InlineSpan> mentionSpans(
  MentionScope scope,
  String text,
  TextStyle? style,
) {
  final spans = <InlineSpan>[];
  var at = 0;
  for (final m in scope.pattern.allMatches(text)) {
    if (m.start > at) spans.add(TextSpan(text: text.substring(at, m.start)));
    spans.add(mentionSpan(scope, m[1]!, style));
    at = m.end;
  }
  if (at < text.length) spans.add(TextSpan(text: text.substring(at)));
  return spans;
}

/// One mention, sitting on the line like a word.
InlineSpan mentionSpan(MentionScope scope, String name, TextStyle? style) {
  final bot = scope.botNamed(name);
  return WidgetSpan(
    alignment: PlaceholderAlignment.middle,
    child: MentionChip(
      label: bot?.name ?? name.toLowerCase(),
      bot: bot,
      everyone: scope.bots,
      style: style,
      onTap: bot == null || scope.onOpen == null
          ? null
          : () => scope.onOpen!(bot),
    ),
  );
}

/// `@Name` in bold beside the bot's icon (the group's for everyone), on a pill in the bot's color.
class MentionChip extends StatelessWidget {
  const MentionChip({
    super.key,
    required this.label,
    this.bot,
    this.everyone = const [],
    this.style,
    this.onTap,
  });
  final String label;

  /// The bot mentioned, or null for everyone.
  final Bot? bot;
  final List<Bot> everyone;
  final TextStyle? style;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final base = style ?? DefaultTextStyle.of(context).style;
    final fontSize = base.fontSize ?? 16;
    final icon = (fontSize * 1.05).roundToDouble();
    final tint = bot == null ? scheme.primary : botPalette(bot!.name).first;
    final chip = DecoratedBox(
      decoration: BoxDecoration(
        color: tint.withValues(alpha: context.isDark ? 0.24 : 0.13),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(2, 1, fontSize * 0.45, 1),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 3,
          children: [
            ExcludeSemantics(
              child: bot != null
                  ? BotAvatar(
                      name: bot!.name,
                      avatar: bot!.avatarUrl,
                      size: icon,
                      animate: false,
                    )
                  : GroupAvatar(
                      bots: everyone,
                      size: icon,
                      ringColor: Color.alphaBlend(
                        tint.withValues(alpha: 0.13),
                        scheme.surface,
                      ),
                    ),
            ),
            Text(
              '@$label',
              style: base.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.25,
                color: scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
    if (onTap == null) {
      return Semantics(
        label: '@$label',
        child: ExcludeSemantics(child: chip),
      );
    }
    return Semantics(
      button: true,
      label: context.l10n.mentionOpenProfile('@$label'),
      child: ExcludeSemantics(
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            key: Key('mention-${bot!.id}'),
            onTap: onTap,
            child: chip,
          ),
        ),
      ),
    );
  }
}

// --- In Markdown replies ----------------------------------------------------------------------

const _tag = 'casamaMention';

class _MentionSyntax extends md.InlineSyntax {
  _MentionSyntax(RegExp pattern) : super(pattern.pattern, caseSensitive: false);

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text(_tag, match[1]!));
    return true;
  }
}

class _MentionNode extends SpanNode {
  _MentionNode(this.scope, this.name, this.paragraph);
  final MentionScope scope;
  final String name;
  final TextStyle paragraph;

  @override
  InlineSpan build() => mentionSpan(scope, name, parentStyle ?? paragraph);
}

/// A Markdown generator that draws group mentions as pills (see [MentionScope]).
MarkdownGenerator mentionMarkdownGenerator(MentionScope scope) =>
    MarkdownGenerator(
      inlineSyntaxList: [_MentionSyntax(scope.pattern)],
      generators: [
        SpanNodeGeneratorWithTag(
          tag: _tag,
          generator: (e, config, visitor) =>
              _MentionNode(scope, e.textContent, config.p.textStyle),
        ),
      ],
    );

@visibleForTesting
List<String> mentionsIn(MentionScope scope, String text) => [
  for (final m in scope.pattern.allMatches(text)) m[1]!,
];
