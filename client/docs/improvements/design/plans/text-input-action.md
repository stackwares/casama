# Fix: The keyboard's action key doesn't move through forms or submit them

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/text-input-action
- **Needs new dependency**: none

## Why

Casama has many forms with several one-line fields: adding a secret, connecting a password
manager, the memory, phone, payments and secret-store sheets, git sync, adding an integration, a
model key, a plugin, knowledge, an action rule, a routine, a project, a new password. Almost none
set `textInputAction`. So the keyboard's action key always says "done" and just closes the
keyboard, and people tap each field by hand and then reach for the Save button. With the right
keyboard actions, Next moves to the next field and the last field's key submits the form, the same
as the main button. Multi-line fields keep their return key for new lines.

There is one trap in this app. A field with a trailing button (the eye button of `Revealable`, a
paste or scan button) puts that button next in focus order, so "Next" would land on the eye button
instead of the next field. On phones and tablets those buttons are taken out of the keyboard's
Next order with one small shared widget, and Tab on a desktop keyboard still reaches them. This was
checked: without it, Next from the new-password field focuses the eye button.

## Where

Every affected location, grouped by form. Each block quotes the current code exactly (lines
starting with `-`) and shows the target (lines starting with `+`). The quoted lines are the
location. Line numbers are where the code was when this plan was written.

The rules applied, from the article:

- A one-line field that has another field after it: `textInputAction: TextInputAction.next`.
  Flutter moves focus to the next field on its own, with no `FocusNode`.
- The last one-line field of a form: `textInputAction: TextInputAction.done`, plus `onSubmitted`
  (or `onFieldSubmitted` for `TextFormField`). It calls the same thing the form's main button
  calls, under the same condition: if the button is disabled (`null`), the key does nothing.
- Multi-line fields (`maxLines` above 1): untouched. Their return key inserts a new line.
- Never `onEditingComplete`: providing it replaces the default next and close behaviour.

When the main button's handler is an inline closure, the plan doesn't move it. It keeps it in a
local `submit` (or `create`) variable at the same spot, with an assignment
(`onSubmit: submit = ...`), and the last field calls `submit?.call()`. That is two small edits
instead of moving 20-40 lines.

#### 1. Shared: keep field buttons out of the Next order — `lib/ui/revealable.dart`

`lib/ui/revealable.dart:1`

```diff
-import 'package:flutter/material.dart';
+import 'package:flutter/foundation.dart';
+import 'package:flutter/material.dart';
```

`lib/ui/revealable.dart:22-27`

```diff
-    final toggle = IconButton(
-      key: const Key('revealToggle'),
-      tooltip: _hidden ? l10n.show : l10n.hide,
-      icon: Icon(_hidden ? LucideIcons.eye : LucideIcons.eyeOff, size: 20),
-      onPressed: () => setState(() => _hidden = !_hidden),
-    );
+    final toggle = FieldSuffix(
+      child: IconButton(
+        key: const Key('revealToggle'),
+        tooltip: _hidden ? l10n.show : l10n.hide,
+        icon: Icon(_hidden ? LucideIcons.eye : LucideIcons.eyeOff, size: 20),
+        onPressed: () => setState(() => _hidden = !_hidden),
+      ),
+    );
```

`lib/ui/revealable.dart:28-30`

```diff
-    return widget.builder(context, _hidden, toggle);
-  }
-}
+    return widget.builder(context, _hidden, toggle);
+  }
+}
+
+/// Keeps a field's trailing buttons (show, paste, scan) out of the keyboard's Next order on phones
+/// and tablets, so Next moves to the next field instead of landing on a button. Tab on a desktop
+/// keyboard still reaches them.
+class FieldSuffix extends StatelessWidget {
+  const FieldSuffix({super.key, required this.child});
+  final Widget child;
+
+  @override
+  Widget build(BuildContext context) => ExcludeFocusTraversal(
+    excluding: defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android,
+    child: child,
+  );
+}
```

#### 2. Add secret (name, value, allowed hosts) — `lib/features/settings/secrets_screen.dart`

`lib/features/settings/secrets_screen.dart:140-141`

```diff
-          key: const Key('secretName'),
-          controller: _name,
+          key: const Key('secretName'),
+          controller: _name,
+          textInputAction: TextInputAction.next,
```

`lib/features/settings/secrets_screen.dart:163-164`

```diff
-          key: const Key('secretValue'),
-          controller: _value,
+          key: const Key('secretValue'),
+          controller: _value,
+          textInputAction: TextInputAction.next,
```

`lib/features/settings/secrets_screen.dart:172-191`

```diff
-            suffixIcon: Row(
-              mainAxisSize: MainAxisSize.min,
-              children: [
-                if (_totp)
-                  TotpScanButton(
-                    onScanned: (link) => setState(() {
-                      _value.text = link;
-                      final issuer = Uri.tryParse(link)?.queryParameters['issuer'];
-                      if (_name.text.isEmpty && issuer != null && issuer.isNotEmpty) {
-                        _name.text = '${issuer.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]+'), '_')}_2FA';
-                      }
-                    }),
-                  ),
-                IconButton(
-                  tooltip: _show ? l10n.hide : l10n.show,
-                  icon: Icon(_show ? LucideIcons.eyeOff : LucideIcons.eye, size: 20),
-                  onPressed: () => setState(() => _show = !_show),
-                ),
-              ],
-            ),
+            suffixIcon: FieldSuffix(
+              child: Row(
+                mainAxisSize: MainAxisSize.min,
+                children: [
+                  if (_totp)
+                    TotpScanButton(
+                      onScanned: (link) => setState(() {
+                        _value.text = link;
+                        final issuer = Uri.tryParse(link)?.queryParameters['issuer'];
+                        if (_name.text.isEmpty && issuer != null && issuer.isNotEmpty) {
+                          _name.text = '${issuer.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]+'), '_')}_2FA';
+                        }
+                      }),
+                    ),
+                  IconButton(
+                    tooltip: _show ? l10n.hide : l10n.show,
+                    icon: Icon(_show ? LucideIcons.eyeOff : LucideIcons.eye, size: 20),
+                    onPressed: () => setState(() => _show = !_show),
+                  ),
+                ],
+              ),
+            ),
```

