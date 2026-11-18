import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:casama_sdk/casama_sdk.dart';

import 'commands_bots.dart' show addOrgOption, openInBrowser, orgFrom;
import 'runner.dart';

// Workspace admin (members, invites, join requests, settings, keys, Git sync, encryption status)
// as subcommands of `casama org`, and `casama billing`. Encryption rotate/replace-key stay
// API-only on purpose (D-238).

/// Used by deletes and revokes: without `--yes`, say what would happen and stop (exit 0).
/// Returns null when the caller should go ahead.
int? confirmGate(CliContext ctx, bool yes, String would, String flag) {
  if (yes) return null;
  return ctx.emit({
    'would': would,
    'confirm': '--yes',
  }, 'Would $would.\nRun again with --yes to $flag.');
}

String _date(DateTime? d) =>
    d == null ? '-' : d.toIso8601String().substring(0, 10);

/// Emails from a file: one per line or separated by commas or spaces. `#` starts a comment.
List<String> parseEmails(String text) {
  final out = <String>[];
  for (final line in text.split('\n')) {
    final clean = line.split('#').first;
    for (final part in clean.split(RegExp(r'[\s,;]+'))) {
      final e = part.trim();
      if (e.isNotEmpty && !out.contains(e)) out.add(e);
    }
  }
  return out;
}

/// `key=value` words for `org settings`, checked against the real fields.
Map<String, Object?> parseSettingsArgs(List<String> words) {
  const bools = {
    'require_mfa',
    'require_app_lock',
    'mcp_decide_approvals',
    'full_access',
    'allow_bot_to_bot',
    'a2a_enabled',
    'llm_tracing',
    'analytics_opt_out',
    'chrome_extension',
    'chrome_act',
  };
  const keys = {...bools, 'run_event_retention_days', 'chrome_blocked_sites'};
  final out = <String, Object?>{};
  for (final w in words) {
    final i = w.indexOf('=');
    if (i < 1) {
      throw UsageException(
        'Use key=value, for example require_mfa=true. Got "$w".',
        '',
      );
    }
    final k = w.substring(0, i).replaceAll('-', '_');
    final v = w.substring(i + 1).trim();
    if (!keys.contains(k)) {
      throw UsageException(
        'Unknown setting "$k". Settings: ${keys.toList()..sort()}',
        '',
      );
    }
    if (bools.contains(k)) {
      if (v != 'true' && v != 'false') {
        throw UsageException('$k is true or false.', '');
      }
      out[k] = v == 'true';
    } else if (k == 'run_event_retention_days') {
      final n = int.tryParse(v);
      if (n == null || n < 0) {
        throw UsageException('$k is a number of days.', '');
      }
      out[k] = n;
    } else {
      out[k] = v.isEmpty
          ? <String>[]
          : v
                .split(',')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList();
    }
  }
  return out;
}

String _settingsText(OrgSettings s) {
  final j = s.toJson();
  final keys = j.keys.toList();
  final w = keys.fold<int>(0, (m, k) => k.length > m ? k.length : m);
  return keys
      .map((k) {
        final v = j[k];
        return '${k.padRight(w)}  ${v is List ? v.join(',') : v}';
      })
      .join('\n');
}

abstract class _OrgAdminCommand extends KCommand {
  _OrgAdminCommand(super.ctx, {bool org = true}) {
    if (org) addOrgOption(this);
  }
  Future<(CasamaClient, OrganizationWithRole)> open() async {
    final c = await ctx.authedClient();
    final org = await orgFrom(ctx, c, argResults!['org'] as String?);
    return (c, org);
  }

  String one(String what) {
    final rest = argResults!.rest;
    if (rest.length != 1) throw UsageException(what, usage);
    return rest.single;
  }

  bool get yes => argResults!['yes'] as bool;
  void addYes() => argParser.addFlag(
    'yes',
    abbr: 'y',
    negatable: false,
    help: 'Do it. Without this, only say what would happen.',
  );
}

