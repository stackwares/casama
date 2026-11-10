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
  String get persona => 'Instructions';

  @override
  String get personaHint =>
      'What this bot does and how it should work. A persona fills this in; edit it freely.';

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
    return '$message';
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
  String get emptyFolder => 'This folder is empty';

  @override
  String get noCheckpoints =>
      'They\'re saved automatically before risky changes, so you can undo them.';

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
      'Connect an MCP server, an OpenAPI source, Composio or Pipedream to give bots more tools.';

  @override
  String get noIntegrationsForBot =>
      'Add integrations in Settings first, then turn them on for this bot here.';

  @override
  String get noNotifications => 'No notifications yet';

  @override
  String get noRoutines =>
      'No routines yet. Routines run this bot on a schedule or when a webhook arrives.';

  @override
  String get noSecrets =>
      'No secrets yet. Bots reference them by name, and each one only goes to the hosts you allow.';

  @override
  String get noTasks => 'No tasks yet';

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
  String get startFrom => 'Persona';

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
      'Its private computer if it has one, otherwise the team computer';

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

  @override
  String get secretsHelp =>
      'Bots put a secret in requests by its name. It\'s only sent to the hosts you allow and the model never sees it.';

  @override
  String deleteSecretTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get deleteSecretBody =>
      'Bots that use it will stop being able to reach that service.';

  @override
  String get hide => 'Hide';

  @override
  String get show => 'Show';

  @override
  String get deleteMemoryTitle => 'Delete this memory?';

  @override
  String get noMemoriesHelp =>
      'As you chat, the bot keeps what matters: facts, preferences and summaries of past work.';

  @override
  String get memoryHelp =>
      'Pinned memories are always in the bot\'s context. Edit anything that\'s wrong; deleted memories are gone for good.';

  @override
  String get memoryFact => 'Fact';

  @override
  String get memoryPreference => 'Preference';

  @override
  String get memorySummary => 'Summary';

  @override
  String get memoryEpisode => 'Episode';

  @override
  String get pinned => 'Pinned';

  @override
  String get editMemory => 'Edit memory';

  @override
  String get editMemoryHelp =>
      'The bot uses this the next time it\'s relevant.';

  @override
  String get modelKeysIntro =>
      'Bots think with your own model provider keys. Keys are stored encrypted and never shown again.';

  @override
  String get yourKeys => 'Your keys';

  @override
  String get keyWorking => 'Working';

  @override
  String get keyFailing => 'Failing';

  @override
  String get keyUntested => 'Not tested';

  @override
  String get skillsHelp =>
      'A skill is a set of instructions a bot loads when a task calls for it, like your house style for reports.';

  @override
  String deleteSkillTitle(String name) {
    return 'Delete the skill “$name”?';
  }

  @override
  String get editSkill => 'Edit skill';

  @override
  String get deleteSkill => 'Delete skill';

  @override
  String get skillDescriptionHelp =>
      'Bots read this to decide when the skill applies.';

  @override
  String get skillBodyHint => '# Steps\n1. …';

  @override
  String get computersHelp =>
      'Each bot works on a computer: the team computer everyone shares, or a private one. Files stay on it between chats.';

  @override
  String get thisDevice => 'This device';

  @override
  String get renameComputer => 'Rename computer';

  @override
  String deleteComputerTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get privacyIntro =>
      'Your chats, memories and files belong to you. Export them any time, or delete your account.';

  @override
  String get yourData => 'Your data';

  @override
  String get dangerZone => 'Danger zone';

  @override
  String get quotasHelp => 'Leave a field empty for no limit.';

  @override
  String get serviceOff => 'Off';

  @override
  String get serviceDown => 'Down';

  @override
  String get serviceOk => 'OK';

  @override
  String get inviteMemberHelp =>
      'They\'ll get an email with a link to join this workspace.';

  @override
  String get sendInvite => 'Send invite';

  @override
  String get inviteReady => 'Invite ready';

  @override
  String inviteCodeHelp(String email) {
    return 'Email isn\'t set up on this server, so share this code with $email. They paste it when joining.';
  }

  @override
  String get copyCode => 'Copy code';

  @override
  String get thinking0 => 'Model';

  @override
  String get computerAndTools => 'Computer and tools';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get autonomyAskAlwaysHelp =>
      'Checks with you before every action that changes something.';

  @override
  String get autonomyAskRiskyHelp =>
      'Works on its own, but asks before anything risky, like deleting files or spending money.';

  @override
  String get autonomyAutonomousHelp =>
      'Acts without asking. Best for routines you trust.';

  @override
  String get usageSubtitle => 'Model spend this month';

  @override
  String get skillsRowHelp => 'Instructions bots load when a task needs them';

  @override
  String get integrationsRowHelp => 'MCP servers and connected apps';

  @override
  String get secretsRowHelp =>
      'Tokens and passwords, sent only where you allow';

  @override
  String get computersRowHelp => 'The team computer and private ones';

  @override
  String get companionRowHelp => 'Let bots use this device\'s apps and files';

  @override
  String get privacyRowHelp => 'Export your data or delete your account';

  @override
  String get adminRowHelp => 'Users, workspaces, quotas and services';

  @override
  String get noIntegrationsTitle => 'No integrations yet';

  @override
  String get integrationsHelp =>
      'Integrations give bots more tools: an MCP server, an OpenAPI source, Composio or Pipedream. Each tool is named after its integration.';

  @override
  String get botIntegrationsHelp =>
      'Turn on the integrations this bot may use. Its tools show up the next time it runs.';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get noRunsHelp =>
      'Each time this bot works, from a chat, a routine or a webhook, the run shows up here with what it did and what it cost.';

  @override
  String get runCompleted => 'Done';

  @override
  String get runWaiting => 'Waiting';

  @override
  String get runWorking => 'Working';

  @override
  String get triggerChat => 'Chat';

  @override
  String get triggerRoutine => 'Routine';

  @override
  String get noEventsForFilter => 'Nothing of this kind in this run.';

  @override
  String get runStatusFailed => 'Failed';

  @override
  String get runStatusStopped => 'Stopped';

  @override
  String get quickAskIntro =>
      'Send a quick request. It starts a new chat with the bot you pick.';

  @override
  String quickAskHintBot(String bot) {
    return 'What should $bot do?';
  }

  @override
  String get noNotificationsHelp =>
      'Routine results, budget alerts and requests from your bots show up here.';

  @override
  String get noTasksHelp =>
      'Bots and people add tasks here to hand work to each other.';

  @override
  String get stateProvisioning => 'Setting up';

  @override
  String get stateStarting => 'Starting';

  @override
  String get stateRunning => 'Running';

  @override
  String get stateIdle => 'Idle';

  @override
  String get stateSleeping => 'Asleep';

  @override
  String get stateStopped => 'Stopped';

  @override
  String get stateError => 'Error';

  @override
  String get terminalHelp =>
      'A shell on this computer. Bots use the same one, so you can see and fix what they did.';

  @override
  String get up => 'Up';

  @override
  String get emptyFolderHelp =>
      'Files your bots make, and files you upload, show up here.';

  @override
  String get noCheckpointsTitle => 'No checkpoints yet';

  @override
  String get checkpointsHelp =>
      'A checkpoint saves this computer before a risky change. Restoring puts its files back as they were.';

  @override
  String deleteFileTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get botComputerAuto => 'Automatic';

  @override
  String get botComputerHelp =>
      'Where this bot runs commands, browses and keeps its files.';

  @override
  String get billingOffTitle => 'No limits here';

  @override
  String revokeKeyTitle(String name) {
    return 'Revoke the key for $name?';
  }

  @override
  String get revokeKeyBody =>
      'That server stops using cloud computers and credits right away.';

  @override
  String get handBackHelp =>
      'The bot picks up where you left off. Tell it what you did, if it helps.';

  @override
  String get serverHelp =>
      'Use your own Kasama server. Enter the address you or your admin set up.';

  @override
  String get ssoHelp =>
      'Enter your work email and we\'ll send you to your company\'s sign-in page.';

  @override
  String get colorScheme => 'Color scheme';

  @override
  String get searchThemes => 'Search schemes';

  @override
  String get noThemesFound => 'No schemes match.';

  @override
  String get familyAll => 'All';

  @override
  String get familyPurple => 'Purple';

  @override
  String get familyBlue => 'Blue';

  @override
  String get familyTeal => 'Teal';

  @override
  String get familyGreen => 'Green';

  @override
  String get familyWarm => 'Warm';

  @override
  String get familyRed => 'Red & pink';

  @override
  String get familyNeutral => 'Neutral';

  @override
  String get background => 'Background';

  @override
  String get backgroundPattern => 'Pattern';

  @override
  String get backgroundColors => 'Colors';

  @override
  String get backgroundThemeColors => 'Theme';

  @override
  String get patternStrength => 'Pattern strength';

  @override
  String get wallpaperEverywhere => 'Show on every screen';

  @override
  String get wallpaperEverywhereHelp =>
      'Turn off to keep it behind chats only.';

  @override
  String get resetBackground => 'Reset to default';

  @override
  String get chatsOnly => 'Chats only';

  @override
  String get copyMessage => 'Copy';

  @override
  String get selectText => 'Select text';

  @override
  String get shareMessage => 'Share';

  @override
  String get messageCopied => 'Copied';

  @override
  String get botUiBroken => 'This part of the reply couldn\'t be shown.';

  @override
  String get botUiSent => 'Sent';

  @override
  String get botIcon => 'Icon';

  @override
  String get botIconInitials => 'Initials';

  @override
  String get errorDetailsTitle => 'What went wrong';

  @override
  String get exportLabel => 'Export';

  @override
  String get openTimeline => 'Open run timeline';

  @override
  String get details => 'Details';

  @override
  String get themes => 'Themes';

  @override
  String get themesHelp =>
      'A theme sets the color scheme, fonts and background together. Change any of them afterwards and save the result as your own.';

  @override
  String get themePresets => 'Presets';

  @override
  String get myThemes => 'Your themes';

  @override
  String get saveTheme => 'Save current look';

  @override
  String get themeName => 'Theme name';

  @override
  String get importTheme => 'Import a theme';

  @override
  String get themeCode => 'Theme code';

  @override
  String get themeCodeHelp =>
      'Paste a code someone shared with you. It starts with kasama-theme:';

  @override
  String get invalidThemeCode => 'That isn\'t a Kasama theme code.';

  @override
  String themeImported(String name) {
    return 'Added $name to your themes';
  }

  @override
  String get themeCodeCopied =>
      'Theme code copied. Anyone can paste it into Themes → Import.';

  @override
  String get shareTheme => 'Share code';

  @override
  String deleteThemeTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get currentLook => 'Custom';

  @override
  String get fonts => 'Fonts';

  @override
  String get headingFont => 'Headings';

  @override
  String get bodyFont => 'Text';

  @override
  String get fontsHelp =>
      'Google Sans and Noto Serif come with the app and work offline. Other Google Fonts download the first time you pick them.';

  @override
  String get searchFonts => 'Search all Google Fonts';

  @override
  String get suggestedFonts => 'Suggested';

  @override
  String get allFonts => 'All Google Fonts';

  @override
  String get noFontsFound => 'No font with that name';

  @override
  String get resetFonts => 'Use the defaults';

  @override
  String get fontSample => 'Your bots, working together with you.';

  @override
  String get backgroundPhoto => 'Photo';

  @override
  String get yourPhoto => 'Your photo';

  @override
  String get browsePhotos => 'Browse photos';

  @override
  String get removePhoto => 'Remove photo';

  @override
  String get photoBlur => 'Blur';

  @override
  String get photoDim => 'Dim';

  @override
  String photoBy(String name) {
    return 'Photo by $name on Unsplash';
  }

  @override
  String get searchPhotos => 'Search photos';

  @override
  String get photosUnavailable => 'Couldn\'t load photos.';

  @override
  String get noPhotos => 'No photos found';

  @override
  String get photoHelp =>
      'A photo goes under the doodles. Blur and dim keep text readable on top.';

  @override
  String get periodToday => 'Today';

  @override
  String get periodWeek => 'This week';

  @override
  String get periodYear => 'This year';

  @override
  String get totalSpend => 'Spend';

  @override
  String get tokensIn => 'Tokens in';

  @override
  String get tokensOut => 'Tokens out';

  @override
  String get runsLabel => 'Runs';

  @override
  String get spendByDay => 'Spend by day';

  @override
  String get byBot => 'By bot';

  @override
  String get byModel => 'By model';

  @override
  String get everythingMetered => 'Everything metered';

  @override
  String get exportCsv => 'Export CSV';

  @override
  String get exportJson => 'Export JSON';

  @override
  String get askBotAboutUsage => 'Ask a bot about this';

  @override
  String get noUsageYet => 'No usage in this period yet.';

  @override
  String get otherModel => 'Computers and other';

  @override
  String get deletedBot => 'Not tied to a bot';

  @override
  String get usageHelp =>
      'Costs are estimates from token counts and published prices. Your model provider\'s bill is the final word.';

  @override
  String usageAskPrompt(String period, String summary) {
    return 'Here is my Kasama usage for $period. Help me understand where the money goes and how I could spend less. You can also check live numbers with your usage tool.\n\n$summary';
  }

  @override
  String get kindTokensIn => 'Model input';

  @override
  String get kindTokensOut => 'Model output';

  @override
  String get kindComputer => 'Cloud computer time';

  @override
  String get kindStream => 'Live view';

  @override
  String get kindTts => 'Read aloud';

  @override
  String get personaWork => 'Work';

  @override
  String get personaResearch => 'Research';

  @override
  String get personaBuild => 'Build';

  @override
  String get personaCreate => 'Create';

  @override
  String get personaLife => 'Life';

  @override
  String get personaOther => 'Other';

  @override
  String get blankBotHelp =>
      'Start from scratch and write your own instructions.';

  @override
  String get browse => 'Browse';

  @override
  String get choosePersona => 'Choose a persona';

  @override
  String get choosePersonaHelp =>
      'Each one comes with instructions, a look, and sometimes skills and routines. You can change anything afterwards.';

  @override
  String get searchPersonas => 'Search personas';

  @override
  String get noPersonasFound => 'No persona matches that';

  @override
  String get previewPersona => 'Preview';

  @override
  String get personaInstructions => 'Instructions';

  @override
  String get personaTryAsking => 'Try asking';

  @override
  String usePersona(String name) {
    return 'Use $name';
  }

  @override
  String get loadPersona => 'Load a persona';

  @override
  String get replaceInstructionsTitle => 'Replace the instructions?';

  @override
  String replaceInstructionsBody(String name) {
    return 'The bot\'s current instructions will be replaced with $name\'s. Skills and routines stay as they are.';
  }

  @override
  String get replace => 'Replace';

  @override
  String get appsTitle => 'Apps';

  @override
  String get appsSubtitle => 'Give your bots the tools your team already uses.';

  @override
  String get connectedTab => 'Connected';

  @override
  String get browseTab => 'Browse';

  @override
  String get searchApps => 'Search apps';

  @override
  String get popularApps => 'Popular';

  @override
  String get allApps => 'All apps';

  @override
  String get appCatDeveloper => 'Developer';

  @override
  String get appCatProductivity => 'Productivity';

  @override
  String get appCatGoogle => 'Google';

  @override
  String get appCatPayments => 'Payments';

  @override
  String get appCatDesign => 'Design';

  @override
  String get appCatSales => 'Sales & support';

  @override
  String get appCatData => 'Data & search';

  @override
  String get appCatAutomation => 'Automation';

  @override
  String get authOneClick => 'One click';

  @override
  String get authApiKey => 'API key';

  @override
  String get authNone => 'No sign-in';

  @override
  String get authAdminSetup => 'Needs setup';

  @override
  String get connectedBadge => 'Connected';

  @override
  String get whatBotsCanDo => 'What your bots can do';

  @override
  String continueWith(String app) {
    return 'Continue with $app';
  }

  @override
  String get signInTab => 'Sign in';

  @override
  String get connectNoSignIn => 'This app works without signing in.';

  @override
  String finishSignIn(String app) {
    return 'Finish signing in to $app';
  }

  @override
  String finishSignInHelp(String app) {
    return '$app opened in your browser. Approve access there and this updates by itself.';
  }

  @override
  String get reopenSignIn => 'Open the sign-in page again';

  @override
  String appConnected(String app) {
    return '$app is connected';
  }

  @override
  String appToolsReady(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tools are ready for your bots.',
      one: '1 tool is ready for your bots.',
      zero: 'Ready to use.',
    );
    return '$_temp0';
  }

  @override
  String get whichBots => 'Which bots can use it?';

  @override
  String get whichBotsHelp => 'Bots still ask you before anything risky.';

  @override
  String get doneLabel => 'Done';

  @override
  String openApp(String app) {
    return 'Open $app';
  }

  @override
  String get pasteLabel => 'Paste';

  @override
  String get connectingLabel => 'Connecting…';

  @override
  String get connectFailedTitle => 'Couldn\'t connect';

  @override
  String adminSetupNeeded(String app) {
    return 'One-click sign-in for $app needs a one-time setup by whoever runs this Kasama server.';
  }

  @override
  String adminSetupRedirect(String uri) {
    return 'Register this redirect address with the app: $uri';
  }

  @override
  String get privacyNote =>
      'The sign-in is stored encrypted and never shown again. Disconnect anytime.';

  @override
  String get moreWays => 'More ways to connect';

  @override
  String get composioHelp =>
      'Hundreds of apps like Gmail, Salesforce and Shopify, with sign-in handled by Composio.';

  @override
  String get pipedreamHelp => 'Thousands of apps through Pipedream Connect.';

  @override
  String get customServer => 'Custom server';

  @override
  String get customServerHelp =>
      'Any MCP server or OpenAPI spec. For developers.';

  @override
  String usedByBots(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Used by $count bots',
      one: 'Used by 1 bot',
      zero: 'Not given to any bot yet',
    );
    return '$_temp0';
  }

  @override
  String get statusReady => 'Ready';

  @override
  String get statusNeedsAttention => 'Needs attention';

  @override
  String get statusChecking => 'Checking';

  @override
  String get toolsTitle => 'Tools';

  @override
  String get toolsHelp =>
      'Read-only tools run on their own. Tools that make changes ask first when a bot has read something untrusted, and ones marked “Always asks” wait for you every time.';

  @override
  String get botsWithAccess => 'Bots with access';

  @override
  String get reconnect => 'Reconnect';

  @override
  String get disconnect => 'Disconnect';

  @override
  String disconnectTitle(String app) {
    return 'Disconnect $app?';
  }

  @override
  String get disconnectBody =>
      'Bots lose its tools right away, and the saved sign-in is deleted.';

  @override
  String get testConnection => 'Test connection';

  @override
  String get signedInOAuth => 'Signed in with your account';

  @override
  String get signedInKey => 'Connected with an API key';

  @override
  String get signedInNone => 'No sign-in needed';

  @override
  String get noConnectionsTitle => 'Connect your first app';

  @override
  String get noConnections =>
      'Stripe, Linear, Notion, Gmail and more. Most take one click.';

  @override
  String get browseApps => 'Browse apps';

  @override
  String providerSetupTitle(String provider) {
    return 'Connect $provider';
  }

  @override
  String providerSetupHelp(String provider) {
    return '$provider signs in to the apps for you, so you never handle their keys.';
  }

  @override
  String get getFreeKey => 'Get a free key';

  @override
  String providerAppsTitle(String provider) {
    return 'Apps through $provider';
  }

  @override
  String get addAnApp => 'Add an app';

  @override
  String searchProviderApps(String provider) {
    return 'Search $provider apps';
  }

  @override
  String get accountConnected => 'Signed in';

  @override
  String get accountPending => 'Waiting for sign-in';

  @override
  String get accountError => 'Sign-in problem';

  @override
  String get noProviderAccounts => 'No apps yet. Add one and sign in to it.';

  @override
  String get projectId => 'Project ID';

  @override
  String get toolRiskLow => 'Read-only';

  @override
  String get toolRiskMedium => 'Makes changes';

  @override
  String get toolRiskHigh => 'Always asks';

  @override
  String get askWhichBot => 'Which bot should look at this?';

  @override
  String get computerWake => 'Wake up';

  @override
  String get computerGoingToSleep => 'Going to sleep';

  @override
  String get liveViewWakesHelp =>
      'This computer is asleep. Opening the live view wakes it up; it goes back to sleep after a while without use.';

  @override
  String get wakeAndWatch => 'Wake up and watch live';

  @override
  String get chatGptPlan => 'ChatGPT plan';

  @override
  String get continueWithChatGpt => 'Continue with ChatGPT';

  @override
  String get chatGptConnectHelp =>
      'Run your bots on your ChatGPT plan instead of an API key. Their model calls count toward your plan\'s limits, and only you can use it.';

  @override
  String get chatGptDesktopOnly =>
      'To connect your ChatGPT plan, open the desktop app, or run \"kasama credential chatgpt\" in the CLI.';

  @override
  String get chatGptWaiting =>
      'Finish signing in with ChatGPT in your browser…';

  @override
  String chatGptConnected(String account) {
    return 'Connected your ChatGPT plan ($account).';
  }

  @override
  String get chatGptPlanUsageOff =>
      'You signed in, but plan usage wasn\'t allowed. Reconnect and allow it, or add an API key.';

  @override
  String get orAddApiKey => 'Or add an API key';

  @override
  String get planOnlyYou => 'Only you can use it';

  @override
  String get planOtherMember => 'Another member\'s plan';

  @override
  String get planConnected => 'Connected';

  @override
  String get planUsageOff => 'Plan usage off';

  @override
  String get planNeedsReconnect => 'Sign in again';

  @override
  String get useNextModelAtLimit =>
      'Use the bot\'s next model at my plan limit';

  @override
  String get useNextModelAtLimitHelp =>
      'Off: a run stops when your ChatGPT limit is reached. On: it continues on the bot\'s next model, which may cost money.';

  @override
  String get manageUsage => 'Manage usage';

  @override
  String get removeKey => 'Remove';

  @override
  String removeKeyConfirm(String label) {
    return 'Remove $label? Bots that use it stop working until you give them another key.';
  }

  @override
  String get removeKeyChatGptNote => 'Your ChatGPT sign-in is revoked too.';

  @override
  String modelFallbackNotice(String message) {
    return 'Switched to the next model: $message';
  }

  @override
  String get twoStepSignIn => 'Two-step sign-in';

  @override
  String get twoStepHelp =>
      'Ask for a code from an authenticator app whenever you sign in.';

  @override
  String get twoStepIsOn => 'On';

  @override
  String get twoStepIsOff => 'Off';

  @override
  String get twoStepRequiredHere =>
      'Required for owners and admins in this workspace';

  @override
  String get twoStepSetUp => 'Set up an authenticator app';

  @override
  String get twoStepAddAnother => 'Add another authenticator';

  @override
  String get twoStepScan =>
      'Scan this code with an authenticator app (such as 1Password, Google Authenticator or Authy), or type in the setup key, then enter the 6-digit code it shows.';

  @override
  String get twoStepKey => 'Setup key';

  @override
  String get twoStepCode => '6-digit code';

  @override
  String get twoStepVerify => 'Verify';

  @override
  String get twoStepNowOn => 'Two-step sign-in is on.';

  @override
  String get twoStepAuthenticators => 'Authenticator apps';

  @override
  String get twoStepRemove => 'Remove';

  @override
  String get twoStepRemoveConfirm =>
      'Remove this authenticator app? If it\'s your only one, you\'ll sign in with just your password.';

  @override
  String get twoStepPromptTitle => 'Enter your code';

  @override
  String get twoStepPromptBody =>
      'Open your authenticator app and enter the 6-digit code to finish signing in.';

  @override
  String get requireTwoStep => 'Require two-step sign-in for owners and admins';

  @override
  String get requireTwoStepHelp =>
      'Owners and admins without it keep member access only until they sign in with it. Turn it on for yourself first.';

  @override
  String get twoStepNeededForAdmin =>
      'This workspace requires two-step sign-in for owners and admins. Set it up, or sign in again with your code, to use admin settings.';

  @override
  String get adminAbuse => 'Abuse';

  @override
  String get adminNoAbuse => 'Nothing suspicious so far.';

  @override
  String get suspendWorkspace => 'Suspend';

  @override
  String get unsuspendWorkspace => 'Lift suspension';

  @override
  String get suspendReason => 'Reason';

  @override
  String get suspendWorkspaceHelp =>
      'Its computers stop and its bots stop running. Nothing is deleted, and you can lift it any time.';

  @override
  String workspaceSuspended(String reason) {
    return 'Suspended: $reason';
  }

  @override
  String get workspaceSuspendedBanner =>
      'This workspace is suspended, so bots can\'t run and computers can\'t start. Contact whoever runs this server.';

  @override
  String get abuseKind_mining_pool => 'Crypto mining blocked';

  @override
  String get abuseKind_blocked_port => 'Mail port blocked';

  @override
  String get abuseKind_egress_flood => 'Traffic flood';

  @override
  String get abuseKind_signup_blocked => 'Sign-up refused';

  @override
  String get abuseKind_suspended => 'Workspace suspended';

  @override
  String get abuseKind_unsuspended => 'Suspension lifted';

  @override
  String get kindLocalMcp => 'On a computer';

  @override
  String get capMcp => 'Local tools (MCP)';

  @override
  String get localMcpServers => 'Local tools (MCP)';

  @override
  String get localMcpHelp =>
      'MCP servers on this computer that your bots can use, such as Claude Code, Codex or design apps. Their tokens stay on this computer.';

  @override
  String get localMcpAdd => 'Add a local MCP server';

  @override
  String get localMcpEmpty => 'No local MCP servers yet.';

  @override
  String get localMcpName => 'Name';

  @override
  String get localMcpKind => 'How it runs';

  @override
  String get localMcpStdio => 'A command';

  @override
  String get localMcpLoopback => 'An address on this computer';

  @override
  String get localMcpCommand => 'Command';

  @override
  String get localMcpCommandHint => 'npx -y @example/mcp-server';

  @override
  String get localMcpUrl => 'Address';

  @override
  String get localMcpFolder => 'Working folder (optional)';

  @override
  String get localMcpEnv =>
      'Environment (one KEY=value per line, kept on this computer)';

  @override
  String get localMcpNeedsCapability =>
      'Turn on Local tools (MCP) above so bots can use these.';

  @override
  String get localMcpBadUrl =>
      'Use an address on this computer, like http://127.0.0.1:3845/mcp.';

  @override
  String get localMcpBadFolder =>
      'Pick a folder inside one of the shared folders.';

  @override
  String localMcpOnDevice(String device) {
    return 'On $device';
  }

  @override
  String get codingAgents => 'Coding agents';

  @override
  String get codingAgentsHelp =>
      'Bots can hand coding tasks to these agents on this computer. They use your own sign-ins and work in the folders you share.';

  @override
  String get codingAgentsNone =>
      'No coding agents found. Install Claude Code, Codex or Cursor\'s command-line agent to hand them coding tasks.';

  @override
  String get codingAgentsNeedShell =>
      'Coding agents run as commands, so they need Run commands turned on.';

  @override
  String get allowCommands => 'Turn on';

  @override
  String get navBoard => 'Board';

  @override
  String get board => 'Board';

  @override
  String get newTicket => 'New ticket';

  @override
  String get ticketTitle => 'Title';

  @override
  String get ticketDetails => 'Details';

  @override
  String get taskInReview => 'In review';

  @override
  String get priority => 'Priority';

  @override
  String get priorityUrgent => 'Urgent';

  @override
  String get priorityHigh => 'High';

  @override
  String get priorityMedium => 'Medium';

  @override
  String get priorityLow => 'Low';

  @override
  String get priorityNone => 'No priority';

  @override
  String get filterAll => 'All';

  @override
  String get filterMine => 'Mine';

  @override
  String get filterBots => 'Bots';

  @override
  String get assignee => 'Assigned to';

  @override
  String get unassigned => 'Unassigned';

  @override
  String get assignToMe => 'Me';

  @override
  String get reviewRequired => 'Needs review';

  @override
  String get reviewRequiredHelp =>
      'The bot finishes in review instead of done.';

  @override
  String get comments => 'Comments';

  @override
  String get addComment => 'Add a comment';

  @override
  String get sendComment => 'Send';

  @override
  String get openThread => 'Open the bot\'s thread';

  @override
  String get deleteTicket => 'Delete ticket';

  @override
  String get noTickets => 'No tickets yet';

  @override
  String get noTicketsHelp =>
      'Add a ticket and assign it to a bot to get it started, or ask a bot to plan work here.';

  @override
  String get ticketStatus => 'Status';

  @override
  String get spaces => 'Workspaces';

  @override
  String get newWorkspace => 'New workspace';

  @override
  String get joinWorkspaceHelp => 'Paste the invite link someone sent you.';

  @override
  String get inviteLinkField => 'Invite link';

  @override
  String get workspaceIcon => 'Icon';

  @override
  String get workspaceColor => 'Color';

  @override
  String get workspaceSettings => 'Workspace settings';

  @override
  String get workspaceSettingsHelp => 'Name, icon, color and invite links';

  @override
  String get inviteLinks => 'Invite links';

  @override
  String get inviteLinksHelp =>
      'Anyone with a link can join after signing in, until it expires, runs out of uses or you revoke it.';

  @override
  String get createInviteLink => 'Create a link';

  @override
  String get inviteRole => 'Joins as';

  @override
  String get linkExpires => 'Expires';

  @override
  String get linkNever => 'Never';

  @override
  String linkDays(String days) {
    return 'In $days days';
  }

  @override
  String get linkMaxUses => 'Uses';

  @override
  String get linkUnlimited => 'Unlimited';

  @override
  String linkUses(String uses) {
    return '$uses used';
  }

  @override
  String get linkRevoked => 'Revoked';

  @override
  String get revokeLink => 'Revoke';

  @override
  String get linkCopied => 'Invite link copied.';

  @override
  String get joiningWorkspace => 'Joining the workspace…';

  @override
  String joinedWorkspace(String name) {
    return 'You joined $name.';
  }

  @override
  String get joinFailed =>
      'This invite link doesn\'t work anymore. Ask for a new one.';

  @override
  String get joinWithLink => 'Join with a link';

  @override
  String get botFolder => 'Folder';

  @override
  String get noFolder => 'No folder';

  @override
  String get newFolder => 'New folder…';

  @override
  String get folderName => 'Folder name';

  @override
  String get archiveBot => 'Archive bot';

  @override
  String archiveBotTitle(String name) {
    return 'Archive $name?';
  }

  @override
  String get archiveBotBody =>
      'It leaves the sidebar and stops running. Its chats and history are kept, and you can bring it back from Archived bots.';

  @override
  String get archive => 'Archive';

  @override
  String get archivedBots => 'Archived bots';

  @override
  String get unarchive => 'Bring back';

  @override
  String botArchived(String name) {
    return '$name archived.';
  }

  @override
  String get settingsHistory => 'Settings history';

  @override
  String get settingsHistoryHelp =>
      'Every change to this bot\'s settings, and who made it';

  @override
  String get noHistory => 'No changes yet.';

  @override
  String get restoreSettings => 'Restore these settings';

  @override
  String restoreSettingsBody(String fields) {
    return 'Put back $fields as they were before this change? The current settings stay in the history.';
  }

  @override
  String changedByBot(String name) {
    return 'Changed by $name';
  }

  @override
  String get changedByPerson => 'Changed by a person';

  @override
  String get changedBySystem => 'Changed by Kasama';

  @override
  String get fieldName => 'name';

  @override
  String get fieldInstructions => 'instructions';

  @override
  String get fieldModel => 'model';

  @override
  String get fieldAutonomy => 'autonomy';

  @override
  String get fieldBudget => 'budget';

  @override
  String get fieldComputer => 'computer';

  @override
  String get fieldArchived => 'archived';

  @override
  String secretRequestTitle(String bot, String service) {
    return '$bot needs a $service key';
  }

  @override
  String secretRequestHosts(String hosts) {
    return 'Only for $hosts';
  }

  @override
  String get secretRequestHelp =>
      'Goes straight to the vault. The bot never sees it.';

  @override
  String secretSaved(String name) {
    return 'Saved $name';
  }

  @override
  String get secretDeclined => 'Declined';

  @override
  String get decline => 'Decline';

  @override
  String get signInCode => 'Sign-in code';

  @override
  String get secretKindValue => 'Key or password';

  @override
  String get totpSeedLabel => 'Two-step key or otpauth:// link';

  @override
  String get totpSeedHelp =>
      'From the site\'s two-step setup. Bots only ever get the current code, never the key.';

  @override
  String get scanQrCode => 'Scan QR code';

  @override
  String totpRequestTitle(String bot, String service) {
    return '$bot needs a $service sign-in code';
  }

  @override
  String get search => 'Search';

  @override
  String get searchHint => 'Search chats, memories, skills, tickets and files';

  @override
  String get searchEmptyPrompt => 'Type at least 2 characters.';

  @override
  String searchNoResults(String query) {
    return 'Nothing found for “$query”.';
  }

  @override
  String get searchMessages => 'Messages';

  @override
  String get searchChats => 'Chats';

  @override
  String get searchTickets => 'Tickets';

  @override
  String get searchFiles => 'Files';

  @override
  String get searchFilesAsleep =>
      'Files on sleeping computers aren\'t searched. Start a computer to include its files.';

  @override
  String get installFor => 'Install for';

  @override
  String get wholeWorkspace => 'The whole workspace';

  @override
  String get skillCatalog => 'Skill catalog';

  @override
  String get searchSkills => 'Search skills';

  @override
  String get all => 'All';

  @override
  String skillFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files',
      one: '1 file',
    );
    return '$_temp0';
  }

  @override
  String get install => 'Install';

  @override
  String skillInstalled(String name) {
    return 'Installed $name.';
  }

  @override
  String get noResults => 'No results.';

  @override
  String get importFromGitHub => 'Import from GitHub';

  @override
  String get importFromGitHubHelp =>
      'Paste a link to a folder with a SKILL.md. You\'ll see every file before anything is installed. Private repositories use a GITHUB_TOKEN secret allowed for api.github.com.';

  @override
  String get preview => 'Preview';

  @override
  String get skillScriptsNote =>
      'Scripts in a skill only ever run on a bot\'s computer, never on the server.';

  @override
  String get binaryFile => '(binary file)';

  @override
  String skillUpdate(String name) {
    return 'Update $name';
  }

  @override
  String get checkingForUpdates => 'Checking for updates…';

  @override
  String get skillUpToDate => 'Already up to date.';

  @override
  String get update => 'Update';

  @override
  String get filesAdded => 'Added';

  @override
  String get filesChanged => 'Changed';

  @override
  String get filesRemoved => 'Removed';

  @override
  String get fromCatalog => 'From the catalog';

  @override
  String get savedByBot => 'Saved by a bot';

  @override
  String get checkForUpdates => 'Check for updates';

  @override
  String get attachSkill => 'Attach a skill';

  @override
  String setupTitle(String name) {
    return 'Set up $name';
  }

  @override
  String get setupBody =>
      'Answer a few quick questions and it will propose its instructions, routines and the accounts to connect. Nothing changes until you approve.';

  @override
  String get startSetup => 'Start setup';

  @override
  String get skipSetup => 'Skip for now';

  @override
  String get rerunSetup => 'Run setup again';

  @override
  String get rerunSetupHelp =>
      'Answer the setup questions again and review a new proposal';

  @override
  String get trace => 'Trace';

  @override
  String get openTrace => 'Open trace';

  @override
  String get editMessage => 'Edit';

  @override
  String get editMessageHelp =>
      'Sending reruns the conversation from here. The original version stays; switch with the arrows.';

  @override
  String get previousVersion => 'Previous version';

  @override
  String get nextVersion => 'Next version';

  @override
  String get quietHours => 'Quiet hours';

  @override
  String get quietHoursHelp =>
      'Notifications wait until quiet hours end; your inbox still fills. Approvals for a chat you\'re in still come through.';

  @override
  String quietHoursRange(String start, String end) {
    return '$start to $end';
  }

  @override
  String get off => 'Off';

  @override
  String get botNotifications => 'Notifications from this bot';

  @override
  String get botNotificationsHelp =>
      'Whether this bot follows your quiet hours';

  @override
  String get quietDefault => 'Follow my quiet hours';

  @override
  String get quietAlways => 'Always notify me';

  @override
  String get quietCustom => 'Its own quiet hours';

  @override
  String get from => 'From';

  @override
  String get until => 'Until';

  @override
  String get shareAsTemplate => 'Share as template';

  @override
  String get shareAsTemplateRow =>
      'A file or link with its instructions, skills and routines';

  @override
  String get shareAsTemplateHelp =>
      'Includes instructions, skills, routines and the services it uses. Never keys or secrets.';

  @override
  String get copyLink => 'Copy link';

  @override
  String get includeMemories => 'Include memories';

  @override
  String get includeMemoriesHelp =>
      'What it has learned about you and your work. Leave off unless you trust who you share with.';

  @override
  String get saveAsFile => 'Save as file';

  @override
  String get notABotTemplate => 'That file isn\'t a Kasama bot template.';

  @override
  String get importBot => 'Import a bot';

  @override
  String botImported(String name) {
    return '$name is ready.';
  }

  @override
  String botImportedConnect(String name, String services) {
    return '$name is ready. Connect $services in Integrations so it can use them.';
  }

  @override
  String get whatComesWithIt => 'What comes with it';

  @override
  String get connectAfterImport => 'Connect after importing';

  @override
  String get importRoutines => 'Schedule its routines';

  @override
  String importMemories(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Keep its $count memories',
      one: 'Keep its 1 memory',
    );
    return '$_temp0';
  }

  @override
  String get startingRoutine => 'Starting the routine…';

  @override
  String get offlineSaved => 'Offline. Showing saved messages.';

  @override
  String get projects => 'Projects';

  @override
  String get newProject => 'New project';

  @override
  String get noProjects => 'No projects yet';

  @override
  String get projectsHelp =>
      'Give a bot a goal. It drafts a plan for you to approve, then works in sessions until it\'s done, within the budget and deadline you set.';

  @override
  String get newProjectHelp =>
      'The lead bot drafts milestones and tickets. Nothing starts until you approve the plan.';

  @override
  String get startPlanning => 'Start planning';

  @override
  String get projectTitle => 'Title';

  @override
  String get projectGoal => 'Goal';

  @override
  String get projectDoneWhen => 'Done when';

  @override
  String get projectLead => 'Lead bot';

  @override
  String get projectBudget => 'Budget';

  @override
  String get projectThread => 'Project chat';

  @override
  String get approvePlan => 'Approve the plan';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Resume';

  @override
  String get milestones => 'Milestones';

  @override
  String get needsSignoff => 'needs your sign-off';

  @override
  String get signOff => 'Sign off';

  @override
  String get projectPlan => 'Plan';

  @override
  String get tickets => 'Tickets';

  @override
  String get projectTimeline => 'Timeline';

  @override
  String get projectPlanning => 'Planning';

  @override
  String get projectActive => 'Active';

  @override
  String get projectPaused => 'Paused';

  @override
  String get projectBlocked => 'Blocked';

  @override
  String get projectDone => 'Done';

  @override
  String get projectCancelled => 'Cancelled';

  @override
  String get forYou => 'For you';

  @override
  String get forYouEmpty => 'Nothing for you right now';

  @override
  String get forYouEmptyHelp =>
      'Turn on check-ins in a bot\'s settings for a morning brief and suggestions through the day.';

  @override
  String morningBriefFrom(String name) {
    return 'Morning brief from $name';
  }

  @override
  String get suggestions => 'Suggestions';

  @override
  String suggestedBy(String name) {
    return 'Suggested by $name';
  }

  @override
  String get dismissSuggestion => 'Dismiss this suggestion?';

  @override
  String get justThisOnce => 'Just this once';

  @override
  String get dontSuggestAgain => 'Don\'t suggest it again';

  @override
  String get doIt => 'Do it';

  @override
  String get checkins => 'Check-ins';

  @override
  String get checkinsHelp =>
      'A morning brief and a look every few hours for things that need you. Off by default.';

  @override
  String get briefTime => 'Morning brief at';

  @override
  String get scanEvery => 'Look every';

  @override
  String hours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours',
      one: '1 hour',
    );
    return '$_temp0';
  }

  @override
  String get dailyCap => 'Daily limit';

  @override
  String get on => 'On';

  @override
  String get actionRules => 'Action rules';

  @override
  String get actionRulesRow => 'What it may do without asking';

  @override
  String get actionRulesHelp =>
      'Rules decide per action: allow, allow within limits, ask first, or hand it to you to finish. The most specific rule wins; with no rule, the bot\'s autonomy decides. Bots can\'t change their own rules.';

  @override
  String get addRule => 'Add a rule';

  @override
  String get addRuleHelp =>
      'Pick what the bot is doing and how it should handle it.';

  @override
  String get noRules => 'No rules yet. The bot\'s autonomy level decides.';

  @override
  String get otherTools => 'Specific tools';

  @override
  String get workspaceRule => 'Workspace rule';

  @override
  String get catSend => 'Sending messages';

  @override
  String get catPay => 'Payments';

  @override
  String get catDelete => 'Deleting';

  @override
  String get catPublish => 'Publishing';

  @override
  String get catShare => 'Sharing and invites';

  @override
  String get catSignIn => 'Signing in';

  @override
  String get whenTheBot => 'When the bot is';

  @override
  String get itShould => 'It should';

  @override
  String get ruleAllow => 'Go ahead';

  @override
  String get ruleAllowLimits => 'Go ahead within limits';

  @override
  String get ruleAsk => 'Ask me first';

  @override
  String get ruleHandOff => 'Hand it to me to finish';

  @override
  String get ruleDomains => 'Only to these domains (comma separated)';

  @override
  String get ruleMaxAmount => 'Up to this amount';

  @override
  String get ruleForWorkspace => 'For every bot in the workspace';

  @override
  String get watchers => 'Watchers';

  @override
  String get watchersRow => 'What it\'s keeping an eye on';

  @override
  String get noWatchers => 'Not watching anything';

  @override
  String get watchersHelp =>
      'Ask the bot \"tell me when…\" and it watches a page, a reply, a result or a time. Checks cost nothing until something changes.';

  @override
  String get watcherActive => 'Watching';

  @override
  String get watcherPaused => 'Paused';

  @override
  String get watcherDone => 'Done';

  @override
  String get watcherExpired => 'Expired';

  @override
  String firedTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'fired $count times',
      one: 'fired once',
      zero: 'not fired yet',
    );
    return '$_temp0';
  }

  @override
  String get connectAiApp => 'Connect an AI app';

  @override
  String connectAiAppAsk(String app) {
    return '$app wants to use Kasama';
  }

  @override
  String connectAiAppHelp(String host) {
    return 'It can list your bots, ask them to do things and read results in the workspace you pick, as you. Your bots\' approvals and rules still apply. You\'ll go back to $host.';
  }

  @override
  String get connectAiAppDone => 'Done. You can go back to the AI app.';

  @override
  String get refuse => 'Refuse';

  @override
  String get allow => 'Allow';

  @override
  String get connectAiApps => 'Connect AI apps';

  @override
  String get connectAiAppsHelp =>
      'Apps that support MCP connect to this address and sign in, or use an API key. They act as the person who connected them.';

  @override
  String get mcpApprovals => 'Allow approvals from AI apps';

  @override
  String get mcpApprovalsHelp =>
      'Connected apps can approve or deny your bots\' actions. Off by default.';

  @override
  String get apiKeyOnce => 'Copy this key now; it won\'t be shown again.';

  @override
  String get newApiKey => 'New API key';

  @override
  String get apiKeyName => 'Name';
}
