import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../l10n/generated/app_localizations.dart';
import '../ui/bottom_padding.dart';
import '../ui/mascot.dart';
import '../ui/skeleton.dart';

export '../ui/skeleton.dart';
import 'date_format.dart';
import 'haptics.dart';
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
    return error.message ?? context.l10n.somethingWentWrong;
  }
  final s = error.toString();
  final m = RegExp(r'message: ([^,)]+)').firstMatch(s);
  return m?.group(1) ?? s.replaceFirst('Exception: ', '');
}

void showError(BuildContext context, Object error, [StackTrace? stackTrace]) {
  HapticsHelper.error();
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(errorText(context, error))));

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

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

/// [showMessage] for something that just worked (saved, sent, imported), with a success haptic.
void showSuccess(BuildContext context, String message) {
  HapticsHelper.success();
  showMessage(context, message);
}

/// [showMessage] for something the person has to fix or can't do here (an invalid email, a file
/// too large, a missing permission), with a warning haptic.
void showWarning(BuildContext context, String message) {
  HapticsHelper.warning();
  showMessage(context, message);
}

/// [showMessage] for a failure that already has its own words (an upload that didn't go through),
/// with an error haptic. For an error object, use [showError].
void showFailure(BuildContext context, String message) {
  HapticsHelper.error();
  showMessage(context, message);
}

/// Renders an AsyncValue with loading, error (with retry) and data states.
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

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      loading: () => loading ?? const SkeletonList(),
      error: (e, _) => EmptyState(
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
      ),
    );
  }
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

Future<T?> runGuarded<T>(
  BuildContext context,
  Future<T> Function() action,
) async {
  try {
    return await action();
  } catch (e, st) {
    if (!context.mounted) return null;
    final paywall = onPaymentRequired;
    if (paywall != null && e is DioException && e.response?.statusCode == 402) {
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