`lib/features/settings/secrets_screen.dart:196-197`

```diff
-          key: const Key('secretHosts'),
-          controller: _hosts,
+          key: const Key('secretHosts'),
+          controller: _hosts,
+          textInputAction: TextInputAction.done,
+          onSubmitted: (_) {
+            if (valid) Navigator.pop(context, (_name.text, _value.text.trim(), _hostList, _totp));
+          },
```

#### 3. Connect a password manager (name, URL, token) — `lib/features/settings/password_managers_screen.dart`

`lib/features/settings/password_managers_screen.dart:124`

```diff
-      onSubmit: !valid || _busy
+      // Also run by the keyboard's Done key on the last field.
+      onSubmit: submit = !valid || _busy
```

`lib/features/settings/password_managers_screen.dart:118-120`

```diff
-    return FormSheet(
-      icon: LucideIcons.keyRound,
-      title: l10n.connectPasswordManager,
+    VoidCallback? submit;
+    return FormSheet(
+      icon: LucideIcons.keyRound,
+      title: l10n.connectPasswordManager,
```

`lib/features/settings/password_managers_screen.dart:153`

```diff
-        TextField(key: const Key('pmName'), controller: _name, onChanged: (_) => setState(() {}), decoration: InputDecoration(labelText: l10n.botNameLabel)),
+        TextField(key: const Key('pmName'), controller: _name, textInputAction: TextInputAction.next, onChanged: (_) => setState(() {}), decoration: InputDecoration(labelText: l10n.botNameLabel)),
```

`lib/features/settings/password_managers_screen.dart:154`

```diff
-        TextField(key: const Key('pmUrl'), controller: _url, onChanged: (_) => setState(() {}), decoration: InputDecoration(labelText: onePw ? l10n.pmConnectUrl : l10n.pmBwUrl)),
+        TextField(key: const Key('pmUrl'), controller: _url, textInputAction: TextInputAction.next, onChanged: (_) => setState(() {}), decoration: InputDecoration(labelText: onePw ? l10n.pmConnectUrl : l10n.pmBwUrl)),
```

`lib/features/settings/password_managers_screen.dart:155`

```diff
-        Revealable(builder: (context, hidden, toggle) => TextField(key: const Key('pmToken'), controller: _token, obscureText: hidden, onChanged: (_) => setState(() {}), decoration: InputDecoration(labelText: onePw ? l10n.pmConnectToken : l10n.pmBwToken, suffixIcon: toggle))),
+        Revealable(builder: (context, hidden, toggle) => TextField(key: const Key('pmToken'), controller: _token, textInputAction: TextInputAction.done, onSubmitted: (_) => submit?.call(), obscureText: hidden, onChanged: (_) => setState(() {}), decoration: InputDecoration(labelText: onePw ? l10n.pmConnectToken : l10n.pmBwToken, suffixIcon: toggle))),
```

#### 4. Memory backend sheet (API key, workspace, base URL) — `lib/features/workspaces/spaces.dart`

`lib/features/workspaces/spaces.dart:637-638`

```diff
-          key: const Key('memoryApiKey'),
-          controller: _key,
+          key: const Key('memoryApiKey'),
+          controller: _key,
+          textInputAction: TextInputAction.next,
```

`lib/features/workspaces/spaces.dart:645-646`

```diff
-            key: const Key('memoryWorkspace'),
-            controller: _workspace,
+            key: const Key('memoryWorkspace'),
+            controller: _workspace,
+            textInputAction: TextInputAction.next,
```

`lib/features/workspaces/spaces.dart:650-651`

```diff
-          key: const Key('memoryUrl'),
-          controller: _url,
+          key: const Key('memoryUrl'),
+          controller: _url,
+          textInputAction: TextInputAction.done,
+          onSubmitted: (_) {
+            if (!_busy && _key.text.trim().length >= 8) _save();
+          },
```

#### 5. Phone calls sheet (SID, token, from number, daily cap) — `lib/features/workspaces/spaces.dart`

`lib/features/workspaces/spaces.dart:763-764`

```diff
-    return FormSheet(
-      icon: LucideIcons.phoneOutgoing,
+    VoidCallback? submit;
+    return FormSheet(
+      icon: LucideIcons.phoneOutgoing,
```

`lib/features/workspaces/spaces.dart:768-769`

```diff
-      submitKey: const Key('savePhoneCalls'),
-      onSubmit: !_valid || _busy
+      submitKey: const Key('savePhoneCalls'),
+      // Also run by the keyboard's Done key on the last field.
+      onSubmit: submit = !_valid || _busy
```

`lib/features/workspaces/spaces.dart:795-796`

```diff
-          key: const Key('twilioSid'),
-          controller: _sid,
+          key: const Key('twilioSid'),
+          controller: _sid,
+          textInputAction: TextInputAction.next,
```

`lib/features/workspaces/spaces.dart:801-802`

```diff
-          key: const Key('twilioToken'),
-          controller: _token,
+          key: const Key('twilioToken'),
+          controller: _token,
+          textInputAction: TextInputAction.next,
```

`lib/features/workspaces/spaces.dart:808-809`

```diff
-          key: const Key('twilioFrom'),
-          controller: _from,
+          key: const Key('twilioFrom'),
+          controller: _from,
+          textInputAction: TextInputAction.next,
```

`lib/features/workspaces/spaces.dart:815-816`

```diff
-          key: const Key('phoneCallsCap'),
-          controller: _cap,
+          key: const Key('phoneCallsCap'),
+          controller: _cap,
+          textInputAction: TextInputAction.done,
+          onSubmitted: (_) => submit?.call(),
```

#### 6. Payments sheet (13 fields through a field() helper) — `lib/features/workspaces/spaces.dart`

`lib/features/workspaces/spaces.dart:906-915`

