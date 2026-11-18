import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/widgets.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';
import 'bot_ui_kit.dart';

// Casama's cards for lists: messages, tasks, results and people (D-337).

// ---------------------------------------------------------------------------------------------
// MessageList
// ---------------------------------------------------------------------------------------------

final messageListComponent = casamaCard(
  'MessageList',
  const ['title', 'app', 'messages', 'reply'],
  (context, props, act) {
    final messages = [
      for (final m in cardRows(props['messages']).take(25))
        if (cardText(m['from']) case final from?)
          (
            id: cardText(m['id']) ?? '',
            from: from,
            subject: cardText(m['subject']),
            preview: cardText(m['preview']),
            time: cardTime(m['time']),
            unread: m['unread'] == true,
          ),
    ];
    if (messages.isEmpty) return null;
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final tt = context.textTheme;
    final unread = messages.where((m) => m.unread).length;
    final canReply = props['reply'] != false;
    return CardLayout(
      header: CardHeader(
        title: cardText(props['title']) ?? l10n.botCardMessages,
        app: cardText(props['app']),
        icon: LucideIcons.mail,
        pill: unread > 0 ? l10n.botCardUnread(unread) : null,
        pillColor: scheme.primary,
      ),
      body: CardPanel(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: CardRows(
          children: [
            for (final (i, m) in messages.indexed)
              Padding(
                key: Key('messageRow-$i'),
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CardAvatar(name: m.from),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (m.unread)
                                Container(
                                  width: 7,
                                  height: 7,
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: BoxDecoration(
                                    color: scheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              Expanded(
                                child: Text(
                                  m.from,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: tt.bodyMedium?.copyWith(
                                    fontWeight: m.unread
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (m.time != null)
                                Text(
                                  cardWhen(context, m.time!),
                                  style: tt.labelSmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                          if (m.subject != null)
                            Text(
                              m.subject!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: tt.bodyMedium?.copyWith(
                                fontWeight: m.unread ? FontWeight.w600 : null,
                              ),
                            ),
                          if (m.preview != null)
                            Text(
                              m.preview!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: tt.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                                height: 1.35,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (canReply)
                      IconButton(
                        key: Key('messageReply-$i'),
                        tooltip: l10n.botCardReply,
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          LucideIcons.reply,
                          size: 18,
                          color: scheme.onSurfaceVariant,
                        ),
                        onPressed: () => act('message.reply', {
                          'id': m.id,
                          'from': m.from,
                          'subject': ?m.subject,
                        }, l10n.botCardReplyTo(m.from)),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  },
);

// ---------------------------------------------------------------------------------------------
// Checklist
// ---------------------------------------------------------------------------------------------

typedef ChecklistItem = ({
  String id,
  String text,
  bool done,
  DateTime? due,
  bool dueDateOnly,
  String? detail,
});

final checklistComponent = casamaCard('Checklist', const ['title', 'items'], (
  context,
  props,
  act,
) {
  final items = <ChecklistItem>[
    for (final m in cardRows(props['items']).take(40))
      if (cardText(m['id']) case final id?)
        if (cardText(m['text']) case final text?)
          (
            id: id,
            text: text,
            done: m['done'] == true,
            due: cardTime(m['due']),
            dueDateOnly: cardIsDateOnly(m['due']),
            detail: cardText(m['detail']),
          ),
  ];
  if (items.isEmpty) return null;
  return BotChecklistCard(
    title: cardText(props['title']),
    items: items,
    onAction: act,
  );
});

/// Tasks or steps to tick; Save sends what changed in one answer.
class BotChecklistCard extends StatefulWidget {
  const BotChecklistCard({
    super.key,
    this.title,
    required this.items,
    required this.onAction,
  });
  final String? title;
  final List<ChecklistItem> items;
  final CardAction onAction;

  @override
  State<BotChecklistCard> createState() => _BotChecklistCardState();
}

class _BotChecklistCardState extends State<BotChecklistCard> {
  late final Map<String, bool> _done = {
    for (final i in widget.items) i.id: i.done,
  };

  List<String> _changed(bool to) => [
    for (final i in widget.items)
      if (_done[i.id] == to && i.done != to) i.id,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final tt = context.textTheme;
    final done = _done.values.where((d) => d).length;
    final dirty = _changed(true).isNotEmpty || _changed(false).isNotEmpty;
    return CardLayout(
      header: CardHeader(
        title: widget.title ?? l10n.botCardTasks,
        icon: LucideIcons.listChecks,
        pill: l10n.botCardDoneOf(done, widget.items.length),
        pillColor: done == widget.items.length
            ? context.appColors.positive
            : scheme.onSurfaceVariant,
      ),
      body: CardPanel(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: CardRows(
          children: [
            for (final (i, item) in widget.items.indexed)
              InkWell(
                key: Key('checkRow-$i'),
                borderRadius: BorderRadius.circular(AppRadius.row),
                onTap: () =>
                    setState(() => _done[item.id] = !(_done[item.id] ?? false)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _done[item.id] ?? false,
                        shape: const CircleBorder(),
                        visualDensity: VisualDensity.compact,
                        onChanged: (v) =>
                            setState(() => _done[item.id] = v ?? false),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.text,
                              style: tt.bodyMedium?.copyWith(
                                decoration: _done[item.id] == true
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: _done[item.id] == true
                                    ? scheme.onSurfaceVariant
                                    : scheme.onSurface,
                              ),
                            ),
                            if (item.due != null || item.detail != null)
                              Text(
                                [
                                  if (item.due != null)
                                    item.dueDateOnly
                                        ? cardDay(context, item.due!)
                                        : '${cardDay(context, item.due!)}, ${cardClock(context, item.due!)}',
                                  ?item.detail,
                                ].join(' · '),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: tt.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpace.xs),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      buttons: dirty
          ? [
              CardButton(
                key: const Key('checklistSave'),
                label: l10n.botCardSaveChanges,
                kind: CardButtonKind.primary,
                onPressed: () => widget.onAction('checklist.save', {
                  'done': _changed(true),
                  'undone': _changed(false),
                }, l10n.botCardSaveChanges),
              ),
            ]
          : const [],
    );
  }
}

// ---------------------------------------------------------------------------------------------
// Results
// ---------------------------------------------------------------------------------------------

typedef ResultItem = ({
  String? id,
  String title,
  String? subtitle,
  String? image,
  double? rating,
  String? reviews,
  String? price,
  String? url,
  String? badge,
});

final resultsComponent = casamaCard(
  'Results',
  const ['title', 'layout', 'items', 'choose'],
  (context, props, act) {
    final items = <ResultItem>[
      for (final m in cardRows(props['items']).take(20))
        if (cardText(m['title']) case final title?)
          (
            id: cardText(m['id']),
            title: title,
            subtitle: cardText(m['subtitle']),
            image: cardText(m['imageUrl']),
            rating: m['rating'] is num
                ? (m['rating']! as num).toDouble().clamp(0, 5).toDouble()
                : null,
            reviews: cardText(m['reviews']),
            price: cardText(m['price']),
            url: cardText(m['url']),
            badge: cardText(m['badge']),
          ),
    ];
    if (items.isEmpty) return null;
    final choose = props['choose'] == true;
    final title = cardText(props['title']);
    final l10n = context.l10n;
    void pick(ResultItem r) => act('result.choose', {
      'id': ?r.id,
      'title': r.title,
    }, l10n.botCardChose(r.title));
    final carousel =
        props['layout'] != 'list' && items.any((r) => r.image != null);
    return CardLayout(
      header: title == null
          ? null
          : CardHeader(title: title, icon: LucideIcons.layoutGrid),
      body: carousel
          ? SizedBox(
              height: choose ? 292 : 252,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(width: AppSpace.xs),
                itemBuilder: (context, i) => SizedBox(
                  width: 196,
                  child: _ResultTile(
                    key: Key('result-$i'),
                    item: items[i],
                    onChoose: choose ? () => pick(items[i]) : null,
                  ),
                ),
              ),
            )
          : CardPanel(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: CardRows(
                children: [
                  for (final (i, r) in items.indexed)
                    _ResultRow(
                      key: Key('result-$i'),
                      item: r,
                      onChoose: choose ? () => pick(r) : null,
                    ),
                ],
              ),
            ),
    );
  },
);

class _ResultMeta extends StatelessWidget {
  const _ResultMeta({required this.item});
  final ResultItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final tt = context.textTheme;
    if (item.rating == null && item.price == null) {
      return const SizedBox.shrink();
    }
    return Row(
      children: [
        if (item.rating != null) ...[
          Icon(LucideIcons.star, size: 13, color: context.appColors.warning),
          const SizedBox(width: 3),
          Text(
            item.rating!.toStringAsFixed(1),
            style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          if (item.reviews != null)
            Text(
              ' (${item.reviews})',
              style: tt.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
        ],
        const Spacer(),
        if (item.price != null)
          Text(
            item.price!,
            style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
      ],
    );
  }
}

class _ResultImage extends StatelessWidget {
  const _ResultImage({
    required this.url,
    required this.width,
    required this.height,
  });
  final String? url;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final empty = Container(
      width: width,
      height: height,
      color: scheme.surfaceContainerHighest,
      child: Icon(LucideIcons.image, color: scheme.onSurfaceVariant, size: 20),
    );
    final u = url;
    if (u == null || !u.startsWith('https://')) return empty;
    return Image.network(
      u,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => empty,
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({super.key, required this.item, this.onChoose});
  final ResultItem item;
  final VoidCallback? onChoose;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final tt = context.textTheme;
    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.tile),
        side: BorderSide(color: context.appColors.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: item.url == null ? null : () => cardOpenUrl(item.url),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                _ResultImage(url: item.image, width: 196, height: 116),
                if (item.badge != null)
                  Positioned(
                    left: 8,
                    top: 8,
                    child: CardPill(text: item.badge!),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: tt.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                    if (item.subtitle != null)
                      Text(
                        item.subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: tt.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    const Spacer(),
                    _ResultMeta(item: item),
                    if (onChoose != null) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: CardButton(
                          label: context.l10n.botCardChoose,
                          onPressed: onChoose,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({super.key, required this.item, this.onChoose});
  final ResultItem item;
  final VoidCallback? onChoose;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final tt = context.textTheme;
    return InkWell(
      onTap: item.url == null ? null : () => cardOpenUrl(item.url),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            if (item.image != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.icon),
                child: _ResultImage(url: item.image, width: 56, height: 56),
              ),
              const SizedBox(width: AppSpace.sm),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tt.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (item.badge != null) ...[
                        const SizedBox(width: 6),
                        CardPill(text: item.badge!),
                      ],
                    ],
                  ),
                  if (item.subtitle != null)
                    Text(
                      item.subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: tt.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  if (item.rating != null || item.price != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: _ResultMeta(item: item),
                    ),
                ],
              ),
            ),
            if (onChoose != null) ...[
              const SizedBox(width: AppSpace.xs),
              CardButton(
                label: context.l10n.botCardChoose,
                onPressed: onChoose,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------------------------
// PersonPicker
// ---------------------------------------------------------------------------------------------

typedef PersonOption = ({
  String? id,
  String name,
  String? detail,
  String? avatar,
});

final personPickerComponent = casamaCard(
  'PersonPicker',
  const ['label', 'people', 'multiple'],
  (context, props, act) {
    final people = <PersonOption>[
      for (final m in cardRows(props['people']).take(12))
        if (cardText(m['name']) case final name?)
          (
            id: cardText(m['id']),
            name: name,
            detail: cardText(m['detail']),
            avatar: cardText(m['avatarUrl']),
          ),
    ];
    if (people.isEmpty) return null;
    return BotPersonPicker(
      label: cardText(props['label']),
      people: people,
      multiple: props['multiple'] == true,
      onAction: act,
    );
  },
);

/// "Which Sarah?": the matching contacts, picked by tapping.
class BotPersonPicker extends StatefulWidget {
  const BotPersonPicker({
    super.key,
    this.label,
    required this.people,
    this.multiple = false,
    required this.onAction,
  });
  final String? label;
  final List<PersonOption> people;
  final bool multiple;
  final CardAction onAction;

  @override
  State<BotPersonPicker> createState() => _BotPersonPickerState();
}

class _BotPersonPickerState extends State<BotPersonPicker> {
  final _picked = <int>{};

  void _toggle(int i) => setState(() {
    if (widget.multiple) {
      _picked.contains(i) ? _picked.remove(i) : _picked.add(i);
    } else {
      _picked
        ..clear()
        ..add(i);
    }
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final tt = context.textTheme;
    final chosen = [for (final i in _picked.toList()..sort()) widget.people[i]];
    return CardLayout(
      header: CardHeader(
        title: widget.label ?? l10n.botCardWhichPerson,
        icon: LucideIcons.userSearch,
      ),
      body: CardPanel(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: CardRows(
          children: [
            for (final (i, p) in widget.people.indexed)
              InkWell(
                key: Key('person-$i'),
                borderRadius: BorderRadius.circular(AppRadius.row),
                onTap: () => _toggle(i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 9,
                  ),
                  child: Row(
                    children: [
                      CardAvatar(name: p.name, url: p.avatar, size: 34),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name,
                              style: tt.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (p.detail != null)
                              Text(
                                p.detail!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: tt.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Icon(
                        _picked.contains(i)
                            ? LucideIcons.circleCheck
                            : widget.multiple
                            ? LucideIcons.square
                            : LucideIcons.circle,
                        size: 20,
                        color: _picked.contains(i)
                            ? scheme.primary
                            : scheme.outline,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      buttons: [
        CardButton(
          key: const Key('personChoose'),
          label: l10n.botCardChoose,
          kind: CardButtonKind.primary,
          onPressed: chosen.isEmpty
              ? null
              : () => widget.onAction('person.pick', {
                  'people': [
                    for (final p in chosen)
                      {'id': ?p.id, 'name': p.name, 'detail': ?p.detail},
                  ],
                }, chosen.map((p) => p.name).join(', ')),
        ),
        CardButton(
          key: const Key('personNone'),
          label: l10n.botCardNoneOfThese,
          kind: CardButtonKind.quiet,
          onPressed: () =>
              widget.onAction('person.none', const {}, l10n.botCardNoneOfThese),
        ),
      ],
    );
  }
}
