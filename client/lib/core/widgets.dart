import 'package:dio/dio.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../l10n/generated/app_localizations.dart';
import '../ui/bottom_padding.dart';
import '../ui/mascot.dart';
import '../ui/skeleton.dart';
import '../ui/toast.dart';

export '../ui/toast.dart' show ToastKind;
export '../ui/skeleton.dart';
import 'date_format.dart';
import 'haptics.dart';
import 'analytics.dart';
import 'telemetry.dart';
import '../ui/effects.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Supabase Auth's messages are for developers ("Invalid login credentials", "For security
/// purposes, you can only request this after 49 seconds"): the common ones, said plainly.
String _authErrorText(BuildContext context, sb.AuthException e) {
  final l10n = context.l10n;
  switch (e.code) {
    case 'invalid_credentials':
      return l10n.authWrongPassword;
    case 'email_not_confirmed':
      return l10n.authEmailNotConfirmed;
    case 'otp_expired':
      return l10n.authCodeInvalid;
    case 'over_email_send_rate_limit' || 'over_request_rate_limit':
      return l10n.authTooManyTries;
    case 'user_already_exists' || 'email_exists':
      return l10n.authAccountExists;
    case 'signup_disabled':
      return l10n.authSignupDisabled;
  }
  if (e.statusCode == '429') return l10n.authTooManyTries;
  if (e is sb.AuthRetryableFetchException) return l10n.connectionFailed;
  return e.message;
}

/// A readable message for an error from the API, Supabase or the network.
String errorText(BuildContext context, Object error) {
  if (error is sb.AuthException) return _authErrorText(context, error);
  if (error is sb.PostgrestException && error.code == 'PT402') return error.message;
  final problem = problemOf(error);
  if (problem != null) return problem.detail ?? problem.title;
  if (error is DioException) {
    // No answer at all (offline, server restarting, blocked): the library's text is for developers
    // (a browser even reports it as a CORS problem), so say it plainly.
    final noAnswer =
        error.response == null &&
        const {
          DioExceptionType.connectionError,
          DioExceptionType.connectionTimeout,
          DioExceptionType.sendTimeout,
          DioExceptionType.receiveTimeout,
          DioExceptionType.unknown,
        }.contains(error.type);
    if (noAnswer) return context.l10n.connectionFailed;
    // An answer without Casama's error body came from something in between (a proxy or tunnel
    // while the server restarts) or an unexpected crash; Dio's own text is for developers.
    final status = error.response?.statusCode ?? 0;
    if (status >= 500) return context.l10n.serverNotResponding;
    return context.l10n.somethingWentWrong;
  }
  final s = error.toString();
  final m = RegExp(r'message: ([^,)]+)').firstMatch(s);
  return m?.group(1) ?? s.replaceFirst('Exception: ', '');
}

void showError(BuildContext context, Object error, [StackTrace? stackTrace]) {
  HapticsHelper.error();
  _reportShown(error);
  final message = errorText(context, error);
  showToast(context, message, kind: ToastKind.error, copyText: _errorCopyText(message, error));

  // Filter out expected user/network issues:
  // DioException with 4xx or offline network connection timeouts
  var isExpected = false;
  if (error is DioException) {
    final status = error.response?.statusCode;
    if (status != null && status >= 400 && status < 500) {
      isExpected = true;
    } else if (error.response == null) {
      isExpected = true;
    }
  } else if (error is sb.AuthException) {
    isExpected = true;
  }

  if (!isExpected) {
    Telemetry.captureException(error, stackTrace ?? StackTrace.current, warning: true);
  }
}

/// The usage-data side of an error the person saw (the `app_error_shown` event).
void _reportShown(Object error) {
  if (error is DioException) {
    final status = error.response?.statusCode;
    final kind = status == null
        ? 'network'
        : status == 401 || status == 403
            ? 'auth'
            : status == 400 || status == 422
                ? 'validation'
                : status >= 500
                    ? 'server'
                    : 'unknown';
    Analytics.errorShown(code: problemOf(error)?.code, status: status, kind: kind);
  } else if (error is sb.AuthException) {
    Analytics.errorShown(code: error.code, status: null, kind: 'auth');
  } else {
    Analytics.errorShown(kind: 'unknown');
  }
}

/// The text an error message's Copy button copies: what the person saw, then the technical detail
/// behind it (problem code, HTTP status, request path, the raw error) for a bug report.
String _errorCopyText(String message, Object error) {
  final lines = <String>[message];
  if (error is DioException) {
    final problem = problemOf(error);
    if (problem != null) {
      lines.add('Code: ${problem.code}');
      if (problem.detail != null && problem.detail != message) lines.add('Detail: ${problem.detail}');
    }
    final status = error.response?.statusCode;
    if (status != null) lines.add('HTTP $status');
    // The path only: query strings can carry tokens.
    lines.add('${error.requestOptions.method} ${error.requestOptions.uri.path}');
    if (problem == null && error.message != null && error.message != message) lines.add(error.message!);
  } else if (error is sb.AuthException) {
    lines.add([if (error.code != null) 'Code: ${error.code}', if (error.statusCode != null) 'HTTP ${error.statusCode}', error.message].join(' · '));
  } else {
    final raw = error.toString();
    if (raw != message && raw.replaceFirst('Exception: ', '') != message) lines.add(raw);
  }
  return lines.join('\n');
}

/// A floating message of [kind] (see [ToastKind]): the shared look for every snackbar in the app.
/// [copyText] adds a Copy button; [action] a trailing button such as Undo.
void showToast(
  BuildContext context,
  String message, {
  ToastKind kind = ToastKind.info,
  String? copyText,
  SnackBarAction? action,
  Duration? duration,
  bool replace = false,
}) {
  final messenger = ScaffoldMessenger.of(context);
  if (replace) messenger.hideCurrentSnackBar();
  messenger.showSnackBar(toastSnackBar(context, message, kind: kind, copyText: copyText, action: action, duration: duration));
}

void showMessage(BuildContext context, String message) {
  showToast(context, message);
}

/// [showMessage] for something that just worked (saved, sent, imported), with a success haptic.
void showSuccess(BuildContext context, String message) {
  HapticsHelper.success();
  showToast(context, message, kind: ToastKind.success);
}

/// [showMessage] for something the person has to fix or can't do here (an invalid email, a file
/// too large, a missing permission), with a warning haptic.
void showWarning(BuildContext context, String message) {
  HapticsHelper.warning();
  showToast(context, message, kind: ToastKind.warning);
}

/// [showMessage] for a failure that already has its own words (an upload that didn't go through),
/// with an error haptic. For an error object, use [showError].
void showFailure(BuildContext context, String message) {
  HapticsHelper.error();
  showToast(context, message, kind: ToastKind.error, copyText: message);
}

/// Renders an AsyncValue with loading, error (with retry) and data states. Moving between them
/// fades through (the skeleton fades out, then the list fades in) rather than cutting; new data in
/// the same state just rebuilds.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({
    super.key,
    required this.value,
    required this.data,
    this.onRetry,
    this.loading,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;

  /// Shown while [value] is loading. A list of rows, unless the screen has another shape.
  final Widget? loading;

  static const _switchIn = Interval(0.3, 1, curve: Curves.easeOut);
  static const _switchOut = Interval(0.6, 1);

  @override
  Widget build(BuildContext context) {
    final (state, child) = value.when(
      data: (v) => ('data', data(v)),
      loading: () => ('loading', loading ?? const SkeletonList()),
      error: (e, _) => ('error', _error(context, e)),
    );
    return AnimatedSwitcher(
      duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 220),
      switchInCurve: _switchIn,
      switchOutCurve: _switchOut,
      // Each state is laid out and painted exactly as it would be on its own.
      layoutBuilder: (current, previous) => Stack(
        fit: StackFit.passthrough,
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [...previous, ?current],
      ),
      child: KeyedSubtree(key: ValueKey(state), child: child),
    );
  }

  Widget _error(BuildContext context, Object e) => EmptyState(
        icon: LucideIcons.cloudOff,
        title: context.l10n.somethingWentWrong,
        message: errorText(context, e),
        isError: true,
        action: onRetry == null
            ? null
            : FilledButton.tonalIcon(
                onPressed: onRetry,
                icon: const Icon(LucideIcons.rotateCw, size: 18),
                label: Text(context.l10n.retry),
              ),
      );
}

