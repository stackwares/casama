# Fix: Missing values show as blank spots, dangling sentences or the word "null"

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/never-show-null
- **Needs new dependency**: none

## Why

When the server leaves a text field out, sends it empty, or a serializer writes the word
`"null"`, Casama puts it on screen anyway: the Secret store row literally reads
`Infisical · null · null`, "Key test failed: " and "Linked with " end with nothing, a chat with
an empty title is a blank row, and the "Why you got this" sheet starts with an empty line. Each
place guards in its own way (`?? ''`, `!= null`, `(x ?? '').isNotEmpty`), and none of them
covers all three cases. One shared guard makes every missing value either disappear cleanly or
show a quiet `—`, so people never see "null" or a hole where a value should be.

**The placeholder is an em dash, `—`** (one constant, `kMissingValue`). It's the typographic
mark for "no value" in every language, so it needs no translation, and the bot history screen
already uses it. Where a better word exists the code passes it instead (for example "Untitled
chat", "a deleted bot"), and where a line only adds detail the line is hidden instead.

## Where

Every on-screen use of a nullable text value from the server (a `String?` field of a
`casama_sdk` model or of the app's own models in `lib/core/backend.dart`) that is guarded by
hand. A search for `orPlaceholder|isUsable|!= 'null'` finds nothing: there is no shared guard.
57 places, 65 lines, in 29 files. Line numbers are from before any edit.

```dart
// 1. lib/features/inbox/inbox_screen.dart:706 — current ("Why you got this" sheet: a missing rule shows an empty line; hide it instead)
        Text(n.whyRule ?? '', key: const Key('whyRule'), style: context.textTheme.bodyLarge),
```

```dart
// 2. lib/features/inbox/inbox_screen.dart:708 — current (same sheet: urgency)
        if (n.urgency != null) Text(l10n.whyUrgency(n.urgency!), style: context.textTheme.bodySmall),
```

```dart
// 3. lib/features/bots/template_picker.dart:415 — current (persona preview box is empty when a template has no persona)
                child: SelectableText(t.persona ?? '', style: context.textTheme.bodyMedium?.copyWith(height: 1.5)),
```

```dart
// 4. lib/features/bots/bot_template.dart:191 — current (imported template's description)
                    if ((t.description ?? '').isNotEmpty) Text(t.description!),
```

```dart
// 5. lib/features/bots/channels_screen.dart:115 — current (chat app row: last error)
                          subtitle: [channelKindName(c.kind), l10n.chatAppsAllowed(c.allowedSenders.length), if (c.lastError != null) c.lastError!].join(' · '),
```

```dart
// 6. lib/features/bots/channels_screen.dart:273–274 — current (chat app setup info: webhook URL and verify token)
        if (channel.webhookUrl != null) _Copyable(label: l10n.chatAppsWebhookUrl, value: channel.webhookUrl!, keyName: 'webhookUrl'),
        if (channel.verifyToken != null) _Copyable(label: l10n.chatAppsVerifyToken, value: channel.verifyToken!, keyName: 'verifyToken'),
```

```dart
// 7. lib/features/bots/channels_screen.dart:337 — current (chat app edit sheet: webhook URL)
        if (c.webhookUrl != null) _Copyable(label: l10n.chatAppsWebhookUrl, value: c.webhookUrl!, keyName: 'webhookUrl'),
```

```dart
// 8. lib/features/bots/channels_screen.dart:361 — current (chat app activity row: blank when the event has neither sender nor preview)
                            title: Text([e.sender ?? '', e.preview ?? ''].where((s) => s.isNotEmpty).join(': '), maxLines: 2, overflow: TextOverflow.ellipsis),
```

```dart
// 9. lib/features/bots/channels_screen.dart:365 — current (chat app activity row: failure detail)
                              ChannelEventStatusEnum.failed => e.detail ?? l10n.chatAppsFailed,
```

```dart
// 10. lib/features/bots/plugins_screen.dart:101 — current (installed plugin title: version)
          title: '${p.name}${p.version == null ? '' : ' ${p.version}'}',
```

```dart
// 11. lib/features/bots/plugins_screen.dart:117 — current (plugin server row: error)
                ? (s.error ?? l10n.pluginServerError)
```

```dart
// 12. lib/features/bots/plugins_screen.dart:119 — current (plugin server row: remote URL)
                ? (s.type == InstalledPluginServerTypeEnum.stdio ? l10n.pluginRunsOnComputer : (s.url ?? ''))
```

```dart
// 13. lib/features/bots/plugins_screen.dart:147 — current (plugin preview title: version)
        Text('${p.name}${p.version == null ? '' : ' ${p.version}'}', style: style.titleMedium),
```

```dart
// 14. lib/features/bots/plugins_screen.dart:159 — current (plugin preview server: command or URL)
            subtitle: Text(s.type == PluginServerInfoTypeEnum.stdio ? l10n.pluginStdio([s.command ?? '', ...s.args].join(' ')) : l10n.pluginRemote(s.url ?? '')),
```

```dart
// 15. lib/features/bots/links_screen.dart:95 — current (bot link row: "Linked with " and nothing)
                              BotLinkStatusEnum.active => l10n.linksActive(link.peerBotName ?? ''),
```

```dart
// 16. lib/features/bots/links_screen.dart:99 — current (bot link row: remote host)
                            if (link.remoteUrl != null) Uri.tryParse(link.remoteUrl!)?.host ?? '',
```

```dart
// 17. lib/features/bots/links_screen.dart:198 — current (bot link sheet subtitle)
      subtitle: link.peerBotName != null ? l10n.linksActive(link.peerBotName!) : null,
```

```dart
// 18. lib/features/bots/links_screen.dart:213 — current (bot link exchange: reply)
            subtitle: Text(e.response ?? (e.status == LinkExchangeStatusEnum.failed ? l10n.linksNoAnswer : l10n.linksWorking), maxLines: 3, overflow: TextOverflow.ellipsis),
```

```dart
// 19. lib/features/bots/knowledge_screen.dart:72 — current (knowledge source row: error)
                              KnowledgeSourceStatusEnum.error => s.error ?? l10n.knowledgeError,
```

```dart
// 20. lib/features/bots/knowledge_screen.dart:76 — current (knowledge source row: warning on a ready source)
                            if (s.status == KnowledgeSourceStatusEnum.ready && s.error != null) s.error!,
```

```dart
// 21. lib/features/bots/sharing_screen.dart:53 — current (sharing list: a person without an email gets a blank row)
        ..addAll(a.entries.map((e) => (userId: e.userId, role: e.role?.value, label: e.email ?? e.role?.value ?? '', access: e.access.value)));
```

```dart
// 22. lib/features/bots/sharing_screen.dart:159–161 — current (sharing: "add a person" chips (lines 159 and 161; line 160 stays))
                        label: Text(m.email ?? m.userId),
                        onPressed: () => setState(() {
                          _entries.add((userId: m.userId, role: null, label: m.email ?? m.userId, access: 'chat'));
```

```dart
// 23. lib/features/bots/bot_history_screen.dart:108–110 — current (bot history values: a local guard that misses "null" and blank model names)
    if (v == null) return '—';
    if (v is String) return v.isEmpty ? '—' : v;
    if (v is Map && v['primary'] is Map) return '${(v['primary'] as Map)['model'] ?? '—'}';
```

```dart
// 24. lib/features/settings/background_screen.dart:331 — current ("Photo by …" credit (line 345 `spec.photoCredit!` stays))
          if ((spec.photoCredit ?? '').isNotEmpty)
```

```dart
// 25. lib/features/settings/settings_screen.dart:136 — current (Settings → Account row)
                    subtitle: backend.userEmail ?? l10n.accountRow,
```

```dart
// 26. lib/features/settings/model_keys_screen.dart:124 — current ("Connected your ChatGPT plan (…)" message)
        : l10n.chatGptConnected(cred.account ?? l10n.chatGptPlan),
```

```dart
// 27. lib/features/settings/model_keys_screen.dart:466 — current ("Key test failed: " with nothing after it)
      r.ok ? l10n.keyOk(r.model, r.latencyMs) : l10n.keyFailed(r.error ?? ''),
```

```dart
// 28. lib/features/settings/model_keys_screen.dart:539 — current (ChatGPT plan row: an empty account leaves a double " ·  · ")
            ?k.account,
```

```dart
// 29. lib/features/settings/model_keys_screen.dart:542 — current (key row: key hint)
        : '${providerLabel(k.provider)}${k.keyHint == null ? '' : ' · …${k.keyHint}'}';
```

```dart
// 30. lib/features/auth/account_screen.dart:122 — current ("enter the code we just emailed to .")
              FormNote(l10n.passwordCodeSent(ref.read(backendProvider).userEmail ?? ''), icon: LucideIcons.mailCheck),
```

```dart
// 31. lib/features/auth/account_screen.dart:293 — current (Account → email row)
              title: backend.userEmail ?? l10n.email,
```

```dart
// 32. lib/features/admin/admin_screen.dart:156–157 — current (admin update notice: version and link)
                              Text(l10n.updateAvailable(u.latest ?? '', u.current), style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                              if (u.url != null) SelectableText(u.url!, style: context.textTheme.bodySmall),
```

```dart
// 33. lib/features/admin/admin_screen.dart:209 — current (admin user row)
                  title: u.email ?? u.id,
```

```dart
// 34. lib/features/admin/admin_screen.dart:294 — current (admin workspace row: "Suspended: " with no reason)
                      if (o.suspendedAt != null) l10n.workspaceSuspended(o.suspendedReason ?? ''),
```

```dart
// 35. lib/features/integrations/integrations_screen.dart:498 — current (connected app row: error)
                      i.status == IntegrationStatusEnum.error && i.error != null ? i.error! : [if (i.tools.isNotEmpty) l10n.toolCount(i.tools.length), l10n.usedByBots(users.length)].join(' · '),
```

```dart
// 36. lib/features/integrations/integration_detail_screen.dart:42 — current ("Connection failed: " with nothing after it)
    if (r != null) showMessage(context, r.ok ? l10n.integrationOk(r.tools.length) : l10n.integrationFailed(r.error ?? ''));
```

```dart
// 37. lib/features/bots/model_picker.dart:185 — current (model list fallback note (the sentence reads fine without a reason, so the placeholder is empty))
                      l10n.modelListFallback(list.error ?? ''),
```

```dart
// 38. lib/features/workspaces/people_screen.dart:57 — current (People: member row name and pronouns)
                title: [m.name ?? m.email ?? m.userId, if (m.pronouns != null) '(${m.pronouns})'].join(' '),
```

```dart
// 39. lib/features/workspaces/people_screen.dart:402–403 — current (People: join request rows)
                title: r.displayName ?? r.email ?? r.userId,
                subtitle: [if (r.displayName != null && r.email != null) r.email!, relativeTime(r.createdAt, context)].join(' · '),
```

```dart
// 40. lib/features/workspaces/join_flow.dart:197 — current (invite preview: " invited you to join")
            eyebrow: p.inviterName == null ? l10n.invitedToJoin : l10n.invitedBy(p.inviterName!),
```

```dart
// 41. lib/features/workspaces/join_flow.dart:206 — current (invite preview: "Sign in with  to accept.")
              if (p.emailHint != null) l10n.inviteSentTo(p.emailHint!),
```

```dart
// 42. lib/features/workspaces/workspace_files.dart:74 — current (Git sync row: folder)
                      '${sync.repo}@${sync.branch}${(sync.path ?? '').isEmpty ? '' : '/${sync.path}'}',
```

```dart
// 43. lib/features/workspaces/workspace_files.dart:76 — current (Git sync row: last error)
                      if (sync.lastError != null) sync.lastError!,
```

```dart
// 44. lib/features/workspaces/spaces.dart:953 — current (Payments sheet: webhook URL)
        if (widget.current.webhookUrl != null) SelectableText('${l10n.paymentsWebhook}: ${widget.current.webhookUrl}'),
```

```dart
// 45. lib/features/workspaces/spaces.dart:989 — current (Secret store row prints the word "null" when the project or environment is missing)
          subtitle: infisical ? 'Infisical · ${s.projectId} · ${s.environment}' : l10n.secretStoreVault,
```

```dart
// 46. lib/features/teach/teach_draft_screen.dart:169 — current (taught step: page URL)
              subtitle: st.url == null ? null : Text(st.url!, maxLines: 1, overflow: TextOverflow.ellipsis),
```

```dart
// 47. lib/features/teach/teach_draft_screen.dart:209–210 — current (taught step labels: "Type “”", "Press ")
    TeachStepKindEnum.type => s.secretName != null ? l10n.teachStepSecret(s.secretName!) : l10n.teachStepType(s.text ?? ''),
    TeachStepKindEnum.key => l10n.teachStepKey(s.key ?? ''),
```

```dart
// 48. lib/features/board/board_screen.dart:589 — current (task details: result card)
          if (task.resultMd != null) AppCard(child: Text(task.resultMd!)),
```

```dart
// 49. lib/features/routines/routines_screen.dart:68 — current (webhook-created sheet gate)
    if (created.webhookUrl != null) {
```

```dart
// 50. lib/features/routines/routines_screen.dart:103–104 — current (webhook-created sheet: URL and secret)
              field(l10n.webhookUrl, created.webhookUrl ?? ''),
              field(l10n.webhookSecret, created.webhookSecret ?? '', key: const Key('webhookSecret')),
```

```dart
// 51. lib/features/routines/routines_screen.dart:136 — current (routine row: schedule)
      RoutineTrigger.schedule => (LucideIcons.repeat, l10n.routineSchedule(scheduleWords(context, r.scheduleCron ?? ''), r.timezone)),
```

```dart
// 52. lib/features/skills/skills_screen.dart:115 — current (skill row: "GitHub " with no repo (the value is an Object?, so call toString first, as the article shows))
                              'github' => 'GitHub ${s.sourceRef['repo'] ?? ''}',
```

```dart
// 53. lib/features/chat/chat_screen.dart:1379 — current (chat list: a chat whose title is empty shows a blank row)
                          c.title ?? l10n.untitledChat,
```

```dart
// 54. lib/features/groups/group_chats.dart:26 — current (group chat title)
    (c.title?.isNotEmpty ?? false) ? c.title! : c.botIds.map((id) => bots.where((b) => b.id == id).firstOrNull?.name ?? '').where((n) => n.isNotEmpty).join(', ');
```

```dart
// 55. lib/features/usage/usage_screen.dart:121 — current (Usage → By bot: a bot name (only the first element of the record changes))
                  for (final b in report.byBot) (b.name ?? l10n.deletedBot, b.costUsd.toDouble(), b.tokensIn + b.tokensOut == 0 ? '' : '${compactNumber(b.tokensIn + b.tokensOut)} tokens'),
```

```dart
// 56. lib/features/usage/usage_screen.dart:397 — current (Usage → By model: model name)
                    m.model == null ? context.l10n.otherModel : names[m.model] ?? m.model!,
```

```dart
// 57. lib/features/billing/billing_screen.dart:383 — current (billed item: instance name)
      return (i.instance == null ? what : '$what · ${i.instance}', icon);
```

## The fix

The article's fix: one extension on `String?` that treats `null`, empty and the literal
`"null"` as missing (`isUsable`), and returns a placeholder for them (`orPlaceholder()`). Use
`orPlaceholder()` where something must show, `orPlaceholder(<better word>)` where the screen
already has a fallback word, and `if (x.isUsable) … x!` where the line should disappear. For a
non-`String` value, call `toString()` first and wrap the chain in parentheses so the guard always
runs: `(value?.toString()).orPlaceholder()`. One addition to the article: blank text (only
spaces) counts as missing too, because it shows the same blank spot.

New file `lib/core/display_text.dart` (target, complete):

```dart
/// Shown in place of a value that's missing (D-NNN): an em dash, the mark for "no value" in
/// every language, so it needs no translation.
const String kMissingValue = '—';

/// Text from the server that may be missing: null, empty, blank, or the word "null" that a
/// serializer wrote. Never put such a value on screen as it is.
extension UsableText on String? {
  /// True when there is real text to show.
  bool get isUsable {
    final String? value = this;

    return value != null && value.trim().isNotEmpty && value != 'null';
  }

  /// The text, or [placeholder] (an em dash unless given) when it isn't usable.
  String orPlaceholder([String placeholder = kMissingValue]) {
    if (!isUsable) return placeholder;

    return this!;
  }
}
```

Targets, numbered as in "Where" (each line keeps everything not shown as changed):

```dart
// 1. lib/features/inbox/inbox_screen.dart:706 — target ("Why you got this" sheet: a missing rule shows an empty line; hide it instead)
        if (n.whyRule.isUsable) Text(n.whyRule!, key: const Key('whyRule'), style: context.textTheme.bodyLarge),
```

```dart
// 2. lib/features/inbox/inbox_screen.dart:708 — target (same sheet: urgency)
        if (n.urgency.isUsable) Text(l10n.whyUrgency(n.urgency!), style: context.textTheme.bodySmall),
```

```dart
// 3. lib/features/bots/template_picker.dart:415 — target (persona preview box is empty when a template has no persona)
                child: SelectableText(t.persona.orPlaceholder(), style: context.textTheme.bodyMedium?.copyWith(height: 1.5)),
```

```dart
// 4. lib/features/bots/bot_template.dart:191 — target (imported template's description)
                    if (t.description.isUsable) Text(t.description!),
```

```dart
// 5. lib/features/bots/channels_screen.dart:115 — target (chat app row: last error)
                          subtitle: [channelKindName(c.kind), l10n.chatAppsAllowed(c.allowedSenders.length), if (c.lastError.isUsable) c.lastError!].join(' · '),
```

```dart
// 6. lib/features/bots/channels_screen.dart:273–274 — target (chat app setup info: webhook URL and verify token)
        if (channel.webhookUrl.isUsable) _Copyable(label: l10n.chatAppsWebhookUrl, value: channel.webhookUrl!, keyName: 'webhookUrl'),
        if (channel.verifyToken.isUsable) _Copyable(label: l10n.chatAppsVerifyToken, value: channel.verifyToken!, keyName: 'verifyToken'),
```

```dart
// 7. lib/features/bots/channels_screen.dart:337 — target (chat app edit sheet: webhook URL)
        if (c.webhookUrl.isUsable) _Copyable(label: l10n.chatAppsWebhookUrl, value: c.webhookUrl!, keyName: 'webhookUrl'),
```

```dart
// 8. lib/features/bots/channels_screen.dart:361 — target (chat app activity row: blank when the event has neither sender nor preview)
                            title: Text([e.sender, e.preview].where((s) => s.isUsable).join(': ').orPlaceholder(), maxLines: 2, overflow: TextOverflow.ellipsis),
```

```dart
// 9. lib/features/bots/channels_screen.dart:365 — target (chat app activity row: failure detail)
                              ChannelEventStatusEnum.failed => e.detail.orPlaceholder(l10n.chatAppsFailed),
```

```dart
// 10. lib/features/bots/plugins_screen.dart:101 — target (installed plugin title: version)
          title: '${p.name}${p.version.isUsable ? ' ${p.version}' : ''}',
```

```dart
// 11. lib/features/bots/plugins_screen.dart:117 — target (plugin server row: error)
                ? s.error.orPlaceholder(l10n.pluginServerError)
```

```dart
// 12. lib/features/bots/plugins_screen.dart:119 — target (plugin server row: remote URL)
                ? (s.type == InstalledPluginServerTypeEnum.stdio ? l10n.pluginRunsOnComputer : s.url.orPlaceholder())
```

```dart
// 13. lib/features/bots/plugins_screen.dart:147 — target (plugin preview title: version)
        Text('${p.name}${p.version.isUsable ? ' ${p.version}' : ''}', style: style.titleMedium),
```

```dart
// 14. lib/features/bots/plugins_screen.dart:159 — target (plugin preview server: command or URL)
            subtitle: Text(s.type == PluginServerInfoTypeEnum.stdio ? l10n.pluginStdio([s.command.orPlaceholder(), ...s.args].join(' ')) : l10n.pluginRemote(s.url.orPlaceholder())),
```

```dart
// 15. lib/features/bots/links_screen.dart:95 — target (bot link row: "Linked with " and nothing)
                              BotLinkStatusEnum.active => l10n.linksActive(link.peerBotName.orPlaceholder()),
```

```dart
// 16. lib/features/bots/links_screen.dart:99 — target (bot link row: remote host)
                            if (link.remoteUrl.isUsable) Uri.tryParse(link.remoteUrl!)?.host ?? '',
```

```dart
// 17. lib/features/bots/links_screen.dart:198 — target (bot link sheet subtitle)
      subtitle: link.peerBotName.isUsable ? l10n.linksActive(link.peerBotName!) : null,
```

```dart
// 18. lib/features/bots/links_screen.dart:213 — target (bot link exchange: reply)
            subtitle: Text(e.response.orPlaceholder(e.status == LinkExchangeStatusEnum.failed ? l10n.linksNoAnswer : l10n.linksWorking), maxLines: 3, overflow: TextOverflow.ellipsis),
```

```dart
// 19. lib/features/bots/knowledge_screen.dart:72 — target (knowledge source row: error)
                              KnowledgeSourceStatusEnum.error => s.error.orPlaceholder(l10n.knowledgeError),
```

```dart
// 20. lib/features/bots/knowledge_screen.dart:76 — target (knowledge source row: warning on a ready source)
                            if (s.status == KnowledgeSourceStatusEnum.ready && s.error.isUsable) s.error!,
```

```dart
// 21. lib/features/bots/sharing_screen.dart:53 — target (sharing list: a person without an email gets a blank row)
        ..addAll(a.entries.map((e) => (userId: e.userId, role: e.role?.value, label: e.email.isUsable ? e.email! : (e.role?.value).orPlaceholder(), access: e.access.value)));
```

```dart
// 22. lib/features/bots/sharing_screen.dart:159–161 — target (sharing: "add a person" chips (lines 159 and 161; line 160 stays))
                        label: Text(m.email.orPlaceholder(m.userId)),
                        onPressed: () => setState(() {
                          _entries.add((userId: m.userId, role: null, label: m.email.orPlaceholder(m.userId), access: 'chat'));
```

```dart
// 23. lib/features/bots/bot_history_screen.dart:108–110 — target (bot history values: a local guard that misses "null" and blank model names)
    if (v == null) return kMissingValue;
    if (v is String) return v.orPlaceholder();
    if (v is Map && v['primary'] is Map) return ((v['primary'] as Map)['model']?.toString()).orPlaceholder();
```

```dart
// 24. lib/features/settings/background_screen.dart:331 — target ("Photo by …" credit (line 345 `spec.photoCredit!` stays))
          if (spec.photoCredit.isUsable)
```

```dart
// 25. lib/features/settings/settings_screen.dart:136 — target (Settings → Account row)
                    subtitle: backend.userEmail.orPlaceholder(l10n.accountRow),
```

```dart
// 26. lib/features/settings/model_keys_screen.dart:124 — target ("Connected your ChatGPT plan (…)" message)
        : l10n.chatGptConnected(cred.account.orPlaceholder(l10n.chatGptPlan)),
```

```dart
// 27. lib/features/settings/model_keys_screen.dart:466 — target ("Key test failed: " with nothing after it)
      r.ok ? l10n.keyOk(r.model, r.latencyMs) : l10n.keyFailed(r.error.orPlaceholder()),
```

```dart
// 28. lib/features/settings/model_keys_screen.dart:539 — target (ChatGPT plan row: an empty account leaves a double " ·  · ")
            if (k.account.isUsable) k.account!,
```

```dart
// 29. lib/features/settings/model_keys_screen.dart:542 — target (key row: key hint)
        : '${providerLabel(k.provider)}${k.keyHint.isUsable ? ' · …${k.keyHint}' : ''}';
```

```dart
// 30. lib/features/auth/account_screen.dart:122 — target ("enter the code we just emailed to .")
              FormNote(l10n.passwordCodeSent(ref.read(backendProvider).userEmail.orPlaceholder()), icon: LucideIcons.mailCheck),
```

```dart
// 31. lib/features/auth/account_screen.dart:293 — target (Account → email row)
              title: backend.userEmail.orPlaceholder(l10n.email),
```

```dart
// 32. lib/features/admin/admin_screen.dart:156–157 — target (admin update notice: version and link)
                              Text(l10n.updateAvailable(u.latest.orPlaceholder(), u.current), style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                              if (u.url.isUsable) SelectableText(u.url!, style: context.textTheme.bodySmall),
```

```dart
// 33. lib/features/admin/admin_screen.dart:209 — target (admin user row)
                  title: u.email.orPlaceholder(u.id),
```

```dart
// 34. lib/features/admin/admin_screen.dart:294 — target (admin workspace row: "Suspended: " with no reason)
                      if (o.suspendedAt != null) l10n.workspaceSuspended(o.suspendedReason.orPlaceholder()),
```

```dart
// 35. lib/features/integrations/integrations_screen.dart:498 — target (connected app row: error)
                      i.status == IntegrationStatusEnum.error && i.error.isUsable ? i.error! : [if (i.tools.isNotEmpty) l10n.toolCount(i.tools.length), l10n.usedByBots(users.length)].join(' · '),
```

```dart
// 36. lib/features/integrations/integration_detail_screen.dart:42 — target ("Connection failed: " with nothing after it)
    if (r != null) showMessage(context, r.ok ? l10n.integrationOk(r.tools.length) : l10n.integrationFailed(r.error.orPlaceholder()));
```

```dart
// 37. lib/features/bots/model_picker.dart:185 — target (model list fallback note (the sentence reads fine without a reason, so the placeholder is empty))
                      l10n.modelListFallback(list.error.orPlaceholder('')),
```

```dart
// 38. lib/features/workspaces/people_screen.dart:57 — target (People: member row name and pronouns)
                title: [m.name.orPlaceholder(m.email.orPlaceholder(m.userId)), if (m.pronouns.isUsable) '(${m.pronouns})'].join(' '),
```

```dart
// 39. lib/features/workspaces/people_screen.dart:402–403 — target (People: join request rows)
                title: r.displayName.orPlaceholder(r.email.orPlaceholder(r.userId)),
                subtitle: [if (r.displayName.isUsable && r.email.isUsable) r.email!, relativeTime(r.createdAt, context)].join(' · '),
```

```dart
// 40. lib/features/workspaces/join_flow.dart:197 — target (invite preview: " invited you to join")
            eyebrow: p.inviterName.isUsable ? l10n.invitedBy(p.inviterName!) : l10n.invitedToJoin,
```

```dart
// 41. lib/features/workspaces/join_flow.dart:206 — target (invite preview: "Sign in with  to accept.")
              if (p.emailHint.isUsable) l10n.inviteSentTo(p.emailHint!),
```

```dart
// 42. lib/features/workspaces/workspace_files.dart:74 — target (Git sync row: folder)
                      '${sync.repo}@${sync.branch}${sync.path.isUsable ? '/${sync.path}' : ''}',
```

```dart
// 43. lib/features/workspaces/workspace_files.dart:76 — target (Git sync row: last error)
                      if (sync.lastError.isUsable) sync.lastError!,
```

```dart
// 44. lib/features/workspaces/spaces.dart:953 — target (Payments sheet: webhook URL)
        if (widget.current.webhookUrl.isUsable) SelectableText('${l10n.paymentsWebhook}: ${widget.current.webhookUrl}'),
```

```dart
// 45. lib/features/workspaces/spaces.dart:989 — target (Secret store row prints the word "null" when the project or environment is missing)
          subtitle: infisical ? 'Infisical · ${s.projectId.orPlaceholder()} · ${s.environment.orPlaceholder()}' : l10n.secretStoreVault,
```

```dart
// 46. lib/features/teach/teach_draft_screen.dart:169 — target (taught step: page URL)
              subtitle: st.url.isUsable ? Text(st.url!, maxLines: 1, overflow: TextOverflow.ellipsis) : null,
```

```dart
// 47. lib/features/teach/teach_draft_screen.dart:209–210 — target (taught step labels: "Type “”", "Press ")
    TeachStepKindEnum.type => s.secretName.isUsable ? l10n.teachStepSecret(s.secretName!) : l10n.teachStepType(s.text.orPlaceholder()),
    TeachStepKindEnum.key => l10n.teachStepKey(s.key.orPlaceholder()),
```

```dart
// 48. lib/features/board/board_screen.dart:589 — target (task details: result card)
          if (task.resultMd.isUsable) AppCard(child: Text(task.resultMd!)),
```

```dart
// 49. lib/features/routines/routines_screen.dart:68 — target (webhook-created sheet gate)
    if (created.webhookUrl.isUsable) {
```

```dart
// 50. lib/features/routines/routines_screen.dart:103–104 — target (webhook-created sheet: URL and secret)
              field(l10n.webhookUrl, created.webhookUrl.orPlaceholder()),
              field(l10n.webhookSecret, created.webhookSecret.orPlaceholder(), key: const Key('webhookSecret')),
```

```dart
// 51. lib/features/routines/routines_screen.dart:136 — target (routine row: schedule)
      RoutineTrigger.schedule => (LucideIcons.repeat, l10n.routineSchedule(scheduleWords(context, r.scheduleCron.orPlaceholder()), r.timezone)),
```

```dart
// 52. lib/features/skills/skills_screen.dart:115 — target (skill row: "GitHub " with no repo (the value is an Object?, so call toString first, as the article shows))
                              'github' => 'GitHub ${(s.sourceRef['repo']?.toString()).orPlaceholder()}',
```

```dart
// 53. lib/features/chat/chat_screen.dart:1379 — target (chat list: a chat whose title is empty shows a blank row)
                          c.title.orPlaceholder(l10n.untitledChat),
```

```dart
// 54. lib/features/groups/group_chats.dart:26 — target (group chat title)
    c.title.isUsable ? c.title! : c.botIds.map((id) => bots.where((b) => b.id == id).firstOrNull?.name ?? '').where((n) => n.isNotEmpty).join(', ');
```

```dart
// 55. lib/features/usage/usage_screen.dart:121 — target (Usage → By bot: a bot name (only the first element of the record changes))
                  for (final b in report.byBot) (b.name.orPlaceholder(l10n.deletedBot), b.costUsd.toDouble(), b.tokensIn + b.tokensOut == 0 ? '' : '${compactNumber(b.tokensIn + b.tokensOut)} tokens'),
```

```dart
// 56. lib/features/usage/usage_screen.dart:397 — target (Usage → By model: model name)
                    m.model.isUsable ? names[m.model] ?? m.model! : context.l10n.otherModel,
```

```dart
// 57. lib/features/billing/billing_screen.dart:383 — target (billed item: instance name)
      return (i.instance.isUsable ? '$what · ${i.instance}' : what, icon);
```

## Steps

1. Create `lib/core/display_text.dart` with exactly the content in "The fix". Leave `D-NNN`
   for now; step 5 replaces it. Run `dart format -l 200 lib/core/display_text.dart` (the only
   source file you may format).
2. For each of the 29 files in "Where", in order:
   a. Replace every quoted line of that file with its target, finding each line by its quoted
      text (the line numbers shift as you edit). Edit by hand; never run `dart format` on
      these files.
   b. Then add the line `import '../../core/display_text.dart';` directly above the file's line
      `import '../../core/providers.dart';` (all 29 files have it).
3. Create `test/display_text_test.dart` with this content, then run
   `dart format -l 200 test/display_text_test.dart`:
   ```dart
   import 'package:flutter_test/flutter_test.dart';
   import 'package:casama_app/core/display_text.dart';

   void main() {
     test('null, empty, blank and the word "null" are not usable', () {
       for (final value in <String?>[null, '', '   ', 'null']) {
         expect(value.isUsable, isFalse, reason: '$value');
         expect(value.orPlaceholder(), '—', reason: '$value');
         expect(value.orPlaceholder('Untitled chat'), 'Untitled chat', reason: '$value');
       }
     });

     test('real text passes through as it is', () {
       expect('Ada'.isUsable, isTrue);
       expect('Ada'.orPlaceholder(), 'Ada');
       expect(' Ada '.orPlaceholder(), ' Ada ');
       expect('nullable'.orPlaceholder(), 'nullable');
     });

     test('non-text values go through toString first', () {
       final Map<String, Object?> sourceRef = {'repo': null};
       expect((sourceRef['repo']?.toString()).orPlaceholder(), kMissingValue);
     });
   }
   ```
4. From `client/`, run
   `flutter test test/display_text_test.dart test/attention_test.dart test/inbox_feed_test.dart test/bot_template_test.dart test/channels_test.dart test/plugins_test.dart test/links_test.dart test/bot_to_bot_test.dart test/knowledge_test.dart test/sharing_test.dart test/bot_management_test.dart test/design_test.dart test/account_test.dart test/chatgpt_test.dart test/admin_test.dart test/mcp_test.dart test/cloud_model_picker_test.dart test/joining_test.dart test/spaces_test.dart test/workspace_files_test.dart test/secret_store_test.dart test/payments_test.dart test/teach_test.dart test/board_test.dart test/routine_editor_test.dart test/skill_library_test.dart test/group_chats_test.dart test/billing_test.dart test/app_test.dart test/phone_layout_test.dart`.
   All must pass. No existing expectation should need to change: every test uses real values.
5. Record the decision. Open `/Users/nemoryoliver/Desktop/Projects/Kasama/docs/DECISIONS.md`,
   find the highest `## D-NNN` number in the whole file right now (others add entries in
   parallel, so read it at this moment), and append this entry at the very end of the file with
   the next free number in place of `D-NNN`:
   ```markdown
   ## D-NNN Missing values show an em dash

   - **Decision**: a text value from the server that is null, empty, blank or the word "null" is never shown as it is. `client/lib/core/display_text.dart` has `isUsable` and `orPlaceholder()`; screens hide a line that only adds detail and show `—` (`kMissingValue`) where a value must appear, or a better word when there is one ("Untitled chat").
   - **Why the em dash**: it is the usual mark for "no value" in every language, so it needs no translation, and bot history already used it.
   - **Tests**: `client/test/display_text_test.dart`.
   ```
   Then, in `lib/core/display_text.dart`, replace `D-NNN` in the first comment with the same
   number (for example `(D-189)`).

## Check it

- `dart analyze lib/core/display_text.dart test/display_text_test.dart` plus every file listed
  in "Where" reports no issues.
- `grep -c "display_text.dart" <file>` → 1 for each of the 29 files in "Where".
- `grep -c "?? ''" lib/features/inbox/inbox_screen.dart` → 1 (the `botName` lookup on line 138 stays)
- `grep -c "?? ''" lib/features/bots/plugins_screen.dart` → 0
- `grep -c "?? ''" lib/features/bots/links_screen.dart` → 1 (the `?.host ?? ''` on line 99 stays)
- `grep -c "?? ''" lib/features/teach/teach_draft_screen.dart` → 0
- `grep -c "?? ''" lib/features/settings/model_keys_screen.dart` → 0
- `grep -c "?? ''" lib/features/integrations/integration_detail_screen.dart` → 0
- `grep -cE "isUsable|orPlaceholder" lib/features/bots/channels_screen.dart` → 6
- `grep -cE "isUsable|orPlaceholder" lib/features/workspaces/people_screen.dart` → 3
- `grep -c "s.environment.orPlaceholder()" lib/features/workspaces/spaces.dart` → 1
- `grep -c "kMissingValue" lib/features/bots/bot_history_screen.dart` → 1
- `grep -c "'—'" lib/features/bots/bot_history_screen.dart` → 0
- `grep -c "Missing values show an em dash" /Users/nemoryoliver/Desktop/Projects/Kasama/docs/DECISIONS.md` → 1
- `grep -c "D-NNN" lib/core/display_text.dart` → 0
- The `flutter test` run in step 4 passes.

## Don't touch

- Editable fields' starting text (`TextEditingController(text: x ?? '')`): an empty field is
  right there; a dash would be typed over.
- Values copied to the clipboard (`Clipboard.setData(… ?? '')`) and the Git webhook dialog in
  `workspace_files.dart` (line 200), where the same value is shown and copied: a placeholder
  must never end up on the clipboard.
- Parsing in `lib/core/` (`backend.dart`, `supabase_backend.dart`, `voice.dart`, `push.dart`,
  `gemini_live.dart`) and `lib/features/voice/phone_calls.dart`: the guard belongs where text
  reaches the screen.
- Lookups of a bot by id (`bots.where(…).firstOrNull?.name ?? ''`, `bot?.name ?? l10n.aBot`,
  `for_you.dart`, `pages_screen.dart`, `inbox_screen.dart` line 138): `Bot.name` is never null;
  those cover a bot missing from the list, a different case.
- The signed-in person's own name and email in `settings_screen.dart` (lines 53, 66, 79, 89, 96)
  and `me_avatar.dart`: already checked for empty before they show, and they come from the
  sign-in session.
- Text written for bots, files or other tools: `usageSummary` and `usageCsv` in
  `usage_screen.dart`, `error_details.dart`'s report, the GitHub issue link in
  `gallery_screen.dart`, `desktop_context.dart`.
- App-local state and loading text (`_error`, `_cwd`, `_link`, `quick_ask_screen.dart`'s `_ctx`,
  `local_server_sheet.dart`'s `p?.detail`, `snap.data ?? '…'`), widget keys, search filters,
  `tool_words.dart` and the tool summary in `chat_widgets.dart`.
- `spaces.dart` line 718 (Phone calls row): it only shows when the account is connected, which
  means a number is saved.
- `routines_screen.dart` line 142 (device trigger detail) and `skill_library.dart` line 122
  (`f.text ?? l10n.binaryFile`: null means a binary file; an empty text file really is empty).
- Non-nullable `String` fields (for example a notification's `title`): out of this fix.
- Never run `dart format` on existing files or directories (only on the two new files).
- No git commands (others commit in this shared tree).
- No new dependencies. No refactors, renames, or cleanups beyond the fix.

## STOP if

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on
  since this plan was written). One exception: on `usage_screen.dart` line 121 the third
  element of the record (`… tokens'`) may already read differently, for example
  `'${(b.tokensIn + b.tokensOut).humanizedCompact(context.l10n.localeName)} tokens'`; keep it
  exactly as it is now and change only the first element.
- A file in "Where" has no `import '../../core/providers.dart';` line.
- The fix seems to require touching something in "Don't touch".
- A check fails twice.

## When you're done

Tell the developer, in two or three sentences, what's different in the app now and one place to
open to see it. Not a list of files, the steps already have those. For example: missing values
from the server now either disappear or show a quiet "—" instead of blanks, dangling sentences
or the word "null"; open Settings → Workspace → Secret store with Infisical and no environment
to see "Infisical · proj-1 · —".
