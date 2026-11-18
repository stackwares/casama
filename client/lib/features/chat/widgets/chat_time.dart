import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

import '../../../core/date_format.dart';
import '../../../core/widgets.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';

/// When messages were sent (D-387), without a time under every bubble: a quiet label where the
/// day changes or the chat picks up again after a while, and the exact time in a message's menu.

/// How long a pause within one day gets its own time label.
const chatTimeGap = Duration(hours: 1);

enum ChatTimeBreak { day, gap }

/// Whether a label goes before a message sent at [at], after the one before it at [prev] (null:
/// it's the first message shown). Both in local time.
ChatTimeBreak? chatTimeBreak(DateTime? prev, DateTime at) {
  if (prev == null || !_sameDay(prev, at)) return ChatTimeBreak.day;
  if (at.difference(prev) >= chatTimeGap) return ChatTimeBreak.gap;
  return null;
}

bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

/// "Today", "Yesterday", "Mon, Nov 16", or "Mon, Nov 16, 2025" in another year.
String chatDayLabel(BuildContext context, DateTime at, {DateTime? now}) {
  final today = now ?? DateTime.now();
  final l10n = context.l10n;
  if (_sameDay(at, today)) return l10n.chatDayToday;
  if (_sameDay(at, DateTime(today.year, today.month, today.day - 1))) return l10n.chatTimeYesterday;
  final locale = Localizations.localeOf(context).toString();
  return at.year == today.year ? DateFormat.MMMEd(locale).format(at) : DateFormat.yMMMEd(locale).format(at);
}

/// The label between messages: the day and the first message's time, or only the time after a pause.
String chatTimeLabel(BuildContext context, ChatTimeBreak kind, DateTime at, {DateTime? now}) => switch (kind) {
      ChatTimeBreak.day => context.l10n.chatDayAndTime(chatDayLabel(context, at, now: now), at.formattedTime(context)),
      ChatTimeBreak.gap => at.formattedTime(context),
    };

/// One message's moment, for its menu and screen readers: "Today at 3:42 PM".
String messageSentLabel(BuildContext context, DateTime at, {DateTime? now}) =>
    context.l10n.messageSentAt(chatDayLabel(context, at, now: now), at.formattedTime(context));

/// The label itself: small muted text in the middle, no line or pill, so it reads on any wallpaper
/// without drawing the eye.
class ChatTimeDivider extends StatelessWidget {
  const ChatTimeDivider({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
        child: Center(
          child: Semantics(
            header: true,
            child: Text(
              label,
              key: const Key('chatTimeDivider'),
              textAlign: TextAlign.center,
              style: context.textTheme.labelSmall?.copyWith(color: context.colorScheme.onSurfaceVariant),
            ),
          ),
        ),
      );
}
