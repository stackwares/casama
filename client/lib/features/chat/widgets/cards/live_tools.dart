import 'dart:math' as math;

import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:flutter/services.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/widgets.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_tokens.dart';
import 'live_kit.dart';

// Cards that work on the device (docs/RICH-CARDS-PLAN.md §6.3): calculators and random pickers
// do their math on the card, and the containers that lay several cards out.

// ---------------------------------------------------------------------------------------------
// Calculator
// ---------------------------------------------------------------------------------------------

final calculatorComponent = liveCard('Calculator', const ['kind', 'title', 'currency', 'inputs'], (context, p, ctl) {
  if (!const {'loan', 'savings', 'tip', 'percent', 'vat', 'unit'}.contains(p.s('kind'))) return null;
  return _Calculator(p: p);
});

class _Field {
  _Field(this.key, this.label, this.value, {this.suffix});
  final String key;
  final String label;
  double value;
  final String? suffix;
  late final controller = TextEditingController(text: value == value.roundToDouble() ? '${value.toInt()}' : '$value');
}

class _Calculator extends StatefulWidget {
  const _Calculator({required this.p});
  final P p;
  @override
  State<_Calculator> createState() => _CalculatorState();
}

class _CalculatorState extends State<_Calculator> {
  late final String kind = widget.p.s('kind')!;
  late final P inputs = widget.p.map('inputs');
  late final List<_Field> fields = _fields();
  late bool _included = inputs.b('included') ?? false;
  late String _from = inputs.s('from') ?? 'km';
  late String _to = inputs.s('to') ?? 'mi';

  List<_Field> _fields() {
    final l = context.l10n;
    double v(String k, double d) => inputs.n(k) ?? d;
    return switch (kind) {
      'loan' => [_Field('amount', l.cardCalcAmount, v('amount', 1000000)), _Field('rate', l.cardCalcRate, v('rate', 7), suffix: '%'), _Field('years', l.cardCalcYears, v('years', 20))],
      'savings' => [_Field('start', l.cardCalcStart, v('start', 10000)), _Field('monthly', l.cardCalcMonthly, v('monthly', 5000)), _Field('rate', l.cardCalcRate, v('rate', 5), suffix: '%'), _Field('years', l.cardCalcYears, v('years', 10))],
      'tip' => [_Field('bill', l.cardCalcBill, v('bill', 1500)), _Field('tip', l.cardCalcTip, v('tip', 10), suffix: '%'), _Field('people', l.cardCalcPeople, v('people', 2))],
      'percent' => [_Field('price', l.cardCalcPrice, v('price', 2000)), _Field('discount', l.cardCalcDiscount, v('discount', 20), suffix: '%')],
      'vat' => [_Field('amount', l.cardCalcAmount, v('amount', 1000)), _Field('rate', l.cardCalcTaxRate, v('rate', 12), suffix: '%')],
      _ => [_Field('value', l.cardCalcValue, v('value', 10))],
    };
  }

  double f(String k) => fields.firstWhere((x) => x.key == k).value;

