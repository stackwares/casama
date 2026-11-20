import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/widgets.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_tokens.dart';
import 'live_kit.dart';

// Composed cards (docs/RICH-CARDS-PLAN.md §4.7, §6.7–6.13): what a bot writes from what it knows
// or read, drawn with the same parts as the data cards, saying where the content came from.

/// "From the bot" unless the card names its source.
LiveFooter composedFooter(BuildContext context, P p) => LiveFooter(note: p.map('source').isEmpty && p.map('live').isEmpty ? context.l10n.cardFromBot : null);

// ---------------------------------------------------------------------------------------------
// Summary (Wikipedia, a person, a place, a company)
// ---------------------------------------------------------------------------------------------

final summaryComponent = liveCard('Summary', const ['title', 'subtitle', 'imageUrl', 'text', 'facts', 'url'], (context, p, ctl) {
  final title = p.s('title');
  if (title == null) return null;
  final img = p.s('imageUrl');
  final facts = p.rows('facts');
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      if (img != null) ...[
        Stack(
          children: [
            CardImage(url: img, height: 170, width: double.infinity, radius: AppRadius.tile),
            Positioned(right: 4, top: 4, child: Container(decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(16)), child: Theme(data: ThemeData.dark(), child: const LiveMenu()))),
          ],
        ),
        const SizedBox(height: 12),
      ],
      Row(
        children: [
          Expanded(child: Text(title, style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700))),
          if (img == null) const LiveMenu(),
        ],
      ),
      if (p.s('subtitle') case final s?) Text(s, style: context.cardLabel),
      const SizedBox(height: 8),
      Text(p.s('text') ?? '', style: context.cardBody, maxLines: 9, overflow: TextOverflow.ellipsis),
      if (facts.isNotEmpty) ...[
        const SizedBox(height: 10),
        LivePanel(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Column(
            children: [
              for (final f in facts)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 110, child: Text(f.s('label') ?? '', style: context.cardLabel)),
                      Expanded(child: Text(f.s('value') ?? '', style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
      if (p.s('url') case final u?)
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(onPressed: () => openCardLink(u), icon: const Icon(LucideIcons.bookOpen, size: 16), label: Text(context.l10n.cardReadMore)),
        ),
      composedFooter(context, p),
    ],
  );
});

// ---------------------------------------------------------------------------------------------
// Definition
// ---------------------------------------------------------------------------------------------

final definitionComponent = liveCard('Definition', const ['word', 'phonetic', 'audioUrl', 'senses', 'synonyms', 'lang'], (context, p, ctl) {
  final l = context.l10n;
  final word = p.s('word');
  if (word == null) return null;
  final senses = p.rows('senses');
  final syn = p.texts('synonyms');
  return LiveLayout(
    header: LiveHeader(icon: LucideIcons.bookA, iconColor: const Color(0xFF8E44AD), title: l.cardDictionary, subtitle: p.s('lang')),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(child: Text(word, style: context.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700, fontFamily: context.textTheme.headlineMedium?.fontFamily))),
            const SizedBox(width: 10),
            if (p.s('phonetic') case final ph?) Flexible(child: Padding(padding: const EdgeInsets.only(bottom: 5), child: Text(ph, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textTheme.titleSmall?.copyWith(color: context.colorScheme.onSurfaceVariant)))),
            if (p.s('audioUrl') case final a?) _PlayButton(url: a),
          ],
        ),
        const SizedBox(height: 10),
        for (final (i, s) in senses.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: const Color(0xFF8E44AD).withValues(alpha: 0.12), shape: BoxShape.circle),
                  child: Text('${i + 1}', style: context.textTheme.labelSmall?.copyWith(color: const Color(0xFF8E44AD), fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (s.s('pos') case final pos?) Text(pos, style: context.textTheme.labelSmall?.copyWith(fontStyle: FontStyle.italic, color: context.colorScheme.onSurfaceVariant)),
                      Text(s.s('meaning') ?? '', style: context.cardBody),
                      if (s.s('example') case final ex?) Padding(padding: const EdgeInsets.only(top: 2), child: Text('“$ex”', style: context.cardLabel?.copyWith(fontStyle: FontStyle.italic))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        if (syn.isNotEmpty)
          Wrap(spacing: 6, runSpacing: 6, children: [Text(l.cardSynonyms, style: context.cardLabel), for (final s in syn) LivePill(text: s)]),
      ],
    ),
    footer: composedFooter(context, p),
  );
});

