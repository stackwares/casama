import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Kasama'**
  String get appTitle;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @signInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to Kasama'**
  String get signInTitle;

  /// No description provided for @signUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get signUpTitle;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get signUp;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'Have an account? Sign in'**
  String get haveAccount;

  /// No description provided for @needAccount.
  ///
  /// In en, this message translates to:
  /// **'New here? Create an account'**
  String get needAccount;

  /// No description provided for @magicLink.
  ///
  /// In en, this message translates to:
  /// **'Email me a sign-in link'**
  String get magicLink;

  /// No description provided for @magicLinkSent.
  ///
  /// In en, this message translates to:
  /// **'Check your email for a sign-in link.'**
  String get magicLinkSent;

  /// No description provided for @confirmEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Check your email to confirm your account, then sign in.'**
  String get confirmEmailSent;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get invalidEmail;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least 6 characters'**
  String get passwordTooShort;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up your workspace'**
  String get onboardingTitle;

  /// No description provided for @createWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Create a workspace'**
  String get createWorkspace;

  /// No description provided for @workspaceName.
  ///
  /// In en, this message translates to:
  /// **'Workspace name'**
  String get workspaceName;

  /// No description provided for @joinWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Join with an invite code'**
  String get joinWorkspace;

  /// No description provided for @inviteCode.
  ///
  /// In en, this message translates to:
  /// **'Invite code'**
  String get inviteCode;

  /// No description provided for @join.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get join;

  /// No description provided for @addModelKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a model key'**
  String get addModelKeyTitle;

  /// No description provided for @addModelKeyBody.
  ///
  /// In en, this message translates to:
  /// **'Bots use your own model provider key. It is stored encrypted and never shown again.'**
  String get addModelKeyBody;

  /// No description provided for @provider.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get provider;

  /// No description provided for @label.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get label;

  /// No description provided for @apiKey.
  ///
  /// In en, this message translates to:
  /// **'API key'**
  String get apiKey;

  /// No description provided for @baseUrl.
  ///
  /// In en, this message translates to:
  /// **'Base URL'**
  String get baseUrl;

  /// No description provided for @testKey.
  ///
  /// In en, this message translates to:
  /// **'Test key'**
  String get testKey;

  /// No description provided for @keyOk.
  ///
  /// In en, this message translates to:
  /// **'Key works ({model}, {ms} ms)'**
  String keyOk(String model, int ms);

  /// No description provided for @keyFailed.
  ///
  /// In en, this message translates to:
  /// **'Key test failed: {error}'**
  String keyFailed(String error);

  /// No description provided for @createFirstBot.
  ///
  /// In en, this message translates to:
  /// **'Create your first bot'**
  String get createFirstBot;

  /// No description provided for @botName.
  ///
  /// In en, this message translates to:
  /// **'Bot name'**
  String get botName;

  /// No description provided for @model.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get model;

  /// No description provided for @persona.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get persona;

  /// No description provided for @personaHint.
  ///
  /// In en, this message translates to:
  /// **'What this bot does and how it should work. A persona fills this in; edit it freely.'**
  String get personaHint;

  /// No description provided for @modelKey.
  ///
  /// In en, this message translates to:
  /// **'Model key'**
  String get modelKey;

  /// No description provided for @navBots.
  ///
  /// In en, this message translates to:
  /// **'Bots'**
  String get navBots;

  /// No description provided for @navComputer.
  ///
  /// In en, this message translates to:
  /// **'Computer'**
  String get navComputer;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @bots.
  ///
  /// In en, this message translates to:
  /// **'Bots'**
  String get bots;

  /// No description provided for @newBot.
  ///
  /// In en, this message translates to:
  /// **'New bot'**
  String get newBot;

  /// No description provided for @noBots.
  ///
  /// In en, this message translates to:
  /// **'No bots yet'**
  String get noBots;

  /// No description provided for @botStatusIdle.
  ///
  /// In en, this message translates to:
  /// **'Idle'**
  String get botStatusIdle;

  /// No description provided for @botStatusWorking.
  ///
  /// In en, this message translates to:
  /// **'Working'**
  String get botStatusWorking;

  /// No description provided for @botStatusWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for you'**
  String get botStatusWaiting;

  /// No description provided for @botStatusDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get botStatusDisabled;

  /// No description provided for @costToday.
  ///
  /// In en, this message translates to:
  /// **'{cost} today'**
  String costToday(String cost);

  /// No description provided for @lastActive.
  ///
  /// In en, this message translates to:
  /// **'Active {when}'**
  String lastActive(String when);

  /// No description provided for @selectBot.
  ///
  /// In en, this message translates to:
  /// **'Select a bot to chat'**
  String get selectBot;

  /// No description provided for @newChat.
  ///
  /// In en, this message translates to:
  /// **'New chat'**
  String get newChat;

  /// No description provided for @conversations.
  ///
  /// In en, this message translates to:
  /// **'Conversations'**
  String get conversations;

  /// No description provided for @messageHint.
  ///
  /// In en, this message translates to:
  /// **'Message {bot}'**
  String messageHint(String bot);

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @thinking.
  ///
  /// In en, this message translates to:
  /// **'Thinking…'**
  String get thinking;

  /// No description provided for @runFailed.
  ///
  /// In en, this message translates to:
  /// **'{message}'**
  String runFailed(String message);

  /// No description provided for @runCancelled.
  ///
  /// In en, this message translates to:
  /// **'Stopped.'**
  String get runCancelled;

  /// No description provided for @emptyChat.
  ///
  /// In en, this message translates to:
  /// **'Say hello to {bot}.'**
  String emptyChat(String bot);

  /// No description provided for @toolRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get toolRunning;

  /// No description provided for @toolDone.
  ///
  /// In en, this message translates to:
  /// **'Done in {ms} ms'**
  String toolDone(int ms);

  /// No description provided for @toolFailedLabel.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get toolFailedLabel;

  /// No description provided for @toolOutput.
  ///
  /// In en, this message translates to:
  /// **'Output'**
  String get toolOutput;

  /// No description provided for @remembered.
  ///
  /// In en, this message translates to:
  /// **'Remembered something'**
  String get remembered;

  /// No description provided for @skillLoaded.
  ///
  /// In en, this message translates to:
  /// **'Loaded skill {name}'**
  String skillLoaded(String name);

  /// No description provided for @checkpointSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved checkpoint: {label}'**
  String checkpointSaved(String label);

  /// No description provided for @computerState.
  ///
  /// In en, this message translates to:
  /// **'Computer {state}'**
  String computerState(String state);

  /// No description provided for @runCost.
  ///
  /// In en, this message translates to:
  /// **'{cost} · {tokens} tokens'**
  String runCost(String cost, int tokens);

  /// No description provided for @activity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activity;

  /// No description provided for @timelineTitle.
  ///
  /// In en, this message translates to:
  /// **'Run timeline'**
  String get timelineTitle;

  /// No description provided for @allEvents.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allEvents;

  /// No description provided for @filterTools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get filterTools;

  /// No description provided for @filterMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get filterMessages;

  /// No description provided for @filterSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get filterSystem;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @restoreConfirm.
  ///
  /// In en, this message translates to:
  /// **'Restore this checkpoint? Files changed since then will be replaced.'**
  String get restoreConfirm;

  /// No description provided for @restored.
  ///
  /// In en, this message translates to:
  /// **'Checkpoint restored.'**
  String get restored;

  /// No description provided for @noRuns.
  ///
  /// In en, this message translates to:
  /// **'No runs yet.'**
  String get noRuns;

  /// No description provided for @computerTitle.
  ///
  /// In en, this message translates to:
  /// **'Computer'**
  String get computerTitle;

  /// No description provided for @computerStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get computerStart;

  /// No description provided for @computerSleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get computerSleep;

  /// No description provided for @screen.
  ///
  /// In en, this message translates to:
  /// **'Screen'**
  String get screen;

  /// No description provided for @terminal.
  ///
  /// In en, this message translates to:
  /// **'Terminal'**
  String get terminal;

  /// No description provided for @files.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get files;

  /// No description provided for @checkpoints.
  ///
  /// In en, this message translates to:
  /// **'Checkpoints'**
  String get checkpoints;

  /// No description provided for @headlessScreenNote.
  ///
  /// In en, this message translates to:
  /// **'This computer has no desktop, so this shows its browser (blank until the bot opens a page). Switch to a desktop to watch and control apps live.'**
  String get headlessScreenNote;

  /// No description provided for @noScreen.
  ///
  /// In en, this message translates to:
  /// **'Nothing on screen yet. The bot\'s browser page appears here.'**
  String get noScreen;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @emptyFolder.
  ///
  /// In en, this message translates to:
  /// **'This folder is empty'**
  String get emptyFolder;

  /// No description provided for @noCheckpoints.
  ///
  /// In en, this message translates to:
  /// **'They\'re saved automatically before risky changes, so you can undo them.'**
  String get noCheckpoints;

  /// No description provided for @computerAsleep.
  ///
  /// In en, this message translates to:
  /// **'The computer is asleep. Its files are saved and it wakes up when needed.'**
  String get computerAsleep;

  /// No description provided for @connectTerminal.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connectTerminal;

  /// No description provided for @terminalDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected.'**
  String get terminalDisconnected;

  /// No description provided for @memory.
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get memory;

  /// No description provided for @noMemories.
  ///
  /// In en, this message translates to:
  /// **'Nothing remembered yet.'**
  String get noMemories;

  /// No description provided for @pin.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get pin;

  /// No description provided for @unpin.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get unpin;

  /// No description provided for @deleteMemoryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Forget this? It cannot be undone.'**
  String get deleteMemoryConfirm;

  /// No description provided for @skills.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get skills;

  /// No description provided for @noSkills.
  ///
  /// In en, this message translates to:
  /// **'No skills yet. Skills are instructions bots load when relevant.'**
  String get noSkills;

  /// No description provided for @newSkill.
  ///
  /// In en, this message translates to:
  /// **'New skill'**
  String get newSkill;

  /// No description provided for @skillName.
  ///
  /// In en, this message translates to:
  /// **'Name (lowercase, dashes)'**
  String get skillName;

  /// No description provided for @skillDescription.
  ///
  /// In en, this message translates to:
  /// **'One-line description'**
  String get skillDescription;

  /// No description provided for @skillBody.
  ///
  /// In en, this message translates to:
  /// **'Instructions (Markdown)'**
  String get skillBody;

  /// No description provided for @enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabled;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @workspace.
  ///
  /// In en, this message translates to:
  /// **'Workspace'**
  String get workspace;

  /// No description provided for @switchWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Switch workspace'**
  String get switchWorkspace;

  /// No description provided for @modelKeys.
  ///
  /// In en, this message translates to:
  /// **'Model keys'**
  String get modelKeys;

  /// No description provided for @noKeys.
  ///
  /// In en, this message translates to:
  /// **'No model keys yet.'**
  String get noKeys;

  /// No description provided for @addKey.
  ///
  /// In en, this message translates to:
  /// **'Add key'**
  String get addKey;

  /// No description provided for @usage.
  ///
  /// In en, this message translates to:
  /// **'Usage'**
  String get usage;

  /// No description provided for @usageMonth.
  ///
  /// In en, this message translates to:
  /// **'This month: {cost}'**
  String usageMonth(String cost);

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @signedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {email}'**
  String signedInAs(String email);

  /// No description provided for @inviteMember.
  ///
  /// In en, this message translates to:
  /// **'Invite a member'**
  String get inviteMember;

  /// No description provided for @inviteSent.
  ///
  /// In en, this message translates to:
  /// **'Invite sent to {email}.'**
  String inviteSent(String email);

  /// No description provided for @inviteCodeToShare.
  ///
  /// In en, this message translates to:
  /// **'Share this invite code: {code}'**
  String inviteCodeToShare(String code);

  /// No description provided for @botSettings.
  ///
  /// In en, this message translates to:
  /// **'Bot settings'**
  String get botSettings;

  /// No description provided for @autonomy.
  ///
  /// In en, this message translates to:
  /// **'Autonomy'**
  String get autonomy;

  /// No description provided for @autonomyAskAlways.
  ///
  /// In en, this message translates to:
  /// **'Ask before acting'**
  String get autonomyAskAlways;

  /// No description provided for @autonomyAskRisky.
  ///
  /// In en, this message translates to:
  /// **'Ask for risky actions'**
  String get autonomyAskRisky;

  /// No description provided for @autonomyAutonomous.
  ///
  /// In en, this message translates to:
  /// **'Act on its own'**
  String get autonomyAutonomous;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved.'**
  String get saved;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 minute ago} other{{n} minutes ago}}'**
  String minutesAgo(int n);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 hour ago} other{{n} hours ago}}'**
  String hoursAgo(int n);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{yesterday} other{{n} days ago}}'**
  String daysAgo(int n);

  /// No description provided for @aBot.
  ///
  /// In en, this message translates to:
  /// **'A bot'**
  String get aBot;

  /// No description provided for @addIntegration.
  ///
  /// In en, this message translates to:
  /// **'Add integration'**
  String get addIntegration;

  /// No description provided for @addSecret.
  ///
  /// In en, this message translates to:
  /// **'Add secret'**
  String get addSecret;

  /// No description provided for @allowedHosts.
  ///
  /// In en, this message translates to:
  /// **'Allowed hosts'**
  String get allowedHosts;

  /// No description provided for @allowedHostsHelp.
  ///
  /// In en, this message translates to:
  /// **'Comma-separated, for example api.github.com'**
  String get allowedHostsHelp;

  /// No description provided for @alwaysAllow.
  ///
  /// In en, this message translates to:
  /// **'Always allow'**
  String get alwaysAllow;

  /// No description provided for @approval.
  ///
  /// In en, this message translates to:
  /// **'Approval'**
  String get approval;

  /// No description provided for @approvalAlreadyDecided.
  ///
  /// In en, this message translates to:
  /// **'This request was already decided or has expired.'**
  String get approvalAlreadyDecided;

  /// No description provided for @approvals.
  ///
  /// In en, this message translates to:
  /// **'Approvals'**
  String get approvals;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// No description provided for @authHeaderOptional.
  ///
  /// In en, this message translates to:
  /// **'Authorization header (optional)'**
  String get authHeaderOptional;

  /// No description provided for @authSecretName.
  ///
  /// In en, this message translates to:
  /// **'Auth secret name (optional)'**
  String get authSecretName;

  /// No description provided for @authSecretNameHelp.
  ///
  /// In en, this message translates to:
  /// **'Name of a secret from Settings › Secrets, sent as a bearer token'**
  String get authSecretNameHelp;

  /// No description provided for @baseUrlOptional.
  ///
  /// In en, this message translates to:
  /// **'Base URL (optional)'**
  String get baseUrlOptional;

  /// No description provided for @blankBot.
  ///
  /// In en, this message translates to:
  /// **'Blank'**
  String get blankBot;

  /// No description provided for @defaultBotName.
  ///
  /// In en, this message translates to:
  /// **'Chief'**
  String get defaultBotName;

  /// No description provided for @chooseModel.
  ///
  /// In en, this message translates to:
  /// **'Choose a model'**
  String get chooseModel;

  /// No description provided for @searchModels.
  ///
  /// In en, this message translates to:
  /// **'Search models or type a model id'**
  String get searchModels;

  /// No description provided for @recommendedModels.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get recommendedModels;

  /// No description provided for @allModels.
  ///
  /// In en, this message translates to:
  /// **'All models'**
  String get allModels;

  /// No description provided for @useCustomModel.
  ///
  /// In en, this message translates to:
  /// **'Use \"{id}\"'**
  String useCustomModel(String id);

  /// No description provided for @modelListFallback.
  ///
  /// In en, this message translates to:
  /// **'Showing suggested models. {reason} You can still type any model id.'**
  String modelListFallback(String reason);

  /// No description provided for @noModelsFound.
  ///
  /// In en, this message translates to:
  /// **'No models match.'**
  String get noModelsFound;

  /// No description provided for @addModelKeyFirst.
  ///
  /// In en, this message translates to:
  /// **'Add a model key first. Your bot uses it to think; it\'s stored encrypted and never shown again.'**
  String get addModelKeyFirst;

  /// No description provided for @botIntegrations.
  ///
  /// In en, this message translates to:
  /// **'Integrations for this bot'**
  String get botIntegrations;

  /// No description provided for @changeStatus.
  ///
  /// In en, this message translates to:
  /// **'Change status'**
  String get changeStatus;

  /// No description provided for @composioToolkits.
  ///
  /// In en, this message translates to:
  /// **'Toolkits (comma-separated, for example github, gmail)'**
  String get composioToolkits;

  /// No description provided for @copySecret.
  ///
  /// In en, this message translates to:
  /// **'Copy secret'**
  String get copySecret;

  /// No description provided for @cronExpression.
  ///
  /// In en, this message translates to:
  /// **'Cron expression'**
  String get cronExpression;

  /// No description provided for @cronHelp.
  ///
  /// In en, this message translates to:
  /// **'minute hour day month weekday'**
  String get cronHelp;

  /// No description provided for @denied.
  ///
  /// In en, this message translates to:
  /// **'Denied'**
  String get denied;

  /// No description provided for @deny.
  ///
  /// In en, this message translates to:
  /// **'Deny'**
  String get deny;

  /// No description provided for @everyDayAt7.
  ///
  /// In en, this message translates to:
  /// **'Every day at 7:00'**
  String get everyDayAt7;

  /// No description provided for @everyHour.
  ///
  /// In en, this message translates to:
  /// **'Every hour'**
  String get everyHour;

  /// No description provided for @expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expired;

  /// No description provided for @inbox.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get inbox;

  /// No description provided for @integrationName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get integrationName;

  /// No description provided for @integrationNameHelp.
  ///
  /// In en, this message translates to:
  /// **'Lowercase letters, numbers and underscores'**
  String get integrationNameHelp;

  /// No description provided for @integrationType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get integrationType;

  /// No description provided for @integrations.
  ///
  /// In en, this message translates to:
  /// **'Integrations'**
  String get integrations;

  /// No description provided for @kindMcp.
  ///
  /// In en, this message translates to:
  /// **'MCP server'**
  String get kindMcp;

  /// No description provided for @kindOpenapi.
  ///
  /// In en, this message translates to:
  /// **'OpenAPI'**
  String get kindOpenapi;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllRead;

  /// No description provided for @mondaysAt9.
  ///
  /// In en, this message translates to:
  /// **'Mondays at 9:00'**
  String get mondaysAt9;

  /// No description provided for @newRoutine.
  ///
  /// In en, this message translates to:
  /// **'New routine'**
  String get newRoutine;

  /// No description provided for @noApprovals.
  ///
  /// In en, this message translates to:
  /// **'Nothing needs your approval right now.'**
  String get noApprovals;

  /// No description provided for @noIntegrations.
  ///
  /// In en, this message translates to:
  /// **'Connect an MCP server, an OpenAPI source, Composio or Pipedream to give bots more tools.'**
  String get noIntegrations;

  /// No description provided for @noIntegrationsForBot.
  ///
  /// In en, this message translates to:
  /// **'Add integrations in Settings first, then turn them on for this bot here.'**
  String get noIntegrationsForBot;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotifications;

  /// No description provided for @noRoutines.
  ///
  /// In en, this message translates to:
  /// **'No routines yet. Routines run this bot on a schedule or when a webhook arrives.'**
  String get noRoutines;

  /// No description provided for @noSecrets.
  ///
  /// In en, this message translates to:
  /// **'No secrets yet. Bots reference them by name, and each one only goes to the hosts you allow.'**
  String get noSecrets;

  /// No description provided for @noTasks.
  ///
  /// In en, this message translates to:
  /// **'No tasks yet'**
  String get noTasks;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @openInbox.
  ///
  /// In en, this message translates to:
  /// **'Open inbox'**
  String get openInbox;

  /// No description provided for @pipedreamApps.
  ///
  /// In en, this message translates to:
  /// **'Apps (comma-separated)'**
  String get pipedreamApps;

  /// No description provided for @pipedreamClientId.
  ///
  /// In en, this message translates to:
  /// **'Client ID'**
  String get pipedreamClientId;

  /// No description provided for @pipedreamClientSecret.
  ///
  /// In en, this message translates to:
  /// **'Client secret'**
  String get pipedreamClientSecret;

  /// No description provided for @pipedreamProject.
  ///
  /// In en, this message translates to:
  /// **'Project ID'**
  String get pipedreamProject;

  /// No description provided for @riskHigh.
  ///
  /// In en, this message translates to:
  /// **'High risk'**
  String get riskHigh;

  /// No description provided for @riskLow.
  ///
  /// In en, this message translates to:
  /// **'Low risk'**
  String get riskLow;

  /// No description provided for @riskMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium risk'**
  String get riskMedium;

  /// No description provided for @routineGithub.
  ///
  /// In en, this message translates to:
  /// **'On GitHub events'**
  String get routineGithub;

  /// No description provided for @routineInstructions.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get routineInstructions;

  /// No description provided for @routineInstructionsHint.
  ///
  /// In en, this message translates to:
  /// **'What should the bot do each time?'**
  String get routineInstructionsHint;

  /// No description provided for @routineName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get routineName;

  /// No description provided for @routineStarted.
  ///
  /// In en, this message translates to:
  /// **'Routine started'**
  String get routineStarted;

  /// No description provided for @routineWebhook.
  ///
  /// In en, this message translates to:
  /// **'On webhook'**
  String get routineWebhook;

  /// No description provided for @routines.
  ///
  /// In en, this message translates to:
  /// **'Routines'**
  String get routines;

  /// No description provided for @runNow.
  ///
  /// In en, this message translates to:
  /// **'Run now'**
  String get runNow;

  /// No description provided for @secretName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get secretName;

  /// No description provided for @secretNameHelp.
  ///
  /// In en, this message translates to:
  /// **'Uppercase, for example GITHUB_TOKEN'**
  String get secretNameHelp;

  /// No description provided for @secretValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get secretValue;

  /// No description provided for @secrets.
  ///
  /// In en, this message translates to:
  /// **'Secrets'**
  String get secrets;

  /// No description provided for @serverUrl.
  ///
  /// In en, this message translates to:
  /// **'Server URL'**
  String get serverUrl;

  /// No description provided for @specUrl.
  ///
  /// In en, this message translates to:
  /// **'OpenAPI spec URL'**
  String get specUrl;

  /// No description provided for @startFrom.
  ///
  /// In en, this message translates to:
  /// **'Persona'**
  String get startFrom;

  /// No description provided for @storedEncrypted.
  ///
  /// In en, this message translates to:
  /// **'Stored encrypted; never shown again'**
  String get storedEncrypted;

  /// No description provided for @taskBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get taskBlocked;

  /// No description provided for @taskBoard.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get taskBoard;

  /// No description provided for @taskDoing.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get taskDoing;

  /// No description provided for @taskDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get taskDone;

  /// No description provided for @taskTodo.
  ///
  /// In en, this message translates to:
  /// **'To do'**
  String get taskTodo;

  /// No description provided for @test.
  ///
  /// In en, this message translates to:
  /// **'Test'**
  String get test;

  /// No description provided for @timezone.
  ///
  /// In en, this message translates to:
  /// **'Timezone'**
  String get timezone;

  /// No description provided for @triggerGithub.
  ///
  /// In en, this message translates to:
  /// **'GitHub'**
  String get triggerGithub;

  /// No description provided for @triggerSchedule.
  ///
  /// In en, this message translates to:
  /// **'Repeats'**
  String get triggerSchedule;

  /// No description provided for @triggerWebhook.
  ///
  /// In en, this message translates to:
  /// **'Webhook'**
  String get triggerWebhook;

  /// No description provided for @viewRun.
  ///
  /// In en, this message translates to:
  /// **'View run'**
  String get viewRun;

  /// No description provided for @webhookCreated.
  ///
  /// In en, this message translates to:
  /// **'Webhook created'**
  String get webhookCreated;

  /// No description provided for @webhookSecret.
  ///
  /// In en, this message translates to:
  /// **'Signing secret'**
  String get webhookSecret;

  /// No description provided for @webhookShownOnce.
  ///
  /// In en, this message translates to:
  /// **'Copy the signing secret now. It is shown only once.'**
  String get webhookShownOnce;

  /// No description provided for @webhookUrl.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get webhookUrl;

  /// No description provided for @approvalsCount.
  ///
  /// In en, this message translates to:
  /// **'Approvals ({n})'**
  String approvalsCount(int n);

  /// No description provided for @botWantsTo.
  ///
  /// In en, this message translates to:
  /// **'{bot}: {summary}'**
  String botWantsTo(String bot, String summary);

  /// No description provided for @integrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed: {error}'**
  String integrationFailed(String error);

  /// No description provided for @integrationOk.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Connected, 1 tool} other{Connected, {n} tools}}'**
  String integrationOk(int n);

  /// No description provided for @needsApprovalFor.
  ///
  /// In en, this message translates to:
  /// **'{bot} needs your approval to use {tool}'**
  String needsApprovalFor(String bot, String tool);

  /// No description provided for @nextRun.
  ///
  /// In en, this message translates to:
  /// **'Next: {when}'**
  String nextRun(String when);

  /// No description provided for @onlySentTo.
  ///
  /// In en, this message translates to:
  /// **'Only sent to {hosts}'**
  String onlySentTo(String hosts);

  /// No description provided for @requestedAgo.
  ///
  /// In en, this message translates to:
  /// **'requested {when}'**
  String requestedAgo(String when);

  /// No description provided for @routineSchedule.
  ///
  /// In en, this message translates to:
  /// **'{cron} ({timezone})'**
  String routineSchedule(String cron, String timezone);

  /// No description provided for @templateIncludesRoutines.
  ///
  /// In en, this message translates to:
  /// **'Includes routines: {names}.'**
  String templateIncludesRoutines(String names);

  /// No description provided for @toolCount.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 tool} other{{n} tools}}'**
  String toolCount(int n);

  /// No description provided for @weekdaysAt9.
  ///
  /// In en, this message translates to:
  /// **'Weekdays at 9:00'**
  String get weekdaysAt9;

  /// No description provided for @botBackInControl.
  ///
  /// In en, this message translates to:
  /// **'The bot is back in control'**
  String get botBackInControl;

  /// No description provided for @botComputer.
  ///
  /// In en, this message translates to:
  /// **'Computer'**
  String get botComputer;

  /// No description provided for @botComputerDefault.
  ///
  /// In en, this message translates to:
  /// **'Its private computer if it has one, otherwise the team computer'**
  String get botComputerDefault;

  /// No description provided for @botInControl.
  ///
  /// In en, this message translates to:
  /// **'Bot in control'**
  String get botInControl;

  /// No description provided for @computerName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get computerName;

  /// No description provided for @computers.
  ///
  /// In en, this message translates to:
  /// **'Computers'**
  String get computers;

  /// No description provided for @connectingLive.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get connectingLive;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @forBot.
  ///
  /// In en, this message translates to:
  /// **'For bot'**
  String get forBot;

  /// No description provided for @handBack.
  ///
  /// In en, this message translates to:
  /// **'Hand back'**
  String get handBack;

  /// No description provided for @handBackNote.
  ///
  /// In en, this message translates to:
  /// **'Note for the bot (optional)'**
  String get handBackNote;

  /// No description provided for @handBackNoteHint.
  ///
  /// In en, this message translates to:
  /// **'For example: I signed in, carry on'**
  String get handBackNoteHint;

  /// No description provided for @live.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get live;

  /// No description provided for @liveView.
  ///
  /// In en, this message translates to:
  /// **'Live view'**
  String get liveView;

  /// No description provided for @liveViewHelp.
  ///
  /// In en, this message translates to:
  /// **'Watch this computer live and take control when needed.'**
  String get liveViewHelp;

  /// No description provided for @newComputer.
  ///
  /// In en, this message translates to:
  /// **'New computer'**
  String get newComputer;

  /// No description provided for @newComputerHelp.
  ///
  /// In en, this message translates to:
  /// **'A private computer belongs to one bot. Its files stay separate from the team computer.'**
  String get newComputerHelp;

  /// No description provided for @openLiveView.
  ///
  /// In en, this message translates to:
  /// **'Open live view'**
  String get openLiveView;

  /// No description provided for @paused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get paused;

  /// No description provided for @pausedUserInControl.
  ///
  /// In en, this message translates to:
  /// **'Paused: a person is in control of the screen'**
  String get pausedUserInControl;

  /// No description provided for @privateComputer.
  ///
  /// In en, this message translates to:
  /// **'Private computer'**
  String get privateComputer;

  /// No description provided for @profileDesktop.
  ///
  /// In en, this message translates to:
  /// **'Desktop'**
  String get profileDesktop;

  /// No description provided for @profileHeadless.
  ///
  /// In en, this message translates to:
  /// **'Headless'**
  String get profileHeadless;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @rightClickNextTap.
  ///
  /// In en, this message translates to:
  /// **'Right-click on next tap'**
  String get rightClickNextTap;

  /// No description provided for @screenshotMode.
  ///
  /// In en, this message translates to:
  /// **'Screenshots (live video unavailable on this network)'**
  String get screenshotMode;

  /// No description provided for @showKeyboard.
  ///
  /// In en, this message translates to:
  /// **'Keyboard'**
  String get showKeyboard;

  /// No description provided for @someoneElseInControl.
  ///
  /// In en, this message translates to:
  /// **'Someone else is in control'**
  String get someoneElseInControl;

  /// No description provided for @switchToDesktop.
  ///
  /// In en, this message translates to:
  /// **'Switch to desktop'**
  String get switchToDesktop;

  /// No description provided for @switchToHeadless.
  ///
  /// In en, this message translates to:
  /// **'Switch to headless'**
  String get switchToHeadless;

  /// No description provided for @takeControl.
  ///
  /// In en, this message translates to:
  /// **'Take control'**
  String get takeControl;

  /// No description provided for @takeoverCompleted.
  ///
  /// In en, this message translates to:
  /// **'Handed back'**
  String get takeoverCompleted;

  /// No description provided for @takeoverDismissed.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get takeoverDismissed;

  /// No description provided for @takeoverPrivacy.
  ///
  /// In en, this message translates to:
  /// **'While you\'re in control, the bot is paused and nothing you type or see is sent to it.'**
  String get takeoverPrivacy;

  /// No description provided for @teamComputer.
  ///
  /// In en, this message translates to:
  /// **'Team computer'**
  String get teamComputer;

  /// No description provided for @withDesktop.
  ///
  /// In en, this message translates to:
  /// **'With a desktop'**
  String get withDesktop;

  /// No description provided for @withDesktopHelp.
  ///
  /// In en, this message translates to:
  /// **'Adds a screen you can watch live; uses more memory'**
  String get withDesktopHelp;

  /// No description provided for @youAreInControl.
  ///
  /// In en, this message translates to:
  /// **'You\'re in control'**
  String get youAreInControl;

  /// No description provided for @botAsksForHelp.
  ///
  /// In en, this message translates to:
  /// **'The bot asks: {reason}'**
  String botAsksForHelp(String reason);

  /// No description provided for @botNeedsHelp.
  ///
  /// In en, this message translates to:
  /// **'{bot} needs your help'**
  String botNeedsHelp(String bot);

  /// No description provided for @deleteComputerConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}? Its files, snapshots and checkpoints are deleted too.'**
  String deleteComputerConfirm(String name);

  /// No description provided for @latencyMs.
  ///
  /// In en, this message translates to:
  /// **'{ms} ms'**
  String latencyMs(int ms);

  /// No description provided for @privateComputerOf.
  ///
  /// In en, this message translates to:
  /// **'{bot}\'s computer'**
  String privateComputerOf(String bot);

  /// No description provided for @micPermissionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Allow microphone access to dictate.'**
  String get micPermissionNeeded;

  /// No description provided for @startCall.
  ///
  /// In en, this message translates to:
  /// **'Start a voice call'**
  String get startCall;

  /// No description provided for @stopDictation.
  ///
  /// In en, this message translates to:
  /// **'Stop and transcribe'**
  String get stopDictation;

  /// No description provided for @dictate.
  ///
  /// In en, this message translates to:
  /// **'Dictate'**
  String get dictate;

  /// No description provided for @readAloud.
  ///
  /// In en, this message translates to:
  /// **'Read aloud'**
  String get readAloud;

  /// No description provided for @callConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get callConnecting;

  /// No description provided for @callLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get callLive;

  /// No description provided for @callEnded.
  ///
  /// In en, this message translates to:
  /// **'Call ended'**
  String get callEnded;

  /// No description provided for @callFailed.
  ///
  /// In en, this message translates to:
  /// **'The call could not connect.'**
  String get callFailed;

  /// No description provided for @unmute.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get unmute;

  /// No description provided for @mute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get mute;

  /// No description provided for @hangUp.
  ///
  /// In en, this message translates to:
  /// **'Hang up'**
  String get hangUp;

  /// No description provided for @callWith.
  ///
  /// In en, this message translates to:
  /// **'Call with {bot}'**
  String callWith(String bot);

  /// No description provided for @replyLatency.
  ///
  /// In en, this message translates to:
  /// **'Reply started in {ms} ms'**
  String replyLatency(int ms);

  /// No description provided for @voiceSettings.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get voiceSettings;

  /// No description provided for @voiceSettingsHelp.
  ///
  /// In en, this message translates to:
  /// **'Read-aloud voice and dictation provider'**
  String get voiceSettingsHelp;

  /// No description provided for @readAloudProvider.
  ///
  /// In en, this message translates to:
  /// **'Read-aloud provider'**
  String get readAloudProvider;

  /// No description provided for @automatic.
  ///
  /// In en, this message translates to:
  /// **'Automatic (first key found)'**
  String get automatic;

  /// No description provided for @voiceId.
  ///
  /// In en, this message translates to:
  /// **'Voice id (optional)'**
  String get voiceId;

  /// No description provided for @voiceIdHelp.
  ///
  /// In en, this message translates to:
  /// **'The provider\'s voice id; empty uses a default voice'**
  String get voiceIdHelp;

  /// No description provided for @dictationProvider.
  ///
  /// In en, this message translates to:
  /// **'Dictation provider'**
  String get dictationProvider;

  /// No description provided for @useThisComputer.
  ///
  /// In en, this message translates to:
  /// **'Use this computer for bots'**
  String get useThisComputer;

  /// No description provided for @companionDesktopOnly.
  ///
  /// In en, this message translates to:
  /// **'Only the desktop app (macOS, Windows, Linux) can act as a bot computer.'**
  String get companionDesktopOnly;

  /// No description provided for @companionIntro.
  ///
  /// In en, this message translates to:
  /// **'Let chosen bots work on this computer: run commands, edit files in folders you pick, browse and use apps. Everything they do shows on screen and can be stopped. Off until you approve each capability.'**
  String get companionIntro;

  /// No description provided for @thisComputer.
  ///
  /// In en, this message translates to:
  /// **'This computer'**
  String get thisComputer;

  /// No description provided for @companionOnline.
  ///
  /// In en, this message translates to:
  /// **'On: bots you allow can use this computer'**
  String get companionOnline;

  /// No description provided for @companionError.
  ///
  /// In en, this message translates to:
  /// **'Cannot reach Kasama; retrying'**
  String get companionError;

  /// No description provided for @companionOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get companionOff;

  /// No description provided for @companionCapabilities.
  ///
  /// In en, this message translates to:
  /// **'What bots may do'**
  String get companionCapabilities;

  /// No description provided for @companionCapabilitiesHelp.
  ///
  /// In en, this message translates to:
  /// **'Approve each one. High-risk actions always ask, whatever the bot\'s autonomy.'**
  String get companionCapabilitiesHelp;

  /// No description provided for @capShell.
  ///
  /// In en, this message translates to:
  /// **'Run commands (inside shared folders)'**
  String get capShell;

  /// No description provided for @capFiles.
  ///
  /// In en, this message translates to:
  /// **'Read and edit files in shared folders'**
  String get capFiles;

  /// No description provided for @capBrowser.
  ///
  /// In en, this message translates to:
  /// **'Use a browser (its own, separate from yours)'**
  String get capBrowser;

  /// No description provided for @capDesktop.
  ///
  /// In en, this message translates to:
  /// **'Use desktop apps'**
  String get capDesktop;

  /// No description provided for @sharedFolders.
  ///
  /// In en, this message translates to:
  /// **'Shared folders'**
  String get sharedFolders;

  /// No description provided for @sharedFoldersHelp.
  ///
  /// In en, this message translates to:
  /// **'Bots can only reach these folders.'**
  String get sharedFoldersHelp;

  /// No description provided for @addFolder.
  ///
  /// In en, this message translates to:
  /// **'Add a folder'**
  String get addFolder;

  /// No description provided for @botsAllowed.
  ///
  /// In en, this message translates to:
  /// **'Bots allowed'**
  String get botsAllowed;

  /// No description provided for @botsAllowedHelp.
  ///
  /// In en, this message translates to:
  /// **'Allowed bots use this computer as theirs.'**
  String get botsAllowedHelp;

  /// No description provided for @unpairComputer.
  ///
  /// In en, this message translates to:
  /// **'Stop using this computer and unpair it'**
  String get unpairComputer;

  /// No description provided for @botActingHere.
  ///
  /// In en, this message translates to:
  /// **'{bot} is working on this computer: {action}'**
  String botActingHere(String bot, String action);

  /// No description provided for @quickAsk.
  ///
  /// In en, this message translates to:
  /// **'Quick ask'**
  String get quickAsk;

  /// No description provided for @quickAskHint.
  ///
  /// In en, this message translates to:
  /// **'Ask a bot anything…'**
  String get quickAskHint;

  /// No description provided for @bot.
  ///
  /// In en, this message translates to:
  /// **'Bot'**
  String get bot;

  /// No description provided for @adminConsole.
  ///
  /// In en, this message translates to:
  /// **'Admin console'**
  String get adminConsole;

  /// No description provided for @adminOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get adminOverview;

  /// No description provided for @adminUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get adminUsers;

  /// No description provided for @adminWorkspaces.
  ///
  /// In en, this message translates to:
  /// **'Workspaces'**
  String get adminWorkspaces;

  /// No description provided for @adminServices.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get adminServices;

  /// No description provided for @notInstanceOwner.
  ///
  /// In en, this message translates to:
  /// **'Only the instance owner can open the admin console.'**
  String get notInstanceOwner;

  /// No description provided for @runs24h.
  ///
  /// In en, this message translates to:
  /// **'Runs (24 h)'**
  String get runs24h;

  /// No description provided for @failedRuns24h.
  ///
  /// In en, this message translates to:
  /// **'Failed runs (24 h)'**
  String get failedRuns24h;

  /// No description provided for @cost24h.
  ///
  /// In en, this message translates to:
  /// **'Spend (24 h)'**
  String get cost24h;

  /// No description provided for @computersRunning.
  ///
  /// In en, this message translates to:
  /// **'Computers running'**
  String get computersRunning;

  /// No description provided for @devicesOnline.
  ///
  /// In en, this message translates to:
  /// **'Personal computers online'**
  String get devicesOnline;

  /// No description provided for @editQuotas.
  ///
  /// In en, this message translates to:
  /// **'Edit quotas'**
  String get editQuotas;

  /// No description provided for @maxBots.
  ///
  /// In en, this message translates to:
  /// **'Max bots'**
  String get maxBots;

  /// No description provided for @monthlyUsd.
  ///
  /// In en, this message translates to:
  /// **'Monthly spend limit (USD)'**
  String get monthlyUsd;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Kasama {latest} is available (you run {current})'**
  String updateAvailable(String latest, String current);

  /// No description provided for @kasamaVersion.
  ///
  /// In en, this message translates to:
  /// **'Kasama {version}'**
  String kasamaVersion(String version);

  /// No description provided for @workspacesCount.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 workspace} other{{n} workspaces}}'**
  String workspacesCount(int n);

  /// No description provided for @lastSignIn.
  ///
  /// In en, this message translates to:
  /// **'signed in {when}'**
  String lastSignIn(String when);

  /// No description provided for @quotasFor.
  ///
  /// In en, this message translates to:
  /// **'Quotas for {name}'**
  String quotasFor(String name);

  /// No description provided for @membersCount.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 member} other{{n} members}}'**
  String membersCount(int n);

  /// No description provided for @botsCount.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 bot} other{{n} bots}}'**
  String botsCount(int n);

  /// No description provided for @cost30d.
  ///
  /// In en, this message translates to:
  /// **'{usd} in 30 days'**
  String cost30d(String usd);

  /// No description provided for @connectingToServer.
  ///
  /// In en, this message translates to:
  /// **'Connecting to Kasama…'**
  String get connectingToServer;

  /// No description provided for @cannotReachServer.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach your Kasama server'**
  String get cannotReachServer;

  /// No description provided for @cannotReachServerHelp.
  ///
  /// In en, this message translates to:
  /// **'Check your connection, or that the server at {url} is running.'**
  String cannotReachServerHelp(String url);

  /// No description provided for @upgradeTitle.
  ///
  /// In en, this message translates to:
  /// **'Upgrade your plan'**
  String get upgradeTitle;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @seePlans.
  ///
  /// In en, this message translates to:
  /// **'See plans'**
  String get seePlans;

  /// No description provided for @billing.
  ///
  /// In en, this message translates to:
  /// **'Billing'**
  String get billing;

  /// No description provided for @billingOffSelfHosted.
  ///
  /// In en, this message translates to:
  /// **'Billing is off on this server. Self-hosted Kasama has no limits.'**
  String get billingOffSelfHosted;

  /// No description provided for @restorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get restorePurchases;

  /// No description provided for @restoreStarted.
  ///
  /// In en, this message translates to:
  /// **'Checking your purchases…'**
  String get restoreStarted;

  /// No description provided for @plans.
  ///
  /// In en, this message translates to:
  /// **'Plans'**
  String get plans;

  /// No description provided for @currentPlan.
  ///
  /// In en, this message translates to:
  /// **'Current plan'**
  String get currentPlan;

  /// No description provided for @subscribeFor.
  ///
  /// In en, this message translates to:
  /// **'Subscribe for {price}'**
  String subscribeFor(String price);

  /// No description provided for @subscribeOnWeb.
  ///
  /// In en, this message translates to:
  /// **'Subscribe on the web'**
  String get subscribeOnWeb;

  /// No description provided for @credits.
  ///
  /// In en, this message translates to:
  /// **'Credits'**
  String get credits;

  /// No description provided for @limitBots.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 bot} other{{count} bots}}'**
  String limitBots(int count);

  /// No description provided for @limitComputerHours.
  ///
  /// In en, this message translates to:
  /// **'{hours} computer hours a month'**
  String limitComputerHours(int hours);

  /// No description provided for @limitCredits.
  ///
  /// In en, this message translates to:
  /// **'\${amount} credits a month'**
  String limitCredits(String amount);

  /// No description provided for @viaWeb.
  ///
  /// In en, this message translates to:
  /// **'Billed on the web'**
  String get viaWeb;

  /// No description provided for @viaAppStore.
  ///
  /// In en, this message translates to:
  /// **'Billed through the App Store'**
  String get viaAppStore;

  /// No description provided for @viaGooglePlay.
  ///
  /// In en, this message translates to:
  /// **'Billed through Google Play'**
  String get viaGooglePlay;

  /// No description provided for @yourPlan.
  ///
  /// In en, this message translates to:
  /// **'Your plan'**
  String get yourPlan;

  /// No description provided for @planEndsOn.
  ///
  /// In en, this message translates to:
  /// **'Ends on {date}'**
  String planEndsOn(String date);

  /// No description provided for @planRenewsOn.
  ///
  /// In en, this message translates to:
  /// **'Renews on {date}'**
  String planRenewsOn(String date);

  /// No description provided for @creditsBalance.
  ///
  /// In en, this message translates to:
  /// **'Credits: \${amount}'**
  String creditsBalance(String amount);

  /// No description provided for @manageSubscription.
  ///
  /// In en, this message translates to:
  /// **'Manage subscription'**
  String get manageSubscription;

  /// No description provided for @usageComputerHours.
  ///
  /// In en, this message translates to:
  /// **'Cloud computers: {hours} h'**
  String usageComputerHours(String hours);

  /// No description provided for @usageLiveViewMinutes.
  ///
  /// In en, this message translates to:
  /// **'Live view: {minutes} min'**
  String usageLiveViewMinutes(String minutes);

  /// No description provided for @usageTokens.
  ///
  /// In en, this message translates to:
  /// **'Model credits: {count} tokens'**
  String usageTokens(int count);

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get thisMonth;

  /// No description provided for @noBillableUsage.
  ///
  /// In en, this message translates to:
  /// **'No billable usage yet.'**
  String get noBillableUsage;

  /// No description provided for @cloudConnect.
  ///
  /// In en, this message translates to:
  /// **'Cloud Connect'**
  String get cloudConnect;

  /// No description provided for @cloudConnectHelp.
  ///
  /// In en, this message translates to:
  /// **'Let a self-hosted Kasama use cloud computers and model credits, billed to this workspace.'**
  String get cloudConnectHelp;

  /// No description provided for @cloudConnectNewKey.
  ///
  /// In en, this message translates to:
  /// **'New Cloud Connect key'**
  String get cloudConnectNewKey;

  /// No description provided for @cloudConnectKeyCreated.
  ///
  /// In en, this message translates to:
  /// **'Key created'**
  String get cloudConnectKeyCreated;

  /// No description provided for @cloudConnectKeyOnce.
  ///
  /// In en, this message translates to:
  /// **'Copy it now; it is shown only once. Set it on your server with KASAMA_CLOUD_URL.'**
  String get cloudConnectKeyOnce;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @revoke.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get revoke;

  /// No description provided for @instanceName.
  ///
  /// In en, this message translates to:
  /// **'Server name'**
  String get instanceName;

  /// No description provided for @server.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get server;

  /// No description provided for @serverAddress.
  ///
  /// In en, this message translates to:
  /// **'Server address'**
  String get serverAddress;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @changeServer.
  ///
  /// In en, this message translates to:
  /// **'Use a different server'**
  String get changeServer;

  /// No description provided for @serverIs.
  ///
  /// In en, this message translates to:
  /// **'Server: {host}'**
  String serverIs(String host);

  /// No description provided for @continueWithSso.
  ///
  /// In en, this message translates to:
  /// **'Continue with SSO'**
  String get continueWithSso;

  /// No description provided for @workEmail.
  ///
  /// In en, this message translates to:
  /// **'Work email'**
  String get workEmail;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @exportMyData.
  ///
  /// In en, this message translates to:
  /// **'Export my data'**
  String get exportMyData;

  /// No description provided for @exportMyDataHelp.
  ///
  /// In en, this message translates to:
  /// **'A ZIP of everything you can see: bots, chats, runs, memories and settings. Secrets and keys are never included.'**
  String get exportMyDataHelp;

  /// No description provided for @exportReady.
  ///
  /// In en, this message translates to:
  /// **'Export ready ({kb} KB)'**
  String exportReady(String kb);

  /// No description provided for @runHistoryRetention.
  ///
  /// In en, this message translates to:
  /// **'Keep run history for'**
  String get runHistoryRetention;

  /// No description provided for @runHistoryRetentionHelp.
  ///
  /// In en, this message translates to:
  /// **'Older run events are deleted automatically.'**
  String get runHistoryRetentionHelp;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String days(int count);

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete my account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountHelp.
  ///
  /// In en, this message translates to:
  /// **'Signs you out now and erases your data and the workspaces you solely own after a short grace period.'**
  String get deleteAccountHelp;

  /// No description provided for @deleteAccountQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get deleteAccountQuestion;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Workspaces where you are the only owner are deleted with your account, including their bots and computers. Type {email} to confirm.'**
  String deleteAccountConfirm(String email);

  /// No description provided for @accountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Account scheduled for deletion'**
  String get accountDeleted;

  /// No description provided for @accountDeletedBody.
  ///
  /// In en, this message translates to:
  /// **'You have been signed out. Your data will be erased on {date}.'**
  String accountDeletedBody(String date);

  /// No description provided for @selectBotHelp.
  ///
  /// In en, this message translates to:
  /// **'Pick a bot on the left, or create one to get started.'**
  String get selectBotHelp;

  /// No description provided for @toolShell.
  ///
  /// In en, this message translates to:
  /// **'Ran a command'**
  String get toolShell;

  /// No description provided for @toolFileRead.
  ///
  /// In en, this message translates to:
  /// **'Read a file'**
  String get toolFileRead;

  /// No description provided for @toolFileWrite.
  ///
  /// In en, this message translates to:
  /// **'Wrote a file'**
  String get toolFileWrite;

  /// No description provided for @toolFiles.
  ///
  /// In en, this message translates to:
  /// **'Worked with files'**
  String get toolFiles;

  /// No description provided for @toolBrowser.
  ///
  /// In en, this message translates to:
  /// **'Used the browser'**
  String get toolBrowser;

  /// No description provided for @toolSearch.
  ///
  /// In en, this message translates to:
  /// **'Searched the web'**
  String get toolSearch;

  /// No description provided for @toolMemory.
  ///
  /// In en, this message translates to:
  /// **'Checked memory'**
  String get toolMemory;

  /// No description provided for @toolSkill.
  ///
  /// In en, this message translates to:
  /// **'Used a skill'**
  String get toolSkill;

  /// No description provided for @toolCheckpoint.
  ///
  /// In en, this message translates to:
  /// **'Saved a checkpoint'**
  String get toolCheckpoint;

  /// No description provided for @toolDesktop.
  ///
  /// In en, this message translates to:
  /// **'Used the desktop'**
  String get toolDesktop;

  /// No description provided for @toolDelegate.
  ///
  /// In en, this message translates to:
  /// **'Asked another bot'**
  String get toolDelegate;

  /// No description provided for @toolOther.
  ///
  /// In en, this message translates to:
  /// **'Used {tool}'**
  String toolOther(String tool);

  /// No description provided for @toolSteps.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 step} other{{count} steps}}'**
  String toolSteps(int count);

  /// No description provided for @showMoreSteps.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Show 1 earlier step} other{Show {count} earlier steps}}'**
  String showMoreSteps(int count);

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @jumpToLatest.
  ///
  /// In en, this message translates to:
  /// **'Jump to latest'**
  String get jumpToLatest;

  /// No description provided for @chatEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'{bot} has its own computer, memory and tools. Ask for something you want done.'**
  String chatEmptySubtitle(String bot);

  /// No description provided for @suggestResearch.
  ///
  /// In en, this message translates to:
  /// **'Research a topic and write me a short summary'**
  String get suggestResearch;

  /// No description provided for @suggestFiles.
  ///
  /// In en, this message translates to:
  /// **'Make a project folder with a to-do list in my workspace'**
  String get suggestFiles;

  /// No description provided for @suggestWebsite.
  ///
  /// In en, this message translates to:
  /// **'Check a website and tell me what\'s new'**
  String get suggestWebsite;

  /// No description provided for @suggestCapabilities.
  ///
  /// In en, this message translates to:
  /// **'What can you do on your computer?'**
  String get suggestCapabilities;

  /// No description provided for @showComputer.
  ///
  /// In en, this message translates to:
  /// **'Show computer'**
  String get showComputer;

  /// No description provided for @hideComputer.
  ///
  /// In en, this message translates to:
  /// **'Hide computer'**
  String get hideComputer;

  /// No description provided for @moreActions.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreActions;

  /// No description provided for @noConversations.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get noConversations;

  /// No description provided for @untitledChat.
  ///
  /// In en, this message translates to:
  /// **'New conversation'**
  String get untitledChat;

  /// No description provided for @listening.
  ///
  /// In en, this message translates to:
  /// **'Listening…'**
  String get listening;

  /// No description provided for @orLabel.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orLabel;

  /// No description provided for @signInTagline.
  ///
  /// In en, this message translates to:
  /// **'Your AI teammates, each with its own computer, memory and tools.'**
  String get signInTagline;

  /// No description provided for @noBotsHelp.
  ///
  /// In en, this message translates to:
  /// **'A bot is a teammate with its own computer. Create one to start chatting.'**
  String get noBotsHelp;

  /// No description provided for @newBotSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A teammate with its own computer and memory.'**
  String get newBotSubtitle;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @settingsBotsSection.
  ///
  /// In en, this message translates to:
  /// **'What your bots can use'**
  String get settingsBotsSection;

  /// No description provided for @settingsMoreSection.
  ///
  /// In en, this message translates to:
  /// **'Privacy and more'**
  String get settingsMoreSection;

  /// No description provided for @modelKeysHelp.
  ///
  /// In en, this message translates to:
  /// **'OpenRouter, OpenAI, Anthropic, Google, xAI or your own server'**
  String get modelKeysHelp;

  /// No description provided for @signOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'You can sign back in any time; your bots keep working.'**
  String get signOutConfirm;

  /// No description provided for @roleOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get roleOwner;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get roleAdmin;

  /// No description provided for @roleMember.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get roleMember;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @accentColor.
  ///
  /// In en, this message translates to:
  /// **'Accent color'**
  String get accentColor;

  /// No description provided for @noApprovalsHelp.
  ///
  /// In en, this message translates to:
  /// **'When a bot wants to do something risky, it asks here first.'**
  String get noApprovalsHelp;

  /// No description provided for @createWorkspaceBody.
  ///
  /// In en, this message translates to:
  /// **'A workspace holds your bots, their computers and the people you work with.'**
  String get createWorkspaceBody;

  /// No description provided for @workspaceNameHint.
  ///
  /// In en, this message translates to:
  /// **'My team'**
  String get workspaceNameHint;

  /// No description provided for @orJoinWithCode.
  ///
  /// In en, this message translates to:
  /// **'or join with an invite code'**
  String get orJoinWithCode;

  /// No description provided for @getOpenRouterKey.
  ///
  /// In en, this message translates to:
  /// **'Get an OpenRouter key'**
  String get getOpenRouterKey;

  /// No description provided for @createFirstBotBody.
  ///
  /// In en, this message translates to:
  /// **'Give it a name and a model. You can change both later.'**
  String get createFirstBotBody;

  /// No description provided for @stepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}'**
  String stepOf(int step, int total);

  /// No description provided for @providerHintOpenRouter.
  ///
  /// In en, this message translates to:
  /// **'recommended'**
  String get providerHintOpenRouter;

  /// No description provided for @providerHintCompatible.
  ///
  /// In en, this message translates to:
  /// **'Ollama, LM Studio, vLLM'**
  String get providerHintCompatible;

  /// No description provided for @providerHintImages.
  ///
  /// In en, this message translates to:
  /// **'images'**
  String get providerHintImages;

  /// No description provided for @providerHintSearch.
  ///
  /// In en, this message translates to:
  /// **'web search'**
  String get providerHintSearch;

  /// No description provided for @providerHintVoice.
  ///
  /// In en, this message translates to:
  /// **'voice'**
  String get providerHintVoice;

  /// No description provided for @noRoutinesHelp.
  ///
  /// In en, this message translates to:
  /// **'A routine is work a bot does later on its own: once at a time you pick, on a schedule, or when a webhook arrives.'**
  String get noRoutinesHelp;

  /// No description provided for @routineOnce.
  ///
  /// In en, this message translates to:
  /// **'Once'**
  String get routineOnce;

  /// No description provided for @lastRun.
  ///
  /// In en, this message translates to:
  /// **'Last: {when}'**
  String lastRun(String when);

  /// No description provided for @routineOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get routineOff;

  /// No description provided for @deleteRoutineTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete “{name}”?'**
  String deleteRoutineTitle(String name);

  /// No description provided for @deleteRoutineBody.
  ///
  /// In en, this message translates to:
  /// **'It won\'t run again. Results it already posted stay in their conversation.'**
  String get deleteRoutineBody;

  /// No description provided for @triggerOnce.
  ///
  /// In en, this message translates to:
  /// **'Once'**
  String get triggerOnce;

  /// No description provided for @inMinutes.
  ///
  /// In en, this message translates to:
  /// **'In {n} min'**
  String inMinutes(int n);

  /// No description provided for @inHours.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{In 1 hour} other{In {n} hours}}'**
  String inHours(int n);

  /// No description provided for @tomorrowAt9.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow 9:00'**
  String get tomorrowAt9;

  /// No description provided for @integrationNeedsName.
  ///
  /// In en, this message translates to:
  /// **'Give it a name with at least one letter.'**
  String get integrationNeedsName;

  /// No description provided for @integrationNeedsField.
  ///
  /// In en, this message translates to:
  /// **'Fill in {field} to save.'**
  String integrationNeedsField(String field);

  /// No description provided for @integrationSavedAs.
  ///
  /// In en, this message translates to:
  /// **'Saved as {name}'**
  String integrationSavedAs(String name);

  /// No description provided for @integrationUrlInvalid.
  ///
  /// In en, this message translates to:
  /// **'Use a full address starting with https://'**
  String get integrationUrlInvalid;

  /// No description provided for @openFile.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openFile;

  /// No description provided for @saveFile.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveFile;

  /// No description provided for @shareFile.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareFile;

  /// No description provided for @savedFile.
  ///
  /// In en, this message translates to:
  /// **'Saved {name}'**
  String savedFile(String name);

  /// No description provided for @noAppToOpen.
  ///
  /// In en, this message translates to:
  /// **'No app on this device opens {name}. Save it instead.'**
  String noAppToOpen(String name);

  /// No description provided for @previewUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No preview for this kind of file. Open or save it to view it.'**
  String get previewUnavailable;

  /// No description provided for @openFileInChat.
  ///
  /// In en, this message translates to:
  /// **'Open file'**
  String get openFileInChat;

  /// No description provided for @attach.
  ///
  /// In en, this message translates to:
  /// **'Attach'**
  String get attach;

  /// No description provided for @attachFiles.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get attachFiles;

  /// No description provided for @attachPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photo library'**
  String get attachPhotos;

  /// No description provided for @attachCamera.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get attachCamera;

  /// No description provided for @dropToAttach.
  ///
  /// In en, this message translates to:
  /// **'Drop files to attach'**
  String get dropToAttach;

  /// No description provided for @uploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t upload {name}'**
  String uploadFailed(String name);

  /// No description provided for @removeAttachment.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeAttachment;

  /// No description provided for @noComputerForFiles.
  ///
  /// In en, this message translates to:
  /// **'This bot has no computer to keep files on.'**
  String get noComputerForFiles;

  /// No description provided for @fileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'{name} is over 25 MB, too large to attach.'**
  String fileTooLarge(String name);

  /// No description provided for @toolRoutineCreate.
  ///
  /// In en, this message translates to:
  /// **'Scheduled a routine'**
  String get toolRoutineCreate;

  /// No description provided for @toolRoutineDelete.
  ///
  /// In en, this message translates to:
  /// **'Deleted a routine'**
  String get toolRoutineDelete;

  /// No description provided for @toolRoutines.
  ///
  /// In en, this message translates to:
  /// **'Checked routines'**
  String get toolRoutines;

  /// No description provided for @toolTasks.
  ///
  /// In en, this message translates to:
  /// **'Updated the task board'**
  String get toolTasks;

  /// No description provided for @toolNotify.
  ///
  /// In en, this message translates to:
  /// **'Sent you a notification'**
  String get toolNotify;

  /// No description provided for @toolHttp.
  ///
  /// In en, this message translates to:
  /// **'Called a web API'**
  String get toolHttp;

  /// No description provided for @toolMedia.
  ///
  /// In en, this message translates to:
  /// **'Made an image'**
  String get toolMedia;

  /// No description provided for @toolTakeover.
  ///
  /// In en, this message translates to:
  /// **'Asked you to take over'**
  String get toolTakeover;

  /// No description provided for @secretsHelp.
  ///
  /// In en, this message translates to:
  /// **'Bots put a secret in requests by its name. It\'s only sent to the hosts you allow and the model never sees it.'**
  String get secretsHelp;

  /// No description provided for @deleteSecretTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String deleteSecretTitle(String name);

  /// No description provided for @deleteSecretBody.
  ///
  /// In en, this message translates to:
  /// **'Bots that use it will stop being able to reach that service.'**
  String get deleteSecretBody;

  /// No description provided for @hide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hide;

  /// No description provided for @show.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get show;

  /// No description provided for @deleteMemoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this memory?'**
  String get deleteMemoryTitle;

  /// No description provided for @noMemoriesHelp.
  ///
  /// In en, this message translates to:
  /// **'As you chat, the bot keeps what matters: facts, preferences and summaries of past work.'**
  String get noMemoriesHelp;

  /// No description provided for @memoryHelp.
  ///
  /// In en, this message translates to:
  /// **'Pinned memories are always in the bot\'s context. Edit anything that\'s wrong; deleted memories are gone for good.'**
  String get memoryHelp;

  /// No description provided for @memoryFact.
  ///
  /// In en, this message translates to:
  /// **'Fact'**
  String get memoryFact;

  /// No description provided for @memoryPreference.
  ///
  /// In en, this message translates to:
  /// **'Preference'**
  String get memoryPreference;

  /// No description provided for @memorySummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get memorySummary;

  /// No description provided for @memoryEpisode.
  ///
  /// In en, this message translates to:
  /// **'Episode'**
  String get memoryEpisode;

  /// No description provided for @pinned.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get pinned;

  /// No description provided for @editMemory.
  ///
  /// In en, this message translates to:
  /// **'Edit memory'**
  String get editMemory;

  /// No description provided for @editMemoryHelp.
  ///
  /// In en, this message translates to:
  /// **'The bot uses this the next time it\'s relevant.'**
  String get editMemoryHelp;

  /// No description provided for @modelKeysIntro.
  ///
  /// In en, this message translates to:
  /// **'Bots think with your own model provider keys. Keys are stored encrypted and never shown again.'**
  String get modelKeysIntro;

  /// No description provided for @yourKeys.
  ///
  /// In en, this message translates to:
  /// **'Your keys'**
  String get yourKeys;

  /// No description provided for @keyWorking.
  ///
  /// In en, this message translates to:
  /// **'Working'**
  String get keyWorking;

  /// No description provided for @keyFailing.
  ///
  /// In en, this message translates to:
  /// **'Failing'**
  String get keyFailing;

  /// No description provided for @keyUntested.
  ///
  /// In en, this message translates to:
  /// **'Not tested'**
  String get keyUntested;

  /// No description provided for @skillsHelp.
  ///
  /// In en, this message translates to:
  /// **'A skill is a set of instructions a bot loads when a task calls for it, like your house style for reports.'**
  String get skillsHelp;

  /// No description provided for @deleteSkillTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete the skill “{name}”?'**
  String deleteSkillTitle(String name);

  /// No description provided for @editSkill.
  ///
  /// In en, this message translates to:
  /// **'Edit skill'**
  String get editSkill;

  /// No description provided for @deleteSkill.
  ///
  /// In en, this message translates to:
  /// **'Delete skill'**
  String get deleteSkill;

  /// No description provided for @skillDescriptionHelp.
  ///
  /// In en, this message translates to:
  /// **'Bots read this to decide when the skill applies.'**
  String get skillDescriptionHelp;

  /// No description provided for @skillBodyHint.
  ///
  /// In en, this message translates to:
  /// **'# Steps\n1. …'**
  String get skillBodyHint;

  /// No description provided for @computersHelp.
  ///
  /// In en, this message translates to:
  /// **'Each bot works on a computer: the team computer everyone shares, or a private one. Files stay on it between chats.'**
  String get computersHelp;

  /// No description provided for @thisDevice.
  ///
  /// In en, this message translates to:
  /// **'This device'**
  String get thisDevice;

  /// No description provided for @renameComputer.
  ///
  /// In en, this message translates to:
  /// **'Rename computer'**
  String get renameComputer;

  /// No description provided for @deleteComputerTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String deleteComputerTitle(String name);

  /// No description provided for @privacyIntro.
  ///
  /// In en, this message translates to:
  /// **'Your chats, memories and files belong to you. Export them any time, or delete your account.'**
  String get privacyIntro;

  /// No description provided for @yourData.
  ///
  /// In en, this message translates to:
  /// **'Your data'**
  String get yourData;

  /// No description provided for @dangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger zone'**
  String get dangerZone;

  /// No description provided for @quotasHelp.
  ///
  /// In en, this message translates to:
  /// **'Leave a field empty for no limit.'**
  String get quotasHelp;

  /// No description provided for @serviceOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get serviceOff;

  /// No description provided for @serviceDown.
  ///
  /// In en, this message translates to:
  /// **'Down'**
  String get serviceDown;

  /// No description provided for @serviceOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get serviceOk;

  /// No description provided for @inviteMemberHelp.
  ///
  /// In en, this message translates to:
  /// **'They\'ll get an email with a link to join this workspace.'**
  String get inviteMemberHelp;

  /// No description provided for @sendInvite.
  ///
  /// In en, this message translates to:
  /// **'Send invite'**
  String get sendInvite;

  /// No description provided for @inviteReady.
  ///
  /// In en, this message translates to:
  /// **'Invite ready'**
  String get inviteReady;

  /// No description provided for @inviteCodeHelp.
  ///
  /// In en, this message translates to:
  /// **'Email isn\'t set up on this server, so share this code with {email}. They paste it when joining.'**
  String inviteCodeHelp(String email);

  /// No description provided for @copyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get copyCode;

  /// No description provided for @thinking0.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get thinking0;

  /// No description provided for @computerAndTools.
  ///
  /// In en, this message translates to:
  /// **'Computer and tools'**
  String get computerAndTools;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @autonomyAskAlwaysHelp.
  ///
  /// In en, this message translates to:
  /// **'Checks with you before every action that changes something.'**
  String get autonomyAskAlwaysHelp;

  /// No description provided for @autonomyAskRiskyHelp.
  ///
  /// In en, this message translates to:
  /// **'Works on its own, but asks before anything risky, like deleting files or spending money.'**
  String get autonomyAskRiskyHelp;

  /// No description provided for @autonomyAutonomousHelp.
  ///
  /// In en, this message translates to:
  /// **'Acts without asking. Best for routines you trust.'**
  String get autonomyAutonomousHelp;

  /// No description provided for @usageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Model spend this month'**
  String get usageSubtitle;

  /// No description provided for @skillsRowHelp.
  ///
  /// In en, this message translates to:
  /// **'Instructions bots load when a task needs them'**
  String get skillsRowHelp;

  /// No description provided for @integrationsRowHelp.
  ///
  /// In en, this message translates to:
  /// **'MCP servers and connected apps'**
  String get integrationsRowHelp;

  /// No description provided for @secretsRowHelp.
  ///
  /// In en, this message translates to:
  /// **'Tokens and passwords, sent only where you allow'**
  String get secretsRowHelp;

  /// No description provided for @computersRowHelp.
  ///
  /// In en, this message translates to:
  /// **'The team computer and private ones'**
  String get computersRowHelp;

  /// No description provided for @companionRowHelp.
  ///
  /// In en, this message translates to:
  /// **'Let bots use this device\'s apps and files'**
  String get companionRowHelp;

  /// No description provided for @privacyRowHelp.
  ///
  /// In en, this message translates to:
  /// **'Export your data or delete your account'**
  String get privacyRowHelp;

  /// No description provided for @adminRowHelp.
  ///
  /// In en, this message translates to:
  /// **'Users, workspaces, quotas and services'**
  String get adminRowHelp;

  /// No description provided for @noIntegrationsTitle.
  ///
  /// In en, this message translates to:
  /// **'No integrations yet'**
  String get noIntegrationsTitle;

  /// No description provided for @integrationsHelp.
  ///
  /// In en, this message translates to:
  /// **'Integrations give bots more tools: an MCP server, an OpenAPI source, Composio or Pipedream. Each tool is named after its integration.'**
  String get integrationsHelp;

  /// No description provided for @botIntegrationsHelp.
  ///
  /// In en, this message translates to:
  /// **'Turn on the integrations this bot may use. Its tools show up the next time it runs.'**
  String get botIntegrationsHelp;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @noRunsHelp.
  ///
  /// In en, this message translates to:
  /// **'Each time this bot works, from a chat, a routine or a webhook, the run shows up here with what it did and what it cost.'**
  String get noRunsHelp;

  /// No description provided for @runCompleted.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get runCompleted;

  /// No description provided for @runWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get runWaiting;

  /// No description provided for @runWorking.
  ///
  /// In en, this message translates to:
  /// **'Working'**
  String get runWorking;

  /// No description provided for @triggerChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get triggerChat;

  /// No description provided for @triggerRoutine.
  ///
  /// In en, this message translates to:
  /// **'Routine'**
  String get triggerRoutine;

  /// No description provided for @noEventsForFilter.
  ///
  /// In en, this message translates to:
  /// **'Nothing of this kind in this run.'**
  String get noEventsForFilter;

  /// No description provided for @runStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get runStatusFailed;

  /// No description provided for @runStatusStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get runStatusStopped;

  /// No description provided for @quickAskIntro.
  ///
  /// In en, this message translates to:
  /// **'Send a quick request. It starts a new chat with the bot you pick.'**
  String get quickAskIntro;

  /// No description provided for @quickAskHintBot.
  ///
  /// In en, this message translates to:
  /// **'What should {bot} do?'**
  String quickAskHintBot(String bot);

  /// No description provided for @noNotificationsHelp.
  ///
  /// In en, this message translates to:
  /// **'Routine results, budget alerts and requests from your bots show up here.'**
  String get noNotificationsHelp;

  /// No description provided for @noTasksHelp.
  ///
  /// In en, this message translates to:
  /// **'Bots and people add tasks here to hand work to each other.'**
  String get noTasksHelp;

  /// No description provided for @stateProvisioning.
  ///
  /// In en, this message translates to:
  /// **'Setting up'**
  String get stateProvisioning;

  /// No description provided for @stateStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting'**
  String get stateStarting;

  /// No description provided for @stateRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get stateRunning;

  /// No description provided for @stateIdle.
  ///
  /// In en, this message translates to:
  /// **'Idle'**
  String get stateIdle;

  /// No description provided for @stateSleeping.
  ///
  /// In en, this message translates to:
  /// **'Asleep'**
  String get stateSleeping;

  /// No description provided for @stateStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get stateStopped;

  /// No description provided for @stateError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get stateError;

  /// No description provided for @terminalHelp.
  ///
  /// In en, this message translates to:
  /// **'A shell on this computer. Bots use the same one, so you can see and fix what they did.'**
  String get terminalHelp;

  /// No description provided for @up.
  ///
  /// In en, this message translates to:
  /// **'Up'**
  String get up;

  /// No description provided for @emptyFolderHelp.
  ///
  /// In en, this message translates to:
  /// **'Files your bots make, and files you upload, show up here.'**
  String get emptyFolderHelp;

  /// No description provided for @noCheckpointsTitle.
  ///
  /// In en, this message translates to:
  /// **'No checkpoints yet'**
  String get noCheckpointsTitle;

  /// No description provided for @checkpointsHelp.
  ///
  /// In en, this message translates to:
  /// **'A checkpoint saves this computer before a risky change. Restoring puts its files back as they were.'**
  String get checkpointsHelp;

  /// No description provided for @deleteFileTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String deleteFileTitle(String name);

  /// No description provided for @botComputerAuto.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get botComputerAuto;

  /// No description provided for @botComputerHelp.
  ///
  /// In en, this message translates to:
  /// **'Where this bot runs commands, browses and keeps its files.'**
  String get botComputerHelp;

  /// No description provided for @billingOffTitle.
  ///
  /// In en, this message translates to:
  /// **'No limits here'**
  String get billingOffTitle;

  /// No description provided for @revokeKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Revoke the key for {name}?'**
  String revokeKeyTitle(String name);

  /// No description provided for @revokeKeyBody.
  ///
  /// In en, this message translates to:
  /// **'That server stops using cloud computers and credits right away.'**
  String get revokeKeyBody;

  /// No description provided for @handBackHelp.
  ///
  /// In en, this message translates to:
  /// **'The bot picks up where you left off. Tell it what you did, if it helps.'**
  String get handBackHelp;

  /// No description provided for @serverHelp.
  ///
  /// In en, this message translates to:
  /// **'Use your own Kasama server. Enter the address you or your admin set up.'**
  String get serverHelp;

  /// No description provided for @ssoHelp.
  ///
  /// In en, this message translates to:
  /// **'Enter your work email and we\'ll send you to your company\'s sign-in page.'**
  String get ssoHelp;

  /// No description provided for @colorScheme.
  ///
  /// In en, this message translates to:
  /// **'Color scheme'**
  String get colorScheme;

  /// No description provided for @searchThemes.
  ///
  /// In en, this message translates to:
  /// **'Search schemes'**
  String get searchThemes;

  /// No description provided for @noThemesFound.
  ///
  /// In en, this message translates to:
  /// **'No schemes match.'**
  String get noThemesFound;

  /// No description provided for @familyAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get familyAll;

  /// No description provided for @familyPurple.
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get familyPurple;

  /// No description provided for @familyBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get familyBlue;

  /// No description provided for @familyTeal.
  ///
  /// In en, this message translates to:
  /// **'Teal'**
  String get familyTeal;

  /// No description provided for @familyGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get familyGreen;

  /// No description provided for @familyWarm.
  ///
  /// In en, this message translates to:
  /// **'Warm'**
  String get familyWarm;

  /// No description provided for @familyRed.
  ///
  /// In en, this message translates to:
  /// **'Red & pink'**
  String get familyRed;

  /// No description provided for @familyNeutral.
  ///
  /// In en, this message translates to:
  /// **'Neutral'**
  String get familyNeutral;

  /// No description provided for @background.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get background;

  /// No description provided for @backgroundPattern.
  ///
  /// In en, this message translates to:
  /// **'Pattern'**
  String get backgroundPattern;

  /// No description provided for @backgroundColors.
  ///
  /// In en, this message translates to:
  /// **'Colors'**
  String get backgroundColors;

  /// No description provided for @backgroundThemeColors.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get backgroundThemeColors;

  /// No description provided for @patternStrength.
  ///
  /// In en, this message translates to:
  /// **'Pattern strength'**
  String get patternStrength;

  /// No description provided for @wallpaperEverywhere.
  ///
  /// In en, this message translates to:
  /// **'Show on every screen'**
  String get wallpaperEverywhere;

  /// No description provided for @wallpaperEverywhereHelp.
  ///
  /// In en, this message translates to:
  /// **'Turn off to keep it behind chats only.'**
  String get wallpaperEverywhereHelp;

  /// No description provided for @resetBackground.
  ///
  /// In en, this message translates to:
  /// **'Reset to default'**
  String get resetBackground;

  /// No description provided for @chatsOnly.
  ///
  /// In en, this message translates to:
  /// **'Chats only'**
  String get chatsOnly;

  /// No description provided for @copyMessage.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copyMessage;

  /// No description provided for @selectText.
  ///
  /// In en, this message translates to:
  /// **'Select text'**
  String get selectText;

  /// No description provided for @shareMessage.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareMessage;

  /// No description provided for @messageCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get messageCopied;

  /// No description provided for @botUiBroken.
  ///
  /// In en, this message translates to:
  /// **'This part of the reply couldn\'t be shown.'**
  String get botUiBroken;

  /// No description provided for @botUiSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get botUiSent;

  /// Label above the picker for a bot's avatar (initials or a cloud mascot)
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get botIcon;

  /// Avatar choice that shows the bot's initials instead of a mascot
  ///
  /// In en, this message translates to:
  /// **'Initials'**
  String get botIconInitials;

  /// No description provided for @errorDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'What went wrong'**
  String get errorDetailsTitle;

  /// No description provided for @exportLabel.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get exportLabel;

  /// No description provided for @openTimeline.
  ///
  /// In en, this message translates to:
  /// **'Open run timeline'**
  String get openTimeline;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @themes.
  ///
  /// In en, this message translates to:
  /// **'Themes'**
  String get themes;

  /// No description provided for @themesHelp.
  ///
  /// In en, this message translates to:
  /// **'A theme sets the color scheme, fonts and background together. Change any of them afterwards and save the result as your own.'**
  String get themesHelp;

  /// No description provided for @themePresets.
  ///
  /// In en, this message translates to:
  /// **'Presets'**
  String get themePresets;

  /// No description provided for @myThemes.
  ///
  /// In en, this message translates to:
  /// **'Your themes'**
  String get myThemes;

  /// No description provided for @saveTheme.
  ///
  /// In en, this message translates to:
  /// **'Save current look'**
  String get saveTheme;

  /// No description provided for @themeName.
  ///
  /// In en, this message translates to:
  /// **'Theme name'**
  String get themeName;

  /// No description provided for @importTheme.
  ///
  /// In en, this message translates to:
  /// **'Import a theme'**
  String get importTheme;

  /// No description provided for @themeCode.
  ///
  /// In en, this message translates to:
  /// **'Theme code'**
  String get themeCode;

  /// No description provided for @themeCodeHelp.
  ///
  /// In en, this message translates to:
  /// **'Paste a code someone shared with you. It starts with kasama-theme:'**
  String get themeCodeHelp;

  /// No description provided for @invalidThemeCode.
  ///
  /// In en, this message translates to:
  /// **'That isn\'t a Kasama theme code.'**
  String get invalidThemeCode;

  /// No description provided for @themeImported.
  ///
  /// In en, this message translates to:
  /// **'Added {name} to your themes'**
  String themeImported(String name);

  /// No description provided for @themeCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Theme code copied. Anyone can paste it into Themes → Import.'**
  String get themeCodeCopied;

  /// No description provided for @shareTheme.
  ///
  /// In en, this message translates to:
  /// **'Share code'**
  String get shareTheme;

  /// No description provided for @deleteThemeTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String deleteThemeTitle(String name);

  /// No description provided for @currentLook.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get currentLook;

  /// No description provided for @fonts.
  ///
  /// In en, this message translates to:
  /// **'Fonts'**
  String get fonts;

  /// No description provided for @headingFont.
  ///
  /// In en, this message translates to:
  /// **'Headings'**
  String get headingFont;

  /// No description provided for @bodyFont.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get bodyFont;

  /// No description provided for @fontsHelp.
  ///
  /// In en, this message translates to:
  /// **'Google Sans and Noto Serif come with the app and work offline. Other Google Fonts download the first time you pick them.'**
  String get fontsHelp;

  /// No description provided for @searchFonts.
  ///
  /// In en, this message translates to:
  /// **'Search all Google Fonts'**
  String get searchFonts;

  /// No description provided for @suggestedFonts.
  ///
  /// In en, this message translates to:
  /// **'Suggested'**
  String get suggestedFonts;

  /// No description provided for @allFonts.
  ///
  /// In en, this message translates to:
  /// **'All Google Fonts'**
  String get allFonts;

  /// No description provided for @noFontsFound.
  ///
  /// In en, this message translates to:
  /// **'No font with that name'**
  String get noFontsFound;

  /// No description provided for @resetFonts.
  ///
  /// In en, this message translates to:
  /// **'Use the defaults'**
  String get resetFonts;

  /// No description provided for @fontSample.
  ///
  /// In en, this message translates to:
  /// **'Your bots, working together with you.'**
  String get fontSample;

  /// No description provided for @backgroundPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get backgroundPhoto;

  /// No description provided for @yourPhoto.
  ///
  /// In en, this message translates to:
  /// **'Your photo'**
  String get yourPhoto;

  /// No description provided for @browsePhotos.
  ///
  /// In en, this message translates to:
  /// **'Browse photos'**
  String get browsePhotos;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get removePhoto;

  /// No description provided for @photoBlur.
  ///
  /// In en, this message translates to:
  /// **'Blur'**
  String get photoBlur;

  /// No description provided for @photoDim.
  ///
  /// In en, this message translates to:
  /// **'Dim'**
  String get photoDim;

  /// No description provided for @photoBy.
  ///
  /// In en, this message translates to:
  /// **'Photo by {name} on Unsplash'**
  String photoBy(String name);

  /// No description provided for @searchPhotos.
  ///
  /// In en, this message translates to:
  /// **'Search photos'**
  String get searchPhotos;

  /// No description provided for @photosUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load photos.'**
  String get photosUnavailable;

  /// No description provided for @noPhotos.
  ///
  /// In en, this message translates to:
  /// **'No photos found'**
  String get noPhotos;

  /// No description provided for @photoHelp.
  ///
  /// In en, this message translates to:
  /// **'A photo goes under the doodles. Blur and dim keep text readable on top.'**
  String get photoHelp;

  /// No description provided for @periodToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get periodToday;

  /// No description provided for @periodWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get periodWeek;

  /// No description provided for @periodYear.
  ///
  /// In en, this message translates to:
  /// **'This year'**
  String get periodYear;

  /// No description provided for @totalSpend.
  ///
  /// In en, this message translates to:
  /// **'Spend'**
  String get totalSpend;

  /// No description provided for @tokensIn.
  ///
  /// In en, this message translates to:
  /// **'Tokens in'**
  String get tokensIn;

  /// No description provided for @tokensOut.
  ///
  /// In en, this message translates to:
  /// **'Tokens out'**
  String get tokensOut;

  /// No description provided for @runsLabel.
  ///
  /// In en, this message translates to:
  /// **'Runs'**
  String get runsLabel;

  /// No description provided for @spendByDay.
  ///
  /// In en, this message translates to:
  /// **'Spend by day'**
  String get spendByDay;

  /// No description provided for @byBot.
  ///
  /// In en, this message translates to:
  /// **'By bot'**
  String get byBot;

  /// No description provided for @byModel.
  ///
  /// In en, this message translates to:
  /// **'By model'**
  String get byModel;

  /// No description provided for @everythingMetered.
  ///
  /// In en, this message translates to:
  /// **'Everything metered'**
  String get everythingMetered;

  /// No description provided for @exportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get exportCsv;

  /// No description provided for @exportJson.
  ///
  /// In en, this message translates to:
  /// **'Export JSON'**
  String get exportJson;

  /// No description provided for @askBotAboutUsage.
  ///
  /// In en, this message translates to:
  /// **'Ask a bot about this'**
  String get askBotAboutUsage;

  /// No description provided for @noUsageYet.
  ///
  /// In en, this message translates to:
  /// **'No usage in this period yet.'**
  String get noUsageYet;

  /// No description provided for @otherModel.
  ///
  /// In en, this message translates to:
  /// **'Computers and other'**
  String get otherModel;

  /// No description provided for @deletedBot.
  ///
  /// In en, this message translates to:
  /// **'Not tied to a bot'**
  String get deletedBot;

  /// No description provided for @usageHelp.
  ///
  /// In en, this message translates to:
  /// **'Costs are estimates from token counts and published prices. Your model provider\'s bill is the final word.'**
  String get usageHelp;

  /// No description provided for @usageAskPrompt.
  ///
  /// In en, this message translates to:
  /// **'Here is my Kasama usage for {period}. Help me understand where the money goes and how I could spend less. You can also check live numbers with your usage tool.\n\n{summary}'**
  String usageAskPrompt(String period, String summary);

  /// No description provided for @kindTokensIn.
  ///
  /// In en, this message translates to:
  /// **'Model input'**
  String get kindTokensIn;

  /// No description provided for @kindTokensOut.
  ///
  /// In en, this message translates to:
  /// **'Model output'**
  String get kindTokensOut;

  /// No description provided for @kindComputer.
  ///
  /// In en, this message translates to:
  /// **'Cloud computer time'**
  String get kindComputer;

  /// No description provided for @kindStream.
  ///
  /// In en, this message translates to:
  /// **'Live view'**
  String get kindStream;

  /// No description provided for @kindTts.
  ///
  /// In en, this message translates to:
  /// **'Read aloud'**
  String get kindTts;

  /// No description provided for @personaWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get personaWork;

  /// No description provided for @personaResearch.
  ///
  /// In en, this message translates to:
  /// **'Research'**
  String get personaResearch;

  /// No description provided for @personaBuild.
  ///
  /// In en, this message translates to:
  /// **'Build'**
  String get personaBuild;

  /// No description provided for @personaCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get personaCreate;

  /// No description provided for @personaLife.
  ///
  /// In en, this message translates to:
  /// **'Life'**
  String get personaLife;

  /// No description provided for @personaOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get personaOther;

  /// No description provided for @blankBotHelp.
  ///
  /// In en, this message translates to:
  /// **'Start from scratch and write your own instructions.'**
  String get blankBotHelp;

  /// No description provided for @browse.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get browse;

  /// No description provided for @choosePersona.
  ///
  /// In en, this message translates to:
  /// **'Choose a persona'**
  String get choosePersona;

  /// No description provided for @choosePersonaHelp.
  ///
  /// In en, this message translates to:
  /// **'Each one comes with instructions, a look, and sometimes skills and routines. You can change anything afterwards.'**
  String get choosePersonaHelp;

  /// No description provided for @searchPersonas.
  ///
  /// In en, this message translates to:
  /// **'Search personas'**
  String get searchPersonas;

  /// No description provided for @noPersonasFound.
  ///
  /// In en, this message translates to:
  /// **'No persona matches that'**
  String get noPersonasFound;

  /// No description provided for @previewPersona.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get previewPersona;

  /// No description provided for @personaInstructions.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get personaInstructions;

  /// No description provided for @personaTryAsking.
  ///
  /// In en, this message translates to:
  /// **'Try asking'**
  String get personaTryAsking;

  /// No description provided for @usePersona.
  ///
  /// In en, this message translates to:
  /// **'Use {name}'**
  String usePersona(String name);

  /// No description provided for @loadPersona.
  ///
  /// In en, this message translates to:
  /// **'Load a persona'**
  String get loadPersona;

  /// No description provided for @replaceInstructionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Replace the instructions?'**
  String get replaceInstructionsTitle;

  /// No description provided for @replaceInstructionsBody.
  ///
  /// In en, this message translates to:
  /// **'The bot\'s current instructions will be replaced with {name}\'s. Skills and routines stay as they are.'**
  String replaceInstructionsBody(String name);

  /// No description provided for @replace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get replace;

  /// No description provided for @appsTitle.
  ///
  /// In en, this message translates to:
  /// **'Apps'**
  String get appsTitle;

  /// No description provided for @appsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Give your bots the tools your team already uses.'**
  String get appsSubtitle;

  /// No description provided for @connectedTab.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connectedTab;

  /// No description provided for @browseTab.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get browseTab;

  /// No description provided for @searchApps.
  ///
  /// In en, this message translates to:
  /// **'Search apps'**
  String get searchApps;

  /// No description provided for @popularApps.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get popularApps;

  /// No description provided for @allApps.
  ///
  /// In en, this message translates to:
  /// **'All apps'**
  String get allApps;

  /// No description provided for @appCatDeveloper.
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get appCatDeveloper;

  /// No description provided for @appCatProductivity.
  ///
  /// In en, this message translates to:
  /// **'Productivity'**
  String get appCatProductivity;

  /// No description provided for @appCatGoogle.
  ///
  /// In en, this message translates to:
  /// **'Google'**
  String get appCatGoogle;

  /// No description provided for @appCatPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get appCatPayments;

  /// No description provided for @appCatDesign.
  ///
  /// In en, this message translates to:
  /// **'Design'**
  String get appCatDesign;

  /// No description provided for @appCatSales.
  ///
  /// In en, this message translates to:
  /// **'Sales & support'**
  String get appCatSales;

  /// No description provided for @appCatData.
  ///
  /// In en, this message translates to:
  /// **'Data & search'**
  String get appCatData;

  /// No description provided for @appCatAutomation.
  ///
  /// In en, this message translates to:
  /// **'Automation'**
  String get appCatAutomation;

  /// No description provided for @authOneClick.
  ///
  /// In en, this message translates to:
  /// **'One click'**
  String get authOneClick;

  /// No description provided for @authApiKey.
  ///
  /// In en, this message translates to:
  /// **'API key'**
  String get authApiKey;

  /// No description provided for @authNone.
  ///
  /// In en, this message translates to:
  /// **'No sign-in'**
  String get authNone;

  /// No description provided for @authAdminSetup.
  ///
  /// In en, this message translates to:
  /// **'Needs setup'**
  String get authAdminSetup;

  /// No description provided for @connectedBadge.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connectedBadge;

  /// No description provided for @whatBotsCanDo.
  ///
  /// In en, this message translates to:
  /// **'What your bots can do'**
  String get whatBotsCanDo;

  /// No description provided for @continueWith.
  ///
  /// In en, this message translates to:
  /// **'Continue with {app}'**
  String continueWith(String app);

  /// No description provided for @signInTab.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInTab;

  /// No description provided for @connectNoSignIn.
  ///
  /// In en, this message translates to:
  /// **'This app works without signing in.'**
  String get connectNoSignIn;

  /// No description provided for @finishSignIn.
  ///
  /// In en, this message translates to:
  /// **'Finish signing in to {app}'**
  String finishSignIn(String app);

  /// No description provided for @finishSignInHelp.
  ///
  /// In en, this message translates to:
  /// **'{app} opened in your browser. Approve access there and this updates by itself.'**
  String finishSignInHelp(String app);

  /// No description provided for @reopenSignIn.
  ///
  /// In en, this message translates to:
  /// **'Open the sign-in page again'**
  String get reopenSignIn;

  /// No description provided for @appConnected.
  ///
  /// In en, this message translates to:
  /// **'{app} is connected'**
  String appConnected(String app);

  /// No description provided for @appToolsReady.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Ready to use.} =1{1 tool is ready for your bots.} other{{count} tools are ready for your bots.}}'**
  String appToolsReady(int count);

  /// No description provided for @whichBots.
  ///
  /// In en, this message translates to:
  /// **'Which bots can use it?'**
  String get whichBots;

  /// No description provided for @whichBotsHelp.
  ///
  /// In en, this message translates to:
  /// **'Bots still ask you before anything risky.'**
  String get whichBotsHelp;

  /// No description provided for @doneLabel.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get doneLabel;

  /// No description provided for @openApp.
  ///
  /// In en, this message translates to:
  /// **'Open {app}'**
  String openApp(String app);

  /// No description provided for @pasteLabel.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get pasteLabel;

  /// No description provided for @connectingLabel.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get connectingLabel;

  /// No description provided for @connectFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t connect'**
  String get connectFailedTitle;

  /// No description provided for @adminSetupNeeded.
  ///
  /// In en, this message translates to:
  /// **'One-click sign-in for {app} needs a one-time setup by whoever runs this Kasama server.'**
  String adminSetupNeeded(String app);

  /// No description provided for @adminSetupRedirect.
  ///
  /// In en, this message translates to:
  /// **'Register this redirect address with the app: {uri}'**
  String adminSetupRedirect(String uri);

  /// No description provided for @privacyNote.
  ///
  /// In en, this message translates to:
  /// **'The sign-in is stored encrypted and never shown again. Disconnect anytime.'**
  String get privacyNote;

  /// No description provided for @moreWays.
  ///
  /// In en, this message translates to:
  /// **'More ways to connect'**
  String get moreWays;

  /// No description provided for @composioHelp.
  ///
  /// In en, this message translates to:
  /// **'Hundreds of apps like Gmail, Salesforce and Shopify, with sign-in handled by Composio.'**
  String get composioHelp;

  /// No description provided for @pipedreamHelp.
  ///
  /// In en, this message translates to:
  /// **'Thousands of apps through Pipedream Connect.'**
  String get pipedreamHelp;

  /// No description provided for @customServer.
  ///
  /// In en, this message translates to:
  /// **'Custom server'**
  String get customServer;

  /// No description provided for @customServerHelp.
  ///
  /// In en, this message translates to:
  /// **'Any MCP server or OpenAPI spec. For developers.'**
  String get customServerHelp;

  /// No description provided for @usedByBots.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Not given to any bot yet} =1{Used by 1 bot} other{Used by {count} bots}}'**
  String usedByBots(int count);

  /// No description provided for @statusReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get statusReady;

  /// No description provided for @statusNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get statusNeedsAttention;

  /// No description provided for @statusChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking'**
  String get statusChecking;

  /// No description provided for @toolsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get toolsTitle;

  /// No description provided for @toolsHelp.
  ///
  /// In en, this message translates to:
  /// **'Read-only tools run on their own. Tools that make changes ask first when a bot has read something untrusted, and ones marked “Always asks” wait for you every time.'**
  String get toolsHelp;

  /// No description provided for @botsWithAccess.
  ///
  /// In en, this message translates to:
  /// **'Bots with access'**
  String get botsWithAccess;

  /// No description provided for @reconnect.
  ///
  /// In en, this message translates to:
  /// **'Reconnect'**
  String get reconnect;

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// No description provided for @disconnectTitle.
  ///
  /// In en, this message translates to:
  /// **'Disconnect {app}?'**
  String disconnectTitle(String app);

  /// No description provided for @disconnectBody.
  ///
  /// In en, this message translates to:
  /// **'Bots lose its tools right away, and the saved sign-in is deleted.'**
  String get disconnectBody;

  /// No description provided for @testConnection.
  ///
  /// In en, this message translates to:
  /// **'Test connection'**
  String get testConnection;

  /// No description provided for @signedInOAuth.
  ///
  /// In en, this message translates to:
  /// **'Signed in with your account'**
  String get signedInOAuth;

  /// No description provided for @signedInKey.
  ///
  /// In en, this message translates to:
  /// **'Connected with an API key'**
  String get signedInKey;

  /// No description provided for @signedInNone.
  ///
  /// In en, this message translates to:
  /// **'No sign-in needed'**
  String get signedInNone;

  /// No description provided for @noConnectionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect your first app'**
  String get noConnectionsTitle;

  /// No description provided for @noConnections.
  ///
  /// In en, this message translates to:
  /// **'Stripe, Linear, Notion, Gmail and more. Most take one click.'**
  String get noConnections;

  /// No description provided for @browseApps.
  ///
  /// In en, this message translates to:
  /// **'Browse apps'**
  String get browseApps;

  /// No description provided for @providerSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect {provider}'**
  String providerSetupTitle(String provider);

  /// No description provided for @providerSetupHelp.
  ///
  /// In en, this message translates to:
  /// **'{provider} signs in to the apps for you, so you never handle their keys.'**
  String providerSetupHelp(String provider);

  /// No description provided for @getFreeKey.
  ///
  /// In en, this message translates to:
  /// **'Get a free key'**
  String get getFreeKey;

  /// No description provided for @providerAppsTitle.
  ///
  /// In en, this message translates to:
  /// **'Apps through {provider}'**
  String providerAppsTitle(String provider);

  /// No description provided for @addAnApp.
  ///
  /// In en, this message translates to:
  /// **'Add an app'**
  String get addAnApp;

  /// No description provided for @searchProviderApps.
  ///
  /// In en, this message translates to:
  /// **'Search {provider} apps'**
  String searchProviderApps(String provider);

  /// No description provided for @accountConnected.
  ///
  /// In en, this message translates to:
  /// **'Signed in'**
  String get accountConnected;

  /// No description provided for @accountPending.
  ///
  /// In en, this message translates to:
  /// **'Waiting for sign-in'**
  String get accountPending;

  /// No description provided for @accountError.
  ///
  /// In en, this message translates to:
  /// **'Sign-in problem'**
  String get accountError;

  /// No description provided for @noProviderAccounts.
  ///
  /// In en, this message translates to:
  /// **'No apps yet. Add one and sign in to it.'**
  String get noProviderAccounts;

  /// No description provided for @projectId.
  ///
  /// In en, this message translates to:
  /// **'Project ID'**
  String get projectId;

  /// No description provided for @toolRiskLow.
  ///
  /// In en, this message translates to:
  /// **'Read-only'**
  String get toolRiskLow;

  /// No description provided for @toolRiskMedium.
  ///
  /// In en, this message translates to:
  /// **'Makes changes'**
  String get toolRiskMedium;

  /// No description provided for @toolRiskHigh.
  ///
  /// In en, this message translates to:
  /// **'Always asks'**
  String get toolRiskHigh;

  /// No description provided for @askWhichBot.
  ///
  /// In en, this message translates to:
  /// **'Which bot should look at this?'**
  String get askWhichBot;

  /// No description provided for @computerWake.
  ///
  /// In en, this message translates to:
  /// **'Wake up'**
  String get computerWake;

  /// No description provided for @computerGoingToSleep.
  ///
  /// In en, this message translates to:
  /// **'Going to sleep'**
  String get computerGoingToSleep;

  /// No description provided for @liveViewWakesHelp.
  ///
  /// In en, this message translates to:
  /// **'This computer is asleep. Opening the live view wakes it up; it goes back to sleep after a while without use.'**
  String get liveViewWakesHelp;

  /// No description provided for @wakeAndWatch.
  ///
  /// In en, this message translates to:
  /// **'Wake up and watch live'**
  String get wakeAndWatch;

  /// No description provided for @chatGptPlan.
  ///
  /// In en, this message translates to:
  /// **'ChatGPT plan'**
  String get chatGptPlan;

  /// Sign-in button label required by OpenAI's branding rules
  ///
  /// In en, this message translates to:
  /// **'Continue with ChatGPT'**
  String get continueWithChatGpt;

  /// No description provided for @chatGptConnectHelp.
  ///
  /// In en, this message translates to:
  /// **'Run your bots on your ChatGPT plan instead of an API key. Their model calls count toward your plan\'s limits, and only you can use it.'**
  String get chatGptConnectHelp;

  /// No description provided for @chatGptDesktopOnly.
  ///
  /// In en, this message translates to:
  /// **'To connect your ChatGPT plan, open the desktop app, or run \"kasama credential chatgpt\" in the CLI.'**
  String get chatGptDesktopOnly;

  /// No description provided for @chatGptWaiting.
  ///
  /// In en, this message translates to:
  /// **'Finish signing in with ChatGPT in your browser…'**
  String get chatGptWaiting;

  /// No description provided for @chatGptConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected your ChatGPT plan ({account}).'**
  String chatGptConnected(String account);

  /// No description provided for @chatGptPlanUsageOff.
  ///
  /// In en, this message translates to:
  /// **'You signed in, but plan usage wasn\'t allowed. Reconnect and allow it, or add an API key.'**
  String get chatGptPlanUsageOff;

  /// No description provided for @orAddApiKey.
  ///
  /// In en, this message translates to:
  /// **'Or add an API key'**
  String get orAddApiKey;

  /// No description provided for @planOnlyYou.
  ///
  /// In en, this message translates to:
  /// **'Only you can use it'**
  String get planOnlyYou;

  /// No description provided for @planOtherMember.
  ///
  /// In en, this message translates to:
  /// **'Another member\'s plan'**
  String get planOtherMember;

  /// No description provided for @planConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get planConnected;

  /// No description provided for @planUsageOff.
  ///
  /// In en, this message translates to:
  /// **'Plan usage off'**
  String get planUsageOff;

  /// No description provided for @planNeedsReconnect.
  ///
  /// In en, this message translates to:
  /// **'Sign in again'**
  String get planNeedsReconnect;

  /// No description provided for @useNextModelAtLimit.
  ///
  /// In en, this message translates to:
  /// **'Use the bot\'s next model at my plan limit'**
  String get useNextModelAtLimit;

  /// No description provided for @useNextModelAtLimitHelp.
  ///
  /// In en, this message translates to:
  /// **'Off: a run stops when your ChatGPT limit is reached. On: it continues on the bot\'s next model, which may cost money.'**
  String get useNextModelAtLimitHelp;

  /// No description provided for @manageUsage.
  ///
  /// In en, this message translates to:
  /// **'Manage usage'**
  String get manageUsage;

  /// No description provided for @removeKey.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeKey;

  /// No description provided for @removeKeyConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove {label}? Bots that use it stop working until you give them another key.'**
  String removeKeyConfirm(String label);

  /// No description provided for @removeKeyChatGptNote.
  ///
  /// In en, this message translates to:
  /// **'Your ChatGPT sign-in is revoked too.'**
  String get removeKeyChatGptNote;

  /// No description provided for @modelFallbackNotice.
  ///
  /// In en, this message translates to:
  /// **'Switched to the next model: {message}'**
  String modelFallbackNotice(String message);

  /// No description provided for @twoStepSignIn.
  ///
  /// In en, this message translates to:
  /// **'Two-step sign-in'**
  String get twoStepSignIn;

  /// No description provided for @twoStepHelp.
  ///
  /// In en, this message translates to:
  /// **'Ask for a code from an authenticator app whenever you sign in.'**
  String get twoStepHelp;

  /// No description provided for @twoStepIsOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get twoStepIsOn;

  /// No description provided for @twoStepIsOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get twoStepIsOff;

  /// No description provided for @twoStepRequiredHere.
  ///
  /// In en, this message translates to:
  /// **'Required for owners and admins in this workspace'**
  String get twoStepRequiredHere;

  /// No description provided for @twoStepSetUp.
  ///
  /// In en, this message translates to:
  /// **'Set up an authenticator app'**
  String get twoStepSetUp;

  /// No description provided for @twoStepAddAnother.
  ///
  /// In en, this message translates to:
  /// **'Add another authenticator'**
  String get twoStepAddAnother;

  /// No description provided for @twoStepScan.
  ///
  /// In en, this message translates to:
  /// **'Scan this code with an authenticator app (such as 1Password, Google Authenticator or Authy), or type in the setup key, then enter the 6-digit code it shows.'**
  String get twoStepScan;

  /// No description provided for @twoStepKey.
  ///
  /// In en, this message translates to:
  /// **'Setup key'**
  String get twoStepKey;

  /// No description provided for @twoStepCode.
  ///
  /// In en, this message translates to:
  /// **'6-digit code'**
  String get twoStepCode;

  /// No description provided for @twoStepVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get twoStepVerify;

  /// No description provided for @twoStepNowOn.
  ///
  /// In en, this message translates to:
  /// **'Two-step sign-in is on.'**
  String get twoStepNowOn;

  /// No description provided for @twoStepAuthenticators.
  ///
  /// In en, this message translates to:
  /// **'Authenticator apps'**
  String get twoStepAuthenticators;

  /// No description provided for @twoStepRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get twoStepRemove;

  /// No description provided for @twoStepRemoveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove this authenticator app? If it\'s your only one, you\'ll sign in with just your password.'**
  String get twoStepRemoveConfirm;

  /// No description provided for @twoStepPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your code'**
  String get twoStepPromptTitle;

  /// No description provided for @twoStepPromptBody.
  ///
  /// In en, this message translates to:
  /// **'Open your authenticator app and enter the 6-digit code to finish signing in.'**
  String get twoStepPromptBody;

  /// No description provided for @requireTwoStep.
  ///
  /// In en, this message translates to:
  /// **'Require two-step sign-in for owners and admins'**
  String get requireTwoStep;

  /// No description provided for @requireTwoStepHelp.
  ///
  /// In en, this message translates to:
  /// **'Owners and admins without it keep member access only until they sign in with it. Turn it on for yourself first.'**
  String get requireTwoStepHelp;

  /// No description provided for @twoStepNeededForAdmin.
  ///
  /// In en, this message translates to:
  /// **'This workspace requires two-step sign-in for owners and admins. Set it up, or sign in again with your code, to use admin settings.'**
  String get twoStepNeededForAdmin;

  /// No description provided for @adminAbuse.
  ///
  /// In en, this message translates to:
  /// **'Abuse'**
  String get adminAbuse;

  /// No description provided for @adminNoAbuse.
  ///
  /// In en, this message translates to:
  /// **'Nothing suspicious so far.'**
  String get adminNoAbuse;

  /// No description provided for @suspendWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Suspend'**
  String get suspendWorkspace;

  /// No description provided for @unsuspendWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Lift suspension'**
  String get unsuspendWorkspace;

  /// No description provided for @suspendReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get suspendReason;

  /// No description provided for @suspendWorkspaceHelp.
  ///
  /// In en, this message translates to:
  /// **'Its computers stop and its bots stop running. Nothing is deleted, and you can lift it any time.'**
  String get suspendWorkspaceHelp;

  /// No description provided for @workspaceSuspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended: {reason}'**
  String workspaceSuspended(String reason);

  /// No description provided for @workspaceSuspendedBanner.
  ///
  /// In en, this message translates to:
  /// **'This workspace is suspended, so bots can\'t run and computers can\'t start. Contact whoever runs this server.'**
  String get workspaceSuspendedBanner;

  /// No description provided for @abuseKind_mining_pool.
  ///
  /// In en, this message translates to:
  /// **'Crypto mining blocked'**
  String get abuseKind_mining_pool;

  /// No description provided for @abuseKind_blocked_port.
  ///
  /// In en, this message translates to:
  /// **'Mail port blocked'**
  String get abuseKind_blocked_port;

  /// No description provided for @abuseKind_egress_flood.
  ///
  /// In en, this message translates to:
  /// **'Traffic flood'**
  String get abuseKind_egress_flood;

  /// No description provided for @abuseKind_signup_blocked.
  ///
  /// In en, this message translates to:
  /// **'Sign-up refused'**
  String get abuseKind_signup_blocked;

  /// No description provided for @abuseKind_suspended.
  ///
  /// In en, this message translates to:
  /// **'Workspace suspended'**
  String get abuseKind_suspended;

  /// No description provided for @abuseKind_unsuspended.
  ///
  /// In en, this message translates to:
  /// **'Suspension lifted'**
  String get abuseKind_unsuspended;

  /// No description provided for @kindLocalMcp.
  ///
  /// In en, this message translates to:
  /// **'On a computer'**
  String get kindLocalMcp;

  /// No description provided for @capMcp.
  ///
  /// In en, this message translates to:
  /// **'Local tools (MCP)'**
  String get capMcp;

  /// No description provided for @localMcpServers.
  ///
  /// In en, this message translates to:
  /// **'Local tools (MCP)'**
  String get localMcpServers;

  /// No description provided for @localMcpHelp.
  ///
  /// In en, this message translates to:
  /// **'MCP servers on this computer that your bots can use, such as Claude Code, Codex or design apps. Their tokens stay on this computer.'**
  String get localMcpHelp;

  /// No description provided for @localMcpAdd.
  ///
  /// In en, this message translates to:
  /// **'Add a local MCP server'**
  String get localMcpAdd;

  /// No description provided for @localMcpEmpty.
  ///
  /// In en, this message translates to:
  /// **'No local MCP servers yet.'**
  String get localMcpEmpty;

  /// No description provided for @localMcpName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get localMcpName;

  /// No description provided for @localMcpKind.
  ///
  /// In en, this message translates to:
  /// **'How it runs'**
  String get localMcpKind;

  /// No description provided for @localMcpStdio.
  ///
  /// In en, this message translates to:
  /// **'A command'**
  String get localMcpStdio;

  /// No description provided for @localMcpLoopback.
  ///
  /// In en, this message translates to:
  /// **'An address on this computer'**
  String get localMcpLoopback;

  /// No description provided for @localMcpCommand.
  ///
  /// In en, this message translates to:
  /// **'Command'**
  String get localMcpCommand;

  /// No description provided for @localMcpCommandHint.
  ///
  /// In en, this message translates to:
  /// **'npx -y @example/mcp-server'**
  String get localMcpCommandHint;

  /// No description provided for @localMcpUrl.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get localMcpUrl;

  /// No description provided for @localMcpFolder.
  ///
  /// In en, this message translates to:
  /// **'Working folder (optional)'**
  String get localMcpFolder;

  /// No description provided for @localMcpEnv.
  ///
  /// In en, this message translates to:
  /// **'Environment (one KEY=value per line, kept on this computer)'**
  String get localMcpEnv;

  /// No description provided for @localMcpNeedsCapability.
  ///
  /// In en, this message translates to:
  /// **'Turn on Local tools (MCP) above so bots can use these.'**
  String get localMcpNeedsCapability;

  /// No description provided for @localMcpBadUrl.
  ///
  /// In en, this message translates to:
  /// **'Use an address on this computer, like http://127.0.0.1:3845/mcp.'**
  String get localMcpBadUrl;

  /// No description provided for @localMcpBadFolder.
  ///
  /// In en, this message translates to:
  /// **'Pick a folder inside one of the shared folders.'**
  String get localMcpBadFolder;

  /// No description provided for @localMcpOnDevice.
  ///
  /// In en, this message translates to:
  /// **'On {device}'**
  String localMcpOnDevice(String device);

  /// No description provided for @codingAgents.
  ///
  /// In en, this message translates to:
  /// **'Coding agents'**
  String get codingAgents;

  /// No description provided for @codingAgentsHelp.
  ///
  /// In en, this message translates to:
  /// **'Bots can hand coding tasks to these agents on this computer. They use your own sign-ins and work in the folders you share.'**
  String get codingAgentsHelp;

  /// No description provided for @codingAgentsNone.
  ///
  /// In en, this message translates to:
  /// **'No coding agents found. Install Claude Code, Codex or Cursor\'s command-line agent to hand them coding tasks.'**
  String get codingAgentsNone;

  /// No description provided for @codingAgentsNeedShell.
  ///
  /// In en, this message translates to:
  /// **'Coding agents run as commands, so they need Run commands turned on.'**
  String get codingAgentsNeedShell;

  /// No description provided for @allowCommands.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get allowCommands;

  /// No description provided for @navBoard.
  ///
  /// In en, this message translates to:
  /// **'Board'**
  String get navBoard;

  /// No description provided for @board.
  ///
  /// In en, this message translates to:
  /// **'Board'**
  String get board;

  /// No description provided for @newTicket.
  ///
  /// In en, this message translates to:
  /// **'New ticket'**
  String get newTicket;

  /// No description provided for @ticketTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get ticketTitle;

  /// No description provided for @ticketDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get ticketDetails;

  /// No description provided for @taskInReview.
  ///
  /// In en, this message translates to:
  /// **'In review'**
  String get taskInReview;

  /// No description provided for @priority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priority;

  /// No description provided for @priorityUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get priorityUrgent;

  /// No description provided for @priorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get priorityHigh;

  /// No description provided for @priorityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get priorityMedium;

  /// No description provided for @priorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get priorityLow;

  /// No description provided for @priorityNone.
  ///
  /// In en, this message translates to:
  /// **'No priority'**
  String get priorityNone;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterMine.
  ///
  /// In en, this message translates to:
  /// **'Mine'**
  String get filterMine;

  /// No description provided for @filterBots.
  ///
  /// In en, this message translates to:
  /// **'Bots'**
  String get filterBots;

  /// No description provided for @assignee.
  ///
  /// In en, this message translates to:
  /// **'Assigned to'**
  String get assignee;

  /// No description provided for @unassigned.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get unassigned;

  /// No description provided for @assignToMe.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get assignToMe;

  /// No description provided for @reviewRequired.
  ///
  /// In en, this message translates to:
  /// **'Needs review'**
  String get reviewRequired;

  /// No description provided for @reviewRequiredHelp.
  ///
  /// In en, this message translates to:
  /// **'The bot finishes in review instead of done.'**
  String get reviewRequiredHelp;

  /// No description provided for @comments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get comments;

  /// No description provided for @addComment.
  ///
  /// In en, this message translates to:
  /// **'Add a comment'**
  String get addComment;

  /// No description provided for @sendComment.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get sendComment;

  /// No description provided for @openThread.
  ///
  /// In en, this message translates to:
  /// **'Open the bot\'s thread'**
  String get openThread;

  /// No description provided for @deleteTicket.
  ///
  /// In en, this message translates to:
  /// **'Delete ticket'**
  String get deleteTicket;

  /// No description provided for @noTickets.
  ///
  /// In en, this message translates to:
  /// **'No tickets yet'**
  String get noTickets;

  /// No description provided for @noTicketsHelp.
  ///
  /// In en, this message translates to:
  /// **'Add a ticket and assign it to a bot to get it started, or ask a bot to plan work here.'**
  String get noTicketsHelp;

  /// No description provided for @ticketStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get ticketStatus;

  /// No description provided for @spaces.
  ///
  /// In en, this message translates to:
  /// **'Workspaces'**
  String get spaces;

  /// No description provided for @newWorkspace.
  ///
  /// In en, this message translates to:
  /// **'New workspace'**
  String get newWorkspace;

  /// No description provided for @joinWorkspaceHelp.
  ///
  /// In en, this message translates to:
  /// **'Paste the invite link someone sent you.'**
  String get joinWorkspaceHelp;

  /// No description provided for @inviteLinkField.
  ///
  /// In en, this message translates to:
  /// **'Invite link'**
  String get inviteLinkField;

  /// No description provided for @workspaceIcon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get workspaceIcon;

  /// No description provided for @workspaceColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get workspaceColor;

  /// No description provided for @workspaceSettings.
  ///
  /// In en, this message translates to:
  /// **'Workspace settings'**
  String get workspaceSettings;

  /// No description provided for @workspaceSettingsHelp.
  ///
  /// In en, this message translates to:
  /// **'Name, icon, color and invite links'**
  String get workspaceSettingsHelp;

  /// No description provided for @inviteLinks.
  ///
  /// In en, this message translates to:
  /// **'Invite links'**
  String get inviteLinks;

  /// No description provided for @inviteLinksHelp.
  ///
  /// In en, this message translates to:
  /// **'Anyone with a link can join after signing in, until it expires, runs out of uses or you revoke it.'**
  String get inviteLinksHelp;

  /// No description provided for @createInviteLink.
  ///
  /// In en, this message translates to:
  /// **'Create a link'**
  String get createInviteLink;

  /// No description provided for @inviteRole.
  ///
  /// In en, this message translates to:
  /// **'Joins as'**
  String get inviteRole;

  /// No description provided for @linkExpires.
  ///
  /// In en, this message translates to:
  /// **'Expires'**
  String get linkExpires;

  /// No description provided for @linkNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get linkNever;

  /// No description provided for @linkDays.
  ///
  /// In en, this message translates to:
  /// **'In {days} days'**
  String linkDays(String days);

  /// No description provided for @linkMaxUses.
  ///
  /// In en, this message translates to:
  /// **'Uses'**
  String get linkMaxUses;

  /// No description provided for @linkUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get linkUnlimited;

  /// No description provided for @linkUses.
  ///
  /// In en, this message translates to:
  /// **'{uses} used'**
  String linkUses(String uses);

  /// No description provided for @linkRevoked.
  ///
  /// In en, this message translates to:
  /// **'Revoked'**
  String get linkRevoked;

  /// No description provided for @revokeLink.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get revokeLink;

  /// No description provided for @linkCopied.
  ///
  /// In en, this message translates to:
  /// **'Invite link copied.'**
  String get linkCopied;

  /// No description provided for @joiningWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Joining the workspace…'**
  String get joiningWorkspace;

  /// No description provided for @joinedWorkspace.
  ///
  /// In en, this message translates to:
  /// **'You joined {name}.'**
  String joinedWorkspace(String name);

  /// No description provided for @joinFailed.
  ///
  /// In en, this message translates to:
  /// **'This invite link doesn\'t work anymore. Ask for a new one.'**
  String get joinFailed;

  /// No description provided for @joinWithLink.
  ///
  /// In en, this message translates to:
  /// **'Join with a link'**
  String get joinWithLink;

  /// No description provided for @botFolder.
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get botFolder;

  /// No description provided for @noFolder.
  ///
  /// In en, this message translates to:
  /// **'No folder'**
  String get noFolder;

  /// No description provided for @newFolder.
  ///
  /// In en, this message translates to:
  /// **'New folder…'**
  String get newFolder;

  /// No description provided for @folderName.
  ///
  /// In en, this message translates to:
  /// **'Folder name'**
  String get folderName;

  /// No description provided for @archiveBot.
  ///
  /// In en, this message translates to:
  /// **'Archive bot'**
  String get archiveBot;

  /// No description provided for @archiveBotTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive {name}?'**
  String archiveBotTitle(String name);

  /// No description provided for @archiveBotBody.
  ///
  /// In en, this message translates to:
  /// **'It leaves the sidebar and stops running. Its chats and history are kept, and you can bring it back from Archived bots.'**
  String get archiveBotBody;

  /// No description provided for @archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archive;

  /// No description provided for @archivedBots.
  ///
  /// In en, this message translates to:
  /// **'Archived bots'**
  String get archivedBots;

  /// No description provided for @unarchive.
  ///
  /// In en, this message translates to:
  /// **'Bring back'**
  String get unarchive;

  /// No description provided for @botArchived.
  ///
  /// In en, this message translates to:
  /// **'{name} archived.'**
  String botArchived(String name);

  /// No description provided for @settingsHistory.
  ///
  /// In en, this message translates to:
  /// **'Settings history'**
  String get settingsHistory;

  /// No description provided for @settingsHistoryHelp.
  ///
  /// In en, this message translates to:
  /// **'Every change to this bot\'s settings, and who made it'**
  String get settingsHistoryHelp;

  /// No description provided for @noHistory.
  ///
  /// In en, this message translates to:
  /// **'No changes yet.'**
  String get noHistory;

  /// No description provided for @restoreSettings.
  ///
  /// In en, this message translates to:
  /// **'Restore these settings'**
  String get restoreSettings;

  /// No description provided for @restoreSettingsBody.
  ///
  /// In en, this message translates to:
  /// **'Put back {fields} as they were before this change? The current settings stay in the history.'**
  String restoreSettingsBody(String fields);

  /// No description provided for @changedByBot.
  ///
  /// In en, this message translates to:
  /// **'Changed by {name}'**
  String changedByBot(String name);

  /// No description provided for @changedByPerson.
  ///
  /// In en, this message translates to:
  /// **'Changed by a person'**
  String get changedByPerson;

  /// No description provided for @changedBySystem.
  ///
  /// In en, this message translates to:
  /// **'Changed by Kasama'**
  String get changedBySystem;

  /// No description provided for @fieldName.
  ///
  /// In en, this message translates to:
  /// **'name'**
  String get fieldName;

  /// No description provided for @fieldInstructions.
  ///
  /// In en, this message translates to:
  /// **'instructions'**
  String get fieldInstructions;

  /// No description provided for @fieldModel.
  ///
  /// In en, this message translates to:
  /// **'model'**
  String get fieldModel;

  /// No description provided for @fieldAutonomy.
  ///
  /// In en, this message translates to:
  /// **'autonomy'**
  String get fieldAutonomy;

  /// No description provided for @fieldBudget.
  ///
  /// In en, this message translates to:
  /// **'budget'**
  String get fieldBudget;

  /// No description provided for @fieldComputer.
  ///
  /// In en, this message translates to:
  /// **'computer'**
  String get fieldComputer;

  /// No description provided for @fieldArchived.
  ///
  /// In en, this message translates to:
  /// **'archived'**
  String get fieldArchived;

  /// No description provided for @secretRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'{bot} needs a {service} key'**
  String secretRequestTitle(String bot, String service);

  /// No description provided for @secretRequestHosts.
  ///
  /// In en, this message translates to:
  /// **'Only for {hosts}'**
  String secretRequestHosts(String hosts);

  /// No description provided for @secretRequestHelp.
  ///
  /// In en, this message translates to:
  /// **'Goes straight to the vault. The bot never sees it.'**
  String get secretRequestHelp;

  /// No description provided for @secretSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved {name}'**
  String secretSaved(String name);

  /// No description provided for @secretDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get secretDeclined;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @signInCode.
  ///
  /// In en, this message translates to:
  /// **'Sign-in code'**
  String get signInCode;

  /// No description provided for @secretKindValue.
  ///
  /// In en, this message translates to:
  /// **'Key or password'**
  String get secretKindValue;

  /// No description provided for @totpSeedLabel.
  ///
  /// In en, this message translates to:
  /// **'Two-step key or otpauth:// link'**
  String get totpSeedLabel;

  /// No description provided for @totpSeedHelp.
  ///
  /// In en, this message translates to:
  /// **'From the site\'s two-step setup. Bots only ever get the current code, never the key.'**
  String get totpSeedHelp;

  /// No description provided for @scanQrCode.
  ///
  /// In en, this message translates to:
  /// **'Scan QR code'**
  String get scanQrCode;

  /// No description provided for @totpRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'{bot} needs a {service} sign-in code'**
  String totpRequestTitle(String bot, String service);

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search chats, memories, skills, tickets and files'**
  String get searchHint;

  /// No description provided for @searchEmptyPrompt.
  ///
  /// In en, this message translates to:
  /// **'Type at least 2 characters.'**
  String get searchEmptyPrompt;

  /// No description provided for @searchNoResults.
  ///
  /// In en, this message translates to:
  /// **'Nothing found for “{query}”.'**
  String searchNoResults(String query);

  /// No description provided for @searchMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get searchMessages;

  /// No description provided for @searchChats.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get searchChats;

  /// No description provided for @searchTickets.
  ///
  /// In en, this message translates to:
  /// **'Tickets'**
  String get searchTickets;

  /// No description provided for @searchFiles.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get searchFiles;

  /// No description provided for @searchFilesAsleep.
  ///
  /// In en, this message translates to:
  /// **'Files on sleeping computers aren\'t searched. Start a computer to include its files.'**
  String get searchFilesAsleep;

  /// No description provided for @installFor.
  ///
  /// In en, this message translates to:
  /// **'Install for'**
  String get installFor;

  /// No description provided for @wholeWorkspace.
  ///
  /// In en, this message translates to:
  /// **'The whole workspace'**
  String get wholeWorkspace;

  /// No description provided for @skillCatalog.
  ///
  /// In en, this message translates to:
  /// **'Skill catalog'**
  String get skillCatalog;

  /// No description provided for @searchSkills.
  ///
  /// In en, this message translates to:
  /// **'Search skills'**
  String get searchSkills;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @skillFiles.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file} other{{count} files}}'**
  String skillFiles(int count);

  /// No description provided for @install.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get install;

  /// No description provided for @skillInstalled.
  ///
  /// In en, this message translates to:
  /// **'Installed {name}.'**
  String skillInstalled(String name);

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results.'**
  String get noResults;

  /// No description provided for @importFromGitHub.
  ///
  /// In en, this message translates to:
  /// **'Import from GitHub'**
  String get importFromGitHub;

  /// No description provided for @importFromGitHubHelp.
  ///
  /// In en, this message translates to:
  /// **'Paste a link to a folder with a SKILL.md. You\'ll see every file before anything is installed. Private repositories use a GITHUB_TOKEN secret allowed for api.github.com.'**
  String get importFromGitHubHelp;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @skillScriptsNote.
  ///
  /// In en, this message translates to:
  /// **'Scripts in a skill only ever run on a bot\'s computer, never on the server.'**
  String get skillScriptsNote;

  /// No description provided for @binaryFile.
  ///
  /// In en, this message translates to:
  /// **'(binary file)'**
  String get binaryFile;

  /// No description provided for @skillUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update {name}'**
  String skillUpdate(String name);

  /// No description provided for @checkingForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Checking for updates…'**
  String get checkingForUpdates;

  /// No description provided for @skillUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Already up to date.'**
  String get skillUpToDate;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @filesAdded.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get filesAdded;

  /// No description provided for @filesChanged.
  ///
  /// In en, this message translates to:
  /// **'Changed'**
  String get filesChanged;

  /// No description provided for @filesRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed'**
  String get filesRemoved;

  /// No description provided for @fromCatalog.
  ///
  /// In en, this message translates to:
  /// **'From the catalog'**
  String get fromCatalog;

  /// No description provided for @savedByBot.
  ///
  /// In en, this message translates to:
  /// **'Saved by a bot'**
  String get savedByBot;

  /// No description provided for @checkForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get checkForUpdates;

  /// No description provided for @attachSkill.
  ///
  /// In en, this message translates to:
  /// **'Attach a skill'**
  String get attachSkill;

  /// No description provided for @setupTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up {name}'**
  String setupTitle(String name);

  /// No description provided for @setupBody.
  ///
  /// In en, this message translates to:
  /// **'Answer a few quick questions and it will propose its instructions, routines and the accounts to connect. Nothing changes until you approve.'**
  String get setupBody;

  /// No description provided for @startSetup.
  ///
  /// In en, this message translates to:
  /// **'Start setup'**
  String get startSetup;

  /// No description provided for @skipSetup.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get skipSetup;

  /// No description provided for @rerunSetup.
  ///
  /// In en, this message translates to:
  /// **'Run setup again'**
  String get rerunSetup;

  /// No description provided for @rerunSetupHelp.
  ///
  /// In en, this message translates to:
  /// **'Answer the setup questions again and review a new proposal'**
  String get rerunSetupHelp;

  /// No description provided for @trace.
  ///
  /// In en, this message translates to:
  /// **'Trace'**
  String get trace;

  /// No description provided for @openTrace.
  ///
  /// In en, this message translates to:
  /// **'Open trace'**
  String get openTrace;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
