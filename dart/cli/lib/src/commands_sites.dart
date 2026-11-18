import 'package:args/command_runner.dart';
import 'package:casama_sdk/casama_sdk.dart';

import 'commands_bots.dart' show addOrgOption, orgFrom;
import 'runner.dart';

/// Sites (D-329): `casama sites list|publish|unpublish`.
class SitesCommand extends Command<int> {
  SitesCommand(CliContext ctx) {
    addSubcommand(SitesListCommand(ctx));
    addSubcommand(SitesPublishCommand(ctx));
    addSubcommand(SitesUnpublishCommand(ctx));
  }
  @override
  String get name => 'sites';
  @override
  String get description => 'Pages published on the web at their own address.';
}

String _siteLine(Site s) =>
    '${s.live ? 'live' : 'off '}  ${s.addressUrl ?? s.url ?? '-'}  ${s.title}  (${s.pageId})';

class SitesListCommand extends KCommand {
  SitesListCommand(super.ctx) {
    addOrgOption(this);
  }
  @override
  String get name => 'list';
  @override
  String get description => 'The workspace\'s published sites.';
  @override
  Future<int> run() async {
    final c = await ctx.authedClient();
    final org = await orgFrom(ctx, c, argResults!['org'] as String?);
    final items = (await c.sites.listSites(id: org.id)).data!.items;
    return ctx.emit([
      for (final s in items) s.toJson(),
    ], items.isEmpty ? 'No sites yet.' : items.map(_siteLine).join('\n'));
  }
}

class SitesPublishCommand extends KCommand {
  SitesPublishCommand(super.ctx) {
    argParser
      ..addOption(
        'name',
        help: 'The address name: <name>.<sites zone>. Default: from the title.',
      )
      ..addFlag(
        'indexable',
        help: 'Let search engines find it (paid plans).',
        defaultsTo: null,
      );
  }
  @override
  String get name => 'publish';
  @override
  String get description =>
      'Put a page on the web at its own address. The page becomes public.';
  @override
  String get invocation => 'casama sites publish <page id> [--name crumb]';
  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.length != 1) {
      throw UsageException('Which page? Pass its id.', usage);
    }
    final c = await ctx.authedClient();
    final s = (await c.sites.publishSite(
      id: rest.single,
      publishSiteRequest: PublishSiteRequest(
        label: argResults!['name'] as String?,
        indexable: argResults!['indexable'] as bool?,
      ),
    )).data!;
    return ctx.emit(s.toJson(), 'Published: ${s.addressUrl ?? s.url}');
  }
}

class SitesUnpublishCommand extends KCommand {
  SitesUnpublishCommand(super.ctx);
  @override
  String get name => 'unpublish';
  @override
  String get description =>
      'Take a site off the web. The page goes private again.';
  @override
  String get invocation => 'casama sites unpublish <page id>';
  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.length != 1) {
      throw UsageException('Which page? Pass its id.', usage);
    }
    final c = await ctx.authedClient();
    await c.sites.unpublishSite(id: rest.single);
    return ctx.emit({
      'page_id': rest.single,
      'published': false,
    }, 'Unpublished.');
  }
}

/// Domains (D-329): `casama domains list|show|connect|check|disconnect`. Buying, renewing and
/// moving a domain away stay in the app, with a person.
class DomainsCommand extends Command<int> {
  DomainsCommand(CliContext ctx) {
    addSubcommand(DomainsListCommand(ctx));
    addSubcommand(DomainsShowCommand(ctx));
    addSubcommand(DomainsConnectCommand(ctx));
    addSubcommand(DomainsCheckCommand(ctx));
    addSubcommand(DomainsDisconnectCommand(ctx));
  }
  @override
  String get name => 'domains';
  @override
  String get description => 'Connected and bought domains.';
}

/// A domain by id or name in the workspace.
Future<Domain> _domain(
  CliContext ctx,
  CasamaClient c,
  String? orgFlag,
  String ref,
) async {
  final org = await orgFrom(ctx, c, orgFlag);
  final items = (await c.domains.listDomains(id: org.id)).data!.items;
  final d = items
      .where((x) => x.id == ref || x.name == ref.toLowerCase())
      .firstOrNull;
  if (d == null) {
    throw CliError('domain_not_found', 'No domain "$ref" in ${org.name}.');
  }
  return d;
}

