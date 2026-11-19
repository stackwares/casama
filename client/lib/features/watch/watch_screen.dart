import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/backend.dart';
import '../../core/haptics.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import '../../ui/page.dart';
import '../app_lock/app_lock.dart';
import 'watch_key_store.dart';
import 'watch_state.dart';

/// Settings → Watch (D-410, docs/WATCH-PLAN.md §6.10): the signed-in watches with Remove, signing
/// one in with the code it shows, what a watch may allow, Show details on the watch, quick replies,
/// and how to put Casama on the watch face. On every platform: a watch can be managed and signed
/// in with a code from the desktop and web apps too; only signing in through the phone needs one.
class WatchScreen extends ConsumerStatefulWidget {
  const WatchScreen({super.key});

  /// Set once the first visit checked Show details against the app lock.
  static const detailsCheckedKey = 'casama.watch.details_checked';

  @override
  ConsumerState<WatchScreen> createState() => _WatchScreenState();
}

class _WatchScreenState extends ConsumerState<WatchScreen> {
  /// The settings as last saved from here, ahead of the provider.
  WatchPrefsView? _prefs;

  /// Show details was turned off on this first visit because the app lock is on.
  var _detailsAutoOff = false;
  var _detailsChecked = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual(watchPrefsProvider, (_, next) {
      final p = next.value;
      if (p != null) unawaited(_checkDetails(p));
    }, fireImmediately: true);
  }

  /// With the app lock on, watches start private (§10): the first visit turns Show details off,
  /// once, and says why. The person can turn it back on.
  Future<void> _checkDetails(WatchPrefsView p) async {
    if (_detailsChecked) return;
    _detailsChecked = true;
    final backend = ref.read(backendProvider);
    final lockOn =
        ref.read(appLockSettingsProvider).activeFor(backend.userId) ||
        ref.read(appLockRequiredByProvider) != null;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(WatchScreen.detailsCheckedKey) == true) return;
      await prefs.setBool(WatchScreen.detailsCheckedKey, true);
      if (!lockOn || !p.showDetails) return;
      final saved = await backend.updateWatchPrefs(showDetails: false);
      if (mounted) {
        setState(() {
          _prefs = saved;
          _detailsAutoOff = true;
        });
      }
    } catch (_) {}
  }

  WatchPrefsView? get _current => _prefs ?? ref.read(watchPrefsProvider).value;

  Future<void> _update({
    WatchAllowance? allow,
    bool? showDetails,
    List<String>? quickReplies,
  }) async {
    final before = _current;
    if (before == null) return;
    // Shown at once; put back if the server says no.
    setState(() {
      _prefs = before.copyWith(
        allow: allow,
        showDetails: showDetails,
        quickReplies: quickReplies?.isEmpty == true ? null : quickReplies,
      );
      if (showDetails != null) _detailsAutoOff = false;
    });
    final saved = await runGuarded(
      context,
      () => ref
          .read(backendProvider)
          .updateWatchPrefs(
            allow: allow,
            showDetails: showDetails,
            quickReplies: quickReplies,
          ),
    );
    if (mounted) setState(() => _prefs = saved ?? before);
  }

  Future<void> _remove(WatchKeyView key) async {
    final l10n = context.l10n;
    final ok = await showConfirm(
      context: context,
      title: l10n.watchPhoneRemoveTitle(key.name),
      message: l10n.watchPhoneRemoveBody,
      confirmLabel: l10n.watchPhoneRemove,
      destructive: true,
      confirmKey: const Key('watchRemoveConfirm'),
    );
    if (!ok || !mounted) return;
    final done = await runGuarded(context, () async {
      await ref.read(backendProvider).deleteWatchKey(key.id);
      return true;
    });
    if (done == true) await WatchKeyStore.removeKey(key.id);
    if (mounted) ref.invalidate(watchKeysProvider);
  }

  Future<void> _signInWithCode() async {
    final org = ref.read(currentOrgProvider);
    if (org == null) return;
    final signedIn = await showAdaptiveSheet<WatchKeyView>(
      context: context,
      builder: (_) => WatchCodeSheet(orgId: org.id, orgName: org.name),
    );
    if (signedIn == null || !mounted) return;
    ref.invalidate(watchKeysProvider);
    showSuccess(context, context.l10n.watchPhoneSignedIn(signedIn.name));
  }

  Future<void> _editReply(List<String> replies, int? index) async {
    final text = await showAdaptiveSheet<String>(
      context: context,
      builder: (_) =>
          _QuickReplySheet(initial: index == null ? '' : replies[index]),
    );
    if (text == null || !mounted) return;
    final next = [...replies];
    if (index == null) {
      if (next.length >= WatchPrefsView.maxQuickReplies) return;
      next.add(text);
    } else {
      next[index] = text;
    }
    await _update(quickReplies: next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final keys = ref.watch(watchKeysProvider);
    final loaded = ref.watch(watchPrefsProvider);
    final prefs = _prefs ?? loaded.value;
    final hasOrg = ref.watch(currentOrgIdProvider) != null;
    return SubPage(
      title: l10n.watchPhoneTitle,
      children: [
        FormNote(l10n.watchPhoneIntro, icon: LucideIcons.watch),
        SectionHeader(title: l10n.watchPhoneWatches),
        AsyncView(
          value: keys,
          onRetry: () => ref.invalidate(watchKeysProvider),
          data: (list) => list.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.xxs),
                  child: Text(
                    l10n.watchPhoneNone,
                    key: const Key('watchNone'),
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : GroupedCard(
                  children: [
                    for (final k in list)
                      _WatchTile(watch: k, onRemove: () => _remove(k)),
                  ],
                ),
        ),
        const SizedBox(height: AppSpace.md),
        OutlinedButton.icon(
          key: const Key('watchUseCode'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
          onPressed: hasOrg ? _signInWithCode : null,
          icon: const Icon(LucideIcons.keyRound, size: 20),
          label: Text(l10n.watchPhoneUseCode),
        ),
        if (prefs != null) ...[
          SectionHeader(title: l10n.watchPhoneAllowTitle),
          RadioGroup<WatchAllowance>(
            groupValue: prefs.allow,
            onChanged: (v) {
              if (v != null && v != prefs.allow) unawaited(_update(allow: v));
            },
            child: GroupedCard(
              children: [
                for (final level in WatchAllowance.values)
                  GroupedTile(
                    key: Key('watchAllow-${level.name}'),
                    icon: switch (level) {
                      WatchAllowance.medium => LucideIcons.shieldCheck,
                      WatchAllowance.low => LucideIcons.shield,
                      WatchAllowance.none => LucideIcons.smartphone,
                    },
                    title: _allowTitle(l10n, level),
                    subtitle: _allowBody(l10n, level),
                    trailing: Radio<WatchAllowance>(value: level),
                    onTap: level == prefs.allow
                        ? null
                        : () {
                            HapticsHelper.light();
                            unawaited(_update(allow: level));
                          },
                  ),
              ],
            ),
          ),
          SectionHeader(title: l10n.appLockPrivacySection),
          GroupedCard(
            children: [
              GroupedTile(
                icon: LucideIcons.eye,
                title: l10n.watchPhoneDetails,
                subtitle: _detailsAutoOff
                    ? l10n.watchPhoneDetailsLockOff
                    : l10n.watchPhoneDetailsBody,
                trailing: Switch(
                  key: const Key('watchShowDetails'),
                  value: prefs.showDetails,
                  onChanged: hapticOnChanged(
                    (v) => unawaited(_update(showDetails: v)),
                  ),
                ),
              ),
            ],
          ),
          SectionHeader(title: l10n.watchPhoneQuickReplies),
          FormNote(
            l10n.watchPhoneQuickRepliesBody,
            icon: LucideIcons.messageSquareReply,
          ),
          const SizedBox(height: AppSpace.xs),
          _QuickReplies(
            replies: prefs.quickReplies,
            onEdit: (i) => _editReply(prefs.quickReplies, i),
            onChanged: (next) => _update(quickReplies: next),
          ),
        ],
        SectionHeader(title: l10n.watchPhoneHowTo),
        const _HowTo(),
        const SizedBox(height: AppSpace.xl),
      ],
    );
  }
}

String _allowTitle(AppLocalizations l10n, WatchAllowance level) =>
    switch (level) {
      WatchAllowance.medium => l10n.watchPhoneAllowMedium,
      WatchAllowance.low => l10n.watchPhoneAllowLow,
      WatchAllowance.none => l10n.watchPhoneAllowNone,
    };

String _allowBody(AppLocalizations l10n, WatchAllowance level) =>
    switch (level) {
      WatchAllowance.medium => l10n.watchPhoneAllowMediumBody,
      WatchAllowance.low => l10n.watchPhoneAllowLowBody,
      WatchAllowance.none => l10n.watchPhoneAllowNoneBody,
    };

class _WatchTile extends StatelessWidget {
  const _WatchTile({required this.watch, required this.onRemove});
  final WatchKeyView watch;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final used = watch.lastUsedAt;
    final when = used == null
        ? l10n.watchPhoneNeverUsed
        : l10n.watchPhoneLastUsed(relativeTime(used.toLocal(), context));
    return GroupedTile(
      key: Key('watch-${watch.id}'),
      icon: LucideIcons.watch,
      title: watch.name,
      subtitle: [?watch.model, when].join(' · '),
      trailing: TextButton(
        key: Key('removeWatch-${watch.id}'),
        onPressed: onRemove,
        child: Text(l10n.watchPhoneRemove),
      ),
    );
  }
}

