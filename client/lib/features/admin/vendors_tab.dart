import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// The bot widgets' Canvas model would shadow dart:ui's Canvas this file paints on.
import 'package:casama_sdk/casama_sdk.dart' hide Canvas;
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';

final adminVendorsProvider = FutureProvider.autoDispose<List<AdminVendor>>(
  (ref) => ref.watch(backendProvider).adminVendors(),
);

String vendorStatus(BuildContext context, AdminVendor v) {
  final words = context.l10n;
  if (v.latest == null) return words.vendorNoReading;
  if (v.latest!.error == 'not_configured') return words.vendorNotSetUp;
  return switch (v.latest!.status.value) {
    'ok' => words.vendorOk,
    'low' => words.vendorLow,
    'out' => words.vendorOut,
    _ => words.vendorUnknown,
  };
}

class VendorAttentionBanner extends ConsumerWidget {
  const VendorAttentionBanner({super.key, required this.tabIndex});
  final int tabIndex;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendors = ref.watch(adminVendorsProvider).value ?? [];
    if (!vendors.any(
      (v) =>
          v.enabled &&
          v.latest != null &&
          v.latest!.status.value != 'ok' &&
          v.latest!.error != 'not_configured',
    )) {
      return const SizedBox.shrink();
    }
    return ListTile(
      leading: const Icon(Icons.warning_amber),
      title: Text(context.l10n.vendorNeedsAttention),
      onTap: () => DefaultTabController.of(context).animateTo(tabIndex),
    );
  }
}

