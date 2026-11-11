import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/app_colors.dart';

/// The kind of thing a tool does, which picks its colour.
enum ToolTone {
  mind,
  web,
  computer,
  files,
  schedule,
  people,
  data,
  apps,
  other,
}

/// A tool step in everyday words, the same in chats, on calls and over the computer's live view:
/// what the bot is doing ("Searching the web") or did ("Searched the web"), the thing it's about
/// ("best time to repot a fern", "nytimes.com", "report.md"), an icon and a colour. No tool names,
/// commands or JSON: those stay behind a tap for the curious.
@immutable
class ToolWords {
  const ToolWords({
    required this.icon,
    required this.tone,
    required this.doing,
    required this.done,
    this.detail,
  });
  final IconData icon;
  final ToolTone tone;
  final String doing;
  final String done;

  /// What it's about, already quoted or shortened; null when there's nothing friendly to say.
  final String? detail;
}

/// Ids the ARB select messages (`toolDoing`, `toolDid`) know, from a tool's name.
const _known = {
  'memory_search',
  'memory_write',
  'memory',
  'knowledge_search',
  'web_search',
  'web', //
  'browser_open',
  'browser_click',
  'browser_type',
  'browser_press',
  'browser_scroll',
  'browser_look', //
  'desktop_click',
  'desktop_type',
  'desktop_press',
  'desktop_launch',
  'desktop_look',
  'shell', //
  'files_read',
  'files_write',
  'files_list',
  'files_search',
  'http',
  'data_search',
  'data_call', //
  'skills_load',
  'skills_create',
  'skills_update',
  'checkpoint',
  'takeover',
  'delegate', //
  'routines_list',
  'routines_create',
  'routines_update',
  'routines_delete',
  'watchers_create', //
  'watchers_list',
  'watchers_delete',
  'tasks_list',
  'tasks_create',
  'tasks',
  'notify_user', //
  'usage_report',
  'device_read',
  'device_access',
  'pages_publish',
  'pages',
  'media',
  'projects', //
  'payments',
  'voice_call',
  'voice_call_user',
  'tools_load',
  'ui_show',
  'start_task',
};

/// Which words a tool uses (an id from [_known]), or null for a connected app's tool.
String? toolWordsId(String tool) {
  final t = tool.replaceAll('__', '.');
  final flat = t.replaceAll('.', '_');
  if (_known.contains(flat)) return flat;
  if (t == 'browser.fill') return 'browser_type';
  if (t.startsWith('browser.')) return 'browser_look';
  if (t.startsWith('desktop.')) return 'desktop_look';
  if (t.startsWith('computer.request_takeover')) return 'takeover';
  if (t.startsWith('computer.')) return 'desktop_look';
  if (t.startsWith('shell')) return 'shell';
  if (t.startsWith('checkpoint')) return 'checkpoint';
  if (t.startsWith('http')) return 'http';
  if (t == 'device.request_access') return 'device_access';
  if (t.startsWith('memory')) return 'memory';
  if (t.startsWith('web')) return 'web';
  if (t.startsWith('tasks') || t.startsWith('tickets')) return 'tasks';
  if (t.startsWith('pages')) return 'pages';
  if (t.startsWith('media')) return 'media';
  if (t.startsWith('projects')) return 'projects';
  if (t.startsWith('payments')) return 'payments';
  if (t.contains('delegate') || t.contains('subagent')) return 'delegate';
  if (t.startsWith('skills')) return 'skills_load';
  if (t.startsWith('files')) return 'files_list';
  if (t.startsWith('routines')) return 'routines_list';
  if (t.startsWith('watchers')) return 'watchers_list';
  return null;
}