/// The quick replies, each editable, movable and deletable; at least one stays, six at most.
class _QuickReplies extends StatelessWidget {
  const _QuickReplies({
    required this.replies,
    required this.onEdit,
    required this.onChanged,
  });
  final List<String> replies;
  final void Function(int? index) onEdit;
  final void Function(List<String> next) onChanged;

  void _move(int from, int to) {
    final next = [...replies];
    final item = next.removeAt(from);
    next.insert(to, item);
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final full = replies.length >= WatchPrefsView.maxQuickReplies;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (replies.isNotEmpty)
          GroupedCard(
            children: [
              for (var i = 0; i < replies.length; i++)
                GroupedTile(
                  key: Key('quickReply-$i'),
                  icon: LucideIcons.messageSquareReply,
                  title: replies[i],
                  onTap: () => onEdit(i),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        key: Key('quickReplyUp-$i'),
                        tooltip: l10n.watchPhoneQuickMoveUp,
                        icon: const Icon(LucideIcons.arrowUp, size: 18),
                        onPressed: i == 0 ? null : () => _move(i, i - 1),
                      ),
                      IconButton(
                        key: Key('quickReplyDown-$i'),
                        tooltip: l10n.watchPhoneQuickMoveDown,
                        icon: const Icon(LucideIcons.arrowDown, size: 18),
                        onPressed: i == replies.length - 1
                            ? null
                            : () => _move(i, i + 1),
                      ),
                      IconButton(
                        key: Key('quickReplyDelete-$i'),
                        tooltip: l10n.watchPhoneQuickDelete,
                        icon: const Icon(LucideIcons.trash2, size: 18),
                        // A reply notification needs at least one.
                        onPressed: replies.length <= 1
                            ? null
                            : () => onChanged([...replies]..removeAt(i)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        const SizedBox(height: AppSpace.xs),
        Wrap(
          spacing: AppSpace.xs,
          runSpacing: AppSpace.xxs,
          children: [
            TextButton.icon(
              key: const Key('quickReplyAdd'),
              onPressed: full ? null : () => onEdit(null),
              icon: const Icon(LucideIcons.plus, size: 18),
              label: Text(l10n.watchPhoneQuickAdd),
            ),
            TextButton.icon(
              key: const Key('quickReplyReset'),
              // Empty asks the server for its built-in list.
              onPressed: () => onChanged(const []),
              icon: const Icon(LucideIcons.rotateCcw, size: 18),
              label: Text(l10n.watchPhoneQuickReset),
            ),
          ],
        ),
      ],
    );
  }
}

/// One quick reply: 1 to 40 characters.
class _QuickReplySheet extends StatefulWidget {
  const _QuickReplySheet({required this.initial});
  final String initial;

  @override
  State<_QuickReplySheet> createState() => _QuickReplySheetState();
}

class _QuickReplySheetState extends State<_QuickReplySheet> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _text => _controller.text.trim();

  void _submit() {
    final text = _text;
    if (text.isEmpty) return;
    // The field stops at 40; a paste that slipped past is cut rather than refused.
    const max = WatchPrefsView.maxQuickReplyLength;
    Navigator.pop(context, text.length > max ? text.substring(0, max) : text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ValueListenableBuilder(
      valueListenable: _controller,
      builder: (context, _, _) => FormSheet(
        icon: LucideIcons.messageSquareReply,
        title: widget.initial.isEmpty
            ? l10n.watchPhoneQuickAdd
            : l10n.watchPhoneQuickReplies,
        submitLabel: l10n.save,
        submitKey: const Key('quickReplySave'),
        onSubmit: _text.isEmpty ? null : _submit,
        children: [
          TextField(
            key: const Key('quickReplyField'),
            controller: _controller,
            autofocus: true,
            maxLength: WatchPrefsView.maxQuickReplyLength,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: l10n.watchPhoneQuickHint,
              helperText: l10n.watchPhoneQuickTooLong,
            ),
          ),
        ],
      ),
    );
  }
}

/// Signing a watch in with the code it shows (§8.2): type it, see which watch is asking, allow it.
class WatchCodeSheet extends ConsumerStatefulWidget {
  const WatchCodeSheet({super.key, required this.orgId, required this.orgName});
  final String orgId;
  final String orgName;