class _PlayButton extends StatefulWidget {
  const _PlayButton({required this.url});
  final String url;
  @override
  State<_PlayButton> createState() => _PlayButtonState();
}

class _PlayButtonState extends State<_PlayButton> {
  AudioPlayer? _player;
  bool _playing = false;
  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  Future<void> _play() async {
    if (!widget.url.startsWith('https://')) return;
    try {
      final player = _player ??= AudioPlayer();
      setState(() => _playing = true);
      await player.setUrl(widget.url);
      await player.play();
    } catch (_) {
    } finally {
      if (mounted) setState(() => _playing = false);
    }
  }

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: context.l10n.cardListen,
    onPressed: _playing ? null : _play,
    icon: Icon(_playing ? LucideIcons.audioLines : LucideIcons.volume2, size: 20),
  );
}

// ---------------------------------------------------------------------------------------------
// Media (a book, film, show, album…)
// ---------------------------------------------------------------------------------------------

IconData _mediaIcon(String? k) => switch (k) {
  'book' => LucideIcons.bookOpen,
  'movie' => LucideIcons.film,
  'show' => LucideIcons.tv,
  'song' || 'album' => LucideIcons.music,
  'game' => LucideIcons.gamepad2,
  'podcast' => LucideIcons.podcast,
  'app' => LucideIcons.appWindow,
  _ => LucideIcons.star,
};

final mediaComponent = liveCard('Media', const ['kind', 'title', 'subtitle', 'imageUrl', 'year', 'rating', 'ratingMax', 'text', 'facts', 'links', 'url'], (context, p, ctl) {
  final title = p.s('title');
  if (title == null) return null;
  final rating = p.n('rating');
  final max = p.n('ratingMax') ?? 10;
  final tall = p.s('kind') == 'book' || p.s('kind') == 'movie' || p.s('kind') == 'show';
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardImage(
            url: p.s('imageUrl'),
            width: 96,
            height: tall ? 144 : 96,
            radius: 10,
            fallback: Container(width: 96, height: tall ? 144 : 96, color: context.colorScheme.surfaceContainerHighest, child: Icon(_mediaIcon(p.s('kind')), size: 32, color: context.colorScheme.onSurfaceVariant)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_mediaIcon(p.s('kind')), size: 14, color: context.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Expanded(child: Text([?p.s('year'), ?p.s('kind')].join(' · ').toUpperCase(), style: context.textTheme.labelSmall?.copyWith(letterSpacing: 0.8, color: context.colorScheme.onSurfaceVariant))),
                    const LiveMenu(),
                  ],
                ),
                Text(title, style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, height: 1.15)),
                if (p.s('subtitle') case final s?) Text(s, style: context.cardLabel),
                if (rating != null) ...[const SizedBox(height: 6), _Stars(value: rating / max * 5, label: '${rating.toStringAsFixed(1)} / ${max.round()}')],
                const SizedBox(height: 6),
                for (final f in p.rows('facts').take(4)) Text('${f.s('label')}: ${f.s('value')}', maxLines: 1, overflow: TextOverflow.ellipsis, style: context.cardLabel),
              ],
            ),
          ),
        ],
      ),
      if (p.s('text') case final t?) ...[const SizedBox(height: 10), Text(t, maxLines: 6, overflow: TextOverflow.ellipsis, style: context.cardBody)],
      if (p.rows('links').isNotEmpty || p.s('url') != null) ...[
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          children: [
            for (final k in p.rows('links').take(4)) OutlinedButton(onPressed: () => openCardLink(k.s('url')), child: Text(k.s('label') ?? '')),
            if (p.rows('links').isEmpty && p.s('url') != null) OutlinedButton.icon(onPressed: () => openCardLink(p.s('url')), icon: const Icon(LucideIcons.externalLink, size: 14), label: Text(context.l10n.cardOpen)),
          ],
        ),
      ],
      composedFooter(context, p),
    ],
  );
});

class _Stars extends StatelessWidget {
  const _Stars({required this.value, required this.label});
  final double value;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var i = 0; i < 5; i++)
        Icon(
          value >= i + 0.75 ? Icons.star_rounded : (value >= i + 0.25 ? Icons.star_half_rounded : Icons.star_outline_rounded),
          size: 18,
          color: const Color(0xFFF5A623),
        ),
      const SizedBox(width: 6),
      Text(label, style: context.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
    ],
  );
}