(IconData, ToolTone) _look(String? id) => switch (id) {
  'memory_search' || 'memory' => (LucideIcons.brain, ToolTone.mind),
  'memory_write' => (LucideIcons.brainCircuit, ToolTone.mind),
  'knowledge_search' => (LucideIcons.bookOpen, ToolTone.mind),
  'skills_load' ||
  'skills_create' ||
  'skills_update' => (LucideIcons.graduationCap, ToolTone.mind),
  'web_search' => (LucideIcons.globe, ToolTone.web),
  'web' || 'browser_look' => (LucideIcons.eye, ToolTone.web),
  'browser_open' => (LucideIcons.appWindow, ToolTone.web),
  'browser_click' ||
  'desktop_click' => (LucideIcons.mousePointerClick, ToolTone.computer),
  'browser_type' || 'desktop_type' => (LucideIcons.keyboard, ToolTone.computer),
  'browser_press' ||
  'desktop_press' => (LucideIcons.command, ToolTone.computer),
  'browser_scroll' => (LucideIcons.mouse, ToolTone.computer),
  'desktop_launch' => (LucideIcons.appWindow, ToolTone.computer),
  'desktop_look' => (LucideIcons.monitor, ToolTone.computer),
  'shell' => (LucideIcons.cpu, ToolTone.computer),
  'checkpoint' => (LucideIcons.rotateCcw, ToolTone.computer),
  'takeover' => (LucideIcons.hand, ToolTone.people),
  'files_read' => (LucideIcons.fileText, ToolTone.files),
  'files_write' => (LucideIcons.filePen, ToolTone.files),
  'files_list' || 'files_search' => (LucideIcons.folderSearch, ToolTone.files),
  'pages_publish' || 'pages' => (LucideIcons.panelsTopLeft, ToolTone.files),
  'media' => (LucideIcons.sparkles, ToolTone.files),
  'http' => (LucideIcons.cable, ToolTone.apps),
  'data_search' || 'data_call' => (LucideIcons.database, ToolTone.data),
  'usage_report' => (LucideIcons.chartColumn, ToolTone.data),
  'device_read' || 'device_access' => (LucideIcons.smartphone, ToolTone.data),
  'payments' => (LucideIcons.creditCard, ToolTone.data),
  'routines_list' ||
  'routines_update' => (LucideIcons.repeat, ToolTone.schedule),
  'routines_create' => (LucideIcons.calendarPlus, ToolTone.schedule),
  'routines_delete' => (LucideIcons.calendarX, ToolTone.schedule),
  'watchers_create' ||
  'watchers_list' ||
  'watchers_delete' => (LucideIcons.radar, ToolTone.schedule),
  'tasks_list' ||
  'tasks_create' ||
  'tasks' ||
  'projects' => (LucideIcons.listChecks, ToolTone.schedule),
  'notify_user' => (LucideIcons.bellRing, ToolTone.people),
  'delegate' => (LucideIcons.users, ToolTone.people),
  'voice_call' || 'voice_call_user' => (LucideIcons.phone, ToolTone.people),
  'start_task' => (LucideIcons.messageSquareShare, ToolTone.people),
  'tools_load' => (LucideIcons.packageOpen, ToolTone.other),
  'ui_show' => (LucideIcons.layoutDashboard, ToolTone.other),
  _ => (LucideIcons.plug, ToolTone.apps),
};

String _human(String s) => s.replaceAll(RegExp(r'[_-]+'), ' ').trim();

/// "github" and "create issue" from `mcp.github.create_issue` (or `github.create_issue`).
(String, String) _appTool(String tool) {
  final parts = tool.replaceAll('__', '.').split('.');
  if (parts.length >= 3) {
    return (_human(parts[1]), _human(parts.sublist(2).join(' ')));
  }
  if (parts.length == 2) return (_human(parts[0]), _human(parts[1]));
  return (_human(tool), '');
}

String _quote(String v, [int max = 48]) {
  final t = v.trim().replaceAll(RegExp(r'\s+'), ' ');
  return '“${t.length > max ? '${t.substring(0, max - 1)}…' : t}”';
}

