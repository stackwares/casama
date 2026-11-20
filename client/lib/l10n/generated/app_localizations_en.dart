// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Casama';

  @override
  String tabTitle(String page, String app) {
    return '$page · $app';
  }

  @override
  String tabTitleBotPage(String page, String bot) {
    return '$page · $bot';
  }

  @override
  String get tabTitleChat => 'Chat';

  @override
  String get tabTitleCall => 'Call';

  @override
  String get tabTitleProject => 'Project';

  @override
  String get tabTitleGroupChat => 'Group chat';

  @override
  String get loading => 'Loading…';

  @override
  String get retry => 'Try Again';

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
  String get errorViewHint => 'Restarting the app should fix it.';

  @override
  String get signInTitle => 'Sign in to Casama';

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
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get continueWithEmail => 'Continue with Email';

  @override
  String get moreSignInOptions => 'More Options';

  @override
  String get usePasswordInstead => 'Use a Password Instead';

  @override
  String get checkInboxTitle => 'Check your inbox';

  @override
  String checkInboxBody(String email) {
    return 'We sent a sign-in link and a 6-digit code to $email. Tap the link, or type the code here.';
  }

  @override
  String get emailCodeLabel => '6-digit code';

  @override
  String get resendLink => 'Send Again';

  @override
  String resendLinkIn(int seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return 'Send Again in ${secondsString}s';
  }

  @override
  String get useDifferentEmail => 'Use a Different Email';

  @override
  String get authWrongPassword =>
      'That email and password don\'t match. Try again, or sign in with an email link instead.';

  @override
  String get authEmailNotConfirmed =>
      'Confirm your email first: open the link we sent you.';

  @override
  String get authCodeInvalid =>
      'That code is wrong or has expired. Check the latest email, or send a new one.';

  @override
  String get authTooManyTries => 'Too many tries. Wait a minute and try again.';

  @override
  String get authAccountExists =>
      'There\'s already an account with this email. Sign in instead.';

  @override
  String get authSignupDisabled => 'This server isn\'t taking new sign-ups.';

  @override
  String get useMagicLinkInstead => 'Email Me a Link Instead';

  @override
  String get invalidEmail => 'Enter a valid email address';

  @override
  String get passwordTooShort => 'Use at least 6 characters';

  @override
  String get signOut => 'Sign Out';

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
  String get testKey => 'Test Key';

  @override
  String keyOk(String model, int ms) {
    final intl.NumberFormat msNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String msString = msNumberFormat.format(ms);

    return 'Key works ($model, $msString ms)';
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
  String get navComputer => 'Computer';

  @override
  String get navChats => 'Chats';

  @override
  String get navTasks => 'Tasks';

  @override
  String get settingsConnectionsSection => 'Connections';

  @override
  String get advanced => 'Advanced';

  @override
  String get settingsAdvancedSummary => 'Secrets, computers, devices';

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
  String get newChat => 'New chat';

  @override
  String get conversations => 'Conversations';

  @override
  String messageHint(String bot) {
    return 'Message $bot';
  }

  @override
  String messageHintWithApps(String bot) {
    return 'Message $bot · @ to mention an app';
  }

  @override
  String get mentionSectionBots => 'Bots';

  @override
  String get mentionSectionApps => 'Apps';

  @override
  String get mentionSectionAddToBot => 'Add to this bot';

  @override
  String get mentionSectionConnect => 'Connect';

  @override
  String get mentionSectionStartGroup => 'Start a group chat';

  @override
  String get mentionBadgeBot => 'Bot';

  @override
  String get mentionBadgeApp => 'App';

  @override
  String get mentionAddAction => 'Add';

  @override
  String get mentionConnectAction => 'Connect';

  @override
  String get mentionMaxApps => 'You can mention up to 3 apps per message.';

  @override
  String get mentionRemovedApp => 'Removed app';

  @override
  String get send => 'Send';

  @override
  String get stop => 'Stop';

  @override
  String get thinking => 'Thinking…';

  @override
  String get checkingItsWork => 'Checking its work…';

  @override
  String get mapFullScreen => 'Full screen';

  @override
  String get mapTitle => 'Map';

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
  String get terminalReconnecting => 'Server restarting, reconnecting…';

  @override
  String get memory => 'Memory';

  @override
  String get noMemories => 'Nothing remembered yet.';

  @override
  String get searchMemories => 'Memories';

  @override
  String get noMemoriesMatch => 'No memories match.';

  @override
  String get clearSearch => 'Clear';

  @override
  String get addMemory => 'Add a Memory';

  @override
  String get addMemoryHelp =>
      'Something the bot should always know about you or your work.';

  @override
  String get addMemoryFactHint =>
      'For example: Our fiscal year starts in April.';

  @override
  String get addMemoryPreferenceHint =>
      'For example: Keep summaries under five bullet points.';

  @override
  String get memoryAdded => 'Memory added';

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
  String get moreProviders => 'More providers';

  @override
  String get integrationsAdvancedSummary =>
      'Composio, Pipedream, custom servers';

  @override
  String get toolPermissions => 'Tool permissions';

  @override
  String get devicesAdvancedSummary =>
      'How long it\'s kept, private models, bots with access';

  @override
  String get companionAdvancedSummary =>
      'Commands, local tools (MCP), coding agents';

  @override
  String get noKeys => 'No model keys yet.';

  @override
  String get addKey => 'Add Key';

  @override
  String get usage => 'Usage';

  @override
  String get language => 'Language';

  @override
  String inviteSent(String email) {
    return 'Invite sent to $email.';
  }

  @override
  String get botProfile => 'Bot profile';

  @override
  String get groupMembers => 'Bots in This Chat';

  @override
  String get groupMembersHelp =>
      'Each keeps its own memory and settings. Tap one to open its profile.';

  @override
  String get botAdvancedSummary =>
      'Chat apps, links, rules, watchers, plugins, activity';

  @override
  String get botActivityRow => 'Every run, step by step';

  @override
  String get createBotAdvancedSummary => 'Model key and model';

  @override
  String get botProfileSection => 'Profile';

  @override
  String get botBrain => 'Brain';

  @override
  String get botAbilities => 'Abilities';

  @override
  String get botSchedule => 'Schedule';

  @override
  String get chatComputerLive => 'Working on its computer';

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
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String hoursAgo(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString days ago',
      one: 'yesterday',
    );
    return '$_temp0';
  }

  @override
  String get aBot => 'A bot';

  @override
  String get addIntegration => 'Add Integration';

  @override
  String get addSecret => 'Add secret';

  @override
  String get allowedHosts => 'Allowed hosts';

  @override
  String get allowedHostsHelp => 'Comma-separated, for example api.github.com';

  @override
  String get alwaysAllow => 'Always Allow';

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
  String get composioToolkits =>
      'Toolkits (comma-separated, for example github, gmail)';

  @override
  String get copySecret => 'Copy Secret';

  @override
  String get cronExpression => 'Cron expression';

  @override
  String get cronHelp => 'minute hour day month weekday';

  @override
  String get denied => 'Denied';

  @override
  String get deny => 'Deny';

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
  String get markAllRead => 'Mark All as Read';

  @override
  String get newRoutine => 'New routine';

  @override
  String get noIntegrationsForBot =>
      'Add integrations in Settings first, then turn them on for this bot here.';

  @override
  String get noRoutines => 'No routines yet';

  @override
  String get noSecrets =>
      'No secrets yet. Bots reference them by name, and each one only goes to the hosts you allow.';

  @override
  String get notifications => 'Notifications';

  @override
  String get openInbox => 'Open Inbox';

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
  String get routineEditTitle => 'Edit Routine';

  @override
  String get routineEditSubtitle => 'Change what it does and when it runs.';

  @override
  String get routineRecentRuns => 'Recent runs';

  @override
  String get routineNoRuns => 'It hasn\'t run yet.';

  @override
  String get routineSaved => 'Routine saved';

  @override
  String get routineStarted => 'Routine started';

  @override
  String get routineWebhook => 'On webhook';

  @override
  String get routines => 'Routines';

  @override
  String get routineAdvancedSummary =>
      'GitHub and webhook triggers, cron, timezone';

  @override
  String get routineRepeatDaily => 'Every day';

  @override
  String get routineRepeatWeekdays => 'Weekdays';

  @override
  String get routineRepeatWeekly => 'Every week';

  @override
  String get routineDay => 'Day';

  @override
  String get routineTimeLabel => 'Time';

  @override
  String get routineRunsAt => 'Runs at';

  @override
  String routineTimesIn(String timezone) {
    return 'Times are in $timezone';
  }

  @override
  String routineCustomSchedule(String schedule) {
    return 'Custom: $schedule';
  }

  @override
  String get routineOtherTriggers => 'Other triggers';

  @override
  String cronEveryMinutes(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Every $nString minutes',
      one: 'Every minute',
    );
    return '$_temp0';
  }

  @override
  String cronEveryHours(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Every $nString hours',
      one: 'Every hour',
    );
    return '$_temp0';
  }

  @override
  String cronHourlyAt(String minute) {
    return 'Every hour at :$minute';
  }

  @override
  String cronDailyAt(String time) {
    return 'Every day at $time';
  }

  @override
  String cronWeekdaysAt(String time) {
    return 'Weekdays at $time';
  }

  @override
  String cronWeekendsAt(String time) {
    return 'Weekends at $time';
  }

  @override
  String cronDaysAt(String days, String time) {
    return '$days at $time';
  }

  @override
  String cronMonthlyAt(int day, String time) {
    return 'Day $day of every month at $time';
  }

  @override
  String cronAnd(String items, String last) {
    return '$items and $last';
  }

  @override
  String cronDays(String day) {
    String _temp0 = intl.Intl.selectLogic(day, {
      'sun': 'Sundays',
      'mon': 'Mondays',
      'tue': 'Tuesdays',
      'wed': 'Wednesdays',
      'thu': 'Thursdays',
      'fri': 'Fridays',
      'sat': 'Saturdays',
      'other': '$day',
    });
    return '$_temp0';
  }

  @override
  String cronDay(String day) {
    String _temp0 = intl.Intl.selectLogic(day, {
      'sun': 'Sunday',
      'mon': 'Monday',
      'tue': 'Tuesday',
      'wed': 'Wednesday',
      'thu': 'Thursday',
      'fri': 'Friday',
      'sat': 'Saturday',
      'other': '$day',
    });
    return '$_temp0';
  }

  @override
  String get headlessScreenNoteSettings =>
      'This computer has no desktop, so this shows its browser (blank until the bot opens a page). To watch and control apps live, switch it to a desktop in computer settings.';

  @override
  String get openComputerSettings => 'Open Computer Settings';

  @override
  String get runNow => 'Run Now';

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
  String get webhookCreated => 'Webhook Created';

  @override
  String get webhookSecret => 'Signing secret';

  @override
  String get webhookShownOnce =>
      'Copy the signing secret now. It is shown only once.';

  @override
  String get webhookUrl => 'URL';

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
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Connected, $nString tools',
      one: 'Connected, 1 tool',
    );
    return '$_temp0';
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
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString tools',
      one: '1 tool',
    );
    return '$_temp0';
  }

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
  String get renameTopic => 'Rename';

  @override
  String get library => 'Library';

  @override
  String get navLibrary => 'Library';

  @override
  String get librarySearchHint => 'Search the Library';

  @override
  String get libraryFilterAll => 'All';

  @override
  String get libraryFilterPages => 'Sites & games';

  @override
  String get libraryFilterImages => 'Images';

  @override
  String get libraryFilterVideos => 'Videos';

  @override
  String get libraryFilterAudio => 'Audio';

  @override
  String get libraryFilterDocuments => 'Documents';

  @override
  String get libraryFilterFiles => 'Files';

  @override
  String get creationKindPage => 'Page';

  @override
  String get creationKindImage => 'Image';

  @override
  String get creationKindVideo => 'Video';

  @override
  String get creationKindAudio => 'Audio';

  @override
  String get creationKindDocument => 'Document';

  @override
  String get creationKindFile => 'File';

  @override
  String get libraryPinned => 'Pinned';

  @override
  String get libraryToday => 'Today';

  @override
  String get libraryYesterday => 'Yesterday';

  @override
  String get libraryThisWeek => 'This week';

  @override
  String get libraryEarlier => 'Earlier';

  @override
  String get videoCantPlay => 'This video won\'t play on this device.';

  @override
  String get libraryEmptyTitle => 'What should we make first?';

  @override
  String get libraryEmptyBody =>
      'Pick one and your bot gets started. Everything your bots make lands here on its own.';

  @override
  String get libraryNoMatch => 'Nothing here matches.';

  @override
  String get libraryStarterGame => 'A small game';

  @override
  String get libraryStarterGamePrompt =>
      'Make me a small game I can play in the browser.';

  @override
  String get libraryStarterLogo => 'A logo';

  @override
  String get libraryStarterLogoPrompt => 'Design a logo for my project.';

  @override
  String get libraryStarterSite => 'A one-page site';

  @override
  String get libraryStarterSitePrompt =>
      'Make a one-page website for my business.';

  @override
  String get libraryStarterVideo => 'A short video';

  @override
  String get libraryStarterVideoPrompt => 'Make a short video of ';

  @override
  String get libraryStarterCard => 'A birthday card';

  @override
  String get libraryStarterCardPrompt => 'Make a birthday card for ';

  @override
  String get libraryStarterReport => 'A report';

  @override
  String get libraryStarterReportPrompt => 'Research and write a report on ';

  @override
  String get libraryStarterElse => 'Something else…';

  @override
  String get creationOpen => 'Open';

  @override
  String get creationPlay => 'Play';

  @override
  String get creationView => 'View';

  @override
  String get creationChangeIt => 'Change It';

  @override
  String creationChangeDraft(String title) {
    return 'About “$title”: ';
  }

  @override
  String creationMadeBy(String bot) {
    return 'Made by $bot';
  }

  @override
  String creationVersion(int n) {
    return 'version $n';
  }

  @override
  String creationFromChat(String bot) {
    return 'From your chat with $bot';
  }

  @override
  String creationFromBot(String bot) {
    return 'Made by $bot';
  }

  @override
  String get creationFromHelp => 'Go to the conversation';

  @override
  String get creationDetails => 'Details';

  @override
  String get creationAlongside => 'Made alongside';

  @override
  String creationDeleted(String title) {
    return 'Deleted “$title”';
  }

  @override
  String get showInLibrary => 'Show in Library';

  @override
  String get creationWhoCanSee => 'Who Can See It';

  @override
  String get libraryTile => 'Library';

  @override
  String get libraryTileHelp => 'What it made';

  @override
  String get regenerateReply => 'Regenerate';

  @override
  String get deleteMessage => 'Delete Message';

  @override
  String get deleteMessageTitle => 'Delete this message?';

  @override
  String get deleteMessageBody =>
      'It\'s removed for everyone in this chat. The messages around it stay.';

  @override
  String get messageDeleted => 'Message deleted';

  @override
  String get findInChat => 'Find in Chat';

  @override
  String get findInChatHint => 'Find in this chat';

  @override
  String findInChatCount(int index, int count) {
    return '$index of $count';
  }

  @override
  String get findInChatNone => 'No matches';

  @override
  String get findPrevious => 'Previous match';

  @override
  String get findNext => 'Next match';

  @override
  String get closeFind => 'Close find';

  @override
  String get pinTopic => 'Pin';

  @override
  String get unpinTopic => 'Unpin';

  @override
  String get inAppAlertReview => 'Review';

  @override
  String get forBot => 'For bot';

  @override
  String get handBack => 'Hand Back';

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
  String get openLiveView => 'Open Live View';

  @override
  String get liveExpand => 'Full screen';

  @override
  String get liveCopy => 'Copy';

  @override
  String get liveScreenshot => 'Screenshot';

  @override
  String get liveScreenshots => 'Screenshots';

  @override
  String get liveScreenshotsHelp =>
      'Live video can\'t get through this network, so the screen updates about once a second.';

  @override
  String get liveReconnecting => 'Reconnecting…';

  @override
  String get liveReconnectingHelp =>
      'The live video was cut off (the server may be restarting). Trying again; screenshots show meanwhile.';

  @override
  String get liveTryAgain => 'Try again';

  @override
  String get liveDroppedHelp =>
      'The live video couldn\'t come back, so the screen updates about once a second. Tap Try again.';

  @override
  String get liveMore => 'More';

  @override
  String get liveSaveScreenshot => 'Save Screenshot';

  @override
  String get liveCopyFromComputer => 'Copy from the computer';

  @override
  String get livePasteToComputer => 'Paste onto the computer';

  @override
  String get liveRotateHint => 'Turn your phone sideways for a bigger screen';

  @override
  String get liveWatching => 'Watching';

  @override
  String get liveCopied => 'Copied from the computer.';

  @override
  String get liveNothingCopied =>
      'Nothing was copied. Select something on the computer first.';

  @override
  String get livePasteEmpty => 'Your clipboard is empty.';

  @override
  String get liveMinimize => 'Back to the side panel';

  @override
  String get liveShownFullScreen => 'The live view is open full screen.';

  @override
  String get liveStillWatching => 'Still watching?';

  @override
  String get liveStillWatchingHelp =>
      'The computer sleeps when nobody\'s watching, to save power.';

  @override
  String get liveKeepWatching => 'Keep Watching';

  @override
  String get livePausedToSavePower => 'Paused to save power';

  @override
  String get livePausedToSavePowerHelp =>
      'Nobody was watching, so the computer can rest. Resume wakes it again.';

  @override
  String get liveResume => 'Resume';

  @override
  String get paused => 'Paused';

  @override
  String get pausedUserInControl =>
      'Paused: a person is in control of the screen';

  @override
  String get letBotUseTerminal => 'Let it use terminal & files';

  @override
  String get screenHandedBack => 'Handed the screen back';

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
  String get switchToDesktop => 'Switch to Desktop';

  @override
  String get switchToHeadless => 'Switch to Headless';

  @override
  String get switchProfileConfirm =>
      'The computer restarts to switch. Your files are kept, but anything running on it now stops.';

  @override
  String get switchProfileButton => 'Switch';

  @override
  String get switchingToDesktop => 'Switching to Desktop…';

  @override
  String get switchingToHeadless => 'Switching to Headless…';

  @override
  String get switchedToDesktop =>
      'Switched to Desktop. Open Live View to watch its screen.';

  @override
  String get switchedToHeadless =>
      'Switched to Headless. It uses less memory now.';

  @override
  String get takeControl => 'Take Control';

  @override
  String get takeoverCompleted => 'Handed back';

  @override
  String get takeoverDismissed => 'Declined';

  @override
  String get takeoverPrivacy =>
      'While you\'re in control, the bot is paused and nothing you type or see is sent to it.';

  @override
  String get liveShellOnTooltip =>
      'Let the bot keep using its terminal and files while you\'re in control';

  @override
  String get liveShellOffTooltip =>
      'Pause the bot\'s terminal and files too while you\'re in control';

  @override
  String get liveShellOnNote =>
      'The bot can keep using its terminal and files. It still can\'t see or use the screen until you hand back.';

  @override
  String get liveShellOffNote => 'The bot is fully paused until you hand back.';

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
    final intl.NumberFormat msNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String msString = msNumberFormat.format(ms);

    return '$msString ms';
  }

  @override
  String privateComputerOf(String bot) {
    return '$bot\'s computer';
  }

  @override
  String get micPermissionNeeded => 'Allow microphone access to dictate.';

  @override
  String get dictationEmpty => 'No speech came through. Try again.';

  @override
  String get startCall => 'Start a voice call';

  @override
  String get stopDictation => 'Stop and transcribe';

  @override
  String get dictate => 'Dictate';

  @override
  String get dictateOnDevice => 'Dictate with this device';

  @override
  String get stopListening => 'Stop listening';

  @override
  String get dictationRetry => 'Try Again';

  @override
  String get dictationSayAgain => 'Say it again';

  @override
  String get dictationFailed => 'Couldn\'t turn that into text.';

  @override
  String get dictationFailedUseDevice =>
      'Couldn\'t turn that into text. Say it again and your device will listen.';

  @override
  String get dictationNoServiceUseDevice =>
      'Dictation isn\'t set up for this workspace. Your device can listen instead.';

  @override
  String get dictationDeviceFailed =>
      'Your device\'s dictation stopped working, so the mic is back on Casama\'s.';

  @override
  String get dictationDevicePermission =>
      'Allow speech recognition to dictate with this device.';

  @override
  String get readAloud => 'Read aloud';

  @override
  String get callConnecting => 'Connecting…';

  @override
  String get callLive => 'Live';

  @override
  String get callEnded => 'Call ended';

  @override
  String get callEndedIdle => 'Ended the call after 2 minutes of silence.';

  @override
  String get callFailed => 'The call could not connect.';

  @override
  String get callListening => 'Listening';

  @override
  String get callSpeaking => 'Speaking';

  @override
  String get callWorking => 'Working on it';

  @override
  String get callMutedState => 'Muted';

  @override
  String get callCaptions => 'Captions';

  @override
  String get callSpeaker => 'Speaker';

  @override
  String get callEarpiece => 'Phone';

  @override
  String get callBluetooth => 'Bluetooth';

  @override
  String get callHeadphones => 'Headphones';

  @override
  String get callAudioOutput => 'Play the call through';

  @override
  String toolDoing(String tool) {
    String _temp0 = intl.Intl.selectLogic(tool, {
      'profile_set_picture': 'Changing its picture',
      'memory_search': 'Searching your memories',
      'memory_write': 'Saving that to memory',
      'memory': 'Updating its memory',
      'knowledge_search': 'Looking through your knowledge',
      'web_search': 'Searching the web',
      'web': 'Reading a web page',
      'browser_open': 'Opening a website',
      'browser_click': 'Clicking on the page',
      'browser_type': 'Typing on the page',
      'browser_press': 'Pressing a key',
      'browser_scroll': 'Scrolling the page',
      'browser_look': 'Looking at the page',
      'desktop_click': 'Clicking on the screen',
      'desktop_type': 'Typing',
      'desktop_press': 'Pressing keys',
      'desktop_launch': 'Opening an app',
      'desktop_look': 'Looking at the screen',
      'shell': 'Working on its computer',
      'files_read': 'Reading a file',
      'files_write': 'Writing a file',
      'files_list': 'Looking through files',
      'files_search': 'Searching files',
      'files_from_chat': 'Getting a file from the chat',
      'http': 'Contacting a service',
      'data_search': 'Looking for data',
      'data_call': 'Getting data',
      'skills_load': 'Getting a skill ready',
      'skills_create': 'Learning a new skill',
      'skills_update': 'Improving a skill',
      'checkpoint': 'Saving a restore point',
      'computer_restart': 'Restarting its computer',
      'takeover': 'Asking you to take over',
      'delegate': 'Asking a helper',
      'routines_list': 'Checking your routines',
      'routines_create': 'Setting up a routine',
      'routines_update': 'Updating a routine',
      'routines_delete': 'Removing a routine',
      'watchers_create': 'Setting up a watcher',
      'watchers_list': 'Checking your watchers',
      'watchers_delete': 'Removing a watcher',
      'tasks_list': 'Checking your tasks',
      'tasks_create': 'Adding a task',
      'tasks': 'Updating your tasks',
      'notify_user': 'Sending you a note',
      'usage_report': 'Checking usage',
      'device_read': 'Reading your device data',
      'device_access': 'Asking for device access',
      'pages_publish': 'Publishing a page',
      'pages': 'Updating a page',
      'media': 'Making an image',
      'media_video': 'Making a video',
      'bots_create': 'Making a new bot',
      'bots_update': 'Updating a bot',
      'bots_list': 'Checking your bots',
      'bots_archive': 'Archiving a bot',
      'channel_send': 'Sending a message',
      'links_ask': 'Asking a contact\'s assistant',
      'logins_list': 'Checking saved logins',
      'replay_run': 'Repeating saved steps',
      'replay_save': 'Saving these steps',
      'setup_apply': 'Suggesting a setup',
      'sidebar_organize': 'Organizing your sidebar',
      'suggestions_add': 'Adding a suggestion',
      'teach_save_draft': 'Saving a draft skill',
      'welcome_name': 'Picking a name',
      'secrets_request': 'Asking you for a secret',
      'pages_list': 'Checking your pages',
      'pages_share': 'Changing who can see a page',
      'projects_create': 'Starting a project',
      'projects_status': 'Checking a project',
      'projects_update': 'Updating a project',
      'projects': 'Planning a project',
      'payments': 'Asking to make a payment',
      'voice_call': 'Calling a business',
      'voice_call_user': 'Calling you',
      'tools_load': 'Getting ready',
      'ui_show': 'Showing you something',
      'start_task': 'Starting this in the chat',
      'other': 'Working on it',
    });
    return '$_temp0';
  }

  @override
  String toolDid(String tool) {
    String _temp0 = intl.Intl.selectLogic(tool, {
      'profile_set_picture': 'Changed its picture',
      'memory_search': 'Searched your memories',
      'memory_write': 'Saved to memory',
      'memory': 'Updated its memory',
      'knowledge_search': 'Looked through your knowledge',
      'web_search': 'Searched the web',
      'web': 'Read a web page',
      'browser_open': 'Opened a website',
      'browser_click': 'Clicked on the page',
      'browser_type': 'Typed on the page',
      'browser_press': 'Pressed a key',
      'browser_scroll': 'Scrolled the page',
      'browser_look': 'Looked at the page',
      'desktop_click': 'Clicked on the screen',
      'desktop_type': 'Typed',
      'desktop_press': 'Pressed keys',
      'desktop_launch': 'Opened an app',
      'desktop_look': 'Looked at the screen',
      'shell': 'Worked on its computer',
      'files_read': 'Read a file',
      'files_write': 'Wrote a file',
      'files_list': 'Looked through files',
      'files_search': 'Searched files',
      'files_from_chat': 'Got a file from the chat',
      'http': 'Contacted a service',
      'data_search': 'Looked for data',
      'data_call': 'Got data',
      'skills_load': 'Used a skill',
      'skills_create': 'Learned a new skill',
      'skills_update': 'Improved a skill',
      'checkpoint': 'Saved a restore point',
      'computer_restart': 'Restarted its computer',
      'takeover': 'Asked you to take over',
      'delegate': 'Asked a helper',
      'routines_list': 'Checked your routines',
      'routines_create': 'Set up a routine',
      'routines_update': 'Updated a routine',
      'routines_delete': 'Removed a routine',
      'watchers_create': 'Set up a watcher',
      'watchers_list': 'Checked your watchers',
      'watchers_delete': 'Removed a watcher',
      'tasks_list': 'Checked your tasks',
      'tasks_create': 'Added a task',
      'tasks': 'Updated your tasks',
      'notify_user': 'Sent you a note',
      'usage_report': 'Checked usage',
      'device_read': 'Read your device data',
      'device_access': 'Asked for device access',
      'pages_publish': 'Published a page',
      'pages': 'Updated a page',
      'media': 'Made an image',
      'media_video': 'Made a video',
      'bots_create': 'Made a new bot',
      'bots_update': 'Updated a bot',
      'bots_list': 'Checked your bots',
      'bots_archive': 'Archived a bot',
      'channel_send': 'Sent a message',
      'links_ask': 'Asked a contact\'s assistant',
      'logins_list': 'Checked saved logins',
      'replay_run': 'Repeated saved steps',
      'replay_save': 'Saved these steps',
      'setup_apply': 'Suggested a setup',
      'sidebar_organize': 'Organized your sidebar',
      'suggestions_add': 'Added a suggestion',
      'teach_save_draft': 'Saved a draft skill',
      'welcome_name': 'Picked a name',
      'secrets_request': 'Asked you for a secret',
      'pages_list': 'Checked your pages',
      'pages_share': 'Changed who can see a page',
      'projects_create': 'Started a project',
      'projects_status': 'Checked a project',
      'projects_update': 'Updated a project',
      'projects': 'Planned a project',
      'payments': 'Asked to make a payment',
      'voice_call': 'Called a business',
      'voice_call_user': 'Called you',
      'tools_load': 'Got ready',
      'ui_show': 'Showed you something',
      'start_task': 'Started in the chat',
      'other': 'Done',
    });
    return '$_temp0';
  }

  @override
  String toolUsingApp(String app) {
    return 'Using $app';
  }

  @override
  String toolUsedApp(String app) {
    return 'Used $app';
  }

  @override
  String get toolDetails => 'Details';

  @override
  String approvalAsking(String bot) {
    return '$bot is asking first';
  }

  @override
  String get approvalLookClosely => 'Look closely before you allow this';

  @override
  String approvalDontAskAgain(String bot) {
    return 'Don\'t ask $bot again for this';
  }

  @override
  String get pageShareToPublic =>
      'Anyone with the link will be able to open it';

  @override
  String get pageShareToWorkspace =>
      'Everyone in this workspace will be able to open it';

  @override
  String get pageShareToPrivate => 'Only you will be able to open it';

  @override
  String approvalAllowedLine(String what) {
    return 'Allowed: $what';
  }

  @override
  String approvalDeclinedLine(String what) {
    return 'Declined: $what';
  }

  @override
  String approvalExpiredLine(String what) {
    return 'No answer in time: $what';
  }

  @override
  String get callToolFailed => 'That didn\'t work';

  @override
  String get callToolNeedsOk => 'Needs your OK to go ahead';

  @override
  String get callToolAllow => 'Allow';

  @override
  String get callToolNotNow => 'Not Now';

  @override
  String get callToolAllowed => 'Allowed. The result will show in the chat';

  @override
  String get callToolDeclined => 'You said not now';

  @override
  String get callToolBackground =>
      'Still working. The result will show in the chat';

  @override
  String get callToolInChat => 'The result will show in the chat';

  @override
  String callToolSeconds(int seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return '${secondsString}s';
  }

  @override
  String get callNeedsKeyTitle => 'Calls need a Google AI key';

  @override
  String get callNeedsKeyBody =>
      'Live calls run on Google\'s Gemini Live, so this workspace needs a Google AI key. It\'s only used for calls: read aloud, dictation, images and video run on OpenRouter. Google gives you one free in AI Studio: create it there, then add it under Model keys and calls work right away. Only workspace owners and admins can add keys.';

  @override
  String get callAddKey => 'Add a Google AI key';

  @override
  String get callGetFreeKey => 'Get a free key from Google';

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
  String callSwitchTitle(String from, String to) {
    return 'End call with $from and call $to?';
  }

  @override
  String get callSwitchBody =>
      'You can be on one call at a time. The current call is saved to its chat first.';

  @override
  String get callSwitchConfirm => 'End and Call';

  @override
  String get callEndedLost =>
      'The call ended because the connection was lost for too long.';

  @override
  String get callMinimize => 'Minimize';

  @override
  String get callEndCall => 'End Call';

  @override
  String get callEndAndAnswer => 'End and Answer';

  @override
  String get callReconnecting => 'Reconnecting…';

  @override
  String callMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes',
      one: '1 minute',
      zero: 'under a minute',
    );
    return '$_temp0';
  }

  @override
  String callBubbleLabel(String bot, String time) {
    return 'Call with $bot, $time, tap to return';
  }

  @override
  String callReturnBar(String bot) {
    return 'On a call with $bot, tap to return';
  }

  @override
  String get callOpen => 'Open Call';

  @override
  String get callOnHold => 'On hold';

  @override
  String get callNotificationLive => 'On a call';

  @override
  String get callNotificationMuted => 'Muted';

  @override
  String get callNotificationChannel => 'Calls';

  @override
  String callTabTitle(String time) {
    return 'On a call · $time';
  }

  @override
  String get callMenuShow => 'Show Call';

  @override
  String get callJobWorking => 'Working on it';

  @override
  String callJobStrip(String task) {
    return 'Working on: $task';
  }

  @override
  String callJobNeedsYou(String task) {
    return 'Needs you: $task';
  }

  @override
  String get callTileWatching => 'Live view';

  @override
  String get callTileDone => 'Done';

  @override
  String get callTileNeedsYou => 'Needs you';

  @override
  String callTileLabel(String state) {
    return 'The bot\'s screen, $state. Tap to see it full size';
  }

  @override
  String get callTileHide => 'Hide Screen';

  @override
  String callRecapTitle(String length) {
    return 'Call · $length';
  }

  @override
  String get callRecapStarted => 'Started on the call';

  @override
  String get callRecapTaskDone => 'Done';

  @override
  String get callRecapTaskFailed => 'Didn\'t finish';

  @override
  String get callRecapTaskStopped => 'Stopped';

  @override
  String get callRecapTaskRunning => 'Still working';

  @override
  String get callRecapOpenRun => 'See what it did';

  @override
  String get summarizeCalls => 'Summarize calls';

  @override
  String get summarizeCallsHelp =>
      'After each call, its card says what it was about and what\'s next. Uses a little of the bot\'s small model.';

  @override
  String callCardVoice(String length) {
    return 'Voice call · $length';
  }

  @override
  String callCardPhone(String length) {
    return 'Phone call · $length';
  }

  @override
  String callCardDropped(String length) {
    return 'Call dropped · $length';
  }

  @override
  String callCardMissed(String name) {
    return 'Missed call from $name';
  }

  @override
  String callCardLive(String name) {
    return 'On a call with $name';
  }

  @override
  String get callCardLiveElsewhere => 'On a call on another device';

  @override
  String get callCardReturn => 'Return to call';

  @override
  String callCardBotHungUp(String name) {
    return '$name hung up';
  }

  @override
  String get callCardEndedQuiet => 'Ended after a quiet stretch';

  @override
  String get callCardEndedLimit => 'Ended at the call limit';

  @override
  String get callCardWritingSummary => 'Writing a summary…';

  @override
  String callCardSummaryBy(String name) {
    return 'Summary by $name';
  }

  @override
  String get callCardNextSteps => 'Next steps';

  @override
  String get callCardDoIt => 'Do it';

  @override
  String get callCardDismissStep => 'Dismiss';

  @override
  String get callCardStepStarted => 'Started';

  @override
  String get callCardStepFailed => 'Couldn\'t start that. Try again.';

  @override
  String get callCardDoneOnCall => 'Done on the call';

  @override
  String callCardMore(int count) {
    return '$count more';
  }

  @override
  String callCardTranscript(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Transcript · $count turns',
      one: 'Transcript · 1 turn',
    );
    return '$_temp0';
  }

  @override
  String get callCardTranscriptTitle => 'Transcript';

  @override
  String get callCardSearchTranscript => 'Search the transcript';

  @override
  String get callCardNoMatches => 'No matches';

  @override
  String get callCardYou => 'You';

  @override
  String get callCardCallBack => 'Call back';

  @override
  String get callCardCopy => 'Copy';

  @override
  String get callCardCopied => 'Copied';

  @override
  String get callCardShare => 'Share';

  @override
  String get callCardMoreActions => 'More';

  @override
  String get callCardDelete => 'Delete call';

  @override
  String get callCardDeleteTitle => 'Delete this call?';

  @override
  String get callCardDeleteBody =>
      'Its card and transcript are removed from this chat. Jobs it started keep their results.';

  @override
  String get callCardDeleted => 'Call deleted';

  @override
  String get callCardDeleteFailed => 'Couldn\'t delete the call';

  @override
  String callCardSemantics(String title, String summary) {
    return '$title. $summary';
  }

  @override
  String replyLatency(int ms) {
    final intl.NumberFormat msNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String msString = msNumberFormat.format(ms);

    return 'Reply started in $msString ms';
  }

  @override
  String get voiceSettings => 'Voice';

  @override
  String get voiceSettingsHelp =>
      'Read-aloud voice and the tools a bot has on calls';

  @override
  String get callTools => 'Tools on Calls';

  @override
  String get callToolsHelp =>
      'Calls already include memory, web search, notes to you, routines and tickets, and hand bigger jobs to the chat. Add connected-app tools the bot should use live; each one adds a little to every call\'s cost.';

  @override
  String get callToolsNone =>
      'This bot has no connected apps turned on yet. Turn one on in its Integrations, then pick its tools here.';

  @override
  String get openIntegrations => 'Open Integrations';

  @override
  String callToolsCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString connected-app tools added',
      one: '1 connected-app tool added',
      zero: 'Only the built-in voice tools',
    );
    return '$_temp0';
  }

  @override
  String get voiceId => 'Voice id (optional)';

  @override
  String get voiceIdHelp =>
      'A Gemini voice name, such as Kore or Puck; empty uses Kore';

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
  String get companionError => 'Cannot reach Casama; retrying';

  @override
  String get companionOff => 'Off';

  @override
  String get companionCapabilities => 'What Bots May Do';

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
  String get sharedFolders => 'Shared Folders';

  @override
  String get sharedFoldersHelp => 'Bots can only reach these folders.';

  @override
  String get addFolder => 'Add a Folder';

  @override
  String get botsAllowed => 'Bots Allowed';

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
  String get adminLockNow => 'Lock now';

  @override
  String get adminUnlock => 'Unlock admin console';

  @override
  String get adminLockedHelp =>
      'The admin console is locked. Verify your password or use a fresh email code. It locks after 5 minutes without activity and when you leave the app.';

  @override
  String get adminConfirmAction => 'Confirm admin action';

  @override
  String get adminConfirmActionHelp =>
      'This action changes the instance. Verify your password or a fresh email code to continue.';

  @override
  String get adminVerifyPassword => 'Verify password';

  @override
  String get adminSendCode => 'Send an email code';

  @override
  String get adminCodeSent =>
      'We sent a code to your account email. Enter it below to continue.';

  @override
  String get adminVerifyCode => 'Verify code';

  @override
  String get adminAuthenticationFailed =>
      'Could not verify your identity. Check your password or code and try again.';

  @override
  String get adminTwoStepHelp =>
      'Your account uses two-step sign-in. Enter the 6-digit code from your authenticator app to finish.';

  @override
  String get adminTwoStepTip =>
      'Tip: turn on two-step sign-in in Settings. Without it, anyone who can read your email on this device can unlock the console with an emailed code.';

  @override
  String get adminUnlockDevice => 'Use Face ID or screen lock';

  @override
  String get adminDeviceReason => 'Confirm it\'s you for the admin console';

  @override
  String get adminVerifyPasskey => 'Verify with a passkey';

  @override
  String get adminOrPassword => 'or use your password';

  @override
  String get adminPasskeyTip =>
      'Tip: add a passkey in Settings → Passkeys to verify with Face ID or a fingerprint instead of your password.';

  @override
  String get adminSecurity => 'Security';

  @override
  String get adminPinTitle => 'Admin PIN';

  @override
  String get adminPinSet => 'Set an admin PIN';

  @override
  String get adminPinChange => 'Change the admin PIN';

  @override
  String get adminPinRemove => 'Remove the admin PIN';

  @override
  String get adminPinHelp =>
      '6 digits to unlock the console and confirm changes, instead of your password. Five wrong tries turn it off.';

  @override
  String get adminPinOffHelp =>
      'Turned off after too many wrong tries. Set a new one.';

  @override
  String get adminPinSetupBody =>
      '6 digits for the admin console. Kept on your server, never on this device.';

  @override
  String get adminPinSaved => 'Admin PIN saved';

  @override
  String get adminPinRemoved => 'Admin PIN removed';

  @override
  String get adminPinLabel => 'Admin PIN';

  @override
  String adminPinWrong(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tries left',
      one: '1 try left',
    );
    return 'Wrong PIN. $_temp0.';
  }

  @override
  String get adminPinTurnedOff =>
      'Too many wrong PINs: the admin PIN is turned off. Use a passkey or your password, then set a new PIN under Security.';

  @override
  String get adminDeviceOfferTitle => 'Use Face ID next time?';

  @override
  String get adminDeviceOfferBody =>
      'Unlock the admin console and confirm changes with Face ID, a fingerprint or this phone\'s passcode. A key in this phone\'s secure chip proves it\'s you, and it never leaves the phone.';

  @override
  String get adminDeviceOfferNo => 'Not now';

  @override
  String get adminDeviceOfferYes => 'Turn on';

  @override
  String get adminDeviceSetupReason => 'Turn on Face ID for the admin console';

  @override
  String get adminDeviceOn => 'Face ID is on for the admin console';

  @override
  String get adminDeviceTitle => 'Face ID and screen lock';

  @override
  String get adminDeviceTurnOn => 'Use Face ID on this phone';

  @override
  String get adminDeviceHelp =>
      'Face ID, a fingerprint or the passcode unlocks the console and confirms changes, with no PIN or password.';

  @override
  String get adminDeviceThisOne => 'This phone';

  @override
  String get adminDeviceRemove => 'Remove';

  @override
  String get adminDeviceRemoved => 'Removed';

  @override
  String get adminOverview => 'Overview';

  @override
  String get adminUsers => 'Users';

  @override
  String get adminWorkspaces => 'Workspaces';

  @override
  String get adminServices => 'Services';

  @override
  String get cloudModelsTitle => 'Cloud Models';

  @override
  String get cloudModelsHelp => 'Applies to every Cloud server within seconds.';

  @override
  String get connectionsTitle => 'App Connections';

  @override
  String get connectionsServerComposio => 'Casama\'s Composio Account';

  @override
  String get connectionsServerComposioHelp =>
      'Apps without their own sign-in connect in one click through this server\'s Composio account.';

  @override
  String get connectionsOwnAccounts => 'People\'s Own Accounts';

  @override
  String get connectionsOwnAccountsHelp =>
      'Each person uses their own Composio, Pipedream or Zapier.';

  @override
  String get connectionsNoComposioKey =>
      'Add COMPOSIO_API_KEY to this server to use Casama\'s account.';

  @override
  String get connectionsGoogleTitle => 'Google Apps';

  @override
  String get connectionsGoogleComposio => 'Through Composio';

  @override
  String get connectionsGoogleComposioHelp =>
      'Gmail, Calendar, Drive and more work right away.';

  @override
  String get connectionsGoogleDirect => 'Google\'s Own Servers';

  @override
  String get connectionsGoogleDirectHelp =>
      'Needs Google Workspace Developer Preview enrollment.';

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
    return 'Casama $latest is available (you run $current)';
  }

  @override
  String casamaVersion(String version) {
    return 'Casama $version';
  }

  @override
  String workspacesCount(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString workspaces',
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
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString members',
      one: '1 member',
    );
    return '$_temp0';
  }

  @override
  String botsCount(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString bots',
      one: '1 bot',
    );
    return '$_temp0';
  }

  @override
  String cost30d(String usd) {
    return '$usd in 30 days';
  }

  @override
  String get connectingToServer => 'Connecting to Casama…';

  @override
  String get cannotReachServer => 'Can\'t reach your Casama server';

  @override
  String get connectionFailed =>
      'Couldn\'t reach your Casama server. Check your connection and try again.';

  @override
  String get serverNotResponding =>
      'Your Casama server isn\'t responding right now. Try again in a moment.';

  @override
  String cannotReachServerHelp(String url) {
    return 'Check your connection, or that the server at $url is running.';
  }

  @override
  String get serverUnreachableBody =>
      'Check that you\'re online. If you are, the server may be restarting, so we\'ll keep trying.';

  @override
  String retryingIn(int seconds) {
    return 'Trying again in ${seconds}s';
  }

  @override
  String get retryingNow => 'Trying…';

  @override
  String get upgradeTitle => 'Upgrade Your Plan';

  @override
  String get notNow => 'Not Now';

  @override
  String get seePlans => 'See plans';

  @override
  String get billing => 'Billing';

  @override
  String get billingOffSelfHosted =>
      'Billing is off on this server. Self-hosted Casama has no limits.';

  @override
  String get restorePurchases => 'Restore Purchases';

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
  String get subscribeOnWeb => 'Subscribe on the Web';

  @override
  String get credits => 'Credits';

  @override
  String get creditHistory => 'Credit History';

  @override
  String get creditReasonPurchase => 'Credits bought';

  @override
  String get creditReasonGrant => 'Credits added';

  @override
  String get creditReasonRefund => 'Refund';

  @override
  String get creditReasonAdjustment => 'Adjustment';

  @override
  String get creditReasonExpire => 'Credits expired';

  @override
  String limitBots(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString bots',
      one: '1 bot',
    );
    return '$_temp0';
  }

  @override
  String get limitBotsUnlimited => 'Unlimited bots';

  @override
  String get unlimitedValue => 'Unlimited';

  @override
  String trialDaysFree(int n) {
    return '$n days free';
  }

  @override
  String get extraPeople => 'Extra People';

  @override
  String extraPeopleHelp(String price, int seats) {
    return '$price per person a month, on top of the $seats your plan includes.';
  }

  @override
  String get extraPeopleSaved => 'Extra people updated';

  @override
  String limitComputerHours(int hours) {
    final intl.NumberFormat hoursNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String hoursString = hoursNumberFormat.format(hours);

    return '$hoursString computer hours a month';
  }

  @override
  String limitCredits(String amount) {
    return '$amount credits a month';
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
    return 'Credits: $amount';
  }

  @override
  String get manageSubscription => 'Manage Subscription';

  @override
  String usageComputerHours(String hours) {
    return 'Cloud computers: $hours h';
  }

  @override
  String usageLiveViewMinutes(String minutes) {
    return 'Live view: $minutes min';
  }

  @override
  String get thisMonth => 'This month';

  @override
  String get noBillableUsage => 'No billable usage yet.';

  @override
  String get linkCloud => 'Casama Link';

  @override
  String get linkCloudHelp =>
      'Connect a self-hosted Casama to this workspace. A public address and notifications are free; cloud computers and model credits are billed here.';

  @override
  String get linkCloudNewKey => 'New Casama Link Key';

  @override
  String get linkCloudKeyCreated => 'Key Created';

  @override
  String get linkCloudKeyOnce =>
      'Copy it now; it is shown only once. Set it on your server with CASAMA_CLOUD_URL.';

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
  String get changeServer => 'Use a Different Server';

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
  String get exportMyData => 'Export My Data';

  @override
  String get exportMyDataHelp =>
      'Bots, chats, runs, memories and settings. No secrets.';

  @override
  String exportReady(String kb) {
    return 'Export ready ($kb KB)';
  }

  @override
  String get runHistoryRetention => 'Keep Run History For';

  @override
  String get runHistoryRetentionHelp =>
      'Older run events are deleted automatically.';

  @override
  String days(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get deleteAccount => 'Delete My Account';

  @override
  String get deleteAccountHelp =>
      'Erases your data after a short grace period.';

  @override
  String get deleteAccountQuestion => 'Delete your account?';

  @override
  String deleteAccountConfirm(String email) {
    return 'Workspaces where you are the only owner are deleted with your account, including their bots and computers. Type $email to confirm.';
  }

  @override
  String get accountDeleted => 'Account Scheduled for Deletion';

  @override
  String accountDeletedBody(String date) {
    return 'You have been signed out. Your data will be erased on $date.';
  }

  @override
  String toolSteps(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString steps',
      one: '1 step',
    );
    return '$_temp0';
  }

  @override
  String showMoreSteps(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Show $countString earlier steps',
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
    return 'Ask $bot anything, or tap an idea below to get started.';
  }

  @override
  String get suggestPlanDay => 'Help me plan my day';

  @override
  String get suggestWriteMessage => 'Help me write a message';

  @override
  String get suggestExplain => 'Look something up and explain it simply';

  @override
  String get suggestCapabilities => 'What can you help me with?';

  @override
  String connectedAppSummary(String app) {
    return 'Connected $app';
  }

  @override
  String get connectAppsTitle => 'Connect your apps';

  @override
  String get moreApps => 'More';

  @override
  String addAppTile(String app) {
    return 'Add $app to this bot';
  }

  @override
  String appAddedToBot(String app, String bot) {
    return '$app added to $bot';
  }

  @override
  String get connectAppsHint =>
      'Let me read and act in the tools you already use.';

  @override
  String connectAppTile(String app) {
    return 'Connect $app';
  }

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
  String get notificationsPrimerBubble => 'Don\'t miss a thing!';

  @override
  String get notificationsPrimerTitle => 'Turn on notifications';

  @override
  String get notificationsPrimerBody =>
      'Your bots tell you when they need a decision from you, or when their work is ready.';

  @override
  String get notificationsPrimerBlockedBody =>
      'Chrome is blocking notifications for this site. Allow them from the lock in the address bar, then tap Turn on again.';

  @override
  String get notificationsTurnOn => 'Turn On';

  @override
  String get importAgentHelp =>
      'Bring a bot over from OpenClaw or Hermes Agent, or paste a setup from Grok Bot, Muse, ChatGPT Dots, Claude Duet, Hark or Instinct: its persona, skills, schedules and memories. You\'ll review everything before it\'s created. Keys and settings files are never read.';

  @override
  String get checkForUpdates => 'Check for updates';

  @override
  String get autoUpdates => 'Update Automatically';

  @override
  String get autoUpdatesHelp => 'Installs new versions when you quit.';

  @override
  String get upToDate => 'Casama Is Up to Date';

  @override
  String updateReady(String version) {
    return 'Casama $version is available';
  }

  @override
  String appVersion(String version) {
    return 'Version $version';
  }

  @override
  String whatsNewTitle(String version) {
    return 'What\'s New in Casama $version';
  }

  @override
  String get whatsNewGotIt => 'Got It';

  @override
  String get whatsNewSubtitle => 'Here\'s what changed since your last update.';

  @override
  String get whatsNew010Calls =>
      'Call your bots and talk things through. They answer out loud, with captions.';

  @override
  String get whatsNew010Looks =>
      'Make Casama yours: themes, color schemes, fonts and wallpapers in Settings → Appearance, with more from the gallery.';

  @override
  String get whatsNew010AboutYou =>
      'Tell your bots about yourself once, in Settings → About you: what to call you and how you like replies.';

  @override
  String get whatsNew010SignIn =>
      'Sign in with a passkey, Apple, Google or a code from your email.';

  @override
  String get openAtLogin => 'Open at Login';

  @override
  String get openAtLoginHelp => 'Ready for the quick-ask shortcut.';

  @override
  String get signInTagline =>
      'Teammates that keep working after you close the app.';

  @override
  String get signInTagline2 => 'Meet your AI crew.';

  @override
  String get signInTagline3 =>
      'AI that doesn\'t just talk. It gets things done.';

  @override
  String get signInTagline4 => 'Capable teammates that ask before they act.';

  @override
  String get signInTagline5 => 'Hand it off. Come back to it done.';

  @override
  String get noBotsHelp =>
      'A bot is a teammate with its own computer. Create one to start chatting.';

  @override
  String get newBotSubtitle => 'A teammate with its own computer and memory.';

  @override
  String get appearance => 'Appearance';

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
  String get createWorkspaceBody =>
      'A workspace holds your bots, their computers and the people you work with.';

  @override
  String get workspaceNameHint => 'My team';

  @override
  String get orJoinWithCode => 'or join with an invite code';

  @override
  String get getOpenRouterKey => 'Get an OpenRouter Key';

  @override
  String get createFirstBotBody =>
      'Give it a name and a model. You can change both later.';

  @override
  String stepOf(int step, int total) {
    return 'Step $step of $total';
  }

  @override
  String get providerHintOpenRouter =>
      'recommended: chat, images, video, voice';

  @override
  String get providerHintGoogle => 'live calls only';

  @override
  String get providerHintCompatible => 'Ollama, LM Studio, vLLM';

  @override
  String get providerHintSearch => 'web search';

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
  String get routineEnds => 'Ends';

  @override
  String get routineEndsNever => 'Never';

  @override
  String get routineEndsOnDate => 'On a date';

  @override
  String get routineEndsAfterRuns => 'After some runs';

  @override
  String get routineEndDate => 'Last day';

  @override
  String get routineRunCountLabel => 'Runs';

  @override
  String routineRunsCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n runs',
      one: '1 run',
    );
    return '$_temp0';
  }

  @override
  String routineEndsAt(String when) {
    return 'Ends $when';
  }

  @override
  String routineRunsLeft(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n runs left',
      one: '1 run left',
      zero: 'No runs left',
    );
    return '$_temp0';
  }

  @override
  String get routineChangeEnd => 'When It Ends';

  @override
  String get routineEndTitle => 'When it ends';

  @override
  String get routineEndSubtitle =>
      'It switches itself off then. A new number of runs counts from now.';

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
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'In $nString min';
  }

  @override
  String inHours(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'In $nString hours',
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
  String get openInSystemPlayer => 'Open in your video player';

  @override
  String get playMedia => 'Play';

  @override
  String get fullScreen => 'Full screen';

  @override
  String get exitFullScreen => 'Exit full screen';

  @override
  String pdfPageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages',
      one: '1 page',
    );
    return '$_temp0';
  }

  @override
  String get openInBrowser => 'Open in Browser';

  @override
  String get convertingToPdf => 'Getting a preview ready…';

  @override
  String tableFirstRows(int count) {
    return 'Showing the first $count rows';
  }

  @override
  String get imageCouldNotLoad => 'Couldn\'t load this picture';

  @override
  String get mediaKindImage => 'Image';

  @override
  String get mediaKindVideo => 'Video';

  @override
  String get mediaKindAudio => 'Audio';

  @override
  String get mediaKindPdf => 'PDF';

  @override
  String get openFileInChat => 'Open File';

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
  String get editPhoto => 'Edit photo';

  @override
  String get retryUpload => 'Try again';

  @override
  String get uploadingAttachments => 'Uploading…';

  @override
  String get notSent => 'Not sent';

  @override
  String get deleteChat => 'Delete Chat';

  @override
  String get deleteChatTitle => 'Delete this chat?';

  @override
  String deleteChatBody(String bot) {
    return 'Its messages are deleted for everyone who can see it. What $bot made here stays in the Library, usage records stay, and anything it remembered from it stays in its memory.';
  }

  @override
  String deleteChatAlsoCreations(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Also delete the $count things made here',
      one: 'Also delete the 1 thing made here',
    );
    return '$_temp0';
  }

  @override
  String get deleteChatAlsoCreationsHelp => 'Off: they stay in the Library.';

  @override
  String get chatDeleted => 'Chat deleted';

  @override
  String get deleteAllChats => 'Delete All Chats';

  @override
  String get deleteAllChatsRow =>
      'Start over with a clean history. Memories stay.';

  @override
  String deleteAllChatsTitle(String bot) {
    return 'Delete all chats with $bot?';
  }

  @override
  String deleteAllChatsBody(String bot) {
    return 'Every chat with $bot that you can delete goes, with its messages, photos and files. Group chats stay. Usage records stay, and what $bot remembered stays in its memory.';
  }

  @override
  String chatsDeleted(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString chats deleted.',
      one: '1 chat deleted.',
      zero: 'No chats to delete.',
    );
    return '$_temp0';
  }

  @override
  String chatsKeptBusy(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          '$nString chats were kept because the bot is still working in them.',
      one: '1 chat was kept because the bot is still working in it.',
    );
    return '$_temp0';
  }

  @override
  String groupEmptySubtitle(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          '$n bots are in this chat. Each keeps its own memory and settings.',
    );
    return '$_temp0';
  }

  @override
  String get groupTipMention => 'Type @ and a name to ask one bot directly.';

  @override
  String groupTipEveryone(String lead) {
    return '@everyone asks $lead to plan the work and hand a part to each bot.';
  }

  @override
  String groupTipNoMention(String lead) {
    return 'Without a mention, the bot that spoke last answers ($lead at first).';
  }

  @override
  String get messageNotSent =>
      'Your files didn\'t upload, so the message wasn\'t sent. It\'s back in the box.';

  @override
  String get noComputerForFiles => 'This bot has no computer to keep files on.';

  @override
  String fileTooLarge(String name) {
    return '$name is over 25 MB, too large to attach.';
  }

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
  String get editMemory => 'Edit Memory';

  @override
  String get editMemoryHelp =>
      'The bot uses this the next time it\'s relevant.';

  @override
  String get modelKeysIntro =>
      'Bots think with your own model provider keys. Keys are stored encrypted and never shown again.';

  @override
  String get casamaCloudKeyHint => 'Paid from your credits';

  @override
  String get casamaCloudIncluded => 'Included';

  @override
  String get casamaCloudModelLocked => 'Casama chooses this model.';

  @override
  String get serverVoiceSetUp =>
      'This server provides voice, so there\'s no key to add. A workspace\'s own key is used first.';

  @override
  String modelKeysFor(String workspace) {
    return 'Keys belong to one workspace. These are for $workspace.';
  }

  @override
  String get yourKeys => 'Your Keys';

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
  String get deleteSkill => 'Delete Skill';

  @override
  String get skillDescriptionHelp =>
      'Bots read this to decide when the skill applies.';

  @override
  String get skillBodyHint => '# Steps\n1. …';

  @override
  String get computersHelp =>
      'Each bot works on a computer: the team computer everyone shares, or a private one. Files stay on it between chats.';

  @override
  String get computersEmptyTitle => 'No computers yet';

  @override
  String get thisDevice => 'This device';

  @override
  String get personalComputerConnected => 'Connected';

  @override
  String get personalComputerOffline => 'Offline';

  @override
  String computerCpus(num n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n CPUs',
      one: '1 CPU',
    );
    return '$_temp0';
  }

  @override
  String computerMemory(Object size) {
    return '$size RAM';
  }

  @override
  String computerDisk(Object size) {
    return '$size disk';
  }

  @override
  String computerLastUsed(Object when) {
    return 'Last used $when';
  }

  @override
  String computerLastSeen(Object when) {
    return 'Last seen $when';
  }

  @override
  String get computerSaved => 'Saved';

  @override
  String get computerSavedHelp => 'Its files are kept while it\'s stopped';

  @override
  String computerCanUse(Object list) {
    return 'Bots can use: $list';
  }

  @override
  String get computerCanUseNothing => 'Bots can\'t use it yet';

  @override
  String get computerCapShell => 'Terminal';

  @override
  String get computerCapFiles => 'Files';

  @override
  String get computerCapBrowser => 'Browser';

  @override
  String get computerCapDesktop => 'Screen';

  @override
  String get computerCapMcp => 'Local tools';

  @override
  String get computerCapMessages => 'Messages';

  @override
  String personalComputerOfflineNamed(String name) {
    return '$name is offline. Open Casama on it and turn on \"Use this computer for bots\". Your own computer never uses your plan\'s computer hours.';
  }

  @override
  String get yourComputerOffline => 'Your computer is offline';

  @override
  String get howToFix => 'How to fix';

  @override
  String get computerHoursUsedTitle => 'Computer hours used up';

  @override
  String get personalScreenNote =>
      'This is your own computer, so you see a new screenshot every few seconds instead of a live view.';

  @override
  String get renameComputer => 'Rename Computer';

  @override
  String deleteComputerTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get privacyIntro =>
      'Your chats, memories and files belong to you. Export them any time, or delete your account.';

  @override
  String get yourData => 'Your Data';

  @override
  String get shareAnalytics => 'Share Usage Data';

  @override
  String get shareAnalyticsHelp =>
      'Usage and crash reports. Never your messages or files.';

  @override
  String get workspaceAnalytics => 'Usage Data for This Workspace';

  @override
  String get workspaceAnalyticsHelp =>
      'Usage data for this workspace. Crash reports stay on.';

  @override
  String get dangerZone => 'Danger Zone';

  @override
  String get quotasHelp => 'Leave a field empty for no limit.';

  @override
  String get serviceOff => 'Off';

  @override
  String get serviceDown => 'Down';

  @override
  String get serviceOk => 'OK';

  @override
  String get sendInvite => 'Send Invite';

  @override
  String get thinking0 => 'Model';

  @override
  String get saveChanges => 'Save Changes';

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
  String quickAskIntroBot(String name) {
    return 'Send a quick request. It starts a new chat with $name.';
  }

  @override
  String quickAskHintBot(String bot) {
    return 'What should $bot do?';
  }

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
      'Use your own Casama server. Enter the address you or your admin set up.';

  @override
  String get ssoHelp =>
      'Enter your work email and we\'ll send you to your company\'s sign-in page.';

  @override
  String get colorScheme => 'Color Scheme';

  @override
  String get searchThemes => 'Search schemes';

  @override
  String get noThemesFound => 'No schemes match.';

  @override
  String get noAppsMatch =>
      'No apps match. You can add your own server under Advanced.';

  @override
  String appsFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count apps',
      one: '1 app',
    );
    return '$_temp0';
  }

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
  String get patternStrength => 'Pattern Strength';

  @override
  String get wallpaperEverywhere => 'Show on every screen';

  @override
  String get wallpaperEverywhereHelp =>
      'Turn off to keep it behind chats only.';

  @override
  String get resetBackground => 'Reset to Default';

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
  String get botUiConnected => 'Connected';

  @override
  String get draftNewEmail => 'New email';

  @override
  String get draftNewMessage => 'New message';

  @override
  String get draftNewPost => 'New post';

  @override
  String get draftReadyToSend => 'Ready to send';

  @override
  String get draftReadyToPost => 'Ready to post';

  @override
  String get draftEdited => 'Edited';

  @override
  String get draftSendEmail => 'Send email';

  @override
  String get draftSend => 'Send';

  @override
  String get draftPost => 'Post';

  @override
  String get draftDiscard => 'Discard';

  @override
  String get draftEdit => 'Edit';

  @override
  String get draftDoneEditing => 'Done';

  @override
  String get draftFrom => 'From';

  @override
  String get draftTo => 'To';

  @override
  String get draftCc => 'Cc';

  @override
  String get draftBcc => 'Bcc';

  @override
  String get draftSubject => 'Subject';

  @override
  String get botCardNewEvent => 'New event';

  @override
  String get botCardEvent => 'Event';

  @override
  String get botCardReadyToAdd => 'Ready to add';

  @override
  String get botCardAddToCalendar => 'Add to calendar';

  @override
  String get botCardChange => 'Change';

  @override
  String get botCardSkip => 'Skip';

  @override
  String get botCardAllDay => 'All day';

  @override
  String botCardMore(int count) {
    return '+$count more';
  }

  @override
  String get botCardAgenda => 'Agenda';

  @override
  String get botCardMessages => 'Messages';

  @override
  String botCardUnread(int count) {
    return '$count unread';
  }

  @override
  String get botCardReply => 'Reply';

  @override
  String botCardReplyTo(String name) {
    return 'Reply to $name';
  }

  @override
  String get botCardTasks => 'Tasks';

  @override
  String botCardDoneOf(int done, int total) {
    return '$done of $total done';
  }

  @override
  String get botCardSaveChanges => 'Save changes';

  @override
  String get botCardChoose => 'Choose';

  @override
  String botCardChose(String title) {
    return '$title';
  }

  @override
  String get botCardWhichPerson => 'Who do you mean?';

  @override
  String get botCardNoneOfThese => 'None of these';

  @override
  String get botCardReminder => 'Reminder';

  @override
  String get botCardRoutine => 'Routine';

  @override
  String get botCardWatcher => 'Watching';

  @override
  String get botCardScheduled => 'Set';

  @override
  String botCardNext(String when) {
    return 'Next: $when';
  }

  @override
  String get botCardCancelIt => 'Cancel it';

  @override
  String get botIcon => 'Icon';

  @override
  String get botIconInitials => 'Initials';

  @override
  String get errorDetailsTitle => 'What went wrong';

  @override
  String get exportLabel => 'Export';

  @override
  String get openTimeline => 'Open Run Timeline';

  @override
  String get details => 'Details';

  @override
  String get themes => 'Themes';

  @override
  String get myThemes => 'Your themes';

  @override
  String get saveTheme => 'Save Current Look';

  @override
  String get themeName => 'Theme name';

  @override
  String get importTheme => 'Import a Theme';

  @override
  String get themeCode => 'Theme code';

  @override
  String get themeCodeHelp =>
      'Paste a code someone shared with you. It starts with casama-theme:';

  @override
  String get invalidThemeCode => 'That isn\'t a Casama theme code.';

  @override
  String themeImported(String name) {
    return 'Added $name to your themes';
  }

  @override
  String get themeCodeCopied =>
      'Theme code copied. Anyone can paste it into Appearance → Import a theme.';

  @override
  String get shareTheme => 'Share code';

  @override
  String deleteThemeTitle(String name) {
    return 'Delete $name?';
  }

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
  String get resetFonts => 'Use the Defaults';

  @override
  String get fontSample => 'Your bots, working together with you.';

  @override
  String get backgroundPhoto => 'Photo';

  @override
  String get yourPhoto => 'Your Photo';

  @override
  String get browsePhotos => 'Browse photos';

  @override
  String get removePhoto => 'Remove Photo';

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
  String get tokensIn => 'Tokens In';

  @override
  String get tokensOut => 'Tokens Out';

  @override
  String get runsLabel => 'Runs';

  @override
  String get spendByDay => 'Spend by Day';

  @override
  String get byBot => 'By Bot';

  @override
  String get byModel => 'By Model';

  @override
  String get everythingMetered => 'Everything Metered';

  @override
  String get bySource => 'By Source';

  @override
  String get byPerson => 'By Person';

  @override
  String get usageAllBots => 'All bots';

  @override
  String get usageAllModels => 'All models';

  @override
  String get usageAllSources => 'All sources';

  @override
  String get usageEveryone => 'Everyone';

  @override
  String get usageJustMe => 'Just me';

  @override
  String get usageClearFilters => 'Clear';

  @override
  String get usageFilterBot => 'Show usage for';

  @override
  String get usageFilterModel => 'Show usage of';

  @override
  String get usageFilterSource => 'Show usage from';

  @override
  String get usageFilterPerson => 'Show usage started by';

  @override
  String get usageSourceChat => 'Chats';

  @override
  String get usageSourceChatApp => 'Chat apps';

  @override
  String get usageSourceRoutine => 'Routines';

  @override
  String get usageSourceApi => 'API and other agents';

  @override
  String get usageSourceOther => 'Other';

  @override
  String get usageNoPerson => 'Automatic';

  @override
  String get usageUnnamedPerson => 'Unnamed member';

  @override
  String usageRunsCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n runs',
      one: '1 run',
    );
    return '$_temp0';
  }

  @override
  String get exportCsv => 'Export CSV';

  @override
  String get exportJson => 'Export JSON';

  @override
  String get askBotAboutUsage => 'Ask a Bot About This';

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
    return 'Here is my Casama usage for $period. Help me understand where the money goes and how I could spend less. You can also check live numbers with your usage tool.\n\n$summary';
  }

  @override
  String get kindTokensIn => 'Model input';

  @override
  String get kindTokensOut => 'Model output';

  @override
  String get kindComputer => 'Cloud computer time';

  @override
  String get kindModels => 'AI models';

  @override
  String get creditsThisMonth => 'This month\'s credits';

  @override
  String creditsUsedPercent(int percent) {
    return '$percent% used';
  }

  @override
  String creditsRunsLeft(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'About $nString more runs at your usual cost',
      one: 'About 1 more run at your usual cost',
      zero: 'Less than one more run at your usual cost',
    );
    return '$_temp0';
  }

  @override
  String get creditsOut =>
      'You\'re out of credits. Add more to keep your bots running.';

  @override
  String creditsExplainer(String amount) {
    return '1 credit = \$1. Your plan adds $amount every month; unused ones carry over for one more month.';
  }

  @override
  String get creditsExplainerShort =>
      '1 credit = \$1. Packs from the App Store or Google Play never expire; web packs last 12 months.';

  @override
  String get creditsDailyLabel => 'Today\'s limit';

  @override
  String creditsDailyOf(String used, String cap) {
    return '$used of $cap';
  }

  @override
  String get creditsDailyExplainer =>
      'What your plan can spend each day on Casama\'s models, voice and apps, whatever credits are left.';

  @override
  String get creditsDailyReached =>
      'Today\'s limit is reached, so your bots are paused. Upgrade for a higher daily limit.';

  @override
  String creditsDailyResetsHours(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Resets in about $n hours.',
      one: 'Resets in about 1 hour.',
    );
    return '$_temp0';
  }

  @override
  String get creditsDailyResetsSoon => 'Resets in less than an hour.';

  @override
  String get creditsHoursLabel => 'Computer hours';

  @override
  String creditsHoursOf(String used, String limit) {
    return '$used of $limit h';
  }

  @override
  String creditsHoursExplainer(String date) {
    return 'Time your bots\' computers run this month. When they run out, chat keeps working; only the computer stops. Resets on $date.';
  }

  @override
  String creditsHoursReached(String date) {
    return 'This month\'s computer hours are used, so your computer can\'t start. Chat still works. Resets on $date. Upgrade for more hours.';
  }

  @override
  String get kindStream => 'Live view';

  @override
  String get kindTts => 'Read aloud';

  @override
  String get computerMissingTitle => 'Computer not found';

  @override
  String get computerMissingHelp =>
      'It may have been removed, or the list is out of date. Refresh to check again.';

  @override
  String get computerMissingBotHelp =>
      'This bot\'s computer may have been removed, or the list is out of date. Refresh, or choose another computer for this bot.';

  @override
  String get computerChoose => 'Choose a Computer';

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
  String get browseAllPersonas => 'Browse all';

  @override
  String get botIdentity => 'Name and icon';

  @override
  String get serviceKeys => 'Service keys';

  @override
  String get noServiceKeys => 'No service keys yet.';

  @override
  String get serviceKeysHelp => 'Your own search, maps or data keys';

  @override
  String get serviceKeysIntro =>
      'Casama runs the models, voice and images for you. Add a key here only to use your own search, maps or data service. Keys are stored encrypted and never shown again.';

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
  String get loadPersona => 'Load a Persona';

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
  String get reopenSignIn => 'Open the Sign-in Page Again';

  @override
  String appConnected(String app) {
    return '$app is connected';
  }

  @override
  String appAlreadyConnected(String app) {
    return '$app is already connected in this workspace. Use that connection, or add another account.';
  }

  @override
  String get useConnection => 'Use It';

  @override
  String get addAnotherAccount => 'Add Another Account';

  @override
  String appToolsReady(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString tools are ready for your bots.',
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
    return 'One-click sign-in for $app needs a one-time setup by whoever runs this Casama server.';
  }

  @override
  String connectThroughHub(String app) {
    return 'Or connect $app through one of these. Sign in once, then ask your bot to use $app.';
  }

  @override
  String adminSetupRedirect(String uri) {
    return 'Register this redirect address with the app: $uri';
  }

  @override
  String get privacyNote =>
      'The sign-in is stored encrypted and never shown again. Disconnect anytime.';

  @override
  String get composioHelp => 'Hundreds of apps, with sign-in handled for you.';

  @override
  String get pipedreamHelp => 'Thousands of apps through Pipedream Connect.';

  @override
  String get customServer => 'Custom Server';

  @override
  String get customServerHelp =>
      'Any MCP server or OpenAPI spec. For developers.';

  @override
  String usedByBots(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Used by $countString bots',
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
  String get toolsHelp =>
      'Read-only tools run on their own. Tools that make changes ask first when a bot has read something untrusted, and ones marked “Always asks” wait for you every time.';

  @override
  String get botsWithAccess => 'Bots with Access';

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
  String get testConnection => 'Test Connection';

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
  String get browseApps => 'Browse Apps';

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
  String connectedThroughHub(String provider) {
    return 'Through $provider';
  }

  @override
  String providerAppsTitle(String provider) {
    return 'Apps Through $provider';
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
  String get wakeAndWatch => 'Wake Up and Watch Live';

  @override
  String get chatGptPlan => 'ChatGPT plan';

  @override
  String get continueWithChatGpt => 'Continue with ChatGPT';

  @override
  String get chatGptConnectHelp =>
      'Run your bots on your ChatGPT plan instead of an API key. Their model calls count toward your plan\'s limits, and only you can use it.';

  @override
  String get chatGptDesktopOnly =>
      'To connect your ChatGPT plan, open the desktop app, or run \"casama credential chatgpt\" in the CLI.';

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
  String get manageUsage => 'Manage Usage';

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
  String get signInWithPasskey => 'Sign In with a Passkey';

  @override
  String get account => 'Account';

  @override
  String get accountRow => 'Email, password and signing out everywhere';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get newPassword => 'New password';

  @override
  String get newPasswordAgain => 'New password again';

  @override
  String get passwordsDontMatch => 'The passwords don\'t match';

  @override
  String get newPasswordTitle => 'Choose a new password';

  @override
  String get newPasswordBody =>
      'You\'re signed in. Pick a new password for signing in with your email.';

  @override
  String get savePassword => 'Save password';

  @override
  String get passwordSaved => 'Password saved.';

  @override
  String get passwordTitle => 'Password';

  @override
  String get passwordRow =>
      'Set or change the password for signing in with your email';

  @override
  String get passwordHelp =>
      'Use at least 6 characters. You can still sign in with Google, Apple, a passkey or an email link.';

  @override
  String passwordCodeSent(String email) {
    return 'To keep your account safe, enter the code we just emailed to $email.';
  }

  @override
  String get changeEmailTitle => 'Change Email';

  @override
  String get changeEmailHelp =>
      'We\'ll email a confirmation link to your current address and to the new one. The change happens once both are confirmed.';

  @override
  String get newEmail => 'New email';

  @override
  String get changeEmailSend => 'Send Confirmation';

  @override
  String get changeEmailRow => 'Change the email you sign in with';

  @override
  String changeEmailSent(String email) {
    return 'Check both inboxes. $email becomes your email once both links are confirmed.';
  }

  @override
  String changeEmailPending(String email) {
    return 'Waiting for confirmation: $email';
  }

  @override
  String get signOutEverywhere => 'Sign Out Everywhere';

  @override
  String get signOutEverywhereHelp =>
      'Every phone, computer and browser, including this one';

  @override
  String get signOutEverywhereConfirm =>
      'Sign out on every device, including this one? Use this if you lost a device or think someone else is signed in.';

  @override
  String get passkeySuggestTitle => 'Sign in faster next time?';

  @override
  String get passkeySuggestBody =>
      'Add a passkey and sign in with Face ID, a fingerprint or your screen lock. No password or email needed.';

  @override
  String get passkeys => 'Passkeys';

  @override
  String get passkeysRow =>
      'Sign in with Face ID, a fingerprint or your screen lock';

  @override
  String get passkeysHelp =>
      'A passkey signs you in with Face ID, a fingerprint or your screen lock, with no password or email. Each phone, computer or password manager keeps its own.';

  @override
  String get passkeyAdd => 'Add a Passkey';

  @override
  String get passkeyAddAnother => 'Add Another Passkey';

  @override
  String get passkeyAdded => 'Passkey added. Next time, sign in with it.';

  @override
  String get passkeyRename => 'Rename';

  @override
  String get passkeyRenameTitle => 'Rename Passkey';

  @override
  String get passkeyNameLabel => 'Name';

  @override
  String get passkeyRemove => 'Remove';

  @override
  String passkeyRemoveConfirm(String name) {
    return 'Remove \"$name\"? You won\'t be able to sign in with it any more.';
  }

  @override
  String passkeyAddedOn(String date) {
    return 'Added $date';
  }

  @override
  String passkeyLastUsed(String when) {
    return 'Last used $when';
  }

  @override
  String get twoStepSetUp => 'Set Up an Authenticator App';

  @override
  String get twoStepAddAnother => 'Add Another Authenticator';

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
  String get twoStepAuthenticators => 'Authenticator Apps';

  @override
  String get twoStepRename => 'Rename';

  @override
  String get twoStepRenameTitle => 'Rename Authenticator';

  @override
  String get twoStepNameLabel => 'Name';

  @override
  String get twoStepNameHint => 'For example: Work phone';

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
      'Owners and admins must use it. Turn yours on first.';

  @override
  String get twoStepNeededForAdmin =>
      'This workspace requires two-step sign-in for owners and admins. Set it up, or sign in again with your code, to use admin settings.';

  @override
  String get adminAbuse => 'Abuse';

  @override
  String get adminCapacityTitle => 'Server capacity';

  @override
  String adminCapacityComputers(String used, String budget) {
    return 'Computers: $used of $budget';
  }

  @override
  String adminCapacityComputersNoBudget(String used) {
    return 'Computers: $used';
  }

  @override
  String adminCapacityFree(String free, String total) {
    return 'Free memory $free of $total';
  }

  @override
  String adminCapacityDisk(int percent) {
    return 'Disk $percent% full';
  }

  @override
  String adminCapacityLoad(String load, int cpus) {
    return 'Load $load on $cpus CPUs';
  }

  @override
  String get adminCapacityPeakChart => 'Computers\' daily peak, last 30 days';

  @override
  String adminCapacityFullIn(int weeks) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: 'Full in about $weeks weeks at this trend',
      one: 'Full in about a week at this trend',
    );
    return '$_temp0';
  }

  @override
  String get adminCapacityFullNow => 'Full now: order the bigger server';

  @override
  String get adminCapacityNoGrowth => 'Not filling up at the current trend';

  @override
  String get adminCapacityNoBudget =>
      'Set COMPUTER_HOST_MEMORY_GB on the server to measure computers against its room.';

  @override
  String get adminCapacityNoData =>
      'The first sample arrives within 5 minutes of the server starting.';

  @override
  String adminCapacityRefusals(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count computer starts refused in 30 days',
      one: '1 computer start refused in 30 days',
      zero: 'No computer starts refused in 30 days',
    );
    return '$_temp0';
  }

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
  String get localMcpServers => 'Local Tools (MCP)';

  @override
  String get localMcpHelp =>
      'MCP servers on this computer or your network that your bots can use, such as T3 Code, Claude Code, Codex or design apps. Their tokens and sign-ins stay on this computer.';

  @override
  String get localMcpAdd => 'Add a Local MCP Server';

  @override
  String get localMcpEmpty => 'No local MCP servers yet.';

  @override
  String get localMcpName => 'Name';

  @override
  String get localMcpStdio => 'A Command';

  @override
  String get localMcpLoopback => 'An Address';

  @override
  String get localMcpCommand => 'Command';

  @override
  String get localMcpCommandHint => 'npx -y @example/mcp-server';

  @override
  String get localMcpUrl => 'Address';

  @override
  String get localMcpFolder => 'Working Folder (Optional)';

  @override
  String get localMcpEnv =>
      'Environment (one KEY=value per line, kept on this computer)';

  @override
  String get localMcpNeedsCapability =>
      'Turn on Local tools (MCP) above so bots can use these.';

  @override
  String get localMcpBadUrl =>
      'Use an http:// address on this computer or your own network, like http://127.0.0.1:3845/mcp, or an https:// address.';

  @override
  String get localMcpBadFolder =>
      'Pick a folder inside one of the shared folders.';

  @override
  String get codingAgents => 'Coding Agents';

  @override
  String get codingAgentsHelp =>
      'Bots can hand coding tasks to these agents on this computer. They use your own sign-ins and work in the folders you share.';

  @override
  String codingAgentsFound(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Found $nString coding agents',
      one: 'Found 1 coding agent',
      zero: 'No coding agents found',
    );
    return '$_temp0';
  }

  @override
  String get localMcpNotSaved =>
      'This server isn\'t saved to the workspace yet. Remove it and add it again.';

  @override
  String get localMcpSignInKind => 'Sign-In';

  @override
  String get localMcpAuthNone => 'None';

  @override
  String get localMcpAuthToken => 'Token';

  @override
  String get localMcpAuthHeader => 'Header';

  @override
  String get localMcpAuthOAuth => 'Browser';

  @override
  String get localMcpToken => 'Token (kept on this computer)';

  @override
  String get localMcpHeaderName => 'Header Name';

  @override
  String get localMcpHeaderValue => 'Header Value (kept on this computer)';

  @override
  String get localMcpOAuthHelp =>
      'Casama opens your browser so you can sign in to this server. The sign-in stays on this computer.';

  @override
  String get localMcpNetworkWarning =>
      'This server isn\'t on this computer. Bots that can use this computer can reach it.';

  @override
  String get localMcpSignIn => 'Sign In';

  @override
  String get localMcpNeedsSignIn => 'Needs sign-in';

  @override
  String get localMcpEdit => 'Edit Local MCP Server';

  @override
  String get localMcpImport => 'Add From Other Apps';

  @override
  String get localMcpImportHelp =>
      'MCP servers already set up in T3 Code, Claude Code, Claude Desktop, Cursor, VS Code, Codex or Windsurf on this computer.';

  @override
  String get localMcpImportNone =>
      'No MCP servers found in other apps on this computer.';

  @override
  String get localMcpImportAdded => 'Already added';

  @override
  String get localMcpImportRemote =>
      'On the internet, so usually added under Connections. Add it here only if just this computer can reach it.';

  @override
  String get mcpQuestionDecline => 'Decline';

  @override
  String get mcpQuestionSend => 'Send';

  @override
  String get cardMcpQuestion => 'Question';

  @override
  String get cardMcpSignIn => 'Sign-in';

  @override
  String get mcpSignInHereHelp => 'Sign in so your bots can use it again.';

  @override
  String localMcpSignedIn(String name) {
    return 'Signed in to $name';
  }

  @override
  String localMcpImportFrom(String source) {
    return 'From $source';
  }

  @override
  String localMcpImportAddCount(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Add $nString Servers',
      one: 'Add 1 Server',
      zero: 'Add',
    );
    return '$_temp0';
  }

  @override
  String localMcpMissingValue(String name) {
    return '$name (kept on this computer)';
  }

  @override
  String mcpSignInTitle(String name) {
    return '$name needs you to sign in';
  }

  @override
  String mcpSignInElsewhereHelp(String device) {
    return 'Open Casama on $device and sign in there.';
  }

  @override
  String mcpQuestionTitle(String connection) {
    return '$connection asks';
  }

  @override
  String mcpQuestionAnswered(String connection) {
    return 'Answered $connection';
  }

  @override
  String mcpQuestionDeclined(String connection) {
    return 'Declined $connection\'s question';
  }

  @override
  String mcpQuestionClosed(String connection) {
    return '$connection\'s question closed';
  }

  @override
  String get codingAgentsNone =>
      'No coding agents found. Install Claude Code, Codex or Cursor\'s command-line agent to hand them coding tasks.';

  @override
  String get codingAgentsNeedShell =>
      'Coding agents run as commands, so they need Run commands turned on.';

  @override
  String get allowCommands => 'Turn On';

  @override
  String get codingAgentAllow => 'Allow';

  @override
  String get codingAgentAllowed => 'Allowed';

  @override
  String get codingAgentsAllowHelp =>
      'An agent with Allow next to it hasn\'t run on this computer yet. Allow it once and bots can hand it tasks.';

  @override
  String get ownAgentsAdd => 'Add Your Own';

  @override
  String get ownAgentYours => 'Yours';

  @override
  String get ownAgentNotFound => 'Not found on this computer';

  @override
  String get ownAgentsHelp =>
      'Your own agents run only on this computer, in chats that act for you. Nobody else in the workspace can see or change them.';

  @override
  String get ownAgentFormTitle => 'Add Your Own Agent';

  @override
  String get ownAgentEditTitle => 'Edit Your Agent';

  @override
  String get ownAgentName => 'Name';

  @override
  String get ownAgentBin => 'Command Name';

  @override
  String get ownAgentCommand => 'Command';

  @override
  String ownAgentCommandHelp(String task, String folder, String result_file) {
    return 'Put $task where the task goes; Casama quotes it. Every command in it starts with the command name. You can also use $folder, and $result_file when the agent writes its answer to a file.';
  }

  @override
  String get ownAgentResult => 'Reading the Answer';

  @override
  String get ownAgentResultTail => 'The end of its output';

  @override
  String get ownAgentResultJson => 'A JSON line with a result field';

  @override
  String get ownAgentResultStream => 'A stream of JSON lines';

  @override
  String get ownAgentResultField => 'A JSON field';

  @override
  String get ownAgentResultFile => 'Written to a file';

  @override
  String get ownAgentResultFieldName => 'Field Name';

  @override
  String get ownAgentTimeLimit => 'Time Limit (Minutes)';

  @override
  String get ownAgentTest => 'Test';

  @override
  String get ownAgentTestHelp =>
      'Test asks it to reply with just the word pong on this computer and shows what it printed.';

  @override
  String ownAgentTestPassed(String reply) {
    return 'It answered: $reply';
  }

  @override
  String ownAgentTestFailed(int code) {
    return 'It didn\'t answer as expected (exit $code).';
  }

  @override
  String get ownAgentTestTimedOut => 'It didn\'t finish in time.';

  @override
  String ownAgentBadCommand(String task) {
    return 'Fill in a name, a command name and a command with $task.';
  }

  @override
  String get board => 'Board';

  @override
  String get newTicket => 'New ticket';

  @override
  String get newTicketSubtitle =>
      'A task for one of your bots, tracked on the board.';

  @override
  String get allProjects => 'All projects';

  @override
  String get manageProjects => 'Manage projects';

  @override
  String get filterByProject => 'Filter by project';

  @override
  String get moveTo => 'Move to';

  @override
  String get noMatchingTickets => 'No matching tickets';

  @override
  String get noMatchingTicketsHelp => 'No tickets match these filters.';

  @override
  String get clearFilters => 'Clear Filters';

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
  String get reviewRequired => 'Needs Review';

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
  String get openThread => 'Open the Bot\'s Thread';

  @override
  String get deleteTicket => 'Delete Ticket';

  @override
  String get ticketResult => 'Result';

  @override
  String get noCommentsYet =>
      'No comments yet. Leave a note for the bot or your team.';

  @override
  String get noTickets => 'Give your bots something to do';

  @override
  String get noTicketsHelp =>
      'Hand off one piece of work, or a whole goal. You can watch it move from here.';

  @override
  String get tasksStartTicket => 'Add a ticket';

  @override
  String get tasksStartTicketHelp =>
      'One piece of work. Assign it to a bot and it starts.';

  @override
  String get tasksStartProject => 'Start a project';

  @override
  String get tasksStartProjectHelp =>
      'A bigger goal. A bot plans it as tickets and waits for your OK.';

  @override
  String get tasksExamples => 'Or start from one of these';

  @override
  String get tasksExampleResearch => 'Research my top three competitors';

  @override
  String get tasksExampleDraft => 'Draft a launch announcement';

  @override
  String get tasksExampleTidy => 'Tidy up my files';

  @override
  String get ticketStatus => 'Status';

  @override
  String get spaces => 'Workspaces';

  @override
  String get newWorkspace => 'New Workspace';

  @override
  String get newWorkspaceSubtitle =>
      'A separate home for a team, with its own bots, chats and people.';

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
  String get createInviteLink => 'Create a Link';

  @override
  String get linkExpires => 'Expires';

  @override
  String get linkNever => 'Never';

  @override
  String linkDays(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'In $daysString days',
      one: 'In 1 day',
    );
    return '$_temp0';
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
  String get inviteRole => 'Role';

  @override
  String get shareLinkLabel => 'Share';

  @override
  String get botFolder => 'Folder';

  @override
  String get noFolder => 'No folder';

  @override
  String get newFolder => 'New folder…';

  @override
  String get folderName => 'Folder name';

  @override
  String get archiveBot => 'Archive Bot';

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
  String get unarchive => 'Bring Back';

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
  String get restoreSettings => 'Restore These Settings';

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
  String get changedBySystem => 'Changed by Casama';

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
  String secretWhat(String service) {
    return '$service key';
  }

  @override
  String totpWhat(String service) {
    return '$service sign-in code';
  }

  @override
  String takeoverHandedBackLine(String what) {
    return 'Handed back: $what';
  }

  @override
  String deviceAccessSkippedLine(String what) {
    return 'Not shared: your $what';
  }

  @override
  String get decline => 'Decline';

  @override
  String get signInCode => 'Sign-in code';

  @override
  String get secretKindValue => 'Key or Password';

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
  String get searchJumpHint => 'Search or jump to…';

  @override
  String get searchRecent => 'Recent';

  @override
  String get searchClearRecent => 'Clear';

  @override
  String get searchRemoveRecent => 'Remove from recent searches';

  @override
  String get searchJumpBackIn => 'Jump back in';

  @override
  String get searchNeedsYou => 'Needs you';

  @override
  String searchWaiting(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n things are waiting for you',
      one: '1 thing is waiting for you',
    );
    return '$_temp0';
  }

  @override
  String get searchGoTo => 'Go to';

  @override
  String get searchTopHits => 'Top hits';

  @override
  String get searchScopeAll => 'All';

  @override
  String get searchKeepTyping =>
      'Keep typing to search messages, memories and files.';

  @override
  String searchAskBot(String bot, String query) {
    return 'Ask $bot about “$query”';
  }

  @override
  String get searchAskBotHelp => 'Starts a new chat with this question';

  @override
  String get searchKeysHint => '↑ ↓ to move   ↵ to open   esc to close';

  @override
  String get searchClear => 'Clear search';

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
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString files',
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
  String get attachSkill => 'Attach a skill';

  @override
  String get rerunSetup => 'Run Setup Again';

  @override
  String get rerunSetupHelp =>
      'Answer the setup questions again and review a new proposal';

  @override
  String get trace => 'Trace';

  @override
  String get openTrace => 'Open Trace';

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
  String get botMayCall => 'Can call me';

  @override
  String get botMayCallHelp =>
      'This bot can phone you when something is worth a call. Off: it sends a notification instead.';

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
  String get shareAsTemplate => 'Share as Template';

  @override
  String get shareAsTemplateRow =>
      'A file or link with its instructions, skills and routines';

  @override
  String get shareAsTemplateHelp =>
      'Includes instructions, skills, routines and the services it uses. Never keys or secrets.';

  @override
  String get copyLink => 'Copy link';

  @override
  String get includeMemories => 'Include Memories';

  @override
  String get includeMemoriesHelp =>
      'What it has learned about you. Share with care.';

  @override
  String get saveAsFile => 'Save as File';

  @override
  String get notABotTemplate => 'That file isn\'t a Casama bot template.';

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
  String get whatComesWithIt => 'What Comes with It';

  @override
  String get connectAfterImport => 'Connect after importing';

  @override
  String get importRoutines => 'Schedule Its Routines';

  @override
  String importMemories(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Keep its $countString memories',
      one: 'Keep its 1 memory',
    );
    return '$_temp0';
  }

  @override
  String get startingRoutine => 'Starting the routine…';

  @override
  String get offlineSaved => 'Offline. Showing saved messages.';

  @override
  String get loadEarlierMessages => 'Earlier Messages';

  @override
  String get chatLoadFailedTitle => 'This chat didn\'t load';

  @override
  String get chatLoadFailedBody => 'Check your connection, then try again.';

  @override
  String get projects => 'Projects';

  @override
  String get newProject => 'New project';

  @override
  String get noProjects => 'No projects yet';

  @override
  String get projectsHelp =>
      'A project keeps one piece of work together: its chat, plan, to-dos, files and everything made for it. Work on it with a bot, or let the bot plan it and work on it by itself.';

  @override
  String get newProjectHelp =>
      'Keeps one piece of work together: its chat, plan, to-dos, files and everything made for it.';

  @override
  String get startPlanning => 'Start Planning';

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
  String get projectGoalHint =>
      'What should exist at the end? A landing page live on my domain…';

  @override
  String get projectDoneHint => 'Optional. How you\'ll know it\'s finished';

  @override
  String get projectBudgetHint => 'Optional. Work pauses when it\'s spent';

  @override
  String get projectThread => 'Project chat';

  @override
  String get approvePlan => 'Approve the Plan';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Resume';

  @override
  String get milestones => 'Milestones';

  @override
  String get needsSignoff => 'needs your sign-off';

  @override
  String get signOff => 'Sign Off';

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
  String get projectName => 'Name';

  @override
  String get projectNameHint => 'Space Dodger, Spring newsletter…';

  @override
  String get createProject => 'Create Project';

  @override
  String projectWorksAlone(String bot) {
    return 'Let $bot work on it by itself';
  }

  @override
  String get projectWorksAloneHelp =>
      'It drafts a plan for you to approve, then works in sessions until the goal is met. Nothing starts before you approve.';

  @override
  String get projectWorksAloneOn => 'Works in sessions until the goal is met.';

  @override
  String get projectWorksAloneOff => 'You work on it together in its chat.';

  @override
  String get projectMade => 'Made in this project';

  @override
  String projectMadeEmpty(String bot) {
    return 'Nothing yet. What $bot makes in this project\'s chat shows up here.';
  }

  @override
  String get projectSeeAll => 'See All';

  @override
  String get projectTodos => 'To-dos';

  @override
  String get projectFiles => 'Files';

  @override
  String projectFilesHelp(String folder, String bot) {
    return '$folder on $bot\'s computer';
  }

  @override
  String get projectMarkDone => 'Mark as Done';

  @override
  String get projectReopen => 'Reopen';

  @override
  String get projectCover => 'Cover';

  @override
  String get projectCoverNone => 'None';

  @override
  String projectCoverName(String name) {
    String _temp0 = intl.Intl.selectLogic(name, {
      'sailboat': 'Sailboat',
      'mountain': 'Mountain',
      'seedling': 'Seedling',
      'compass': 'Compass',
      'lantern': 'Lantern',
      'telescope': 'Telescope',
      'map': 'Map',
      'chess': 'Chess',
      'other': '$name',
    });
    return '$_temp0';
  }

  @override
  String projectThings(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString things',
      one: '1 thing',
      zero: 'Nothing yet',
    );
    return '$_temp0';
  }

  @override
  String get creationProjectLabel => 'Project';

  @override
  String get creationMoveToProject => 'Move to Project';

  @override
  String get creationNoProject => 'No Project';

  @override
  String get makeProject => 'Make This a Project';

  @override
  String get makeProjectTitle => 'Make this topic a project';

  @override
  String makeProjectHelp(String bot) {
    return 'What $bot made in this topic is filed under the project, and so is what it makes here next.';
  }

  @override
  String get openProject => 'Open Project';

  @override
  String get theBot => 'the bot';

  @override
  String get forYou => 'For you';

  @override
  String get inboxNeedsYou => 'Needs you';

  @override
  String inboxNeedsYouCount(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'Needs you ($nString)';
  }

  @override
  String get inboxBriefs => 'Briefs';

  @override
  String get inboxUpdates => 'Updates';

  @override
  String get inboxEmptyHelp =>
      'Requests, morning briefs, notifications and new pages from your bots show up here.';

  @override
  String get inboxNeedsYouEmpty => 'Nothing needs you right now';

  @override
  String get inboxNeedsYouEmptyHelp =>
      'When a bot needs a decision, your help or has an idea, it shows up here.';

  @override
  String get noBriefs => 'No morning briefs yet';

  @override
  String botPublishedPage(String bot, String title) {
    return '$bot published $title';
  }

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
  String dismissSuggestionHelp(String bot) {
    return 'Choose whether $bot can bring it up again.';
  }

  @override
  String get justThisOnce => 'Just This Once';

  @override
  String justThisOnceHelp(String bot) {
    return 'Hide it for now. If it still matters later, $bot may suggest it again.';
  }

  @override
  String get dontSuggestAgain => 'Don\'t Suggest It Again';

  @override
  String dontSuggestAgainHelp(String bot) {
    return 'Gone for good. $bot will remember you\'d rather not.';
  }

  @override
  String wontSuggestAgain(String bot) {
    return 'Got it. $bot won\'t suggest that again.';
  }

  @override
  String get doIt => 'Do It';

  @override
  String get checkins => 'Check-Ins';

  @override
  String get checkinsHelp =>
      'A morning brief and a look every few hours for things that need you. Off by default.';

  @override
  String get briefTime => 'Morning brief at';

  @override
  String get scanEvery => 'Look every';

  @override
  String hours(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString hours',
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
  String get otherTools => 'Specific Tools';

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
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'fired $countString times',
      one: 'fired once',
      zero: 'not fired yet',
    );
    return '$_temp0';
  }

  @override
  String get connectAiApp => 'Connect an AI app';

  @override
  String connectAiAppAsk(String app) {
    return '$app wants to use Casama';
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
  String get connectAiApps => 'Connect AI Apps';

  @override
  String get connectAiAppsHelp =>
      'Apps that support MCP connect to this address and sign in, or use an API key. They act as the person who connected them.';

  @override
  String get mcpApprovals => 'Allow Approvals from AI Apps';

  @override
  String get mcpApprovalsHelp =>
      'Connected apps can approve your bots\' actions.';

  @override
  String get newApiKey => 'New API Key';

  @override
  String get apiKeyName => 'Name';

  @override
  String get newGroupChat => 'New group chat';

  @override
  String get groupChats => 'Group chats';

  @override
  String groupWhoAnswers(String names) {
    return '$names will answer';
  }

  @override
  String get groupEveryoneAnswers => 'Everyone will answer';

  @override
  String get groupMentionHint => '@mention a bot, or @everyone';

  @override
  String routineRan(String name) {
    return 'Routine “$name” ran';
  }

  @override
  String groupBotCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString bots',
      one: '1 bot',
    );
    return '$_temp0';
  }

  @override
  String botWaitingCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString things waiting for you',
      one: '1 thing waiting for you',
    );
    return '$_temp0';
  }

  @override
  String get newGroupChatHelp =>
      'Bring 2 to 10 bots into one chat. @Name asks one bot; @everyone asks the lead to plan and share out the work.';

  @override
  String get groupCreate => 'Create group chat';

  @override
  String get groupCrewEmpty => 'Pick bots below to build the group.';

  @override
  String get groupLeadShort => 'Lead';

  @override
  String get groupMakeLead => 'Make lead';

  @override
  String groupRemoveBot(String name) {
    return 'Remove $name';
  }

  @override
  String groupPickMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pick $count more bots',
      one: 'Pick 1 more bot',
    );
    return '$_temp0';
  }

  @override
  String get groupFull => 'That\'s 10 bots, the most a group can have.';

  @override
  String get groupLeadHint =>
      'The lead plans the work when you @everyone. Tap another bot at the top to make it lead.';

  @override
  String get groupNeedTwoBots =>
      'A group chat needs at least two bots. Make another bot first.';

  @override
  String get groupSearchBots => 'Search bots';

  @override
  String get groupNoMatch => 'No bots match that name.';

  @override
  String get groupTitle => 'Name (optional)';

  @override
  String get groupPickBots => 'Bots';

  @override
  String get groupLead => 'Leads the group';

  @override
  String get mentionEveryone => 'everyone';

  @override
  String get pages => 'Pages';

  @override
  String get pagesRow => 'Reports and dashboards it published';

  @override
  String get noPages => 'No pages yet';

  @override
  String get pagesHelp =>
      'Ask a bot for a report, dashboard or tracker and it can publish it as a page. Pages open in your browser and stay private until you share them.';

  @override
  String get pagePrivate => 'Only me';

  @override
  String get pageWorkspace => 'Workspace';

  @override
  String get pagePublic => 'Anyone with the link';

  @override
  String get pageRefreshes => 'Refreshes on schedule';

  @override
  String get pageCardOpen => 'Page · Tap to open';

  @override
  String pageUpdated(String date) {
    return 'Updated $date';
  }

  @override
  String get exportPdf => 'Export PDF';

  @override
  String get pageMakePublicTitle => 'Make this page public?';

  @override
  String get pageMakePublicBody =>
      'Anyone with the link can open it, including the data on it. You can take it back any time; the link stops working.';

  @override
  String get pageMakePublic => 'Make Public';

  @override
  String get pagePublicLinkTitle => 'Public Link';

  @override
  String get pagePublicLinkBody =>
      'Copied. It isn\'t listed in search engines.';

  @override
  String deletePageTitle(String title) {
    return 'Delete \"$title\"?';
  }

  @override
  String get openPages => 'Open in Pages';

  @override
  String get skillInstructions => 'Instructions';

  @override
  String get discard => 'Discard';

  @override
  String get teachTask => 'Teach a task';

  @override
  String get teachWhichBot => 'Which bot should learn this?';

  @override
  String get teachRecording => 'Recording';

  @override
  String get teachRecordingPaused => 'Recording stopped';

  @override
  String get teachRecordingHelp =>
      'Do the task as you normally would. Each step is saved with what\'s on screen; password fields never are.';

  @override
  String get teachStop => 'Stop';

  @override
  String get teachMarkSecret => 'Mark as Secret';

  @override
  String get teachMarkSecretHelp =>
      'What you just typed is deleted from the recording and becomes a secret input the bot asks for.';

  @override
  String get teachDraftTitle => 'New skill';

  @override
  String get teachDrafting => 'Writing a skill from your recording…';

  @override
  String teachSteps(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString steps',
      one: '1 step',
    );
    return '$_temp0';
  }

  @override
  String teachRecordedSteps(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString steps',
      one: '1 step',
    );
    return 'What you showed ($_temp0)';
  }

  @override
  String get teachReviewHelp =>
      'Check the steps, inputs and success checks, then save. You can try it right away.';

  @override
  String get teachDraftFailed =>
      'The bot couldn\'t write a draft. Write the steps yourself from the recording below, or discard it.';

  @override
  String get teachAlreadySaved => 'This skill is saved';

  @override
  String get teachSaveAndTry => 'Save and Try';

  @override
  String teachSaved(String name) {
    return 'Saved $name';
  }

  @override
  String get teachDiscardTitle => 'Discard this recording?';

  @override
  String get teachDiscardBody =>
      'Every step, snapshot and screenshot it captured is deleted.';

  @override
  String teachStepClick(int x, int y) {
    return 'Click at $x, $y';
  }

  @override
  String teachStepType(String text) {
    return 'Type “$text”';
  }

  @override
  String teachStepSecret(String name) {
    return 'Type secret $name';
  }

  @override
  String teachStepKey(String key) {
    return 'Press $key';
  }

  @override
  String get teachStepScroll => 'Scroll';

  @override
  String get plugins => 'Plugins';

  @override
  String get pluginsRow => 'Skills and tools from plugin packages';

  @override
  String get noPlugins => 'No plugins yet';

  @override
  String get pluginsHelp =>
      'Plugins are Agent Plugins 1.0 packages on GitHub. They can bring skills and MCP tools; their servers run on this bot\'s computer, never on Casama\'s servers.';

  @override
  String get addPlugin => 'Add a plugin';

  @override
  String get addPluginHelp =>
      'Paste a GitHub link to the plugin\'s folder. You\'ll see what it adds before anything is installed.';

  @override
  String get pluginAdds => 'It adds';

  @override
  String pluginStdio(String command) {
    return 'Runs on the bot\'s computer: $command';
  }

  @override
  String pluginRemote(String url) {
    return 'Connects to $url';
  }

  @override
  String pluginTalksTo(String hosts) {
    return 'Talks to: $hosts';
  }

  @override
  String get pluginSkill => 'Skill';

  @override
  String get pluginHosts => 'Network';

  @override
  String get pluginServerError => 'Couldn\'t start';

  @override
  String get pluginRunsOnComputer => 'Runs on the bot\'s computer';

  @override
  String get pluginWhereToolsRun => 'Where its tools run';

  @override
  String get pluginWhereToolsRunHelp =>
      'On your own computer the tools can use what\'s there, and only you can use them, from your own chats. Servers on the internet aren\'t affected.';

  @override
  String get pluginPlaceBot => 'The bot\'s computer';

  @override
  String pluginPlaceMine(String name) {
    return 'My computer: $name';
  }

  @override
  String pluginRunsOnDevice(String name) {
    return 'Runs on $name';
  }

  @override
  String get pluginRunsOnDeviceHelp =>
      'Its tools work only in chats with the person whose computer it is';

  @override
  String get pluginRunsOnDeviceOffline =>
      'Offline: its tools work again when the Casama app is open there';

  @override
  String get pluginUpToDate => 'Already up to date';

  @override
  String get checkForUpdate => 'Check for Update';

  @override
  String get uninstall => 'Uninstall';

  @override
  String uninstallPluginTitle(String name) {
    return 'Uninstall $name?';
  }

  @override
  String get uninstallPluginBody =>
      'Its skills, tools, files and saved secrets are removed from this bot.';

  @override
  String updatePluginTitle(String name) {
    return 'Update $name';
  }

  @override
  String pluginDiffSkillsAdded(String names) {
    return 'New skills: $names';
  }

  @override
  String pluginDiffSkillsChanged(String names) {
    return 'Changed skills: $names';
  }

  @override
  String pluginDiffSkillsRemoved(String names) {
    return 'Removed skills: $names';
  }

  @override
  String pluginDiffServersAdded(String names) {
    return 'New tool servers: $names';
  }

  @override
  String pluginDiffServersChanged(String names) {
    return 'Changed tool servers: $names';
  }

  @override
  String pluginDiffServersRemoved(String names) {
    return 'Removed tool servers: $names';
  }

  @override
  String pluginDiffHosts(String hosts) {
    return 'Talks to new hosts: $hosts';
  }

  @override
  String get pluginDiffNone => 'No changes to what it adds.';

  @override
  String get next => 'Next';

  @override
  String get botNameLabel => 'Name';

  @override
  String get importAgent => 'Import an Agent';

  @override
  String get importAgentPickFolder => 'Pick Its Folder';

  @override
  String get importAgentPickZip => 'Upload a ZIP of its folder';

  @override
  String get importPasteChoice => 'Paste a Bot\'s Setup';

  @override
  String get importPasteChoiceHelp =>
      'From Grok Bot, Muse, ChatGPT Dots, Claude Duet, Hark, Instinct or another app';

  @override
  String get importPasteTitle => 'Paste a Bot\'s Setup';

  @override
  String get importPasteHelp =>
      'Send your bot the prompt below, then paste its whole reply. You\'ll review everything before the new bot is created.';

  @override
  String get importPasteSource => 'Where is your bot now?';

  @override
  String get importPasteOther => 'Somewhere else';

  @override
  String get importPasteStep1 => '1. Send your bot this prompt';

  @override
  String get importPasteReply => '2. Paste its reply';

  @override
  String get importPasteSafety =>
      'Lines that look like keys, passwords or card numbers are removed. Sign in to its apps again after importing.';

  @override
  String get importPasteSubtitle => 'Pasted setup';

  @override
  String get agentImportReviewHelp =>
      'Untick anything you don\'t want. Nothing is created until you import.';

  @override
  String get agentImportNoPersona => 'No persona file was found.';

  @override
  String agentImportSkills(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString skills',
      one: '1 skill',
    );
    return '$_temp0';
  }

  @override
  String agentImportRoutines(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString routines',
      one: '1 routine',
    );
    return '$_temp0';
  }

  @override
  String agentImportMemories(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString memories',
      one: '1 memory',
    );
    return '$_temp0';
  }

  @override
  String agentImportLeftovers(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString other files',
      one: '1 other file',
    );
    return 'Copy $_temp0 to ~/imported/ on its computer';
  }

  @override
  String agentImportSkipped(String files) {
    return 'Not imported: $files';
  }

  @override
  String agentImportedWithFiles(String name, int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Imported $name and copied $countString files to its computer';
  }

  @override
  String agentImportedFilesLater(String name) {
    return 'Imported $name. Its other files couldn\'t be copied yet; give it a computer and import again to copy them.';
  }

  @override
  String get importMemoryTitle => 'Import memories from ChatGPT or Claude';

  @override
  String get importMemoryHelp =>
      'Copy this prompt into ChatGPT or Claude, then paste its answer below.';

  @override
  String get importMemoryPick => 'Keep what\'s right; untick the rest.';

  @override
  String get importMemoryPaste => 'Its answer';

  @override
  String get importMemoryNone => 'No memories found in that answer.';

  @override
  String memoriesImported(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString memories',
      one: '1 memory',
    );
    return 'Added $_temp0';
  }

  @override
  String get routinesAsFiles => 'Routines and Skills as Files';

  @override
  String get routinesAsFilesHelp =>
      'Every routine and skill as a Markdown file: export them, edit them anywhere, import them back, or keep them in a GitHub repository.';

  @override
  String get exportFiles => 'Export as Files';

  @override
  String get importFiles => 'Import Files';

  @override
  String get importFilesApply => 'Apply';

  @override
  String filesPreview(int created, int updated, int unchanged) {
    final intl.NumberFormat createdNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String createdString = createdNumberFormat.format(created);
    final intl.NumberFormat updatedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String updatedString = updatedNumberFormat.format(updated);
    final intl.NumberFormat unchangedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String unchangedString = unchangedNumberFormat.format(unchanged);

    return '$createdString new, $updatedString changed, $unchangedString unchanged';
  }

  @override
  String filesImported(int created, int updated) {
    final intl.NumberFormat createdNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String createdString = createdNumberFormat.format(created);
    final intl.NumberFormat updatedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String updatedString = updatedNumberFormat.format(updated);

    return 'Imported: $createdString new, $updatedString changed';
  }

  @override
  String get gitSync => 'Git Sync';

  @override
  String get gitSyncOff => 'Off';

  @override
  String get gitSyncHelp =>
      'Changes in Casama are committed to the repository, and pushes to it update Casama after they\'re checked. If a file changed in both places, Casama keeps its version and opens a pull request. Needs a GITHUB_TOKEN secret allowed for api.github.com.';

  @override
  String get gitSyncNeedsToken => 'Needs a GITHUB_TOKEN secret';

  @override
  String gitSyncLast(String date) {
    return 'Synced $date';
  }

  @override
  String get gitSyncPr => 'Pull Request Waiting for You';

  @override
  String get syncNow => 'Sync now';

  @override
  String get syncQueued => 'Syncing within a minute';

  @override
  String get gitBranch => 'Branch';

  @override
  String get gitFolder => 'Folder in the repository (optional)';

  @override
  String get gitSyncOn => 'Sync On';

  @override
  String get gitSyncRemove => 'Stop Syncing';

  @override
  String get gitWebhookTitle => 'Add this webhook to the repository';

  @override
  String get gitWebhookHelp =>
      'In the repository\'s settings, add a webhook for push events with this address and secret (content type application/json). The secret is shown only now.';

  @override
  String get gitWebhookUrl => 'Payload URL';

  @override
  String get gitWebhookSecret => 'Secret';

  @override
  String get knowledge => 'Knowledge';

  @override
  String get knowledgeRow => 'Documents it can search and cite';

  @override
  String get noKnowledge => 'No knowledge yet';

  @override
  String get knowledgeHelp =>
      'Give it files, a website or a GitHub repository. It searches them when they\'re relevant and tells you which document an answer came from.';

  @override
  String get addKnowledge => 'Add knowledge';

  @override
  String get addKnowledgeHelp =>
      'PDF, Word, Markdown, HTML, CSV or text files; a website (one domain, following its robots.txt); or a repository\'s documents. Websites and repositories refresh daily.';

  @override
  String get knowledgeFiles => 'Files';

  @override
  String get knowledgeWebsite => 'Website';

  @override
  String get knowledgePickFiles => 'Choose Files';

  @override
  String get knowledgeWebsiteUrl => 'Website address';

  @override
  String get knowledgeRepoUrl => 'GitHub link';

  @override
  String get knowledgeShareAll => 'Share with every bot in the workspace';

  @override
  String get knowledgeShared => 'Whole workspace';

  @override
  String knowledgeReady(int docs, int chunks) {
    final intl.NumberFormat docsNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String docsString = docsNumberFormat.format(docs);
    final intl.NumberFormat chunksNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String chunksString = chunksNumberFormat.format(chunks);

    String _temp0 = intl.Intl.pluralLogic(
      docs,
      locale: localeName,
      other: '$docsString documents',
      one: '1 document',
    );
    return '$_temp0, $chunksString passages';
  }

  @override
  String get knowledgeError => 'Couldn\'t read it';

  @override
  String get knowledgeSyncing => 'Reading…';

  @override
  String get knowledgePending => 'Waiting to be read';

  @override
  String get add => 'Add';

  @override
  String skillIdeaFrom(String bot, String name) {
    return '$bot suggests a skill: $name';
  }

  @override
  String skillEditFrom(String bot, String name) {
    return '$bot suggests improving $name';
  }

  @override
  String skillUsesTools(String tools) {
    return 'Uses: $tools';
  }

  @override
  String get saveSkill => 'Save Skill';

  @override
  String get applyEdit => 'Apply Change';

  @override
  String skillSaved(String name) {
    return 'Saved $name';
  }

  @override
  String skillUpdated(String name) {
    return 'Updated $name';
  }

  @override
  String get skillStats => 'How it\'s doing';

  @override
  String get skillNotUsedYet => 'Not used yet';

  @override
  String skillStatsLine(int uses, int rate, int failures, int corrections) {
    final intl.NumberFormat usesNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String usesString = usesNumberFormat.format(uses);
    final intl.NumberFormat rateNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String rateString = rateNumberFormat.format(rate);
    final intl.NumberFormat failuresNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String failuresString = failuresNumberFormat.format(failures);
    final intl.NumberFormat correctionsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String correctionsString = correctionsNumberFormat.format(
      corrections,
    );

    return 'Used $usesString times · $rateString% went well · $failuresString failed · $correctionsString corrected';
  }

  @override
  String skillLastFailure(String date) {
    return 'Last problem: $date';
  }

  @override
  String get skillHistory => 'Earlier versions';

  @override
  String get replays => 'Replays';

  @override
  String get replaysRow => 'Recorded steps it runs without thinking';

  @override
  String get noReplays => 'No replays yet';

  @override
  String get replaysHelp =>
      'A replay is a recorded set of browser or desktop steps the bot runs as is, which is faster and cheaper. If a step doesn\'t work any more, the bot takes over from there and can update the replay. Save one from a teach recording, or ask the bot to save what it just did.';

  @override
  String replaySteps(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString steps',
      one: '1 step',
    );
    return '$_temp0';
  }

  @override
  String replayRuns(int runs, int failures) {
    final intl.NumberFormat runsNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String runsString = runsNumberFormat.format(runs);
    final intl.NumberFormat failuresNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String failuresString = failuresNumberFormat.format(failures);

    return 'run $runsString times, $failuresString needed help';
  }

  @override
  String runReplay(String name) {
    return 'Run $name';
  }

  @override
  String get runReplayHelp => 'Check the values it fills in, then run it.';

  @override
  String get run => 'Run';

  @override
  String get saveAsReplay => 'Also Save as a Replay';

  @override
  String replaySaved(String name) {
    return 'Saved the replay $name';
  }

  @override
  String get passwordManagers => 'Password managers';

  @override
  String get passwordManagersRow => '1Password or Bitwarden logins for bots';

  @override
  String get noPasswordManagers => 'No password managers connected';

  @override
  String get passwordManagersHelp =>
      'Bots can sign in with logins from the vaults you choose. They never see a password: it\'s filled into the browser only on that login\'s own sites.';

  @override
  String get connectPasswordManager => 'Connect a password manager';

  @override
  String get pmWorkspace => 'Whole workspace';

  @override
  String get pmJustMe => 'Just me';

  @override
  String get pmNoVaults => 'No vaults chosen yet';

  @override
  String pmVaults(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString vaults',
      one: '1 vault',
    );
    return '$_temp0';
  }

  @override
  String pmLogins(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString logins',
      one: '1 login',
    );
    return '$_temp0';
  }

  @override
  String get pmOnePasswordHelp =>
      'Uses a 1Password Connect server with a service account\'s token.';

  @override
  String get pmBitwardenHelp =>
      'Uses Bitwarden\'s Vault Management API (bw serve) for your organization\'s collections.';

  @override
  String get pmConnectUrl => 'Connect server address';

  @override
  String get pmConnectToken => 'Connect token';

  @override
  String get pmBwUrl => 'bw serve address';

  @override
  String get pmBwToken => 'Access token (optional)';

  @override
  String get pmForWorkspace => 'For the Whole Workspace';

  @override
  String get pmChooseVaults => 'Vaults Bots May Use';

  @override
  String get pmChooseVaultsHelp =>
      'Only logins in the vaults or collections you tick are available to bots.';

  @override
  String get welcomeGettingReady => 'Getting your space ready…';

  @override
  String get setUpManually => 'Set Up Manually';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get inviteLinkCopied =>
      'Invite link copied. Send it to the people you work with.';

  @override
  String get inviteFriends => 'Invite Friends';

  @override
  String inviteFriendsRow(String amount) {
    return 'Earn $amount of free usage for each friend who joins';
  }

  @override
  String get inviteFriendsRowPlain => 'Share Casama with your friends';

  @override
  String inviteFriendsHeadline(String amount) {
    return 'Give Casama, Get $amount';
  }

  @override
  String get inviteFriendsHeadlinePlain => 'Share Casama with Friends';

  @override
  String inviteFriendsHelp(String amount) {
    return 'Send your link to a friend. When they sign up and finish their first chat, you get $amount of free usage.';
  }

  @override
  String get inviteFriendsHelpPlain =>
      'Send your link to a friend. They can sign up straight away.';

  @override
  String get inviteFriendsYourCode => 'Your invite code. Tap to copy.';

  @override
  String get inviteFriendsShare => 'Share Link';

  @override
  String get inviteFriendsCopyLink => 'Copy Link';

  @override
  String get inviteFriendsCopied => 'Copied. Send it to a friend.';

  @override
  String inviteFriendsShareText(String link, String code) {
    return 'Join me on Casama, where AI teammates get things done for you: $link (invite code $code)';
  }

  @override
  String get inviteFriendsProgress => 'Your Invites';

  @override
  String get inviteFriendsJoined => 'Friends Who Joined';

  @override
  String inviteFriendsPending(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString haven\'t finished a first chat yet',
      one: '1 hasn\'t finished a first chat yet',
    );
    return '$_temp0';
  }

  @override
  String get inviteFriendsEarned => 'Free Usage Earned';

  @override
  String inviteFriendsLeft(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString more friends can earn you a reward',
      one: '1 more friend can earn you a reward',
    );
    return '$_temp0';
  }

  @override
  String get inviteFriendsCapReached =>
      'You\'ve earned the most invites can give. Thank you!';

  @override
  String get inviteFriendsHow => 'How It Works';

  @override
  String get inviteFriendsStep1 => 'Share your link or code with a friend';

  @override
  String get inviteFriendsStep2 =>
      'They sign up and enter your code within a week';

  @override
  String inviteFriendsStep3(String amount) {
    return 'When they finish their first chat, you get $amount of free usage';
  }

  @override
  String get inviteFriendsStep3Plain =>
      'They get going with their own AI teammates';

  @override
  String get inviteFriendsUnavailable =>
      'Invites aren\'t available on this server.';

  @override
  String get referralHaveCode => 'Got a Friend\'s Code?';

  @override
  String get referralCodeHint => 'Invite code';

  @override
  String get referralUse => 'Use';

  @override
  String get referralRedeemed => 'Invite code added. Welcome to Casama!';

  @override
  String referralRedeemedFrom(String name) {
    return 'You joined through $name\'s invite. Welcome to Casama!';
  }

  @override
  String referralJoinedThrough(String name) {
    return 'You joined through $name\'s invite.';
  }

  @override
  String get referralJoinedThroughFriend =>
      'You joined through a friend\'s invite.';

  @override
  String referralInvitedBy(String name) {
    return '$name invited you';
  }

  @override
  String get referralInvitedByFriend => 'A friend invited you';

  @override
  String get referralWelcomeTitle => 'Welcome to Casama';

  @override
  String get referralWelcomeHelp =>
      'AI teammates that work for you on their own computers. Accept the invite so your friend gets the credit.';

  @override
  String get referralAccept => 'Accept Invite';

  @override
  String get referralGetStarted => 'Get Started';

  @override
  String get referralInvalid => 'This Invite Doesn\'t Work';

  @override
  String get referralInvalidHelp =>
      'The code may be mistyped. You can still sign up and use Casama.';

  @override
  String inviteFriendsHeadlineBoth(String amount) {
    return 'Give $amount, Get $amount';
  }

  @override
  String inviteFriendsHelpBoth(String amount) {
    return 'Send your link to a friend. When they sign up with your code and finish their first chat, you each get $amount of free usage.';
  }

  @override
  String inviteFriendsHelpTwo(String reward, String welcome) {
    return 'Send your link to a friend. When they sign up with your code and finish their first chat, you get $reward of free usage and they get $welcome.';
  }

  @override
  String inviteFriendsStep3Both(String amount) {
    return 'When they finish their first chat, you each get $amount of free usage';
  }

  @override
  String inviteFriendsStep3Two(String reward, String welcome) {
    return 'When they finish their first chat, you get $reward and they get $welcome';
  }

  @override
  String inviteFriendsShareTextBonus(String link, String code, String amount) {
    return 'Join me on Casama, where AI teammates get things done for you. Sign up with my invite code $code and you get $amount of free usage: $link';
  }

  @override
  String referralHaveCodeHelp(String amount) {
    return 'Enter it within a week of signing up and get $amount of free usage after your first chat.';
  }

  @override
  String referralWelcomeEarned(String amount) {
    return 'Your $amount welcome bonus is in your workspace.';
  }

  @override
  String referralWelcomePending(String amount) {
    return 'Your $amount welcome bonus arrives after your first chat.';
  }

  @override
  String referralWelcomeHelpBonus(String amount) {
    return 'AI teammates that work for you on their own computers. Accept the invite and get $amount of free usage after your first chat.';
  }

  @override
  String referralRedeemedBonus(String amount) {
    return 'You\'re in! Your $amount welcome bonus arrives after your first chat.';
  }

  @override
  String get connectManaged => 'Sign in through Composio';

  @override
  String connectManagedHelp(String app) {
    return 'Casama connects $app through Composio, which handles the sign-in. You can disconnect any time.';
  }

  @override
  String get sharing => 'Sharing';

  @override
  String get sharingRow => 'Who can chat with, edit or manage it';

  @override
  String get sharingHelp =>
      'Everyone in the workspace can chat with a bot unless you make it private. People you add can chat, edit its settings, or also manage who has access. A bot working for someone only uses their own personal computer and connections.';

  @override
  String get sharingPrivate => 'Private';

  @override
  String get sharingPrivateOn => 'Only you and the people below can see it';

  @override
  String get sharingPrivateOff => 'Everyone in the workspace can chat with it';

  @override
  String get sharingPeople => 'People';

  @override
  String get sharingOnlyCreator => 'Only Its Creator';

  @override
  String get sharingEveryoneChats =>
      'Everyone can chat; add people who should edit it';

  @override
  String sharingEveryoneRole(String role) {
    return 'Everyone Who Is $role';
  }

  @override
  String get accessChat => 'Can chat';

  @override
  String get accessEdit => 'Can edit';

  @override
  String get accessAdmin => 'Can manage';

  @override
  String get sharingSaved => 'Sharing saved';

  @override
  String get triggerCalendar => 'Meetings';

  @override
  String routineCalendar(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'Around matching meetings ($minutesString min)',
      zero: 'At the start of matching meetings',
    );
    return '$_temp0';
  }

  @override
  String get calendarTriggerNeedsCalendar =>
      'Connect Google Calendar or Outlook first.';

  @override
  String get calendarTriggerCalendar => 'Calendar';

  @override
  String calendarOffset(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutesString min',
      zero: 'At start',
    );
    return '$_temp0';
  }

  @override
  String get calendarOutsideGuests =>
      'Only meetings with people outside my company';

  @override
  String get calendarVideoLink => 'Only meetings with a video link';

  @override
  String get calendarTitleMatch => 'Only titles containing (optional)';

  @override
  String get fullAccess => 'Full access';

  @override
  String get fullAccessHelp =>
      'Bots act without asking first, on their computers and on your Mac. Payments, password changes and your own \"ask\" rules still ask.';

  @override
  String get fullAccessConfirmTitle => 'Turn on full access?';

  @override
  String get fullAccessConfirmBody =>
      'Every bot in this workspace will send messages, delete files, run commands on your Mac and add connections without asking you first. Payments and password changes still ask.';

  @override
  String get fullAccessTurnOn => 'Turn on';

  @override
  String get botToBot => 'Bots can talk to each other';

  @override
  String get botToBotHelp =>
      'Bots can @mention, message and hand work to each other.';

  @override
  String get capMessages => 'Messages (iMessage)';

  @override
  String get chatApps => 'Chat apps';

  @override
  String get chatAppsRow => 'Telegram, email, SMS, Slack, WhatsApp and more';

  @override
  String get botEmail => 'Email address';

  @override
  String get botEmailRow => 'Give this bot its own address';

  @override
  String botEmailClaimTitle(String name) {
    return 'Give $name an email address';
  }

  @override
  String get botEmailClaimHelp =>
      'People can write to it, and it answers by email. Forward it anything: bills, bookings, newsletters.';

  @override
  String get botEmailNameHint => 'ada';

  @override
  String get botEmailNameFixed => 'The name can\'t be changed later.';

  @override
  String get botEmailNameLabel => 'Name';

  @override
  String botEmailWillBe(String address) {
    return 'Your bot\'s address: $address.';
  }

  @override
  String get botEmailClaim => 'Create address';

  @override
  String get botEmailTaken => 'That name is taken. Try one of these:';

  @override
  String get botEmailClaimed => 'Your bot has an address';

  @override
  String get botEmailClaimedHelp =>
      'A welcome mail is on its way to you. Reply to it, or forward anything.';

  @override
  String get botEmailCopy => 'Copy';

  @override
  String get botEmailCopied => 'Copied';

  @override
  String get botEmailContacts => 'Add to contacts';

  @override
  String botEmailWrite(String name) {
    return 'Write to $name';
  }

  @override
  String get botEmailPaused =>
      'Paused. It still receives and keeps mail, but answers nothing.';

  @override
  String get botEmailPause => 'Pause';

  @override
  String get botEmailResume => 'Resume';

  @override
  String get botEmailSenders => 'Allowed senders';

  @override
  String get botEmailSendersHelp =>
      'Only these people get answers. Strangers\' mail is kept, and starts nothing.';

  @override
  String get botEmailEditSenders => 'Edit in Chat apps';

  @override
  String get botEmailMove => 'Move to another bot';

  @override
  String get botEmailMoveHelp =>
      'The address and its mail move to the other bot.';

  @override
  String get botEmailRelease => 'Release address';

  @override
  String get botEmailReleaseHelp =>
      'Stops receiving for good. The name is never given out again.';

  @override
  String botEmailReleaseConfirm(String address) {
    return 'Release $address? It stops receiving at once, and the name is never given out again.';
  }

  @override
  String get botEmailReleaseNow => 'Release';

  @override
  String get botEmailMoved => 'Moved';

  @override
  String botEmailNewBotRow(String name) {
    return 'Give $name an email address';
  }

  @override
  String get botEmailInbox => 'Inbox';

  @override
  String get botEmailInboxRow => 'Kept mail, strangers and files';

  @override
  String get botEmailEmpty => 'No mail yet';

  @override
  String get botEmailStrangers => 'Strangers';

  @override
  String get botEmailAll => 'All mail';

  @override
  String get botEmailUnconfirmed => 'Couldn\'t confirm this sender';

  @override
  String get botEmailAllow => 'Allow';

  @override
  String get botEmailBlock => 'Block';

  @override
  String get botEmailBlocked => 'Blocked. New mail from here is refused.';

  @override
  String get botEmailUnblock => 'Unblock';

  @override
  String get botEmailOpenChat => 'Open chat';

  @override
  String get botEmailFiles => 'Files';

  @override
  String get botEmailNewSenders => 'Tell me about new senders';

  @override
  String get botEmailNewSendersHelp =>
      'At most once a day. Off unless you turn it on.';

  @override
  String get botEmailTryTitle => 'Things to try';

  @override
  String get botEmailTryForward => 'Forward a bill or a booking';

  @override
  String get botEmailTryForwardHelp =>
      'Forward anything to the address above. It reads it and answers here.';

  @override
  String get botEmailTryReceipts => 'Keep my receipts';

  @override
  String botEmailTryReceiptsHelp(String address) {
    return 'Makes a routine that files mail sent to $address.';
  }

  @override
  String get botEmailTryDigest => 'One digest a week';

  @override
  String botEmailTryDigestHelp(String address) {
    return 'Makes a routine that gathers newsletters from $address into a weekly summary.';
  }

  @override
  String get botEmailTryCopied => 'Address copied';

  @override
  String get botEmailTryMade => 'Routine made';

  @override
  String get botEmailReceiptsName => 'Keep my receipts';

  @override
  String get botEmailReceiptsInstructions =>
      'File the receipt from this mail: what it was for, how much, and when. Say nothing unless something looks wrong.';

  @override
  String get botEmailDigestName => 'Weekly newsletter digest';

  @override
  String get botEmailDigestInstructions =>
      'Collect this week\'s newsletters and send one short digest: the headlines worth knowing, nothing more.';

  @override
  String get botEmailTriggerTag => 'Plus tag';

  @override
  String get botEmailTriggerTagHelp =>
      'Only mail to this tag, like shop for ada+shop@. Email addresses only.';

  @override
  String get botEmailTriggerUnconfirmed => 'Hear unconfirmed senders too';

  @override
  String get botEmailTriggerAutomatic => 'Hear automatic mail too';

  @override
  String botEmailStorage(String used, String limit) {
    return '$used of $limit';
  }

  @override
  String botEmailStorageUsed(String used) {
    return '$used used';
  }

  @override
  String get botEmailStorageFull =>
      'The mailbox is full, so new mail is refused. Delete old mail to make room.';

  @override
  String get botEmailSelect => 'Select';

  @override
  String get botEmailSelectDone => 'Done';

  @override
  String get botEmailDelete => 'Delete';

  @override
  String botEmailDeleteCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Delete $n mails',
      one: 'Delete 1 mail',
    );
    return '$_temp0';
  }

  @override
  String botEmailDeleteTitle(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Delete $n mails?',
      one: 'Delete this mail?',
    );
    return '$_temp0';
  }

  @override
  String get botEmailDeleteBody =>
      'Their text and files are gone for good. Copies already in a chat stay there.';

  @override
  String get botEmailDeleteOlder => 'Delete older mail';

  @override
  String get botEmailOlder30Days => 'Older than 30 days';

  @override
  String get botEmailOlder6Months => 'Older than 6 months';

  @override
  String get botEmailOlderYear => 'Older than a year';

  @override
  String botEmailDeleteOlderTitle(String age) {
    return 'Delete all mail $age?';
  }

  @override
  String botEmailDeleted(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Deleted $n mails',
      one: 'Deleted 1 mail',
      zero: 'Nothing to delete',
    );
    return '$_temp0';
  }

  @override
  String botEmailPerkAddresses(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n bot email addresses',
      one: '1 bot email address',
    );
    return '$_temp0';
  }

  @override
  String get botEmailPerkWritesNew => 'Bots write to new people by email';

  @override
  String get botEmailPerkRepliesOnly => 'Bots reply to you by email';

  @override
  String adminMailSentToday(int sent, int ceiling) {
    return 'Sent today: $sent of $ceiling';
  }

  @override
  String adminMailSentTodayNoCeiling(int sent) {
    return 'Sent today: $sent';
  }

  @override
  String get chatAppsAdd => 'Connect a chat app';

  @override
  String get chatAppsEmpty => 'No chat apps yet';

  @override
  String get chatAppsHelp =>
      'Let people message this bot from Telegram, email, SMS, Slack, WhatsApp, Messenger, Feishu or iMessage. It only answers people on the allowed list; everyone else is logged here.';

  @override
  String get chatAppsAddHelp =>
      'Paste the credentials from the app\'s developer settings. They\'re stored encrypted and never shown again.';

  @override
  String get chatAppsKind => 'App';

  @override
  String get chatAppsSenders => 'Allowed senders';

  @override
  String get chatAppsSendersHelp =>
      'One per line: email addresses (or *@company.com), phone numbers, or user ids. Not sure of an id? Leave it empty, message the bot, and copy the id from Activity.';

  @override
  String get chatAppsMac => 'Mac';

  @override
  String get chatAppsNoMac =>
      'Turn on \"Use this computer for bots\" with Messages allowed in the desktop app on your Mac first.';

  @override
  String chatAppsConnected(String name) {
    return '$name is connected';
  }

  @override
  String get chatAppsTelegramDone =>
      'Telegram is already sending messages here. Message your bot to try it.';

  @override
  String get chatAppsPasteUrl =>
      'Paste this address into the app\'s webhook settings.';

  @override
  String get chatAppsWebhookUrl => 'Webhook address';

  @override
  String get chatAppsVerifyToken => 'Verify token';

  @override
  String chatAppsAllowed(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString allowed senders',
      one: '1 allowed sender',
      zero: 'Nobody allowed',
    );
    return '$_temp0';
  }

  @override
  String get chatAppsActivity => 'Activity';

  @override
  String get chatAppsNoActivity => 'No messages yet.';

  @override
  String get chatAppsIgnored => 'Ignored: not on the allowed list';

  @override
  String get chatAppsAllow => 'Allow';

  @override
  String chatAppsSenderAllowed(String sender) {
    return '$sender can now message this bot';
  }

  @override
  String get chatAppsRoutine => 'Started a routine';

  @override
  String get chatAppsFailed => 'Couldn\'t send';

  @override
  String get chatAppsSent => 'Sent';

  @override
  String get chatAppsAnswered => 'Answered';

  @override
  String get chatAppsRemove => 'Disconnect';

  @override
  String get chBotToken => 'Bot token';

  @override
  String get chAddress => 'Email address';

  @override
  String get chApiKey => 'API key';

  @override
  String get chSigningSecret => 'Signing secret';

  @override
  String get chPhoneNumber => 'Phone number';

  @override
  String get chAccountSid => 'Account SID';

  @override
  String get chAuthToken => 'Auth token';

  @override
  String get chPhoneNumberId => 'Phone number ID';

  @override
  String get chAccessToken => 'Access token';

  @override
  String get chAppSecret => 'App secret';

  @override
  String get chPageToken => 'Page access token';

  @override
  String get chAppId => 'App ID';

  @override
  String get chEncryptKey => 'Encrypt key';

  @override
  String get chVerificationToken => 'Verification token';

  @override
  String get chPublicKey => 'Public key';

  @override
  String get chTrackerUser => 'The bot\'s user ID in the tracker';

  @override
  String get chSiteUrl => 'Site address (https://…)';

  @override
  String get chAccountEmail => 'Account email';

  @override
  String get routineMessage => 'When a matching message arrives';

  @override
  String get triggerMessage => 'Messages';

  @override
  String get messageTriggerHelp =>
      'Starts when an email or chat message to this bot matches. Connect the app under Chat apps first.';

  @override
  String get messageTriggerAnyApp => 'Any app';

  @override
  String get messageTriggerSender => 'From (address, number, or *@company.com)';

  @override
  String get messageTriggerSubject => 'Subject contains';

  @override
  String get messageTriggerWords => 'Message contains';

  @override
  String callIncoming(String name) {
    return '$name is calling';
  }

  @override
  String get callAnswer => 'Answer';

  @override
  String get callDecline => 'Decline';

  @override
  String get callFullScreenTitle => 'Calls on the Lock Screen';

  @override
  String get callFullScreenOff =>
      'Off: a bot\'s call shows only as a notification. Tap to let calls ring on the full screen.';

  @override
  String get encryption => 'Encrypt Content';

  @override
  String get encryptionHelp =>
      'Messages, memories, tickets, pages and knowledge are encrypted before they\'re stored, with this workspace\'s own key. Search then matches titles and meaning, not exact words in encrypted text.';

  @override
  String get encryptionOff => 'Off';

  @override
  String get encryptionUnavailable =>
      'Not available: this server has no encryption key set up';

  @override
  String get encryptionEncrypting =>
      'Turning on: encrypting what\'s already stored';

  @override
  String get encryptionOnServer => 'On, with the server\'s key';

  @override
  String get encryptionOnKms => 'On, with AWS KMS';

  @override
  String get encryptionDecrypting => 'Turning off: decrypting what\'s stored';

  @override
  String get encryptionConfirm =>
      'Content will be encrypted with this workspace\'s key. If the workspace is deleted, its key is destroyed and the content can\'t be recovered. Exact-word search stops matching encrypted text.';

  @override
  String get encryptionTurnOn => 'Turn On';

  @override
  String get encryptionRotate => 'Rotate Key';

  @override
  String get encryptionKeyManaged =>
      'Casama creates and keeps this workspace\'s key for you, wrapped with the server\'s own key. There\'s nothing to save or copy.';

  @override
  String get encryptionRotateTitle => 'Rotate the key?';

  @override
  String get encryptionRotateBody =>
      'The workspace key is wrapped again with the server\'s current key. Your content stays readable and nothing needs re-encrypting. Do this after changing the server\'s key, or on a schedule.';

  @override
  String get encryptionRotateHelp =>
      'Rewraps the workspace key with the server\'s current key';

  @override
  String encryptionRotated(String date) {
    return 'Last rotated $date';
  }

  @override
  String get memoryBackend => 'Where Memory Is Kept';

  @override
  String get memoryBuiltIn => 'Built in';

  @override
  String get memoryBackendHelp => 'Bots\' long-term memory';

  @override
  String get memoryBackendSheetHelp =>
      'Keep your bots\' memory in Honcho or Supermemory with your own account. The memory screen, exports and deletion work the same.';

  @override
  String get memoryHonchoWorkspace => 'Honcho workspace';

  @override
  String get memoryHonchoWorkspaceHelp =>
      'Leave empty to use one made for this Casama workspace';

  @override
  String get memoryBaseUrl => 'Server address (optional)';

  @override
  String get memoryBaseUrlHelp =>
      'Only for a self-hosted Honcho or Supermemory';

  @override
  String get memoryCopyExisting => 'Copy Current Memories Over';

  @override
  String get memoryUseBuiltIn => 'Use Built-in Memory Again';

  @override
  String get providerHintData => 'paid data (places, emails, SEO)';

  @override
  String get kindA2a => 'AI agent (A2A)';

  @override
  String get a2aAgentUrl => 'Agent address or agent card URL';

  @override
  String get a2aAgentToken => 'Access token (optional)';

  @override
  String get a2a => 'Agent-to-Agent (A2A)';

  @override
  String get a2aHelp => 'Outside agents can give tasks to bots you publish.';

  @override
  String get chromeExtensionSwitch => 'Casama for Chrome';

  @override
  String get chromeExtensionSwitchHelp =>
      'Members can use the browser extension with this workspace.';

  @override
  String get chromeActSwitch => 'Bots in Members\' Browsers';

  @override
  String get chromeActSwitchHelp =>
      'Members can let bots open pages and act in their own Chrome, in a tab group they can stop.';

  @override
  String get a2aPublish => 'Publish as an A2A Agent';

  @override
  String get a2aPublishHelp =>
      'Outside agents with a workspace API key can give this bot tasks.';

  @override
  String get a2aWorkspaceOff =>
      'Turn on agent-to-agent in workspace settings first.';

  @override
  String get a2aCardUrl => 'Agent card';

  @override
  String get phoneCalls => 'Phone Calls';

  @override
  String get phoneCallsHelp =>
      'Let bots call businesses for you through your Twilio account. Every call asks first under the usual approvals.';

  @override
  String get twilioSid => 'Account SID';

  @override
  String get twilioToken => 'Auth token';

  @override
  String get twilioFrom => 'Calls come from';

  @override
  String get phoneCallsPersonal => 'Allow Calling Personal Numbers';

  @override
  String get phoneCallsCap => 'Calls per day';

  @override
  String get phoneCallsOff => 'Not connected';

  @override
  String get outCall => 'Call';

  @override
  String get outCallRinging => 'Ringing…';

  @override
  String get outCallLive => 'On the call';

  @override
  String outCallEnded(int seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return 'Ended after ${secondsString}s';
  }

  @override
  String get outCallEndedByYou => 'You ended the call';

  @override
  String get outCallTakenOver => 'You took over the call';

  @override
  String get outCallFailed => 'Didn\'t go through';

  @override
  String get outCallNothingYet => 'Nothing said yet.';

  @override
  String get outCallTakeOver => 'Take Over';

  @override
  String get outCallEnd => 'End Call';

  @override
  String get outCallYourPhone => 'Your phone number';

  @override
  String get outCallYourPhoneHelp =>
      'International format, like +14155550123. Leave empty to use the one saved.';

  @override
  String get payments => 'Payments';

  @override
  String get paymentsHelp =>
      'Let bots pay merchants with single-use virtual cards you approve each time. Bring your own Stripe Issuing account.';

  @override
  String paymentsOn(String spent, String cap) {
    return '$spent spent this month of $cap';
  }

  @override
  String get paymentsSheetHelp =>
      'Every card is approved by you with the amount shown, works once at that merchant for one hour, and never for securities, crypto, gift cards or transfers.';

  @override
  String get paymentsStripeKey => 'Stripe secret key (with Issuing)';

  @override
  String get paymentsWebhookSecret => 'Webhook signing secret';

  @override
  String get paymentsWebhook => 'Point a Stripe webhook here';

  @override
  String get paymentsCardholder => 'Name on cards';

  @override
  String get paymentsAddress => 'Billing address';

  @override
  String get paymentsCity => 'City';

  @override
  String get paymentsState => 'State or region';

  @override
  String get paymentsZip => 'Postal code';

  @override
  String get paymentsCountry => 'Country (2 letters)';

  @override
  String get paymentsCap => 'Workspace limit per month (USD)';

  @override
  String get paymentsBotCap => 'Per-bot limit per month (USD)';

  @override
  String get links => 'Linked bots';

  @override
  String get linksRow => 'Link with a trusted contact\'s bot';

  @override
  String get linksHelp =>
      'Your bot can ask a linked contact\'s bot for things like a dinner slot. Each bot answers under its own person\'s rules and shares only what\'s needed; both of you see every exchange.';

  @override
  String get linksEmpty => 'No linked bots yet';

  @override
  String get linksInvite => 'Invite a contact';

  @override
  String get linksContactName => 'Contact\'s name';

  @override
  String get linksInviteReady => 'Send This Invite';

  @override
  String get linksInviteHelp =>
      'Send it to your contact. They accept it in Casama with one of their bots. It works once, for 7 days.';

  @override
  String get linksAccept => 'Accept an invite';

  @override
  String get linksAcceptHelp => 'Paste the invite your contact sent you.';

  @override
  String get linksInviteText => 'Invite';

  @override
  String linksActive(String bot) {
    return 'Linked with $bot';
  }

  @override
  String get linksPending => 'Waiting for your contact to accept';

  @override
  String get linksRevoked => 'Unlinked';

  @override
  String get linksExchanges => 'Exchanges';

  @override
  String get linksNoExchanges => 'Nothing asked yet.';

  @override
  String get linksNoAnswer => 'No answer';

  @override
  String get linksWorking => 'Working…';

  @override
  String get linksRevoke => 'Unlink';

  @override
  String get wakeWord => 'Wake Word';

  @override
  String get wakeWordRow => 'Say a phrase to start a call with a bot';

  @override
  String wakeWordOnRow(String phrase) {
    return 'Listening for \"$phrase\"';
  }

  @override
  String get wakeWordHelp =>
      'While Casama is open, this device listens for your phrase and starts a live call with the bot you choose.';

  @override
  String get wakeWordListen => 'Listen for the Wake Word';

  @override
  String get wakeWordPhrase => 'Phrase';

  @override
  String get wakeWordPhraseHelp => 'Two or three words, like \"hey casama\"';

  @override
  String get wakeWordBot => 'Call this bot';

  @override
  String get wakeWordDownloading => 'Downloading the on-device model…';

  @override
  String get wakeWordPrivacy =>
      'Listening happens on this device with an open-source model (about 18 MB, downloaded once). Nothing is sent anywhere until the call starts.';

  @override
  String get secretStore => 'Where Secrets Are Kept';

  @override
  String get secretStoreVault => 'This server\'s vault';

  @override
  String get secretStoreHelp =>
      'Keep bots\' named secrets in your own Infisical project. Casama keeps only each secret\'s name and where it may be used.';

  @override
  String get secretStoreSite => 'Infisical address';

  @override
  String get secretStoreProject => 'Project ID';

  @override
  String get secretStoreEnv => 'Environment';

  @override
  String get secretStoreClientId => 'Machine identity client ID';

  @override
  String get secretStoreClientSecret => 'Client secret';

  @override
  String get secretStoreMove => 'Move Current Secrets into Infisical';

  @override
  String get secretStoreBack => 'Use This Server\'s Vault Again';

  @override
  String get localServer => 'Run Casama on This Computer';

  @override
  String get setupTitleMac => 'Set Up Casama on This Mac';

  @override
  String get setupTitle => 'Set Up Casama on This Computer';

  @override
  String get setupEntryMac => 'Run on This Mac';

  @override
  String get setupEntry => 'Run on This Computer';

  @override
  String get setupEntryHelp =>
      'Free and private: your own server, on this computer.';

  @override
  String get setupStepDocker => 'Docker';

  @override
  String get setupStepServer => 'Server';

  @override
  String get setupStepAccount => 'Account';

  @override
  String get setupStepModel => 'AI model';

  @override
  String get setupStepPhone => 'Phone';

  @override
  String get setupDockerChecking => 'Checking Docker…';

  @override
  String get setupDockerMissingTitle => 'First, install Docker';

  @override
  String get setupDockerMissingBodyMac =>
      'Casama\'s server runs inside Docker Desktop, a free app that keeps it separate from the rest of your Mac.';

  @override
  String get setupDockerMissingBodyLinux =>
      'Casama\'s server runs inside Docker, which keeps it separate from the rest of your computer.';

  @override
  String get setupDockerGetMac => 'Download Docker Desktop';

  @override
  String get setupDockerGetLinux => 'Open Docker\'s Install Guide';

  @override
  String get setupDockerStep1 =>
      'Open the file that downloads and drag Docker to Applications.';

  @override
  String get setupDockerStep2 => 'Open Docker and accept its terms.';

  @override
  String get setupDockerStep3 =>
      'Come back here. This page continues by itself.';

  @override
  String get setupDockerWaiting => 'Waiting for Docker…';

  @override
  String get setupDockerStoppedTitle => 'Docker needs to be running';

  @override
  String get setupDockerStoppedBodyMac =>
      'Docker is installed but not open. Once it has started, which can take a minute, this page continues by itself.';

  @override
  String get setupDockerStoppedBodyLinux =>
      'Docker is installed but not running. Start it with this command, and this page continues by itself.';

  @override
  String get setupDockerOpen => 'Open Docker';

  @override
  String get setupDockerOpening => 'Starting Docker…';

  @override
  String get setupDockerPermissionTitle => 'Docker needs your permission';

  @override
  String get setupDockerPermissionBody =>
      'Docker is running, but your user isn\'t allowed to use it. Run this command, then log out and back in.';

  @override
  String get setupDockerComposeTitle => 'Docker is missing Compose';

  @override
  String get setupDockerComposeBody =>
      'This Docker has no Compose v2. Docker Desktop includes it; on Linux, install the docker-compose-plugin package.';

  @override
  String setupDiskLow(String gb) {
    return 'Only $gb GB of disk space is free. The server needs about 10 GB.';
  }

  @override
  String get setupServerTitle => 'Download and start your server';

  @override
  String get setupServerBody =>
      'About 10 GB and 5 to 10 minutes the first time. You can keep using your computer.';

  @override
  String get setupServerStart => 'Start';

  @override
  String get setupServerStageDownload => 'Downloading the server';

  @override
  String get setupServerStagePrepare => 'Getting it ready';

  @override
  String get setupServerStageParts => 'Downloading its parts';

  @override
  String get setupServerStagePartsNote => 'The longest step';

  @override
  String get setupServerStageStart => 'Starting it';

  @override
  String get setupServerStageWait => 'Waiting for it to answer';

  @override
  String get setupServerKeepOpen => 'Keep Casama open until this finishes.';

  @override
  String get setupServerFailed => 'The server didn\'t start.';

  @override
  String get setupServerConnecting => 'Ready. Connecting…';

  @override
  String get setupShowDetails => 'Show Details';

  @override
  String get setupHideDetails => 'Hide Details';

  @override
  String get setupAccountTitle => 'Create your account';

  @override
  String get setupAccountBody =>
      'It lives on this computer only, and it owns this server. No email is sent.';

  @override
  String get setupAccountName => 'Your name';

  @override
  String get setupAccountNameMissing => 'Enter your name';

  @override
  String get setupAccountCreate => 'Create Account';

  @override
  String get setupAccountHave => 'I Already Have an Account Here';

  @override
  String get setupAccountNew => 'Create a New Account Instead';

  @override
  String get setupAccountSignInTitle => 'Sign in to your server';

  @override
  String get setupAccountSignInBody =>
      'Use the account you made on this server.';

  @override
  String get setupAccountClosed =>
      'This server already has its owner. Sign in with that account.';

  @override
  String get setupAccountPreparing => 'Getting your space ready…';

  @override
  String get setupModelTitle => 'Give your bots a model';

  @override
  String get setupModelBody =>
      'Bots need an AI model to think with. Sign in with a ChatGPT plan, or paste a key from OpenRouter, Google or another provider.';

  @override
  String get setupSkip => 'Skip for Now';

  @override
  String get setupPhoneTitle => 'Connect your phone';

  @override
  String get setupPhoneBody =>
      'Casama Link gives this computer a private address, so your phone reaches it from anywhere. You approve it once with a free Casama Cloud account. Your chats stay on this computer.';

  @override
  String get setupPhoneTurnOn => 'Give This Computer an Address';

  @override
  String get setupPhoneScanTitle => 'Scan this with your phone\'s camera';

  @override
  String get setupPhoneScanBody =>
      'It opens Casama on the phone and signs you in. If Casama isn\'t on the phone yet, the page that opens says where to get it.';

  @override
  String get setupPhoneWaiting => 'Waiting for your phone…';

  @override
  String get setupPhoneConnected => 'Phone connected';

  @override
  String get setupPhoneConnectedBody =>
      'Your phone is signed in. Show a new code to add another device.';

  @override
  String get setupPhoneOwnerOnly =>
      'Only this server\'s owner can give it an address.';

  @override
  String get setupFinish => 'Finish';

  @override
  String get setupCardTitle => 'Finish setting up';

  @override
  String get setupCardModel => 'Add an AI model so your bots can answer.';

  @override
  String get setupCardPhone => 'Connect your phone to this computer.';

  @override
  String get setupCardOpen => 'Continue Setup';

  @override
  String get desktopUsers => 'Desktop users at once';

  @override
  String get desktopUsersHelp =>
      'Bots on this team computer share one screen. Others wait (and keep working with the shell, files and browser) while it\'s in use.';

  @override
  String desktopUsersCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString bots',
      one: '1 bot',
    );
    return '$_temp0';
  }

  @override
  String deviceAccessTitle(String bot, String what) {
    return '$bot would like to use your $what';
  }

  @override
  String get deviceAccessHelp =>
      'Only in your own chats. You can stop it any time in Settings → Device connections.';

  @override
  String deviceAccessAllowed(String what) {
    return 'Allowed to use your $what';
  }

  @override
  String get deviceAccessSkipped => 'Not shared';

  @override
  String get deviceKindCalendar => 'calendar';

  @override
  String get deviceKindReminders => 'reminders';

  @override
  String get deviceKindContacts => 'contacts';

  @override
  String get deviceKindPlaces => 'places';

  @override
  String get deviceKindPhotos => 'photos';

  @override
  String get deviceKindHealth => 'health data';

  @override
  String get deviceKindNotifications => 'notifications';

  @override
  String get deviceKindActivity => 'computer activity';

  @override
  String get deviceKindBrowserTab => 'current browser tab';

  @override
  String get deviceKindBrowserHistory => 'browser history and bookmarks';

  @override
  String get deviceBrowserAsks => 'What Bots May Ask Your Browser';

  @override
  String get deviceBrowserAsksHelp =>
      'Casama for Chrome answers these live and nothing is kept. Turn them on or off in the extension\'s settings.';

  @override
  String deviceBrowserAskRevoke(String bot) {
    return 'Stop letting $bot ask';
  }

  @override
  String get deviceConnections => 'Device connections';

  @override
  String get deviceConnectionsHelp =>
      'Share data from this device with your bots. Each kind is off until you turn it on, and only bots you allow can read it, only in your own chats.';

  @override
  String get deviceConnectionsNone =>
      'This device can\'t share data yet. On your phone, open Casama and turn on what you\'d like to share.';

  @override
  String get deviceKeepFor => 'Keep for';

  @override
  String get deviceKeepLiveOnly => 'Live only';

  @override
  String deviceKeepDays(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get devicePrivateModel => 'Private Models Only';

  @override
  String get devicePrivateModelHelp => 'Only bots on a local model can read it';

  @override
  String get deviceNoBots =>
      'No bots yet. A bot asks when it needs this, or allow one now.';

  @override
  String get deviceAllowBot => 'Allow a bot';

  @override
  String deviceAllowBotTitle(String kind) {
    return 'Which bot may read your $kind?';
  }

  @override
  String get devicePermissionDenied =>
      'Casama doesn\'t have permission. Allow it in the system settings, then try again.';

  @override
  String get deviceOtherDevices => 'Your Other Devices';

  @override
  String get deviceForget => 'Forget this device';

  @override
  String get deviceBrowsers => 'Browsers Bots Can Use';

  @override
  String get deviceBrowsersHelp =>
      'Paired in Casama for Chrome. Bots you allowed work there in their own tab group, signed in as you.';

  @override
  String deviceBrowserBots(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bots',
      one: '1 bot',
      zero: 'No bots yet',
    );
    return '$_temp0';
  }

  @override
  String get deviceBrowserOnline => 'Online';

  @override
  String get deviceBrowserOffline => 'Offline';

  @override
  String get deviceBrowserUnpair => 'Unpair this browser';

  @override
  String get deviceConnectionsRowHelp =>
      'Calendar, contacts and more from this device';

  @override
  String get healthExtraCycle => 'Cycle tracking';

  @override
  String get healthExtraGlucose => 'Blood glucose';

  @override
  String get healthExtraBloodPressure => 'Blood pressure';

  @override
  String get healthNotMedical =>
      'Daily summaries only (sleep, activity, workouts, heart). Bots describe how you compare with your usual and never give medical advice.';

  @override
  String get healthNeedsEncryption =>
      'Health data needs encryption at rest. Turn it on for a workspace you own, then try again.';

  @override
  String get placeAddHere => 'Add Where I Am Now';

  @override
  String get placeName => 'Name this place (Home, Work, Gym)';

  @override
  String get placeNoLocation =>
      'Your location isn\'t available. Allow location for Casama, then try again.';

  @override
  String get placesHelp =>
      'Bots hear when you arrive at or leave these places. Only the place name and the time are shared, never your route.';

  @override
  String get watchedAppsHelp =>
      'Only notifications from these apps are shared. One-time codes are hidden before anything leaves your phone.';

  @override
  String get watchedAppAdd => 'Add an app (name or package id)';

  @override
  String get providerHintMaps => 'travel times for leave-now';

  @override
  String routineDevice(String event, String detail) {
    return 'On your phone: $event $detail';
  }

  @override
  String get ctxSelection => 'Selected Text';

  @override
  String get ctxAddScreenshot => 'Add a Screenshot';

  @override
  String get ctxScreenshotAdded => 'Screenshot Added';

  @override
  String get ctxScreenshotFailed =>
      'Couldn\'t take a screenshot. Allow screen recording for Casama in your system settings.';

  @override
  String get watchedFolders => 'Watched Folders';

  @override
  String get watchedFoldersHelp =>
      'A new file in one of these folders can start a routine (for example, file new PDFs in Downloads). Only its name is shared; bots read the file only if they work on this computer.';

  @override
  String get whyTitle => 'Why am I seeing this?';

  @override
  String whyData(String data) {
    return 'Used: $data';
  }

  @override
  String whyUrgency(String urgency) {
    return 'Urgency: $urgency';
  }

  @override
  String get heldMeeting =>
      'It waited while you were in a meeting and came with your brief.';

  @override
  String get heldFocus =>
      'It waited while Focus was on and came with your brief.';

  @override
  String get heldDriving =>
      'It waited while you were driving and came with your brief.';

  @override
  String get heldCap =>
      'The bot had already sent 5 messages today, so this one waited for your brief.';

  @override
  String get heldLow =>
      'It wasn\'t urgent, so it waited for your brief instead of buzzing your phone.';

  @override
  String get lessLikeThis => 'Less like this';

  @override
  String get lessLikeThisDone => 'Got It, Fewer Like This';

  @override
  String get widgetStatusWorking => 'Working…';

  @override
  String get widgetStatusOff => 'Turned off';

  @override
  String get adminNoWorkspaces => 'No workspaces yet';

  @override
  String get suspendedByInstanceOwner => 'Suspended by the instance owner';

  @override
  String get previewHi => 'Hi!';

  @override
  String get previewAsk => 'Can you tidy up my notes?';

  @override
  String get previewOnIt => 'On it';

  @override
  String get previewDone => 'Done! They are in three folders now.';

  @override
  String get previewMessage => 'Message';

  @override
  String get fontPreviewGreeting => 'Good morning';

  @override
  String get photosFromUnsplash => 'Photos from Unsplash';

  @override
  String get showBotSteps => 'Show the bot\'s steps';

  @override
  String get showBotStepsHelp => 'Commands and technical errors in every chat.';

  @override
  String get showReplyUsage => 'Show usage on replies';

  @override
  String get showReplyUsageHelp => 'What each reply cost, in a line under it.';

  @override
  String get openLinksInApp => 'Open links in the app';

  @override
  String get openLinksInAppHelp =>
      'Web links open in a browser inside Casama. Off: they open in your default browser.';

  @override
  String replyUsageTokens(String count) {
    return '$count tokens';
  }

  @override
  String replyUsageOnYourKeys(String amount) {
    return '$amount on your keys';
  }

  @override
  String get replyUsageOnPlan => 'On your ChatGPT plan';

  @override
  String replyUsageSoFar(String amount) {
    return '$amount so far';
  }

  @override
  String get replyUsageTooltip => 'What this reply cost';

  @override
  String get replyUsageTitle => 'What this reply cost';

  @override
  String get replyUsageFromCredits => 'From your credits';

  @override
  String get replyUsageYourKeys => 'On your own keys';

  @override
  String get replyUsageTotal => 'Total';

  @override
  String get replyUsageTime => 'Time';

  @override
  String get replyUsageTokensLabel => 'Tokens';

  @override
  String get replyUsageSteps => 'Steps';

  @override
  String replyUsageHelpers(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Includes $n helper runs',
      one: 'Includes 1 helper run',
    );
    return '$_temp0';
  }

  @override
  String get replyUsageNothing => 'Nothing was metered for this reply.';

  @override
  String get replyUsageCreditsNote =>
      '1 credit = \$1. Your own keys and plans are billed by their provider, not by Casama.';

  @override
  String get replyUsageOpenRun => 'Open the run';

  @override
  String get replyUsageLoadFailed => 'Couldn\'t load this reply\'s usage.';

  @override
  String get replyUsageOurCost => 'Our cost';

  @override
  String get replyUsageMargin => 'Margin';

  @override
  String replyUsageItemCost(String amount) {
    return 'Our cost $amount';
  }

  @override
  String get replyUsageAdminNote =>
      'Our cost and margin are shown to you because you run this server. Nobody else sees them.';

  @override
  String get adminMarginTitle => 'Usage margin';

  @override
  String adminMarginDays(int n) {
    return '$n days';
  }

  @override
  String get adminMarginCharged => 'Charged';

  @override
  String get adminMarginCost => 'Our cost';

  @override
  String get adminMarginProfit => 'Margin';

  @override
  String get adminMarginEmpty =>
      'Nothing was used on the server\'s keys in this period.';

  @override
  String adminMarginUntracked(String amount) {
    return 'Plus $amount charged with no cost recorded, left out of the margin.';
  }

  @override
  String get adminMarginNote =>
      'Usage paid from credits, against what the providers charged the server (OpenRouter\'s fee included). Computers count at their provider\'s rate. Cost also includes usage that was given back and web search on the server\'s own providers, which isn\'t charged.';

  @override
  String adminMarginRow(String charged, String cost, String margin) {
    return '$charged charged · $cost cost · $margin margin';
  }

  @override
  String adminMarginRowUntracked(String charged) {
    return '$charged charged · no cost recorded';
  }

  @override
  String adminMarginRowNoCost(String amount) {
    return '$amount with no cost recorded';
  }

  @override
  String get adminMarginByKind => 'By kind';

  @override
  String get adminMarginTopOrgs => 'Top workspaces';

  @override
  String get kindSpeechToText => 'Voice to text';

  @override
  String get kindVoice => 'Voice calls';

  @override
  String get kindImages => 'Images';

  @override
  String get kindVideo => 'Video';

  @override
  String get kindSearch => 'Web searches';

  @override
  String get kindData => 'Data lookups';

  @override
  String get kindPhone => 'Phone calls';

  @override
  String get kindApps => 'App actions';

  @override
  String get activityReady => 'Getting ready…';

  @override
  String get activitySearching => 'Searching the web…';

  @override
  String get activityBrowsing => 'Browsing the web…';

  @override
  String get activityComputer => 'Working on its computer…';

  @override
  String get activityFiles => 'Going through files…';

  @override
  String get activityImage => 'Making an image…';

  @override
  String get activityVideo => 'Making a video…';

  @override
  String get activityMemory => 'Checking what it knows…';

  @override
  String get activityApps => 'Using your apps…';

  @override
  String get activityScheduling => 'Setting up a schedule…';

  @override
  String get activityWorking => 'Working on it…';

  @override
  String get activityWaitingForScreen =>
      'Waiting for you to hand back the screen…';

  @override
  String get runFailedPlain =>
      'Something went wrong. Try again, or open Details to see why.';

  @override
  String get newKeyTitle => 'Copy your new key';

  @override
  String get newKeyHelp =>
      'It\'s shown only this once. Paste it into the app you\'re connecting, then tap Done.';

  @override
  String get copyKey => 'Copy Key';

  @override
  String get keyCopied => 'Key copied';

  @override
  String revokeApiKeyTitle(String name) {
    return 'Revoke “$name”?';
  }

  @override
  String get revokeApiKeyBody =>
      'Apps using this key stop connecting right away. This can\'t be undone; to reconnect, make a new key.';

  @override
  String unlinkTitle(String name) {
    return 'Unlink “$name”?';
  }

  @override
  String get unlinkBody =>
      'The bots stop talking to each other right away. Linking them again needs a new invite.';

  @override
  String get alreadyMember => 'You\'re already in this workspace.';

  @override
  String get askAdminToInvite =>
      'Only owners and admins can invite people. Ask one of them for an invite link.';

  @override
  String get askBeforeJoining => 'Ask Me Before People Join';

  @override
  String get askBeforeJoiningHelp =>
      'An admin approves each person who uses the link.';

  @override
  String get askToJoin => 'Ask to join';

  @override
  String get customLinks => 'Custom links';

  @override
  String get customLinksHelp =>
      'Links with their own role, expiry or number of uses.';

  @override
  String get emailAddresses => 'Email addresses';

  @override
  String get emailAddressesHelp =>
      'Paste one or more, separated by commas or new lines.';

  @override
  String get getCode => 'Get a Code';

  @override
  String get getNewCode => 'Get a New Code';

  @override
  String get getStarted => 'Get Started';

  @override
  String get welcomeCta => 'Let\'s Go';

  @override
  String get inviteAsAdmin => 'Invite as Admins';

  @override
  String get inviteByEmail => 'Invite by Email';

  @override
  String get inviteExpired => 'Expired';

  @override
  String inviteExpires(String when) {
    return 'Expires $when';
  }

  @override
  String get inviteInvalid => 'This invite doesn\'t work';

  @override
  String get inviteInvalidHelp =>
      'It may have expired, been used up or been turned off. Ask for a new one.';

  @override
  String get inviteLink => 'Invite link';

  @override
  String get inviteLinkApprovalHelp =>
      'Anyone with this link can ask to join. You approve them below.';

  @override
  String get inviteLinkHelp =>
      'Anyone with this link can join as a member. Share it in a chat or email.';

  @override
  String get inviteLinkOrCode => 'Invite link or code';

  @override
  String inviteOtherServer(String host) {
    return 'This invite is for $host, and this app is connected to a different server.';
  }

  @override
  String get inviteRenewed =>
      'The invite works for 7 more days. Send them the new link.';

  @override
  String inviteSentTo(String email) {
    return 'Sign in with $email to accept.';
  }

  @override
  String inviteShareText(String workspace, String url) {
    return 'Join $workspace on Casama: $url';
  }

  @override
  String invitedBy(String name) {
    return '$name invited you to join';
  }

  @override
  String get invitedToJoin => 'You\'re invited to join';

  @override
  String invitesSent(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString invites sent.',
      one: 'Invite sent.',
    );
    return '$_temp0';
  }

  @override
  String get joinAsAdmin => 'You\'ll join as an admin';

  @override
  String get joinAsMember => 'You\'ll join as a member';

  @override
  String get joinByDomain => 'Join by Email Domain';

  @override
  String get joinByDomainHelp => 'Verified addresses join without an invite.';

  @override
  String joinByDomainSwitch(String domain) {
    return 'Anyone with a verified @$domain email can join';
  }

  @override
  String get joinByDomainUnavailable =>
      'Available when you sign in with a verified work email (not gmail.com and the like).';

  @override
  String get joinNeedsApproval =>
      'An admin approves new people before they join.';

  @override
  String get joinRequestSent => 'Request sent';

  @override
  String joinRequestSentHelp(String name) {
    return 'An admin of $name will look at it. You\'ll get a notification when you\'re in.';
  }

  @override
  String get joinWithLinkOrCode => 'Join with a link or code';

  @override
  String get spacesInvite => 'Invite people';

  @override
  String spacesInviteTo(String name) {
    return 'To $name';
  }

  @override
  String get spacesNew => 'New workspace';

  @override
  String get spacesNewHint => 'Its own bots, people and billing';

  @override
  String get spacesJoin => 'Join a workspace';

  @override
  String get spacesJoinHint => 'With an invite link or code';

  @override
  String joinWorkspaceNamed(String name) {
    return 'Join $name';
  }

  @override
  String get joinedBotsHelp =>
      'These bots are here to help. Say hello to one to get started.';

  @override
  String get joinedNoBots =>
      'There are no bots here yet. Make one, or look around first.';

  @override
  String memberCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString members',
      one: '1 member',
    );
    return '$_temp0';
  }

  @override
  String get members => 'Members';

  @override
  String openToDomain(String domain) {
    return 'Open to @$domain';
  }

  @override
  String openWorkspace(String name) {
    return 'Open $name';
  }

  @override
  String get pendingInvites => 'Invites Not Accepted Yet';

  @override
  String get people => 'People';

  @override
  String get workspaceAdvancedSummary =>
      'Secrets, memory, encryption, payments, MCP';

  @override
  String get peopleAdvancedSummary => 'Invite code, email domain, custom links';

  @override
  String get inviteLinkToCopy => 'Invite link, ready to copy';

  @override
  String linkMade(String when) {
    return 'Made $when';
  }

  @override
  String get billingAdvancedSummary =>
      'Charges by server, Casama Link servers and keys';

  @override
  String get billingChargesSummary => 'Charges by server';

  @override
  String get billingUsageRow => 'What bots used and what it cost';

  @override
  String billingUsageSoFar(String amount) {
    return 'This month so far: $amount';
  }

  @override
  String get usageAdvancedSummary => 'Token counts, JSON export';

  @override
  String get peopleHelp => 'Invite people and decide who gets in.';

  @override
  String get peopleRow => 'Invite people, approve requests, see members';

  @override
  String get qrCode => 'QR Code';

  @override
  String get remove => 'Remove';

  @override
  String get resendInvite => 'Send Again';

  @override
  String get resetLink => 'Reset Link';

  @override
  String get resetLinkHelp =>
      'The current link stops working right away and you get a new one. People already in stay in.';

  @override
  String get revokeInvite => 'Cancel Invite';

  @override
  String scanToJoin(String name) {
    return 'Scan to join $name';
  }

  @override
  String sendInvitesCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Send $countString Invites';
  }

  @override
  String get sendInvitesYourself => 'Send these invites yourself';

  @override
  String get sendInvitesYourselfHelp =>
      'Email isn\'t set up on this server. Send each person their link, and they sign in with that address to join.';

  @override
  String get signInToJoin => 'Sign in to join';

  @override
  String get startOwnWorkspace => 'Start My Own Workspace Instead';

  @override
  String switchToServer(String host) {
    return 'Switch to $host';
  }

  @override
  String get waitingToJoin => 'Waiting to Join';

  @override
  String welcomeToWorkspace(String name) {
    return 'Welcome to $name';
  }

  @override
  String get workspacesYouCanJoin => 'Workspaces You Can Join';

  @override
  String get yourTeamIsHere => 'Your team is already here';

  @override
  String yourTeamIsHereHelp(String domain) {
    return 'People at $domain use these workspaces. Join one, or start your own.';
  }

  @override
  String get inviteCodeCardHelp =>
      'Easy to read out or type. Works for 48 hours. People enter it under Join with a link or code.';

  @override
  String get inviteSomeoneNew => 'Invite someone new to the workspace';

  @override
  String oauthNeedsHttps(String app, String address) {
    return '$app only signs in on a secure (https) address, and this Casama server is at $address. Serve Casama over https to use sign-in.';
  }

  @override
  String get aboutYou => 'About you';

  @override
  String get aboutYouRow => 'What your bots call you and know about you';

  @override
  String get aboutYouIntro =>
      'Your bots read this so they can call you by name and answer the way you like. Only you can see it.';

  @override
  String get photoChange => 'Change profile photo';

  @override
  String get photoTake => 'Take a Photo';

  @override
  String get photoChoose => 'Choose a Photo';

  @override
  String get photoUseGoogle => 'Use My Google Photo';

  @override
  String get photoRemove => 'Remove Photo';

  @override
  String get photoUnreadable =>
      'That file isn\'t a photo Casama can use. Try a JPEG or PNG.';

  @override
  String get whatToCallYou => 'What should bots call you?';

  @override
  String get pronounsOptional => 'Pronouns (optional)';

  @override
  String get aboutMe => 'About me';

  @override
  String get aboutMeHint =>
      'Your work, the people in your life, what you\'re into. Anything that helps.';

  @override
  String get replyStyle => 'How I like replies';

  @override
  String get replyStyleHint =>
      'For example: short answers, no emoji, explain things like I\'m new to them';

  @override
  String get learnAboutMe => 'Learn About Me from Chats';

  @override
  String get learnAboutMeHelp =>
      'Bots save facts about you. Edit them any time.';

  @override
  String useInThisSpace(String workspace) {
    return 'Use what I\'ve shared in $workspace';
  }

  @override
  String get useInThisSpaceHelp =>
      'Off: only your name and reply style are used here.';

  @override
  String get learnedAboutYou => 'What Bots Learned';

  @override
  String get noLearnedFacts =>
      'Nothing yet. Facts bots learn about you in chat show up here.';

  @override
  String get addFact => 'Add a Fact';

  @override
  String get editFact => 'Edit fact';

  @override
  String get deleteFactTitle => 'Delete this fact?';

  @override
  String get deleteFactConfirm => 'Your bots won\'t know it anymore.';

  @override
  String get importToProfile => 'Import from ChatGPT or Claude';

  @override
  String get savedToProfile => 'Saved to your profile';

  @override
  String get undo => 'Undo';

  @override
  String get suggestedLookApplied => 'New look applied';

  @override
  String get suggestedLookUnavailable => 'This app doesn\'t have that look';

  @override
  String get removedFromProfile => 'Removed from your profile';

  @override
  String factsImported(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString facts',
      one: '1 fact',
    );
    return 'Added $_temp0';
  }

  @override
  String get nameCardHelp =>
      'Your bots will use it in every workspace. You can change it later in Settings → About you.';

  @override
  String get nameStepBubble => 'Nice to meet you!';

  @override
  String get nameStepHint => 'Your name';

  @override
  String get skillCatalogSubtitle =>
      'Ready-made skills your bots load when a task calls for one.';

  @override
  String get skillCategoryWork => 'Work';

  @override
  String get skillCategoryWriting => 'Writing';

  @override
  String get skillCategoryResearch => 'Research';

  @override
  String get skillCategoryData => 'Data';

  @override
  String get skillCategoryMoney => 'Money';

  @override
  String get skillCategoryBuild => 'Build';

  @override
  String get skillCategoryLife => 'Life';

  @override
  String skillCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString skills',
      one: '1 skill',
    );
    return '$_temp0';
  }

  @override
  String get skillInstalledBadge => 'Installed';

  @override
  String skillInstalledFor(String names) {
    return 'Installed for $names';
  }

  @override
  String installSkillFor(String name) {
    return 'Install $name for';
  }

  @override
  String skillUseHint(String name) {
    return 'Bots load it on their own when a task fits, or type /$name in a chat to use it.';
  }

  @override
  String get skillAlreadyEverywhere => 'Installed everywhere it can be.';

  @override
  String get gallery => 'Gallery';

  @override
  String get galleryEmpty => 'Nothing in the gallery matches.';

  @override
  String get galleryOffline =>
      'The gallery can\'t be reached right now. The built-in looks and skills are still here.';

  @override
  String get galleryUse => 'Use';

  @override
  String get galleryInstall => 'Install';

  @override
  String get galleryReport => 'Report';

  @override
  String get galleryShare => 'Share to Gallery';

  @override
  String galleryBy(String name) {
    return 'By $name';
  }

  @override
  String get galleryFeatured => 'Featured';

  @override
  String get galleryAll => 'All';

  @override
  String get galleryThemes => 'Themes';

  @override
  String get gallerySchemes => 'Colors';

  @override
  String get galleryWallpapers => 'Wallpapers';

  @override
  String get gallerySkills => 'Skills';

  @override
  String get fromGallery => 'Gallery';

  @override
  String galleryApplied(String name) {
    return 'Using $name';
  }

  @override
  String get gallerySeeAll => 'See All';

  @override
  String get galleryInUse => 'In use';

  @override
  String galleryInstalled(String name) {
    return 'Installed $name';
  }

  @override
  String get galleryPreviewDark => 'Preview in dark';

  @override
  String get galleryPreviewLight => 'Preview in light';

  @override
  String get galleryClearSearch => 'Clear search';

  @override
  String get galleryOfflineTitle => 'The gallery is offline';

  @override
  String galleryNoMatches(String query) {
    return 'Nothing matches “$query”';
  }

  @override
  String get galleryInstructions => 'Instructions';

  @override
  String galleryPatternOn(String pattern, String palette) {
    return '$pattern on $palette';
  }

  @override
  String get galleryImage => 'Image';

  @override
  String get galleryMeshGradient => 'a mesh gradient';

  @override
  String get galleryOwnDoodles => 'Own doodles';

  @override
  String get galleryLightAndDark => 'Light and dark';

  @override
  String get galleryContribute =>
      'Made a look you like? Share it, and everyone on Casama can find it here.';

  @override
  String get galleryTypeTheme => 'Theme';

  @override
  String get galleryTypeScheme => 'Color scheme';

  @override
  String get galleryTypeWallpaper => 'Wallpaper';

  @override
  String get galleryTypeSkill => 'Skill';

  @override
  String get galleryBehindChats => 'Behind Your Chats';

  @override
  String celebrateNewBot(String name) {
    return 'Say hi to $name!';
  }

  @override
  String celebrateNewSpace(String name) {
    return '$name is ready!';
  }

  @override
  String get celebrateJoined => 'You\'re in! Welcome to the space.';

  @override
  String celebrateNewRoutine(String name) {
    return '$name is all set.';
  }

  @override
  String get fewerEffects => 'Fewer Effects';

  @override
  String get fewerEffectsHelp =>
      'No celebrations, bouncing tabs or animated bots.';

  @override
  String get settingsAppSection => 'App';

  @override
  String get settingsSecuritySection => 'Sign-in & security';

  @override
  String get customize => 'Customize';

  @override
  String get customizeColors => 'Colors';

  @override
  String get appearanceCustomLook => 'Custom look';

  @override
  String get appearanceCustomHelp =>
      'Your own changes. Save them to keep this look.';

  @override
  String get appearanceFromGallery => 'From the Gallery';

  @override
  String appearanceShowAll(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Show All $countString';
  }

  @override
  String appearanceSwitched(String name) {
    return 'Switched to $name';
  }

  @override
  String appearanceSaved(String name) {
    return 'Saved $name to your themes';
  }

  @override
  String get appearanceAboutTheme => 'About this theme';

  @override
  String settingsOnDevServer(String host) {
    return 'Settings · development server $host';
  }

  @override
  String chatPreviewYou(String text) {
    return 'You: $text';
  }

  @override
  String get chatPreviewPhoto => 'Photo';

  @override
  String get chatPreviewVideo => 'Video';

  @override
  String get chatPreviewVoice => 'Voice note';

  @override
  String get chatPreviewNone => 'No messages yet';

  @override
  String get chatTimeYesterday => 'Yesterday';

  @override
  String get chatDayToday => 'Today';

  @override
  String chatDayAndTime(String day, String time) {
    return '$day · $time';
  }

  @override
  String messageSentAt(String day, String time) {
    return '$day at $time';
  }

  @override
  String get anyPriority => 'Any priority';

  @override
  String get readingAloud => 'Reading aloud';

  @override
  String get readAloudPreparing => 'Getting ready…';

  @override
  String get readAloudPaused => 'Paused';

  @override
  String get stopReading => 'Stop reading';

  @override
  String get readAloudSpeed => 'Playback speed';

  @override
  String readAloudTimeLeft(String time) {
    return '$time left';
  }

  @override
  String get readAloudShowMessage => 'Show the message being read';

  @override
  String mentionOpenProfile(String name) {
    return '$name, open profile';
  }

  @override
  String get paywallSubtitle =>
      'More bots, more computer time and fresh credits every month, so your bots can keep working.';

  @override
  String get paywallPerkBots => 'Bots';

  @override
  String get paywallPerkBotsBody => 'A whole crew, each with its own job.';

  @override
  String get paywallPerkComputers => 'Computer time';

  @override
  String get paywallPerkComputersBody =>
      'Bots get their own computers to browse, code and build.';

  @override
  String get paywallPerkCredits => 'Monthly credits';

  @override
  String get paywallPerkCreditsBody => 'For models, search and tools.';

  @override
  String get paywallPerkSeats => 'Seats';

  @override
  String get paywallPerkSeatsBody => 'Bring your team into the same workspace.';

  @override
  String paywallHours(String hours) {
    return '$hours h';
  }

  @override
  String get paywallWeekly => 'Weekly';

  @override
  String get paywallMonthly => 'Monthly';

  @override
  String get paywallYearly => 'Yearly';

  @override
  String get paywallPerMonth => '/ month';

  @override
  String get paywallPerYear => '/ year';

  @override
  String get paywallContinue => 'Continue';

  @override
  String get paywallContinueCheckout => 'Continue to checkout';

  @override
  String get paywallRestore => 'Restore';

  @override
  String get paywallFineStore =>
      'Renews automatically. Cancel anytime in your store settings.';

  @override
  String get paywallFineWeb =>
      'Renews automatically. Cancel anytime from Billing.';

  @override
  String paywallDisclosureStore(String price, String period, String store) {
    return '$price $period, renewing automatically until you cancel. Payment is charged to your $store. Cancel anytime in your $store settings at least 24 hours before it renews.';
  }

  @override
  String paywallDisclosureStoreTrial(
    int days,
    String price,
    String period,
    String store,
  ) {
    return 'Free for $days days, then $price $period, renewing automatically until you cancel. Payment is charged to your $store when the trial ends. Cancel in your $store settings at least 24 hours before the trial ends and you won\'t be charged.';
  }

  @override
  String get paywallStartFreeTrial => 'Start free trial';

  @override
  String paywallTrialThen(int days, String price, String period) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return '$_temp0 free, then $price$period';
  }

  @override
  String paywallDisclosureWeb(String price) {
    return '$price, renewing automatically until you cancel. Cancel anytime from Billing; you keep the plan until the period ends.';
  }

  @override
  String paywallDisclosureWebTrial(int days, String price) {
    return 'Free for $days days, then $price, renewing automatically until you cancel. Cancel from Billing before the trial ends and you won\'t be charged.';
  }

  @override
  String get pricePerWeek => 'per week';

  @override
  String get pricePerMonth => 'per month';

  @override
  String get pricePerYear => 'per year';

  @override
  String get storeAccountApple => 'Apple Account';

  @override
  String get storeAccountGoogle => 'Google Play account';

  @override
  String get termsOfUse => 'Terms of Use';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get aiConsentTitle => 'Your chats go to AI companies';

  @override
  String get aiConsentBody =>
      'To write replies, Casama sends what you share with your bots to outside AI providers. Nothing is sent until you agree.';

  @override
  String get aiConsentWhatTitle => 'What is sent';

  @override
  String get aiConsentWhat =>
      'Your messages, files and photos, your voice in calls, what bots remember about you, and any phone data you turn on, such as calendar or health.';

  @override
  String get aiConsentWhoTitle => 'Who gets it';

  @override
  String get aiConsentWho =>
      'OpenRouter, which passes it to the company that makes the model you use, such as DeepSeek, Google or OpenAI. Calls use Google Gemini. Web searches go to Parallel, Serper or DeepSeek. With your own API key, it goes to that provider instead.';

  @override
  String get aiConsentWhyTitle => 'What they do with it';

  @override
  String get aiConsentWhy =>
      'They use it to write the reply. You can stop this any time in Settings › Privacy, and the privacy policy has the details.';

  @override
  String get aiConsentAgree => 'Agree and Continue';

  @override
  String get aiConsentTile => 'AI providers';

  @override
  String get aiConsentTileOn =>
      'Allowed. What you share with bots goes to outside AI providers to write replies.';

  @override
  String get aiConsentWithdrawQuestion => 'Stop sharing with AI providers?';

  @override
  String get aiConsentWithdrawBody =>
      'Bots can\'t reply without them. Casama asks again before anything else is sent.';

  @override
  String get aiConsentWithdraw => 'Stop Sharing';

  @override
  String get planChanged => 'Plan changed';

  @override
  String get purchasesRestored => 'Purchases restored';

  @override
  String get creditsAdded => 'Credits added';

  @override
  String get purchasePending =>
      'Waiting for the purchase to be approved. It\'s added as soon as it is.';

  @override
  String get purchaseFailed =>
      'The purchase didn\'t go through, and you weren\'t charged.';

  @override
  String get purchaseVerifyFailed =>
      'We couldn\'t confirm your purchase yet. It\'s retried on its own; if it doesn\'t show up soon, tap Restore Purchases.';

  @override
  String paywallTitleFor(String plan) {
    return 'Grow your crew with $plan';
  }

  @override
  String paywallWelcomePlan(String plan) {
    return 'Welcome to $plan!';
  }

  @override
  String paywallMonthsFree(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n months free',
      one: '1 month free',
    );
    return '$_temp0';
  }

  @override
  String paywallSwitchTo(String plan) {
    return 'Switch to $plan';
  }

  @override
  String subscribedInStoreNote(String store) {
    return 'You subscribe through $store. To change plans, use $store on the device you subscribed with.';
  }

  @override
  String get subscribedOnWebNote =>
      'You subscribe on the web. Change plans here with web checkout, or manage your subscription.';

  @override
  String get subscribedOutsideAppNote =>
      'Your subscription is billed outside this app, so it can\'t be changed here.';

  @override
  String get outOfCreditsTitle => 'You\'re out of credits';

  @override
  String get outOfCreditsPaidBody =>
      'Your bots pause until you add credits. Packs from the App Store or Google Play never expire; web packs last 12 months.';

  @override
  String get outOfCreditsFreeBody =>
      'Upgrade for more credits every month, more bots and more computer time.';

  @override
  String get addCredits => 'Add Credits';

  @override
  String get seePlansButton => 'See Plans';

  @override
  String get paywallAskAdmin =>
      'Only workspace owners and admins can change the plan. Ask one of them to upgrade.';

  @override
  String get upgradeToPro => 'Upgrade to Pro';

  @override
  String get upgradeToProBody =>
      'More bots, computer time and monthly credits.';

  @override
  String get manageTab => 'Manage';

  @override
  String get vitalsCpu => 'CPU';

  @override
  String get vitalsMemory => 'Memory';

  @override
  String get vitalsDisk => 'Disk';

  @override
  String get fixItTitle => 'Not working right?';

  @override
  String get fixItSubtitle =>
      'Try these in order. Each one goes a bit further.';

  @override
  String get fixRestart => 'Restart';

  @override
  String get fixRestartHelp => 'About 20 seconds · nothing is lost';

  @override
  String get fixResetSystem => 'Reset system';

  @override
  String get fixResetSystemHelp => 'A fresh system · your files stay';

  @override
  String get fixErase => 'Erase everything';

  @override
  String get fixEraseHelp => 'Like new · can be undone for 7 days';

  @override
  String get fixResetAction => 'Reset…';

  @override
  String get fixEraseAction => 'Erase…';

  @override
  String get computerRestarting => 'Restarting…';

  @override
  String get computerRestarted => 'Restarted. Your files are all there.';

  @override
  String get computerUpdateTitle => 'Update available';

  @override
  String get computerUpdateBody =>
      'New tools and fixes are ready. Updating restarts this computer: your files stay, open windows and running programs close.';

  @override
  String get computerUpdateBotWorking =>
      'A bot is working on this computer right now. Updating stops what it\'s doing.';

  @override
  String get computerUpdateNow => 'Update now';

  @override
  String get computerUpdateLater => 'Later';

  @override
  String get computerUpdateConfirmTitle => 'Update this computer?';

  @override
  String get computerUpdateMenu => 'Update computer';

  @override
  String get computerUpdating => 'Updating…';

  @override
  String get computerUpdated => 'Updated. Your files are all there.';

  @override
  String get computerUpdateBusyTitle => 'A command is still running';

  @override
  String get computerUpdateBusyBody =>
      'Updating now stops it. Wait until it\'s done, or update anyway.';

  @override
  String get computerUpdateAnyway => 'Update anyway';

  @override
  String resetSheetTitle(String name) {
    return 'Reset $name';
  }

  @override
  String resetSheetBusy(String bots) {
    return '$bots can\'t use it for about a minute.';
  }

  @override
  String get resetSheetBusyNone => 'It can\'t be used for about a minute.';

  @override
  String get resetOptionSystem => 'Reset system, keep my files';

  @override
  String get resetOptionSystemHelp =>
      'Fixes broken installs, settings and stuck programs.';

  @override
  String get resetOptionErase => 'Erase everything';

  @override
  String get resetOptionEraseHelp => 'Back to a brand-new computer.';

  @override
  String get resetKept => 'Kept';

  @override
  String get resetRemoved => 'Removed';

  @override
  String get resetKeptFiles => 'Your files in workspace';

  @override
  String get resetKeptSettings => 'Name, settings and bots';

  @override
  String get resetKeptRestorePoints => 'Restore points';

  @override
  String get resetRemovedApps => 'Apps and tools you installed';

  @override
  String get resetRemovedPrograms => 'Running programs';

  @override
  String get resetRemovedCaches => 'Caches and home folder settings';

  @override
  String get resetRemovedFiles => 'Every file, workspace too';

  @override
  String get resetSavePoint => 'Save a restore point first';

  @override
  String get resetSavePointHelp => 'So you can undo this for 7 days';

  @override
  String eraseTypeName(String name) {
    return 'Type $name to confirm';
  }

  @override
  String get resetConfirmSystem => 'Reset system';

  @override
  String get resetConfirmErase => 'Erase everything';

  @override
  String get resetStepSaving => 'Saving a restore point';

  @override
  String get resetStepWipingSystem => 'Removing apps and settings';

  @override
  String get resetStepWipingErase => 'Erasing every file';

  @override
  String get resetStepRestarting => 'Starting a fresh system';

  @override
  String resettingStatus(int step, int total) {
    final intl.NumberFormat stepNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String stepString = stepNumberFormat.format(step);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'Resetting… $stepString of $totalString';
  }

  @override
  String erasingStatus(int step, int total) {
    final intl.NumberFormat stepNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String stepString = stepNumberFormat.format(step);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'Erasing… $stepString of $totalString';
  }

  @override
  String get resetLeaveHint =>
      'You can leave this screen. It keeps going on its own.';

  @override
  String get resetDone => 'Fresh system ready';

  @override
  String get eraseDone => 'Computer erased';

  @override
  String get resetFailed => 'The reset didn\'t finish';

  @override
  String get resetUndoHint =>
      'Undo puts everything back the way it was. The restore point stays for 7 days.';

  @override
  String get restoredPrevious => 'Put back the way it was';

  @override
  String get usageThisMonth => 'This month';

  @override
  String usageDuration(int hours, int minutes) {
    final intl.NumberFormat hoursNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String hoursString = hoursNumberFormat.format(hours);
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return '$hoursString h $minutesString m';
  }

  @override
  String get usageCostNote =>
      'Charged only while it\'s on. Asleep costs nothing.';

  @override
  String get usageNone => 'Not used yet this month';

  @override
  String get sleepTimerTitle => 'Goes to sleep after';

  @override
  String sleepTimerMinutes(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '$nString min';
  }

  @override
  String get sleepTimerHour => '1 hour';

  @override
  String get sleepTimerHelp =>
      'Never while a bot is working or you\'re using it. A longer wait keeps it on longer, which costs more.';

  @override
  String sleepTimerSaved(String label) {
    return 'Sleeps after $label without activity';
  }

  @override
  String get storageTitle => 'Storage';

  @override
  String storageOf(String total) {
    return 'of $total';
  }

  @override
  String get storageFiles => 'Your files';

  @override
  String get storageApps => 'Apps and tools';

  @override
  String get storageCaches => 'Caches';

  @override
  String get storageBrowser => 'Browser';

  @override
  String get storageOther => 'Other';

  @override
  String get storageFree => 'Free';

  @override
  String storageFreeUp(String size) {
    return 'Free up $size';
  }

  @override
  String get storageNothingToClean => 'No caches to clear';

  @override
  String storageFreed(String size) {
    return 'Freed $size';
  }

  @override
  String get storageAsleep => 'Wake the computer to see what takes up space.';

  @override
  String get processesTitle => 'Running now';

  @override
  String get processesNone => 'Nothing is running besides the computer itself.';

  @override
  String get processesAsleep => 'Nothing runs while it sleeps.';

  @override
  String get processStop => 'Stop';

  @override
  String processStopTitle(String name) {
    return 'Stop $name?';
  }

  @override
  String get processStopMessage => 'Anything it hasn\'t saved is lost.';

  @override
  String processStopped(String name) {
    return 'Stopped $name';
  }

  @override
  String processLine(String duration, String cpu, String memory) {
    return '$duration · $cpu% CPU · $memory';
  }

  @override
  String get usedByTitle => 'Used by';

  @override
  String get usedByNone => 'No bot uses this computer yet.';

  @override
  String botLastActive(String when) {
    return 'Active $when';
  }

  @override
  String get botNeverActive => 'Not active yet';

  @override
  String get restorePointsTitle => 'Restore points';

  @override
  String get restorePointsNone =>
      'None yet. Bots save one before risky changes.';

  @override
  String get restorePointSaveNow => 'Save a restore point now';

  @override
  String get restorePointSaveTitle => 'Save a restore point';

  @override
  String get restorePointDefaultLabel => 'Saved by hand';

  @override
  String get restorePointSaved => 'Restore point saved';

  @override
  String restorePointsShowAll(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'Show all $nString';
  }

  @override
  String get historyTitle => 'History';

  @override
  String get historyNone => 'Nothing has happened yet.';

  @override
  String get historyStarted => 'Woke up';

  @override
  String get historySlept => 'Went to sleep';

  @override
  String get historySleptIdle => 'Went to sleep (no activity)';

  @override
  String get historyRestarted => 'Restarted';

  @override
  String get historyReset => 'Reset the system';

  @override
  String get historyErased => 'Erased everything';

  @override
  String get historyCheckpointCreated => 'Saved a restore point';

  @override
  String get historyCheckpointRestored => 'Restored a restore point';

  @override
  String historyStorageCleaned(String size) {
    return 'Freed up $size';
  }

  @override
  String get historyStorageCleanedPlain => 'Freed up space';

  @override
  String historyProcessStopped(String name) {
    return 'Stopped $name';
  }

  @override
  String get historyUpdated => 'Changed its settings';

  @override
  String get historyYou => 'you';

  @override
  String get yourDataTitle => 'Your data';

  @override
  String get downloadAllFiles => 'Download all files';

  @override
  String get downloadAllFilesHelp => 'A .zip of everything in workspace';

  @override
  String get downloadNothing => 'There are no files to download yet.';

  @override
  String get deleteComputerHelp => 'Removes it and its restore points';

  @override
  String get manageComputer => 'Manage';

  @override
  String get restartComputer => 'Restart';

  @override
  String get resetComputerMenu => 'Reset…';

  @override
  String get moreFixes => 'More fixes';

  @override
  String durationMinutes(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '$nString min';
  }

  @override
  String durationHours(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '$nString h';
  }

  @override
  String durationDays(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '$nString d';
  }

  @override
  String get remoteUpdateTitle => 'Time to update Casama';

  @override
  String get remoteUpdateBody =>
      'This version of Casama is no longer supported. Update it to keep going.';

  @override
  String get remoteUpdateNoLink =>
      'This version of Casama is no longer supported. Update it from where you installed it.';

  @override
  String get remoteMaintenanceTitle => 'Casama is down for maintenance';

  @override
  String get openLink => 'Open';

  @override
  String get routineIdeas => 'Ideas';

  @override
  String get routineIdeasHelp => 'Start from an idea, then change anything.';

  @override
  String get pluginDirectory => 'Reviewed plugins';

  @override
  String get pluginDirectoryHelp =>
      'Checked by Casama and pinned to the version that was checked.';

  @override
  String get pluginOrPaste => 'Or add one from a GitHub link';

  @override
  String byAuthor(String name) {
    return 'By $name';
  }

  @override
  String get adminAppSettings => 'App settings';

  @override
  String get adminAppSettingsHelp =>
      'Minimum versions, maintenance, announcements, feature switches and links for every app, with no release.';

  @override
  String get adminAppSettingsBadJson =>
      'That isn\'t valid JSON. Check the brackets, quotes and commas.';

  @override
  String get adminEmailCopy => 'Email words';

  @override
  String get adminEmailCopyHelp =>
      'The welcome emails and the monthly gallery picks, in your words. Leave a field out to use Casama\'s.';

  @override
  String get adminModelCatalog => 'Model catalog';

  @override
  String get adminModelCatalogHelp =>
      'Default, small, featured and test models, model prices and image prices. Anything left out uses the built-in value.';

  @override
  String get adminCostTables => 'Cost tables';

  @override
  String get adminCostTablesHelp =>
      'What voice, calls, computers and media cost, and which domains are sold. Billing uses them within a minute.';

  @override
  String get adminGuardSites => 'Browser guard sites';

  @override
  String get adminGuardSitesHelp =>
      'Sites Casama for Chrome and bots\' browsers keep out, on top of the built-in list. You can only add to it.';

  @override
  String get adminBuiltInValues => 'Built-in values';

  @override
  String get adminCallLimits => 'Call limits';

  @override
  String get adminCallLimitsHelp =>
      'Silence before a call hangs up, the longest call, warnings before a limit, and how often bots may ring someone. Values left out use the built-in ones.';

  @override
  String get paywallBillingPeriod => 'Billing period';

  @override
  String get paywallNotSoldTitle => 'No plans on this server';

  @override
  String get paywallNotSoldBody =>
      'This server doesn\'t sell plans, so there\'s nothing to upgrade here.';

  @override
  String get paywallPlansFailedTitle => 'Plans didn\'t load';

  @override
  String get paywallPlansFailedBody => 'Check your connection, then try again.';

  @override
  String paywallStoreEmptyTitle(String store) {
    String _temp0 = intl.Intl.selectLogic(store, {
      'app_store': 'The App Store',
      'google_play': 'Google Play',
      'other': 'The store',
    });
    return '$_temp0 isn\'t showing plans';
  }

  @override
  String paywallStoreEmptyBody(String store) {
    String _temp0 = intl.Intl.selectLogic(store, {
      'app_store': 'the App Store',
      'google_play': 'Google Play',
      'other': 'the store',
    });
    return 'Make sure you\'re signed in to $_temp0 on this device, then try again.';
  }

  @override
  String paywallSaveUpTo(int pct) {
    return 'Save up to $pct%';
  }

  @override
  String get paywallMostPopular => 'Most popular';

  @override
  String get paywallTaglinePlus => 'For you and a handful of bots';

  @override
  String get paywallTaglinePro => 'For a busy crew and a small team';

  @override
  String get paywallTaglineMax => 'For teams with bots working all day';

  @override
  String get paywallPerMonthShort => '/mo';

  @override
  String paywallBilledYearly(String price) {
    return '$price billed yearly';
  }

  @override
  String paywallWorksOutTo(String price) {
    return 'Works out to $price/mo';
  }

  @override
  String get paywallBilledMonthly => 'Billed monthly';

  @override
  String get paywallBilledWeekly => 'Billed weekly';

  @override
  String get paywallPerWeekShort => '/wk';

  @override
  String paywallPerWeekWorksOut(String price) {
    return 'That\'s $price a week';
  }

  @override
  String get paywallBilledYearlyPlain => 'Billed yearly';

  @override
  String get paywallPerYearShort => '/yr';

  @override
  String paywallStartTrial(int n) {
    return 'Start $n-day free trial';
  }

  @override
  String paywallGetPlan(String plan) {
    return 'Get $plan';
  }

  @override
  String paywallPeople(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people',
      one: '1 person',
    );
    return '$_temp0';
  }

  @override
  String paywallFactHours(int hours) {
    final intl.NumberFormat hoursNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String hoursString = hoursNumberFormat.format(hours);

    return '$hoursString computer hours';
  }

  @override
  String get billingChangePlan => 'Change plan';

  @override
  String get billingChangePlanBody => 'Compare every plan, monthly or yearly.';

  @override
  String paywallWhatYouGet(String plan) {
    return 'What $plan gets you';
  }

  @override
  String get adminPricing => 'Pricing';

  @override
  String get adminCreditPacks => 'Credit packs';

  @override
  String get adminOnSale => 'On sale';

  @override
  String get adminHidden => 'Hidden';

  @override
  String get adminNoPriceLabel => 'No price label';

  @override
  String get adminPlanSaveHelp =>
      'Saving applies to every workspace on this plan straight away.';

  @override
  String get adminPackSaveHelp =>
      'Saving changes the pack for everyone straight away.';

  @override
  String get adminPlanName => 'Name';

  @override
  String get adminPriceLabel => 'Price label';

  @override
  String get adminPriceLabelHelp =>
      'Shown where the store has no price of its own';

  @override
  String get adminPlanActiveHelp =>
      'A hidden plan stays with the workspaces already on it.';

  @override
  String get adminCreditGate => 'Stop at zero credits';

  @override
  String get adminCreditGateHelp =>
      'Runs on Casama\'s keys stop when the workspace\'s credits run out.';

  @override
  String get adminPaywallDefault => 'Paywall opens here';

  @override
  String get adminPaywallDefaultHelp =>
      'Free workspaces start on this plan, and everyone starts on its billing period. Only one plan at a time.';

  @override
  String get adminPaywallPopular => 'Most popular';

  @override
  String get adminPaywallPopularHelp =>
      'Shows the Most popular badge on this plan\'s tier.';

  @override
  String get adminPlanSort => 'Sort order';

  @override
  String get adminPlanLimits => 'Limits';

  @override
  String get adminLimitMonthlyCredits => 'Monthly credits (USD)';

  @override
  String get adminLimitMaxBots => 'Bots';

  @override
  String get adminLimitMaxComputers => 'Computers';

  @override
  String get adminLimitComputerHours => 'Computer hours a month';

  @override
  String get adminLimitSeats => 'People';

  @override
  String get adminLimitCloudDaily => 'Cloud spend a day (USD)';

  @override
  String get adminLimitMaxRunning => 'Computers running at once';

  @override
  String get adminLimitComputerSize => 'Computer size (vCPUs and GB)';

  @override
  String get adminLimitExtraSeat => 'Extra person a month (USD)';

  @override
  String get adminLimitTrialDays => 'Trial days';

  @override
  String get adminLimitTrialCredits => 'Trial credits (USD)';

  @override
  String get adminLimitTrialHours => 'Trial computer hours';

  @override
  String get adminLimitMailAddresses => 'Bot email addresses';

  @override
  String get adminLimitMailNewDay => 'Mail to new people, a day';

  @override
  String get adminLimitMailSentDay => 'Mail sent, a day';

  @override
  String get adminLimitMailStorage => 'Mailbox size, MB';

  @override
  String get adminAddLimit => 'Add a limit';

  @override
  String get adminLimitKey => 'Limit key';

  @override
  String get adminLimitKeyInvalid =>
      'Use lowercase letters, digits and underscores';

  @override
  String get adminLimitValue => 'Value';

  @override
  String get adminStoreProducts => 'Store products';

  @override
  String get adminAppStoreId => 'App Store product id';

  @override
  String get adminGooglePlayId => 'Google Play product id';

  @override
  String get adminDodoId => 'Dodo product id';

  @override
  String get adminPackCredits => 'Credits (USD)';

  @override
  String get adminMarkup => 'Usage markup';

  @override
  String adminMarkupValue(String markup) {
    return '×$markup';
  }

  @override
  String get adminMarkupHelp => '1.3 = charge 30% over what Casama pays';

  @override
  String get adminMarkupTooLow =>
      'Use 1 or more. 1 charges exactly what Casama pays.';

  @override
  String get adminNumberInvalid => 'Enter a number of 0 or more';

  @override
  String get adminNumberPositive => 'Enter a number above 0';

  @override
  String get adminWholeNumber => 'Enter a whole number';

  @override
  String get adminNameRequired => 'Enter a name';

  @override
  String get adminPricingBillingOff =>
      'Billing is off on this server. These prices apply once it\'s on.';

  @override
  String get updatesRow => 'Updates';

  @override
  String get updatesRowSubtitle => 'News from your workspace';

  @override
  String get updatesEmpty => 'No updates';

  @override
  String get updatesEmptyHelp =>
      'Workspace notices and new pages show up here. What your bots send you is in their chats.';

  @override
  String chatsNeedsYou(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n things need you',
      one: '1 thing needs you',
    );
    return '$_temp0';
  }

  @override
  String suggestionInTopic(String title) {
    return 'Working on it: $title';
  }

  @override
  String suggestionClosed(String title) {
    return 'Not now: $title';
  }

  @override
  String openTopic(String title) {
    return 'Open $title';
  }

  @override
  String get newTopic => 'New topic';

  @override
  String get topics => 'Topics';

  @override
  String get olderTopics => 'Older';

  @override
  String get generalChat => 'General';

  @override
  String get allTopics => 'All topics';

  @override
  String get cardSecrets => 'Secrets';

  @override
  String get cardApproval => 'Approval';

  @override
  String get cardTakeover => 'Take over';

  @override
  String get cardDevice => 'Device access';

  @override
  String get cardSuggestion => 'Suggestion';

  @override
  String get formNext => 'Next';

  @override
  String get formSkip => 'Skip';

  @override
  String formStep(int n, int total) {
    return 'Question $n of $total';
  }

  @override
  String get cardSuggestions => 'Suggestions';

  @override
  String suggestionsTitle(int n) {
    return 'Found $n things worth a look';
  }

  @override
  String suggestionStarted(String when) {
    return 'Started $when';
  }

  @override
  String get suggestionStartedPlain => 'Started';

  @override
  String get suggestionPutAway => 'Put away';

  @override
  String get suggestionExpired => 'Expired';

  @override
  String suggestionExpiredTitle(String title) {
    return 'Expired: $title';
  }

  @override
  String suggestionsHandled(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n suggestions handled',
      one: '1 suggestion handled',
    );
    return '$_temp0';
  }

  @override
  String get casamaLink => 'Casama Link';

  @override
  String get linkRow => 'Use this server on your phone';

  @override
  String get linkIntro =>
      'Give this server an address your phone can reach from anywhere. No domain and no router settings.';

  @override
  String get linkIntroDetails =>
      'It links this server to a free Casama Cloud account. Your phone\'s traffic goes through Cloudflare straight to this computer, never through Casama\'s servers.';

  @override
  String get linkTurnOn => 'Use on Your Phone';

  @override
  String get linkSignupsNote =>
      'New sign-ups close while it is on. Only people who already have an account here can sign in.';

  @override
  String get linkStepSignIn => 'Link this server';

  @override
  String get linkSignInBody =>
      'Approve this code on the page that just opened in your browser. Check that the page shows the same code.';

  @override
  String get linkSignInOpen => 'Open the Page Again';

  @override
  String get linkStepAddress => 'Get an address';

  @override
  String get linkStepRestart => 'Restart the server';

  @override
  String get linkStepConnect => 'Connect';

  @override
  String get linkStateOnline => 'Online';

  @override
  String get linkStateStarting => 'Starting';

  @override
  String get linkStateOffline => 'Offline';

  @override
  String get linkStateAttention => 'Needs attention';

  @override
  String get linkStateOff => 'Off';

  @override
  String get linkAddress => 'Address';

  @override
  String get linkLocalAddress => 'On this computer';

  @override
  String get linkShowCode => 'Show Sign-In Code';

  @override
  String get linkCheck => 'Check Again';

  @override
  String get linkTurnOff => 'Turn Off';

  @override
  String get linkTurnOffConfirm =>
      'Turn off remote access? The address stops working, and phones lose this server until you turn it on again. It gets the same address back.';

  @override
  String get linkTurningOff => 'Turning off';

  @override
  String get linkNeedsOwner => 'Only this server\'s owner can turn this on.';

  @override
  String get linkTwoStepTip =>
      'This server can now be reached from the internet. Two-step sign-in means a guessed password isn\'t enough.';

  @override
  String get linkProblemNotLinked =>
      'This server isn\'t linked to Casama Cloud. Turn it on again to link it.';

  @override
  String get linkProblemCloudUnreachable =>
      'Casama Cloud can\'t be reached right now. If the address was working, it still is.';

  @override
  String get linkProblemKeyRejected =>
      'Casama Cloud no longer accepts this server\'s key. Turn it on again to link it.';

  @override
  String get linkProblemSuspended =>
      'Casama Cloud turned remote access off for this server.';

  @override
  String get linkProblemRemoved =>
      'This server was removed from its workspace in Casama Cloud. Turn it on again to link it.';

  @override
  String get linkProblemPlanLimit =>
      'Your Casama Cloud plan connects fewer servers. Remove one there, or upgrade.';

  @override
  String get linkProblemUnknownServer =>
      'Casama Cloud has no address for this server any more. Turn it on again.';

  @override
  String get linkProblemAddressChanged =>
      'This server\'s address changed. Turn it on again to use the new one.';

  @override
  String get connectProblemConnectorMissing =>
      'The connector isn\'t running. Check that Docker is running, then check again.';

  @override
  String get connectProblemConnectorBlocked =>
      'This network blocks the connection. A VPN or a strict firewall is the usual cause (outbound port 7844).';

  @override
  String get linkProblemAddressUnanswered =>
      'Everything is connected, but the address doesn\'t answer yet. A new address can take a minute.';

  @override
  String get linkServers => 'Linked Servers';

  @override
  String linkServersHelp(int limit) {
    String _temp0 = intl.Intl.pluralLogic(
      limit,
      locale: localeName,
      other: 'Your plan connects $limit servers.',
      one: 'Your plan connects 1 server.',
    );
    return '$_temp0';
  }

  @override
  String get linkServersNone =>
      'No servers linked yet. On your own server, open Settings, then Casama Link.';

  @override
  String linkServerRemoveConfirm(String name) {
    return 'Remove $name? Its address stops working. The server can be linked again later.';
  }

  @override
  String get linkStatusActive => 'Has an address';

  @override
  String get linkStatusParked => 'Not seen lately';

  @override
  String get linkStatusSuspended => 'Suspended';

  @override
  String get pairDevice => 'Sign In on Another Device';

  @override
  String get pairDeviceRow => 'Show a code your phone scans';

  @override
  String get pairDeviceHelp =>
      'Scan this with your phone\'s camera. Or in Casama on the phone: Sign in, then Scan a code.';

  @override
  String get pairDeviceWarning =>
      'Anyone who scans it is signed in as you. It works once, for a few minutes.';

  @override
  String pairDeviceServer(String host) {
    return 'Signs in to $host';
  }

  @override
  String get pairDeviceNewCode => 'New Code';

  @override
  String get pairDeviceExpired => 'This code ran out.';

  @override
  String get pairDeviceNotReachable =>
      'This server only answers on this computer, so a phone can\'t reach it yet.';

  @override
  String get pairDeviceNotReachableOther =>
      'This server\'s address only works on its own network. Ask whoever runs it for an address others can reach.';

  @override
  String get pairDeviceCopyLink => 'Copy Link';

  @override
  String get pairDeviceLinkCopied =>
      'Link copied. Paste it into Casama for Chrome or on another device.';

  @override
  String get pairDeviceConnectChrome => 'Connect Chrome';

  @override
  String get pairDeviceChromeDone => 'Casama for Chrome is signed in.';

  @override
  String get pairDeviceChromeFinish =>
      'Finish in the Casama for Chrome tab that opened.';

  @override
  String get pairDeviceChromeMissing =>
      'Casama for Chrome isn\'t installed in this browser.';

  @override
  String pairDeviceChromeFailed(String error) {
    return 'Casama for Chrome couldn\'t sign in. $error';
  }

  @override
  String get scanToSignIn => 'Scan a Code from Your Computer';

  @override
  String get scanToSignInTitle => 'Scan the Code';

  @override
  String get scanToSignInHelp =>
      'On a computer where you\'re signed in, open Settings, then Sign In on Another Device.';

  @override
  String pairSignInTo(String host) {
    return 'Sign in to $host?';
  }

  @override
  String get pairSignInBody =>
      'The code signs this device in to the account that showed it.';

  @override
  String pairSwitchServerBody(String current, String host) {
    return 'This device uses $current now. Signing in to $host switches it over.';
  }

  @override
  String get pairSigningIn => 'Signing in';

  @override
  String get pairCodeInvalid =>
      'That code isn\'t valid any more. Show a new one and scan again.';

  @override
  String get pairLinkInvalid => 'This isn\'t a Casama sign-in code.';

  @override
  String get linkServerTitle => 'Link a Server';

  @override
  String linkServerBody(String name) {
    return '$name wants to connect to your Casama Cloud account.';
  }

  @override
  String get linkServerCode => 'Code on the server';

  @override
  String get linkServerCheck =>
      'Only link it if you started this on your own server and it shows this same code.';

  @override
  String get linkServerWhat =>
      'It gets a public address and can send you notifications. It can\'t spend your credits.';

  @override
  String get linkServerApprove => 'Link';

  @override
  String get linkServerDone => 'Linked';

  @override
  String linkServerDoneBody(String name) {
    return 'Go back to $name. It carries on by itself.';
  }

  @override
  String get linkServerInvalid =>
      'That code isn\'t valid any more. Start again on your server.';

  @override
  String get linkServerEnterCode => 'The code your server shows';

  @override
  String get linkServerFind => 'Find';

  @override
  String get linkServerNeedAdmin =>
      'Only owners and admins of a workspace can link a server.';

  @override
  String get serverOfflineTitle => 'Your server is offline';

  @override
  String get serverOfflineBody =>
      'Is the computer that runs it on and awake? This reconnects by itself.';

  @override
  String get signUpsClosed =>
      'This server isn\'t taking new accounts. Sign in with an account you already have here.';

  @override
  String get signUpsByInvitation =>
      'New accounts here are by invitation. Use the email address you were invited with.';

  @override
  String get linkPrivateNotifications => 'Private Notifications';

  @override
  String get linkPrivateNotificationsHelp =>
      'Notifications reach your phone through Casama Cloud. With this on they carry no text and say only \"New activity\"; the app loads the rest from this server.';

  @override
  String get linkInvites => 'Let Invited People Sign Up';

  @override
  String get linkInvitesHelp =>
      'Off: nobody can make a new account while this is on. On: people you invite by email can. The server restarts to change it.';

  @override
  String get linkKeepAwake => 'Keep This Mac Awake While Plugged In';

  @override
  String get linkKeepAwakeHelp =>
      'Phones can only reach this server while this computer is awake and Casama is open.';

  @override
  String get linkLiveView => 'Live View Away From Here';

  @override
  String get linkLiveViewIncluded =>
      'Included in your plan. Away from this computer, a bot\'s screen plays live through Casama Cloud\'s relay.';

  @override
  String get linkLiveViewPlan =>
      'Comes with Plus and up on Casama Cloud. Away from this computer you see a bot\'s screen about once a second. On this computer it is always live.';

  @override
  String get liveAwayNeedsPlan =>
      'Away from the server\'s computer, live video comes with Plus and up on Casama Cloud. Until then the screen updates about once a second.';

  @override
  String get chatShareExport => 'Share or Export';

  @override
  String get chatShareExportHelp =>
      'Save this chat as a file, or make a read-only link to it.';

  @override
  String get chatExportMarkdown => 'Export as Markdown';

  @override
  String get chatExportMarkdownHelp => 'A text file anyone can read';

  @override
  String get chatExportJson => 'Export as JSON';

  @override
  String get chatExportJsonHelp => 'For other apps and scripts';

  @override
  String get chatShareLink => 'Share a Read-Only Link';

  @override
  String get chatShareLinkHelp => 'Anyone with the link can read this chat';

  @override
  String get chatStopSharing => 'Stop Sharing the Link';

  @override
  String get chatStopSharingHelp => 'The link stops working';

  @override
  String get chatMakePublicTitle => 'Share this chat with a link?';

  @override
  String get chatMakePublicBody =>
      'Anyone with the link can read this chat as you see it. Attached files are listed by name, not shared. You can stop it any time.';

  @override
  String get chatMakePublic => 'Make Link';

  @override
  String get chatLinkTitle => 'Read-Only Link';

  @override
  String get chatLinkBody =>
      'Copied. It isn\'t listed in search engines. Making a new link stops this one.';

  @override
  String get chatSharingStopped => 'The link no longer works';

  @override
  String get creationDuplicate => 'Duplicate';

  @override
  String creationDuplicated(String title) {
    return 'Made a copy: “$title”';
  }

  @override
  String get slackInstall => 'Add to Slack';

  @override
  String slackInstallHelp(String bot) {
    return 'Connect a Slack workspace in one step. $bot answers @mentions and direct messages there.';
  }

  @override
  String get slackInstallFinish => 'Finish in Slack, then come back here.';

  @override
  String get helpAndSupport => 'Help & support';

  @override
  String get helpAndSupportRow => 'Ask Casama Help, contact us, guides';

  @override
  String get casamaHelp => 'Casama Help';

  @override
  String get casamaHelpPitch =>
      'Instant answers from our guides and your account. A person is one tap away.';

  @override
  String get supportIntro =>
      'Questions, a problem with a purchase, or something not working? Write to us.';

  @override
  String supportSelfHosted(String host) {
    return 'Your workspace runs on $host. For sign-in, accounts and plans, ask whoever runs that server. We can help with the app itself.';
  }

  @override
  String get supportTalkToPerson => 'Talk to a person';

  @override
  String get contactSupport => 'Contact support';

  @override
  String contactSupportRow(String email) {
    return 'Write to our team at $email';
  }

  @override
  String get contactSupportHelp =>
      'Tell us what\'s going on. We\'ll reply by email.';

  @override
  String get contactSupportHelpMail =>
      'Tell us what\'s going on. This opens your email app with the details filled in.';

  @override
  String get supportSend => 'Send';

  @override
  String get supportWriteEmail => 'Open email';

  @override
  String get supportTopicPrompt => 'What\'s it about?';

  @override
  String get supportTopicBilling => 'Billing & purchases';

  @override
  String get supportTopicBroken => 'Something\'s not working';

  @override
  String get supportTopicAccount => 'Account & sign-in';

  @override
  String get supportTopicQuestion => 'A question or idea';

  @override
  String get supportTopicOther => 'Something else';

  @override
  String get supportMessageLabel => 'Your message';

  @override
  String get supportMessageHint => 'What happened, and what did you expect?';

  @override
  String get supportMessageMore =>
      'Add a sentence or two: what you were doing and what went wrong.';

  @override
  String get supportIncludeChat => 'Include my conversation with Casama Help';

  @override
  String get supportIncludeChatHelp =>
      'So you don\'t have to explain it twice.';

  @override
  String get supportDetailsNote =>
      'We add your app version and your workspace and account IDs so we can find your account. Never your chats.';

  @override
  String get supportSentTitle => 'Message sent';

  @override
  String supportSentBody(String email, String reference) {
    return 'We\'ll reply to $email. Your reference is $reference.';
  }

  @override
  String supportNoMailApp(String email) {
    return 'No email app found, so we copied your message. Paste it into an email to $email.';
  }

  @override
  String get supportGuides => 'Guides and FAQ';

  @override
  String get supportGuidesHelp => 'Step-by-step help for everything in Casama';

  @override
  String get supportIds => 'Support IDs';

  @override
  String get supportIdsHelp =>
      'Support may ask for these. They find your account and purchases, and don\'t give anyone access.';

  @override
  String supportWorkspaceId(String name) {
    return 'Workspace ID · $name';
  }

  @override
  String get supportWorkspaceIdHelp =>
      'Also your purchase ID in the App Store and Google Play';

  @override
  String get supportAccountId => 'Account ID';

  @override
  String get supportCopyAll => 'Copy all details';

  @override
  String get supportCopyAllHelp =>
      'App version, platform and IDs, to paste into a message';

  @override
  String get supportNewChat => 'New conversation';

  @override
  String get supportAskHint => 'Ask anything about Casama';

  @override
  String get supportAiNote =>
      'Casama Help is AI and can make mistakes. It sees your plan and bot errors, not your chats.';

  @override
  String get supportGreeting =>
      'Hi! I\'m Casama Help. Ask me about Casama, your plan, or a problem you\'re having. If I can\'t fix it, I\'ll pass it to our support team.';

  @override
  String get supportStarterPurchase => 'My purchase didn\'t go through';

  @override
  String get supportStarterCancel => 'How do I cancel my plan?';

  @override
  String get supportStarterBot => 'My bot isn\'t answering';

  @override
  String get supportStarterHowTo => 'What can my bots do?';

  @override
  String get supportAskPerson => 'Ask a person';

  @override
  String get supportHandoffTitle => 'Send this to our support team?';

  @override
  String get supportHandoffButton => 'Review and send';

  @override
  String get supportThinking => 'Looking into it…';

  @override
  String get supportAssistantError =>
      'Casama Help couldn\'t answer. Try again, or ask a person.';

  @override
  String get supportAssistantLimit =>
      'Casama Help can\'t answer more right now. A person can help.';

  @override
  String get purchaseHelp => 'Trouble with a purchase? Get help';

  @override
  String get adminReports => 'Reports';

  @override
  String get adminSupport => 'Support';

  @override
  String get report => 'Report';

  @override
  String get reportAndBlock => 'Report and block';

  @override
  String get reportReply => 'Report reply';

  @override
  String get reportBot => 'Report bot';

  @override
  String get reportBotRow =>
      'Something in its name, description or replies isn\'t right';

  @override
  String get reportPerson => 'Report person';

  @override
  String get reportGalleryItem => 'Report gallery item';

  @override
  String get reportGalleryRequest => 'Report request';

  @override
  String get reportWorkspace => 'Report workspace';

  @override
  String get reportHelp =>
      'Tell the people who run this server what\'s wrong. They review every report.';

  @override
  String get reportPersonHelp =>
      'Tell the people who run this server what happened. We\'ll also block this person for you.';

  @override
  String get reportNote => 'Anything else they should know (optional)';

  @override
  String reportAlsoBlock(String name) {
    return 'Also block $name';
  }

  @override
  String get reportSent => 'Thanks. Your report was sent for review.';

  @override
  String get reportReasonSpam => 'Spam or scam';

  @override
  String get reportReasonSexual => 'Sexual content';

  @override
  String get reportReasonViolence => 'Violence or threats';

  @override
  String get reportReasonHarassment => 'Harassment or hate';

  @override
  String get reportReasonIllegal => 'Illegal or dangerous';

  @override
  String get reportReasonImpersonation => 'Pretending to be someone';

  @override
  String get reportReasonOther => 'Something else';

  @override
  String get thisPerson => 'this person';

  @override
  String blockPerson(String name) {
    return 'Block $name';
  }

  @override
  String blocked(String name) {
    return '$name is blocked';
  }

  @override
  String get blockHelp =>
      'Blocked people can\'t invite you to a workspace, and you won\'t hear from them.';

  @override
  String get blockedPeople => 'Blocked people';

  @override
  String get blockedPeopleRow => 'People who can\'t invite you or reach you';

  @override
  String get noBlockedPeople => 'No one is blocked';

  @override
  String get unblock => 'Unblock';

  @override
  String get emailTips => 'Tips and news by email';

  @override
  String get emailTipsHelp =>
      'Getting started tips and the occasional update. Emails about your plan and account always come.';

  @override
  String get reportsInApp => 'Reported in the app';

  @override
  String get reportsNone =>
      'No open reports. Reports people send from the app show up here.';

  @override
  String get reportsPublicLinks => 'Reported public links';

  @override
  String get reportsNoLinks => 'No public links were reported.';

  @override
  String reportsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reports',
      one: '1 report',
    );
    return '$_temp0';
  }

  @override
  String get reportsTakeDown => 'Take down';

  @override
  String get reportsRestore => 'Restore';

  @override
  String get reportKindReply => 'Bot reply';

  @override
  String get reportKindBot => 'Bot';

  @override
  String get reportKindPerson => 'Person';

  @override
  String get reportKindGallery => 'Gallery item';

  @override
  String get reportKindWorkspace => 'Workspace';

  @override
  String get reportMarkActioned => 'Dealt with it';

  @override
  String reportSuspendWorkspace(String name) {
    return 'Suspend the workspace $name';
  }

  @override
  String get reportDismiss => 'Dismiss: nothing wrong';

  @override
  String get supportWebTitle => 'Website Casama Help';

  @override
  String get supportWebOn => 'On';

  @override
  String get supportWebOff => 'Off';

  @override
  String supportWebToday(int count, String spent, String budget) {
    return '$count messages today · \$$spent of \$$budget budget';
  }

  @override
  String supportWebPaused(int count) {
    return '$count addresses paused';
  }

  @override
  String supportWebGaps(int count) {
    return 'Show $count unanswered questions';
  }

  @override
  String get ticketsOpen => 'Open';

  @override
  String get ticketsClosed => 'Closed';

  @override
  String get ticketsAll => 'All';

  @override
  String get ticketsNone => 'No messages here.';

  @override
  String get ticketClose => 'Close';

  @override
  String get ticketReopen => 'Reopen';

  @override
  String get serviceStatus => 'Status';

  @override
  String get supportStatus => 'Casama Cloud status';

  @override
  String get supportStatusHelp => 'Check whether something is down right now';

  @override
  String get galleryChatSuggestionLabel => 'From the gallery';

  @override
  String get galleryChatAdd => 'Add';

  @override
  String galleryChatAdded(String name) {
    return 'Added $name';
  }

  @override
  String galleryChatReads(String things) {
    return 'Reads $things';
  }

  @override
  String get galleryChatRunsCode => 'Runs code';

  @override
  String get galleryChatComputer => 'Uses a computer';

  @override
  String galleryChatNeeds(String apps) {
    return 'Needs $apps';
  }

  @override
  String get galleryChatDraftLabel => 'Skill draft';

  @override
  String get galleryChatShowInstructions => 'Show instructions';

  @override
  String get galleryChatHideInstructions => 'Hide instructions';

  @override
  String get galleryChatSaveSkill => 'Save to my skills';

  @override
  String get galleryChatSaved => 'Saved';

  @override
  String get galleryChatSavedSkill => 'Saved to your skills';

  @override
  String get galleryChatSubmit => 'Submit to the gallery';

  @override
  String galleryChatSubmitTitle(String name) {
    return 'Submit $name to the gallery?';
  }

  @override
  String get galleryChatSubmitBody =>
      'A maintainer reviews it first. Once it\'s in, anyone can find and use it. Your display name is shown as the author, never your email.';

  @override
  String get galleryChatSent => 'Sent';

  @override
  String get galleryChatSubmitted => 'Sent to the gallery for review';

  @override
  String get galleryChatSubmissionsOff =>
      'This server doesn\'t take gallery submissions.';

  @override
  String get galleryPicksTitle => 'Picks for you';

  @override
  String get galleryPicksHelp =>
      'Start with a set of skills, apps and routines that fit. You can change anything later.';

  @override
  String get galleryPicksAdd => 'Add this set';

  @override
  String get galleryPicksSkip => 'Skip for now';

  @override
  String galleryPicksAddNamed(String name) {
    return 'Add $name';
  }

  @override
  String get galleryPicksBestMatch => 'Best match';

  @override
  String get galleryPicksInside => 'What\'s inside';

  @override
  String galleryPicksBots(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bots',
      one: '1 bot',
    );
    return '$_temp0';
  }

  @override
  String galleryPicksSkills(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count skills',
      one: '1 skill',
    );
    return '$_temp0';
  }

  @override
  String galleryPicksRoutines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count routines',
      one: '1 routine',
    );
    return '$_temp0';
  }

  @override
  String galleryPicksApps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count apps',
      one: '1 app',
    );
    return '$_temp0';
  }

  @override
  String galleryPicksPlugins(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count plugins',
      one: '1 plugin',
    );
    return '$_temp0';
  }

  @override
  String galleryPicksLooks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count looks',
      one: '1 look',
    );
    return '$_temp0';
  }

  @override
  String galleryPicksAdded(String name) {
    return 'Added $name';
  }

  @override
  String galleryPicksAddedNeedsApps(String name, String apps) {
    return 'Added $name. Connect $apps in Apps to finish.';
  }

  @override
  String galleryPicksPending(String name) {
    return 'An admin will look at $name before it\'s added.';
  }

  @override
  String get galleryPolicyTitle => 'Gallery';

  @override
  String get galleryPolicyRow => 'What people here can add from the gallery';

  @override
  String get galleryPolicyMode => 'Who can add';

  @override
  String get galleryPolicyOpen => 'Open';

  @override
  String get galleryPolicyOpenHelp =>
      'Anyone here can add anything that isn\'t blocked.';

  @override
  String get galleryPolicyApproval => 'Ask first';

  @override
  String get galleryPolicyApprovalHelp =>
      'Adding asks an admin first, for what you pick below.';

  @override
  String get galleryPolicyAllowlist => 'Only allowed';

  @override
  String get galleryPolicyAllowlistHelp =>
      'People can add only what\'s on the allowed list.';

  @override
  String get galleryPolicyApprovalFor => 'Ask first for';

  @override
  String get galleryPolicyRunsCode => 'Things that run code';

  @override
  String get galleryPolicyApps => 'Things that connect apps';

  @override
  String get galleryPolicyAll => 'Everything';

  @override
  String get galleryPolicyAllowed => 'Allowed';

  @override
  String get galleryPolicyAllowedHelp =>
      'Added without asking. With Only allowed, the only things people can add.';

  @override
  String get galleryPolicyBlocked => 'Blocked';

  @override
  String get galleryPolicyBlockedHelp => 'Nobody here can add these.';

  @override
  String get galleryPolicyAddItem => 'Add from the gallery';

  @override
  String get galleryPolicyNone => 'Nothing yet';

  @override
  String get galleryPolicySearch => 'Search the gallery';

  @override
  String get galleryPolicyNoResults => 'Nothing in the gallery matches.';

  @override
  String get galleryPolicySaved => 'Gallery rules saved';

  @override
  String galleryPolicyRemove(String name) {
    return 'Remove $name';
  }

  @override
  String get galleryPolicyAdminsOnly =>
      'Only admins and owners can change this.';

  @override
  String get galleryPolicyWaiting => 'Waiting for approval';

  @override
  String galleryPolicyRequestedBy(String name) {
    return '$name asked';
  }

  @override
  String get galleryPolicyApprove => 'Approve';

  @override
  String get galleryPolicyDecline => 'Decline';

  @override
  String galleryPolicyApproved(String name) {
    return '$name approved and added';
  }

  @override
  String galleryPolicyDeclined(String name) {
    return '$name declined';
  }

  @override
  String galleryPolicyApproveFailed(String name, String error) {
    return 'Approved, but $name couldn\'t be added. $error';
  }

  @override
  String get galleryDigestEmails => 'Monthly gallery picks';

  @override
  String get galleryDigestHelp =>
      'Up to six new skills, apps and routines that fit what you use, once a month.';

  @override
  String get newsletterTitle => 'Casama\'s monthly email';

  @override
  String get newsletterHelp =>
      'What\'s new and what\'s next, once a month at most.';

  @override
  String get newsletterSignUp =>
      'Send me Casama\'s monthly email: what\'s new and what\'s next, once a month at most.';

  @override
  String get newsletterCardTitle => 'Get Casama\'s monthly email?';

  @override
  String get newsletterCardBody =>
      'What\'s new and what\'s next, once a month at most. Stop any time.';

  @override
  String get newsletterCardYes => 'Yes, send it';

  @override
  String get newsletterCardNo => 'No thanks';

  @override
  String get newsletterCardDone =>
      'You\'re on the list. Turn it off any time in Settings.';

  @override
  String get galleryKindApp => 'App';

  @override
  String get galleryKindApps => 'Apps';

  @override
  String get galleryKindBot => 'Starter bot';

  @override
  String get galleryKindBots => 'Starter bots';

  @override
  String get galleryKindRoutine => 'Routine';

  @override
  String get galleryKindRoutines => 'Routines';

  @override
  String get galleryKindPlugin => 'Plugin';

  @override
  String get galleryKindPlugins => 'Plugins';

  @override
  String get galleryKindSet => 'Starter set';

  @override
  String get galleryKindSets => 'Starter sets';

  @override
  String get galleryTabBrowse => 'Browse';

  @override
  String get galleryTabInstalled => 'Installed';

  @override
  String get gallerySearchEverything => 'Search everything';

  @override
  String get galleryNewBadge => 'New';

  @override
  String get galleryRowPicks => 'Picks';

  @override
  String get galleryRowNew => 'New';

  @override
  String get galleryRowTrending => 'Trending this week';

  @override
  String get galleryRowMostUsed => 'Most used';

  @override
  String get galleryRowWorksWith => 'Works with what you have';

  @override
  String get galleryRowSets => 'Starter sets';

  @override
  String get galleryRowSeasonal => 'In season';

  @override
  String get galleryFilterFree => 'Free';

  @override
  String get galleryFilterPlan => 'Uses credits';

  @override
  String get galleryFilterSelfHosted => 'Works self-hosted';

  @override
  String get galleryFilterComputer => 'Needs a computer';

  @override
  String get galleryNoFilterMatches => 'Nothing matches these filters';

  @override
  String get galleryClearFilters => 'Clear filters';

  @override
  String get galleryRequestThis => 'Request this';

  @override
  String get galleryAskCasama => 'Ask Casama to make it';

  @override
  String galleryAskPrompt(String query) {
    return 'Make me something for this: $query';
  }

  @override
  String get galleryAccessTitle => 'What it can access';

  @override
  String galleryAccessReads(String things) {
    return 'Reads your $things';
  }

  @override
  String get galleryAccessRunsCode => 'Runs code';

  @override
  String get galleryAccessComputer => 'Uses a computer';

  @override
  String get galleryAccessNothing =>
      'Doesn\'t read or change anything of yours';

  @override
  String get galleryCreditsNone => 'Uses no credits';

  @override
  String get galleryCreditsLow => 'Uses few credits';

  @override
  String get galleryCreditsMedium => 'Uses some credits';

  @override
  String get galleryCreditsHigh => 'Uses many credits';

  @override
  String get galleryTryIt => 'Try it';

  @override
  String galleryUsedBy(int count, String shown) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Used by $shown people',
      one: 'Used by 1 person',
    );
    return '$_temp0';
  }

  @override
  String galleryRunsFinish(int percent) {
    return '$percent% of runs finish';
  }

  @override
  String get galleryAbout => 'About';

  @override
  String get galleryMadeByCasama => 'Made by Casama';

  @override
  String get galleryMadeByCommunity => 'Made by the community';

  @override
  String get galleryMadeReviewed => 'Reviewed';

  @override
  String get galleryReviewedHelp => 'Its tests passed for this version';

  @override
  String galleryMoreFrom(String name) {
    return 'More from $name';
  }

  @override
  String galleryVersion(int version) {
    return 'Version $version';
  }

  @override
  String galleryUpdatedOn(String date) {
    return 'Updated $date';
  }

  @override
  String galleryRemixOf(String name) {
    return 'Remix of $name';
  }

  @override
  String galleryChangesTitle(String name) {
    return 'What changed in $name';
  }

  @override
  String get galleryBreaking => 'Works differently';

  @override
  String galleryAuthorCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items in the gallery',
      one: '1 item in the gallery',
    );
    return '$_temp0';
  }

  @override
  String get galleryAuthorEmpty => 'Nothing in the gallery by this author yet.';

  @override
  String get galleryInstalledWorkspace => 'In this workspace';

  @override
  String get galleryInstalledDevice => 'Looks on this device';

  @override
  String get galleryInstalledEmptyTitle => 'Nothing added yet';

  @override
  String get galleryInstalledEmpty =>
      'Skills, apps, routines and looks you add from the gallery show here, with updates.';

  @override
  String get galleryInstalledError => 'Couldn\'t load what\'s installed.';

  @override
  String galleryUpdatesAvailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count updates',
      one: '1 update',
    );
    return '$_temp0';
  }

  @override
  String get galleryUpdate => 'Update';

  @override
  String galleryUpdated(String name) {
    return 'Updated $name';
  }

  @override
  String galleryUpdateFromTo(int from, int to) {
    return 'Version $from → $to';
  }

  @override
  String galleryUpdateAskTitle(String name) {
    return 'Update $name?';
  }

  @override
  String get galleryUpdateAccessHelp =>
      'The new version can do more than the one you have:';

  @override
  String get galleryUpdateBreakingHelp =>
      'The new version works differently, so check it after updating.';

  @override
  String galleryUpdateNowReads(String things) {
    return 'Now reads your $things';
  }

  @override
  String galleryUpdateNowWrites(String action) {
    return 'Now can: $action';
  }

  @override
  String get galleryUpdateNowRunsCode => 'Now runs code';

  @override
  String get galleryUpdateNowComputer => 'Now uses a computer';

  @override
  String get galleryRemove => 'Remove';

  @override
  String galleryRemoveTitle(String name) {
    return 'Remove $name?';
  }

  @override
  String get galleryRemoveHelp =>
      'It\'s removed from this workspace. You can add it again from the gallery.';

  @override
  String galleryRemoved(String name) {
    return 'Removed $name';
  }

  @override
  String get galleryRetired => 'No longer in the gallery';

  @override
  String get galleryRetiredReplaced =>
      'No longer in the gallery; there\'s a replacement';

  @override
  String get gallerySeeReplacement => 'See replacement';

  @override
  String get galleryForgetLook => 'Remove from this list';

  @override
  String galleryWizardTitle(String name) {
    return 'Add $name';
  }

  @override
  String get galleryWizardAdd => 'Add';

  @override
  String get galleryWizardRequired => 'Fill this in';

  @override
  String galleryWizardSetIncludes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Includes $count items',
      one: 'Includes 1 item',
    );
    return '$_temp0';
  }

  @override
  String get galleryWizardNeeds => 'What it needs';

  @override
  String galleryWizardNeedsSkills(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count skills, added for you',
      one: '1 skill, added for you',
    );
    return '$_temp0';
  }

  @override
  String galleryWizardNeedsApps(String apps) {
    return 'Apps to connect: $apps';
  }

  @override
  String get galleryWizardBot => 'Add to which bot';

  @override
  String get galleryWizardPickBot => 'Pick a bot';

  @override
  String get galleryWizardSetBotHelp =>
      'Where the set\'s routines go. Without one they\'re left out.';

  @override
  String get galleryWizardSetNotAdded => 'Not added';

  @override
  String get galleryWizardNeedsTitle => 'Connect your apps';

  @override
  String galleryWizardNeedsHelp(String name) {
    return '$name works once these are connected.';
  }

  @override
  String get galleryWizardSkillAdded => 'Added';

  @override
  String get galleryWizardConnected => 'Connected';

  @override
  String get galleryWizardConnect => 'Connect';

  @override
  String galleryWizardConnectInApps(String name) {
    return 'Connect $name in Settings → Apps.';
  }

  @override
  String get galleryWizardContinue => 'Continue';

  @override
  String get galleryWizardSkip => 'Later';

  @override
  String galleryWizardDoneTitle(String name) {
    return '$name is ready';
  }

  @override
  String get galleryWizardDoneHelp =>
      'You\'ll find it with the rest of your things.';

  @override
  String galleryWizardDoneMissing(String apps) {
    return 'It works fully once you connect $apps.';
  }

  @override
  String get galleryWizardPendingTitle => 'Waiting for approval';

  @override
  String get galleryWizardPendingHelp =>
      'Your workspace asks an admin first. It\'s added once they approve.';

  @override
  String get galleryRequestsTitle => 'Requests';

  @override
  String get galleryRequestsHelp =>
      'Ideas for the gallery. Vote for the ones you want; makers pick from the top.';

  @override
  String get galleryRequestsLinkHelp =>
      'Ask for something that isn\'t here yet, or vote';

  @override
  String get galleryRequestsTop => 'Top';

  @override
  String get galleryRequestsNew => 'New';

  @override
  String get galleryRequestsEmpty => 'No requests yet. Be the first.';

  @override
  String get galleryRequestsError => 'Couldn\'t load requests.';

  @override
  String get galleryRequestNew => 'New request';

  @override
  String get galleryRequestNewHelp =>
      'Say what you\'d like someone to make. Similar requests are merged.';

  @override
  String get galleryRequestKind => 'Kind';

  @override
  String get galleryRequestTitleLabel => 'What should it do?';

  @override
  String get galleryRequestTitleLength => 'Use 4 to 80 characters.';

  @override
  String get galleryRequestDetails => 'Details (optional)';

  @override
  String get galleryRequestSend => 'Send request';

  @override
  String get galleryRequestSent => 'Request sent';

  @override
  String galleryRequestSimilar(String title) {
    return '\"$title\" was already asked for, so your vote went to it';
  }

  @override
  String get galleryRequestMine => 'Yours';

  @override
  String get galleryRequestVote => 'Vote';

  @override
  String get galleryRequestOpen => 'Open';

  @override
  String get galleryRequestPlanned => 'Planned';

  @override
  String get galleryRequestDone => 'Done';

  @override
  String get galleryRequestDeclined => 'Declined';

  @override
  String get gallerySubmitStart => 'Submit to the gallery';

  @override
  String get gallerySubmissionsLinkHelp =>
      'Share a look, skill, routine or bot you made';

  @override
  String get gallerySubmitPick => 'What do you want to share?';

  @override
  String get gallerySubmitPickHelp =>
      'Pick something you made. It\'s reviewed before it\'s in the gallery.';

  @override
  String get galleryLooksMine => 'Your looks';

  @override
  String get gallerySubmitCurrentScheme => 'Color scheme in use';

  @override
  String get gallerySubmitCurrentWallpaper => 'Wallpaper in use';

  @override
  String get gallerySubmitMyWallpaper => 'My wallpaper';

  @override
  String gallerySubmitTitle(String kind) {
    return 'Submit a $kind';
  }

  @override
  String get gallerySubmitHelp =>
      'Your display name is shown as the author. Your email is never shared.';

  @override
  String get gallerySubmitName => 'Name';

  @override
  String get gallerySubmitNameLength => 'Use 1 to 60 characters.';

  @override
  String get gallerySubmitTags => 'Tags';

  @override
  String get gallerySubmitTagsHelp => 'Up to six, separated by commas';

  @override
  String get gallerySubmitLicense => 'License';

  @override
  String gallerySubmitRemix(String name) {
    return 'Credits the original: $name';
  }

  @override
  String get gallerySubmitSend => 'Submit';

  @override
  String get gallerySubmitted => 'Sent for review';

  @override
  String get gallerySubmissionsTitle => 'My submissions';

  @override
  String get gallerySubmissionsHelp =>
      'What you sent to the gallery and where it stands.';

  @override
  String get gallerySubmissionsSent => 'Sent';

  @override
  String get gallerySubmissionsEmpty => 'Nothing sent yet.';

  @override
  String get gallerySubmissionsError => 'Couldn\'t load your submissions.';

  @override
  String get gallerySubmissionOpen => 'In review';

  @override
  String get gallerySubmissionMerged => 'In the gallery';

  @override
  String get gallerySubmissionClosed => 'Not accepted';

  @override
  String get gallerySubmissionFailed => 'Couldn\'t be sent';

  @override
  String get galleryMyItems => 'Your items in the gallery';

  @override
  String galleryReportsOpen(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count open reports',
      one: '1 open report',
    );
    return '$_temp0';
  }

  @override
  String get islandBot => 'A bot';

  @override
  String get islandNeedsOk => 'Needs your OK';

  @override
  String get islandTakeOver => 'Wants you to take over';

  @override
  String get islandWriting => 'Writing a reply';

  @override
  String get islandWorking => 'Working';

  @override
  String get islandFinished => 'Finished';

  @override
  String get islandStoppedProblem => 'Stopped with a problem';

  @override
  String get islandOnThisMac => 'On this Mac';

  @override
  String get islandStale => 'Open Casama for the latest';

  @override
  String get islandOpen => 'Open';

  @override
  String get islandStop => 'Stop';

  @override
  String get islandAllow => 'Allow';

  @override
  String get islandDeny => 'Deny';

  @override
  String get islandReview => 'Review';

  @override
  String get islandNothing => 'No bot is working right now';

  @override
  String get islandQuickAsk => 'Quick ask…';

  @override
  String get islandOpenCasama => 'Open Casama';

  @override
  String get islandSettings => 'Settings…';

  @override
  String get islandQuit => 'Quit Casama';

  @override
  String get islandAskHint => 'Ask a bot…';

  @override
  String get islandNeedsYou => 'Needs you';

  @override
  String get islandDropHere => 'Drop to ask a bot';

  @override
  String get islandBotWorking => 'A bot is working';

  @override
  String get islandOnThisComputer => 'on this computer';

  @override
  String get islandOnACall => 'On a call';

  @override
  String get islandStartElsewhere => 'Bots you start elsewhere';

  @override
  String get islandStartElsewhereHelp =>
      'Show what you start on another device, such as your Mac, on this phone\'s Lock Screen too.';

  @override
  String get islandBotsAtWork => 'Bots at work';

  @override
  String islandSteps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count steps',
      one: '1 step',
    );
    return '$_temp0';
  }

  @override
  String get showBotsInNotch => 'Show bots in the notch';

  @override
  String get showBotsInNotchHelp =>
      'What your bots are doing, around the camera. The menu bar icon shows it either way.';

  @override
  String get notchOnHover => 'Open the notch on hover';

  @override
  String get notchOnHoverHelp => 'Off: click the notch to open it.';

  @override
  String get sitePublishToWeb => 'Publish to the Web';

  @override
  String get sitePublishToWebHelp => 'Give it its own web address.';

  @override
  String get siteAddressName => 'Address name';

  @override
  String get siteAddressRules =>
      '3 to 40 lowercase letters, numbers and hyphens, starting and ending with a letter or number.';

  @override
  String get siteAddressChecking => 'Checking…';

  @override
  String get siteAddressAvailable => 'Available';

  @override
  String get siteAddressTaken => 'This name isn\'t available.';

  @override
  String get siteAnyoneCanOpen =>
      'Anyone with the address will be able to open it.';

  @override
  String get sitePublish => 'Publish';

  @override
  String get siteOnTheWeb => 'On the web';

  @override
  String get siteSearchEngines => 'Let Search Engines Find It';

  @override
  String get siteSearchEnginesHelp =>
      'Lists it in Google and other search engines.';

  @override
  String get siteSearchEnginesPaid => 'Needs a paid plan.';

  @override
  String get siteUseOwnDomain => 'Use Your Own Domain';

  @override
  String get siteUnpublish => 'Unpublish';

  @override
  String get siteUnpublishTitle => 'Unpublish this site?';

  @override
  String get siteUnpublishBody =>
      'It stops opening at its web addresses. It stays in your Library.';

  @override
  String get siteHostLive => 'Live';

  @override
  String get siteHostWaitingForDns => 'Waiting for DNS';

  @override
  String get siteHostGettingCertificate => 'Getting its certificate';

  @override
  String get siteHostNeedsAttention => 'Needs attention';

  @override
  String get siteHostPaused => 'Paused';

  @override
  String get siteHostSuspended => 'Suspended';

  @override
  String get settingsDomains => 'Domains';

  @override
  String get settingsDomainsHelp => 'Open your sites at a domain you own.';

  @override
  String get settingsSearchHint => 'Search settings';

  @override
  String settingsSearchNone(String query) {
    return 'No settings match “$query”.';
  }

  @override
  String get domainsEmpty =>
      'Connect a domain you own, like bakery.com, and your site opens there.';

  @override
  String get domainsConnectOwn => 'Connect a Domain You Own';

  @override
  String get domainStateLive => 'Live';

  @override
  String get domainStateWaitingDns => 'Waiting for DNS';

  @override
  String get domainStateWaitingCert => 'Getting Its Certificate';

  @override
  String get domainStatePaused => 'Paused';

  @override
  String get domainStateNeedsAttention => 'Needs Attention';

  @override
  String get domainNoSite => 'No site yet';

  @override
  String get domainConnectField => 'Your domain';

  @override
  String get domainConnectHelp =>
      'Type it like bakery.com, www.bakery.com or shop.bakery.com.';

  @override
  String get domainConnectSite => 'Site to show';

  @override
  String get domainSiteNone => 'None';

  @override
  String get domainSiteNoneHelp =>
      'The domain shows nothing until you pick a site.';

  @override
  String get domainConnect => 'Connect';

  @override
  String get domainClaimTitle => 'Show it\'s yours';

  @override
  String get domainClaimBody =>
      'Another workspace has connected this domain. Add this record to show it\'s yours, then tap Connect again.';

  @override
  String get domainRecordType => 'Type';

  @override
  String get domainRecordName => 'Name';

  @override
  String get domainRecordValue => 'Value';

  @override
  String get domainSite => 'Site';

  @override
  String get domainPickSite => 'Choose a Site';

  @override
  String get domainHosts => 'Addresses';

  @override
  String get domainPrimary => 'Primary';

  @override
  String get domainPrimaryHelp =>
      'Visitors land here; the other addresses send them to it.';

  @override
  String get domainMakePrimary => 'Make Primary';

  @override
  String get domainRecordsTitle => 'Records to add';

  @override
  String get domainRecordsAtCloudflare =>
      'Add these at Cloudflare. Set the records to DNS only.';

  @override
  String domainRecordsAt(String provider) {
    return 'Add these in your DNS settings at $provider.';
  }

  @override
  String get domainRecordsGeneric =>
      'Add these where your domain\'s DNS is managed, usually the company you bought it from.';

  @override
  String get domainRecordsNone => 'Nothing to add. You\'re all set.';

  @override
  String get domainRecordOptional => 'Optional';

  @override
  String domainRecordForward(String from, String to) {
    return 'Turn on forwarding from $from to $to at the company you bought the domain from.';
  }

  @override
  String get domainRecordFound => 'Found';

  @override
  String get domainRecordNotFound => 'Not found yet';

  @override
  String get domainCheckAgain => 'Check Again';

  @override
  String get domainCheckTooSoon =>
      'We just checked. Try again in a few seconds.';

  @override
  String get domainChecksItself =>
      'We also check by ourselves, so you can leave this screen.';

  @override
  String get domainHistory => 'History';

  @override
  String get domainEventConnected => 'Connected';

  @override
  String get domainEventProved => 'Records found';

  @override
  String get domainEventLive => 'Live';

  @override
  String get domainEventNeedsDns => 'Still waiting for DNS';

  @override
  String get domainEventFailed => 'Couldn\'t finish setting up';

  @override
  String get domainEventDisconnected =>
      'Records removed, so it was disconnected';

  @override
  String get domainEventPaused => 'Paused: your plan doesn\'t cover it';

  @override
  String get domainEventResumed => 'Back on';

  @override
  String get domainEventRemoved => 'Disconnected';

  @override
  String get domainEventClaim => 'Asked to show it\'s yours';

  @override
  String get domainEventClaimAttempt => 'Another workspace tried to connect it';

  @override
  String get domainEventOverLimit => 'Over your plan\'s limit';

  @override
  String get domainEventSuspended => 'Suspended';

  @override
  String get domainEventOther => 'Updated';

  @override
  String domainDisconnectTitle(String name) {
    return 'Disconnect $name?';
  }

  @override
  String get domainDisconnectBody =>
      'Your site stops opening at this domain. You can remove its records at your DNS company afterwards.';

  @override
  String get domainsFind => 'Find a Domain';

  @override
  String get domainsEmptyBuy =>
      'Buy a domain for your site, or connect one you own.';

  @override
  String get domainFindField => 'Name or a few words';

  @override
  String get domainFindHint => 'bakery';

  @override
  String get domainFindHelp => 'Prices are per year and before tax.';

  @override
  String get domainFindNone => 'No names found. Try other words.';

  @override
  String get domainFindNotOffered =>
      'Buying a domain isn\'t available in this app. You can still connect a domain you own.';

  @override
  String domainPricePerYear(String price) {
    return '$price a year plus tax';
  }

  @override
  String domainRenewsAt(String price) {
    return 'Renews at $price';
  }

  @override
  String get domainReasonTaken => 'Taken';

  @override
  String get domainReasonPremium => 'Premium name, not sold here';

  @override
  String get domainReasonNotSold => 'Not sold here';

  @override
  String get domainBuy => 'Buy';

  @override
  String domainBuyTitle(String name) {
    return 'Buy $name';
  }

  @override
  String domainBuyPrice(String price, String renew) {
    return '$price for the first year, then $renew a year, plus tax.';
  }

  @override
  String get domainBuyFinal =>
      'Sales are final once the domain is registered. If it can\'t be registered, you get a full refund.';

  @override
  String get domainBuyTerms => 'I accept the domain terms';

  @override
  String get domainBuyReadTerms => 'Read the Terms';

  @override
  String get domainRenewAuto => 'Renew Automatically';

  @override
  String get domainRenewAutoHelp =>
      'Charges your saved payment method about two weeks before it expires.';

  @override
  String get domainBuySite => 'Site to show';

  @override
  String get domainBuyPayInBrowser =>
      'Finish paying in your browser. This screen follows along.';

  @override
  String get domainContactTitle => 'Contact Details';

  @override
  String get domainContactHelp =>
      'The person or business the domain is registered to. Registrars keep these private.';

  @override
  String get domainContactFirstName => 'First name';

  @override
  String get domainContactLastName => 'Last name';

  @override
  String get domainContactOrganization => 'Business (optional)';

  @override
  String get domainContactAddress1 => 'Address';

  @override
  String get domainContactAddress2 => 'Address line 2 (optional)';

  @override
  String get domainContactCity => 'City';

  @override
  String get domainContactState => 'State or region';

  @override
  String get domainContactZip => 'Postal code';

  @override
  String get domainContactCountry => 'Country code';

  @override
  String get domainContactCountryHint => 'US';

  @override
  String get domainContactPhone => 'Phone';

  @override
  String get domainContactPhoneHint => '+1 415 555 0100';

  @override
  String get domainContactEmail => 'Email';

  @override
  String get domainContactRequired => 'Required';

  @override
  String get domainContactCountryInvalid => 'Use a two-letter code, like US';

  @override
  String get domainContactPhoneInvalid =>
      'Use international form, like +1 415 555 0100';

  @override
  String get domainContactEmailInvalid => 'Enter a valid email';

  @override
  String get domainContactSave => 'Save';

  @override
  String get domainContactSaved => 'Contact details saved.';

  @override
  String get domainContactChangeNote =>
      'Changes apply to every domain this workspace bought. A new email has to be confirmed again.';

  @override
  String get domainOrderTitle => 'Your Order';

  @override
  String get domainOrderWaitingPayment =>
      'Waiting for your payment in the browser.';

  @override
  String domainOrderRegistering(String name) {
    return 'Registering $name…';
  }

  @override
  String domainOrderSettingUp(String name) {
    return 'Setting up $name…';
  }

  @override
  String domainOrderRefunding(String name) {
    return 'We couldn\'t register $name. Refunding you now…';
  }

  @override
  String domainOrderRefunded(String name) {
    return 'We couldn\'t register $name, so we refunded you in full.';
  }

  @override
  String get domainOrderAbandoned =>
      'This checkout wasn\'t paid, so nothing was charged.';

  @override
  String get domainOrderNeedsAttention =>
      'Something went wrong with this order. We\'ve been told and will sort it out.';

  @override
  String domainOrderDone(String name) {
    return '$name is yours.';
  }

  @override
  String get domainOrderLeave =>
      'You can leave this screen. We\'ll let you know when it\'s ready.';

  @override
  String get domainOrderBack => 'Back to Domains';

  @override
  String domainRenewsOn(String date) {
    return 'Renews on $date';
  }

  @override
  String domainExpiresOn(String date) {
    return 'Expires on $date';
  }

  @override
  String domainRenewPrice(String price) {
    return '$price a year plus tax';
  }

  @override
  String get domainRenewNow => 'Renew Now';

  @override
  String get domainRenewPayInBrowser =>
      'Finish paying in your browser. The new date shows here once it\'s paid.';

  @override
  String get domainRenewCharged =>
      'Renewed. The new date shows here in a minute.';

  @override
  String get domainRegistration => 'Registration';

  @override
  String domainExpired(String date) {
    return 'Expired on $date. Renew within 25 days of that date to keep it.';
  }

  @override
  String get domainLapsed =>
      'This domain has lapsed. Write to support to ask about restoring it; that isn\'t guaranteed.';

  @override
  String get domainSuspendedLine =>
      'This domain is suspended. Write to support to find out why.';

  @override
  String get domainVerifyTitle => 'Confirm the registrant email';

  @override
  String get domainVerifyBody =>
      'The registrar sent an email to the registrant\'s address. Open it and confirm, or the domain stops working.';

  @override
  String get domainVerifySendAgain => 'Send Again';

  @override
  String get domainVerifySent => 'Sent. Check the registrant\'s inbox.';

  @override
  String get domainDnsRecords => 'DNS Records';

  @override
  String get domainDnsRecordsHelp => 'Email, subdomains and site checks';

  @override
  String get domainMoveOut => 'Move to Another Registrar';

  @override
  String domainMoveOutAfter(String date) {
    return 'It can move after $date';
  }

  @override
  String get domainMoveOutHelp => 'Get a transfer code for another registrar';

  @override
  String domainMoveOutTitle(String name) {
    return 'Move $name?';
  }

  @override
  String domainMoveOutBody(String name) {
    return 'This unlocks the domain and shows its transfer code once. Type $name to confirm.';
  }

  @override
  String get domainMoveOutConfirm => 'Get Transfer Code';

  @override
  String domainMoveOutLocked(String date) {
    return 'It can move after $date.';
  }

  @override
  String get domainTransferCodeTitle => 'Transfer code';

  @override
  String get domainTransferCodeBody =>
      'Give this code to the new registrar. It\'s shown only this once, so copy it now.';

  @override
  String get domainTransferCode => 'Code';

  @override
  String get domainUnlocked => 'Unlocked for a move';

  @override
  String get domainLockAgain => 'Lock Again';

  @override
  String get domainLocked => 'Locked again.';

  @override
  String get domainReauthTitle => 'Sign In Again';

  @override
  String get domainReauthSendCode => 'Email Me a Code';

  @override
  String domainReauthCodeSent(String email) {
    return 'We sent a code to $email.';
  }

  @override
  String get domainReauthCode => 'Code from the email';

  @override
  String get domainReauthSignIn => 'Sign In';

  @override
  String get domainReauthSignOut =>
      'Sign out and in again, then try once more.';

  @override
  String get dnsRecordsEmpty => 'No records yet.';

  @override
  String get dnsRecordAdd => 'Add Record';

  @override
  String get dnsRecordEdit => 'Edit Record';

  @override
  String get dnsRecordManaged => 'Used by your Casama site';

  @override
  String get dnsRecordType => 'Type';

  @override
  String get dnsRecordHost => 'Name';

  @override
  String dnsRecordHostHelp(String name) {
    return 'Leave empty for $name itself, or type www, shop…';
  }

  @override
  String get dnsRecordAnswer => 'Value';

  @override
  String get dnsRecordTtl => 'TTL (seconds)';

  @override
  String get dnsRecordPriority => 'Priority';

  @override
  String get dnsRecordSave => 'Save';

  @override
  String get dnsRecordDeleteTitle => 'Delete this record?';

  @override
  String dnsRecordDeleteBody(String type, String host, String answer) {
    return '$type $host → $answer';
  }

  @override
  String get dnsRecordTtlInvalid => '300 seconds or more';

  @override
  String get dnsRecordAnswerRequired => 'Required';

  @override
  String get adminDomains => 'Domains';

  @override
  String get adminMail => 'Mail';

  @override
  String adminMailHealth(int sent, int bounced, int complained) {
    return '$sent sent · $bounced bounced · $complained complained in 30 days';
  }

  @override
  String get adminMailAutoPaused => 'Paused automatically';

  @override
  String get adminMailPause => 'Pause';

  @override
  String adminMailPauseTitle(String address) {
    return 'Pause $address?';
  }

  @override
  String get adminMailLift => 'Lift';

  @override
  String adminMailLiftTitle(String address) {
    return 'Lift the pause on $address?';
  }

  @override
  String get adminMailLiftBody =>
      'This clears the automatic pause. The owner can pause it again themselves.';

  @override
  String get adminMailReserved => 'Reserved names';

  @override
  String get adminMailReservedHelp =>
      'One name per line. Nobody can claim these, on top of the built-in list.';

  @override
  String get adminDomainsConnected => 'Connected';

  @override
  String get adminDomainsRegistered => 'Bought';

  @override
  String get adminDomainsLiveHosts => 'Live addresses';

  @override
  String get adminDomainsSuspended => 'Suspended';

  @override
  String get adminDomainsBalance => 'Registrar balance';

  @override
  String get adminDomainsBalanceUnknown => 'Not available';

  @override
  String get adminDomainsOrders => 'Orders that need a person';

  @override
  String get adminDomainsNoOrders => 'No orders need a person.';

  @override
  String get adminDomainsList => 'Domains';

  @override
  String get adminDomainsNone => 'No domains yet.';

  @override
  String get adminDomainsApprove => 'Approve';

  @override
  String get adminDomainsRetry => 'Retry';

  @override
  String get adminDomainsApproved => 'Approved. Registering now.';

  @override
  String get adminDomainsRetried => 'Trying again.';

  @override
  String get adminDomainsSuspend => 'Suspend';

  @override
  String get adminDomainsUnsuspend => 'Unsuspend';

  @override
  String adminDomainsSuspendTitle(String name) {
    return 'Suspend $name?';
  }

  @override
  String get adminDomainsSuspendBody =>
      'Its site goes offline and the domain is locked at the registrar.';

  @override
  String adminDomainsUnsuspendTitle(String name) {
    return 'Unsuspend $name?';
  }

  @override
  String get adminDomainsUnsuspendBody =>
      'Its site comes back and the domain works again.';

  @override
  String adminDomainsAttempts(int count) {
    return '$count tries';
  }

  @override
  String get adminDomainsNoWorkspace => 'No workspace';

  @override
  String get deleteAccountDomains => 'Bought domains in your workspaces';

  @override
  String get deleteAccountDomainsBody =>
      'These domains stay registered to their registrant until they expire, stop renewing, and their sites go offline.';

  @override
  String get whatsNew010Sites =>
      'Put a page on the web at its own address, and use your own domain for it.';

  @override
  String get inAppAlertOpen => 'Open';

  @override
  String get pushPrefsTitle => 'Notifications';

  @override
  String get pushPrefsHelp =>
      'Choose what buzzes your devices. Everything still lands in your inbox.';

  @override
  String get pushAllOn => 'All on';

  @override
  String pushOneOff(String kind) {
    return '$kind off';
  }

  @override
  String pushSomeOff(int count) {
    return '$count kinds off';
  }

  @override
  String get pushReplies => 'Replies';

  @override
  String get pushRepliesHelp =>
      'When a bot answers something you asked, if you\'ve left the chat.';

  @override
  String get pushNeedsYou => 'Needs you';

  @override
  String get pushNeedsYouHelp =>
      'Approvals, passwords and takeovers your bots are waiting for.';

  @override
  String get pushNeedsYouOffWarning =>
      'Off: your bots will wait until you open the app.';

  @override
  String get pushRoutines => 'Routines and briefs';

  @override
  String get pushRoutinesHelp => 'Results of routines and your morning brief.';

  @override
  String get pushSuggestions => 'Suggestions and check-ins';

  @override
  String get pushSuggestionsHelp => 'Things your bots offer to do for you.';

  @override
  String get pushAccount => 'Account';

  @override
  String get pushAccountHelp =>
      'Credits running low, projects and your server.';

  @override
  String get pushHideReplyText => 'Hide reply text';

  @override
  String get pushHideReplyTextHelp =>
      'Notifications say a bot replied, without its words.';

  @override
  String get reactToMessage => 'React';

  @override
  String get moreReactions => 'More reactions';

  @override
  String get reactionsTitle => 'Reactions';

  @override
  String get reactionsAll => 'All';

  @override
  String get reactionsYou => 'You';

  @override
  String get reactionsTapToRemove => 'Tap to remove';

  @override
  String get reactionsNone => 'No reactions yet.';

  @override
  String get reactionsLoadFailed => 'Couldn\'t load who reacted.';

  @override
  String get searchEmoji => 'Search emoji';

  @override
  String reactionChip(String emoji, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reactions',
      one: '1 reaction',
    );
    return '$emoji, $_temp0';
  }

  @override
  String reactionChipMine(String emoji, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reactions',
      one: '1 reaction',
    );
    return '$emoji, $_temp0, including yours';
  }

  @override
  String reactionQuick(String emoji) {
    return 'React with $emoji';
  }

  @override
  String reactionRemove(String emoji) {
    return 'Remove your $emoji reaction';
  }

  @override
  String get packsShelfTitle => 'Packs';

  @override
  String get packsShelfHelp =>
      'Bots, skills and routines that work together, added in one go.';

  @override
  String get packReviewed => 'Reviewed';

  @override
  String get packNotReviewed => 'Not reviewed by Casama';

  @override
  String packCountBots(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bots',
      one: '1 bot',
    );
    return '$_temp0';
  }

  @override
  String packCountSkills(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count skills',
      one: '1 skill',
    );
    return '$_temp0';
  }

  @override
  String packCountRoutines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count routines',
      one: '1 routine',
    );
    return '$_temp0';
  }

  @override
  String packCountApps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count apps',
      one: '1 app',
    );
    return '$_temp0';
  }

  @override
  String packCountLooks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count looks',
      one: '1 look',
    );
    return '$_temp0';
  }

  @override
  String packCountTools(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tools',
      one: '1 tool',
    );
    return '$_temp0';
  }

  @override
  String packCountItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get packStarterSet => 'Starter set';

  @override
  String get packAddFromLink => 'Add a pack from a link';

  @override
  String get packAddFromLinkHelp =>
      'Paste a GitHub link to a pack and see what it adds first.';

  @override
  String get packAddFromFile => 'Add from a file';

  @override
  String get packAddFromFileHelp => 'Pick a pack\'s .zip file.';

  @override
  String get packLinkLabel => 'GitHub link';

  @override
  String get packFileUnreadable => 'That file isn\'t a pack\'s .zip.';

  @override
  String get packFileTooBig => 'That file is too big for a pack.';

  @override
  String packSource(String where, String commit) {
    return '$where at $commit';
  }

  @override
  String get packFromFile => 'From a file';

  @override
  String get packFromShare => 'Shared with you';

  @override
  String get packAlreadyHere => 'This workspace already has this pack.';

  @override
  String get packOpenInstalled => 'See installed packs';

  @override
  String get packAdd => 'Add pack';

  @override
  String packWizardTitle(String name) {
    return 'Add $name';
  }

  @override
  String get packWhatsInside => 'What\'s inside';

  @override
  String get packWhatsInsideHelp => 'Untick anything you don\'t want.';

  @override
  String get packSectionBots => 'Bots';

  @override
  String get packSectionSkills => 'Skills';

  @override
  String get packSectionRoutines => 'Routines';

  @override
  String get packSectionApps => 'Apps';

  @override
  String get packSectionLooks => 'Looks';

  @override
  String get packSectionIncludes => 'From the gallery';

  @override
  String get packSectionTools => 'Tools';

  @override
  String get packSkillRunsScripts => 'Runs scripts on the bot\'s computer';

  @override
  String get packSkillForWorkspace => 'For the whole workspace';

  @override
  String packRoutineRuns(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Runs about $count times a week',
      one: 'Runs about once a week',
      zero: 'Runs now and then',
    );
    return '$_temp0';
  }

  @override
  String packAppHost(String host) {
    return 'Talks to $host';
  }

  @override
  String packToolRemote(String url) {
    return 'Connects to $url';
  }

  @override
  String get packIncludeMissing => 'Not found in the gallery';

  @override
  String get packLookHelp => 'You can use it on this device after adding.';

  @override
  String get packNothingTicked => 'Tick at least one thing to add.';

  @override
  String get packQuestions => 'A few questions';

  @override
  String get packQuestionsHelp =>
      'The pack fills these into its bots and routines.';

  @override
  String get packSecretsTitle => 'Keys and settings';

  @override
  String get packSecretsHelp => 'The pack\'s tools need these to work.';

  @override
  String get packReachTitle => 'What it can reach';

  @override
  String get packReachHelp => 'Worked out by Casama from the pack\'s files.';

  @override
  String get packReachRunsCode => 'Runs code';

  @override
  String get packReachComputer => 'Uses the bot\'s computer';

  @override
  String packReachHosts(String hosts) {
    return 'Talks to $hosts';
  }

  @override
  String get packReachNoHosts => 'Doesn\'t talk to other sites';

  @override
  String packReachSecrets(String names) {
    return 'Uses keys: $names';
  }

  @override
  String packReachRuns(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'About $count scheduled runs a week',
      one: 'About 1 scheduled run a week',
      zero: 'No scheduled runs',
    );
    return '$_temp0';
  }

  @override
  String get packUnreviewedWarning =>
      'Casama hasn\'t reviewed this pack. Add it only if you trust where it comes from. Its routines start switched off.';

  @override
  String get packPickBotTitle => 'Which bot gets it?';

  @override
  String get packPickBotHelp =>
      'This pack brings no bot. Pick one for its routines and tools.';

  @override
  String packDoneTitle(String name) {
    return '$name is in';
  }

  @override
  String get packDoneHelp => 'Here\'s what it added.';

  @override
  String get packPendingHelp =>
      'We\'ve asked an admin. The pack is added once they approve.';

  @override
  String get packStatusInstalled => 'Added';

  @override
  String get packStatusPending => 'Waiting for an admin';

  @override
  String get packStatusSkipped => 'Skipped';

  @override
  String get packStatusFailed => 'Didn\'t work';

  @override
  String get packStatusDevice => 'On this device';

  @override
  String get packConnectTitle => 'Connect its apps';

  @override
  String get packConnectHelp => 'Its bots work fully once these are connected.';

  @override
  String get packLooksTitle => 'Use a look on this device?';

  @override
  String get packUseLook => 'Use';

  @override
  String get packLookInUse => 'In use';

  @override
  String get packInstalledTitle => 'That pack is already here';

  @override
  String get packsInstalledTitle => 'Installed packs';

  @override
  String get packsInstalledRow => 'Packs this workspace added, with updates';

  @override
  String get packsInstalledEmpty =>
      'No packs yet. Find one on the Packs shelf, or add one from a link.';

  @override
  String get packEditedBadge => 'Edited by you';

  @override
  String get packRemove => 'Remove';

  @override
  String get packUpToDate => 'This pack is up to date.';

  @override
  String get packCantCheck =>
      'This pack came from a file or link and can\'t check for updates.';

  @override
  String packUpdateTitle(String name) {
    return 'Update $name';
  }

  @override
  String packDiffAdded(String names) {
    return 'New: $names';
  }

  @override
  String packDiffRemoved(String names) {
    return 'Removed: $names';
  }

  @override
  String packDiffChanged(String name) {
    return 'Changed: $name';
  }

  @override
  String packDiffHosts(String hosts) {
    return 'New sites it talks to: $hosts';
  }

  @override
  String packDiffSecrets(String names) {
    return 'New keys it needs: $names';
  }

  @override
  String packDiffSchedules(String names) {
    return 'New schedules: $names';
  }

  @override
  String packDiffRuns(String from, String to) {
    return 'Scheduled runs a week: $from → $to';
  }

  @override
  String get packDiffNone => 'Nothing you\'d notice changed.';

  @override
  String get packEditedTitle => 'Things you changed';

  @override
  String get packEditedHelp => 'Your version stays unless you switch it.';

  @override
  String get packTakeTheirs => 'Use the pack\'s version';

  @override
  String get packReachGrewTitle => 'It reaches further';

  @override
  String get packReachGrewHelp =>
      'The new version can reach more than the one you have.';

  @override
  String get packReachConfirm => 'I\'ve checked what it can reach now';

  @override
  String packUpdated(String name) {
    return '$name is updated.';
  }

  @override
  String packRemoveTitle(String name) {
    return 'Remove $name?';
  }

  @override
  String get packRemoveBody =>
      'Its tools and keys go, and skills and routines you didn\'t change. App connections stay.';

  @override
  String get packRemoveBots => 'Also delete the bots this pack created';

  @override
  String packRemoved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pack removed. $count items stayed because you changed them.',
      one: 'Pack removed. 1 item stayed because you changed it.',
      zero: 'Pack removed.',
    );
    return '$_temp0';
  }

  @override
  String get sharePackTitle => 'Share as pack';

  @override
  String get sharePackRow => 'Bundle bots and skills for someone else';

  @override
  String get sharePackHelp =>
      'Keys, chats, memories, About you and the model choice are never included.';

  @override
  String get sharePackBots => 'Bots';

  @override
  String get sharePackBotsHelp =>
      'Pick up to 5. Each brings its instructions, skills and routines.';

  @override
  String get sharePackSkills => 'Workspace skills';

  @override
  String get sharePackName => 'Name';

  @override
  String get sharePackSummary => 'One line about it';

  @override
  String get sharePackLook => 'Include this device\'s look';

  @override
  String get sharePackCheck => 'Check and share';

  @override
  String get sharePackFindingsTitle => 'Some lines look like keys';

  @override
  String get sharePackFindingsHelp =>
      'Check these before you share. Go back to fix them, or share if they\'re safe.';

  @override
  String sharePackFinding(String path, int line, String what) {
    return '$path, line $line: $what';
  }

  @override
  String get sharePackGoBack => 'Go back';

  @override
  String get sharePackAnyway => 'Share anyway';

  @override
  String get sharePackLinkTitle => 'Your pack link';

  @override
  String sharePackLinkHelp(String date) {
    return 'Anyone signed in to Casama can open it until $date.';
  }

  @override
  String get sharePackShare => 'Share';

  @override
  String get sharePackSaveFile => 'Save as file';

  @override
  String get sharePackLinkCopied => 'Link copied.';

  @override
  String get sharePackStop => 'Stop sharing';

  @override
  String get sharePackStopped => 'The link no longer works.';

  @override
  String pluginFromPack(String pack) {
    return 'From the $pack pack';
  }

  @override
  String get pluginFromPackHelp =>
      'Update or remove it with its pack, in Gallery → Installed packs.';

  @override
  String get pluginSettings => 'Settings';

  @override
  String get pluginEditSettings => 'Edit settings';

  @override
  String get pluginSettingsSaved => 'Settings saved.';

  @override
  String get galleryPolicyKeyHelp =>
      'You can also type a repository (repo/owner:name) or a pack (pack/name).';

  @override
  String galleryPolicyUseKey(String key) {
    return 'Add $key';
  }

  @override
  String galleryApprovalPack(String name) {
    return 'Pack: $name';
  }

  @override
  String get reportPackShare => 'Report this pack';

  @override
  String get appLock => 'App lock';

  @override
  String get appLockRow => 'Ask to unlock Casama when it opens';

  @override
  String get appLockHelp =>
      'Casama asks you to unlock it when it opens and after time away. While it\'s on, your sign-in is kept in this device\'s keychain.';

  @override
  String get appLockSwitch => 'Lock Casama';

  @override
  String get appLockLocked => 'Casama Is Locked';

  @override
  String get appLockUnlock => 'Unlock';

  @override
  String get appLockUnlockWithPasskey => 'Unlock with a Passkey';

  @override
  String get appLockUnlockReason => 'Unlock Casama';

  @override
  String get appLockTurnOnReason => 'Turn on the app lock';

  @override
  String get appLockConfirmReason => 'Confirm it\'s you';

  @override
  String get appLockConfirmTitle => 'Confirm It\'s You';

  @override
  String appLockUnlockWith(String method) {
    return 'Use $method.';
  }

  @override
  String get appLockDeviceIos => 'Face ID, Touch ID or your passcode';

  @override
  String get appLockDeviceAndroid => 'your fingerprint, face or screen lock';

  @override
  String get appLockDeviceMac => 'Touch ID or your Mac\'s password';

  @override
  String get appLockDeviceWindows => 'Windows Hello';

  @override
  String get appLockDeviceOther => 'your device\'s screen lock';

  @override
  String appLockMethodDevice(String method) {
    return 'Unlocks with $method';
  }

  @override
  String get appLockMethodPin => 'Unlocks with a 6-digit PIN';

  @override
  String get appLockMethodPasskey => 'Unlocks with a passkey';

  @override
  String get appLockPinHint => 'Enter your PIN';

  @override
  String appLockPinWrong(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Wrong PIN. $count tries left.',
      one: 'Wrong PIN. 1 try left.',
      zero: 'Wrong PIN.',
    );
    return '$_temp0';
  }

  @override
  String get appLockPinStopped =>
      'Too many wrong PINs. Sign out, then sign in again to open Casama.';

  @override
  String get appLockFailed => 'That didn\'t work. Try again.';

  @override
  String get appLockUnavailable =>
      'This device can\'t unlock Casama right now. Sign out, then sign in again to get back in.';

  @override
  String get appLockSignOutConfirm =>
      'Signing out turns the app lock off on this device. Sign in again to open Casama.';

  @override
  String get appLockCallRinging => 'A call is ringing. Unlock to answer it.';

  @override
  String get appLockRequiredTitle => 'Turn On the App Lock';

  @override
  String appLockRequiredBody(String workspace) {
    return '$workspace requires the app lock on every device that opens Casama.';
  }

  @override
  String get appLockRequiredNoWay =>
      'This browser can\'t use passkeys with this server, so it can\'t lock Casama. Open Casama in the app on your phone or computer.';

  @override
  String appLockRequiredBy(String workspace) {
    return 'On. Required by $workspace';
  }

  @override
  String get appLockTurnOn => 'Turn On';

  @override
  String get appLockTurnedOn => 'App lock is on';

  @override
  String get appLockNoWayHere =>
      'This browser can\'t use passkeys with this server, so Casama can\'t be locked here.';

  @override
  String get appLockNotChecked => 'Couldn\'t confirm it\'s you.';

  @override
  String get appLockPinSetupTitle => 'Choose a PIN';

  @override
  String get appLockPinAgainTitle => 'Enter the PIN Again';

  @override
  String get appLockPinSetupBody =>
      '6 digits. You\'ll enter it to open Casama.';

  @override
  String get appLockPinNext => 'Continue';

  @override
  String get appLockPinMismatch => 'The PINs didn\'t match. Choose one again.';

  @override
  String get appLockPinNotSaved => 'Couldn\'t save the PIN on this device.';

  @override
  String get appLockPinChanged => 'PIN changed';

  @override
  String get appLockChangePin => 'Change PIN';

  @override
  String get appLockAfter => 'Lock after';

  @override
  String get appLockAfterHelp =>
      'Time in the background, minimised, or behind other apps on a computer.';

  @override
  String get appLockAfterImmediately => 'Right away';

  @override
  String get appLockAfterOneMinute => '1 minute';

  @override
  String get appLockAfterFiveMinutes => '5 minutes';

  @override
  String get appLockAfterFifteenMinutes => '15 minutes';

  @override
  String get appLockAfterOneHour => '1 hour';

  @override
  String get appLockBlockScreenshots => 'Block screenshots';

  @override
  String get appLockBlockScreenshotsHelp =>
      'Screenshots, screen recordings and screen sharing show nothing of Casama.';

  @override
  String get appLockLockNow => 'Lock now';

  @override
  String get appLockPrivacySection => 'More privacy';

  @override
  String get appLockAskBeforeRisky => 'Confirm risky actions';

  @override
  String get appLockAskBeforeRiskyHelp =>
      'Unlock again before deleting your account, making keys, changing billing, exporting data, approving high-risk requests and taking over a computer.';

  @override
  String get requireAppLock => 'Require the app lock';

  @override
  String get requireAppLockHelp =>
      'Members must lock Casama on every device before it opens. On the web that takes a passkey.';

  @override
  String get requireAppLockOwnFirst =>
      'Turn on the app lock on this device first.';

  @override
  String get permLocation => 'Location';

  @override
  String get permLocationAlways => 'Location in the background';

  @override
  String get permCamera => 'Camera';

  @override
  String get permMicrophone => 'Microphone';

  @override
  String get permSpeech => 'Speech recognition';

  @override
  String get permPhotos => 'Photos';

  @override
  String get permContacts => 'Contacts';

  @override
  String get permCalendar => 'Calendars';

  @override
  String get permHealth => 'Health';

  @override
  String get permNotifications => 'Notifications';

  @override
  String get permNotificationAccess => 'Notification access';

  @override
  String get permAccessibility => 'Accessibility';

  @override
  String get permScreenRecording => 'Screen Recording';

  @override
  String get permAutomation => 'Automation';

  @override
  String get permFullDisk => 'Full Disk Access';

  @override
  String get permSharedFolders => 'Shared folders';

  @override
  String get permLocalTools => 'Local tools';

  @override
  String get cardPermissions => 'Permissions';

  @override
  String permissionsTitle(String device) {
    return 'Turn these on for $device';
  }

  @override
  String get permStateOn => 'On';

  @override
  String get permStateOff => 'Off';

  @override
  String get permStateNotAsked => 'Not asked yet';

  @override
  String get permStateLimited => 'Limited';

  @override
  String get permStateUnknown => 'Unknown';

  @override
  String get permStateUnavailable => 'Not available on this device';

  @override
  String get permStateUpdate => 'Update Casama to turn this on here';

  @override
  String get permTurnOn => 'Turn on';

  @override
  String get permOpenSettings => 'Open settings';

  @override
  String get permOpenHealth => 'Open Health';

  @override
  String get permHealthIosHow =>
      'In Health, tap your picture, then Apps, then Casama, and turn on what your bots may read.';

  @override
  String get permChoose => 'Choose';

  @override
  String get permRestart => 'Restart Casama';

  @override
  String get permRestartToFinish => 'Restart Casama to finish';

  @override
  String permOpenedOn(String device) {
    return 'Opened on $device';
  }

  @override
  String permSentTo(String device) {
    return 'Sent to $device: tap the notification there';
  }

  @override
  String permOffline(String device) {
    return '$device is offline';
  }

  @override
  String permRestarting(String device) {
    return 'Restarting Casama on $device';
  }

  @override
  String permOnlyOwner(String device) {
    return 'Only $device\'s owner can turn these on';
  }

  @override
  String get permNotNowLine => 'Not now';

  @override
  String get permContinue => 'Continue';

  @override
  String get permContinueMessage => 'They\'re on, go ahead.';

  @override
  String get permContinuedLine => 'Turned on';

  @override
  String get permissionsScreenTitle => 'Permissions';

  @override
  String get permissionsScreenHelp =>
      'What bots can use on this device. Nothing is asked until you tap.';

  @override
  String get permissionsRowHelp =>
      'Location, screen, microphone and more on this device';

  @override
  String permOtherDevice(String device) {
    return 'This was for $device. Open Casama there to turn it on.';
  }

  @override
  String get permAnotherDevice => 'another device';

  @override
  String get permissionsNone => 'Nothing to turn on on this device.';

  @override
  String get widgetNeedsYou => 'Needs you';

  @override
  String get widgetAllClear => 'All clear';

  @override
  String get widgetAllow => 'Allow';

  @override
  String get widgetDeny => 'Deny';

  @override
  String get widgetReview => 'Review';

  @override
  String get widgetOpen => 'Open';

  @override
  String get widgetDoIt => 'Do it';

  @override
  String get widgetRunNow => 'Run now';

  @override
  String get widgetStarted => 'Started';

  @override
  String get widgetStop => 'Stop';

  @override
  String get widgetAsk => 'Ask';

  @override
  String widgetAskBot(String bot) {
    return 'Ask $bot';
  }

  @override
  String get widgetTalk => 'Talk';

  @override
  String get widgetTry => 'Try';

  @override
  String get widgetUpNext => 'Up next';

  @override
  String get widgetNoRoutines => 'No routines yet';

  @override
  String get widgetWorking => 'Working';

  @override
  String get widgetWaiting => 'Waiting for you';

  @override
  String get widgetIdle => 'Idle';

  @override
  String widgetRepliedAt(String time) {
    return 'Replied $time';
  }

  @override
  String get widgetBrief => 'Brief';

  @override
  String widgetBriefAt(String time) {
    return 'Brief at $time';
  }

  @override
  String get widgetNoBrief => 'No brief yet';

  @override
  String get widgetToday => 'Today';

  @override
  String get widgetCredits => 'Credits';

  @override
  String widgetCreditsLeft(String amount) {
    return '$amount left';
  }

  @override
  String widgetSpentToday(String amount) {
    return '$amount today';
  }

  @override
  String widgetUsedPct(String n) {
    return '$n% used';
  }

  @override
  String widgetResetsAt(String time) {
    return 'Resets $time';
  }

  @override
  String get widgetFinished => 'Finished';

  @override
  String get widgetLibrary => 'Library';

  @override
  String get widgetNoCreations => 'Nothing made yet';

  @override
  String get widgetTasks => 'Tasks';

  @override
  String get widgetTodo => 'To do';

  @override
  String get widgetInProgress => 'In progress';

  @override
  String get widgetInReview => 'In review';

  @override
  String get widgetBlocked => 'Blocked';

  @override
  String get widgetSignIn => 'Open Casama to sign in';

  @override
  String get widgetNoBots => 'Meet your first bot';

  @override
  String widgetAsOf(String time) {
    return 'as of $time';
  }

  @override
  String get widgetUpdateServer =>
      'Update your Casama server to use this widget';

  @override
  String widgetNeedsOkFrom(String bot) {
    return '$bot needs your OK';
  }

  @override
  String widgetSuggests(String bot) {
    return '$bot suggests';
  }

  @override
  String widgetTakeOver(String bot) {
    return '$bot needs you to take over';
  }

  @override
  String widgetNextBrief(String time) {
    return 'Next brief $time';
  }

  @override
  String get widgetNothingNext => 'Nothing scheduled';

  @override
  String get widgetsTitle => 'Widgets';

  @override
  String get widgetsRow => 'Your bots on the Home screen and Lock Screen';

  @override
  String get widgetsIntro =>
      'Widgets show what your bots are doing and what waits on you, without opening Casama.';

  @override
  String get widgetNameBot => 'Bot';

  @override
  String get widgetNameRoutines => 'Routines';

  @override
  String get widgetDescNeedsYou => 'See which bots are waiting on you';

  @override
  String get widgetDescBot => 'See what one bot is doing';

  @override
  String get widgetDescAsk => 'Ask or talk to a bot in one tap';

  @override
  String get widgetDescRoutines => 'See what runs next and run it now';

  @override
  String get widgetDescToday => 'See your whole day on one large widget';

  @override
  String get widgetDescBrief => 'Read your morning brief';

  @override
  String get widgetDescLibrary => 'See what your bots made lately';

  @override
  String get widgetDescTasks => 'See where the task board stands';

  @override
  String get widgetDescCredits => 'Keep an eye on your credits';

  @override
  String get widgetsAddToHome => 'Add to Home screen';

  @override
  String get widgetsPinUnsupported =>
      'Your launcher can\'t add widgets from here. Touch and hold an empty spot on your Home screen, tap Widgets, and pick Casama.';

  @override
  String get widgetsHowToAdd => 'How to add';

  @override
  String get widgetsHowToIos =>
      'Touch and hold an empty spot on your Home Screen, tap Edit, then Add Widget, and pick Casama.';

  @override
  String get widgetsHowToMac =>
      'Click the date and time in the menu bar, then Edit Widgets, and pick Casama. Or right-click the desktop and choose Edit Widgets.';

  @override
  String get widgetsLockScreen => 'Lock Screen and controls';

  @override
  String get widgetsLockScreenHelp =>
      'Touch and hold the Lock Screen, tap Customize, then Lock Screen, and tap the space under the clock to add Needs you, Up next, Bot or Credits. A request stays hidden until you unlock.';

  @override
  String get widgetsControlsHelp =>
      'Open Control Center, touch and hold, tap Add a Control, and pick Ask Casama, Talk to a bot or Run a routine. They also fit the Lock Screen corners and the Action button.';

  @override
  String get widgetsShowDetails => 'Show details in widgets';

  @override
  String get widgetsShowDetailsHelp =>
      'With the app lock on, widgets show only numbers and bot names, and their buttons open Casama. Turn this on to show requests, messages and routine names too.';

  @override
  String get widgetsShowDetailsNoLock =>
      'Only matters while the app lock is on. Without it, widgets show details.';

  @override
  String widgetsShowDetailsRequired(String workspace) {
    return '$workspace requires the app lock, so widgets keep details hidden.';
  }

  @override
  String get widgetsPinBot => 'Pin a bot to your Home screen';

  @override
  String get widgetsPinBotHelp =>
      'Puts the bot on your Home screen as its own icon. Tap it to chat.';

  @override
  String get widgetsPin => 'Pin';

  @override
  String get widgetNudgeNeedsYou =>
      'Answer requests from your Home screen with the Needs you widget.';

  @override
  String get widgetNudgeRoutines =>
      'Run routines from your Home screen with the Routines widget.';

  @override
  String get widgetNameCanvas => 'Canvas';

  @override
  String get widgetDescCanvas =>
      'Shows what your bots put there, like a daily verse or a countdown';

  @override
  String get canvasEmpty => 'Ask a bot to put something here';

  @override
  String get canvasTry => 'Try: put a daily verse on my Lock Screen';

  @override
  String get canvasAutomatic => 'Automatic';

  @override
  String canvasIn(String time) {
    return 'in $time';
  }

  @override
  String canvasSince(String time) {
    return '$time since';
  }

  @override
  String get canvasNow => 'Now';

  @override
  String canvasLeft(String n) {
    return '$n left';
  }

  @override
  String get canvasLeftUnit => 'left';

  @override
  String canvasDaysUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'days',
      one: 'day',
    );
    return '$_temp0';
  }

  @override
  String get canvasCardLabel => 'Widgets';

  @override
  String canvasPreviewAsk(String bot) {
    return '$bot wants to show this on your widgets';
  }

  @override
  String canvasPreviewAskHelp(String bot) {
    return 'Once you say yes, $bot can change it without asking. You can stop it any time in Settings, Widgets.';
  }

  @override
  String canvasPreviewSet(String bot) {
    return '$bot put this on your widgets';
  }

  @override
  String get canvasShow => 'Show on my widgets';

  @override
  String get canvasShowing => 'Showing on your widgets';

  @override
  String canvasNotShown(String bot) {
    return 'Not shown. $bot can ask again another day.';
  }

  @override
  String get canvasGone => 'No longer on your widgets';

  @override
  String get canvasNotPlaced => 'Add the Canvas widget to see it.';

  @override
  String get canvasHowToIos =>
      'Touch and hold the Home Screen or Lock Screen, tap Edit, then Add Widget, and pick Casama, then Canvas.';

  @override
  String get canvasHowToMac =>
      'Right-click the desktop, choose Edit Widgets, and pick Casama, then Canvas.';

  @override
  String get canvasHowToElsewhere =>
      'Add Casama\'s Canvas widget on your phone or Mac to see it there.';

  @override
  String get canvasAdded => 'Canvas widget added';

  @override
  String get canvasLockScreen => 'On the Lock Screen';

  @override
  String get widgetsFromBots => 'From your bots';

  @override
  String get widgetsFromBotsEmpty =>
      'Nothing yet. Ask a bot something like \"Put a daily verse on my Lock Screen\".';

  @override
  String canvasSetAt(String time) {
    return 'Set $time';
  }

  @override
  String canvasOnDevices(String devices) {
    return 'Showing on $devices';
  }

  @override
  String get canvasNoWidget => 'No Canvas widget placed yet';

  @override
  String get canvasPausedLine => 'Paused';

  @override
  String get canvasWaitingLine => 'Waiting for your yes';

  @override
  String get canvasHideLocked => 'Hide on a locked phone';

  @override
  String get canvasPause => 'Pause';

  @override
  String get canvasResume => 'Resume';

  @override
  String get canvasClear => 'Clear';

  @override
  String canvasClearTitle(String name) {
    return 'Clear $name?';
  }

  @override
  String canvasClearMessage(String bot) {
    return 'It comes off your widgets. $bot can put something there again.';
  }

  @override
  String get canvasAllowedBots => 'Bots on your widgets';

  @override
  String get canvasMayShow => 'May show things on your widgets';

  @override
  String canvasStopTitle(String bot) {
    return 'Stop $bot?';
  }

  @override
  String canvasStopMessage(String bot) {
    return 'What $bot shows on your widgets is cleared, and it has to ask again.';
  }

  @override
  String get canvasStop => 'Stop';

  @override
  String get canvasDeviceIos => 'iPhone';

  @override
  String get canvasDeviceAndroid => 'Android phone';

  @override
  String get canvasDeviceMac => 'Mac';

  @override
  String get widgetNudgeAction => 'Show me';

  @override
  String get widgetLowRisk => 'Low risk';

  @override
  String get widgetThisMonth => 'This month';

  @override
  String get watchNow => 'Now';

  @override
  String get watchAsk => 'Ask';

  @override
  String watchAskBot(String bot) {
    return 'Ask $bot';
  }

  @override
  String get watchBots => 'Bots';

  @override
  String get watchUpNext => 'Up next';

  @override
  String get watchBrief => 'Brief';

  @override
  String get watchSettings => 'Settings';

  @override
  String get watchChat => 'Chat';

  @override
  String get watchTalk => 'Talk';

  @override
  String get watchCredits => 'Credits';

  @override
  String get watchNeedsYou => 'Needs you';

  @override
  String get watchNeedsYouOne => '1 needs you';

  @override
  String watchNeedsYouMany(String count) {
    return '$count need you';
  }

  @override
  String get watchNeedsOk => 'Needs your OK';

  @override
  String watchNeedsOkFrom(String bot) {
    return '$bot needs your OK';
  }

  @override
  String watchSuggests(String bot) {
    return '$bot suggests';
  }

  @override
  String get watchTakeOver => 'Wants you to take over';

  @override
  String get watchAllClear => 'All clear';

  @override
  String get watchNothingWaiting => 'Nothing needs you';

  @override
  String get watchAllow => 'Allow';

  @override
  String get watchDeny => 'Deny';

  @override
  String get watchHoldToAllow => 'Hold to allow';

  @override
  String get watchHoldHint => 'Allow this? Double tap to allow.';

  @override
  String get watchReview => 'Review';

  @override
  String get watchReviewOnIphone => 'Review on iPhone';

  @override
  String get watchReviewOnPhone => 'Review on phone';

  @override
  String get watchWhyHighRisk => 'High risk: answer on your phone';

  @override
  String get watchWhyPayment => 'Payments are answered on your phone';

  @override
  String get watchWhySetting => 'Your settings keep this on your phone';

  @override
  String get watchWhyWorkspace => 'Your workspace keeps this on your phone';

  @override
  String get watchWhyNotYours =>
      'Only the person who started this chat can allow it';

  @override
  String get watchHighRisk => 'High risk';

  @override
  String get watchMediumRisk => 'Medium risk';

  @override
  String get watchLowRisk => 'Low risk';

  @override
  String get watchAllowed => 'Allowed';

  @override
  String get watchDenied => 'Denied';

  @override
  String get watchDone => 'Done';

  @override
  String get watchAlreadyAnswered => 'Already answered';

  @override
  String get watchLockToAllow =>
      'Set a passcode on this watch to allow from it';

  @override
  String get watchDoIt => 'Do It';

  @override
  String get watchNotNow => 'Not now';

  @override
  String get watchOpenOnIphone => 'Open on iPhone';

  @override
  String get watchOpenOnPhone => 'Open on phone';

  @override
  String get watchSentToPhone => 'Sent to your phone';

  @override
  String get watchWorking => 'Working';

  @override
  String watchIsWorking(String bot) {
    return '$bot is working';
  }

  @override
  String get watchWaitingForYou => 'Waiting for you';

  @override
  String watchRepliedAt(String time) {
    return 'Replied $time';
  }

  @override
  String get watchIdle => 'Idle';

  @override
  String get watchOff => 'Off';

  @override
  String watchStepCount(String count) {
    return 'Step $count';
  }

  @override
  String get watchStop => 'Stop';

  @override
  String get watchStopped => 'Stopped';

  @override
  String get watchFinished => 'Finished';

  @override
  String get watchProblem => 'Stopped with a problem';

  @override
  String get watchCouldntFinish => 'Couldn\'t finish';

  @override
  String get watchListening => 'Listening…';

  @override
  String get watchTapToStop => 'Tap to stop';

  @override
  String get watchTypeInstead => 'Type instead';

  @override
  String get watchSending => 'Sending…';

  @override
  String get watchHeard => 'Heard';

  @override
  String get watchUndo => 'Undo';

  @override
  String get watchKeptOffline => 'Saved. It sends when you\'re back online';

  @override
  String watchKeptOld(String time) {
    return 'Send what you asked at $time?';
  }

  @override
  String get watchSend => 'Send';

  @override
  String get watchDiscard => 'Discard';

  @override
  String get watchMicDenied =>
      'Allow the microphone in Settings to ask by voice';

  @override
  String get watchNoDictation =>
      'This server has no voice service. Use Type instead';

  @override
  String get watchDidntCatch => 'Didn\'t catch that. Try again';

  @override
  String get watchReply => 'Reply';

  @override
  String get watchReadAloud => 'Read aloud';

  @override
  String get watchStopReading => 'Stop reading';

  @override
  String get watchContinuesOnIphone => 'Continues on iPhone';

  @override
  String get watchContinuesOnPhone => 'Continues on phone';

  @override
  String get watchReplyReady => 'Reply ready';

  @override
  String get watchYou => 'You';

  @override
  String get watchQuickYes => 'Yes';

  @override
  String get watchQuickNo => 'No';

  @override
  String get watchQuickTellMore => 'Tell me more';

  @override
  String get watchQuickNotNow => 'Not now';

  @override
  String get watchRunNow => 'Run Now';

  @override
  String get watchStarted => 'Started';

  @override
  String watchInMinutes(String minutes) {
    return 'in $minutes min';
  }

  @override
  String get watchNoRoutines => 'No routines yet';

  @override
  String watchBriefAt(String time) {
    return 'Brief at $time';
  }

  @override
  String watchBriefTomorrow(String time) {
    return 'Brief at $time tomorrow';
  }

  @override
  String get watchNoBrief => 'No brief set up';

  @override
  String get watchNoBots => 'No bots yet. Make one on your phone';

  @override
  String get watchSigningIn => 'Signing you in';

  @override
  String watchSignedInAs(String name) {
    return 'Signed in as $name';
  }

  @override
  String get watchOpenPhoneToFinishIphone =>
      'Open Casama on your iPhone to finish';

  @override
  String get watchOpenPhoneToFinish => 'Open Casama on your phone to finish';

  @override
  String get watchUseCode => 'Sign in with a code';

  @override
  String get watchCodeHelp =>
      'Type it in Casama on your phone or computer: Settings → Watch';

  @override
  String get watchNewCode => 'New code';

  @override
  String get watchSignedOut => 'This watch is signed out';

  @override
  String get watchOpenToSignIn => 'Open Casama to sign in';

  @override
  String watchAsOf(String time) {
    return 'as of $time';
  }

  @override
  String get watchOffline => 'Offline';

  @override
  String get watchCouldntReach => 'Couldn\'t reach Casama';

  @override
  String get watchTryAgain => 'Try again';

  @override
  String get watchServerTooOld => 'Update your Casama server to use the watch';

  @override
  String get watchOutOfCredits => 'Out of credits';

  @override
  String get watchTalkOnPhone => 'Starting the call on your phone';

  @override
  String get watchSignOut => 'Sign out of this watch';

  @override
  String get watchHideDetails => 'Hide details when my wrist is down';

  @override
  String get watchReadRepliesAloud => 'Read replies aloud';

  @override
  String get watchAskUses => 'Ask uses';

  @override
  String get watchWorkspace => 'Workspace';

  @override
  String get watchSignedInAsLabel => 'Signed in as';

  @override
  String get watchCompNeedsYou => 'Needs you';

  @override
  String get watchCompAsk => 'Ask a bot';

  @override
  String get watchCompBot => 'Bot';

  @override
  String get watchCompUpNext => 'Up next';

  @override
  String get watchCompCasama => 'Casama';

  @override
  String get watchCompDescNeedsYou =>
      'How many requests wait, and the first one';

  @override
  String get watchCompDescAsk => 'Ask a bot by voice in one tap';

  @override
  String get watchCompDescBot => 'Where a bot stands and what it is doing';

  @override
  String get watchCompDescUpNext => 'The next routine and when it runs';

  @override
  String get watchCompDescCredits => 'Credits used this period';

  @override
  String get watchNeedYouShort => 'need you';

  @override
  String get watchControlAsk => 'Ask Casama';

  @override
  String get watchControlTalk => 'Talk to a bot';

  @override
  String get watchControlRun => 'Run a routine';

  @override
  String watchSiriNeeds(String count, String text) {
    return '$count need you. First: $text';
  }

  @override
  String get watchPhoneTitle => 'Watch';

  @override
  String get watchPhoneIntro =>
      'Answer bots, ask by voice and see who is working, from your wrist.';

  @override
  String get watchPhoneWatches => 'Signed-in watches';

  @override
  String get watchPhoneNone =>
      'No watch signed in yet. Open Casama on your watch and it signs in by itself.';

  @override
  String watchPhoneLastUsed(String time) {
    return 'Last used $time';
  }

  @override
  String get watchPhoneNeverUsed => 'Not used yet';

  @override
  String get watchPhoneRemove => 'Remove';

  @override
  String watchPhoneRemoveTitle(String name) {
    return 'Remove $name?';
  }

  @override
  String get watchPhoneRemoveBody =>
      'It signs out at once. You can sign it in again later.';

  @override
  String get watchPhoneUseCode => 'Sign in a watch with a code';

  @override
  String get watchPhoneCodeHint => 'The code on your watch';

  @override
  String watchPhoneCodeAsk(String name) {
    return 'Sign in $name?';
  }

  @override
  String watchPhoneCodeAskBody(String workspace) {
    return 'It will be signed in to $workspace as you. Only allow a code shown on your own watch.';
  }

  @override
  String get watchPhoneCodeAllow => 'Sign it in';

  @override
  String get watchPhoneCodeWrong =>
      'That code didn\'t work. Check it on your watch';

  @override
  String get watchPhoneCodeTaken =>
      'This watch is still signed in to another account. Remove it there in Settings → Watch, then get a new code';

  @override
  String watchPhoneElsewhere(String workspace) {
    return 'Signed in to $workspace';
  }

  @override
  String get watchPhoneElsewhereUnknown => 'Signed in to another workspace';

  @override
  String watchPhoneSignedIn(String name) {
    return '$name is signed in';
  }

  @override
  String get watchPhoneAllowTitle => 'Allow from the watch';

  @override
  String get watchPhoneAllowMedium => 'Low and medium risk';

  @override
  String get watchPhoneAllowMediumBody =>
      'Low risk in one tap, medium risk with a hold. High risk and payments always need your phone.';

  @override
  String get watchPhoneAllowLow => 'Low risk only';

  @override
  String get watchPhoneAllowNone => 'Never';

  @override
  String get watchPhoneDetails => 'Show details on the watch';

  @override
  String get watchPhoneDetailsBody =>
      'Off: the watch shows counts and bot names, not what bots wrote.';

  @override
  String get watchPhoneQuickReplies => 'Quick replies';

  @override
  String get watchPhoneQuickRepliesBody =>
      'Short answers you can send from a reply notification. Up to six.';

  @override
  String get watchPhoneQuickAdd => 'Add a quick reply';

  @override
  String get watchPhoneQuickReset => 'Use the built-in replies';

  @override
  String get watchPhoneHowTo => 'Add Casama to your watch face';

  @override
  String get watchPhoneHowToApple =>
      'Touch and hold your watch face, tap Edit, then choose Casama for a complication. Turn the Digital Crown on the face to find Casama in the Smart Stack.';

  @override
  String get watchPhoneHowToWear =>
      'Touch and hold your watch face to add a Casama complication. Swipe left from the face and tap + to add a Casama tile.';

  @override
  String watchPhoneSigningInBanner(String name) {
    return 'Signing in $name…';
  }

  @override
  String get watchPhoneLockAsk => 'Sign in your watch?';

  @override
  String get watchPhoneNudge =>
      'Casama is on your watch too. Answer bots from your wrist.';

  @override
  String get watchPhoneHandoffTitle => 'From your watch';

  @override
  String get watchPhoneRow => 'Your bots on your Apple Watch or Wear OS watch';

  @override
  String get watchPhoneAllowLowBody =>
      'Low risk in one tap. Everything else needs your phone.';

  @override
  String get watchPhoneAllowNoneBody =>
      'The watch can only deny. Allow on your phone.';

  @override
  String get watchPhoneDetailsLockOff =>
      'Turned off because the app lock is on, so your watch shows no words from your chats. Turn it on to see them.';

  @override
  String get watchPhoneQuickHint => 'A short reply';

  @override
  String get watchPhoneQuickTooLong => 'Up to 40 characters';

  @override
  String get watchPhoneQuickMoveUp => 'Move up';

  @override
  String get watchPhoneQuickMoveDown => 'Move down';

  @override
  String get watchPhoneQuickDelete => 'Delete this reply';

  @override
  String get watchPhoneCodeBody =>
      'On your watch, open Casama and choose Sign in with a code.';

  @override
  String get watchPhoneAppleWatch => 'Apple Watch';

  @override
  String get watchPhoneWearOs => 'Wear OS';

  @override
  String get watchCompDescWorking => 'Who is working and what they are doing';

  @override
  String get watchCompDescBrief => 'This morning\'s brief';

  @override
  String get watchCodeWaiting => 'Waiting for the code…';

  @override
  String watchCodeA11y(String code) {
    return 'Sign-in code $code';
  }

  @override
  String get watchChooseBot => 'Choose a bot';

  @override
  String get watchChannelRequests => 'Requests';

  @override
  String get watchChannelReplies => 'Replies';

  @override
  String get watchChannelRuns => 'Working bots';

  @override
  String get watchChannelOther => 'Other';

  @override
  String get watchOtherWorkspace =>
      'This is in another workspace. Answer it on your phone';

  @override
  String get watchReplySent => 'Sent';

  @override
  String get watchReplyNotSent => 'Couldn\'t send your reply';

  @override
  String watchAskDropped(String time) {
    return 'Couldn\'t send what you asked at $time';
  }

  @override
  String get watchNeedsHttps =>
      'This watch can only reach your server over https or on your home network';

  @override
  String get watchSignIn => 'Sign in';

  @override
  String get watchNotOnWatch =>
      'This watch can\'t answer this one. Open it on your phone';

  @override
  String watchMoreOnPhone(String count) {
    return '$count more on your phone';
  }

  @override
  String get showList => 'Show the list';

  @override
  String get hideList => 'Hide the list';

  @override
  String get panePickLibrary =>
      'Pick something from the Library to see it here.';

  @override
  String get panePickSetting => 'Pick a setting to see it here.';

  @override
  String get trackpad => 'Trackpad';

  @override
  String get trackpadHint =>
      'One finger moves the pointer, two scroll, a tap clicks.';

  @override
  String get trackpadTakeControl => 'Take control to use the trackpad.';

  @override
  String get foldScreenTitle => 'Folding screen';

  @override
  String get foldRowHelp => 'What Casama sees of this device\'s screens';

  @override
  String get foldScreenHelp =>
      'How this device is held and where its fold is, as Casama sees it now. Open, close or fold the device and the numbers follow. Copy them if a screen looks wrong.';

  @override
  String get foldPose => 'Pose';

  @override
  String get foldWindow => 'Window';

  @override
  String get foldInsets => 'Safe area';

  @override
  String get foldStrip => 'Side strip';

  @override
  String get foldFold => 'Fold';

  @override
  String get foldHinge => 'Hinge';

  @override
  String get foldSystemSays => 'What the system reports';

  @override
  String get inviteGateLine => 'Casama Cloud is invite-only for now.';

  @override
  String get inviteGateSelfHost =>
      'Running Casama on your own server is open to everyone.';

  @override
  String get joinTheWaitlist => 'Join the Waitlist';

  @override
  String get iHaveAnInvite => 'I Have an Invite';

  @override
  String get waitlistSubtitle =>
      'We\'re letting people in every day. You\'ll get one email when it\'s your turn.';

  @override
  String get waitlistNote => 'What would you have a bot do first?';

  @override
  String get waitlistNoteHint => 'Optional';

  @override
  String get waitlistSelfHosting => 'I run Casama on my own server';

  @override
  String get waitlistNewsletter =>
      'Also send me Casama\'s monthly email (once a month at most)';

  @override
  String get waitlistAppleRelay =>
      'This is the private address Apple made for you. Keep it if you\'ll sign in with Apple; Apple forwards our email to your inbox.';

  @override
  String get waitlistJoinedTitle => 'You\'re on the list.';

  @override
  String get waitlistJoinedBody =>
      'We\'re letting people in every day. You\'ll get one email when it\'s your turn, and nothing else unless you asked for the monthly email.';

  @override
  String get waitlistJoinedCode => 'Have an invite code? Enter it here.';

  @override
  String get waitlistJoinedSelfHost =>
      'Don\'t want to wait? Casama is open source. Run it on your own computer today.';

  @override
  String get waitlistRunItYourself => 'Run It Yourself';

  @override
  String get inviteSubtitle =>
      'Enter your invite code, or paste the invite link.';

  @override
  String get inviteCodeLabel => 'Invite code';

  @override
  String get inviteNotFound =>
      'That code doesn\'t match any invite. Check it and try again.';

  @override
  String inviteFromName(String name) {
    return '$name invited you to Casama';
  }

  @override
  String get inviteFromFriend => 'A friend invited you to Casama';

  @override
  String inviteFromCampaign(String label) {
    return 'Your invite: $label';
  }

  @override
  String get inviteFromCasama => 'Your invite to Casama';

  @override
  String get inviteChooseSignIn =>
      'Now choose how you\'ll sign in. Use the address you want for your account.';

  @override
  String get inviteGoneHelp =>
      'These invites are gone. Enter your email and you\'ll go on the waitlist, ahead of the line.';

  @override
  String get inviteEmailHelp =>
      'We\'ll let this address in, then send it a sign-in link.';

  @override
  String inviteCheckInbox(String email) {
    return 'You\'re in. Check $email for a sign-in link, or type its code here.';
  }

  @override
  String get inviteWaitlistedTitle => 'You\'re on the waitlist';

  @override
  String get inviteWaitlisted =>
      'These invites are gone, but you\'re ahead of the line.';

  @override
  String get inviteUseEmailHere =>
      'On this device, use Continue with Email. Apple and Google work with an invite in the iPhone, Mac and Android apps.';

  @override
  String get inviteDifferentCode => 'Use a Different Code';

  @override
  String get inviteRefusedHelp =>
      'Join the waitlist and we\'ll email you when it\'s your turn, or enter an invite code if you have one.';

  @override
  String inviteFriendsInvitesLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count invites left',
      one: '1 invite left',
      zero: 'No invites left',
    );
    return '$_temp0';
  }

  @override
  String inviteFriendsInvitesUsed(int used, int total) {
    return '$used of $total used. Each one lets a friend make an account.';
  }

  @override
  String get inviteFriendsInvitesLocked =>
      'Your invites unlock after your first finished chat.';

  @override
  String get adminWaitlist => 'Waitlist';

  @override
  String get adminWaitlistWaiting => 'Waiting';

  @override
  String get adminWaitlistListedToday => 'Joined the list today';

  @override
  String get adminWaitlistAdmittedToday => 'Let in today';

  @override
  String get adminWaitlistAdmittedTotal => 'Let in, total';

  @override
  String get adminWaitlistJoined => 'Signed up';

  @override
  String get adminWaitlistFirstChat => 'First chat';

  @override
  String get adminWaitlistEmailsToday => '\"You\'re in\" emails today';

  @override
  String adminWaitlistEmailsOf(int sent, int max) {
    return '$sent of $max';
  }

  @override
  String get adminWaitlistLastBatch => 'Last batch';

  @override
  String adminWaitlistLastBatchValue(int count) {
    return '$count let in';
  }

  @override
  String adminWaitlistLastBatchSkipped(String reason) {
    return 'Skipped. $reason';
  }

  @override
  String get adminWaitlistBySource => 'By source';

  @override
  String adminWaitlistSourceRow(
    int listed,
    int admitted,
    int joined,
    int firstChat,
  ) {
    return '$listed on the list · $admitted let in · $joined signed up · $firstChat first chat';
  }

  @override
  String get adminWaitlistAdmit => 'Admit';

  @override
  String get adminWaitlistAdmitPrompt => 'Let in the next people in line';

  @override
  String get adminWaitlistAdmitCount => 'How many';

  @override
  String adminWaitlistAdmitTitle(int count) {
    return 'Let in the next $count in line?';
  }

  @override
  String get adminWaitlistAdmitBody =>
      'Each gets a \"You\'re in\" email, within today\'s email limit.';

  @override
  String adminWaitlistAdmitted(int count) {
    return '$count let in.';
  }

  @override
  String get adminWaitlistAdd => 'Add Addresses';

  @override
  String get adminWaitlistAddHelp =>
      'They\'re let in at once. One per line, or separated by commas.';

  @override
  String get adminWaitlistAddLabel => 'Email addresses';

  @override
  String get adminWaitlistAddNotify => 'Send each the \"You\'re in\" email';

  @override
  String adminWaitlistAdded(int count) {
    return '$count added.';
  }

  @override
  String adminWaitlistSkipped(String list) {
    return 'Not email addresses: $list';
  }

  @override
  String adminWaitlistRemoveTitle(String email) {
    return 'Remove $email from the waitlist?';
  }

  @override
  String get adminWaitlistRemoveBody =>
      'The entry is deleted. They can join again later.';

  @override
  String get adminWaitlistPeople => 'People';

  @override
  String get adminWaitlistSearch => 'Search by email';

  @override
  String get adminWaitlistNone => 'No one here yet.';

  @override
  String get adminWaitlistShowMore => 'Show More';

  @override
  String get adminWaitlistStatusWaiting => 'Waiting';

  @override
  String get adminWaitlistStatusQueued => 'Chosen';

  @override
  String get adminWaitlistStatusAdmitted => 'Let in';

  @override
  String get adminWaitlistStatusJoined => 'Signed up';

  @override
  String get adminWaitlistSelfHosts => 'Runs their own server';

  @override
  String get adminCampaigns => 'Campaign codes';

  @override
  String get adminCampaignNew => 'New Code';

  @override
  String get adminCampaignCode => 'Code';

  @override
  String get adminCampaignCodeHelp =>
      '9 or more characters, or with a hyphen: letters, digits and hyphens (SHOWHN-DEC8).';

  @override
  String get adminCampaignLabel => 'Label';

  @override
  String get adminCampaignTotal => 'Total uses';

  @override
  String get adminCampaignPerDay => 'A day at most (optional)';

  @override
  String get adminCampaignStarts => 'Starts';

  @override
  String get adminCampaignEnds => 'Ends';

  @override
  String get adminCampaignAnyTime => 'Any time';

  @override
  String get adminCampaignCreate => 'Create Code';

  @override
  String adminCampaignUsed(int used, int total) {
    return '$used of $total used';
  }

  @override
  String adminCampaignPerDayShort(int count) {
    return '$count a day';
  }

  @override
  String adminCampaignEndsOn(String date) {
    return 'ends $date';
  }

  @override
  String adminCampaignStartsOn(String date) {
    return 'starts $date';
  }

  @override
  String get adminCampaignOff => 'Off';

  @override
  String get adminCampaignTurnOff => 'Turn Off';

  @override
  String get adminCampaignTurnOn => 'Turn On';

  @override
  String get adminCampaignNone => 'No campaign codes yet.';

  @override
  String get adminCampaignCopied => 'Link copied.';

  @override
  String get adminGate => 'Sign-ups';

  @override
  String get adminGateInviteOnly => 'Invite-only';

  @override
  String get adminGateInviteOnlyHelp =>
      'New accounts only for people let in from the waitlist or with an invite code. Existing accounts sign in as always.';

  @override
  String get adminGateOpenTitle => 'Open sign-ups to everyone?';

  @override
  String get adminGateOpenBody =>
      'Anyone can make an account straight away. The waitlist stays as it is.';

  @override
  String get adminGateOpenConfirm => 'Open Sign-Ups';

  @override
  String get adminGateCloseTitle => 'Make Casama Cloud invite-only?';

  @override
  String get adminGateCloseBody =>
      'New people need an invite code, or a place let in from the waitlist. Existing accounts keep signing in.';

  @override
  String get adminGateCloseConfirm => 'Make Invite-Only';

  @override
  String get adminGateClosedNow => 'Invite-only now';

  @override
  String get adminGateOpenNow => 'Open now';

  @override
  String get adminGateOpensAt => 'Opens on its own';

  @override
  String get adminGateOpensAtNone => 'Not set';

  @override
  String get adminGateClearOpensAt => 'Clear the Opening Time';

  @override
  String get adminGateInvites => 'Invites per person';

  @override
  String get adminGateDailyAdmit => 'Let in each day';

  @override
  String get adminGateDailyAdmitOff => 'None (by hand only)';

  @override
  String get adminGateDailyEmails => '\"You\'re in\" emails a day at most';

  @override
  String get adminGateBatchHour => 'Batch time (UTC)';

  @override
  String adminGateBatchHourValue(String hour) {
    return '$hour:00 UTC';
  }

  @override
  String get adminGateNumberInvalid => 'Enter a whole number';

  @override
  String savedResetAvailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count resets saved',
      one: '1 reset saved',
    );
    return '$_temp0';
  }

  @override
  String savedResetExpiry(String date) {
    return 'Use by $date';
  }

  @override
  String get savedResetUse => 'Use Reset';

  @override
  String get savedResetConfirmTitle => 'Use this reset?';

  @override
  String get savedResetConfirmDaily =>
      'Clears today’s limit so your bots can work again today. This can’t be undone.';

  @override
  String get savedResetConfirmComputer =>
      'Gives back this month’s computer hours. This can’t be undone.';

  @override
  String get savedResetOwnerRequired => 'Only a workspace owner can use it.';

  @override
  String get savedResetPaused => 'Paused for now. Check back later.';

  @override
  String get savedResetPeriodLimit =>
      'You’ve used this period’s reset. You can use this one next period.';

  @override
  String get savedResetNothingToRefill =>
      'Nothing to refill yet. Keep it for when you run low.';

  @override
  String get savedResetNoBillingPeriod =>
      'Available once your plan finishes setting up.';

  @override
  String get savedResetUnavailable => 'Not available right now.';

  @override
  String savedResetDone(String amount) {
    return 'Reset used: $amount added';
  }

  @override
  String get savedResetDoneNoCredits => 'Reset used';

  @override
  String savedResetConfirm(String amount) {
    return 'Refills \$$amount of this period’s included credits. This can’t be undone.';
  }

  @override
  String get adminResets => 'Resets';

  @override
  String get resetsEnabled => 'Enable saved resets';

  @override
  String get resetsPerPeriod => 'Uses per workspace per period';

  @override
  String get resetsMaxHeld => 'Maximum saved resets';

  @override
  String get resetsNotifyOwners => 'Notify instance owners';

  @override
  String get resetsNewCampaign => 'Reset campaign';

  @override
  String get resetsName => 'Name';

  @override
  String get resetsMessage => 'Message to people';

  @override
  String get resetsPlans => 'Plan codes, separated by commas (empty means all)';

  @override
  String get resetsWorkspaces =>
      'Workspace IDs, separated by commas (empty means all)';

  @override
  String get resetsBefore => 'Created before (date and time, optional)';

  @override
  String get resetsLimitedDays => 'Hit a limit in the last N days (optional)';

  @override
  String get resetsStart => 'Starts (date and time)';

  @override
  String get resetsExpiry => 'Expires (date and time)';

  @override
  String get resetsPercent => 'Included credits to refill (%)';

  @override
  String get resetsCap => 'Maximum dollars per use (optional)';

  @override
  String get resetsBudget => 'Total credit budget in dollars (optional)';

  @override
  String get resetsDaily => 'Clear today’s model limit';

  @override
  String get resetsComputer => 'Refill this month’s computer hours';

  @override
  String get resetsArrival => 'Notify on arrival';

  @override
  String get resetsReminder => 'Remind before expiry';

  @override
  String get resetsPreviewSave => 'Preview and save';

  @override
  String get resetsSchedule => 'Schedule';

  @override
  String get resetsPause => 'Pause';

  @override
  String get resetsResume => 'Resume';

  @override
  String resetsCampaignCounts(int given, int used, String credits) {
    return '$given given · $used used · \$$credits refilled';
  }

  @override
  String resetsPreview(int count, String credits, String cost) {
    return '$count workspaces. Maximum refill: \$$credits. Estimated cost: \$$cost.';
  }

  @override
  String get resetsWorkspace => 'Workspace ID (empty for all history)';

  @override
  String get resetsHistory => 'Load history';

  @override
  String get resetsGive => 'Give a reset';

  @override
  String get resetsCopyCsv => 'Copy CSV';

  @override
  String get resetsRevoke => 'Take back';

  @override
  String get resetsUndo => 'Undo unused refill';

  @override
  String get adminVendors => 'Vendors';

  @override
  String get vendorNeedsAttention => 'Vendor services need attention';

  @override
  String get vendorNotSetUp => 'Not set up';

  @override
  String get vendorCheckNow => 'Check now';

  @override
  String get vendorLimit => 'Limit or prepaid amount';

  @override
  String get vendorWarnAt => 'Warning threshold (0–1)';

  @override
  String get vendorExpiry => 'Expiry (ISO date and time)';

  @override
  String get vendorHistory => 'Recent readings';

  @override
  String get vendorSave => 'Save';

  @override
  String get vendorEnabled => 'Monitoring enabled';

  @override
  String get vendorUnknown => 'Unknown';

  @override
  String get vendorLow => 'Low';

  @override
  String get vendorOut => 'Out';

  @override
  String get vendorOk => 'OK';

  @override
  String get vendorNoReading => 'No reading yet';

  @override
  String get vendorCheckFailed => 'Check failed';

  @override
  String get vendorResets => 'Resets';

  @override
  String get vendorSource => 'Source';

  @override
  String get vendorBilling => 'Billing and refill';

  @override
  String get vendorBalanceWarning => 'Warn below balance';

  @override
  String get vendorPeriodStart => 'Period start (ISO date and time)';

  @override
  String get vendorInvalidSettings =>
      'Enter a positive limit, a warning between 0 and 1, and valid dates.';

  @override
  String get cropTitle => 'Move and Scale';

  @override
  String get cropDone => 'Done';

  @override
  String get cropPosition => 'Picture position';

  @override
  String get cropMoveUp => 'Move up';

  @override
  String get cropMoveDown => 'Move down';

  @override
  String get cropMoveLeft => 'Move left';

  @override
  String get cropMoveRight => 'Move right';

  @override
  String get cropRotate => 'Rotate';

  @override
  String get cropMirror => 'Mirror';

  @override
  String get cropReset => 'Reset';

  @override
  String get cropZoom => 'Zoom';

  @override
  String get cropZoomIn => 'Zoom in';

  @override
  String get cropZoomOut => 'Zoom out';

  @override
  String get cropSoft => 'Zoomed in close: the picture may look soft';

  @override
  String get cropAnimatedStill => 'Animated pictures stay still';

  @override
  String get cropBackground => 'Background';

  @override
  String get cropBackgroundNone => 'None';

  @override
  String cropBackgroundBot(String name) {
    return '$name\'s color';
  }

  @override
  String get cropBackgroundWhite => 'White';

  @override
  String get cropBackgroundBlack => 'Black';

  @override
  String get cropUnreadable =>
      'This picture can\'t be opened here. Try a JPEG or PNG.';

  @override
  String cropTooBig(String size) {
    return 'This file is $size, over the 40 MB limit.';
  }

  @override
  String get botPicture => 'Picture';

  @override
  String botPictureTitle(String name) {
    return '$name\'s Picture';
  }

  @override
  String botPictureChange(String name) {
    return 'Change $name\'s picture';
  }

  @override
  String get botPicturePaste => 'Paste Picture';

  @override
  String get botPictureDraw => 'Make One with AI';

  @override
  String get botPictureDrawHelp => 'Casama draws two to choose from';

  @override
  String get botPictureRecrop => 'Re-crop';

  @override
  String get botPictureMascot => 'Use a Mascot Instead';

  @override
  String get botPictureRemove => 'Remove Picture';

  @override
  String get botPictureRecent => 'Recent';

  @override
  String get botPictureUpdated => 'Picture updated';

  @override
  String get botPictureRemoved => 'Picture removed';

  @override
  String get botPictureFailed => 'Couldn\'t save the picture';

  @override
  String botPictureDrop(String name) {
    return 'Drop to use as $name\'s picture';
  }

  @override
  String botPictureUseAs(String name) {
    return 'Use as $name\'s Picture';
  }

  @override
  String get botPictureUseAsBot => 'Use as a Bot\'s Picture';

  @override
  String get botPictureWhichBot => 'Which bot gets this picture?';

  @override
  String botDrawTitle(String name) {
    return 'A Picture for $name';
  }

  @override
  String get botDrawIntro =>
      'Pick a look, add a few words if you like, and Casama draws two pictures to choose from.';

  @override
  String get botDrawDescribe => 'Describe it (optional)';

  @override
  String get botDrawHint => 'A friendly owl with reading glasses';

  @override
  String get botDrawMake => 'Make 2';

  @override
  String get botDrawMore => 'Make 2 More';

  @override
  String get botDrawPick => 'Tap one to use it';

  @override
  String get botDrawCost =>
      'Each picture uses image credits, like any picture Casama makes.';

  @override
  String get botDrawWorking => 'Drawing…';

  @override
  String get botDrawStyleCloud => 'Casama Cloud';

  @override
  String get botDrawStyleSoft3d => 'Soft 3D';

  @override
  String get botDrawStyleWatercolor => 'Watercolor';

  @override
  String get botDrawStyleFlat => 'Flat Icon';

  @override
  String get botDrawStylePixel => 'Pixel Art';

  @override
  String get botDrawStyleLine => 'Line Art';

  @override
  String get botDrawStylePhoto => 'Photo';

  @override
  String get sharePictureStays =>
      'Its picture stays in this workspace: the copy gets its earlier mascot, or its initials.';
}
