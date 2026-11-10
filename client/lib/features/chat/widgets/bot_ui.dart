import 'package:a2ui_core/a2ui_core.dart';
import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:a2ui_flutter/basic_catalog.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/widgets.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';
import 'chat_markdown.dart';

/// What a person did on a bot's interactive UI: the action's name and its resolved values.
class BotUiAction {
  const BotUiAction({required this.surfaceId, required this.name, required this.context, required this.sourceComponentId});
  final String surfaceId;
  final String name;
  final Map<String, Object?> context;
  final String sourceComponentId;

  Map<String, Object?> toJson() => {'surface_id': surfaceId, 'name': name, 'context': context, 'source_component_id': sourceComponentId};
}

/// The text of the message an action sends: the chosen values, or the action's name.
String uiActionSummary(BotUiAction a) {
  String show(Object? v) => v is List ? v.join(', ') : '$v';
  final values = a.context.entries.where((e) => e.value != null && '${e.value}'.isNotEmpty).toList();
  if (values.isEmpty) return a.name;
  if (values.length == 1) return show(values.single.value);
  return values.map((e) => '${e.key}: ${show(e.value)}').join('\n');
}

/// Holds the A2UI surfaces of one chat (D-086). Bots send small interactive UIs (choices, short
/// forms, cards) as A2UI v1.0 messages in a `ui` message part; this renders them with the basic
/// catalog in the app's own theme, and reports what the person does.
class BotUiHost {
  BotUiHost({required this.onAction}) {
    _actionSub = _processor.model.onAction.subscribe(
      (a) => onAction(BotUiAction(surfaceId: a.surfaceId, name: a.name, context: Map<String, Object?>.from(a.context), sourceComponentId: a.sourceComponentId)),
    );
  }

  final void Function(BotUiAction action) onAction;

  final _processor = MessageProcessor<ComponentImplementation>(
    catalogs: [
      basicCatalog(
        // Links in bot UI open outside the app, and only web addresses.
        openUrl: (uri) async {
          if (uri.scheme == 'http' || uri.scheme == 'https') await launchUrl(uri, mode: LaunchMode.externalApplication);
        },
      ),
    ],
  );
  late final Subscription _actionSub;
  final _failed = <String>{};

  /// The surface for [surfaceId], built from [messages] the first time it is asked for. Null when
  /// the messages don't describe a valid surface.
  SurfaceModel<ComponentImplementation>? surface(String surfaceId, List<Object?> messages) {
    if (_failed.contains(surfaceId)) return null;
    final existing = _processor.model.getSurface(surfaceId);
    if (existing != null) return existing;
    try {
      _processor.processMessages(messages);
    } catch (e) {
      debugPrint('bot ui $surfaceId: $e');
      _failed.add(surfaceId);
    }
    return _processor.model.getSurface(surfaceId);
  }

  void dispose() {
    _actionSub.unsubscribe();
    _processor.dispose();
  }
}

/// A bot's interactive UI in the thread: a card around the A2UI surface. Once answered it stays
/// visible, dimmed, with a note that it was sent.
class BotUiCard extends StatelessWidget {
  const BotUiCard({super.key, required this.host, required this.surfaceId, required this.messages, this.answered = false});
  final BotUiHost host;
  final String surfaceId;
  final List<Object?> messages;
  final bool answered;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final surface = host.surface(surfaceId, messages);
    final Widget body = surface == null
        ? Text(context.l10n.botUiBroken, style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant))
        : A2uiMarkdown(
            // Plain text keeps the inherited style (a button's label color); Markdown gets the chat's look.
            builder: (context, markdown, style) =>
                RegExp(r'[*_`#\[>|-]').hasMatch(markdown) ? ChatMarkdown(data: markdown, selectable: false) : Text(markdown, style: style),
            child: A2uiSurface(key: ObjectKey(surface), surface: surface),
          );
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          key: Key('botUi-$surfaceId'),
          padding: const EdgeInsets.all(AppSpace.md),
          decoration: BoxDecoration(
            color: context.isDark ? scheme.surfaceContainer : scheme.surfaceContainerLowest,
            borderRadius: const BorderRadiusDirectional.only(
              topStart: Radius.circular(6),
              topEnd: Radius.circular(20),
              bottomStart: Radius.circular(20),
              bottomEnd: Radius.circular(20),
            ),
            border: Border.all(color: answered ? context.appColors.hairline : scheme.primary.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: context.isDark ? 0.2 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // The basic components are Material widgets and need a Material ancestor.
              Material(
                type: MaterialType.transparency,
                child: IgnorePointer(
                  ignoring: answered,
                  child: AnimatedOpacity(opacity: answered ? 0.6 : 1, duration: AppMotion.fast, child: body),
                ),
              ),
              if (answered) ...[
                const SizedBox(height: AppSpace.xs),
                Row(
                  children: [
                    Icon(LucideIcons.circleCheck, size: 14, color: context.appColors.positive),
                    const SizedBox(width: 6),
                    Text(context.l10n.botUiSent, style: context.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
