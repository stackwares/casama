import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import 'for_you.dart' show forYouProvider;

/// "Do it" on a suggestion's notification (D-247): accepts it and opens the chat where the bot
/// does it. A suggestion that's already handled (or anything else going wrong) lands in the inbox,
/// where For you shows what's left.
class AcceptSuggestionScreen extends ConsumerStatefulWidget {
  const AcceptSuggestionScreen({super.key, required this.suggestionId, this.botId});

  final String suggestionId;
  final String? botId;

  @override
  ConsumerState<AcceptSuggestionScreen> createState() => _AcceptSuggestionScreenState();
}

class _AcceptSuggestionScreenState extends ConsumerState<AcceptSuggestionScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(_accept());
  }

  Future<void> _accept() async {
    String target = '/inbox';
    try {
      final r = await ref.read(backendProvider).acceptSuggestion(widget.suggestionId);
      final bot = widget.botId;
      if (bot != null && bot.isNotEmpty) target = '/bots/$bot/chat?c=${r.conversationId}';
    } catch (_) {
      // Already accepted or dismissed, or offline: the inbox has the rest.
    }
    ref.invalidate(forYouProvider);
    if (mounted) context.go(target);
  }

  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: CircularProgressIndicator()));
}
