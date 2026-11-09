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
  /// **'Persona'**
  String get persona;

  /// No description provided for @personaHint.
  ///
  /// In en, this message translates to:
  /// **'How should this bot behave? (optional)'**
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
  /// **'No bots yet. Create one to start.'**
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
  /// **'The run failed: {message}'**
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
  /// **'This folder is empty.'**
  String get emptyFolder;

  /// No description provided for @noCheckpoints.
  ///
  /// In en, this message translates to:
  /// **'No checkpoints yet. They are saved before risky changes.'**
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
  /// **'No integrations yet. Connect an MCP server, an OpenAPI source, Composio or Pipedream.'**
  String get noIntegrations;

  /// No description provided for @noIntegrationsForBot.
  ///
  /// In en, this message translates to:
  /// **'Add integrations in Settings first.'**
  String get noIntegrationsForBot;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet.'**
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
  /// **'The task board is empty.'**
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
  /// **'Start from'**
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
  /// **'Schedule'**
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
  /// **'Default (its private computer, else the team computer)'**
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
