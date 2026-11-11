import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kasama_sdk/kasama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../l10n/generated/app_localizations.dart';

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
    final noAnswer = error.response == null &&
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

void showError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorText(context, error))));
}

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

/// Renders an AsyncValue with loading, error (with retry) and data states.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({super.key, required this.value, required this.data, this.onRetry});

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      loading: () => Center(
        child: Semantics(
          label: context.l10n.loading,
          child: const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5, strokeCap: StrokeCap.round)),
        ),
      ),
      error: (e, _) => EmptyState(
        icon: LucideIcons.cloudOff,
        title: context.l10n.somethingWentWrong,
        message: errorText(context, e),
        isError: true,
        action: onRetry == null
            ? null
            : FilledButton.tonalIcon(onPressed: onRetry, icon: const Icon(LucideIcons.rotateCw, size: 18), label: Text(context.l10n.retry)),
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
          child: Text(errorText(context, error), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.error, height: 1.35)),
        ),
        if (onRetry != null) TextButton(onPressed: onRetry, child: Text(context.l10n.retry)),
      ],
    );
  }
}

/// Centered empty or error state: a soft circle with the icon, a title, a muted line and an action.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.message, this.title, this.action, this.isError = false});
  final IconData icon;

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
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), shape: BoxShape.circle),
                  child: Icon(icon, size: 32, color: accent),
                ),
                const SizedBox(height: 20),
                Text(
                  title ?? message,
                  textAlign: TextAlign.center,
                  style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.2),
                ),
                if (title != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant, height: 1.4),
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

/// Runs an async action with a progress state and error snackbar.
/// Called instead of the error snackbar when the server answers 402 Payment Required (plan limit or
/// out of credits, Kasama Cloud only). The app sets it to the paywall at startup.
Future<void> Function(BuildContext context, String message)? onPaymentRequired;

Future<T?> runGuarded<T>(BuildContext context, Future<T> Function() action) async {
  try {
    return await action();
  } catch (e) {
    if (!context.mounted) return null;
    final paywall = onPaymentRequired;
    if (paywall != null && e is DioException && e.response?.statusCode == 402) {
      await paywall(context, errorText(context, e));
    } else {
      showError(context, e);
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
  return MaterialLocalizations.of(context).formatShortDate(t.toLocal());
}