```diff
-    final l10n = context.l10n;
-    Widget field(String key, TextEditingController c, String label, {bool secret = false}) => Revealable(builder: (context, hidden, toggle) => TextField(
-      key: Key(key),
-      controller: c,
-      obscureText: hidden && (secret),
-      onChanged: (_) => setState(() {}),
-      decoration: InputDecoration(labelText: label, suffixIcon: (secret) ? toggle : null),
-    ));
-    return FormSheet(
-      icon: LucideIcons.creditCard,
+    final l10n = context.l10n;
+    VoidCallback? submit;
+    Widget field(String key, TextEditingController c, String label, {bool secret = false, bool last = false}) => Revealable(builder: (context, hidden, toggle) => TextField(
+      key: Key(key),
+      controller: c,
+      obscureText: hidden && (secret),
+      // Next moves down the form; Done on the last field saves it.
+      textInputAction: last ? TextInputAction.done : TextInputAction.next,
+      onSubmitted: last ? (_) => submit?.call() : null,
+      onChanged: (_) => setState(() {}),
+      decoration: InputDecoration(labelText: label, suffixIcon: (secret) ? toggle : null),
+    ));
+    return FormSheet(
+      icon: LucideIcons.creditCard,
```

`lib/features/workspaces/spaces.dart:919-920`

```diff
-      submitKey: const Key('savePayments'),
-      onSubmit: !_valid || _busy
+      submitKey: const Key('savePayments'),
+      // Also run by the keyboard's Done key on the last field.
+      onSubmit: submit = !_valid || _busy
```

`lib/features/workspaces/spaces.dart:964`

```diff
-        field('paymentsBotCap', _botCap, l10n.paymentsBotCap),
+        field('paymentsBotCap', _botCap, l10n.paymentsBotCap, last: true),
```

#### 7. Secret store sheet (5 fields through a field() helper) — `lib/features/workspaces/spaces.dart`

`lib/features/workspaces/spaces.dart:1032-1040`

```diff
-    Widget field(String key, TextEditingController c, String label, {bool secret = false}) => Revealable(builder: (context, hidden, toggle) => TextField(
-      key: Key(key),
-      controller: c,
-      obscureText: hidden && (secret),
-      onChanged: (_) => setState(() {}),
-      decoration: InputDecoration(labelText: label, suffixIcon: (secret) ? toggle : null),
-    ));
-    return FormSheet(
-      icon: LucideIcons.vault,
+    VoidCallback? submit;
+    Widget field(String key, TextEditingController c, String label, {bool secret = false, bool last = false}) => Revealable(builder: (context, hidden, toggle) => TextField(
+      key: Key(key),
+      controller: c,
+      obscureText: hidden && (secret),
+      // Next moves down the form; Done on the last field saves it.
+      textInputAction: last ? TextInputAction.done : TextInputAction.next,
+      onSubmitted: last ? (_) => submit?.call() : null,
+      onChanged: (_) => setState(() {}),
+      decoration: InputDecoration(labelText: label, suffixIcon: (secret) ? toggle : null),
+    ));
+    return FormSheet(
+      icon: LucideIcons.vault,
```

`lib/features/workspaces/spaces.dart:1044-1045`

```diff
-      submitKey: const Key('saveSecretStore'),
-      onSubmit: !valid || _busy
+      submitKey: const Key('saveSecretStore'),
+      // Also run by the keyboard's Done key on the last field.
+      onSubmit: submit = !valid || _busy
```

`lib/features/workspaces/spaces.dart:1075`

```diff
-        field('infisicalClientSecret', _clientSecret, l10n.secretStoreClientSecret, secret: true),
+        field('infisicalClientSecret', _clientSecret, l10n.secretStoreClientSecret, secret: true, last: true),
```

#### 8. Routine editor (name, then the trigger fields) — `lib/features/routines/routines_screen.dart`

`lib/features/routines/routines_screen.dart:346-347`

```diff
-    return SingleChildScrollView(
-      padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.md),
+    VoidCallback? create;
+    return SingleChildScrollView(
+      padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.md),
```

`lib/features/routines/routines_screen.dart:355-356`

```diff
-            key: const Key('routineName'),
-            controller: _name,
+            key: const Key('routineName'),
+            controller: _name,
+            textInputAction: TextInputAction.next,
```

`lib/features/routines/routines_screen.dart:417-418`

```diff
-              TextField(
-                controller: _titleMatch,
+              TextField(
+                controller: _titleMatch,
+                textInputAction: TextInputAction.done,
+                onSubmitted: (_) => create?.call(),
```

`lib/features/routines/routines_screen.dart:439-440`

```diff
-              key: const Key('messageSender'),
-              controller: _msgSender,
+              key: const Key('messageSender'),
+              controller: _msgSender,
+              textInputAction: TextInputAction.next,
```

`lib/features/routines/routines_screen.dart:445-446`

```diff
-              key: const Key('messageSubject'),
-              controller: _msgSubject,
+              key: const Key('messageSubject'),
+              controller: _msgSubject,
+              textInputAction: TextInputAction.next,
```

`lib/features/routines/routines_screen.dart:451-452`

```diff
-              key: const Key('messageText'),
-              controller: _msgText,
+              key: const Key('messageText'),
+              controller: _msgText,
+              textInputAction: TextInputAction.done,
+              onSubmitted: (_) => create?.call(),
```

`lib/features/routines/routines_screen.dart:543-544`

```diff
-                  key: const Key('routineCron'),
-                  controller: _cron,
+                  key: const Key('routineCron'),
+                  controller: _cron,
+                  textInputAction: TextInputAction.next,
```

`lib/features/routines/routines_screen.dart:550-551`

```diff
-                  key: const Key('routineTimezone'),
-                  controller: _timezone,
+                  key: const Key('routineTimezone'),
+                  controller: _timezone,
+                  textInputAction: TextInputAction.done,
+                  onSubmitted: (_) => create?.call(),
```

`lib/features/routines/routines_screen.dart:560-562`

```diff
-            key: const Key('createRoutine'),
-            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
-            onPressed: _busy || !valid
+            key: const Key('createRoutine'),
+            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
+            // Also run by the keyboard's Done key on the last field.
+            onPressed: create = _busy || !valid
```