/// A one-line load failure with a retry, for lists inside sheets and forms where a full [AsyncView] would not fit.
class InlineError extends StatelessWidget {
  const InlineError({super.key, required this.error, this.onRetry});
  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(LucideIcons.cloudOff, size: 16, color: scheme.error),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            errorText(context, error),
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: scheme.error, height: 1.35),
          ),
        ),
        if (onRetry != null)
          TextButton(onPressed: onRetry, child: Text(context.l10n.retry)),
      ],
    );
  }
}

/// Centered empty or error state: a cloud bot holding the icon as a badge (or an [illustration]),
/// a title, a muted line and an action. The bot's mood follows the icon: dozing when there's
/// nothing yet, thinking when a search or filter finds nothing, shy on an error, starry when
/// everything is done.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    this.icon,
    this.illustration,
    required this.message,
    this.title,
    this.action,
    this.isError = false,
    this.mascot,
  }) : assert(icon != null || illustration != null);
  final IconData? icon;

  /// The bot to show, instead of the one picked from [icon] and [isError].
  final Mascot? mascot;

  static final _done = {LucideIcons.circleCheck, LucideIcons.circleCheckBig};
  static final _noMatch = {LucideIcons.searchX, LucideIcons.funnelX, LucideIcons.listFilter};
  static final _trouble = {
    LucideIcons.triangleAlert,
    LucideIcons.circleAlert,
    LucideIcons.cloudOff,
    LucideIcons.phoneOff,
    LucideIcons.unplug,
    LucideIcons.monitorOff,
    LucideIcons.lock,
  };

  /// The bot for this state.
  static Mascot moodFor(IconData? icon, {bool isError = false}) {
    if (isError || _trouble.contains(icon)) return Mascot.shy;
    if (_done.contains(icon)) return Mascot.starry;
    if (_noMatch.contains(icon)) return Mascot.thinker;
    // Nothing here yet, or a computer that's asleep.
    return Mascot.sleepy;
  }

  /// Shown instead of the icon circle (the animated blank bot on "no bots yet").
  final Widget? illustration;

  /// Bold line above [message]; when null, [message] is shown as the title.
  final String? title;
  final String message;
  final Widget? action;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final accent = isError ? scheme.error : scheme.primary;
    return Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              32,
              24,
              32,
              BottomPadding.of(context, minimum: 24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                illustration ??
                    _BotWithBadge(
                      mascot: mascot ?? moodFor(icon, isError: isError),
                      icon: icon!,
                      accent: accent,
                    ),
                const SizedBox(height: 12),
                Text(
                  title ?? message,
                  textAlign: TextAlign.center,
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                if (title != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: text.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
                if (action != null) ...[const SizedBox(height: 24), action!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A cloud bot with the state's icon in a small badge at its side.
class _BotWithBadge extends StatelessWidget {
  const _BotWithBadge({required this.mascot, required this.icon, required this.accent});
  final Mascot mascot;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 132,
      height: 112,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // A soft halo, so the bot reads on any wallpaper.
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [accent.withValues(alpha: 0.16), accent.withValues(alpha: 0)]),
            ),
          ),
          MascotImage(mascot, size: 104, animate: Effects.decorative(context)),
          PositionedDirectional(
            end: 8,
            bottom: 4,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Color.alphaBlend(accent.withValues(alpha: 0.14), scheme.surface),
                shape: BoxShape.circle,
                border: Border.all(color: scheme.surface, width: 3),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Icon(icon, size: 18, color: accent),
            ),
          ),
        ],
      ),
    );
  }
}