// ---------------------------------------------------------------------------------------------
// Recipe
// ---------------------------------------------------------------------------------------------

final recipeComponent = liveCard('Recipe', const ['title', 'imageUrl', 'time', 'servings', 'calories', 'ingredients', 'steps', 'url'], (context, p, ctl) {
  if (p.s('title') == null || p.rows('ingredients').isEmpty) return null;
  return _Recipe(p: p);
});

class _Recipe extends StatefulWidget {
  const _Recipe({required this.p});
  final P p;
  @override
  State<_Recipe> createState() => _RecipeState();
}

class _RecipeState extends State<_Recipe> {
  late final int _base = widget.p.i('servings') ?? 0;
  late int _servings = _base;
  final _have = <int>{};
  bool _showSteps = false;

  String _qty(double q) {
    final v = _base > 0 ? q * _servings / _base : q;
    if (v == v.roundToDouble()) return '${v.toInt()}';
    final fr = {0.25: '¼', 0.5: '½', 0.75: '¾', 0.33: '⅓', 0.67: '⅔'};
    final whole = v.floor();
    final part = double.parse((v - whole).toStringAsFixed(2));
    final f = fr[part];
    if (f != null) return whole > 0 ? '$whole$f' : f;
    return v.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = widget.p;
    final ing = p.rows('ingredients');
    final steps = p.texts('steps');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (p.s('imageUrl') case final img?) ...[CardImage(url: img, height: 160, width: double.infinity, radius: AppRadius.tile), const SizedBox(height: 12)],
        LiveHeader(icon: LucideIcons.chefHat, iconColor: const Color(0xFFE67E22), title: p.s('title')!, subtitle: [?p.s('time'), if (p.i('calories') case final c?) l.cardCalories(c)].join(' · ')),
        const SizedBox(height: 10),
        if (_base > 0)
          Row(
            children: [
              Text(l.cardServings, style: context.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
              const Spacer(),
              IconButton.filledTonal(onPressed: _servings > 1 ? () => setState(() => _servings--) : null, icon: const Icon(LucideIcons.minus, size: 16)),
              SizedBox(width: 36, child: Text('$_servings', textAlign: TextAlign.center, style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
              IconButton.filledTonal(onPressed: _servings < 50 ? () => setState(() => _servings++) : null, icon: const Icon(LucideIcons.plus, size: 16)),
            ],
          ),
        LivePanel(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Column(
            children: [
              for (final (i, x) in ing.indexed)
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => setState(() => _have.contains(i) ? _have.remove(i) : _have.add(i)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      children: [
                        Icon(_have.contains(i) ? LucideIcons.circleCheck : LucideIcons.circle, size: 18, color: _have.contains(i) ? context.appColors.positive : context.colorScheme.outline),
                        const SizedBox(width: 10),
                        if (x.n('qty') case final q?)
                          Padding(padding: const EdgeInsets.only(right: 6), child: Text('${_qty(q)}${x.s('unit') == null ? '' : ' ${x.s('unit')}'}', style: context.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800, fontFeatures: AppText.tabular))),
                        Expanded(child: Text(x.s('text') ?? '', style: context.cardBody?.copyWith(decoration: _have.contains(i) ? TextDecoration.lineThrough : null, color: _have.contains(i) ? context.colorScheme.onSurfaceVariant : null))),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (steps.isNotEmpty) ...[
          const SizedBox(height: 8),
          InkWell(
            onTap: () => setState(() => _showSteps = !_showSteps),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [Text(l.cardStepsCount(steps.length), style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)), const Spacer(), Icon(_showSteps ? LucideIcons.chevronUp : LucideIcons.chevronDown, size: 18)]),
            ),
          ),
          if (_showSteps)
            for (final (i, s) in steps.indexed) _NumberedRow(n: i + 1, text: s, color: const Color(0xFFE67E22)),
        ],
        if (p.s('url') != null) Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: () => openCardLink(p.s('url')), icon: const Icon(LucideIcons.externalLink, size: 14), label: Text(l.cardFullRecipe))),
        composedFooter(context, p),
      ],
    );
  }
}

class _NumberedRow extends StatelessWidget {
  const _NumberedRow({required this.n, required this.text, required this.color, this.title});
  final int n;
  final String text;
  final String? title;
  final Color color;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Text('$n', style: context.textTheme.labelMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null) Text(title!, style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              if (text.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 2), child: Text(text, style: context.cardBody)),
            ],
          ),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------------------------