#### 9. Add integration (name, URL/command, extra field, apps, secret) — `lib/features/integrations/integrations_screen.dart`

`lib/features/integrations/integrations_screen.dart:645-646`

```diff
-          key: const Key('integrationName'),
-          controller: _name,
+          key: const Key('integrationName'),
+          controller: _name,
+          textInputAction: TextInputAction.next,
```

`lib/features/integrations/integrations_screen.dart:655-656`

```diff
-          key: const Key('integrationPrimary'),
-          controller: _primary,
+          key: const Key('integrationPrimary'),
+          controller: _primary,
+          textInputAction: TextInputAction.next,
```

`lib/features/integrations/integrations_screen.dart:668-669`

```diff
-          TextField(
-            controller: _secondary,
+          TextField(
+            controller: _secondary,
+            textInputAction: TextInputAction.next,
```

`lib/features/integrations/integrations_screen.dart:674-675`

```diff
-          TextField(
-            controller: _apps,
+          TextField(
+            controller: _apps,
+            textInputAction: TextInputAction.next,
```

`lib/features/integrations/integrations_screen.dart:679-680`

```diff
-          key: const Key('integrationSecret'),
-          controller: _secret,
+          key: const Key('integrationSecret'),
+          controller: _secret,
+          textInputAction: TextInputAction.done,
+          onSubmitted: (_) {
+            if (missing == null) _save(name);
+          },
```

#### 10. About you (name, pronouns, then two multi-line fields) — `lib/features/settings/about_you_screen.dart`

`lib/features/settings/about_you_screen.dart:136-137`

```diff
-                key: const Key('aboutName'),
-                controller: _name,
+                key: const Key('aboutName'),
+                controller: _name,
+                textInputAction: TextInputAction.next,
```

`lib/features/settings/about_you_screen.dart:144-145`

```diff
-                key: const Key('aboutPronouns'),
-                controller: _pronouns,
+                key: const Key('aboutPronouns'),
+                controller: _pronouns,
+                textInputAction: TextInputAction.next,
```

#### 11. New project (title, goal, done-when, lead, budget) — `lib/features/projects/projects_screen.dart`

`lib/features/projects/projects_screen.dart:123-124`

```diff
-    return FormSheet(
-      icon: LucideIcons.target,
+    VoidCallback? submit;
+    return FormSheet(
+      icon: LucideIcons.target,
```

`lib/features/projects/projects_screen.dart:129-132`

```diff
-      onSubmit: !valid || _busy
-          ? null
-          : () async {
-              final org = ref.read(currentOrgProvider);
+      // Also run by the keyboard's Done key on the last field.
+      onSubmit: submit = !valid || _busy
+          ? null
+          : () async {
+              final org = ref.read(currentOrgProvider);
```

`lib/features/projects/projects_screen.dart:151`

```diff
-        TextField(key: const Key('projectTitle'), controller: _title, autofocus: true, decoration: InputDecoration(labelText: l10n.projectTitle), onChanged: (_) => setState(() {})),
+        TextField(key: const Key('projectTitle'), controller: _title, textInputAction: TextInputAction.next, autofocus: true, decoration: InputDecoration(labelText: l10n.projectTitle), onChanged: (_) => setState(() {})),
```

`lib/features/projects/projects_screen.dart:163-164`

```diff
-          key: const Key('projectBudget'),
-          controller: _budget,
+          key: const Key('projectBudget'),
+          controller: _budget,
+          textInputAction: TextInputAction.done,
+          onSubmitted: (_) => submit?.call(),
```

#### 12. Local MCP server (name, then URL or command) — `lib/features/companion/companion_screen.dart`

`lib/features/companion/companion_screen.dart:375-376`

```diff
-            key: const Key('localMcpUrl'),
-            controller: _url,
+            key: const Key('localMcpUrl'),
+            controller: _url,
+            textInputAction: TextInputAction.done,
+            onSubmitted: (_) => _submit(),
```

#### 13. Connect a chat app (name, the app's fields, then senders) — `lib/features/bots/channels_screen.dart`

`lib/features/bots/channels_screen.dart:215-216`

```diff
-          key: const Key('channelName'),
-          controller: _name,
+          key: const Key('channelName'),
+          controller: _name,
+          textInputAction: TextInputAction.next,
```

`lib/features/bots/channels_screen.dart:222-223`

```diff
-            key: Key('channelField-${f.$1}'),
-            controller: _c(f.$1),
+            key: Key('channelField-${f.$1}'),
+            controller: _c(f.$1),
+            textInputAction: TextInputAction.next,
```

#### 14. Admin: workspace limits (max bots, monthly USD) — `lib/features/admin/admin_screen.dart`

`lib/features/admin/admin_screen.dart:340-341`

```diff
-    return FormSheet(
-      icon: LucideIcons.slidersHorizontal,
+    VoidCallback? submit;
+    return FormSheet(
+      icon: LucideIcons.slidersHorizontal,
```

`lib/features/admin/admin_screen.dart:345-346`

```diff
-      submitKey: const Key('saveQuota'),
-      onSubmit: () => Navigator.pop(context, <String, num>{
+      submitKey: const Key('saveQuota'),
+      // Also run by the keyboard's Done key on the last field.
+      onSubmit: submit = () => Navigator.pop(context, <String, num>{
```

`lib/features/admin/admin_screen.dart:352-353`

```diff
-          key: const Key('maxBots'),
-          controller: _bots,
+          key: const Key('maxBots'),
+          controller: _bots,
+          textInputAction: TextInputAction.next,
```

`lib/features/admin/admin_screen.dart:358-359`

```diff
-          key: const Key('monthlyUsd'),
-          controller: _usd,
+          key: const Key('monthlyUsd'),
+          controller: _usd,
+          textInputAction: TextInputAction.done,
+          onSubmitted: (_) => submit?.call(),
```

#### 15. Admin: cloud models (ten fields through a box() helper) — `lib/features/admin/admin_screen.dart`