// ---- members

class OrgMembersCommand extends _OrgAdminCommand {
  OrgMembersCommand(super.ctx);
  @override
  String get name => 'members';
  @override
  String get description => 'The people in a workspace and their roles.';
  @override
  Future<int> run() async {
    final (c, org) = await open();
    final items = (await c.workspaces.listMembers(id: org.id)).data!.items;
    return ctx.emit(
      [for (final m in items) m.toJson()],
      items.isEmpty
          ? 'No members.'
          : items
                .map(
                  (m) =>
                      '${m.userId}\t${m.role.value}\t${m.name ?? ''}\t${m.email ?? ''}',
                )
                .join('\n'),
    );
  }
}

// ---- invites

class OrgInvitesCommand extends _OrgAdminCommand {
  OrgInvitesCommand(super.ctx);
  @override
  String get name => 'invites';
  @override
  String get description => 'Pending email invites.';
  @override
  Future<int> run() async {
    final (c, org) = await open();
    final items = (await c.workspaces.listInvites(id: org.id)).data!.items;
    return ctx.emit(
      [for (final i in items) i.toJson()],
      items.isEmpty
          ? 'No pending invites. Send one with `casama org invite <email>`.'
          : items
                .map(
                  (i) =>
                      '${i.id}\t${i.role.value}\t${i.email}\texpires ${_date(i.expiresAt)}',
                )
                .join('\n'),
    );
  }
}

class OrgInviteResendCommand extends _OrgAdminCommand {
  OrgInviteResendCommand(super.ctx);
  @override
  String get name => 'invite-resend';
  @override
  String get description => 'Send a pending invite email again.';
  @override
  String get invocation =>
      'casama org invite-resend <invite id> [--org <slug>]';
  @override
  Future<int> run() async {
    final id = one('Which invite? Pass its id (see `casama org invites`).');
    final (c, org) = await open();
    final i = (await c.workspaces.resendInvite(id: org.id, inviteId: id)).data!;
    return ctx.emit(
      i.toJson(),
      i.emailSent
          ? 'Sent again to ${i.email}.'
          : 'Invite for ${i.email} renewed; the email did not send.',
    );
  }
}

class OrgInviteRevokeCommand extends _OrgAdminCommand {
  OrgInviteRevokeCommand(super.ctx) {
    addYes();
  }
  @override
  String get name => 'invite-revoke';
  @override
  String get description => 'Cancel a pending invite.';
  @override
  String get invocation => 'casama org invite-revoke <invite id> [--yes]';
  @override
  Future<int> run() async {
    final id = one('Which invite? Pass its id (see `casama org invites`).');
    final gate = confirmGate(ctx, yes, 'cancel invite $id', 'cancel it');
    if (gate != null) return gate;
    final (c, org) = await open();
    await c.workspaces.revokeInvite(id: org.id, inviteId: id);
    return ctx.emit({'id': id, 'revoked': true}, 'Invite cancelled.');
  }
}

class OrgInviteBatchCommand extends _OrgAdminCommand {
  OrgInviteBatchCommand(super.ctx) {
    argParser.addOption(
      'role',
      allowed: ['member', 'admin'],
      defaultsTo: 'member',
    );
  }
  @override
  String get name => 'invite-batch';
  @override
  String get description =>
      'Invite many people at once from a file of email addresses.';
  @override
  String get invocation =>
      'casama org invite-batch <file> [--role member|admin]';
  @override
  Future<int> run() async {
    final path = one('Which file? One email per line, or separated by commas.');
    final f = File(path);
    if (!f.existsSync()) throw CliError('file_not_found', 'No file at $path.');
    final emails = parseEmails(f.readAsStringSync());
    if (emails.isEmpty) {
      throw CliError('no_emails', 'No email addresses found in $path.');
    }
    final (c, org) = await open();
    final items = (await c.workspaces.createInvites(
      id: org.id,
      createInvitesRequest: CreateInvitesRequest(
        emails: emails,
        role: CreateInvitesRequestRoleEnum.values.firstWhere(
          (r) => r.value == argResults!['role'],
        ),
      ),
    )).data!.items;
    return ctx.emit(
      [for (final i in items) i.toJson()],
      'Invited ${items.length} of ${emails.length}:\n${items.map((i) => '${i.id}\t${i.email}\t${i.emailSent ? 'sent' : 'not sent'}').join('\n')}',
    );
  }
}

