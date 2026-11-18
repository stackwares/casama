import 'package:material_ui/material_ui.dart';

import 'bot_ui_cards.dart';
import 'bot_ui_draft.dart';
import 'bot_ui_kit.dart';

// What an approval card shows for a message or an event (D-337): the email, chat message or event
// itself, drawn like the bot's own cards, instead of three lines of its arguments.

final _sendTool = RegExp(
  r'(send|reply|forward|post|create_email_draft)',
  caseSensitive: false,
);
final _mailTool = RegExp(r'(gmail|outlook|mail)', caseSensitive: false);
final _chatTool = RegExp(
  r'(slack|whatsapp|telegram|discord|teams|sms|message|chat|channel\.send)',
  caseSensitive: false,
);
final _eventTool = RegExp(
  r'(calendar|event).*(create|insert|add|quick_add|update|patch)|(create|add|insert)_?event|device\.calendar\.create',
  caseSensitive: false,
);

Object? _first(Map<String, Object?> args, List<String> keys) {
  for (final k in keys) {
    final v = args[k];
    if (v != null &&
        (v is! String || v.trim().isNotEmpty) &&
        (v is! List || v.isNotEmpty)) {
      return v;
    }
  }
  return null;
}

/// People from a tool's arguments: "a@x.com, b@y.com", ["a@x.com"], or [{email, name}].
List<String> _people(Object? v) => switch (v) {
  final String s => DraftSpec.splitPeople(s),
  final List<Object?> l => [
    for (final x in l)
      if (x is Map)
        ?cardText(x['email'] ?? x['address'] ?? x['name'])
      else
        ...DraftSpec.splitPeople('${x ?? ''}'),
  ],
  final Map<Object?, Object?> m => [
    ?cardText(m['email'] ?? m['address'] ?? m['name']),
  ],
  _ => const [],
};

/// A time from a tool's arguments: "2026-11-20T14:00", or Google's {dateTime} / {date}.
String? _time(Object? v) => switch (v) {
  final String s => cardText(s),
  final Map<Object?, Object?> m => cardText(
    m['dateTime'] ?? m['date_time'] ?? m['date'],
  ),
  _ => null,
};

/// The message an approval would send, when its tool sends one.
DraftSpec? approvalDraft(String tool, Map<String, Object?> args) {
  final name = tool.split('.').last;
  if (!_sendTool.hasMatch(name) && tool != 'channel.send') return null;
  final body = cardText(
    _first(args, const [
      'body',
      'message_body',
      'text',
      'message',
      'content',
      'html_body',
      'markdown_text',
    ]),
  );
  if (body == null) return null;
  final mail = _mailTool.hasMatch(tool);
  if (!mail && !_chatTool.hasMatch(tool)) return null;
  final subject = cardText(_first(args, const ['subject', 'title']));
  final plain = body
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</p>\s*', caseSensitive: false), '\n\n')
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .trim();
  return DraftSpec(
    kind: mail || subject != null ? 'email' : 'message',
    body: plain,
    app: switch (tool) {
      final t when t.contains('gmail') => 'gmail',
      final t when t.contains('slack') => 'slack',
      _ => null,
    },
    to: _people(
      _first(args, const [
        'to',
        'recipient_email',
        'recipients',
        'to_recipients',
        'recipient',
        'channel',
        'channel_id',
        'chat_id',
        'phone',
        'phone_number',
      ]),
    ),
    cc: _people(_first(args, const ['cc', 'cc_recipients'])),
    bcc: _people(_first(args, const ['bcc', 'bcc_recipients'])),
    subject: subject,
  );
}

/// The event an approval would add, when its tool adds or changes one.
EventSpec? approvalEvent(String tool, Map<String, Object?> args) {
  if (!_eventTool.hasMatch(tool)) return null;
  final title = cardText(
    _first(args, const ['summary', 'title', 'name', 'event_name']),
  );
  final start = _time(
    _first(args, const [
      'start_datetime',
      'start',
      'start_time',
      'startDate',
      'start_date',
      'date',
    ]),
  );
  if (title == null || start == null) return null;
  return EventSpec.fromMap({
    'title': title,
    'start': start,
    'end': _time(
      _first(args, const [
        'end_datetime',
        'end',
        'end_time',
        'endDate',
        'end_date',
      ]),
    ),
    'allDay': args['all_day'] == true || args['allDay'] == true,
    'location': cardText(args['location']),
    'attendees': _people(
      _first(args, const ['attendees', 'guests', 'invitees']),
    ),
    'description': cardText(args['description']),
  }, actions: false);
}

/// The preview an approval card shows for [tool], or null to keep its usual summary.
Widget? approvalPreview(String tool, Map<String, Object?> args) {
  if (approvalDraft(tool, args) case final draft?) {
    return BotDraftCard(
      key: const Key('approvalDraftPreview'),
      spec: draft,
      readOnly: true,
      onAction: (_, _, _) {},
    );
  }
  if (approvalEvent(tool, args) case final event?) {
    return BotEventCard(
      key: const Key('approvalEventPreview'),
      spec: event,
      showHeader: false,
    );
  }
  return null;
}