  @override
  void dispose() {
    for (final x in fields) {
      x.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cur = widget.p.s('currency');
    String m(num v) => fmtMoney(context, v, cur);
    final (String main, String mainLabel, List<(String, String)> rows, Widget? chart) = switch (kind) {
      'loan' => () {
        final n = f('years') * 12;
        final r = f('rate') / 100 / 12;
        final pay = n <= 0 ? 0.0 : (r == 0 ? f('amount') / n : f('amount') * r / (1 - math.pow(1 + r, -n)));
        final total = pay * n;
        final interest = total - f('amount');
        return (m(pay), l.cardCalcMonthlyPayment, [(l.cardCalcTotalInterest, m(interest)), (l.cardCalcTotalPaid, m(total))], _Split(a: f('amount'), b: math.max(0, interest), aLabel: l.cardCalcPrincipal, bLabel: l.cardCalcInterest));
      }(),
      'savings' => () {
        final r = f('rate') / 100 / 12;
        final n = (f('years') * 12).round();
        var bal = f('start');
        final pts = <double>[bal];
        for (var i = 0; i < n; i++) {
          bal = bal * (1 + r) + f('monthly');
          if (i % 12 == 11) pts.add(bal);
        }
        final put = f('start') + f('monthly') * n;
        return (m(bal), l.cardCalcAfterYears(f('years').round()), [(l.cardCalcYouPutIn, m(put)), (l.cardCalcGrowth, m(bal - put))], Sparkline(points: pts, color: context.appColors.positive, height: 70));
      }(),
      'tip' => () {
        final tip = f('bill') * f('tip') / 100;
        final people = math.max(1, f('people').round());
        return (m((f('bill') + tip) / people), l.cardCalcPerPerson, [(l.cardCalcTipAmount, m(tip)), (l.cardCalcTotal, m(f('bill') + tip))], null);
      }(),
      'percent' => () {
        final off = f('price') * f('discount') / 100;
        return (m(f('price') - off), l.cardCalcYouPay, [(l.cardCalcYouSave, m(off))], null);
      }(),
      'vat' => () {
        final rate = f('rate') / 100;
        final net = _included ? f('amount') / (1 + rate) : f('amount');
        return (m(net * (1 + rate)), l.cardCalcGross, [(l.cardCalcNet, m(net)), (l.cardCalcTax, m(net * rate))], null);
      }(),
      _ => () {
        final out = convertUnit(f('value'), _from, _to);
        return (out == null ? '—' : '${_trim(out)} $_to', '${_trim(f('value'))} $_from', <(String, String)>[], null);
      }(),
    };
    final icon = switch (kind) {
      'loan' => LucideIcons.landmark,
      'savings' => LucideIcons.piggyBank,
      'tip' => LucideIcons.receipt,
      'percent' => LucideIcons.percent,
      'vat' => LucideIcons.receiptText,
      _ => LucideIcons.ruler,
    };
    return LiveLayout(
      header: LiveHeader(icon: icon, iconColor: const Color(0xFF0E7C66), title: widget.p.s('title') ?? _title(l, kind)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final x in fields)
                SizedBox(
                  width: kind == 'unit' ? 120 : 140,
                  child: TextField(
                    controller: x.controller,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, fontFeatures: AppText.tabular),
                    decoration: InputDecoration(labelText: x.label, suffixText: x.suffix, isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    onChanged: (v) => setState(() => x.value = double.tryParse(v) ?? 0),
                  ),
                ),
              if (kind == 'unit') ...[
                _UnitPicker(value: _from, onChanged: (v) => setState(() => _from = v)),
                const Icon(LucideIcons.arrowRight, size: 18),
                _UnitPicker(value: _to, family: unitFamily(_from), onChanged: (v) => setState(() => _to = v)),
              ],
              if (kind == 'vat') FilterChip(label: Text(l.cardCalcTaxIncluded), selected: _included, onSelected: (v) => setState(() => _included = v)),
            ],
          ),
          const SizedBox(height: 12),
          LivePanel(
            gradient: const LinearGradient(colors: [Color(0xFF0E7C66), Color(0xFF16A085)]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mainLabel, style: context.textTheme.labelLarge?.copyWith(color: Colors.white70)),
                FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(main, style: context.textTheme.displaySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700, fontFeatures: AppText.tabular))),
                for (final (k, v) in rows)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Expanded(child: Text(k, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textTheme.labelMedium?.copyWith(color: Colors.white70))),
                        const SizedBox(width: 8),
                        Flexible(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight, child: Text(v, style: context.textTheme.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700, fontFeatures: AppText.tabular)))),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (chart != null) ...[const SizedBox(height: 10), chart],
        ],
      ),
      footer: null,
    );
  }
}

String _title(dynamic l, String kind) => switch (kind) {
  'loan' => l.cardCalcLoan as String,
  'savings' => l.cardCalcSavings as String,
  'tip' => l.cardCalcTipSplit as String,
  'percent' => l.cardCalcDiscountTitle as String,
  'vat' => l.cardCalcVat as String,
  _ => l.cardCalcUnits as String,
};

String _trim(double v) {
  if (v.abs() >= 1000) return v.toStringAsFixed(0);
  final s = v.toStringAsPrecision(6);
  return s.contains('.') ? s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '') : s;
}

class _Split extends StatelessWidget {
  const _Split({required this.a, required this.b, required this.aLabel, required this.bLabel});
  final double a, b;
  final String aLabel, bLabel;
  @override
  Widget build(BuildContext context) {
    final total = a + b;
    final fa = total <= 0 ? 0.5 : a / total;
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 12,
            child: Row(children: [Expanded(flex: (fa * 1000).round(), child: Container(color: const Color(0xFF16A085))), Expanded(flex: ((1 - fa) * 1000).round(), child: Container(color: const Color(0xFFF2994A)))]),
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            _Legend(color: const Color(0xFF16A085), text: '$aLabel ${(fa * 100).round()}%'),
            _Legend(color: const Color(0xFFF2994A), text: '$bLabel ${((1 - fa) * 100).round()}%'),
          ],
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.text});
  final Color color;
  final String text;
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 4), Text(text, style: context.cardLabel)]);
}

