import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:markdown_widget/markdown_widget.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/backend.dart' show MessageAppMention;
import '../../../core/widgets.dart';
import '../../../theme/app_colors.dart';
import '../../../ui/bot_avatar.dart';
import '../../groups/group_chats.dart' show GroupAvatar;
import '../../integrations/app_logo.dart';

/// An app that can appear as an `@App` pill in a chat message (D-434).
class AppMentionInfo {
  const AppMentionInfo({
    required this.integrationId,
    required this.label,
    this.toolkit,
    this.appId,
    this.color,
    this.kind,
    this.removed = false,
  });

  final String integrationId;
  final String label;
  final String? toolkit;
  final String? appId;
  final String? color;
  final IntegrationKind? kind;

  /// True when the underlying integration was removed/disconnected from the workspace.
  final bool removed;

  Iterable<String> get matchTerms sync* {
    if (label.trim().isNotEmpty) yield label.trim();
    if (toolkit != null && toolkit!.trim().isNotEmpty) {
      yield toolkit!.trim();
      yield toolkit!.trim().replaceAll('_', '-');
    }
    if (appId != null && appId!.trim().isNotEmpty) {
      yield appId!.trim();
      yield appId!.trim().replaceAll('_', '-');
    }
  }
}

/// The bots (D-118) and apps (D-434) a chat can @mention, for the messages in it: `@Name`,
/// `@everyone`, and `@App` show bold in a soft pill with an icon, and tapping opens the bot's
/// profile or the app's connection page. Only known names count, so an email address or a stray
/// "@" stays plain text.
class MentionScope extends InheritedWidget {
  MentionScope({
    super.key,
    List<Bot> bots = const [],
    List<AppMentionInfo> apps = const [],
    this.knownIntegrationIds,
    this.onOpen,
    this.onOpenApp,
    required super.child,
  }) : bots = List.unmodifiable(bots),
       apps = List.unmodifiable(apps);

  final List<Bot> bots;
  final List<AppMentionInfo> apps;

  /// All live integration IDs in the workspace (when loaded). Used to mark stored `{ type: "app" }`
  /// mentions as removed/greyed out if the integration was later deleted.
  final Set<String>? knownIntegrationIds;

  /// Opens a mentioned bot (its profile).
  final ValueChanged<Bot>? onOpen;

  /// Opens a mentioned app's connection settings (`/settings/integrations/:id`).
  final ValueChanged<String>? onOpenApp;

  static MentionScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MentionScope>();

  /// The words that mean the whole group, as the server reads them.
  static const everyoneWords = {'everyone', 'all', 'team'};

  late final RegExp pattern = mentionPattern(
    [for (final b in bots) b.name, for (final a in apps) ...a.matchTerms],
    includeEveryone: bots.isNotEmpty,
  );

  /// The member [name] names (any case), or null for everyone.
  Bot? botNamed(String name) {
    final lower = name.toLowerCase();
    return bots.where((b) => b.name.toLowerCase() == lower).firstOrNull;
  }

  /// Finds an app matching [token], checking stored [messageApps] first and enriching from live
  /// [apps]. When [pickerOnly] is true, only matches an explicit picker ref from [messageApps].
  AppMentionInfo? appNamed(
    String token, {
    List<MessageAppMention> messageApps = const [],
    bool pickerOnly = false,
  }) {
    final lower = token.toLowerCase();
    final norm = _normToken(token);
    for (final m in messageApps) {
      if (pickerOnly && m.source != 'picker') continue;
      if (_matchesMessageApp(m, lower, norm)) {
        final live = _liveFor(m.integrationId, m.toolkit);
        final removed =
            knownIntegrationIds != null &&
            !knownIntegrationIds!.contains(m.integrationId);
        return AppMentionInfo(
          integrationId: m.integrationId,
          label: live?.label ?? m.label,
          toolkit: m.toolkit ?? live?.toolkit,
          appId: m.appId ?? live?.appId,
          color: live?.color,
          kind: live?.kind,
          removed: removed,
        );
      }
    }
    if (pickerOnly) return null;
    for (final a in apps) {
      if (a.label.toLowerCase() == lower ||
          _normToken(a.label) == norm ||
          (a.toolkit != null && _normToken(a.toolkit!) == norm) ||
          (a.appId != null && _normToken(a.appId!) == norm)) {
        return a;
      }
    }
    return null;
  }