`lib/features/admin/admin_screen.dart:476-480`

```diff
-    Widget box(Key key, TextEditingController controller, String label) => TextField(
-      key: key,
-      controller: controller,
-      decoration: field(label),
-    );
+    VoidCallback? submit;
+    // Next moves down the list. Images is followed by the resolution dropdown, so its key just
+    // closes the keyboard. Done on the last field saves.
+    Widget box(Key key, TextEditingController controller, String label, {TextInputAction action = TextInputAction.next, bool last = false}) => TextField(
+      key: key,
+      controller: controller,
+      textInputAction: last ? TextInputAction.done : action,
+      onSubmitted: last ? (_) => submit?.call() : null,
+      decoration: field(label),
+    );
```

`lib/features/admin/admin_screen.dart:486-487`

```diff
-      submitKey: const Key('saveCloudModels'),
-      onSubmit: () {
+      submitKey: const Key('saveCloudModels'),
+      // Also run by the keyboard's Done key on the last field.
+      onSubmit: submit = () {
```

`lib/features/admin/admin_screen.dart:509`

```diff
-        box(const Key('cloudImage'), _image, 'Images'),
+        box(const Key('cloudImage'), _image, 'Images', action: TextInputAction.done),
```

`lib/features/admin/admin_screen.dart:527`

```diff
-        box(const Key('cloudVideo'), _video, 'Video'),
+        box(const Key('cloudVideo'), _video, 'Video', last: true),
```

#### 16. Sign in (email, password) — `lib/features/auth/sign_in_screen.dart`

`lib/features/auth/sign_in_screen.dart:577`

```diff
-                                      onFieldSubmitted: (_) => _submit(),
+                                      textInputAction: TextInputAction.done,
+                                      onFieldSubmitted: (_) => _submit(),
```

#### 17. Git sync (repository, branch, folder) — `lib/features/workspaces/workspace_files.dart`

`lib/features/workspaces/workspace_files.dart:152-153`

```diff
-    return FormSheet(
-      icon: LucideIcons.gitBranch,
+    VoidCallback? submit;
+    return FormSheet(
+      icon: LucideIcons.gitBranch,
```

`lib/features/workspaces/workspace_files.dart:157-158`

```diff
-      submitKey: const Key('saveGitSync'),
-      onSubmit: !valid
+      submitKey: const Key('saveGitSync'),
+      // Also run by the keyboard's Done key on the last field.
+      onSubmit: submit = !valid
```

`lib/features/workspaces/workspace_files.dart:168`

```diff
-        TextField(key: const Key('gitRepo'), controller: _repo, onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'owner/repository')),
+        TextField(key: const Key('gitRepo'), controller: _repo, textInputAction: TextInputAction.next, onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'owner/repository')),
```

`lib/features/workspaces/workspace_files.dart:169`

```diff
-        TextField(key: const Key('gitBranch'), controller: _branch, decoration: InputDecoration(labelText: l10n.gitBranch)),
+        TextField(key: const Key('gitBranch'), controller: _branch, textInputAction: TextInputAction.next, decoration: InputDecoration(labelText: l10n.gitBranch)),
```

`lib/features/workspaces/workspace_files.dart:170`

```diff
-        TextField(key: const Key('gitPath'), controller: _path, decoration: InputDecoration(labelText: l10n.gitFolder)),
+        TextField(key: const Key('gitPath'), controller: _path, textInputAction: TextInputAction.done, onSubmitted: (_) => submit?.call(), decoration: InputDecoration(labelText: l10n.gitFolder)),
```

#### 18. Teach: skill draft (name, description, then instructions) — `lib/features/teach/teach_draft_screen.dart`

`lib/features/teach/teach_draft_screen.dart:134-135`

```diff
-            key: const Key('teachName'),
-            controller: _name,
+            key: const Key('teachName'),
+            controller: _name,
+            textInputAction: TextInputAction.next,
```

`lib/features/teach/teach_draft_screen.dart:141-142`

```diff
-            key: const Key('teachDescription'),
-            controller: _description,
+            key: const Key('teachDescription'),
+            controller: _description,
+            textInputAction: TextInputAction.next,
```

#### 19. Skill editor (name, description, then body) — `lib/features/skills/skills_screen.dart`

`lib/features/skills/skills_screen.dart:274-275`

```diff
-        TextField(
-          controller: _name,
+        TextField(
+          controller: _name,
+          textInputAction: TextInputAction.next,
```

`lib/features/skills/skills_screen.dart:283-284`

```diff
-        TextField(
-          controller: _description,
+        TextField(
+          controller: _description,
+          textInputAction: TextInputAction.next,
```

#### 20. Add a model key (label, API key, base URL) — `lib/features/settings/model_keys_screen.dart`

`lib/features/settings/model_keys_screen.dart:326-327`

```diff
-        TextField(
-          controller: _label,
+        TextField(
+          controller: _label,
+          textInputAction: TextInputAction.next,
```

`lib/features/settings/model_keys_screen.dart:335-336`

```diff
-            key: const Key('apiKey'),
-            controller: _key,
+            key: const Key('apiKey'),
+            controller: _key,
+            textInputAction: compatible ? TextInputAction.next : TextInputAction.done,
+            onSubmitted: compatible || _busy ? null : (_) => _add(),
```

`lib/features/settings/model_keys_screen.dart:342-361`

```diff
-              suffixIcon: Row(
-                mainAxisSize: MainAxisSize.min,
-                children: [
-                  IconButton(
-                    key: const Key('pasteApiKey'),
-                    tooltip: l10n.pasteLabel,
-                    icon: const Icon(LucideIcons.clipboardPaste, size: 18),
-                    onPressed: () async {
-                      final data = await Clipboard.getData(
-                        Clipboard.kTextPlain,
-                      );
-                      final text = data?.text?.trim();
-                      if (text != null && text.isNotEmpty) {
-                        setState(() => _key.text = text);
-                      }
-                    },
-                  ),
-                  toggle,
-                ],
-              ),
+              suffixIcon: FieldSuffix(
+                child: Row(
+                  mainAxisSize: MainAxisSize.min,
+                  children: [
+                    IconButton(
+                      key: const Key('pasteApiKey'),
+                      tooltip: l10n.pasteLabel,
+                      icon: const Icon(LucideIcons.clipboardPaste, size: 18),
+                      onPressed: () async {
+                        final data = await Clipboard.getData(
+                          Clipboard.kTextPlain,
+                        );
+                        final text = data?.text?.trim();
+                        if (text != null && text.isNotEmpty) {
+                          setState(() => _key.text = text);
+                        }
+                      },
+                    ),
+                    toggle,
+                  ],
+                ),
+              ),
```