// Comparison, pros and cons, steps, timeline
// ---------------------------------------------------------------------------------------------

final comparisonComponent = liveCard('Comparison', const ['title', 'items', 'rows'], (context, p, ctl) {
  final items = p.texts('items');
  final rows = p.rows('rows');
  if (items.length < 2 || rows.isEmpty) return null;
  final wins = List.filled(items.length, 0);
  for (final r in rows) {
    final b = r.i('best');
    if (b != null && b < items.length) wins[b]++;
  }
  final top = wins.reduce((a, b) => a > b ? a : b);
  return LiveLayout(
    header: LiveHeader(icon: LucideIcons.columns3, title: p.s('title') ?? context.l10n.cardComparison, subtitle: items.join(' vs ')),
    body: LivePanel(
      padding: const EdgeInsets.all(4),
      child: Table(
        columnWidths: {0: const FlexColumnWidth(1.1), for (var i = 1; i <= items.length; i++) i: const FlexColumnWidth(1)},
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            decoration: BoxDecoration(color: context.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(10)),
            children: [
              const SizedBox(),
              for (final (i, it) in items.indexed)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Text(it, textAlign: TextAlign.center, style: context.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
                      if (top > 0 && wins[i] == top) Padding(padding: const EdgeInsets.only(top: 2), child: FittedBox(fit: BoxFit.scaleDown, child: LivePill(text: context.l10n.cardWins(wins[i]), color: context.appColors.positive))),
                    ],
                  ),
                ),
            ],
          ),
          for (final r in rows)
            TableRow(
              children: [
                Padding(padding: const EdgeInsets.all(8), child: Text(r.s('label') ?? '', style: context.cardLabel?.copyWith(fontWeight: FontWeight.w600))),
                for (final (i, v) in r.texts('values').indexed)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (r.i('best') == i) ...[Icon(LucideIcons.badgeCheck, size: 14, color: context.appColors.positive), const SizedBox(width: 3)],
                        Flexible(child: Text(v, textAlign: TextAlign.center, style: context.textTheme.bodySmall?.copyWith(fontWeight: r.i('best') == i ? FontWeight.w800 : null))),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    ),
    footer: composedFooter(context, p),
  );
});

final prosConsComponent = liveCard('ProsCons', const ['title', 'pros', 'cons', 'verdict'], (context, p, ctl) {
  final l = context.l10n;
  Widget col(String title, List<String> items, Color c, IconData icon) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(AppRadius.tile)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.textTheme.labelLarge?.copyWith(color: c, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          for (final t in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Padding(padding: const EdgeInsets.only(top: 2), child: Icon(icon, size: 14, color: c)), const SizedBox(width: 6), Expanded(child: Text(t, style: context.textTheme.bodySmall))]),
            ),
        ],
      ),
    ),
  );
  return LiveLayout(
    header: LiveHeader(icon: LucideIcons.scale, title: p.s('title') ?? l.cardProsCons),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [col(l.cardPros, p.texts('pros'), context.appColors.positive, LucideIcons.plus), const SizedBox(width: 8), col(l.cardCons, p.texts('cons'), context.appColors.negative, LucideIcons.minus)],
          ),
        ),
        if (p.s('verdict') case final v?) ...[const SizedBox(height: 8), LivePanel(child: Row(children: [const Icon(LucideIcons.gavel, size: 16), const SizedBox(width: 8), Expanded(child: Text(v, style: context.cardBody?.copyWith(fontWeight: FontWeight.w600)))]))],
      ],
    ),
    footer: composedFooter(context, p),
  );
});

final stepsComponent = liveCard('Steps', const ['title', 'steps'], (context, p, ctl) {
  final steps = p.rows('steps');
  if (steps.isEmpty) return null;
  return LiveLayout(
    header: LiveHeader(icon: LucideIcons.listOrdered, title: p.s('title') ?? context.l10n.cardStepsCount(steps.length), subtitle: context.l10n.cardStepsCount(steps.length)),
    body: Column(children: [for (final (i, s) in steps.indexed) _NumberedRow(n: i + 1, title: s.s('title'), text: s.s('detail') ?? '', color: context.colorScheme.primary)]),
    footer: composedFooter(context, p),
  );
});