String? _str(Map<String, Object?> a, List<String> keys) {
  for (final k in keys) {
    final v = a[k];
    if (v is String && v.trim().isNotEmpty) return v.trim();
  }
  return null;
}

/// nytimes.com from https://www.nytimes.com/...
String? _site(String? url) {
  if (url == null) return null;
  final host =
      Uri.tryParse(url.contains('://') ? url : 'https://$url')?.host ?? '';
  return host.isEmpty ? null : host.replaceFirst(RegExp(r'^www\.'), '');
}

String? _fileName(String? path) {
  if (path == null) return null;
  final name = path
      .split(RegExp(r'[/\\]'))
      .where((p) => p.isNotEmpty)
      .lastOrNull;
  return name;
}

/// Typed text is shown only when it looks harmless (never secrets or long blobs).
String? _typed(String? text) {
  if (text == null ||
      text.contains('{{') ||
      text.contains('•') ||
      text.length > 80) {
    return null;
  }
  return _quote(text, 32);
}

/// The thing a step is about, in friendly form.
String? _detailFor(String? id, String tool, Map<String, Object?> a) =>
    switch (id) {
      'browser_open' || 'http' || 'web' => _site(_str(a, ['url'])),
      'files_read' || 'files_write' => _fileName(_str(a, ['path'])),
      'browser_type' || 'desktop_type' => _typed(_str(a, ['text', 'value'])),
      'browser_press' || 'desktop_press' => _str(a, ['key', 'keys']),
      'desktop_launch' => _str(a, ['app']),
      'skills_load' ||
      'skills_create' ||
      'skills_update' => _str(a, ['name']).map(_human),
      'pages_publish' => _str(a, ['title']).map(_quote),
      'shell' ||
      'browser_click' ||
      'desktop_click' ||
      'browser_look' ||
      'desktop_look' ||
      'browser_scroll' ||
      'tools_load' => null,
      'start_task' => null,
      _ => _str(a, [
        'query',
        'q',
        'title',
        'name',
        'task',
        'text',
        'message',
        'description',
        'content',
      ]).map(_quote),
    };

extension<T extends Object> on T? {
  R? map<R>(R Function(T) f) => this == null ? null : f(this as T);
}

/// The command someone is being asked to allow, when the everyday line doesn't already
/// name what it's about. Shortened, and only from redacted arguments.
String? toolApprovalFocus(Map<String, Object?> args) {
  final command = _str(args, ['command', 'cmd']);
  return command == null ? null : _quote(command, 72);
}

/// [tool] (a dotted or wire name) with its redacted [args], in everyday words.
ToolWords toolWords(
  AppLocalizations l10n,
  String tool, [
  Map<String, Object?> args = const {},
]) {
  final id = toolWordsId(tool);
  final (icon, tone) = _look(id);
  if (id == null) {
    final (app, action) = _appTool(tool);
    return ToolWords(
      icon: icon,
      tone: tone,
      doing: l10n.toolUsingApp(app),
      done: l10n.toolUsedApp(app),
      detail: action.isEmpty ? null : action,
    );
  }
  return ToolWords(
    icon: icon,
    tone: tone,
    doing: l10n.toolDoing(id),
    done: l10n.toolDid(id),
    detail: _detailFor(id, tool, args),
  );
}

/// The colour for a [ToolTone] in the current theme.
Color toolTint(BuildContext context, ToolTone tone) {
  final scheme = Theme.of(context).colorScheme;
  final colors = context.appColors;
  return switch (tone) {
    ToolTone.mind => scheme.primary,
    ToolTone.web => scheme.secondary,
    ToolTone.computer => colors.info,
    ToolTone.files => scheme.tertiary,
    ToolTone.schedule => colors.warning,
    ToolTone.people => scheme.primary,
    ToolTone.data => colors.info,
    ToolTone.apps => scheme.secondary,
    ToolTone.other => scheme.onSurfaceVariant,
  };
}