  AppMentionInfo? _liveFor(String integrationId, String? toolkit) {
    for (final a in apps) {
      if (a.integrationId == integrationId && a.toolkit == toolkit) return a;
    }
    if (toolkit == null) {
      for (final a in apps) {
        if (a.integrationId == integrationId) return a;
      }
    }
    return null;
  }

  static String _normToken(String s) =>
      s.trim().toLowerCase().replaceAll(RegExp(r'[\s_\-]+'), '');

  static bool _matchesMessageApp(MessageAppMention m, String lower, String norm) {
    if (m.label.toLowerCase() == lower || _normToken(m.label) == norm) return true;
    if (m.toolkit != null &&
        (m.toolkit!.toLowerCase() == lower || _normToken(m.toolkit!) == norm)) {
      return true;
    }
    if (m.appId != null &&
        (m.appId!.toLowerCase() == lower || _normToken(m.appId!) == norm)) {
      return true;
    }
    return false;
  }

  /// A key that changes when what the mentions look like changes.
  String get signature => [
    for (final b in bots) 'b:${b.id}|${b.name}|${b.avatarUrl}',
    for (final a in apps) 'a:${a.integrationId}|${a.toolkit}|${a.label}|${a.appId}|${a.color}',
    if (knownIntegrationIds != null) 'k:${knownIntegrationIds!.length}',
  ].join(',');

  @override
  bool updateShouldNotify(MentionScope old) => old.signature != signature;
}

/// `@everyone`, `@all`, `@team` (when [includeEveryone]) or `@<name>` for these names: not inside
/// a word or an email address, and not followed by more of a word. Longer names first, so
/// "@Ada Lovelace" wins over "@Ada".
RegExp mentionPattern(Iterable<String> names, {bool includeEveryone = true}) {
  final words = {
    if (includeEveryone) ...MentionScope.everyoneWords,
    for (final n in names)
      if (n.trim().isNotEmpty) n.trim(),
  }.toList()..sort((a, b) => b.length - a.length);
  if (words.isEmpty) return RegExp(r'(?!)');
  return RegExp(
    '(?<![\\w@.])@(${words.map(RegExp.escape).join('|')})(?![\\w])',
    caseSensitive: false,
  );
}

/// [text] with each mention as a pill, for a plain-text message.
List<InlineSpan> mentionSpans(
  MentionScope scope,
  String text,
  TextStyle? style, {
  List<MessageAppMention> messageApps = const [],
}) {
  final pattern = messageApps.isEmpty
      ? scope.pattern
      : mentionPattern(
          [
            for (final b in scope.bots) b.name,
            for (final a in scope.apps) ...a.matchTerms,
            for (final m in messageApps) ...[
              m.label,
              if (m.toolkit != null) ...[m.toolkit!, m.toolkit!.replaceAll('_', '-')],
              if (m.appId != null) ...[m.appId!, m.appId!.replaceAll('_', '-')],
            ],
          ],
          includeEveryone: scope.bots.isNotEmpty,
        );
  final spans = <InlineSpan>[];
  var at = 0;
  for (final m in pattern.allMatches(text)) {
    if (m.start > at) spans.add(TextSpan(text: text.substring(at, m.start)));
    spans.add(mentionSpan(scope, m[1]!, style, messageApps: messageApps));
    at = m.end;
  }
  if (at < text.length) spans.add(TextSpan(text: text.substring(at)));
  return spans;
}

/// One mention, sitting on the line like a word.
InlineSpan mentionSpan(
  MentionScope scope,
  String name,
  TextStyle? style, {
  List<MessageAppMention> messageApps = const [],
}) {
  // Explicit picker app mention wins over a same-named bot in group chats (D-434).
  final pickedApp = scope.appNamed(name, messageApps: messageApps, pickerOnly: true);
  if (pickedApp != null) {
    return _appSpan(scope, pickedApp, style);
  }
  final lower = name.toLowerCase();
  final bot = scope.botNamed(name);
  if (bot != null || (scope.bots.isNotEmpty && MentionScope.everyoneWords.contains(lower))) {
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: MentionChip(
        label: bot?.name ?? lower,
        bot: bot,
        everyone: scope.bots,
        style: style,
        onTap: bot == null || scope.onOpen == null
            ? null
            : () => scope.onOpen!(bot),
      ),
    );
  }
  final app = scope.appNamed(name, messageApps: messageApps);
  if (app != null) {
    return _appSpan(scope, app, style);
  }
  return TextSpan(text: '@$name', style: style);
}