final timelineComponent = liveCard('Timeline', const ['title', 'events'], (context, p, ctl) {
  final events = p.rows('events');
  if (events.isEmpty) return null;
  final c = context.colorScheme.primary;
  return LiveLayout(
    header: LiveHeader(icon: LucideIcons.milestone, title: p.s('title') ?? context.l10n.cardTimeline),
    body: Column(
      children: [
        for (final (i, e) in events.indexed)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: 78, child: Padding(padding: const EdgeInsets.only(top: 1), child: Text(e.s('when') ?? '', textAlign: TextAlign.right, style: context.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700, color: c)))),
                const SizedBox(width: 10),
                Column(
                  children: [
                    Container(width: 12, height: 12, margin: const EdgeInsets.only(top: 3), decoration: BoxDecoration(shape: BoxShape.circle, color: c, border: Border.all(color: context.colorScheme.surface, width: 2))),
                    if (i < events.length - 1) Expanded(child: Container(width: 2, color: c.withValues(alpha: 0.25))),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.s('title') ?? '', style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                        if (e.s('detail') case final d?) Text(d, style: context.cardLabel),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
    footer: composedFooter(context, p),
  );
});

// ---------------------------------------------------------------------------------------------
// Translation, contact, nutrition, status
// ---------------------------------------------------------------------------------------------

final translationComponent = liveCard('Translation', const ['from', 'to', 'source', 'translated', 'romanized', 'note'], (context, p, ctl) {
  final l = context.l10n;
  Widget side(String lang, String text, {bool main = false, String? extra}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: main ? context.colorScheme.primary.withValues(alpha: 0.08) : context.colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.tile),
      border: Border.all(color: main ? context.colorScheme.primary.withValues(alpha: 0.3) : context.appColors.hairline),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(lang.toUpperCase(), style: context.textTheme.labelSmall?.copyWith(letterSpacing: 1, fontWeight: FontWeight.w800, color: main ? context.colorScheme.primary : context.colorScheme.onSurfaceVariant)),
            const Spacer(),
            InkResponse(
              radius: 16,
              onTap: () {
                Clipboard.setData(ClipboardData(text: text));
                ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(l.cardCopied)));
              },
              child: Icon(LucideIcons.copy, size: 15, color: context.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SelectableText(text, style: (main ? context.textTheme.titleMedium : context.textTheme.bodyMedium)?.copyWith(fontWeight: main ? FontWeight.w600 : null, height: 1.4)),
        if (extra != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(extra, style: context.cardLabel?.copyWith(fontStyle: FontStyle.italic))),
      ],
    ),
  );
  return LiveLayout(
    header: LiveHeader(icon: LucideIcons.languages, title: l.cardTranslation, subtitle: '${p.s('from')} → ${p.s('to')}'),
    body: Column(
      children: [
        side(p.s('from') ?? '', p.s('source') ?? ''),
        const SizedBox(height: 6),
        side(p.s('to') ?? '', p.s('translated') ?? '', main: true, extra: p.s('romanized')),
        if (p.s('note') case final n?) Padding(padding: const EdgeInsets.only(top: 8), child: Row(children: [const Icon(LucideIcons.info, size: 14), const SizedBox(width: 6), Expanded(child: Text(n, style: context.cardLabel))])),
      ],
    ),
    footer: composedFooter(context, p),
  );
});

