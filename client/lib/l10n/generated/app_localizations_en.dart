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
  String get noBots => 'No bots yet';

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
  String get headlessScreenNote =>
      'This computer has no desktop, so this shows its browser (blank until the bot opens a page). Switch to a desktop to watch and control apps live.';

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
  String get defaultBotName => 'Chief';

  @override
  String get chooseModel => 'Choose a model';

  @override
  String get searchModels => 'Search models or type a model id';

  @override
  String get recommendedModels => 'Recommended';

  @override
  String get allModels => 'All models';

  @override
  String useCustomModel(String id) {
    return 'Use \"$id\"';
  }

  @override
  String modelListFallback(String reason) {
    return 'Showing suggested models. $reason You can still type any model id.';
  }

  @override
  String get noModelsFound => 'No models match.';

  @override
  String get addModelKeyFirst =>
      'Add a model key first. Your bot uses it to think; it\'s stored encrypted and never shown again.';

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
  String get triggerSchedule => 'Repeats';

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

  @override
  String get botBackInControl => 'The bot is back in control';

  @override
  String get botComputer => 'Computer';

  @override
  String get botComputerDefault =>
      'Default (its private computer, else the team computer)';

  @override
  String get botInControl => 'Bot in control';

  @override
  String get computerName => 'Name';

  @override
  String get computers => 'Computers';

  @override
  String get connectingLive => 'Connecting…';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get forBot => 'For bot';

  @override
  String get handBack => 'Hand back';

  @override
  String get handBackNote => 'Note for the bot (optional)';

  @override
  String get handBackNoteHint => 'For example: I signed in, carry on';

  @override
  String get live => 'Live';

  @override
  String get liveView => 'Live view';

  @override
  String get liveViewHelp =>
      'Watch this computer live and take control when needed.';

  @override
  String get newComputer => 'New computer';

  @override
  String get newComputerHelp =>
      'A private computer belongs to one bot. Its files stay separate from the team computer.';

  @override
  String get openLiveView => 'Open live view';

  @override
  String get paused => 'Paused';

  @override
  String get pausedUserInControl =>
      'Paused: a person is in control of the screen';

  @override
  String get privateComputer => 'Private computer';

  @override
  String get profileDesktop => 'Desktop';

  @override
  String get profileHeadless => 'Headless';

  @override
  String get rename => 'Rename';

  @override
  String get rightClickNextTap => 'Right-click on next tap';

  @override
  String get screenshotMode =>
      'Screenshots (live video unavailable on this network)';

  @override
  String get showKeyboard => 'Keyboard';

  @override
  String get someoneElseInControl => 'Someone else is in control';

  @override
  String get switchToDesktop => 'Switch to desktop';

  @override
  String get switchToHeadless => 'Switch to headless';

  @override
  String get takeControl => 'Take control';

  @override
  String get takeoverCompleted => 'Handed back';

  @override
  String get takeoverDismissed => 'Declined';

  @override
  String get takeoverPrivacy =>
      'While you\'re in control, the bot is paused and nothing you type or see is sent to it.';

  @override
  String get teamComputer => 'Team computer';

  @override
  String get withDesktop => 'With a desktop';

  @override
  String get withDesktopHelp =>
      'Adds a screen you can watch live; uses more memory';

  @override
  String get youAreInControl => 'You\'re in control';

  @override
  String botAsksForHelp(String reason) {
    return 'The bot asks: $reason';
  }

  @override
  String botNeedsHelp(String bot) {
    return '$bot needs your help';
  }

  @override
  String deleteComputerConfirm(String name) {
    return 'Delete $name? Its files, snapshots and checkpoints are deleted too.';
  }

  @override
  String latencyMs(int ms) {
    return '$ms ms';
  }

  @override
  String privateComputerOf(String bot) {
    return '$bot\'s computer';
  }

  @override
  String get micPermissionNeeded => 'Allow microphone access to dictate.';

  @override
  String get startCall => 'Start a voice call';

  @override
  String get stopDictation => 'Stop and transcribe';

  @override
  String get dictate => 'Dictate';

  @override
  String get readAloud => 'Read aloud';

  @override
  String get callConnecting => 'Connecting…';

  @override
  String get callLive => 'Live';

  @override
  String get callEnded => 'Call ended';

  @override
  String get callFailed => 'The call could not connect.';

  @override
  String get unmute => 'Unmute';

  @override
  String get mute => 'Mute';

  @override
  String get hangUp => 'Hang up';

  @override
  String callWith(String bot) {
    return 'Call with $bot';
  }

  @override
  String replyLatency(int ms) {
    return 'Reply started in $ms ms';
  }

  @override
  String get voiceSettings => 'Voice';

  @override
  String get voiceSettingsHelp => 'Read-aloud voice and dictation provider';

  @override
  String get readAloudProvider => 'Read-aloud provider';

  @override
  String get automatic => 'Automatic (first key found)';

  @override
  String get voiceId => 'Voice id (optional)';

  @override
  String get voiceIdHelp =>
      'The provider\'s voice id; empty uses a default voice';

  @override
  String get dictationProvider => 'Dictation provider';

  @override
  String get useThisComputer => 'Use this computer for bots';

  @override
  String get companionDesktopOnly =>
      'Only the desktop app (macOS, Windows, Linux) can act as a bot computer.';

  @override
  String get companionIntro =>
      'Let chosen bots work on this computer: run commands, edit files in folders you pick, browse and use apps. Everything they do shows on screen and can be stopped. Off until you approve each capability.';

  @override
  String get thisComputer => 'This computer';

  @override
  String get companionOnline => 'On: bots you allow can use this computer';

  @override
  String get companionError => 'Cannot reach Kasama; retrying';

  @override
  String get companionOff => 'Off';

  @override
  String get companionCapabilities => 'What bots may do';

  @override
  String get companionCapabilitiesHelp =>
      'Approve each one. High-risk actions always ask, whatever the bot\'s autonomy.';

  @override
  String get capShell => 'Run commands (inside shared folders)';

  @override
  String get capFiles => 'Read and edit files in shared folders';

  @override
  String get capBrowser => 'Use a browser (its own, separate from yours)';

  @override
  String get capDesktop => 'Use desktop apps';

  @override
  String get sharedFolders => 'Shared folders';

  @override
  String get sharedFoldersHelp => 'Bots can only reach these folders.';

  @override
  String get addFolder => 'Add a folder';

  @override
  String get botsAllowed => 'Bots allowed';

  @override
  String get botsAllowedHelp => 'Allowed bots use this computer as theirs.';

  @override
  String get unpairComputer => 'Stop using this computer and unpair it';

  @override
  String botActingHere(String bot, String action) {
    return '$bot is working on this computer: $action';
  }

  @override
  String get quickAsk => 'Quick ask';

  @override
  String get quickAskHint => 'Ask a bot anything…';

  @override
  String get bot => 'Bot';

  @override
  String get adminConsole => 'Admin console';

  @override
  String get adminOverview => 'Overview';

  @override
  String get adminUsers => 'Users';

  @override
  String get adminWorkspaces => 'Workspaces';

  @override
  String get adminServices => 'Services';

  @override
  String get notInstanceOwner =>
      'Only the instance owner can open the admin console.';

  @override
  String get runs24h => 'Runs (24 h)';

  @override
  String get failedRuns24h => 'Failed runs (24 h)';

  @override
  String get cost24h => 'Spend (24 h)';

  @override
  String get computersRunning => 'Computers running';

  @override
  String get devicesOnline => 'Personal computers online';

  @override
  String get editQuotas => 'Edit quotas';

  @override
  String get maxBots => 'Max bots';

  @override
  String get monthlyUsd => 'Monthly spend limit (USD)';

  @override
  String updateAvailable(String latest, String current) {
    return 'Kasama $latest is available (you run $current)';
  }

  @override
  String kasamaVersion(String version) {
    return 'Kasama $version';
  }

  @override
  String workspacesCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n workspaces',
      one: '1 workspace',
    );
    return '$_temp0';
  }

  @override
  String lastSignIn(String when) {
    return 'signed in $when';
  }

  @override
  String quotasFor(String name) {
    return 'Quotas for $name';
  }

  @override
  String membersCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n members',
      one: '1 member',
    );
    return '$_temp0';
  }

  @override
  String botsCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n bots',
      one: '1 bot',
    );
    return '$_temp0';
  }

  @override
  String cost30d(String usd) {
    return '$usd in 30 days';
  }

  @override
  String get connectingToServer => 'Connecting to Kasama…';

  @override
  String get cannotReachServer => 'Can\'t reach your Kasama server';

  @override
  String cannotReachServerHelp(String url) {
    return 'Check your connection, or that the server at $url is running.';
  }

  @override
  String get upgradeTitle => 'Upgrade your plan';

  @override
  String get notNow => 'Not now';

  @override
  String get seePlans => 'See plans';

  @override
  String get billing => 'Billing';

  @override
  String get billingOffSelfHosted =>
      'Billing is off on this server. Self-hosted Kasama has no limits.';

  @override
  String get restorePurchases => 'Restore purchases';

  @override
  String get restoreStarted => 'Checking your purchases…';

  @override
  String get plans => 'Plans';

  @override
  String get currentPlan => 'Current plan';

  @override
  String subscribeFor(String price) {
    return 'Subscribe for $price';
  }

  @override
  String get subscribeOnWeb => 'Subscribe on the web';

  @override
  String get credits => 'Credits';

  @override
  String limitBots(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bots',
      one: '1 bot',
    );
    return '$_temp0';
  }

  @override
  String limitComputerHours(int hours) {
    return '$hours computer hours a month';
  }

  @override
  String limitCredits(String amount) {
    return '\$$amount credits a month';
  }

  @override
  String get viaWeb => 'Billed on the web';

  @override
  String get viaAppStore => 'Billed through the App Store';

  @override
  String get viaGooglePlay => 'Billed through Google Play';

  @override
  String get yourPlan => 'Your plan';

  @override
  String planEndsOn(String date) {
    return 'Ends on $date';
  }

  @override
  String planRenewsOn(String date) {
    return 'Renews on $date';
  }

  @override
  String creditsBalance(String amount) {
    return 'Credits: \$$amount';
  }

  @override
  String get manageSubscription => 'Manage subscription';

  @override
  String usageComputerHours(String hours) {
    return 'Cloud computers: $hours h';
  }

  @override
  String usageLiveViewMinutes(String minutes) {
    return 'Live view: $minutes min';
  }

  @override
  String usageTokens(int count) {
    return 'Model credits: $count tokens';
  }

  @override
  String get thisMonth => 'This month';

  @override
  String get noBillableUsage => 'No billable usage yet.';

  @override
  String get cloudConnect => 'Cloud Connect';

  @override
  String get cloudConnectHelp =>
      'Let a self-hosted Kasama use cloud computers and model credits, billed to this workspace.';

  @override
  String get cloudConnectNewKey => 'New Cloud Connect key';

  @override
  String get cloudConnectKeyCreated => 'Key created';

  @override
  String get cloudConnectKeyOnce =>
      'Copy it now; it is shown only once. Set it on your server with KASAMA_CLOUD_URL.';

  @override
  String get copy => 'Copy';

  @override
  String get revoke => 'Revoke';

  @override
  String get instanceName => 'Server name';

  @override
  String get server => 'Server';

  @override
  String get serverAddress => 'Server address';

  @override
  String get connect => 'Connect';

  @override
  String get changeServer => 'Use a different server';

  @override
  String serverIs(String host) {
    return 'Server: $host';
  }

  @override
  String get continueWithSso => 'Continue with SSO';

  @override
  String get workEmail => 'Work email';

  @override
  String get privacy => 'Privacy';

  @override
  String get exportMyData => 'Export my data';

  @override
  String get exportMyDataHelp =>
      'A ZIP of everything you can see: bots, chats, runs, memories and settings. Secrets and keys are never included.';

  @override
  String exportReady(String kb) {
    return 'Export ready ($kb KB)';
  }

  @override
  String get runHistoryRetention => 'Keep run history for';

  @override
  String get runHistoryRetentionHelp =>
      'Older run events are deleted automatically.';

  @override
  String days(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get deleteAccount => 'Delete my account';

  @override
  String get deleteAccountHelp =>
      'Signs you out now and erases your data and the workspaces you solely own after a short grace period.';

  @override
  String get deleteAccountQuestion => 'Delete your account?';

  @override
  String deleteAccountConfirm(String email) {
    return 'Workspaces where you are the only owner are deleted with your account, including their bots and computers. Type $email to confirm.';
  }

  @override
  String get accountDeleted => 'Account scheduled for deletion';

  @override
  String accountDeletedBody(String date) {
    return 'You have been signed out. Your data will be erased on $date.';
  }

  @override
  String get selectBotHelp =>
      'Pick a bot on the left, or create one to get started.';

  @override
  String get toolShell => 'Ran a command';

  @override
  String get toolFileRead => 'Read a file';

  @override
  String get toolFileWrite => 'Wrote a file';

  @override
  String get toolFiles => 'Worked with files';

  @override
  String get toolBrowser => 'Used the browser';

  @override
  String get toolSearch => 'Searched the web';

  @override
  String get toolMemory => 'Checked memory';

  @override
  String get toolSkill => 'Used a skill';

  @override
  String get toolCheckpoint => 'Saved a checkpoint';

  @override
  String get toolDesktop => 'Used the desktop';

  @override
  String get toolDelegate => 'Asked another bot';

  @override
  String toolOther(String tool) {
    return 'Used $tool';
  }

  @override
  String toolSteps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count steps',
      one: '1 step',
    );
    return '$_temp0';
  }

  @override
  String showMoreSteps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Show $count earlier steps',
      one: 'Show 1 earlier step',
    );
    return '$_temp0';
  }

  @override
  String get copied => 'Copied';

  @override
  String get jumpToLatest => 'Jump to latest';

  @override
  String chatEmptySubtitle(String bot) {
    return '$bot has its own computer, memory and tools. Ask for something you want done.';
  }

  @override
  String get suggestResearch => 'Research a topic and write me a short summary';

  @override
  String get suggestFiles =>
      'Make a project folder with a to-do list in my workspace';

  @override
  String get suggestWebsite => 'Check a website and tell me what\'s new';

  @override
  String get suggestCapabilities => 'What can you do on your computer?';

  @override
  String get showComputer => 'Show computer';

  @override
  String get hideComputer => 'Hide computer';

  @override
  String get moreActions => 'More';

  @override
  String get noConversations => 'No conversations yet';

  @override
  String get untitledChat => 'New conversation';

  @override
  String get listening => 'Listening…';

  @override
  String get orLabel => 'or';

  @override
  String get signInTagline =>
      'Your AI teammates, each with its own computer, memory and tools.';

  @override
  String get noBotsHelp =>
      'A bot is a teammate with its own computer. Create one to start chatting.';

  @override
  String get newBotSubtitle => 'A teammate with its own computer and memory.';

  @override
  String get appearance => 'Appearance';

  @override
  String get settingsBotsSection => 'What your bots can use';

  @override
  String get settingsMoreSection => 'Privacy and more';

  @override
  String get modelKeysHelp =>
      'OpenRouter, OpenAI, Anthropic, Google, xAI or your own server';

  @override
  String get signOutConfirm =>
      'You can sign back in any time; your bots keep working.';

  @override
  String get roleOwner => 'Owner';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleMember => 'Member';

  @override
  String get themeLight => 'Light';

  @override
  String get themeSystem => 'System';

  @override
  String get themeDark => 'Dark';

  @override
  String get accentColor => 'Accent color';

  @override
  String get noApprovalsHelp =>
      'When a bot wants to do something risky, it asks here first.';

  @override
  String get createWorkspaceBody =>
      'A workspace holds your bots, their computers and the people you work with.';

  @override
  String get workspaceNameHint => 'My team';

  @override
  String get orJoinWithCode => 'or join with an invite code';

  @override
  String get getOpenRouterKey => 'Get an OpenRouter key';

  @override
  String get createFirstBotBody =>
      'Give it a name and a model. You can change both later.';

  @override
  String stepOf(int step, int total) {
    return 'Step $step of $total';
  }

  @override
  String get providerHintOpenRouter => 'recommended';

  @override
  String get providerHintCompatible => 'Ollama, LM Studio, vLLM';

  @override
  String get providerHintImages => 'images';

  @override
  String get providerHintSearch => 'web search';

  @override
  String get providerHintVoice => 'voice';

  @override
  String get noRoutinesHelp =>
      'A routine is work a bot does later on its own: once at a time you pick, on a schedule, or when a webhook arrives.';

  @override
  String get routineOnce => 'Once';

  @override
  String lastRun(String when) {
    return 'Last: $when';
  }

  @override
  String get routineOff => 'Off';

  @override
  String deleteRoutineTitle(String name) {
    return 'Delete “$name”?';
  }

  @override
  String get deleteRoutineBody =>
      'It won\'t run again. Results it already posted stay in their conversation.';

  @override
  String get triggerOnce => 'Once';

  @override
  String inMinutes(int n) {
    return 'In $n min';
  }

  @override
  String inHours(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'In $n hours',
      one: 'In 1 hour',
    );
    return '$_temp0';
  }

  @override
  String get tomorrowAt9 => 'Tomorrow 9:00';

  @override
  String get integrationNeedsName => 'Give it a name with at least one letter.';

  @override
  String integrationNeedsField(String field) {
    return 'Fill in $field to save.';
  }

  @override
  String integrationSavedAs(String name) {
    return 'Saved as $name';
  }

  @override
  String get integrationUrlInvalid =>
      'Use a full address starting with https://';

  @override
  String get openFile => 'Open';

  @override
  String get saveFile => 'Save';

  @override
  String get shareFile => 'Share';

  @override
  String savedFile(String name) {
    return 'Saved $name';
  }

  @override
  String noAppToOpen(String name) {
    return 'No app on this device opens $name. Save it instead.';
  }

  @override
  String get previewUnavailable =>
      'No preview for this kind of file. Open or save it to view it.';

  @override
  String get openFileInChat => 'Open file';

  @override
  String get attach => 'Attach';

  @override
  String get attachFiles => 'Files';

  @override
  String get attachPhotos => 'Photo library';

  @override
  String get attachCamera => 'Take photo';

  @override
  String get dropToAttach => 'Drop files to attach';

  @override
  String uploadFailed(String name) {
    return 'Couldn\'t upload $name';
  }

  @override
  String get removeAttachment => 'Remove';

  @override
  String get noComputerForFiles => 'This bot has no computer to keep files on.';

  @override
  String fileTooLarge(String name) {
    return '$name is over 25 MB, too large to attach.';
  }

  @override
  String get toolRoutineCreate => 'Scheduled a routine';

  @override
  String get toolRoutineDelete => 'Deleted a routine';

  @override
  String get toolRoutines => 'Checked routines';

  @override
  String get toolTasks => 'Updated the task board';

  @override
  String get toolNotify => 'Sent you a notification';

  @override
  String get toolHttp => 'Called a web API';

  @override
  String get toolMedia => 'Made an image';

  @override
  String get toolTakeover => 'Asked you to take over';
}