InlineSpan _appSpan(MentionScope scope, AppMentionInfo app, TextStyle? style) =>
    WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: MentionChip(
        label: app.label,
        app: app,
        style: style,
        onTap: app.removed || scope.onOpenApp == null
            ? null
            : () => scope.onOpenApp!(app.integrationId),
      ),
    );

/// `@Name` in bold beside the bot's or app's icon, on a soft pill in its brand color.
class MentionChip extends StatelessWidget {
  const MentionChip({
    super.key,
    required this.label,
    this.bot,
    this.app,
    this.everyone = const [],
    this.style,
    this.onTap,
  });
  final String label;

  /// The bot mentioned, or null for everyone or an app.
  final Bot? bot;

  /// The app mentioned (D-434), or null for a bot/everyone mention.
  final AppMentionInfo? app;
  final List<Bot> everyone;
  final TextStyle? style;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final base = style ?? DefaultTextStyle.of(context).style;
    final fontSize = base.fontSize ?? 16;
    final icon = (fontSize * 1.05).roundToDouble();
    final isRemovedApp = app?.removed ?? false;
    final tint = app != null
        ? (isRemovedApp
              ? scheme.onSurfaceVariant
              : brandColor(app!.color, scheme.primary))
        : (bot == null ? scheme.primary : botPalette(bot!.name).first);
    // The text around it decides, not the theme: your own bubble is light even in dark mode, and
    // onSurface there drew a white name on a white bubble.
    final ink = base.color ?? scheme.onSurface;
    final onDark = ink.computeLuminance() > 0.5;
    final textInk = isRemovedApp ? ink.withValues(alpha: 0.62) : ink;
    final Widget leading;
    if (app != null) {
      leading = isRemovedApp
          ? Icon(LucideIcons.plug, size: icon * 0.85, color: textInk)
          : AppLogo(
              appId:
                  app!.appId ??
                  (app!.kind == IntegrationKind.mcp ? 'mcp' : null),
              name: app!.label,
              color: app!.color,
              icon: app!.appId != null ? null : _iconForKind(app!.kind),
              size: icon,
            );
    } else if (bot != null) {
      leading = BotAvatar(
        name: bot!.name,
        avatar: bot!.avatarUrl,
        size: icon,
        animate: false,
      );
    } else {
      leading = GroupAvatar(
        bots: everyone,
        size: icon,
        ringColor: Color.alphaBlend(
          tint.withValues(alpha: 0.13),
          scheme.surface,
        ),
      );
    }
    final chip = DecoratedBox(
      decoration: BoxDecoration(
        color: tint.withValues(
          alpha: isRemovedApp ? (onDark ? 0.16 : 0.09) : (onDark ? 0.24 : 0.13),
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          isRemovedApp ? 5 : 2,
          1,
          fontSize * 0.45,
          1,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 3,
          children: [
            ExcludeSemantics(child: leading),
            Text(
              '@$label',
              style: base.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.25,
                color: textInk,
              ),
            ),
          ],
        ),
      ),
    );
    final tapKey = app != null
        ? Key('mention-app-${app!.integrationId}')
        : (bot != null ? Key('mention-${bot!.id}') : null);
    if (onTap == null) {
      return Semantics(
        label: isRemovedApp ? '@$label (${context.l10n.mentionRemovedApp})' : '@$label',
        child: ExcludeSemantics(
          child: tapKey != null ? KeyedSubtree(key: tapKey, child: chip) : chip,
        ),
      );
    }
    return Semantics(
      button: true,
      label: context.l10n.mentionOpenProfile('@$label'),
      child: ExcludeSemantics(
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            key: tapKey,
            onTap: onTap,
            child: chip,
          ),
        ),
      ),
    );
  }

  static IconData? _iconForKind(IntegrationKind? kind) => switch (kind) {
    IntegrationKind.mcp => null,
    IntegrationKind.openapi => LucideIcons.braces,
    IntegrationKind.composio => LucideIcons.blocks,
    IntegrationKind.pipedream => LucideIcons.cable,
    IntegrationKind.localMcp => LucideIcons.laptop,
    IntegrationKind.a2a => LucideIcons.bot,
    null => LucideIcons.plug,
  };
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

/// A Markdown generator that draws group and app mentions as pills (see [MentionScope]).
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