String _linkLine(InviteLink l) =>
    '${l.id}\t${l.role.value}\t…${l.tokenHint}\t${l.uses}${l.maxUses == null ? '' : '/${l.maxUses}'} uses\texpires ${_date(l.expiresAt)}${l.revokedAt != null ? '\trevoked' : ''}${l.requiresApproval == true ? '\tneeds approval' : ''}';

class OrgInviteLinksCommand extends _OrgAdminCommand {
  OrgInviteLinksCommand(super.ctx);
  @override
  String get name => 'invite-links';
  @override
  String get description => 'Invite links people can join with.';
  @override
  Future<int> run() async {
    final (c, org) = await open();
    final items = (await c.workspaces.listInviteLinks(id: org.id)).data!.items;
    return ctx.emit(
      [for (final l in items) l.toJson()],
      items.isEmpty
          ? 'No invite links. Make one with `casama org invite-link-create`.'
          : items.map(_linkLine).join('\n'),
    );
  }
}

class OrgInviteLinkCreateCommand extends _OrgAdminCommand {
  OrgInviteLinkCreateCommand(super.ctx) {
    argParser
      ..addOption('role', allowed: ['member', 'admin'], defaultsTo: 'member')
      ..addOption('expires-in-days', help: 'Days until the link stops working.')
      ..addOption('max-uses', help: 'How many people can use it.')
      ..addFlag(
        'requires-approval',
        defaultsTo: null,
        help: 'An admin approves each person who joins.',
      );
  }
  @override
  String get name => 'invite-link-create';
  @override
  String get description => 'Make an invite link.';
  @override
  Future<int> run() async {
    int? num(String key) {
      final v = argResults![key] as String?;
      if (v == null) return null;
      final n = int.tryParse(v);
      if (n == null || n < 1) {
        throw UsageException('--$key is a whole number, 1 or more.', usage);
      }
      return n;
    }

    final days = num('expires-in-days');
    final uses = num('max-uses');
    final (c, org) = await open();
    final l = (await c.workspaces.createInviteLink(
      id: org.id,
      createInviteLinkRequest: CreateInviteLinkRequest(
        role: CreateInviteLinkRequestRoleEnum.values.firstWhere(
          (r) => r.value == argResults!['role'],
        ),
        expiresInDays: days,
        maxUses: uses,
        requiresApproval: argResults!['requires-approval'] as bool?,
      ),
    )).data!;
    return ctx.emit(
      l.toJson(),
      '${l.url}\nShare this link. It is the only time the full link is shown.\nid: ${l.id}',
    );
  }
}

class OrgInviteLinkDeleteCommand extends _OrgAdminCommand {
  OrgInviteLinkDeleteCommand(super.ctx) {
    addYes();
  }
  @override
  String get name => 'invite-link-delete';
  @override
  String get description => 'Turn an invite link off.';
  @override
  String get invocation => 'casama org invite-link-delete <link id> [--yes]';
  @override
  Future<int> run() async {
    final id = one('Which link? Pass its id (see `casama org invite-links`).');
    final gate = confirmGate(
      ctx,
      yes,
      'turn off invite link $id',
      'turn it off',
    );
    if (gate != null) return gate;
    final (c, org) = await open();
    await c.workspaces.revokeInviteLink(id: org.id, linkId: id);
    return ctx.emit({'id': id, 'revoked': true}, 'Invite link turned off.');
  }
}