final contactComponent = liveCard('Contact', const ['name', 'title', 'company', 'phones', 'emails', 'address', 'avatarUrl', 'url'], (context, p, ctl) {
  final l = context.l10n;
  final name = p.s('name');
  if (name == null) return null;
  final phones = p.texts('phones');
  final emails = p.texts('emails');
  Future<void> go(String scheme, String v) => launchUrl(Uri(scheme: scheme, path: v));
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        children: [
          Monogram(text: name, url: p.s('avatarUrl'), size: 52),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                if ([p.s('title'), p.s('company')].whereType<String>().join(' · ') case final t when t.isNotEmpty) Text(t, style: context.cardLabel),
              ],
            ),
          ),
          const LiveMenu(),
        ],
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (phones.isNotEmpty) FilledButton.tonalIcon(onPressed: () => go('tel', phones.first), icon: const Icon(LucideIcons.phone, size: 16), label: Text(l.cardCall)),
          if (phones.isNotEmpty) FilledButton.tonalIcon(onPressed: () => go('sms', phones.first), icon: const Icon(LucideIcons.messageSquare, size: 16), label: Text(l.cardMessage)),
          if (emails.isNotEmpty) FilledButton.tonalIcon(onPressed: () => go('mailto', emails.first), icon: const Icon(LucideIcons.mail, size: 16), label: Text(l.cardEmail)),
          if (p.s('url') != null) FilledButton.tonalIcon(onPressed: () => openCardLink(p.s('url')), icon: const Icon(LucideIcons.globe, size: 16), label: Text(l.cardWebsite)),
        ],
      ),
      const SizedBox(height: 10),
      LivePanel(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          children: [
            for (final ph in phones) _ContactRow(icon: LucideIcons.phone, text: ph),
            for (final e in emails) _ContactRow(icon: LucideIcons.mail, text: e),
            if (p.s('address') case final a?) _ContactRow(icon: LucideIcons.mapPin, text: a),
          ],
        ),
      ),
    ],
  );
});

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Icon(icon, size: 16, color: context.colorScheme.onSurfaceVariant),
        const SizedBox(width: 10),
        Expanded(child: SelectableText(text, style: context.cardBody)),
        InkResponse(
          radius: 16,
          onTap: () {
            Clipboard.setData(ClipboardData(text: text));
            ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(context.l10n.cardCopied)));
          },
          child: Icon(LucideIcons.copy, size: 15, color: context.colorScheme.onSurfaceVariant),
        ),
      ],
    ),
  );
}

final nutritionComponent = liveCard('Nutrition', const ['title', 'serving', 'calories', 'rows'], (context, p, ctl) {
  final l = context.l10n;
  final cal = p.n('calories');
  if (cal == null) return null;
  final ink = context.colorScheme.onSurface;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(children: [Expanded(child: Text(p.s('title') ?? '', style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700))), const LiveMenu()]),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(border: Border.all(color: ink, width: 1.5), borderRadius: BorderRadius.circular(6)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.cardNutritionFacts, style: context.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, height: 1)),
            if (p.s('serving') case final s?) Text(l.cardServingSize(s), style: context.textTheme.labelMedium),
            Divider(thickness: 8, color: ink, height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(l.cardCaloriesWord, style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                const Spacer(),
                Text('${cal.round()}', style: context.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
              ],
            ),
            Divider(thickness: 4, color: ink, height: 12),
            for (final r in p.rows('rows'))
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: ink.withValues(alpha: 0.3)))),
                child: Row(
                  children: [
                    Text(r.s('label') ?? '', style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(width: 6),
                    Text(r.s('value') ?? '', style: context.textTheme.bodyMedium),
                    const Spacer(),
                    if (r.n('daily') case final d?) Text('${d.round()}%', style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
          ],
        ),
      ),
      composedFooter(context, p),
    ],
  );
});

(Color, IconData) statusLook(BuildContext context, String? s) => switch (s?.toLowerCase()) {
  'open' || 'running' || 'queued' => (const Color(0xFF2F7BD3), LucideIcons.circleDot),
  'merged' || 'done' || 'passed' || 'up' => (context.appColors.positive, LucideIcons.circleCheck),
  'closed' || 'cancelled' => (const Color(0xFF8B5CF6), LucideIcons.circleSlash),
  'failed' || 'down' || 'blocked' => (context.appColors.negative, LucideIcons.circleX),
  'degraded' => (context.appColors.warning, LucideIcons.triangleAlert),
  'draft' => (context.colorScheme.outline, LucideIcons.circleDashed),
  _ => (context.colorScheme.onSurfaceVariant, LucideIcons.circle),
};