  @override
  ConsumerState<WatchCodeSheet> createState() => _WatchCodeSheetState();
}

class _WatchCodeSheetState extends ConsumerState<WatchCodeSheet> {
  final _controller = TextEditingController();
  var _busy = false;
  String? _error;

  /// The watch showing the code, once looked up; null while the code is being typed.
  WatchCodeView? _watch;
  String? _code;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _lookUp() async {
    final l10n = context.l10n;
    final code = normalizeWatchCode(_controller.text);
    if (code == null) {
      setState(() => _error = l10n.watchPhoneCodeWrong);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final found = await runGuarded(
      context,
      () => ref.read(backendProvider).watchCodeInfo(code),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _watch = found;
      _code = found == null ? null : code;
      if (found == null) _error = l10n.watchPhoneCodeWrong;
    });
  }

  Future<void> _allow() async {
    final code = _code;
    if (code == null) return;
    setState(() => _busy = true);
    final key = await runGuarded(
      context,
      () => ref.read(backendProvider).claimWatchCode(code, widget.orgId),
    );
    if (!mounted) return;
    if (key == null) {
      // Expired, used, or too many tries: start again with a new code from the watch.
      setState(() {
        _busy = false;
        _watch = null;
        _code = null;
        _error = context.l10n.watchPhoneCodeWrong;
      });
      return;
    }
    HapticsHelper.success();
    Navigator.pop(context, key);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final watch = _watch;
    if (watch != null) {
      return FormSheet(
        key: const Key('watchCodeConfirm'),
        icon: LucideIcons.watch,
        title: l10n.watchPhoneCodeAsk(watch.name),
        subtitle: [
          ?watch.model,
          l10n.watchPhoneCodeAskBody(widget.orgName),
        ].join('\n'),
        submitLabel: l10n.watchPhoneCodeAllow,
        submitKey: const Key('watchCodeAllow'),
        busy: _busy,
        onSubmit: _allow,
        children: const [],
      );
    }
    return FormSheet(
      icon: LucideIcons.keyRound,
      title: l10n.watchPhoneUseCode,
      subtitle: l10n.watchPhoneCodeBody,
      submitLabel: l10n.next,
      submitKey: const Key('watchCodeNext'),
      busy: _busy,
      onSubmit: _lookUp,
      children: [
        TextField(
          key: const Key('watchCodeField'),
          controller: _controller,
          autofocus: true,
          autocorrect: false,
          enableSuggestions: false,
          textCapitalization: TextCapitalization.characters,
          // "KQ7M 2XAB", "kq7m-2xab": spaces and dashes are fine.
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Za-z \-]')),
            LengthLimitingTextInputFormatter(12),
          ],
          textInputAction: TextInputAction.go,
          onSubmitted: (_) => _lookUp(),
          style: const TextStyle(
            fontFeatures: AppText.tabular,
            letterSpacing: 2,
          ),
          decoration: InputDecoration(
            labelText: l10n.watchPhoneCodeHint,
            hintText: 'KQ7M 2XAB',
            errorText: _error,
          ),
        ),
      ],
    );
  }
}

/// How to put Casama on the watch face: Apple's way on iPhone, Wear OS's on Android, both
/// elsewhere (a person with a Mac or the web app may have either).
class _HowTo extends StatelessWidget {
  const _HowTo();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final platform = kIsWeb ? null : defaultTargetPlatform;
    final style = context.textTheme.bodyMedium;
    if (platform == TargetPlatform.iOS) {
      return Text(
        l10n.watchPhoneHowToApple,
        key: const Key('watchHowToApple'),
        style: style,
      );
    }
    if (platform == TargetPlatform.android) {
      return Text(
        l10n.watchPhoneHowToWear,
        key: const Key('watchHowToWear'),
        style: style,
      );
    }
    final heading = context.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w700,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpace.xxs,
      children: [
        Text(l10n.watchPhoneAppleWatch, style: heading),
        Text(
          l10n.watchPhoneHowToApple,
          key: const Key('watchHowToApple'),
          style: style,
        ),
        const SizedBox(height: AppSpace.xs),
        Text(l10n.watchPhoneWearOs, style: heading),
        Text(
          l10n.watchPhoneHowToWear,
          key: const Key('watchHowToWear'),
          style: style,
        ),
      ],
    );
  }
}