// ---- join requests

class OrgRequestsCommand extends _OrgAdminCommand {
  OrgRequestsCommand(super.ctx);
  @override
  String get name => 'requests';
  @override
  String get description =>
      'People waiting to join (from invite links that need approval).';
  @override
  Future<int> run() async {
    final (c, org) = await open();
    final items = (await c.workspaces.listJoinRequests(id: org.id)).data!.items;
    return ctx.emit(
      [for (final r in items) r.toJson()],
      items.isEmpty
          ? 'No join requests.'
          : items
                .map(
                  (r) =>
                      '${r.id}\t${r.status.value}\t${r.displayName ?? ''}\t${r.email ?? r.userId}',
                )
                .join('\n'),
    );
  }
}

class OrgRequestCommand extends _OrgAdminCommand {
  OrgRequestCommand(super.ctx);
  @override
  String get name => 'request';
  @override
  String get description => 'Approve or deny a join request.';
  @override
  String get invocation => 'casama org request <request id> approve|deny';
  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.length != 2 || !const ['approve', 'deny'].contains(rest[1])) {
      throw UsageException('Pass the request id and approve or deny.', usage);
    }
    final (c, org) = await open();
    final r = (await c.workspaces.decideJoinRequest(
      id: org.id,
      requestId: rest[0],
      decideJoinRequest: DecideJoinRequest(approve: rest[1] == 'approve'),
    )).data!;
    return ctx.emit(r.toJson(), 'Request ${r.status.value}.');
  }
}

// ---- settings

class OrgRenameCommand extends _OrgAdminCommand {
  OrgRenameCommand(super.ctx);
  @override
  String get name => 'rename';
  @override
  String get description => 'Change the workspace name.';
  @override
  String get invocation => 'casama org rename <new name> [--org <slug>]';
  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    final newName = rest.join(' ').trim();
    if (newName.isEmpty) {
      throw UsageException('What should it be called?', usage);
    }
    final (c, org) = await open();
    final o = (await c.workspaces.updateOrg(
      id: org.id,
      updateOrganizationRequest: UpdateOrganizationRequest(name: newName),
    )).data!;
    return ctx.emit(o.toJson(), 'Renamed to ${o.name}.');
  }
}

class OrgSettingsCommand extends _OrgAdminCommand {
  OrgSettingsCommand(super.ctx);
  @override
  String get name => 'settings';
  @override
  String get description =>
      'Show workspace settings, or change some with key=value.';
  @override
  String get invocation => 'casama org settings [key=value ...] [--org <slug>]';
  @override
  Future<int> run() async {
    final changes = parseSettingsArgs(argResults!.rest);
    final (c, org) = await open();
    final OrgSettings s;
    if (changes.isEmpty) {
      s = (await c.privacy.getOrgSettings(id: org.id)).data!;
    } else {
      s = (await c.privacy.updateOrgSettings(
        id: org.id,
        updateOrgSettingsRequest: UpdateOrgSettingsRequest.fromJson(changes),
      )).data!;
    }
    return ctx.emit(s.toJson(), _settingsText(s));
  }
}

// ---- MCP keys

class OrgMcpKeysCommand extends _OrgAdminCommand {
  OrgMcpKeysCommand(super.ctx);
  @override
  String get name => 'mcp-keys';
  @override
  String get description =>
      'Keys other tools use to reach this workspace over MCP.';
  @override
  Future<int> run() async {
    final (c, org) = await open();
    final items = (await c.mcp.listMcpKeys(id: org.id)).data!.items;
    return ctx.emit(
      [for (final k in items) k.toJson()],
      items.isEmpty
          ? 'No MCP keys. Make one with `casama org mcp-key-create <name>`.'
          : items
                .map(
                  (k) =>
                      '${k.id}\t${k.name}\t…${k.hint}\tlast used ${_date(k.lastUsedAt)}',
                )
                .join('\n'),
    );
  }
}