final statusComponent = liveCard('Status', const ['title', 'kind', 'state', 'ref', 'url', 'subtitle', 'app', 'jobs', 'stats'], (context, p, ctl) {
  final (c, icon) = statusLook(context, p.s('state'));
  final checks = p.rows('jobs');
  final passed = checks.where((x) => ['passed', 'done', 'up', 'success'].contains(x.s('state')?.toLowerCase())).length;
  final kindIcon = switch (p.s('kind')) {
    'pr' => LucideIcons.gitPullRequest,
    'issue' => LucideIcons.circleDot,
    'ci' => LucideIcons.workflow,
    'deploy' => LucideIcons.rocket,
    'service' => LucideIcons.server,
    'order' => LucideIcons.package,
    _ => LucideIcons.squareCheck,
  };
  return LiveLayout(
    header: LiveHeader(icon: kindIcon, iconColor: c, title: p.s('title')!, subtitle: [?p.s('ref'), ?p.s('subtitle')].join(' · '), pill: p.s('state'), pillColor: c),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (p.rows('stats').isNotEmpty)
          Wrap(spacing: 6, runSpacing: 6, children: [for (final s in p.rows('stats')) FactChip(icon: LucideIcons.hash, label: s.s('label') ?? '', value: s.s('value') ?? '')]),
        if (checks.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(children: [Text(context.l10n.cardChecksPassed(passed, checks.length), style: context.cardLabel), const Spacer()]),
          const SizedBox(height: 4),
          ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: checks.isEmpty ? 0 : passed / checks.length, minHeight: 6, color: context.appColors.positive, backgroundColor: context.colorScheme.surfaceContainerHighest)),
          const SizedBox(height: 6),
          LivePanel(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Column(
              children: [
                for (final x in checks.take(12))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Builder(
                      builder: (context) {
                        final (cc, ii) = statusLook(context, x.s('state'));
                        return Row(children: [Icon(ii, size: 15, color: cc), const SizedBox(width: 8), Expanded(child: Text(x.s('name') ?? '', maxLines: 1, overflow: TextOverflow.ellipsis)), if (x.s('detail') case final d?) Text(d, style: context.cardLabel)]);
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (p.s('url') != null) Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: () => openCardLink(p.s('url')), icon: Icon(icon, size: 14), label: Text(context.l10n.cardOpen))),
      ],
    ),
    footer: composedFooter(context, p),
  );
});

// ---------------------------------------------------------------------------------------------
// Quiz
// ---------------------------------------------------------------------------------------------

final quizComponent = liveCard('Quiz', const ['title', 'question', 'options', 'answer', 'explanation'], (context, p, ctl) {
  if (p.s('question') == null || p.texts('options').length < 2) return null;
  return _Quiz(p: p, ctl: ctl);
});

class _Quiz extends StatefulWidget {
  const _Quiz({required this.p, required this.ctl});
  final P p;
  final LiveCardController ctl;
  @override
  State<_Quiz> createState() => _QuizState();
}

/// Answers by question, so a quiz the chat rebuilds after the answer is sent still shows it.
final _quizPicks = <String, int>{};

class _QuizState extends State<_Quiz> {
  String get _key => '${widget.p.s('question')}|${widget.p.texts('options').join('|')}';
  int? get _picked => _quizPicks[_key];
  set _picked(int? v) => v == null ? _quizPicks.remove(_key) : _quizPicks[_key] = v;
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = widget.p;
    final opts = p.texts('options');
    final right = p.i('answer');
    return LiveLayout(
      header: LiveHeader(icon: LucideIcons.circleHelp, iconColor: const Color(0xFF8E44AD), title: p.s('title') ?? l.cardQuiz),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(p.s('question')!, style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          for (final (i, o) in opts.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Builder(
                builder: (context) {
                  final done = _picked != null;
                  final isRight = right == i;
                  final isPicked = _picked == i;
                  final c = !done
                      ? context.colorScheme.outlineVariant
                      : isRight
                      ? context.appColors.positive
                      : (isPicked ? context.appColors.negative : context.colorScheme.outlineVariant);
                  return Material(
                    color: done && (isRight || isPicked) ? c.withValues(alpha: 0.10) : context.colorScheme.surface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: c, width: done && (isRight || isPicked) ? 2 : 1)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: done
                          ? null
                          : () {
                              HapticFeedback.selectionClick();
                              setState(() => _picked = i);
                              widget.ctl.act('quiz.answer', {'choice': i, 'option': o, if (right != null) 'correct': right == i}, o);
                            },
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Text(String.fromCharCode(65 + i), style: context.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800, color: context.colorScheme.onSurfaceVariant)),
                            const SizedBox(width: 12),
                            Expanded(child: Text(o)),
                            if (done && isRight) Icon(LucideIcons.circleCheck, color: context.appColors.positive, size: 18),
                            if (done && isPicked && !isRight) Icon(LucideIcons.circleX, color: context.appColors.negative, size: 18),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          if (_picked != null && p.s('explanation') != null) LivePanel(child: Text(p.s('explanation')!, style: context.cardBody)),
        ],
      ),
      footer: null,
    );
  }
}