`lib/features/settings/model_keys_screen.dart:370`

```diff
-            controller: _baseUrl,
+            controller: _baseUrl,
+            textInputAction: TextInputAction.done,
+            onSubmitted: _busy ? null : (_) => _add(),
```

#### 21. Add a plugin (GitHub URL, then its secrets) — `lib/features/bots/plugins_screen.dart`

`lib/features/bots/plugins_screen.dart:228-229`

```diff
-          key: const Key('pluginUrl'),
-          controller: _url,
+          key: const Key('pluginUrl'),
+          controller: _url,
+          textInputAction: TextInputAction.done,
+          onSubmitted: (_) {
+            if (ready && !_busy) _submit();
+          },
```

`lib/features/bots/plugins_screen.dart:238-239`

```diff
-              key: Key('pluginSecret-${s.name}'),
-              controller: _secrets[s.name],
+              key: Key('pluginSecret-${s.name}'),
+              controller: _secrets[s.name],
+              textInputAction: s == p.secrets.last ? TextInputAction.done : TextInputAction.next,
+              onSubmitted: s == p.secrets.last
+                  ? (_) {
+                      if (ready && !_busy) _submit();
+                    }
+                  : null,
```

#### 22. Update a plugin (its secrets) — `lib/features/bots/plugins_screen.dart`

`lib/features/bots/plugins_screen.dart:293-294`

```diff
-    return FormSheet(
-      icon: LucideIcons.refreshCw,
+    VoidCallback? submit;
+    return FormSheet(
+      icon: LucideIcons.refreshCw,
```

`lib/features/bots/plugins_screen.dart:298-299`

```diff
-      submitKey: const Key('pluginUpdate'),
-      onSubmit: _busy || _secrets.values.any((c) => c.text.trim().isEmpty)
+      submitKey: const Key('pluginUpdate'),
+      // Also run by the keyboard's Done key on the last field.
+      onSubmit: submit = _busy || _secrets.values.any((c) => c.text.trim().isEmpty)
```

`lib/features/bots/plugins_screen.dart:313-314`

```diff
-            key: Key('pluginSecret-${e.key}'),
-            controller: e.value,
+            key: Key('pluginSecret-${e.key}'),
+            controller: e.value,
+            textInputAction: e.key == _secrets.keys.last ? TextInputAction.done : TextInputAction.next,
+            onSubmitted: e.key == _secrets.keys.last ? (_) => submit?.call() : null,
```

#### 23. Accept a link (invite text, contact name) — `lib/features/bots/links_screen.dart`

`lib/features/bots/links_screen.dart:175-176`

```diff
-          key: const Key('acceptName'),
-          controller: _name,
+          key: const Key('acceptName'),
+          controller: _name,
+          textInputAction: TextInputAction.done,
+          onSubmitted: (_) {
+            if (ok) Navigator.pop(context, (_invite.text.trim(), _name.text.trim()));
+          },
```

#### 24. New ticket (title, then details) — `lib/features/board/board_screen.dart`

`lib/features/board/board_screen.dart:503`

```diff
-        TextField(key: const Key('ticketTitle'), controller: _title, decoration: InputDecoration(labelText: l10n.ticketTitle)),
+        TextField(key: const Key('ticketTitle'), controller: _title, textInputAction: TextInputAction.next, decoration: InputDecoration(labelText: l10n.ticketTitle)),
```

#### 25. Provider setup (project, client ID, key, through a field() helper) — `lib/features/integrations/provider_setup.dart`

`lib/features/integrations/provider_setup.dart:100`

```diff
-    Widget field(TextEditingController c, String label, IconData icon, {bool secret = false, Key? key}) => Revealable(
+    Widget field(TextEditingController c, String label, IconData icon, {bool secret = false, Key? key, bool last = false}) => Revealable(
```

`lib/features/integrations/provider_setup.dart:102-103`

```diff
-            key: key,
-            controller: c,
+            key: key,
+            controller: c,
+            // Next moves down the form; Done on the last field connects.
+            textInputAction: last ? TextInputAction.done : TextInputAction.next,
+            onSubmitted: last
+                ? (_) {
+                    if (_valid) _save();
+                  }
+                : null,
```

`lib/features/integrations/provider_setup.dart:111-124`

```diff
-              suffixIcon: Row(
-                mainAxisSize: MainAxisSize.min,
-                children: [
-                  if (secret) toggle,
-                  IconButton(
-                    tooltip: l10n.pasteLabel,
-                    icon: const Icon(LucideIcons.clipboardPaste, size: 18),
-                    onPressed: () async {
-                      final d = await Clipboard.getData(Clipboard.kTextPlain);
-                      if (d?.text != null) setState(() => c.text = d!.text!.trim());
-                    },
-                  ),
-                ],
-              ),
+              suffixIcon: FieldSuffix(
+                child: Row(
+                  mainAxisSize: MainAxisSize.min,
+                  children: [
+                    if (secret) toggle,
+                    IconButton(
+                      tooltip: l10n.pasteLabel,
+                      icon: const Icon(LucideIcons.clipboardPaste, size: 18),
+                      onPressed: () async {
+                        final d = await Clipboard.getData(Clipboard.kTextPlain);
+                        if (d?.text != null) setState(() => c.text = d!.text!.trim());
+                      },
+                    ),
+                  ],
+                ),
+              ),
```

`lib/features/integrations/provider_setup.dart:147`