class OrgMcpKeyCreateCommand extends _OrgAdminCommand {
  OrgMcpKeyCreateCommand(super.ctx);
  @override
  String get name => 'mcp-key-create';
  @override
  String get description => 'Make an MCP key. The key is shown once.';
  @override
  String get invocation => 'casama org mcp-key-create <name> [--org <slug>]';
  @override
  Future<int> run() async {
    final n = argResults!.rest.join(' ').trim();
    if (n.isEmpty) {
      throw UsageException('What is the key for? Give it a name.', usage);
    }
    final (c, org) = await open();
    final k = (await c.mcp.createMcpKey(
      id: org.id,
      createMcpKeyRequest: CreateMcpKeyRequest(name: n),
    )).data!;
    return ctx.emit(
      k.toJson(),
      'Key: ${k.key}\nMCP URL: ${k.mcpUrl}\nid: ${k.id}\nCopy the key now. It will not be shown again.',
    );
  }
}

class OrgMcpKeyDeleteCommand extends _OrgAdminCommand {
  OrgMcpKeyDeleteCommand(super.ctx) {
    addYes();
  }
  @override
  String get name => 'mcp-key-delete';
  @override
  String get description => 'Revoke an MCP key. Tools using it stop working.';
  @override
  String get invocation => 'casama org mcp-key-delete <key id> [--yes]';
  @override
  Future<int> run() async {
    final id = one('Which key? Pass its id (see `casama org mcp-keys`).');
    final gate = confirmGate(ctx, yes, 'revoke MCP key $id', 'revoke it');
    if (gate != null) return gate;
    final (c, org) = await open();
    await c.mcp.revokeMcpKey(id: org.id, keyId: id);
    return ctx.emit({'id': id, 'revoked': true}, 'Key revoked.');
  }
}

// ---- Git sync

String _gitText(GitSyncStatus g) {
  if (!g.configured) {
    return 'Git sync is not set up. Set it with `casama org git-sync-set <repo>`.';
  }
  return [
    '${g.enabled ? 'on ' : 'off'}  ${g.repo}  ${g.branch ?? ''}${g.path == null ? '' : '  path ${g.path}'}',
    'token: ${g.hasToken ? 'saved' : 'none'}',
    if (g.webhookUrl != null) 'webhook: ${g.webhookUrl}',
    'last sync: ${g.lastSyncedAt?.toIso8601String() ?? 'never'}${g.lastCommit == null ? '' : '  (${g.lastCommit})'}',
    if (g.lastError != null) 'last error: ${g.lastError}',
    if (g.openPrUrl != null) 'open pull request: ${g.openPrUrl}',
  ].join('\n');
}

class OrgGitSyncCommand extends _OrgAdminCommand {
  OrgGitSyncCommand(super.ctx);
  @override
  String get name => 'git-sync';
  @override
  String get description => 'Show the workspace files\' Git sync.';
  @override
  Future<int> run() async {
    final (c, org) = await open();
    final g = (await c.files.getGitSync(id: org.id)).data!;
    return ctx.emit(g.toJson(), _gitText(g));
  }
}

class OrgGitSyncSetCommand extends _OrgAdminCommand {
  OrgGitSyncSetCommand(super.ctx) {
    argParser
      ..addOption('branch', help: 'Branch to sync with.')
      ..addOption('path', help: 'Folder in the repo to sync.')
      ..addFlag('enabled', defaultsTo: null, help: 'Turn syncing on or off.');
  }
  @override
  String get name => 'git-sync-set';
  @override
  String get description =>
      'Set or change the Git repo the workspace files sync with.';
  @override
  String get invocation =>
      'casama org git-sync-set <repo> [--branch b] [--path p] [--enabled]';
  @override
  Future<int> run() async {
    final repo = one(
      'Which repo? For example: casama org git-sync-set owner/name',
    );
    final (c, org) = await open();
    final g = (await c.files.setGitSync(
      id: org.id,
      setGitSyncRequest: SetGitSyncRequest(
        repo: repo,
        branch: argResults!['branch'] as String?,
        path: argResults!['path'] as String?,
        enabled: argResults!['enabled'] as bool?,
      ),
    )).data!;
    return ctx.emit(g.toJson(), _gitText(g));
  }
}

