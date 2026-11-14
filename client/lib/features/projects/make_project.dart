import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/form_sheet.dart';
import 'projects_screen.dart';

/// Makes a topic a project (D-295): asks for a name (the topic's, to start with), then the topic
/// becomes the project's chat and what was made in it is filed under the project. Opens the
/// project when it's made.
Future<void> makeProjectFromTopic(
  BuildContext context,
  WidgetRef ref, {
  required String botId,
  required String conversationId,
  required String title,
}) async {
  final id = await showAdaptiveSheet<String>(
    context: context,
    builder: (_) => _MakeProject(
      botId: botId,
      conversationId: conversationId,
      title: title,
    ),
  );
  if (id == null) return;
  ref
    ..invalidate(conversationsProvider(botId))
    ..invalidate(projectsProvider);
  if (context.mounted) GoRouter.maybeOf(context)?.push('/projects/$id');
}

class _MakeProject extends ConsumerStatefulWidget {
  const _MakeProject({
    required this.botId,
    required this.conversationId,
    required this.title,
  });
  final String botId;
  final String conversationId;
  final String title;

  @override
  ConsumerState<_MakeProject> createState() => _MakeProjectState();
}

class _MakeProjectState extends ConsumerState<_MakeProject> {
  late final _name = TextEditingController(text: widget.title);
  var _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final org = ref.read(currentOrgProvider);
    final name = _name.text.trim();
    if (org == null || name.isEmpty || _busy) return;
    setState(() => _busy = true);
    final project = await runGuarded(
      context,
      () => ref
          .read(backendProvider)
          .createProject(
            org.id,
            title: name,
            leadBotId: widget.botId,
            conversationId: widget.conversationId,
          ),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (project != null) Navigator.pop(context, project.id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bot = ref.watch(botProvider(widget.botId));
    return FormSheet(
      icon: LucideIcons.folderKanban,
      title: l10n.makeProjectTitle,
      subtitle: l10n.makeProjectHelp(bot?.name ?? l10n.theBot),
      submitLabel: l10n.createProject,
      submitKey: const Key('makeProjectSubmit'),
      busy: _busy,
      onSubmit: _name.text.trim().isEmpty || _busy ? null : _submit,
      children: [
        TextField(
          key: const Key('makeProjectName'),
          controller: _name,
          autofocus: true,
          maxLength: 200,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: l10n.projectName,
            hintText: l10n.projectNameHint,
          ),
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _submit(),
        ),
      ],
    );
  }
}
