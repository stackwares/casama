import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kasama_sdk/kasama_sdk.dart';

import '../l10n/generated/app_localizations.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// A readable message for an error from the API, Supabase or the network.
String errorText(BuildContext context, Object error) {
  final problem = problemOf(error);
  if (problem != null) return problem.detail ?? problem.title;
  if (error is DioException) return error.message ?? context.l10n.somethingWentWrong;
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
      loading: () => Center(child: Semantics(label: context.l10n.loading, child: const CircularProgressIndicator())),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(errorText(context, e), textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onRetry, child: Text(context.l10n.retry)),
            ],
          ]),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.message, this.action});
  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 40, color: theme.colorScheme.outline),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ]),
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