class OrgGitSyncRunCommand extends _OrgAdminCommand {
  OrgGitSyncRunCommand(super.ctx);
  @override
  String get name => 'git-sync-run';
  @override
  String get description => 'Sync with Git now.';
  @override
  Future<int> run() async {
    final (c, org) = await open();
    final g = (await c.files.runGitSync(id: org.id)).data!;
    return ctx.emit(g.toJson(), _gitText(g));
  }
}

class OrgGitSyncOffCommand extends _OrgAdminCommand {
  OrgGitSyncOffCommand(super.ctx) {
    addYes();
  }
  @override
  String get name => 'git-sync-off';
  @override
  String get description => 'Remove the Git sync setup.';
  @override
  String get invocation => 'casama org git-sync-off [--yes]';
  @override
  Future<int> run() async {
    final gate = confirmGate(
      ctx,
      yes,
      'remove the Git sync setup',
      'remove it',
    );
    if (gate != null) return gate;
    final (c, org) = await open();
    final g = (await c.files.deleteGitSync(id: org.id)).data!;
    return ctx.emit(g.toJson(), 'Git sync removed.');
  }
}

// ---- encryption

class OrgEncryptionCommand extends _OrgAdminCommand {
  OrgEncryptionCommand(super.ctx);
  @override
  String get name => 'encryption';
  @override
  String get description =>
      'Show the workspace\'s encryption status. Key changes are API-only.';
  @override
  Future<int> run() async {
    final (c, org) = await open();
    final e = (await c.encryption.getEncryption(id: org.id)).data!;
    return ctx.emit(
      e.toJson(),
      'mode: ${e.mode.value}${e.key == null ? '' : '\nkey: ${e.key!.value}'}\navailable: ${e.available}'
      '${e.since == null ? '' : '\nsince: ${_date(e.since)}'}${e.rotatedAt == null ? '' : '\nkey rotated: ${_date(e.rotatedAt)}'}'
      '${e.rekeying == true ? '\nre-encrypting now' : ''}',
    );
  }
}

// ---- billing

class BillingCommand extends Command<int> {
  BillingCommand(CliContext ctx) {
    addSubcommand(BillingShowCommand(ctx));
    addSubcommand(BillingUsageCommand(ctx));
    addSubcommand(BillingUpgradeCommand(ctx));
    addSubcommand(BillingPortalCommand(ctx));
  }
  @override
  String get name => 'billing';
  @override
  String get description => 'The workspace\'s plan, usage and payment pages.';
}

class BillingShowCommand extends _OrgAdminCommand {
  BillingShowCommand(super.ctx);
  @override
  String get name => 'show';
  @override
  String get description => 'Plan, period, seats and credits.';
  @override
  Future<int> run() async {
    final (c, org) = await open();
    final b = (await c.billing.getBilling(id: org.id)).data!;
    return ctx.emit(
      b.toJson(),
      [
        if (!b.enabled) 'Billing is off on this server.',
        'plan: ${b.planName} (${b.planCode}), ${b.interval}',
        if (b.validUntil != null)
          'renews or ends: ${_date(b.validUntil)}${b.cancelAtPeriodEnd ? ' (cancels at period end)' : ''}',
        'extra seats: ${b.extraSeats ?? 0}',
        'credits: \$${b.creditsUsd}',
        if (b.daily != null)
          'today: \$${b.daily!.usedUsd} of \$${b.daily!.capUsd}',
        if (b.trialAvailable == true) 'A free trial is available.',
      ].join('\n'),
    );
  }
}