/// Unit families and each unit's size in the family's base unit.
const _units = <String, Map<String, double>>{
  'length': {'mm': 0.001, 'cm': 0.01, 'm': 1, 'km': 1000, 'in': 0.0254, 'ft': 0.3048, 'yd': 0.9144, 'mi': 1609.344},
  'mass': {'g': 1, 'kg': 1000, 'oz': 28.349523125, 'lb': 453.59237, 'st': 6350.29318},
  'volume': {'ml': 1, 'l': 1000, 'tsp': 4.92892, 'tbsp': 14.7868, 'cup': 236.588, 'floz': 29.5735, 'pt': 473.176, 'qt': 946.353, 'gal': 3785.41},
  'speed': {'kph': 1, 'mph': 1.609344, 'ms': 3.6, 'kn': 1.852},
  'area': {'m2': 1, 'km2': 1e6, 'ha': 1e4, 'ft2': 0.092903, 'acre': 4046.86, 'sqm': 1},
  'temp': {'c': 1, 'f': 1, 'k': 1},
};

String? unitFamily(String u) {
  final k = u.toLowerCase();
  for (final e in _units.entries) {
    if (e.value.containsKey(k)) return e.key;
  }
  return null;
}

/// [v] in unit [from] as unit [to]; null when they don't measure the same thing.
double? convertUnit(double v, String from, String to) {
  final a = from.toLowerCase(), b = to.toLowerCase();
  final fam = unitFamily(a);
  if (fam == null || unitFamily(b) != fam) return null;
  if (fam == 'temp') {
    final c = switch (a) {
      'f' => (v - 32) * 5 / 9,
      'k' => v - 273.15,
      _ => v,
    };
    return switch (b) {
      'f' => c * 9 / 5 + 32,
      'k' => c + 273.15,
      _ => c,
    };
  }
  return v * _units[fam]![a]! / _units[fam]![b]!;
}

class _UnitPicker extends StatelessWidget {
  const _UnitPicker({required this.value, required this.onChanged, this.family});
  final String value;
  final ValueChanged<String> onChanged;
  final String? family;
  @override
  Widget build(BuildContext context) {
    final options = [
      for (final e in _units.entries)
        if (family == null || e.key == family)
          for (final u in e.value.keys) u,
    ];
    return DropdownButton<String>(
      value: options.contains(value.toLowerCase()) ? value.toLowerCase() : null,
      items: [for (final u in options) DropdownMenuItem(value: u, child: Text(u))],
      onChanged: (v) => v == null ? null : onChanged(v),
      underline: const SizedBox.shrink(),
    );
  }
}

// ---------------------------------------------------------------------------------------------
// Random
// ---------------------------------------------------------------------------------------------

final randomComponent = liveCard('Random', const ['kind', 'title', 'sides', 'count', 'min', 'max', 'options'], (context, p, ctl) {
  if (!const {'dice', 'coin', 'number', 'pick'}.contains(p.s('kind'))) return null;
  return _Random(p: p);
});

class _Random extends StatefulWidget {
  const _Random({required this.p});
  final P p;
  @override
  State<_Random> createState() => _RandomState();
}

class _RandomState extends State<_Random> {
  final _rnd = math.Random();
  List<String>? _result;
  int _spins = 0;

  void _go() {
    HapticFeedback.mediumImpact();
    final p = widget.p;
    setState(() {
      _spins++;
      _result = switch (p.s('kind')) {
        'dice' => [for (var i = 0; i < (p.i('count') ?? 1).clamp(1, 6); i++) '${_rnd.nextInt((p.i('sides') ?? 6).clamp(2, 100)) + 1}'],
        'coin' => [_rnd.nextBool() ? context.l10n.cardHeads : context.l10n.cardTails],
        'number' => ['${(p.i('min') ?? 1) + _rnd.nextInt(math.max(1, (p.i('max') ?? 100) - (p.i('min') ?? 1) + 1))}'],
        _ => p.texts('options').isEmpty ? ['—'] : [p.texts('options')[_rnd.nextInt(p.texts('options').length)]],
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final kind = widget.p.s('kind')!;
    final icon = switch (kind) {
      'dice' => LucideIcons.dices,
      'coin' => LucideIcons.coins,
      'number' => LucideIcons.hash,
      _ => LucideIcons.shuffle,
    };
    final r = _result;
    return LiveLayout(
      header: LiveHeader(icon: icon, iconColor: const Color(0xFF6C5CE7), title: widget.p.s('title') ?? l.cardRandom),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (kind == 'pick' && widget.p.texts('options').isNotEmpty)
            Wrap(spacing: 6, runSpacing: 6, children: [for (final o in widget.p.texts('options')) LivePill(text: o, color: r?.first == o ? const Color(0xFF6C5CE7) : null)]),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 350),
            transitionBuilder: (c, a) => ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.elasticOut), child: c),
            child: Container(
              key: ValueKey(_spins),
              height: 96,
              alignment: Alignment.center,
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)]), borderRadius: BorderRadius.circular(AppRadius.tile)),
              child: Text(
                r == null ? '?' : r.join('  '),
                textAlign: TextAlign.center,
                style: context.textTheme.displaySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          if (kind == 'dice' && r != null && r.length > 1) Padding(padding: const EdgeInsets.only(top: 6), child: Text(l.cardTotal(r.map(int.parse).reduce((a, b) => a + b)), textAlign: TextAlign.center, style: context.cardLabel)),
          const SizedBox(height: 10),
          FilledButton.icon(onPressed: _go, icon: Icon(icon, size: 18), label: Text(r == null ? l.cardGo : l.cardAgain)),
        ],
      ),
      footer: null,
    );
  }
}