```diff
-          field(_key, l10n.pipedreamClientSecret, LucideIcons.keyRound, secret: true, key: const Key('providerKey')),
+          field(_key, l10n.pipedreamClientSecret, LucideIcons.keyRound, secret: true, key: const Key('providerKey'), last: true),
```

`lib/features/integrations/provider_setup.dart:149`

```diff
-          field(_key, l10n.apiKey, LucideIcons.keyRound, secret: true, key: const Key('providerKey')),
+          field(_key, l10n.apiKey, LucideIcons.keyRound, secret: true, key: const Key('providerKey'), last: true),
```

#### 26. Add knowledge (URL, name) — `lib/features/bots/knowledge_screen.dart`

`lib/features/bots/knowledge_screen.dart:201-202`

```diff
-            key: const Key('knowledgeUrl'),
-            controller: _url,
+            key: const Key('knowledgeUrl'),
+            controller: _url,
+            textInputAction: TextInputAction.next,
```

`lib/features/bots/knowledge_screen.dart:206`

```diff
-        TextField(key: const Key('knowledgeName'), controller: _name, onChanged: (_) => setState(() {}), decoration: InputDecoration(labelText: l10n.botNameLabel)),
+        TextField(key: const Key('knowledgeName'), controller: _name, textInputAction: TextInputAction.done, onSubmitted: (_) => _valid && !_busy ? _submit() : null, onChanged: (_) => setState(() {}), decoration: InputDecoration(labelText: l10n.botNameLabel)),
```

#### 27. New action rule (domains, max amount) — `lib/features/bots/action_rules_screen.dart`

`lib/features/bots/action_rules_screen.dart:136-137`

```diff
-    return FormSheet(
-      icon: LucideIcons.shieldCheck,
+    VoidCallback? submit;
+    return FormSheet(
+      icon: LucideIcons.shieldCheck,
```

`lib/features/bots/action_rules_screen.dart:141-142`

```diff
-      submitKey: const Key('saveRule'),
-      onSubmit: !valid
+      submitKey: const Key('saveRule'),
+      // Also run by the keyboard's Done key on the last field.
+      onSubmit: submit = !valid
```

`lib/features/bots/action_rules_screen.dart:183-184`

```diff
-          key: const Key('ruleDomains'),
-          controller: _domains,
+          key: const Key('ruleDomains'),
+          controller: _domains,
+          textInputAction: TextInputAction.next,
```

`lib/features/bots/action_rules_screen.dart:190-191`

```diff
-          key: const Key('ruleAmount'),
-          controller: _amount,
+          key: const Key('ruleAmount'),
+          controller: _amount,
+          textInputAction: TextInputAction.done,
+          onSubmitted: (_) => submit?.call(),
```

#### 28. New password (password, again) — `lib/features/auth/account_screen.dart`

`lib/features/auth/account_screen.dart:93-94`

```diff
-                key: const Key('newPassword'),
-                controller: _password,
+                key: const Key('newPassword'),
+                controller: _password,
+                textInputAction: TextInputAction.next,
```

`lib/features/auth/account_screen.dart:118`

```diff
-                onFieldSubmitted: (_) => _submit(),
+                textInputAction: TextInputAction.done,
+                onFieldSubmitted: (_) => _submit(),
```

#### 29. Import for the shared widget — `lib/features/settings/secrets_screen.dart`

`FieldSuffix` (form 1) is used in this file, which doesn't import `revealable.dart` yet.
`model_keys_screen.dart` and `provider_setup.dart` already import it.

```diff
-import '../../ui/glow_button.dart';
+import '../../ui/glow_button.dart';
+import '../../ui/revealable.dart';
```

## The fix

The article's fix: set `textInputAction` on every one-line field, `.next` on all but the last, and
`.done` with a submit in `onSubmitted` on the last. The target code is the `+` side of each block
in "Where". There is one shared addition, in `lib/ui/revealable.dart` (form 1):

```dart
/// Keeps a field's trailing buttons (show, paste, scan) out of the keyboard's Next order on phones
/// and tablets, so Next moves to the next field instead of landing on a button. Tab on a desktop
/// keyboard still reaches them.
class FieldSuffix extends StatelessWidget {
  const FieldSuffix({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => ExcludeFocusTraversal(
    excluding: defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android,
    child: child,
  );
}
```

`Revealable` wraps its eye button in it, which covers every hidden field in the app at once. The
three hand-made suffix rows that come before another field get it too: the secret value's scan
and eye buttons, the API key's paste button, and the provider setup's paste button. Keys and taps
are unchanged: tests that tap `revealToggle` or `pasteApiKey` still work.

On iPhone, number and phone keyboards (`TextInputType.number`, `.phone`, decimal) have no action
key at all. Those fields still get the right action for Android and iPad. Don't change their
keyboard types.

## Steps

1. Apply form 1 (`lib/ui/revealable.dart`) first, then forms 2 to 29 in order. For each block,
   find the `-` lines in the file (exact text, indentation included). Replace them with the `+`
   lines, without the leading `-`/`+` marker. Edit by hand. Where one form has several blocks in
   the same file, apply them top to bottom. Earlier blocks shift line numbers, so always find the
   quoted text, not the line number.

2. After all forms, run `dart analyze lib`. It must show no new errors, warnings or infos compared
   with before your change. If it reports `Undefined name 'FieldSuffix'` in a file, add
   `import '../../ui/revealable.dart';` below that file's last `import '../../ui/...';` line.