class BillingUsageCommand extends _OrgAdminCommand {
  BillingUsageCommand(super.ctx);
  @override
  String get name => 'usage';
  @override
  String get description =>
      'This month\'s billable usage and recent credit entries.';
  @override
  Future<int> run() async {
    final (c, org) = await open();
    final u = (await c.billing.billingUsage(id: org.id)).data!;
    final lines = [
      'since ${_date(u.periodStart)}: \$${u.totalUsd}',
      for (final i in u.items)
        '  ${i.kind}${i.instance == null ? '' : ' ${i.instance}'}\t${i.quantity}\t\$${i.costUsd}',
      if (u.credits.isNotEmpty) 'credits:',
      for (final e in u.credits)
        '  ${_date(e.createdAt)}\t${e.delta}\t${e.reason}\tbalance ${e.balanceAfter}',
    ];
    return ctx.emit(u.toJson(), lines.join('\n'));
  }
}

/// The plan code the API expects: `plus`, `pro`, `max`, with `_yearly` for the yearly price.
String planCodeFor(String plan, String period) =>
    period == 'yearly' ? '${plan}_yearly' : plan;

Future<int> _showUrl(
  CliContext ctx,
  String url,
  bool browser,
  String lead,
) async {
  var opened = false;
  if (browser && !ctx.json) opened = await openInBrowser(Uri.parse(url));
  return ctx.emit(
    {'url': url},
    '$lead\n$url${opened
        ? ''
        : browser
        ? '\nOpen the link in a browser.'
        : ''}',
  );
}

class BillingUpgradeCommand extends _OrgAdminCommand {
  BillingUpgradeCommand(super.ctx) {
    addYes();
    argParser
      ..addOption(
        'plan',
        allowed: ['plus', 'pro', 'max'],
        help: 'The plan to switch to.',
      )
      ..addOption(
        'period',
        allowed: ['monthly', 'yearly'],
        defaultsTo: 'monthly',
      )
      ..addFlag(
        'browser',
        defaultsTo: true,
        help: 'Open the checkout page (otherwise only print the link).',
      );
  }
  @override
  String get name => 'upgrade';
  @override
  String get description =>
      'Start checkout for a plan. A plan change can bill you.';
  @override
  String get invocation =>
      'casama billing upgrade --plan plus|pro|max [--period monthly|yearly] [--yes]';
  @override
  Future<int> run() async {
    final plan = argResults!['plan'] as String?;
    if (plan == null) {
      throw UsageException('Which plan? Pass --plan plus, pro or max.', usage);
    }
    final code = planCodeFor(plan, argResults!['period'] as String);
    final gate = confirmGate(ctx, yes, 'start checkout for $code', 'start it');
    if (gate != null) return gate;
    final (c, org) = await open();
    final r = (await c.billing.createCheckout(
      id: org.id,
      checkoutRequest: CheckoutRequest(planCode: code),
    )).data!;
    if (r.changed == true) {
      return ctx.emit(r.toJson(), 'Your plan changed to $code.');
    }
    return _showUrl(
      ctx,
      r.url,
      argResults!['browser'] as bool,
      'Finish the payment here:',
    );
  }
}

class BillingPortalCommand extends _OrgAdminCommand {
  BillingPortalCommand(super.ctx) {
    argParser.addFlag(
      'browser',
      defaultsTo: true,
      help: 'Open the page (otherwise only print the link).',
    );
  }
  @override
  String get name => 'portal';
  @override
  String get description =>
      'Open the page to manage payment methods and invoices.';
  @override
  Future<int> run() async {
    final (c, org) = await open();
    final r = (await c.billing.billingPortal(
      id: org.id,
      portalRequest: PortalRequest(),
    )).data!;
    return _showUrl(
      ctx,
      r.url,
      argResults!['browser'] as bool,
      'Manage billing here:',
    );
  }
}