// ---------------------------------------------------------------------------------------------
// Dashboard and Carousel
// ---------------------------------------------------------------------------------------------

ComponentImplementation _container(String name, Widget Function(BuildContext context, String? title, List<Widget> kids) build) => ComponentImplementation(
  name: name,
  schema: Schema.fromMap(<String, Object?>{
    'type': 'object',
    'properties': <String, Object?>{
      'component': <String, Object?>{'const': name},
      'title': const <String, Object?>{'type': 'string'},
      'children': const <String, Object?>{r'$ref': r'common_types.json#/$defs/ChildList'},
    },
    'required': const <Object?>['component', 'children'],
  }),
  builder: (context, node, props, buildChild) {
    final kids = props.children('children');
    if (kids.isEmpty) return const SizedBox.shrink();
    return build(context, props.string('title'), [for (final k in kids) buildChild(k)]);
  },
);

/// A grid of cards: two columns when there's room, one on a narrow phone.
final dashboardComponent = _container('Dashboard', (context, title, kids) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      if (title != null) Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(title, style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
      LayoutBuilder(
        builder: (context, box) {
          final two = box.maxWidth >= 720;
          final w = two ? (box.maxWidth - AppSpace.sm) / 2 : box.maxWidth;
          return Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              for (final k in kids)
                SizedBox(
                  width: w,
                  child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: context.colorScheme.surface.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(AppRadius.card), border: Border.all(color: context.appColors.hairline)), child: k),
                ),
            ],
          );
        },
      ),
    ],
  );
});

/// Cards side by side that the person swipes, with dots.
final carouselComponent = _container('Carousel', (context, title, kids) => _Carousel(title: title, kids: kids));

class _Carousel extends StatefulWidget {
  const _Carousel({required this.title, required this.kids});
  final String? title;
  final List<Widget> kids;
  @override
  State<_Carousel> createState() => _CarouselState();
}

class _CarouselState extends State<_Carousel> {
  final _c = PageController(viewportFraction: 0.92);
  int _at = 0;
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      if (widget.title != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(widget.title!, style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
      _MeasuredPages(controller: _c, kids: widget.kids, onPage: (i) => setState(() => _at = i)),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < widget.kids.length; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _at ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(color: i == _at ? context.colorScheme.primary : context.colorScheme.outlineVariant, borderRadius: BorderRadius.circular(3)),
            ),
        ],
      ),
    ],
  );
}

/// Pages as tall as the current page's card (a PageView needs a height; cards differ).
class _MeasuredPages extends StatefulWidget {
  const _MeasuredPages({required this.controller, required this.kids, required this.onPage});
  final PageController controller;
  final List<Widget> kids;
  final ValueChanged<int> onPage;
  @override
  State<_MeasuredPages> createState() => _MeasuredPagesState();
}

class _MeasuredPagesState extends State<_MeasuredPages> {
  final _heights = <int, double>{};
  int _page = 0;
  @override
  Widget build(BuildContext context) {
    final h = _heights[_page] ?? 360;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      height: h,
      child: PageView.builder(
        controller: widget.controller,
        itemCount: widget.kids.length,
        onPageChanged: (i) {
          setState(() => _page = i);
          widget.onPage(i);
        },
        itemBuilder: (context, i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: OverflowBox(
            alignment: Alignment.topCenter,
            minHeight: 0,
            maxHeight: double.infinity,
            child: _SizeReporter(
              onSize: (s) {
                if ((_heights[i] ?? 0) != s.height) setState(() => _heights[i] = s.height);
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: context.colorScheme.surface.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(AppRadius.card), border: Border.all(color: context.appColors.hairline)),
                child: widget.kids[i],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SizeReporter extends StatefulWidget {
  const _SizeReporter({required this.onSize, required this.child});
  final ValueChanged<Size> onSize;
  final Widget child;
  @override
  State<_SizeReporter> createState() => _SizeReporterState();
}

class _SizeReporterState extends State<_SizeReporter> {
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final s = context.size;
      if (mounted && s != null) widget.onSize(s);
    });
    return widget.child;
  }
}
