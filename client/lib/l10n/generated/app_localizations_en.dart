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
  String get noRoutines =>
      'No routines yet. Routines run this bot on a schedule or when a webhook arrives.';

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
  String get computerAdvancedTabsShow => 'Show the terminal';

  @override
  String get computerAdvancedTabsHide => 'Hide the terminal';

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
  String get takeControl => 'Take Control';

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
  String get callNeedsKeyTitle => 'Calls need a voice key';

  @override
  String get callNeedsKeyBody =>
      'Live calls run on Google\'s Gemini Live, so this workspace needs a Google AI key. Google gives you one free in AI Studio: create it there, then add it under Model keys and calls work right away. Only workspace owners and admins can add keys.';

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
  String get voiceSettingsHelp => 'Read-aloud voice and dictation provider';

  @override
  String get callTools => 'Tools on Calls';

  @override
  String get callToolsHelp =>
      'Calls already include memory, web search, notes to you, routines and tickets, and hand bigger jobs to the chat. Add connected-app tools the bot should use live; each one adds a little to every call\'s cost.';

  @override
  String get callToolsNone =>
      'This bot has no connected apps yet. Connect one under Integrations.';

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
  String get cloudConnect => 'Cloud Connect';

  @override
  String get cloudConnectHelp =>
      'Let a self-hosted Casama use cloud computers and model credits, billed to this workspace.';

  @override
  String get cloudConnectNewKey => 'New Cloud Connect Key';

  @override
  String get cloudConnectKeyCreated => 'Key Created';

  @override
  String get cloudConnectKeyOnce =>
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
  String get selectBotHelp =>
      'Pick a bot on the left, or create one to get started.';

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
      'Bring a bot over from OpenClaw or Hermes Agent: its persona, skills, schedules and memories. You\'ll review everything before it\'s created. Keys and settings files are never read.';

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
  String get whatsNew080Calls =>
      'Call your bots and talk things through. They answer out loud, with captions.';

  @override
  String get whatsNew080Looks =>
      'Make Casama yours: themes, color schemes, fonts and wallpapers in Settings → Appearance, with more from the gallery.';

  @override
  String get whatsNew080AboutYou =>
      'Tell your bots about yourself once, in Settings → About you: what to call you and how you like replies.';

  @override
  String get whatsNew080SignIn =>
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
    return 'Its messages, photos and files are deleted for everyone who can see it. Usage records stay, and anything $bot remembered from it stays in its memory.';
  }

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
  String get personalComputerOfflineHelp =>
      'This computer is offline. Open Casama on it and turn on \"Use this computer for bots\".';

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
      '1 credit = \$1. Credits from packs last 12 months.';

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
      'MCP servers on this computer that your bots can use, such as Claude Code, Codex or design apps. Their tokens stay on this computer.';

  @override
  String get localMcpAdd => 'Add a Local MCP Server';

  @override
  String get localMcpEmpty => 'No local MCP servers yet.';

  @override
  String get localMcpName => 'Name';

  @override
  String get localMcpStdio => 'A Command';

  @override
  String get localMcpLoopback => 'An Address on This Computer';

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
      'Use an address on this computer, like http://127.0.0.1:3845/mcp.';

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
  String get codingAgentsNone =>
      'No coding agents found. Install Claude Code, Codex or Cursor\'s command-line agent to hand them coding tasks.';

  @override
  String get codingAgentsNeedShell =>
      'Coding agents run as commands, so they need Run commands turned on.';

  @override
  String get allowCommands => 'Turn On';

  @override
  String get board => 'Board';

  @override
  String get newTicket => 'New ticket';

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
  String get noTickets => 'No tickets yet';

  @override
  String get noTicketsHelp =>
      'Add a ticket and assign it to a bot to get it started, or ask a bot to plan work here.';

  @override
  String get ticketStatus => 'Status';

  @override
  String get spaces => 'Workspaces';

  @override
  String get newWorkspace => 'New Workspace';

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
  String get searchMemories => 'Memories';

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
  String get justThisOnce => 'Just This Once';

  @override
  String get dontSuggestAgain => 'Don\'t Suggest It Again';

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
      'One per line: email addresses (or *@company.com), phone numbers, or user ids.';

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
  String get localServerHelp =>
      'Starts your own Casama server here with Docker and connects to it. Only this computer can reach it.';

  @override
  String get localServerIntro =>
      'Needs Docker Desktop running and about 10 GB of disk. The first start downloads the server, which takes several minutes.';

  @override
  String get localServerChecking => 'Checking Docker…';

  @override
  String get localServerDownloading => 'Downloading the server…';

  @override
  String get localServerInstalling => 'Setting up the server…';

  @override
  String get localServerStarting => 'Waiting for the server to answer…';

  @override
  String get localServerReady => 'Ready. Connecting…';

  @override
  String get localServerFailed => 'Something went wrong.';

  @override
  String get localServerStart => 'Start the server';

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
  String get deviceNoBots => 'No bots yet. A bot asks when it needs this.';

  @override
  String get devicePermissionDenied =>
      'Casama doesn\'t have permission. Allow it in the system settings, then try again.';

  @override
  String get deviceOtherDevices => 'Your Other Devices';

  @override
  String get deviceForget => 'Forget this device';

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
  String get showBotSteps => 'Show the Bot\'s Steps';

  @override
  String get showBotStepsHelp => 'Commands and technical errors in every chat.';

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
  String invitePeopleTo(String name) {
    return 'Invite People to $name';
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
  String get billingAdvancedSummary => 'Charges by server, Cloud Connect keys';

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
  String get settingsSecuritySection => 'Sign-in & Security';

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
    return '$price $period, renewing automatically until you cancel. Payment is charged to your $store account. Cancel anytime in your $store account settings at least 24 hours before it renews.';
  }

  @override
  String paywallDisclosureWeb(String price) {
    return '$price, renewing automatically until you cancel. Cancel anytime from Billing; you keep the plan until the period ends.';
  }

  @override
  String get pricePerMonth => 'per month';

  @override
  String get pricePerYear => 'per year';

  @override
  String get storeAccountApple => 'Apple ID';

  @override
  String get storeAccountGoogle => 'Google Play';

  @override
  String get termsOfUse => 'Terms of Use';

  @override
  String get privacyPolicy => 'Privacy Policy';

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
  String get outOfCreditsTitle => 'You\'re out of credits';

  @override
  String get outOfCreditsPaidBody =>
      'Your bots pause until you add credits. Credits from a pack last 12 months.';

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
      'Minimum versions, maintenance, announcements and feature switches for every app, with no release.';

  @override
  String get adminAppSettingsBadJson =>
      'That isn\'t valid JSON. Check the brackets, quotes and commas.';

  @override
  String get paywallBillingPeriod => 'Billing period';

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
}