String _domainText(Domain d) {
  final lines = <String>[
    '${d.name}  ${d.state}${d.pageTitle == null ? '' : '  → ${d.pageTitle}'}',
    for (final h in d.hosts)
      '  ${h.live ? 'live' : h.status.padRight(4)}  ${h.hostname}${h.statusReason == null ? '' : '  (${h.statusReason})'}',
    if (d.expiresAt != null)
      '  renews ${d.expiresAt!.toIso8601String().substring(0, 10)}${d.autoRenew ? ' automatically' : ' (not automatically)'}',
  ];
  final todo = d.records.where((r) => r.ok != true).toList();
  if (todo.isNotEmpty) {
    lines.add('Add these records at your DNS company:');
    for (final r in todo) {
      lines.add(
        '  ${r.type.padRight(5)} ${r.name}  →  ${r.value}${r.seen == null || r.seen!.isEmpty ? '' : '   (now: ${r.seen!.join(', ')})'}',
      );
    }
  }
  return lines.join('\n');
}

class DomainsListCommand extends KCommand {
  DomainsListCommand(super.ctx) {
    addOrgOption(this);
  }
  @override
  String get name => 'list';
  @override
  String get description => 'The workspace\'s domains and their states.';
  @override
  Future<int> run() async {
    final c = await ctx.authedClient();
    final org = await orgFrom(ctx, c, argResults!['org'] as String?);
    final items = (await c.domains.listDomains(id: org.id)).data!.items;
    return ctx.emit(
      [for (final d in items) d.toJson()],
      items.isEmpty
          ? 'No domains yet. Connect one with `casama domains connect <name>`.'
          : items
                .map(
                  (d) =>
                      '${d.state.padRight(16)} ${d.name}${d.kind == 'registered' ? '  (bought)' : ''}',
                )
                .join('\n'),
    );
  }
}

class DomainsShowCommand extends KCommand {
  DomainsShowCommand(super.ctx) {
    addOrgOption(this);
  }
  @override
  String get name => 'show';
  @override
  String get description => 'A domain\'s hosts, states and the records to add.';
  @override
  String get invocation => 'casama domains show <domain>';
  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.length != 1) throw UsageException('Which domain?', usage);
    final c = await ctx.authedClient();
    final d = await _domain(ctx, c, argResults!['org'] as String?, rest.single);
    final full = (await c.domains.getDomain(id: d.id)).data!;
    return ctx.emit(full.toJson(), _domainText(full));
  }
}

class DomainsConnectCommand extends KCommand {
  DomainsConnectCommand(super.ctx) {
    addOrgOption(this);
    argParser.addOption(
      'page',
      help: 'A published site\'s page id to show on it.',
    );
  }
  @override
  String get name => 'connect';
  @override
  String get description =>
      'Connect a domain you own (bakery.com, www.bakery.com or shop.bakery.com).';
  @override
  String get invocation => 'casama domains connect <name> [--page <page id>]';
  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.length != 1) {
      throw UsageException(
        'Which domain? For example: casama domains connect bakery.com',
        usage,
      );
    }
    final c = await ctx.authedClient();
    final org = await orgFrom(ctx, c, argResults!['org'] as String?);
    final r = (await c.domains.connectDomain(
      id: org.id,
      connectDomainRequest: ConnectDomainRequest(
        name: rest.single,
        pageId: argResults!['page'] as String?,
      ),
    )).data!;
    final claim = r.claim;
    if (claim != null) {
      return ctx.emit(
        r.toJson(),
        '${rest.single} is connected to another workspace. To move it here, add this record, then run the command again:\n  ${claim.type} ${claim.name}  →  ${claim.value}',
      );
    }
    return ctx.emit(r.toJson(), _domainText(r.domain!));
  }
}

class DomainsCheckCommand extends KCommand {
  DomainsCheckCommand(super.ctx) {
    addOrgOption(this);
  }
  @override
  String get name => 'check';
  @override
  String get description => 'Check a domain\'s DNS and certificate now.';
  @override
  String get invocation => 'casama domains check <domain>';
  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.length != 1) throw UsageException('Which domain?', usage);
    final c = await ctx.authedClient();
    final d = await _domain(ctx, c, argResults!['org'] as String?, rest.single);
    final full = (await c.domains.checkDomain(id: d.id)).data!;
    return ctx.emit(full.toJson(), _domainText(full));
  }
}

class DomainsDisconnectCommand extends KCommand {
  DomainsDisconnectCommand(super.ctx) {
    addOrgOption(this);
  }
  @override
  String get name => 'disconnect';
  @override
  String get description =>
      'Disconnect a domain. A bought domain stays registered; only its site link goes.';
  @override
  String get invocation => 'casama domains disconnect <domain>';
  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.length != 1) throw UsageException('Which domain?', usage);
    final c = await ctx.authedClient();
    final d = await _domain(ctx, c, argResults!['org'] as String?, rest.single);
    await c.domains.deleteDomain(id: d.id);
    return ctx.emit({
      'id': d.id,
      'name': d.name,
      'disconnected': true,
    }, 'Disconnected ${d.name}.');
  }
}