class VendorsTab extends ConsumerWidget {
  const VendorsTab({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(adminVendorsProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) =>
              Center(child: Text(context.l10n.vendorCheckFailed)),
          data: (vendors) {
            final ordered = [...vendors]
              ..sort((a, b) {
                int rank(AdminVendor v) => switch (v.latest?.status.value) {
                  'out' => 0,
                  'unknown' => 1,
                  'low' => 2,
                  _ => 3,
                };
                final severity = rank(a).compareTo(rank(b));
                if (severity != 0) return severity;
                double fraction(AdminVendor v) {
                  final limit = v.latest?.limitValue ?? v.limitValue;
                  return limit != null && limit > 0
                      ? (v.latest?.used ?? 0) / limit
                      : 0;
                }

                return fraction(b).compareTo(fraction(a));
              });
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(adminVendorsProvider);
                await ref.read(adminVendorsProvider.future);
              },
              child: ListView.builder(
                itemCount: ordered.length,
                itemBuilder: (context, index) {
                  final v = ordered[index];
                  final reading = v.latest;
                  final limit = reading?.limitValue ?? v.limitValue;
                  return ListTile(
                    title: Text(v.label),
                    trailing: Chip(label: Text(vendorStatus(context, v))),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          v.kind.value == 'balance'
                              ? '${reading?.remaining ?? '–'} ${v.unit} · ${vendorStatus(context, v)}'
                              : '${reading?.used ?? '–'} / ${limit ?? '–'} ${v.unit} · ${vendorStatus(context, v)}',
                        ),
                        if (reading?.resetsAt != null)
                          Text(
                            '${context.l10n.vendorResets}: ${reading!.resetsAt}',
                          ),
                        if (reading?.used != null && limit != null && limit > 0)
                          LinearProgressIndicator(
                            value: (reading!.used! / limit)
                                .clamp(0, 1)
                                .toDouble(),
                          ),
                        if (reading != null)
                          Text(
                            '${reading.checkedAt} · ${reading.source_.value}',
                          ),
                      ],
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => VendorDetail(vendor: v),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
  }
}

class VendorDetail extends ConsumerStatefulWidget {
  const VendorDetail({super.key, required this.vendor});
  final AdminVendor vendor;
  @override
  ConsumerState<VendorDetail> createState() => _VendorDetailState();
}

class _VendorDetailState extends ConsumerState<VendorDetail> {
  late AdminVendor vendor = widget.vendor;
  late final limit = TextEditingController(
    text: vendor.limitValue?.toString() ?? '',
  );
  late final balanceWarning = TextEditingController(
    text: vendor.balanceWarnBelow.toString(),
  );
  late final warning = TextEditingController(text: vendor.warnAt.toString());
  late final start = TextEditingController(
    text: vendor.periodStart?.toIso8601String() ?? '',
  );
  late final expiry = TextEditingController(
    text: vendor.expiresAt?.toIso8601String() ?? '',
  );
  late bool enabled = vendor.enabled;
  late VendorSettingsPeriodEnum? period = vendor.period == null
      ? null
      : VendorSettingsPeriodEnum.values.firstWhere(
          (v) => v.value == vendor.period!.value,
        );
  bool busy = false;
  String? validationError;
  @override
  void dispose() {
    limit.dispose();
    balanceWarning.dispose();
    warning.dispose();
    expiry.dispose();
    start.dispose();
    super.dispose();
  }

  Future<void> act(Future<AdminVendor> Function() action) async {
    setState(() => busy = true);
    await runGuarded(context, () async {
      final result = await action();
      ref.invalidate(adminVendorsProvider);
      if (mounted) setState(() => vendor = result);
    });
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final words = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(vendor.label)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(vendorStatus(context, vendor)),
          if (vendor.impact != null) Text(vendor.impact!),
          if (vendor.billingUrl != null)
            TextButton(
              onPressed: () async {
                final uri = Uri.tryParse(vendor.billingUrl!);
                if (uri != null && uri.scheme == 'https') {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: Text(words.vendorBilling),
            ),
          SwitchListTile(
            title: Text(words.vendorEnabled),
            value: enabled,
            onChanged: busy ? null : (v) => setState(() => enabled = v),
          ),
          TextField(
            controller: limit,
            decoration: InputDecoration(labelText: words.vendorLimit),
            keyboardType: TextInputType.number,
          ),
          if (vendor.kind.value == 'balance')
            TextField(
              controller: balanceWarning,
              decoration: InputDecoration(
                labelText: words.vendorBalanceWarning,
              ),
              keyboardType: TextInputType.number,
            ),
          TextField(
            controller: warning,
            decoration: InputDecoration(labelText: words.vendorWarnAt),
            keyboardType: TextInputType.number,
          ),
          DropdownButtonFormField<VendorSettingsPeriodEnum>(
            initialValue: period,
            items: VendorSettingsPeriodEnum.values
                .map((v) => DropdownMenuItem(value: v, child: Text(v.value)))
                .toList(),
            onChanged: busy ? null : (v) => setState(() => period = v),
          ),
          TextField(
            controller: start,
            decoration: InputDecoration(labelText: words.vendorPeriodStart),
          ),
          TextField(
            controller: expiry,
            decoration: InputDecoration(labelText: words.vendorExpiry),
          ),
          if (validationError != null)
            Text(
              validationError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          FilledButton(
            onPressed: busy
                ? null
                : () => act(() async {
                    final n = limit.text.trim().isEmpty
                        ? null
                        : num.tryParse(limit.text);
                    final w = num.tryParse(warning.text);
                    final bw = num.tryParse(balanceWarning.text);
                    final st = start.text.trim().isEmpty
                        ? null
                        : DateTime.tryParse(start.text);
                    final ex = expiry.text.trim().isEmpty
                        ? null
                        : DateTime.tryParse(expiry.text);
                    if ((limit.text.trim().isNotEmpty &&
                            (n == null || !n.isFinite || n <= 0)) ||
                        w == null ||
                        !w.isFinite ||
                        w <= 0 ||
                        w > 1 ||
                        bw == null ||
                        !bw.isFinite ||
                        bw < 0 ||
                        (start.text.trim().isNotEmpty && st == null) ||
                        (expiry.text.trim().isNotEmpty && ex == null)) {
                      setState(
                        () => validationError = words.vendorInvalidSettings,
                      );
                      return vendor;
                    }
                    setState(() => validationError = null);
                    return ref
                        .read(backendProvider)
                        .setAdminVendor(
                          vendor.vendor,
                          VendorSettings(
                            limitValue: n,
                            warnAt: w,
                            enabled: enabled,
                            balanceWarnBelow: bw,
                            period: period,
                            periodStart: st?.toUtc(),
                            expiresAt: ex?.toUtc(),
                          ),
                        );
                  }),
            child: Text(words.vendorSave),
          ),
          OutlinedButton(
            onPressed: busy
                ? null
                : () => act(
                    () => ref
                        .read(backendProvider)
                        .checkAdminVendor(vendor.vendor),
                  ),
            child: Text(words.vendorCheckNow),
          ),
          Text(words.vendorHistory),
          _HistorySparkline(vendor.history),
          for (final r in vendor.history)
            ListTile(
              title: Text(
                '${r.used ?? '–'} / ${r.limitValue ?? '–'} ${vendor.unit}',
              ),
              subtitle: Text('${r.checkedAt} · ${r.status.value}'),
            ),
        ],
      ),
    );
  }
}

class _HistorySparkline extends StatelessWidget {
  const _HistorySparkline(this.history);
  final List<VendorReading> history;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 64,
    child: CustomPaint(
      painter: _SparkPainter(history, Theme.of(context).colorScheme.primary),
      size: const Size(double.infinity, 64),
    ),
  );
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.history, this.color);
  final List<VendorReading> history;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final values = history.reversed
        .map((r) => r.used ?? r.remaining)
        .whereType<num>()
        .toList();
    if (values.length < 2) return;
    final low = values.reduce((a, b) => a < b ? a : b);
    final high = values.reduce((a, b) => a > b ? a : b);
    final range = high == low ? 1 : high - low;
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = i * size.width / (values.length - 1);
      final y = size.height - 4 - (values[i] - low) / range * (size.height - 8);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_SparkPainter old) =>
      old.history != history || old.color != color;
}