3. Create the test file `test/text_input_action_test.dart` with exactly this content:

   ```dart
   import 'dart:typed_data';

   import 'package:flutter/material.dart';
   import 'package:flutter_test/flutter_test.dart';
   import 'package:casama_app/features/auth/account_screen.dart';
   import 'package:casama_app/features/workspaces/workspace_files.dart';

   import 'app_test.dart' show harness, setSize;
   import 'fake_backend.dart';

   /// The text field (by its key) that has keyboard focus right now, if any.
   Finder _focused(Key key) => find.descendant(
     of: find.byKey(key),
     matching: find.byWidgetPredicate((w) => w is EditableText && w.focusNode.hasFocus),
   );

   void main() {
     testWidgets('git sync: Next walks the fields, Done saves', (tester) async {
       await setSize(tester, const Size(900, 1400));
       final backend = FakeBackend();
       await tester.pumpWidget(harness(
         backend,
         Scaffold(
           body: SingleChildScrollView(
             child: WorkspaceFilesSection(orgId: orgId, pickZip: () async => Uint8List.fromList([1]), saveZip: (b) async {}),
           ),
         ),
       ));
       await tester.pumpAndSettle();
       await tester.tap(find.byKey(const Key('gitSync')));
       await tester.pumpAndSettle();
       expect(tester.widget<TextField>(find.byKey(const Key('gitRepo'))).textInputAction, TextInputAction.next);
       expect(tester.widget<TextField>(find.byKey(const Key('gitPath'))).textInputAction, TextInputAction.done);

       await tester.enterText(find.byKey(const Key('gitRepo')), 'acme/casama-config');
       await tester.testTextInput.receiveAction(TextInputAction.next);
       await tester.pump();
       expect(_focused(const Key('gitBranch')), findsOneWidget);

       await tester.testTextInput.receiveAction(TextInputAction.next);
       await tester.pump();
       expect(_focused(const Key('gitPath')), findsOneWidget);
       await tester.enterText(find.byKey(const Key('gitPath')), 'casama');
       await tester.testTextInput.receiveAction(TextInputAction.done);
       await tester.pumpAndSettle();
       expect(backend.fileActions.last, 'git:acme/casama-config:main:casama');
     });

     testWidgets('new password: Next skips the show button and lands on the second field', (tester) async {
       await setSize(tester, const Size(500, 1000));
       final backend = FakeBackend()..newPasswordNeeded = true;
       await tester.pumpWidget(harness(backend, const NewPasswordScreen()));
       await tester.enterText(find.byKey(const Key('newPassword')), 'brand-new-pw');
       await tester.testTextInput.receiveAction(TextInputAction.next);
       await tester.pump();
       expect(_focused(const Key('newPasswordAgain')), findsOneWidget);
     });
   }
   ```

   Then format only this new file: `dart format -l 200 test/text_input_action_test.dart`.

4. Run `flutter test test/text_input_action_test.dart`. Both tests must pass.

5. Run the tests for the forms you touched: `flutter test test/password_managers_test.dart test/action_rules_test.dart test/workspace_files_test.dart test/plugins_test.dart test/knowledge_test.dart test/links_test.dart test/channels_test.dart test/routine_editor_test.dart test/projects_test.dart test/account_test.dart test/spaces_test.dart test/secret_store_test.dart test/phone_calls_test.dart test/payments_test.dart test/admin_test.dart test/about_you_test.dart test/teach_test.dart test/local_mcp_test.dart test/board_test.dart`.
   Then the whole suite: `flutter test`. Nothing that passed before may fail.

## Check it

- `dart analyze lib test/text_input_action_test.dart` shows no new issues.
- `grep -c "class FieldSuffix extends StatelessWidget" lib/ui/revealable.dart` → `1`
- `grep -c "final toggle = FieldSuffix(" lib/ui/revealable.dart` → `1`
- `grep -c "textInputAction:" lib/features/settings/secrets_screen.dart` → `3`
- `grep -c "textInputAction:" lib/features/settings/password_managers_screen.dart` → `3`
- `grep -c "textInputAction:" lib/features/workspaces/workspace_files.dart` → `3`
- `grep -c "textInputAction:" lib/features/workspaces/spaces.dart` → `9`
- `grep -c "textInputAction:" lib/features/routines/routines_screen.dart` → `7`
- `grep -c "textInputAction:" lib/features/integrations/integrations_screen.dart` → `5`
- `grep -c "textInputAction:" lib/features/settings/model_keys_screen.dart` → `3`
- `grep -c "textInputAction:" lib/features/admin/admin_screen.dart` → `3`
- `grep -c "textInputAction: TextInputAction.done," lib/features/auth/sign_in_screen.dart` → `1`
- `grep -c "onEditingComplete" lib/features/settings/secrets_screen.dart` → `0`
- `flutter test test/text_input_action_test.dart` passes.

## Don't touch

- Multi-line fields (persona, instructions, goal, details, senders, env, notes, the composer, the
  comment box, memory and fact editors): leave their return key alone.
- Forms with a single one-line field (new workspace, rename, SSO email, theme name, onboarding's
  separate steps, agent-import name, the teach secret name, search boxes): out of scope.
- The bot name in the create-bot sheet (`lib/features/bots/bots_screen.dart:471`) and on the bot
  profile (`lib/features/bots/bot_profile_screen.dart:277`). The next control is the icon picker,
  not a field, so "Next" would land on an icon. The default Done is right. Same for the local MCP
  server's name (a segmented control follows) and command (a folder button follows) in
  `lib/features/companion/companion_screen.dart`.
- The sign-in email field already has the right action (`next`, or `send` for the email link).
- Keyboard types, validators, labels, keys. Don't add `FocusNode`s or `onEditingComplete`.
- No new dependencies. No refactors, renames, or cleanups beyond the fix. Existing widget `Key`s:
  keep them all.
- Don't run `dart format` on existing files or folders (only on the test file this plan creates).
  No git commands (shared tree; others commit).

## STOP if

- Form 1 (`lib/ui/revealable.dart`) doesn't match the quoted code.
- In forms 2-29, a block's `-` text isn't in the file exactly. Don't guess. Skip that whole form,
  finish the others, and list the skipped forms in your report. If more than 3 forms have to be
  skipped, stop and report instead.
- The fix seems to require touching something in "Don't touch".
- A test that passed before your change fails after it, or a check fails twice.

## When you're done

Tell the developer, in two or three sentences, what's different in the app now and one place to
open to see it. For example: "Forms can now be filled with the keyboard alone. Next moves field to
field, skipping the show and paste buttons on phones, and the last field's key saves the form like
its main button. On a phone, open Settings → Secrets → Add, type a name, tap Next twice, and Done
saves."