/// Runs an async action with a progress state and error snackbar.
/// Called instead of the error snackbar when the server answers 402 Payment Required (plan limit or
/// out of credits, Casama Cloud only). The app sets it to the paywall at startup.
Future<void> Function(BuildContext context, String message)? onPaymentRequired;

/// Called instead of [onPaymentRequired] when the 402 is `out_of_credits`: a paying workspace is
/// offered credit packs rather than other plans (D-248). Set by the app at startup.
Future<void> Function(BuildContext context)? onOutOfCredits;

Future<T?> runGuarded<T>(
  BuildContext context,
  Future<T> Function() action,
) async {
  try {
    return await action();
  } catch (e, st) {
    if (!context.mounted) return null;
    final paywall = onPaymentRequired;
    // A 402 from the server, or a plan limit the database enforces (SQLSTATE PT402, such as
    // unarchiving a bot past the plan's bot limit).
    final paymentRequired =
        (e is DioException && e.response?.statusCode == 402) ||
        (e is sb.PostgrestException && e.code == 'PT402');
    final outOfCredits = onOutOfCredits;
    final code = e is DioException ? e.response?.data : null;
    if (outOfCredits != null && paymentRequired && code is Map && code['code'] == 'out_of_credits') {
      await outOfCredits(context);
    } else if (paywall != null && paymentRequired) {
      await paywall(context, errorText(context, e));
    } else {
      showError(context, e, st);
    }
    return null;
  }
}

/// Short relative time ("5 minutes ago"); older than a week shows the date.
String relativeTime(DateTime t, BuildContext context) {
  final d = DateTime.now().difference(t.toLocal());
  final l10n = AppLocalizations.of(context);
  if (d.inSeconds < 60) return l10n.justNow;
  if (d.inMinutes < 60) return l10n.minutesAgo(d.inMinutes);
  if (d.inHours < 24) return l10n.hoursAgo(d.inHours);
  if (d.inDays < 7) return l10n.daysAgo(d.inDays);
  return t.toLocal().formattedDate(context);
}

/// [relativeTime] as text, with the exact date and time on hover or long press.
class TimeAgo extends StatelessWidget {
  const TimeAgo(this.at, {super.key, this.style, this.label});

  final DateTime at;
  final TextStyle? style;

  /// Puts the relative time in a sentence, e.g. l10n.skillLastFailure ("Last problem: 2 days ago").
  final String Function(String when)? label;

  @override
  Widget build(BuildContext context) {
    final when = relativeTime(at, context);
    return Tooltip(message: at.toLocal().formattedExact(context), child: Text(label?.call(when) ?? when, style: style));
  }
}
