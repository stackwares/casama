// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Kasama';

  @override
  String get loading => 'Loading…';

  @override
  String get retry => 'Try again';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get close => 'Close';

  @override
  String get create => 'Create';

  @override
  String get continueLabel => 'Continue';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get signInTitle => 'Sign in to Kasama';

  @override
  String get signUpTitle => 'Create your account';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get signIn => 'Sign in';

  @override
  String get signUp => 'Create account';

  @override
  String get haveAccount => 'Have an account? Sign in';

  @override
  String get needAccount => 'New here? Create an account';

  @override
  String get magicLink => 'Email me a sign-in link';

  @override
  String get magicLinkSent => 'Check your email for a sign-in link.';

  @override
  String get confirmEmailSent =>
      'Check your email to confirm your account, then sign in.';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get invalidEmail => 'Enter a valid email address';

  @override
  String get passwordTooShort => 'Use at least 6 characters';

  @override
  String get signOut => 'Sign out';

  @override
  String get onboardingTitle => 'Set up your workspace';

  @override
  String get createWorkspace => 'Create a workspace';

  @override
  String get workspaceName => 'Workspace name';

  @override
  String get joinWorkspace => 'Join with an invite code';

  @override
  String get inviteCode => 'Invite code';

  @override
  String get join => 'Join';

  @override
  String get addModelKeyTitle => 'Add a model key';

  @override
  String get addModelKeyBody =>
      'Bots use your own model provider key. It is stored encrypted and never shown again.';

  @override
  String get provider => 'Provider';

  @override
  String get label => 'Label';

  @override
  String get apiKey => 'API key';

  @override
  String get baseUrl => 'Base URL';

  @override
  String get testKey => 'Test key';

  @override
  String keyOk(String model, int ms) {
    return 'Key works ($model, $ms ms)';
  }

  @override
  String keyFailed(String error) {
    return 'Key test failed: $error';
  }

  @override
  String get createFirstBot => 'Create your first bot';

  @override
  String get botName => 'Bot name';

  @override
  String get model => 'Model';

  @override
  String get persona => 'Persona';

  @override
  String get personaHint => 'How should this bot behave? (optional)';

  @override
  String get modelKey => 'Model key';

  @override
  String get navBots => 'Bots';

  @override
  String get navComputer => 'Computer';

  @override
  String get navSettings => 'Settings';

  @override
  String get bots => 'Bots';

  @override
  String get newBot => 'New bot';

  @override
  String get noBots => 'No bots yet. Create one to start.';

  @override
  String get botStatusIdle => 'Idle';

  @override
  String get botStatusWorking => 'Working';

  @override
  String get botStatusWaiting => 'Waiting for you';

  @override
  String get botStatusDisabled => 'Disabled';

  @override
  String costToday(String cost) {
    return '$cost today';
  }

  @override
  String lastActive(String when) {
    return 'Active $when';
  }

  @override
  String get selectBot => 'Select a bot to chat';

  @override
  String get newChat => 'New chat';

  @override
  String get conversations => 'Conversations';

  @override
  String messageHint(String bot) {
    return 'Message $bot';
  }

  @override
  String get send => 'Send';

  @override
  String get stop => 'Stop';

  @override
  String get thinking => 'Thinking…';

  @override
  String runFailed(String message) {
    return 'The run failed: $message';
  }

  @override
  String get runCancelled => 'Stopped.';

  @override
  String emptyChat(String bot) {
    return 'Say hello to $bot.';
  }

  @override
  String get toolRunning => 'Running';

  @override
  String toolDone(int ms) {
    return 'Done in $ms ms';
  }

  @override
  String get toolFailedLabel => 'Failed';

  @override
  String get toolOutput => 'Output';

  @override
  String get remembered => 'Remembered something';

  @override
  String skillLoaded(String name) {
    return 'Loaded skill $name';
  }

  @override
  String checkpointSaved(String label) {
    return 'Saved checkpoint: $label';
  }

  @override
  String computerState(String state) {
    return 'Computer $state';
  }

  @override
  String runCost(String cost, int tokens) {
    return '$cost · $tokens tokens';
  }

  @override
  String get activity => 'Activity';

  @override
  String get timelineTitle => 'Run timeline';

  @override
  String get allEvents => 'All';

  @override
  String get filterTools => 'Tools';

  @override
  String get filterMessages => 'Messages';

  @override
  String get filterSystem => 'System';

  @override
  String get restore => 'Restore';

  @override
  String get restoreConfirm =>
      'Restore this checkpoint? Files changed since then will be replaced.';

  @override
  String get restored => 'Checkpoint restored.';

  @override
  String get noRuns => 'No runs yet.';

  @override
  String get computerTitle => 'Computer';

  @override
  String get computerStart => 'Start';

  @override
  String get computerSleep => 'Sleep';

  @override
  String get screen => 'Screen';

  @override
  String get terminal => 'Terminal';

  @override
  String get files => 'Files';

  @override
  String get checkpoints => 'Checkpoints';

  @override
  String get noScreen =>
      'Nothing on screen yet. The bot\'s browser page appears here.';

  @override
  String get refresh => 'Refresh';

  @override
  String get upload => 'Upload';

  @override
  String get download => 'Download';

  @override
  String get emptyFolder => 'This folder is empty.';

  @override
  String get noCheckpoints =>
      'No checkpoints yet. They are saved before risky changes.';

  @override
  String get computerAsleep =>
      'The computer is asleep. Its files are saved and it wakes up when needed.';

  @override
  String get connectTerminal => 'Connect';

  @override
  String get terminalDisconnected => 'Disconnected.';

  @override
  String get memory => 'Memory';

  @override
  String get noMemories => 'Nothing remembered yet.';

  @override
  String get pin => 'Pin';

  @override
  String get unpin => 'Unpin';

  @override
  String get deleteMemoryConfirm => 'Forget this? It cannot be undone.';

  @override
  String get skills => 'Skills';

  @override
  String get noSkills =>
      'No skills yet. Skills are instructions bots load when relevant.';

  @override
  String get newSkill => 'New skill';

  @override
  String get skillName => 'Name (lowercase, dashes)';

  @override
  String get skillDescription => 'One-line description';

  @override
  String get skillBody => 'Instructions (Markdown)';

  @override
  String get enabled => 'Enabled';

  @override
  String get settings => 'Settings';

  @override
  String get workspace => 'Workspace';

  @override
  String get switchWorkspace => 'Switch workspace';

  @override
  String get modelKeys => 'Model keys';

  @override
  String get noKeys => 'No model keys yet.';

  @override
  String get addKey => 'Add key';

  @override
  String get usage => 'Usage';

  @override
  String usageMonth(String cost) {
    return 'This month: $cost';
  }

  @override
  String get language => 'Language';

  @override
  String signedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String get inviteMember => 'Invite a member';

  @override
  String inviteSent(String email) {
    return 'Invite sent to $email.';
  }

  @override
  String inviteCodeToShare(String code) {
    return 'Share this invite code: $code';
  }

  @override
  String get botSettings => 'Bot settings';

  @override
  String get autonomy => 'Autonomy';

  @override
  String get autonomyAskAlways => 'Ask before acting';

  @override
  String get autonomyAskRisky => 'Ask for risky actions';

  @override
  String get autonomyAutonomous => 'Act on its own';

  @override
  String get saved => 'Saved.';

  @override
  String get justNow => 'just now';

  @override
  String minutesAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String hoursAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n days ago',
      one: 'yesterday',
    );
    return '$_temp0';
  }

  @override
  String get aBot => 'A bot';

  @override
  String get addIntegration => 'Add integration';

  @override
  String get addSecret => 'Add secret';

  @override
  String get allowedHosts => 'Allowed hosts';

  @override
  String get allowedHostsHelp => 'Comma-separated, for example api.github.com';

  @override
  String get alwaysAllow => 'Always allow';

  @override
  String get approval => 'Approval';

  @override
  String get approvalAlreadyDecided =>
      'This request was already decided or has expired.';

  @override
  String get approvals => 'Approvals';

  @override
  String get approve => 'Approve';

  @override
  String get approved => 'Approved';

  @override
  String get authHeaderOptional => 'Authorization header (optional)';

  @override
  String get authSecretName => 'Auth secret name (optional)';

  @override
  String get authSecretNameHelp =>
      'Name of a secret from Settings › Secrets, sent as a bearer token';

  @override
  String get baseUrlOptional => 'Base URL (optional)';

  @override
  String get blankBot => 'Blank';

  @override
  String get botIntegrations => 'Integrations for this bot';

  @override
  String get changeStatus => 'Change status';

  @override
  String get composioToolkits =>
      'Toolkits (comma-separated, for example github, gmail)';

  @override
  String get copySecret => 'Copy secret';

  @override
  String get cronExpression => 'Cron expression';

  @override
  String get cronHelp => 'minute hour day month weekday';

  @override
  String get denied => 'Denied';

  @override
  String get deny => 'Deny';

  @override
  String get everyDayAt7 => 'Every day at 7:00';

  @override
  String get everyHour => 'Every hour';

  @override
  String get expired => 'Expired';

  @override
  String get inbox => 'Inbox';

  @override
  String get integrationName => 'Name';

  @override
  String get integrationNameHelp =>
      'Lowercase letters, numbers and underscores';

  @override
  String get integrationType => 'Type';

  @override
  String get integrations => 'Integrations';

  @override
  String get kindMcp => 'MCP server';

  @override
  String get kindOpenapi => 'OpenAPI';

  @override
  String get markAllRead => 'Mark all as read';

  @override
  String get mondaysAt9 => 'Mondays at 9:00';

  @override
  String get newRoutine => 'New routine';

  @override
  String get noApprovals => 'Nothing needs your approval right now.';

  @override
  String get noIntegrations =>
      'No integrations yet. Connect an MCP server, an OpenAPI source, Composio or Pipedream.';

  @override
  String get noIntegrationsForBot => 'Add integrations in Settings first.';

  @override
  String get noNotifications => 'No notifications yet.';

  @override
  String get noRoutines =>
      'No routines yet. Routines run this bot on a schedule or when a webhook arrives.';

  @override
  String get noSecrets =>
      'No secrets yet. Bots reference them by name, and each one only goes to the hosts you allow.';

  @override
  String get noTasks => 'The task board is empty.';

  @override
  String get notifications => 'Notifications';

  @override
  String get openInbox => 'Open inbox';

  @override
  String get pipedreamApps => 'Apps (comma-separated)';

  @override
  String get pipedreamClientId => 'Client ID';

  @override
  String get pipedreamClientSecret => 'Client secret';

  @override
  String get pipedreamProject => 'Project ID';

  @override
  String get riskHigh => 'High risk';

  @override
  String get riskLow => 'Low risk';

  @override
  String get riskMedium => 'Medium risk';

  @override
  String get routineGithub => 'On GitHub events';

  @override
  String get routineInstructions => 'Instructions';

  @override
  String get routineInstructionsHint => 'What should the bot do each time?';

  @override
  String get routineName => 'Name';

  @override
  String get routineStarted => 'Routine started';

  @override
  String get routineWebhook => 'On webhook';

  @override
  String get routines => 'Routines';

  @override
  String get runNow => 'Run now';

  @override
  String get secretName => 'Name';

  @override
  String get secretNameHelp => 'Uppercase, for example GITHUB_TOKEN';

  @override
  String get secretValue => 'Value';

  @override
  String get secrets => 'Secrets';

  @override
  String get serverUrl => 'Server URL';

  @override
  String get specUrl => 'OpenAPI spec URL';

  @override
  String get startFrom => 'Start from';

  @override
  String get storedEncrypted => 'Stored encrypted; never shown again';

  @override
  String get taskBlocked => 'Blocked';

  @override
  String get taskBoard => 'Tasks';

  @override
  String get taskDoing => 'In progress';

  @override
  String get taskDone => 'Done';

  @override
  String get taskTodo => 'To do';

  @override
  String get test => 'Test';

  @override
  String get timezone => 'Timezone';

  @override
  String get triggerGithub => 'GitHub';

  @override
  String get triggerSchedule => 'Schedule';

  @override
  String get triggerWebhook => 'Webhook';

  @override
  String get viewRun => 'View run';

  @override
  String get webhookCreated => 'Webhook created';

  @override
  String get webhookSecret => 'Signing secret';

  @override
  String get webhookShownOnce =>
      'Copy the signing secret now. It is shown only once.';

  @override
  String get webhookUrl => 'URL';

  @override
  String approvalsCount(int n) {
    return 'Approvals ($n)';
  }

  @override
  String botWantsTo(String bot, String summary) {
    return '$bot: $summary';
  }

  @override
  String integrationFailed(String error) {
    return 'Connection failed: $error';
  }

  @override
  String integrationOk(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Connected, $n tools',
      one: 'Connected, 1 tool',
    );
    return '$_temp0';
  }

  @override
  String needsApprovalFor(String bot, String tool) {
    return '$bot needs your approval to use $tool';
  }

  @override
  String nextRun(String when) {
    return 'Next: $when';
  }

  @override
  String onlySentTo(String hosts) {
    return 'Only sent to $hosts';
  }

  @override
  String requestedAgo(String when) {
    return 'requested $when';
  }

  @override
  String routineSchedule(String cron, String timezone) {
    return '$cron ($timezone)';
  }

  @override
  String templateIncludesRoutines(String names) {
    return 'Includes routines: $names.';
  }

  @override
  String toolCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n tools',
      one: '1 tool',
    );
    return '$_temp0';
  }

  @override
  String get weekdaysAt9 => 'Weekdays at 9:00';
}
