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
  /// **'Casama'**
  String get appTitle;

  /// No description provided for @tabTitle.
  ///
  /// In en, this message translates to:
  /// **'{page} · {app}'**
  String tabTitle(String page, String app);

  /// No description provided for @tabTitleBotPage.
  ///
  /// In en, this message translates to:
  /// **'{page} · {bot}'**
  String tabTitleBotPage(String page, String bot);

  /// No description provided for @tabTitleChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get tabTitleChat;

  /// No description provided for @tabTitleCall.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get tabTitleCall;

  /// No description provided for @tabTitleProject.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get tabTitleProject;

  /// No description provided for @tabTitleGroupChat.
  ///
  /// In en, this message translates to:
  /// **'Group chat'**
  String get tabTitleGroupChat;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
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

  /// No description provided for @errorViewHint.
  ///
  /// In en, this message translates to:
  /// **'Restarting the app should fix it.'**
  String get errorViewHint;

  /// No description provided for @signInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to Casama'**
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

  /// No description provided for @continueWithEmail.
  ///
  /// In en, this message translates to:
  /// **'Continue with Email'**
  String get continueWithEmail;

  /// No description provided for @moreSignInOptions.
  ///
  /// In en, this message translates to:
  /// **'More Options'**
  String get moreSignInOptions;

  /// No description provided for @usePasswordInstead.
  ///
  /// In en, this message translates to:
  /// **'Use a Password Instead'**
  String get usePasswordInstead;

  /// No description provided for @checkInboxTitle.
  ///
  /// In en, this message translates to:
  /// **'Check your inbox'**
  String get checkInboxTitle;

  /// No description provided for @checkInboxBody.
  ///
  /// In en, this message translates to:
  /// **'We sent a sign-in link and a 6-digit code to {email}. Tap the link, or type the code here.'**
  String checkInboxBody(String email);

  /// No description provided for @emailCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'6-digit code'**
  String get emailCodeLabel;

  /// No description provided for @resendLink.
  ///
  /// In en, this message translates to:
  /// **'Send Again'**
  String get resendLink;

  /// No description provided for @resendLinkIn.
  ///
  /// In en, this message translates to:
  /// **'Send Again in {seconds}s'**
  String resendLinkIn(int seconds);

  /// No description provided for @useDifferentEmail.
  ///
  /// In en, this message translates to:
  /// **'Use a Different Email'**
  String get useDifferentEmail;

  /// No description provided for @authWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'That email and password don\'t match. Try again, or sign in with an email link instead.'**
  String get authWrongPassword;

  /// No description provided for @authEmailNotConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirm your email first: open the link we sent you.'**
  String get authEmailNotConfirmed;

  /// No description provided for @authCodeInvalid.
  ///
  /// In en, this message translates to:
  /// **'That code is wrong or has expired. Check the latest email, or send a new one.'**
  String get authCodeInvalid;

  /// No description provided for @authTooManyTries.
  ///
  /// In en, this message translates to:
  /// **'Too many tries. Wait a minute and try again.'**
  String get authTooManyTries;

  /// No description provided for @authAccountExists.
  ///
  /// In en, this message translates to:
  /// **'There\'s already an account with this email. Sign in instead.'**
  String get authAccountExists;

  /// No description provided for @authSignupDisabled.
  ///
  /// In en, this message translates to:
  /// **'This server isn\'t taking new sign-ups.'**
  String get authSignupDisabled;

  /// No description provided for @useMagicLinkInstead.
  ///
  /// In en, this message translates to:
  /// **'Email Me a Link Instead'**
  String get useMagicLinkInstead;

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
  /// **'Sign Out'**
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
  /// **'Test Key'**
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

  /// No description provided for @navComputer.
  ///
  /// In en, this message translates to:
  /// **'Computer'**
  String get navComputer;

  /// No description provided for @navChats.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get navChats;

  /// No description provided for @navTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get navTasks;

  /// No description provided for @settingsConnectionsSection.
  ///
  /// In en, this message translates to:
  /// **'Connections'**
  String get settingsConnectionsSection;

  /// No description provided for @advanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get advanced;

  /// No description provided for @settingsAdvancedSummary.
  ///
  /// In en, this message translates to:
  /// **'Secrets, computers, devices'**
  String get settingsAdvancedSummary;

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

  /// No description provided for @messageHintWithApps.
  ///
  /// In en, this message translates to:
  /// **'Message {bot} · @ to mention an app'**
  String messageHintWithApps(String bot);

  /// No description provided for @mentionSectionBots.
  ///
  /// In en, this message translates to:
  /// **'Bots'**
  String get mentionSectionBots;

  /// No description provided for @mentionSectionApps.
  ///
  /// In en, this message translates to:
  /// **'Apps'**
  String get mentionSectionApps;

  /// No description provided for @mentionSectionAddToBot.
  ///
  /// In en, this message translates to:
  /// **'Add to this bot'**
  String get mentionSectionAddToBot;

  /// No description provided for @mentionSectionConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get mentionSectionConnect;

  /// No description provided for @mentionSectionStartGroup.
  ///
  /// In en, this message translates to:
  /// **'Start a group chat'**
  String get mentionSectionStartGroup;

  /// No description provided for @mentionBadgeBot.
  ///
  /// In en, this message translates to:
  /// **'Bot'**
  String get mentionBadgeBot;

  /// No description provided for @mentionBadgeApp.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get mentionBadgeApp;

  /// No description provided for @mentionAddAction.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get mentionAddAction;

  /// No description provided for @mentionConnectAction.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get mentionConnectAction;

  /// No description provided for @mentionMaxApps.
  ///
  /// In en, this message translates to:
  /// **'You can mention up to 3 apps per message.'**
  String get mentionMaxApps;

  /// No description provided for @mentionRemovedApp.
  ///
  /// In en, this message translates to:
  /// **'Removed app'**
  String get mentionRemovedApp;

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

  /// Working line while the bot looks over a reply it took back before you saw it finished
  ///
  /// In en, this message translates to:
  /// **'Checking its work…'**
  String get checkingItsWork;

  /// Tooltip on a map card in a bot's reply that opens the map full screen.
  ///
  /// In en, this message translates to:
  /// **'Full screen'**
  String get mapFullScreen;

  /// Title of the full-screen map opened from a bot's map card.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get mapTitle;

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

  /// No description provided for @terminalReconnecting.
  ///
  /// In en, this message translates to:
  /// **'Server restarting, reconnecting…'**
  String get terminalReconnecting;

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

  /// No description provided for @searchMemories.
  ///
  /// In en, this message translates to:
  /// **'Memories'**
  String get searchMemories;

  /// No description provided for @noMemoriesMatch.
  ///
  /// In en, this message translates to:
  /// **'No memories match.'**
  String get noMemoriesMatch;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearSearch;

  /// No description provided for @addMemory.
  ///
  /// In en, this message translates to:
  /// **'Add a Memory'**
  String get addMemory;

  /// No description provided for @addMemoryHelp.
  ///
  /// In en, this message translates to:
  /// **'Something the bot should always know about you or your work.'**
  String get addMemoryHelp;

  /// No description provided for @addMemoryFactHint.
  ///
  /// In en, this message translates to:
  /// **'For example: Our fiscal year starts in April.'**
  String get addMemoryFactHint;

  /// No description provided for @addMemoryPreferenceHint.
  ///
  /// In en, this message translates to:
  /// **'For example: Keep summaries under five bullet points.'**
  String get addMemoryPreferenceHint;

  /// No description provided for @memoryAdded.
  ///
  /// In en, this message translates to:
  /// **'Memory added'**
  String get memoryAdded;

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

  /// No description provided for @moreProviders.
  ///
  /// In en, this message translates to:
  /// **'More providers'**
  String get moreProviders;

  /// No description provided for @integrationsAdvancedSummary.
  ///
  /// In en, this message translates to:
  /// **'Composio, Pipedream, custom servers'**
  String get integrationsAdvancedSummary;

  /// No description provided for @toolPermissions.
  ///
  /// In en, this message translates to:
  /// **'Tool permissions'**
  String get toolPermissions;

  /// No description provided for @devicesAdvancedSummary.
  ///
  /// In en, this message translates to:
  /// **'How long it\'s kept, private models, bots with access'**
  String get devicesAdvancedSummary;

  /// No description provided for @companionAdvancedSummary.
  ///
  /// In en, this message translates to:
  /// **'Commands, local tools (MCP), coding agents'**
  String get companionAdvancedSummary;

  /// No description provided for @noKeys.
  ///
  /// In en, this message translates to:
  /// **'No model keys yet.'**
  String get noKeys;

  /// No description provided for @addKey.
  ///
  /// In en, this message translates to:
  /// **'Add Key'**
  String get addKey;

  /// No description provided for @usage.
  ///
  /// In en, this message translates to:
  /// **'Usage'**
  String get usage;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @inviteSent.
  ///
  /// In en, this message translates to:
  /// **'Invite sent to {email}.'**
  String inviteSent(String email);

  /// No description provided for @botProfile.
  ///
  /// In en, this message translates to:
  /// **'Bot profile'**
  String get botProfile;

  /// No description provided for @groupMembers.
  ///
  /// In en, this message translates to:
  /// **'Bots in This Chat'**
  String get groupMembers;

  /// No description provided for @groupMembersHelp.
  ///
  /// In en, this message translates to:
  /// **'Each keeps its own memory and settings. Tap one to open its profile.'**
  String get groupMembersHelp;

  /// No description provided for @botAdvancedSummary.
  ///
  /// In en, this message translates to:
  /// **'Chat apps, links, rules, watchers, plugins, activity'**
  String get botAdvancedSummary;

  /// No description provided for @botActivityRow.
  ///
  /// In en, this message translates to:
  /// **'Every run, step by step'**
  String get botActivityRow;

  /// No description provided for @createBotAdvancedSummary.
  ///
  /// In en, this message translates to:
  /// **'Model key and model'**
  String get createBotAdvancedSummary;

  /// No description provided for @botProfileSection.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get botProfileSection;

  /// No description provided for @botBrain.
  ///
  /// In en, this message translates to:
  /// **'Brain'**
  String get botBrain;

  /// No description provided for @botAbilities.
  ///
  /// In en, this message translates to:
  /// **'Abilities'**
  String get botAbilities;

  /// No description provided for @botSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get botSchedule;

  /// No description provided for @chatComputerLive.
  ///
  /// In en, this message translates to:
  /// **'Working on its computer'**
  String get chatComputerLive;

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
  /// **'Add Integration'**
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
  /// **'Always Allow'**
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

  /// No description provided for @composioToolkits.
  ///
  /// In en, this message translates to:
  /// **'Toolkits (comma-separated, for example github, gmail)'**
  String get composioToolkits;

  /// No description provided for @copySecret.
  ///
  /// In en, this message translates to:
  /// **'Copy Secret'**
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
  /// **'Mark All as Read'**
  String get markAllRead;

  /// No description provided for @newRoutine.
  ///
  /// In en, this message translates to:
  /// **'New routine'**
  String get newRoutine;

  /// No description provided for @noIntegrationsForBot.
  ///
  /// In en, this message translates to:
  /// **'Add integrations in Settings first, then turn them on for this bot here.'**
  String get noIntegrationsForBot;

  /// No description provided for @noRoutines.
  ///
  /// In en, this message translates to:
  /// **'No routines yet'**
  String get noRoutines;

  /// No description provided for @noSecrets.
  ///
  /// In en, this message translates to:
  /// **'No secrets yet. Bots reference them by name, and each one only goes to the hosts you allow.'**
  String get noSecrets;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @openInbox.
  ///
  /// In en, this message translates to:
  /// **'Open Inbox'**
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

  /// No description provided for @routineEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Routine'**
  String get routineEditTitle;

  /// No description provided for @routineEditSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Change what it does and when it runs.'**
  String get routineEditSubtitle;

  /// No description provided for @routineRecentRuns.
  ///
  /// In en, this message translates to:
  /// **'Recent runs'**
  String get routineRecentRuns;

  /// No description provided for @routineNoRuns.
  ///
  /// In en, this message translates to:
  /// **'It hasn\'t run yet.'**
  String get routineNoRuns;

  /// No description provided for @routineSaved.
  ///
  /// In en, this message translates to:
  /// **'Routine saved'**
  String get routineSaved;

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

  /// No description provided for @routineAdvancedSummary.
  ///
  /// In en, this message translates to:
  /// **'GitHub and webhook triggers, cron, timezone'**
  String get routineAdvancedSummary;

  /// No description provided for @routineRepeatDaily.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get routineRepeatDaily;

  /// No description provided for @routineRepeatWeekdays.
  ///
  /// In en, this message translates to:
  /// **'Weekdays'**
  String get routineRepeatWeekdays;

  /// No description provided for @routineRepeatWeekly.
  ///
  /// In en, this message translates to:
  /// **'Every week'**
  String get routineRepeatWeekly;

  /// No description provided for @routineDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get routineDay;

  /// No description provided for @routineTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get routineTimeLabel;

  /// No description provided for @routineRunsAt.
  ///
  /// In en, this message translates to:
  /// **'Runs at'**
  String get routineRunsAt;

  /// No description provided for @routineTimesIn.
  ///
  /// In en, this message translates to:
  /// **'Times are in {timezone}'**
  String routineTimesIn(String timezone);

  /// No description provided for @routineCustomSchedule.
  ///
  /// In en, this message translates to:
  /// **'Custom: {schedule}'**
  String routineCustomSchedule(String schedule);

  /// No description provided for @routineOtherTriggers.
  ///
  /// In en, this message translates to:
  /// **'Other triggers'**
  String get routineOtherTriggers;

  /// No description provided for @cronEveryMinutes.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Every minute} other{Every {n} minutes}}'**
  String cronEveryMinutes(int n);

  /// No description provided for @cronEveryHours.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Every hour} other{Every {n} hours}}'**
  String cronEveryHours(int n);

  /// No description provided for @cronHourlyAt.
  ///
  /// In en, this message translates to:
  /// **'Every hour at :{minute}'**
  String cronHourlyAt(String minute);

  /// No description provided for @cronDailyAt.
  ///
  /// In en, this message translates to:
  /// **'Every day at {time}'**
  String cronDailyAt(String time);

  /// No description provided for @cronWeekdaysAt.
  ///
  /// In en, this message translates to:
  /// **'Weekdays at {time}'**
  String cronWeekdaysAt(String time);

  /// No description provided for @cronWeekendsAt.
  ///
  /// In en, this message translates to:
  /// **'Weekends at {time}'**
  String cronWeekendsAt(String time);

  /// No description provided for @cronDaysAt.
  ///
  /// In en, this message translates to:
  /// **'{days} at {time}'**
  String cronDaysAt(String days, String time);

  /// No description provided for @cronMonthlyAt.
  ///
  /// In en, this message translates to:
  /// **'Day {day} of every month at {time}'**
  String cronMonthlyAt(int day, String time);

  /// No description provided for @cronAnd.
  ///
  /// In en, this message translates to:
  /// **'{items} and {last}'**
  String cronAnd(String items, String last);

  /// No description provided for @cronDays.
  ///
  /// In en, this message translates to:
  /// **'{day, select, sun{Sundays} mon{Mondays} tue{Tuesdays} wed{Wednesdays} thu{Thursdays} fri{Fridays} sat{Saturdays} other{{day}}}'**
  String cronDays(String day);

  /// No description provided for @cronDay.
  ///
  /// In en, this message translates to:
  /// **'{day, select, sun{Sunday} mon{Monday} tue{Tuesday} wed{Wednesday} thu{Thursday} fri{Friday} sat{Saturday} other{{day}}}'**
  String cronDay(String day);

  /// No description provided for @headlessScreenNoteSettings.
  ///
  /// In en, this message translates to:
  /// **'This computer has no desktop, so this shows its browser (blank until the bot opens a page). To watch and control apps live, switch it to a desktop in computer settings.'**
  String get headlessScreenNoteSettings;

  /// No description provided for @openComputerSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Computer Settings'**
  String get openComputerSettings;

  /// No description provided for @runNow.
  ///
  /// In en, this message translates to:
  /// **'Run Now'**
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
  /// **'Webhook Created'**
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

  /// No description provided for @renameTopic.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get renameTopic;

  /// No description provided for @library.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get library;

  /// No description provided for @navLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get navLibrary;

  /// No description provided for @librarySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search the Library'**
  String get librarySearchHint;

  /// No description provided for @libraryFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get libraryFilterAll;

  /// No description provided for @libraryFilterPages.
  ///
  /// In en, this message translates to:
  /// **'Sites & games'**
  String get libraryFilterPages;

  /// No description provided for @libraryFilterImages.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get libraryFilterImages;

  /// No description provided for @libraryFilterVideos.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get libraryFilterVideos;

  /// No description provided for @libraryFilterAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get libraryFilterAudio;

  /// No description provided for @libraryFilterDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get libraryFilterDocuments;

  /// No description provided for @libraryFilterFiles.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get libraryFilterFiles;

  /// No description provided for @creationKindPage.
  ///
  /// In en, this message translates to:
  /// **'Page'**
  String get creationKindPage;

  /// No description provided for @creationKindImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get creationKindImage;

  /// No description provided for @creationKindVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get creationKindVideo;

  /// No description provided for @creationKindAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get creationKindAudio;

  /// No description provided for @creationKindDocument.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get creationKindDocument;

  /// No description provided for @creationKindFile.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get creationKindFile;

  /// No description provided for @libraryPinned.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get libraryPinned;

  /// No description provided for @libraryToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get libraryToday;

  /// No description provided for @libraryYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get libraryYesterday;

  /// No description provided for @libraryThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get libraryThisWeek;

  /// No description provided for @libraryEarlier.
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get libraryEarlier;

  /// No description provided for @videoCantPlay.
  ///
  /// In en, this message translates to:
  /// **'This video won\'t play on this device.'**
  String get videoCantPlay;

  /// No description provided for @libraryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'What should we make first?'**
  String get libraryEmptyTitle;

  /// No description provided for @libraryEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Pick one and your bot gets started. Everything your bots make lands here on its own.'**
  String get libraryEmptyBody;

  /// No description provided for @libraryNoMatch.
  ///
  /// In en, this message translates to:
  /// **'Nothing here matches.'**
  String get libraryNoMatch;

  /// No description provided for @libraryStarterGame.
  ///
  /// In en, this message translates to:
  /// **'A small game'**
  String get libraryStarterGame;

  /// No description provided for @libraryStarterGamePrompt.
  ///
  /// In en, this message translates to:
  /// **'Make me a small game I can play in the browser.'**
  String get libraryStarterGamePrompt;

  /// No description provided for @libraryStarterLogo.
  ///
  /// In en, this message translates to:
  /// **'A logo'**
  String get libraryStarterLogo;

  /// No description provided for @libraryStarterLogoPrompt.
  ///
  /// In en, this message translates to:
  /// **'Design a logo for my project.'**
  String get libraryStarterLogoPrompt;

  /// No description provided for @libraryStarterSite.
  ///
  /// In en, this message translates to:
  /// **'A one-page site'**
  String get libraryStarterSite;

  /// No description provided for @libraryStarterSitePrompt.
  ///
  /// In en, this message translates to:
  /// **'Make a one-page website for my business.'**
  String get libraryStarterSitePrompt;

  /// No description provided for @libraryStarterVideo.
  ///
  /// In en, this message translates to:
  /// **'A short video'**
  String get libraryStarterVideo;

  /// No description provided for @libraryStarterVideoPrompt.
  ///
  /// In en, this message translates to:
  /// **'Make a short video of '**
  String get libraryStarterVideoPrompt;

  /// No description provided for @libraryStarterCard.
  ///
  /// In en, this message translates to:
  /// **'A birthday card'**
  String get libraryStarterCard;

  /// No description provided for @libraryStarterCardPrompt.
  ///
  /// In en, this message translates to:
  /// **'Make a birthday card for '**
  String get libraryStarterCardPrompt;

  /// No description provided for @libraryStarterReport.
  ///
  /// In en, this message translates to:
  /// **'A report'**
  String get libraryStarterReport;

  /// No description provided for @libraryStarterReportPrompt.
  ///
  /// In en, this message translates to:
  /// **'Research and write a report on '**
  String get libraryStarterReportPrompt;

  /// No description provided for @libraryStarterElse.
  ///
  /// In en, this message translates to:
  /// **'Something else…'**
  String get libraryStarterElse;

  /// No description provided for @creationOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get creationOpen;

  /// No description provided for @creationPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get creationPlay;

  /// No description provided for @creationView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get creationView;

  /// No description provided for @creationChangeIt.
  ///
  /// In en, this message translates to:
  /// **'Change It'**
  String get creationChangeIt;

  /// No description provided for @creationChangeDraft.
  ///
  /// In en, this message translates to:
  /// **'About “{title}”: '**
  String creationChangeDraft(String title);

  /// No description provided for @creationMadeBy.
  ///
  /// In en, this message translates to:
  /// **'Made by {bot}'**
  String creationMadeBy(String bot);

  /// No description provided for @creationVersion.
  ///
  /// In en, this message translates to:
  /// **'version {n}'**
  String creationVersion(int n);

  /// No description provided for @creationFromChat.
  ///
  /// In en, this message translates to:
  /// **'From your chat with {bot}'**
  String creationFromChat(String bot);

  /// No description provided for @creationFromBot.
  ///
  /// In en, this message translates to:
  /// **'Made by {bot}'**
  String creationFromBot(String bot);

  /// No description provided for @creationFromHelp.
  ///
  /// In en, this message translates to:
  /// **'Go to the conversation'**
  String get creationFromHelp;

  /// No description provided for @creationDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get creationDetails;

  /// No description provided for @creationAlongside.
  ///
  /// In en, this message translates to:
  /// **'Made alongside'**
  String get creationAlongside;

  /// No description provided for @creationDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted “{title}”'**
  String creationDeleted(String title);

  /// No description provided for @showInLibrary.
  ///
  /// In en, this message translates to:
  /// **'Show in Library'**
  String get showInLibrary;

  /// No description provided for @creationWhoCanSee.
  ///
  /// In en, this message translates to:
  /// **'Who Can See It'**
  String get creationWhoCanSee;

  /// No description provided for @libraryTile.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get libraryTile;

  /// No description provided for @libraryTileHelp.
  ///
  /// In en, this message translates to:
  /// **'What it made'**
  String get libraryTileHelp;

  /// No description provided for @regenerateReply.
  ///
  /// In en, this message translates to:
  /// **'Regenerate'**
  String get regenerateReply;

  /// No description provided for @deleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete Message'**
  String get deleteMessage;

  /// No description provided for @deleteMessageTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this message?'**
  String get deleteMessageTitle;

  /// No description provided for @deleteMessageBody.
  ///
  /// In en, this message translates to:
  /// **'It\'s removed for everyone in this chat. The messages around it stay.'**
  String get deleteMessageBody;

  /// No description provided for @messageDeleted.
  ///
  /// In en, this message translates to:
  /// **'Message deleted'**
  String get messageDeleted;

  /// No description provided for @findInChat.
  ///
  /// In en, this message translates to:
  /// **'Find in Chat'**
  String get findInChat;

  /// No description provided for @findInChatHint.
  ///
  /// In en, this message translates to:
  /// **'Find in this chat'**
  String get findInChatHint;

  /// No description provided for @findInChatCount.
  ///
  /// In en, this message translates to:
  /// **'{index} of {count}'**
  String findInChatCount(int index, int count);

  /// No description provided for @findInChatNone.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get findInChatNone;

  /// No description provided for @findPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous match'**
  String get findPrevious;

  /// No description provided for @findNext.
  ///
  /// In en, this message translates to:
  /// **'Next match'**
  String get findNext;

  /// No description provided for @closeFind.
  ///
  /// In en, this message translates to:
  /// **'Close find'**
  String get closeFind;

  /// No description provided for @pinTopic.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get pinTopic;

  /// No description provided for @unpinTopic.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get unpinTopic;

  /// No description provided for @inAppAlertReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get inAppAlertReview;

  /// No description provided for @forBot.
  ///
  /// In en, this message translates to:
  /// **'For bot'**
  String get forBot;

  /// No description provided for @handBack.
  ///
  /// In en, this message translates to:
  /// **'Hand Back'**
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
  /// **'Open Live View'**
  String get openLiveView;

  /// No description provided for @liveExpand.
  ///
  /// In en, this message translates to:
  /// **'Full screen'**
  String get liveExpand;

  /// No description provided for @liveCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get liveCopy;

  /// No description provided for @liveScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Screenshot'**
  String get liveScreenshot;

  /// No description provided for @liveScreenshots.
  ///
  /// In en, this message translates to:
  /// **'Screenshots'**
  String get liveScreenshots;

  /// No description provided for @liveScreenshotsHelp.
  ///
  /// In en, this message translates to:
  /// **'Live video can\'t get through this network, so the screen updates about once a second.'**
  String get liveScreenshotsHelp;

  /// No description provided for @liveReconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting…'**
  String get liveReconnecting;

  /// No description provided for @liveReconnectingHelp.
  ///
  /// In en, this message translates to:
  /// **'The live video was cut off (the server may be restarting). Trying again; screenshots show meanwhile.'**
  String get liveReconnectingHelp;

  /// No description provided for @liveTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get liveTryAgain;

  /// No description provided for @liveDroppedHelp.
  ///
  /// In en, this message translates to:
  /// **'The live video couldn\'t come back, so the screen updates about once a second. Tap Try again.'**
  String get liveDroppedHelp;

  /// No description provided for @liveMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get liveMore;

  /// No description provided for @liveSaveScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Save Screenshot'**
  String get liveSaveScreenshot;

  /// No description provided for @liveCopyFromComputer.
  ///
  /// In en, this message translates to:
  /// **'Copy from the computer'**
  String get liveCopyFromComputer;

  /// No description provided for @livePasteToComputer.
  ///
  /// In en, this message translates to:
  /// **'Paste onto the computer'**
  String get livePasteToComputer;

  /// No description provided for @liveRotateHint.
  ///
  /// In en, this message translates to:
  /// **'Turn your phone sideways for a bigger screen'**
  String get liveRotateHint;

  /// No description provided for @liveWatching.
  ///
  /// In en, this message translates to:
  /// **'Watching'**
  String get liveWatching;

  /// No description provided for @liveCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied from the computer.'**
  String get liveCopied;

  /// No description provided for @liveNothingCopied.
  ///
  /// In en, this message translates to:
  /// **'Nothing was copied. Select something on the computer first.'**
  String get liveNothingCopied;

  /// No description provided for @livePasteEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your clipboard is empty.'**
  String get livePasteEmpty;

  /// No description provided for @liveMinimize.
  ///
  /// In en, this message translates to:
  /// **'Back to the side panel'**
  String get liveMinimize;

  /// No description provided for @liveShownFullScreen.
  ///
  /// In en, this message translates to:
  /// **'The live view is open full screen.'**
  String get liveShownFullScreen;

  /// No description provided for @liveStillWatching.
  ///
  /// In en, this message translates to:
  /// **'Still watching?'**
  String get liveStillWatching;

  /// No description provided for @liveStillWatchingHelp.
  ///
  /// In en, this message translates to:
  /// **'The computer sleeps when nobody\'s watching, to save power.'**
  String get liveStillWatchingHelp;

  /// No description provided for @liveKeepWatching.
  ///
  /// In en, this message translates to:
  /// **'Keep Watching'**
  String get liveKeepWatching;

  /// No description provided for @livePausedToSavePower.
  ///
  /// In en, this message translates to:
  /// **'Paused to save power'**
  String get livePausedToSavePower;

  /// No description provided for @livePausedToSavePowerHelp.
  ///
  /// In en, this message translates to:
  /// **'Nobody was watching, so the computer can rest. Resume wakes it again.'**
  String get livePausedToSavePowerHelp;

  /// No description provided for @liveResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get liveResume;

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

  /// No description provided for @letBotUseTerminal.
  ///
  /// In en, this message translates to:
  /// **'Let it use terminal & files'**
  String get letBotUseTerminal;

  /// No description provided for @screenHandedBack.
  ///
  /// In en, this message translates to:
  /// **'Handed the screen back'**
  String get screenHandedBack;

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
  /// **'Switch to Desktop'**
  String get switchToDesktop;

  /// No description provided for @switchToHeadless.
  ///
  /// In en, this message translates to:
  /// **'Switch to Headless'**
  String get switchToHeadless;

  /// No description provided for @switchProfileConfirm.
  ///
  /// In en, this message translates to:
  /// **'The computer restarts to switch. Your files are kept, but anything running on it now stops.'**
  String get switchProfileConfirm;

  /// No description provided for @switchProfileButton.
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get switchProfileButton;

  /// No description provided for @switchingToDesktop.
  ///
  /// In en, this message translates to:
  /// **'Switching to Desktop…'**
  String get switchingToDesktop;

  /// No description provided for @switchingToHeadless.
  ///
  /// In en, this message translates to:
  /// **'Switching to Headless…'**
  String get switchingToHeadless;

  /// No description provided for @switchedToDesktop.
  ///
  /// In en, this message translates to:
  /// **'Switched to Desktop. Open Live View to watch its screen.'**
  String get switchedToDesktop;

  /// No description provided for @switchedToHeadless.
  ///
  /// In en, this message translates to:
  /// **'Switched to Headless. It uses less memory now.'**
  String get switchedToHeadless;

  /// No description provided for @takeControl.
  ///
  /// In en, this message translates to:
  /// **'Take Control'**
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

  /// No description provided for @liveShellOnTooltip.
  ///
  /// In en, this message translates to:
  /// **'Let the bot keep using its terminal and files while you\'re in control'**
  String get liveShellOnTooltip;

  /// No description provided for @liveShellOffTooltip.
  ///
  /// In en, this message translates to:
  /// **'Pause the bot\'s terminal and files too while you\'re in control'**
  String get liveShellOffTooltip;

  /// No description provided for @liveShellOnNote.
  ///
  /// In en, this message translates to:
  /// **'The bot can keep using its terminal and files. It still can\'t see or use the screen until you hand back.'**
  String get liveShellOnNote;

  /// No description provided for @liveShellOffNote.
  ///
  /// In en, this message translates to:
  /// **'The bot is fully paused until you hand back.'**
  String get liveShellOffNote;

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

  /// No description provided for @dictationEmpty.
  ///
  /// In en, this message translates to:
  /// **'No speech came through. Try again.'**
  String get dictationEmpty;

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

  /// No description provided for @dictateOnDevice.
  ///
  /// In en, this message translates to:
  /// **'Dictate with this device'**
  String get dictateOnDevice;

  /// No description provided for @stopListening.
  ///
  /// In en, this message translates to:
  /// **'Stop listening'**
  String get stopListening;

  /// No description provided for @dictationRetry.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get dictationRetry;

  /// No description provided for @dictationSayAgain.
  ///
  /// In en, this message translates to:
  /// **'Say it again'**
  String get dictationSayAgain;

  /// No description provided for @dictationFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t turn that into text.'**
  String get dictationFailed;

  /// No description provided for @dictationFailedUseDevice.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t turn that into text. Say it again and your device will listen.'**
  String get dictationFailedUseDevice;

  /// No description provided for @dictationNoServiceUseDevice.
  ///
  /// In en, this message translates to:
  /// **'Dictation isn\'t set up for this workspace. Your device can listen instead.'**
  String get dictationNoServiceUseDevice;

  /// No description provided for @dictationDeviceFailed.
  ///
  /// In en, this message translates to:
  /// **'Your device\'s dictation stopped working, so the mic is back on Casama\'s.'**
  String get dictationDeviceFailed;

  /// No description provided for @dictationDevicePermission.
  ///
  /// In en, this message translates to:
  /// **'Allow speech recognition to dictate with this device.'**
  String get dictationDevicePermission;

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

  /// No description provided for @callEndedIdle.
  ///
  /// In en, this message translates to:
  /// **'Ended the call after 2 minutes of silence.'**
  String get callEndedIdle;

  /// No description provided for @callFailed.
  ///
  /// In en, this message translates to:
  /// **'The call could not connect.'**
  String get callFailed;

  /// No description provided for @callListening.
  ///
  /// In en, this message translates to:
  /// **'Listening'**
  String get callListening;

  /// No description provided for @callSpeaking.
  ///
  /// In en, this message translates to:
  /// **'Speaking'**
  String get callSpeaking;

  /// No description provided for @callWorking.
  ///
  /// In en, this message translates to:
  /// **'Working on it'**
  String get callWorking;

  /// No description provided for @callMutedState.
  ///
  /// In en, this message translates to:
  /// **'Muted'**
  String get callMutedState;

  /// No description provided for @callCaptions.
  ///
  /// In en, this message translates to:
  /// **'Captions'**
  String get callCaptions;

  /// No description provided for @callSpeaker.
  ///
  /// In en, this message translates to:
  /// **'Speaker'**
  String get callSpeaker;

  /// No description provided for @callEarpiece.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get callEarpiece;

  /// No description provided for @callBluetooth.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth'**
  String get callBluetooth;

  /// No description provided for @callHeadphones.
  ///
  /// In en, this message translates to:
  /// **'Headphones'**
  String get callHeadphones;

  /// No description provided for @callAudioOutput.
  ///
  /// In en, this message translates to:
  /// **'Play the call through'**
  String get callAudioOutput;

  /// What the bot is doing in a tool step, in everyday words (chats, calls, the computer view).
  ///
  /// In en, this message translates to:
  /// **'{tool, select, memory_search{Searching your memories} memory_write{Saving that to memory} memory{Updating its memory} knowledge_search{Looking through your knowledge} web_search{Searching the web} web{Reading a web page} browser_open{Opening a website} browser_click{Clicking on the page} browser_type{Typing on the page} browser_press{Pressing a key} browser_scroll{Scrolling the page} browser_look{Looking at the page} desktop_click{Clicking on the screen} desktop_type{Typing} desktop_press{Pressing keys} desktop_launch{Opening an app} desktop_look{Looking at the screen} shell{Working on its computer} files_read{Reading a file} files_write{Writing a file} files_list{Looking through files} files_search{Searching files} files_from_chat{Getting a file from the chat} http{Contacting a service} data_search{Looking for data} data_call{Getting data} skills_load{Getting a skill ready} skills_create{Learning a new skill} skills_update{Improving a skill} checkpoint{Saving a restore point} computer_restart{Restarting its computer} takeover{Asking you to take over} delegate{Asking a helper} routines_list{Checking your routines} routines_create{Setting up a routine} routines_update{Updating a routine} routines_delete{Removing a routine} watchers_create{Setting up a watcher} watchers_list{Checking your watchers} watchers_delete{Removing a watcher} tasks_list{Checking your tasks} tasks_create{Adding a task} tasks{Updating your tasks} notify_user{Sending you a note} usage_report{Checking usage} device_read{Reading your device data} device_access{Asking for device access} pages_publish{Publishing a page} pages{Updating a page} media{Making an image} media_video{Making a video} bots_create{Making a new bot} bots_update{Updating a bot} bots_list{Checking your bots} bots_archive{Archiving a bot} channel_send{Sending a message} links_ask{Asking a contact\'s assistant} logins_list{Checking saved logins} replay_run{Repeating saved steps} replay_save{Saving these steps} setup_apply{Suggesting a setup} sidebar_organize{Organizing your sidebar} suggestions_add{Adding a suggestion} teach_save_draft{Saving a draft skill} welcome_name{Picking a name} secrets_request{Asking you for a secret} pages_list{Checking your pages} pages_share{Changing who can see a page} projects_create{Starting a project} projects_status{Checking a project} projects_update{Updating a project} projects{Planning a project} payments{Asking to make a payment} voice_call{Calling a business} voice_call_user{Calling you} tools_load{Getting ready} ui_show{Showing you something} start_task{Starting this in the chat} other{Working on it}}'**
  String toolDoing(String tool);

  /// The same step once it's done.
  ///
  /// In en, this message translates to:
  /// **'{tool, select, memory_search{Searched your memories} memory_write{Saved to memory} memory{Updated its memory} knowledge_search{Looked through your knowledge} web_search{Searched the web} web{Read a web page} browser_open{Opened a website} browser_click{Clicked on the page} browser_type{Typed on the page} browser_press{Pressed a key} browser_scroll{Scrolled the page} browser_look{Looked at the page} desktop_click{Clicked on the screen} desktop_type{Typed} desktop_press{Pressed keys} desktop_launch{Opened an app} desktop_look{Looked at the screen} shell{Worked on its computer} files_read{Read a file} files_write{Wrote a file} files_list{Looked through files} files_search{Searched files} files_from_chat{Got a file from the chat} http{Contacted a service} data_search{Looked for data} data_call{Got data} skills_load{Used a skill} skills_create{Learned a new skill} skills_update{Improved a skill} checkpoint{Saved a restore point} computer_restart{Restarted its computer} takeover{Asked you to take over} delegate{Asked a helper} routines_list{Checked your routines} routines_create{Set up a routine} routines_update{Updated a routine} routines_delete{Removed a routine} watchers_create{Set up a watcher} watchers_list{Checked your watchers} watchers_delete{Removed a watcher} tasks_list{Checked your tasks} tasks_create{Added a task} tasks{Updated your tasks} notify_user{Sent you a note} usage_report{Checked usage} device_read{Read your device data} device_access{Asked for device access} pages_publish{Published a page} pages{Updated a page} media{Made an image} media_video{Made a video} bots_create{Made a new bot} bots_update{Updated a bot} bots_list{Checked your bots} bots_archive{Archived a bot} channel_send{Sent a message} links_ask{Asked a contact\'s assistant} logins_list{Checked saved logins} replay_run{Repeated saved steps} replay_save{Saved these steps} setup_apply{Suggested a setup} sidebar_organize{Organized your sidebar} suggestions_add{Added a suggestion} teach_save_draft{Saved a draft skill} welcome_name{Picked a name} secrets_request{Asked you for a secret} pages_list{Checked your pages} pages_share{Changed who can see a page} projects_create{Started a project} projects_status{Checked a project} projects_update{Updated a project} projects{Planned a project} payments{Asked to make a payment} voice_call{Called a business} voice_call_user{Called you} tools_load{Got ready} ui_show{Showed you something} start_task{Started in the chat} other{Done}}'**
  String toolDid(String tool);

  /// No description provided for @toolUsingApp.
  ///
  /// In en, this message translates to:
  /// **'Using {app}'**
  String toolUsingApp(String app);

  /// No description provided for @toolUsedApp.
  ///
  /// In en, this message translates to:
  /// **'Used {app}'**
  String toolUsedApp(String app);

  /// No description provided for @toolDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get toolDetails;

  /// No description provided for @approvalAsking.
  ///
  /// In en, this message translates to:
  /// **'{bot} is asking first'**
  String approvalAsking(String bot);

  /// No description provided for @approvalLookClosely.
  ///
  /// In en, this message translates to:
  /// **'Look closely before you allow this'**
  String get approvalLookClosely;

  /// No description provided for @approvalDontAskAgain.
  ///
  /// In en, this message translates to:
  /// **'Don\'t ask {bot} again for this'**
  String approvalDontAskAgain(String bot);

  /// No description provided for @pageShareToPublic.
  ///
  /// In en, this message translates to:
  /// **'Anyone with the link will be able to open it'**
  String get pageShareToPublic;

  /// No description provided for @pageShareToWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Everyone in this workspace will be able to open it'**
  String get pageShareToWorkspace;

  /// No description provided for @pageShareToPrivate.
  ///
  /// In en, this message translates to:
  /// **'Only you will be able to open it'**
  String get pageShareToPrivate;

  /// No description provided for @approvalAllowedLine.
  ///
  /// In en, this message translates to:
  /// **'Allowed: {what}'**
  String approvalAllowedLine(String what);

  /// No description provided for @approvalDeclinedLine.
  ///
  /// In en, this message translates to:
  /// **'Declined: {what}'**
  String approvalDeclinedLine(String what);

  /// No description provided for @approvalExpiredLine.
  ///
  /// In en, this message translates to:
  /// **'No answer in time: {what}'**
  String approvalExpiredLine(String what);

  /// No description provided for @callToolFailed.
  ///
  /// In en, this message translates to:
  /// **'That didn\'t work'**
  String get callToolFailed;

  /// No description provided for @callToolNeedsOk.
  ///
  /// In en, this message translates to:
  /// **'Needs your OK to go ahead'**
  String get callToolNeedsOk;

  /// No description provided for @callToolAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get callToolAllow;

  /// No description provided for @callToolNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not Now'**
  String get callToolNotNow;

  /// No description provided for @callToolAllowed.
  ///
  /// In en, this message translates to:
  /// **'Allowed. The result will show in the chat'**
  String get callToolAllowed;

  /// No description provided for @callToolDeclined.
  ///
  /// In en, this message translates to:
  /// **'You said not now'**
  String get callToolDeclined;

  /// No description provided for @callToolBackground.
  ///
  /// In en, this message translates to:
  /// **'Still working. The result will show in the chat'**
  String get callToolBackground;

  /// No description provided for @callToolInChat.
  ///
  /// In en, this message translates to:
  /// **'The result will show in the chat'**
  String get callToolInChat;

  /// No description provided for @callToolSeconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s'**
  String callToolSeconds(int seconds);

  /// No description provided for @callNeedsKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Calls need a Google AI key'**
  String get callNeedsKeyTitle;

  /// No description provided for @callNeedsKeyBody.
  ///
  /// In en, this message translates to:
  /// **'Live calls run on Google\'s Gemini Live, so this workspace needs a Google AI key. It\'s only used for calls: read aloud, dictation, images and video run on OpenRouter. Google gives you one free in AI Studio: create it there, then add it under Model keys and calls work right away. Only workspace owners and admins can add keys.'**
  String get callNeedsKeyBody;

  /// No description provided for @callAddKey.
  ///
  /// In en, this message translates to:
  /// **'Add a Google AI key'**
  String get callAddKey;

  /// No description provided for @callGetFreeKey.
  ///
  /// In en, this message translates to:
  /// **'Get a free key from Google'**
  String get callGetFreeKey;

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

  /// No description provided for @callSwitchTitle.
  ///
  /// In en, this message translates to:
  /// **'End call with {from} and call {to}?'**
  String callSwitchTitle(String from, String to);

  /// No description provided for @callSwitchBody.
  ///
  /// In en, this message translates to:
  /// **'You can be on one call at a time. The current call is saved to its chat first.'**
  String get callSwitchBody;

  /// No description provided for @callSwitchConfirm.
  ///
  /// In en, this message translates to:
  /// **'End and Call'**
  String get callSwitchConfirm;

  /// No description provided for @callEndedLost.
  ///
  /// In en, this message translates to:
  /// **'The call ended because the connection was lost for too long.'**
  String get callEndedLost;

  /// No description provided for @callMinimize.
  ///
  /// In en, this message translates to:
  /// **'Minimize'**
  String get callMinimize;

  /// No description provided for @callEndCall.
  ///
  /// In en, this message translates to:
  /// **'End Call'**
  String get callEndCall;

  /// No description provided for @callEndAndAnswer.
  ///
  /// In en, this message translates to:
  /// **'End and Answer'**
  String get callEndAndAnswer;

  /// No description provided for @callReconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting…'**
  String get callReconnecting;

  /// No description provided for @callMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{under a minute} =1{1 minute} other{{count} minutes}}'**
  String callMinutes(int count);

  /// No description provided for @callBubbleLabel.
  ///
  /// In en, this message translates to:
  /// **'Call with {bot}, {time}, tap to return'**
  String callBubbleLabel(String bot, String time);

  /// No description provided for @callReturnBar.
  ///
  /// In en, this message translates to:
  /// **'On a call with {bot}, tap to return'**
  String callReturnBar(String bot);

  /// No description provided for @callOpen.
  ///
  /// In en, this message translates to:
  /// **'Open Call'**
  String get callOpen;

  /// No description provided for @callOnHold.
  ///
  /// In en, this message translates to:
  /// **'On hold'**
  String get callOnHold;

  /// No description provided for @callNotificationLive.
  ///
  /// In en, this message translates to:
  /// **'On a call'**
  String get callNotificationLive;

  /// No description provided for @callNotificationMuted.
  ///
  /// In en, this message translates to:
  /// **'Muted'**
  String get callNotificationMuted;

  /// No description provided for @callNotificationChannel.
  ///
  /// In en, this message translates to:
  /// **'Calls'**
  String get callNotificationChannel;

  /// No description provided for @callTabTitle.
  ///
  /// In en, this message translates to:
  /// **'On a call · {time}'**
  String callTabTitle(String time);

  /// No description provided for @callMenuShow.
  ///
  /// In en, this message translates to:
  /// **'Show Call'**
  String get callMenuShow;

  /// No description provided for @callJobWorking.
  ///
  /// In en, this message translates to:
  /// **'Working on it'**
  String get callJobWorking;

  /// No description provided for @callJobStrip.
  ///
  /// In en, this message translates to:
  /// **'Working on: {task}'**
  String callJobStrip(String task);

  /// No description provided for @callJobNeedsYou.
  ///
  /// In en, this message translates to:
  /// **'Needs you: {task}'**
  String callJobNeedsYou(String task);

  /// No description provided for @callTileWatching.
  ///
  /// In en, this message translates to:
  /// **'Live view'**
  String get callTileWatching;

  /// No description provided for @callTileDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get callTileDone;

  /// No description provided for @callTileNeedsYou.
  ///
  /// In en, this message translates to:
  /// **'Needs you'**
  String get callTileNeedsYou;

  /// No description provided for @callTileLabel.
  ///
  /// In en, this message translates to:
  /// **'The bot\'s screen, {state}. Tap to see it full size'**
  String callTileLabel(String state);

  /// No description provided for @callTileHide.
  ///
  /// In en, this message translates to:
  /// **'Hide Screen'**
  String get callTileHide;

  /// No description provided for @callRecapTitle.
  ///
  /// In en, this message translates to:
  /// **'Call · {length}'**
  String callRecapTitle(String length);

  /// No description provided for @callRecapStarted.
  ///
  /// In en, this message translates to:
  /// **'Started on the call'**
  String get callRecapStarted;

  /// No description provided for @callRecapTaskDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get callRecapTaskDone;

  /// No description provided for @callRecapTaskFailed.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t finish'**
  String get callRecapTaskFailed;

  /// No description provided for @callRecapTaskStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get callRecapTaskStopped;

  /// No description provided for @callRecapTaskRunning.
  ///
  /// In en, this message translates to:
  /// **'Still working'**
  String get callRecapTaskRunning;

  /// No description provided for @callRecapOpenRun.
  ///
  /// In en, this message translates to:
  /// **'See what it did'**
  String get callRecapOpenRun;

  /// No description provided for @summarizeCalls.
  ///
  /// In en, this message translates to:
  /// **'Summarize calls'**
  String get summarizeCalls;

  /// No description provided for @summarizeCallsHelp.
  ///
  /// In en, this message translates to:
  /// **'After each call, its card says what it was about and what\'s next. Uses a little of the bot\'s small model.'**
  String get summarizeCallsHelp;

  /// No description provided for @callCardVoice.
  ///
  /// In en, this message translates to:
  /// **'Voice call · {length}'**
  String callCardVoice(String length);

  /// No description provided for @callCardPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone call · {length}'**
  String callCardPhone(String length);

  /// No description provided for @callCardDropped.
  ///
  /// In en, this message translates to:
  /// **'Call dropped · {length}'**
  String callCardDropped(String length);

  /// No description provided for @callCardMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed call from {name}'**
  String callCardMissed(String name);

  /// No description provided for @callCardLive.
  ///
  /// In en, this message translates to:
  /// **'On a call with {name}'**
  String callCardLive(String name);

  /// No description provided for @callCardLiveElsewhere.
  ///
  /// In en, this message translates to:
  /// **'On a call on another device'**
  String get callCardLiveElsewhere;

  /// No description provided for @callCardReturn.
  ///
  /// In en, this message translates to:
  /// **'Return to call'**
  String get callCardReturn;

  /// No description provided for @callCardBotHungUp.
  ///
  /// In en, this message translates to:
  /// **'{name} hung up'**
  String callCardBotHungUp(String name);

  /// No description provided for @callCardEndedQuiet.
  ///
  /// In en, this message translates to:
  /// **'Ended after a quiet stretch'**
  String get callCardEndedQuiet;

  /// No description provided for @callCardEndedLimit.
  ///
  /// In en, this message translates to:
  /// **'Ended at the call limit'**
  String get callCardEndedLimit;

  /// No description provided for @callCardWritingSummary.
  ///
  /// In en, this message translates to:
  /// **'Writing a summary…'**
  String get callCardWritingSummary;

  /// No description provided for @callCardSummaryBy.
  ///
  /// In en, this message translates to:
  /// **'Summary by {name}'**
  String callCardSummaryBy(String name);

  /// No description provided for @callCardNextSteps.
  ///
  /// In en, this message translates to:
  /// **'Next steps'**
  String get callCardNextSteps;

  /// No description provided for @callCardDoIt.
  ///
  /// In en, this message translates to:
  /// **'Do it'**
  String get callCardDoIt;

  /// No description provided for @callCardDismissStep.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get callCardDismissStep;

  /// No description provided for @callCardStepStarted.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get callCardStepStarted;

  /// No description provided for @callCardStepFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t start that. Try again.'**
  String get callCardStepFailed;

  /// No description provided for @callCardDoneOnCall.
  ///
  /// In en, this message translates to:
  /// **'Done on the call'**
  String get callCardDoneOnCall;

  /// No description provided for @callCardMore.
  ///
  /// In en, this message translates to:
  /// **'{count} more'**
  String callCardMore(int count);

  /// No description provided for @callCardTranscript.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Transcript · 1 turn} other{Transcript · {count} turns}}'**
  String callCardTranscript(int count);

  /// No description provided for @callCardTranscriptTitle.
  ///
  /// In en, this message translates to:
  /// **'Transcript'**
  String get callCardTranscriptTitle;

  /// No description provided for @callCardSearchTranscript.
  ///
  /// In en, this message translates to:
  /// **'Search the transcript'**
  String get callCardSearchTranscript;

  /// No description provided for @callCardNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get callCardNoMatches;

  /// No description provided for @callCardYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get callCardYou;

  /// No description provided for @callCardCallBack.
  ///
  /// In en, this message translates to:
  /// **'Call back'**
  String get callCardCallBack;

  /// No description provided for @callCardCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get callCardCopy;

  /// No description provided for @callCardCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get callCardCopied;

  /// No description provided for @callCardShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get callCardShare;

  /// No description provided for @callCardMoreActions.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get callCardMoreActions;

  /// No description provided for @callCardDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete call'**
  String get callCardDelete;

  /// No description provided for @callCardDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this call?'**
  String get callCardDeleteTitle;

  /// No description provided for @callCardDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Its card and transcript are removed from this chat. Jobs it started keep their results.'**
  String get callCardDeleteBody;

  /// No description provided for @callCardDeleted.
  ///
  /// In en, this message translates to:
  /// **'Call deleted'**
  String get callCardDeleted;

  /// No description provided for @callCardDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete the call'**
  String get callCardDeleteFailed;

  /// No description provided for @callCardSemantics.
  ///
  /// In en, this message translates to:
  /// **'{title}. {summary}'**
  String callCardSemantics(String title, String summary);

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
  /// **'Read-aloud voice and the tools a bot has on calls'**
  String get voiceSettingsHelp;

  /// No description provided for @callTools.
  ///
  /// In en, this message translates to:
  /// **'Tools on Calls'**
  String get callTools;

  /// No description provided for @callToolsHelp.
  ///
  /// In en, this message translates to:
  /// **'Calls already include memory, web search, notes to you, routines and tickets, and hand bigger jobs to the chat. Add connected-app tools the bot should use live; each one adds a little to every call\'s cost.'**
  String get callToolsHelp;

  /// No description provided for @callToolsNone.
  ///
  /// In en, this message translates to:
  /// **'This bot has no connected apps turned on yet. Turn one on in its Integrations, then pick its tools here.'**
  String get callToolsNone;

  /// Button in Tools on Calls when the bot has no apps: opens the bot's Integrations screen.
  ///
  /// In en, this message translates to:
  /// **'Open Integrations'**
  String get openIntegrations;

  /// No description provided for @callToolsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Only the built-in voice tools} =1{1 connected-app tool added} other{{count} connected-app tools added}}'**
  String callToolsCount(int count);

  /// No description provided for @voiceId.
  ///
  /// In en, this message translates to:
  /// **'Voice id (optional)'**
  String get voiceId;

  /// No description provided for @voiceIdHelp.
  ///
  /// In en, this message translates to:
  /// **'A Gemini voice name, such as Kore or Puck; empty uses Kore'**
  String get voiceIdHelp;

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
  /// **'Cannot reach Casama; retrying'**
  String get companionError;

  /// No description provided for @companionOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get companionOff;

  /// No description provided for @companionCapabilities.
  ///
  /// In en, this message translates to:
  /// **'What Bots May Do'**
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
  /// **'Shared Folders'**
  String get sharedFolders;

  /// No description provided for @sharedFoldersHelp.
  ///
  /// In en, this message translates to:
  /// **'Bots can only reach these folders.'**
  String get sharedFoldersHelp;

  /// No description provided for @addFolder.
  ///
  /// In en, this message translates to:
  /// **'Add a Folder'**
  String get addFolder;

  /// No description provided for @botsAllowed.
  ///
  /// In en, this message translates to:
  /// **'Bots Allowed'**
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

  /// No description provided for @adminLockNow.
  ///
  /// In en, this message translates to:
  /// **'Lock now'**
  String get adminLockNow;

  /// No description provided for @adminUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock admin console'**
  String get adminUnlock;

  /// No description provided for @adminLockedHelp.
  ///
  /// In en, this message translates to:
  /// **'The admin console is locked. Verify your password or use a fresh email code. It locks after 5 minutes without activity and when you leave the app.'**
  String get adminLockedHelp;

  /// No description provided for @adminConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm admin action'**
  String get adminConfirmAction;

  /// No description provided for @adminConfirmActionHelp.
  ///
  /// In en, this message translates to:
  /// **'This action changes the instance. Verify your password or a fresh email code to continue.'**
  String get adminConfirmActionHelp;

  /// No description provided for @adminVerifyPassword.
  ///
  /// In en, this message translates to:
  /// **'Verify password'**
  String get adminVerifyPassword;

  /// No description provided for @adminSendCode.
  ///
  /// In en, this message translates to:
  /// **'Send an email code'**
  String get adminSendCode;

  /// No description provided for @adminCodeSent.
  ///
  /// In en, this message translates to:
  /// **'We sent a code to your account email. Enter it below to continue.'**
  String get adminCodeSent;

  /// No description provided for @adminVerifyCode.
  ///
  /// In en, this message translates to:
  /// **'Verify code'**
  String get adminVerifyCode;

  /// No description provided for @adminAuthenticationFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not verify your identity. Check your password or code and try again.'**
  String get adminAuthenticationFailed;

  /// No description provided for @adminTwoStepHelp.
  ///
  /// In en, this message translates to:
  /// **'Your account uses two-step sign-in. Enter the 6-digit code from your authenticator app to finish.'**
  String get adminTwoStepHelp;

  /// No description provided for @adminTwoStepTip.
  ///
  /// In en, this message translates to:
  /// **'Tip: turn on two-step sign-in in Settings. Without it, anyone who can read your email on this device can unlock the console with an emailed code.'**
  String get adminTwoStepTip;

  /// No description provided for @adminUnlockDevice.
  ///
  /// In en, this message translates to:
  /// **'Unlock with Face ID or fingerprint'**
  String get adminUnlockDevice;

  /// No description provided for @adminDeviceReason.
  ///
  /// In en, this message translates to:
  /// **'Unlock the admin console'**
  String get adminDeviceReason;

  /// No description provided for @adminVerifyPasskey.
  ///
  /// In en, this message translates to:
  /// **'Verify with a passkey'**
  String get adminVerifyPasskey;

  /// No description provided for @adminOrPassword.
  ///
  /// In en, this message translates to:
  /// **'or use your password'**
  String get adminOrPassword;

  /// No description provided for @adminPasskeyTip.
  ///
  /// In en, this message translates to:
  /// **'Tip: add a passkey in Settings → Passkeys to verify with Face ID or a fingerprint instead of your password.'**
  String get adminPasskeyTip;

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

  /// No description provided for @cloudModelsTitle.
  ///
  /// In en, this message translates to:
  /// **'Cloud Models'**
  String get cloudModelsTitle;

  /// No description provided for @cloudModelsHelp.
  ///
  /// In en, this message translates to:
  /// **'Applies to every Cloud server within seconds.'**
  String get cloudModelsHelp;

  /// No description provided for @connectionsTitle.
  ///
  /// In en, this message translates to:
  /// **'App Connections'**
  String get connectionsTitle;

  /// No description provided for @connectionsServerComposio.
  ///
  /// In en, this message translates to:
  /// **'Casama\'s Composio Account'**
  String get connectionsServerComposio;

  /// No description provided for @connectionsServerComposioHelp.
  ///
  /// In en, this message translates to:
  /// **'Apps without their own sign-in connect in one click through this server\'s Composio account.'**
  String get connectionsServerComposioHelp;

  /// No description provided for @connectionsOwnAccounts.
  ///
  /// In en, this message translates to:
  /// **'People\'s Own Accounts'**
  String get connectionsOwnAccounts;

  /// No description provided for @connectionsOwnAccountsHelp.
  ///
  /// In en, this message translates to:
  /// **'Each person uses their own Composio, Pipedream or Zapier.'**
  String get connectionsOwnAccountsHelp;

  /// No description provided for @connectionsNoComposioKey.
  ///
  /// In en, this message translates to:
  /// **'Add COMPOSIO_API_KEY to this server to use Casama\'s account.'**
  String get connectionsNoComposioKey;

  /// No description provided for @connectionsGoogleTitle.
  ///
  /// In en, this message translates to:
  /// **'Google Apps'**
  String get connectionsGoogleTitle;

  /// No description provided for @connectionsGoogleComposio.
  ///
  /// In en, this message translates to:
  /// **'Through Composio'**
  String get connectionsGoogleComposio;

  /// No description provided for @connectionsGoogleComposioHelp.
  ///
  /// In en, this message translates to:
  /// **'Gmail, Calendar, Drive and more work right away.'**
  String get connectionsGoogleComposioHelp;

  /// No description provided for @connectionsGoogleDirect.
  ///
  /// In en, this message translates to:
  /// **'Google\'s Own Servers'**
  String get connectionsGoogleDirect;

  /// No description provided for @connectionsGoogleDirectHelp.
  ///
  /// In en, this message translates to:
  /// **'Needs Google Workspace Developer Preview enrollment.'**
  String get connectionsGoogleDirectHelp;

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
  /// **'Casama {latest} is available (you run {current})'**
  String updateAvailable(String latest, String current);

  /// No description provided for @casamaVersion.
  ///
  /// In en, this message translates to:
  /// **'Casama {version}'**
  String casamaVersion(String version);

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
  /// **'Connecting to Casama…'**
  String get connectingToServer;

  /// No description provided for @cannotReachServer.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach your Casama server'**
  String get cannotReachServer;

  /// No description provided for @connectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach your Casama server. Check your connection and try again.'**
  String get connectionFailed;

  /// No description provided for @serverNotResponding.
  ///
  /// In en, this message translates to:
  /// **'Your Casama server isn\'t responding right now. Try again in a moment.'**
  String get serverNotResponding;

  /// No description provided for @cannotReachServerHelp.
  ///
  /// In en, this message translates to:
  /// **'Check your connection, or that the server at {url} is running.'**
  String cannotReachServerHelp(String url);

  /// No description provided for @serverUnreachableBody.
  ///
  /// In en, this message translates to:
  /// **'Check that you\'re online. If you are, the server may be restarting, so we\'ll keep trying.'**
  String get serverUnreachableBody;

  /// No description provided for @retryingIn.
  ///
  /// In en, this message translates to:
  /// **'Trying again in {seconds}s'**
  String retryingIn(int seconds);

  /// No description provided for @retryingNow.
  ///
  /// In en, this message translates to:
  /// **'Trying…'**
  String get retryingNow;

  /// No description provided for @upgradeTitle.
  ///
  /// In en, this message translates to:
  /// **'Upgrade Your Plan'**
  String get upgradeTitle;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not Now'**
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
  /// **'Billing is off on this server. Self-hosted Casama has no limits.'**
  String get billingOffSelfHosted;

  /// No description provided for @restorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore Purchases'**
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
  /// **'Subscribe on the Web'**
  String get subscribeOnWeb;

  /// No description provided for @credits.
  ///
  /// In en, this message translates to:
  /// **'Credits'**
  String get credits;

  /// No description provided for @creditHistory.
  ///
  /// In en, this message translates to:
  /// **'Credit History'**
  String get creditHistory;

  /// No description provided for @creditReasonPurchase.
  ///
  /// In en, this message translates to:
  /// **'Credits bought'**
  String get creditReasonPurchase;

  /// No description provided for @creditReasonGrant.
  ///
  /// In en, this message translates to:
  /// **'Credits added'**
  String get creditReasonGrant;

  /// No description provided for @creditReasonRefund.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get creditReasonRefund;

  /// No description provided for @creditReasonAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Adjustment'**
  String get creditReasonAdjustment;

  /// No description provided for @creditReasonExpire.
  ///
  /// In en, this message translates to:
  /// **'Credits expired'**
  String get creditReasonExpire;

  /// No description provided for @limitBots.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 bot} other{{count} bots}}'**
  String limitBots(int count);

  /// No description provided for @limitBotsUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited bots'**
  String get limitBotsUnlimited;

  /// No description provided for @unlimitedValue.
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get unlimitedValue;

  /// No description provided for @trialDaysFree.
  ///
  /// In en, this message translates to:
  /// **'{n} days free'**
  String trialDaysFree(int n);

  /// No description provided for @extraPeople.
  ///
  /// In en, this message translates to:
  /// **'Extra People'**
  String get extraPeople;

  /// No description provided for @extraPeopleHelp.
  ///
  /// In en, this message translates to:
  /// **'{price} per person a month, on top of the {seats} your plan includes.'**
  String extraPeopleHelp(String price, int seats);

  /// No description provided for @extraPeopleSaved.
  ///
  /// In en, this message translates to:
  /// **'Extra people updated'**
  String get extraPeopleSaved;

  /// No description provided for @limitComputerHours.
  ///
  /// In en, this message translates to:
  /// **'{hours} computer hours a month'**
  String limitComputerHours(int hours);

  /// No description provided for @limitCredits.
  ///
  /// In en, this message translates to:
  /// **'{amount} credits a month'**
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
  /// **'Credits: {amount}'**
  String creditsBalance(String amount);

  /// No description provided for @manageSubscription.
  ///
  /// In en, this message translates to:
  /// **'Manage Subscription'**
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

  /// No description provided for @linkCloud.
  ///
  /// In en, this message translates to:
  /// **'Casama Link'**
  String get linkCloud;

  /// No description provided for @linkCloudHelp.
  ///
  /// In en, this message translates to:
  /// **'Connect a self-hosted Casama to this workspace. A public address and notifications are free; cloud computers and model credits are billed here.'**
  String get linkCloudHelp;

  /// No description provided for @linkCloudNewKey.
  ///
  /// In en, this message translates to:
  /// **'New Casama Link Key'**
  String get linkCloudNewKey;

  /// No description provided for @linkCloudKeyCreated.
  ///
  /// In en, this message translates to:
  /// **'Key Created'**
  String get linkCloudKeyCreated;

  /// No description provided for @linkCloudKeyOnce.
  ///
  /// In en, this message translates to:
  /// **'Copy it now; it is shown only once. Set it on your server with CASAMA_CLOUD_URL.'**
  String get linkCloudKeyOnce;

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
  /// **'Use a Different Server'**
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
  /// **'Export My Data'**
  String get exportMyData;

  /// No description provided for @exportMyDataHelp.
  ///
  /// In en, this message translates to:
  /// **'Bots, chats, runs, memories and settings. No secrets.'**
  String get exportMyDataHelp;

  /// No description provided for @exportReady.
  ///
  /// In en, this message translates to:
  /// **'Export ready ({kb} KB)'**
  String exportReady(String kb);

  /// No description provided for @runHistoryRetention.
  ///
  /// In en, this message translates to:
  /// **'Keep Run History For'**
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
  /// **'Delete My Account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountHelp.
  ///
  /// In en, this message translates to:
  /// **'Erases your data after a short grace period.'**
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
  /// **'Account Scheduled for Deletion'**
  String get accountDeleted;

  /// No description provided for @accountDeletedBody.
  ///
  /// In en, this message translates to:
  /// **'You have been signed out. Your data will be erased on {date}.'**
  String accountDeletedBody(String date);

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
  /// **'Ask {bot} anything, or tap an idea below to get started.'**
  String chatEmptySubtitle(String bot);

  /// No description provided for @suggestPlanDay.
  ///
  /// In en, this message translates to:
  /// **'Help me plan my day'**
  String get suggestPlanDay;

  /// No description provided for @suggestWriteMessage.
  ///
  /// In en, this message translates to:
  /// **'Help me write a message'**
  String get suggestWriteMessage;

  /// No description provided for @suggestExplain.
  ///
  /// In en, this message translates to:
  /// **'Look something up and explain it simply'**
  String get suggestExplain;

  /// No description provided for @suggestCapabilities.
  ///
  /// In en, this message translates to:
  /// **'What can you help me with?'**
  String get suggestCapabilities;

  /// What the person did, shown in the welcome chat after connecting an app from a card.
  ///
  /// In en, this message translates to:
  /// **'Connected {app}'**
  String connectedAppSummary(String app);

  /// No description provided for @connectAppsTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect your apps'**
  String get connectAppsTitle;

  /// No description provided for @moreApps.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreApps;

  /// No description provided for @addAppTile.
  ///
  /// In en, this message translates to:
  /// **'Add {app} to this bot'**
  String addAppTile(String app);

  /// No description provided for @appAddedToBot.
  ///
  /// In en, this message translates to:
  /// **'{app} added to {bot}'**
  String appAddedToBot(String app, String bot);

  /// No description provided for @connectAppsHint.
  ///
  /// In en, this message translates to:
  /// **'Let me read and act in the tools you already use.'**
  String get connectAppsHint;

  /// Screen-reader label for an app tile in an empty chat.
  ///
  /// In en, this message translates to:
  /// **'Connect {app}'**
  String connectAppTile(String app);

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

  /// No description provided for @notificationsPrimerBubble.
  ///
  /// In en, this message translates to:
  /// **'Don\'t miss a thing!'**
  String get notificationsPrimerBubble;

  /// No description provided for @notificationsPrimerTitle.
  ///
  /// In en, this message translates to:
  /// **'Turn on notifications'**
  String get notificationsPrimerTitle;

  /// No description provided for @notificationsPrimerBody.
  ///
  /// In en, this message translates to:
  /// **'Your bots tell you when they need a decision from you, or when their work is ready.'**
  String get notificationsPrimerBody;

  /// No description provided for @notificationsPrimerBlockedBody.
  ///
  /// In en, this message translates to:
  /// **'Chrome is blocking notifications for this site. Allow them from the lock in the address bar, then tap Turn on again.'**
  String get notificationsPrimerBlockedBody;

  /// No description provided for @notificationsTurnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn On'**
  String get notificationsTurnOn;

  /// No description provided for @importAgentHelp.
  ///
  /// In en, this message translates to:
  /// **'Bring a bot over from OpenClaw or Hermes Agent, or paste a setup from Grok Bot, Muse, ChatGPT Dots, Claude Duet, Hark or Instinct: its persona, skills, schedules and memories. You\'ll review everything before it\'s created. Keys and settings files are never read.'**
  String get importAgentHelp;

  /// No description provided for @checkForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get checkForUpdates;

  /// No description provided for @autoUpdates.
  ///
  /// In en, this message translates to:
  /// **'Update Automatically'**
  String get autoUpdates;

  /// No description provided for @autoUpdatesHelp.
  ///
  /// In en, this message translates to:
  /// **'Installs new versions when you quit.'**
  String get autoUpdatesHelp;

  /// No description provided for @upToDate.
  ///
  /// In en, this message translates to:
  /// **'Casama Is Up to Date'**
  String get upToDate;

  /// No description provided for @updateReady.
  ///
  /// In en, this message translates to:
  /// **'Casama {version} is available'**
  String updateReady(String version);

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String appVersion(String version);

  /// No description provided for @whatsNewTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s New in Casama {version}'**
  String whatsNewTitle(String version);

  /// No description provided for @whatsNewGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got It'**
  String get whatsNewGotIt;

  /// No description provided for @whatsNewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Here\'s what changed since your last update.'**
  String get whatsNewSubtitle;

  /// No description provided for @whatsNew010Calls.
  ///
  /// In en, this message translates to:
  /// **'Call your bots and talk things through. They answer out loud, with captions.'**
  String get whatsNew010Calls;

  /// No description provided for @whatsNew010Looks.
  ///
  /// In en, this message translates to:
  /// **'Make Casama yours: themes, color schemes, fonts and wallpapers in Settings → Appearance, with more from the gallery.'**
  String get whatsNew010Looks;

  /// No description provided for @whatsNew010AboutYou.
  ///
  /// In en, this message translates to:
  /// **'Tell your bots about yourself once, in Settings → About you: what to call you and how you like replies.'**
  String get whatsNew010AboutYou;

  /// No description provided for @whatsNew010SignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in with a passkey, Apple, Google or a code from your email.'**
  String get whatsNew010SignIn;

  /// No description provided for @openAtLogin.
  ///
  /// In en, this message translates to:
  /// **'Open at Login'**
  String get openAtLogin;

  /// No description provided for @openAtLoginHelp.
  ///
  /// In en, this message translates to:
  /// **'Ready for the quick-ask shortcut.'**
  String get openAtLoginHelp;

  /// No description provided for @signInTagline.
  ///
  /// In en, this message translates to:
  /// **'Teammates that keep working after you close the app.'**
  String get signInTagline;

  /// No description provided for @signInTagline2.
  ///
  /// In en, this message translates to:
  /// **'Meet your AI crew.'**
  String get signInTagline2;

  /// No description provided for @signInTagline3.
  ///
  /// In en, this message translates to:
  /// **'AI that doesn\'t just talk. It gets things done.'**
  String get signInTagline3;

  /// No description provided for @signInTagline4.
  ///
  /// In en, this message translates to:
  /// **'Capable teammates that ask before they act.'**
  String get signInTagline4;

  /// No description provided for @signInTagline5.
  ///
  /// In en, this message translates to:
  /// **'Hand it off. Come back to it done.'**
  String get signInTagline5;

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
  /// **'Get an OpenRouter Key'**
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
  /// **'recommended: chat, images, video, voice'**
  String get providerHintOpenRouter;

  /// No description provided for @providerHintGoogle.
  ///
  /// In en, this message translates to:
  /// **'live calls only'**
  String get providerHintGoogle;

  /// No description provided for @providerHintCompatible.
  ///
  /// In en, this message translates to:
  /// **'Ollama, LM Studio, vLLM'**
  String get providerHintCompatible;

  /// No description provided for @providerHintSearch.
  ///
  /// In en, this message translates to:
  /// **'web search'**
  String get providerHintSearch;

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

  /// No description provided for @routineEnds.
  ///
  /// In en, this message translates to:
  /// **'Ends'**
  String get routineEnds;

  /// No description provided for @routineEndsNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get routineEndsNever;

  /// No description provided for @routineEndsOnDate.
  ///
  /// In en, this message translates to:
  /// **'On a date'**
  String get routineEndsOnDate;

  /// No description provided for @routineEndsAfterRuns.
  ///
  /// In en, this message translates to:
  /// **'After some runs'**
  String get routineEndsAfterRuns;

  /// No description provided for @routineEndDate.
  ///
  /// In en, this message translates to:
  /// **'Last day'**
  String get routineEndDate;

  /// No description provided for @routineRunCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Runs'**
  String get routineRunCountLabel;

  /// No description provided for @routineRunsCount.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 run} other{{n} runs}}'**
  String routineRunsCount(int n);

  /// No description provided for @routineEndsAt.
  ///
  /// In en, this message translates to:
  /// **'Ends {when}'**
  String routineEndsAt(String when);

  /// No description provided for @routineRunsLeft.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{No runs left} =1{1 run left} other{{n} runs left}}'**
  String routineRunsLeft(int n);

  /// No description provided for @routineChangeEnd.
  ///
  /// In en, this message translates to:
  /// **'When It Ends'**
  String get routineChangeEnd;

  /// No description provided for @routineEndTitle.
  ///
  /// In en, this message translates to:
  /// **'When it ends'**
  String get routineEndTitle;

  /// No description provided for @routineEndSubtitle.
  ///
  /// In en, this message translates to:
  /// **'It switches itself off then. A new number of runs counts from now.'**
  String get routineEndSubtitle;

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

  /// No description provided for @openInSystemPlayer.
  ///
  /// In en, this message translates to:
  /// **'Open in your video player'**
  String get openInSystemPlayer;

  /// No description provided for @playMedia.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get playMedia;

  /// No description provided for @fullScreen.
  ///
  /// In en, this message translates to:
  /// **'Full screen'**
  String get fullScreen;

  /// No description provided for @exitFullScreen.
  ///
  /// In en, this message translates to:
  /// **'Exit full screen'**
  String get exitFullScreen;

  /// No description provided for @pdfPageCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 page} other{{count} pages}}'**
  String pdfPageCount(int count);

  /// No description provided for @openInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Open in Browser'**
  String get openInBrowser;

  /// No description provided for @convertingToPdf.
  ///
  /// In en, this message translates to:
  /// **'Getting a preview ready…'**
  String get convertingToPdf;

  /// No description provided for @tableFirstRows.
  ///
  /// In en, this message translates to:
  /// **'Showing the first {count} rows'**
  String tableFirstRows(int count);

  /// No description provided for @imageCouldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this picture'**
  String get imageCouldNotLoad;

  /// No description provided for @mediaKindImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get mediaKindImage;

  /// No description provided for @mediaKindVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get mediaKindVideo;

  /// No description provided for @mediaKindAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get mediaKindAudio;

  /// No description provided for @mediaKindPdf.
  ///
  /// In en, this message translates to:
  /// **'PDF'**
  String get mediaKindPdf;

  /// No description provided for @openFileInChat.
  ///
  /// In en, this message translates to:
  /// **'Open File'**
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

  /// No description provided for @editPhoto.
  ///
  /// In en, this message translates to:
  /// **'Edit photo'**
  String get editPhoto;

  /// No description provided for @retryUpload.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retryUpload;

  /// No description provided for @uploadingAttachments.
  ///
  /// In en, this message translates to:
  /// **'Uploading…'**
  String get uploadingAttachments;

  /// No description provided for @notSent.
  ///
  /// In en, this message translates to:
  /// **'Not sent'**
  String get notSent;

  /// No description provided for @deleteChat.
  ///
  /// In en, this message translates to:
  /// **'Delete Chat'**
  String get deleteChat;

  /// No description provided for @deleteChatTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this chat?'**
  String get deleteChatTitle;

  /// No description provided for @deleteChatBody.
  ///
  /// In en, this message translates to:
  /// **'Its messages are deleted for everyone who can see it. What {bot} made here stays in the Library, usage records stay, and anything it remembered from it stays in its memory.'**
  String deleteChatBody(String bot);

  /// No description provided for @deleteChatAlsoCreations.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Also delete the 1 thing made here} other{Also delete the {count} things made here}}'**
  String deleteChatAlsoCreations(int count);

  /// No description provided for @deleteChatAlsoCreationsHelp.
  ///
  /// In en, this message translates to:
  /// **'Off: they stay in the Library.'**
  String get deleteChatAlsoCreationsHelp;

  /// No description provided for @chatDeleted.
  ///
  /// In en, this message translates to:
  /// **'Chat deleted'**
  String get chatDeleted;

  /// No description provided for @deleteAllChats.
  ///
  /// In en, this message translates to:
  /// **'Delete All Chats'**
  String get deleteAllChats;

  /// No description provided for @deleteAllChatsRow.
  ///
  /// In en, this message translates to:
  /// **'Start over with a clean history. Memories stay.'**
  String get deleteAllChatsRow;

  /// No description provided for @deleteAllChatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete all chats with {bot}?'**
  String deleteAllChatsTitle(String bot);

  /// No description provided for @deleteAllChatsBody.
  ///
  /// In en, this message translates to:
  /// **'Every chat with {bot} that you can delete goes, with its messages, photos and files. Group chats stay. Usage records stay, and what {bot} remembered stays in its memory.'**
  String deleteAllChatsBody(String bot);

  /// No description provided for @chatsDeleted.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{No chats to delete.} =1{1 chat deleted.} other{{n} chats deleted.}}'**
  String chatsDeleted(int n);

  /// No description provided for @chatsKeptBusy.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 chat was kept because the bot is still working in it.} other{{n} chats were kept because the bot is still working in them.}}'**
  String chatsKeptBusy(int n);

  /// No description provided for @groupEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, other{{n} bots are in this chat. Each keeps its own memory and settings.}}'**
  String groupEmptySubtitle(int n);

  /// No description provided for @groupTipMention.
  ///
  /// In en, this message translates to:
  /// **'Type @ and a name to ask one bot directly.'**
  String get groupTipMention;

  /// No description provided for @groupTipEveryone.
  ///
  /// In en, this message translates to:
  /// **'@everyone asks {lead} to plan the work and hand a part to each bot.'**
  String groupTipEveryone(String lead);

  /// No description provided for @groupTipNoMention.
  ///
  /// In en, this message translates to:
  /// **'Without a mention, the bot that spoke last answers ({lead} at first).'**
  String groupTipNoMention(String lead);

  /// No description provided for @messageNotSent.
  ///
  /// In en, this message translates to:
  /// **'Your files didn\'t upload, so the message wasn\'t sent. It\'s back in the box.'**
  String get messageNotSent;

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
  /// **'Edit Memory'**
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

  /// No description provided for @casamaCloudKeyHint.
  ///
  /// In en, this message translates to:
  /// **'Paid from your credits'**
  String get casamaCloudKeyHint;

  /// No description provided for @casamaCloudIncluded.
  ///
  /// In en, this message translates to:
  /// **'Included'**
  String get casamaCloudIncluded;

  /// No description provided for @casamaCloudModelLocked.
  ///
  /// In en, this message translates to:
  /// **'Casama chooses this model.'**
  String get casamaCloudModelLocked;

  /// No description provided for @serverVoiceSetUp.
  ///
  /// In en, this message translates to:
  /// **'This server provides voice, so there\'s no key to add. A workspace\'s own key is used first.'**
  String get serverVoiceSetUp;

  /// No description provided for @modelKeysFor.
  ///
  /// In en, this message translates to:
  /// **'Keys belong to one workspace. These are for {workspace}.'**
  String modelKeysFor(String workspace);

  /// No description provided for @yourKeys.
  ///
  /// In en, this message translates to:
  /// **'Your Keys'**
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
  /// **'Delete Skill'**
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

  /// No description provided for @computersEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No computers yet'**
  String get computersEmptyTitle;

  /// No description provided for @thisDevice.
  ///
  /// In en, this message translates to:
  /// **'This device'**
  String get thisDevice;

  /// No description provided for @personalComputerConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get personalComputerConnected;

  /// No description provided for @personalComputerOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get personalComputerOffline;

  /// No description provided for @computerCpus.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 CPU} other{{n} CPUs}}'**
  String computerCpus(num n);

  /// No description provided for @computerMemory.
  ///
  /// In en, this message translates to:
  /// **'{size} RAM'**
  String computerMemory(Object size);

  /// No description provided for @computerDisk.
  ///
  /// In en, this message translates to:
  /// **'{size} disk'**
  String computerDisk(Object size);

  /// No description provided for @computerLastUsed.
  ///
  /// In en, this message translates to:
  /// **'Last used {when}'**
  String computerLastUsed(Object when);

  /// No description provided for @computerLastSeen.
  ///
  /// In en, this message translates to:
  /// **'Last seen {when}'**
  String computerLastSeen(Object when);

  /// No description provided for @computerSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get computerSaved;

  /// No description provided for @computerSavedHelp.
  ///
  /// In en, this message translates to:
  /// **'Its files are kept while it\'s stopped'**
  String get computerSavedHelp;

  /// No description provided for @computerCanUse.
  ///
  /// In en, this message translates to:
  /// **'Bots can use: {list}'**
  String computerCanUse(Object list);

  /// No description provided for @computerCanUseNothing.
  ///
  /// In en, this message translates to:
  /// **'Bots can\'t use it yet'**
  String get computerCanUseNothing;

  /// No description provided for @computerCapShell.
  ///
  /// In en, this message translates to:
  /// **'Terminal'**
  String get computerCapShell;

  /// No description provided for @computerCapFiles.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get computerCapFiles;

  /// No description provided for @computerCapBrowser.
  ///
  /// In en, this message translates to:
  /// **'Browser'**
  String get computerCapBrowser;

  /// No description provided for @computerCapDesktop.
  ///
  /// In en, this message translates to:
  /// **'Screen'**
  String get computerCapDesktop;

  /// No description provided for @computerCapMcp.
  ///
  /// In en, this message translates to:
  /// **'Local tools'**
  String get computerCapMcp;

  /// No description provided for @computerCapMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get computerCapMessages;

  /// No description provided for @personalComputerOfflineNamed.
  ///
  /// In en, this message translates to:
  /// **'{name} is offline. Open Casama on it and turn on \"Use this computer for bots\". Your own computer never uses your plan\'s computer hours.'**
  String personalComputerOfflineNamed(String name);

  /// Chat notice: the bot reached for the person's own computer, whose Casama app isn't running (D-447).
  ///
  /// In en, this message translates to:
  /// **'Your computer is offline'**
  String get yourComputerOffline;

  /// No description provided for @howToFix.
  ///
  /// In en, this message translates to:
  /// **'How to fix'**
  String get howToFix;

  /// No description provided for @computerHoursUsedTitle.
  ///
  /// In en, this message translates to:
  /// **'Computer hours used up'**
  String get computerHoursUsedTitle;

  /// No description provided for @personalScreenNote.
  ///
  /// In en, this message translates to:
  /// **'This is your own computer, so you see a new screenshot every few seconds instead of a live view.'**
  String get personalScreenNote;

  /// No description provided for @renameComputer.
  ///
  /// In en, this message translates to:
  /// **'Rename Computer'**
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
  /// **'Your Data'**
  String get yourData;

  /// No description provided for @shareAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Share Usage Data'**
  String get shareAnalytics;

  /// No description provided for @shareAnalyticsHelp.
  ///
  /// In en, this message translates to:
  /// **'Usage and crash reports. Never your messages or files.'**
  String get shareAnalyticsHelp;

  /// No description provided for @workspaceAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Usage Data for This Workspace'**
  String get workspaceAnalytics;

  /// No description provided for @workspaceAnalyticsHelp.
  ///
  /// In en, this message translates to:
  /// **'Usage data for this workspace. Crash reports stay on.'**
  String get workspaceAnalyticsHelp;

  /// No description provided for @dangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
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

  /// No description provided for @sendInvite.
  ///
  /// In en, this message translates to:
  /// **'Send Invite'**
  String get sendInvite;

  /// No description provided for @thinking0.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get thinking0;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
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

  /// No description provided for @quickAskIntroBot.
  ///
  /// In en, this message translates to:
  /// **'Send a quick request. It starts a new chat with {name}.'**
  String quickAskIntroBot(String name);

  /// No description provided for @quickAskHintBot.
  ///
  /// In en, this message translates to:
  /// **'What should {bot} do?'**
  String quickAskHintBot(String bot);

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
  /// **'Use your own Casama server. Enter the address you or your admin set up.'**
  String get serverHelp;

  /// No description provided for @ssoHelp.
  ///
  /// In en, this message translates to:
  /// **'Enter your work email and we\'ll send you to your company\'s sign-in page.'**
  String get ssoHelp;

  /// No description provided for @colorScheme.
  ///
  /// In en, this message translates to:
  /// **'Color Scheme'**
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

  /// No description provided for @noAppsMatch.
  ///
  /// In en, this message translates to:
  /// **'No apps match. You can add your own server under Advanced.'**
  String get noAppsMatch;

  /// No description provided for @appsFound.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 app} other{{count} apps}}'**
  String appsFound(int count);

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
  /// **'Pattern Strength'**
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
  /// **'Reset to Default'**
  String get resetBackground;

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

  /// No description provided for @botUiConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get botUiConnected;

  /// No description provided for @draftNewEmail.
  ///
  /// In en, this message translates to:
  /// **'New email'**
  String get draftNewEmail;

  /// No description provided for @draftNewMessage.
  ///
  /// In en, this message translates to:
  /// **'New message'**
  String get draftNewMessage;

  /// No description provided for @draftNewPost.
  ///
  /// In en, this message translates to:
  /// **'New post'**
  String get draftNewPost;

  /// No description provided for @draftReadyToSend.
  ///
  /// In en, this message translates to:
  /// **'Ready to send'**
  String get draftReadyToSend;

  /// No description provided for @draftReadyToPost.
  ///
  /// In en, this message translates to:
  /// **'Ready to post'**
  String get draftReadyToPost;

  /// No description provided for @draftEdited.
  ///
  /// In en, this message translates to:
  /// **'Edited'**
  String get draftEdited;

  /// No description provided for @draftSendEmail.
  ///
  /// In en, this message translates to:
  /// **'Send email'**
  String get draftSendEmail;

  /// No description provided for @draftSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get draftSend;

  /// No description provided for @draftPost.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get draftPost;

  /// No description provided for @draftDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get draftDiscard;

  /// No description provided for @draftEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get draftEdit;

  /// No description provided for @draftDoneEditing.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get draftDoneEditing;

  /// No description provided for @draftFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get draftFrom;

  /// No description provided for @draftTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get draftTo;

  /// No description provided for @draftCc.
  ///
  /// In en, this message translates to:
  /// **'Cc'**
  String get draftCc;

  /// No description provided for @draftBcc.
  ///
  /// In en, this message translates to:
  /// **'Bcc'**
  String get draftBcc;

  /// No description provided for @draftSubject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get draftSubject;

  /// No description provided for @botCardNewEvent.
  ///
  /// In en, this message translates to:
  /// **'New event'**
  String get botCardNewEvent;

  /// No description provided for @botCardEvent.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get botCardEvent;

  /// No description provided for @botCardReadyToAdd.
  ///
  /// In en, this message translates to:
  /// **'Ready to add'**
  String get botCardReadyToAdd;

  /// No description provided for @botCardAddToCalendar.
  ///
  /// In en, this message translates to:
  /// **'Add to calendar'**
  String get botCardAddToCalendar;

  /// No description provided for @botCardChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get botCardChange;

  /// No description provided for @botCardSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get botCardSkip;

  /// No description provided for @botCardAllDay.
  ///
  /// In en, this message translates to:
  /// **'All day'**
  String get botCardAllDay;

  /// No description provided for @botCardMore.
  ///
  /// In en, this message translates to:
  /// **'+{count} more'**
  String botCardMore(int count);

  /// No description provided for @botCardAgenda.
  ///
  /// In en, this message translates to:
  /// **'Agenda'**
  String get botCardAgenda;

  /// No description provided for @botCardMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get botCardMessages;

  /// No description provided for @botCardUnread.
  ///
  /// In en, this message translates to:
  /// **'{count} unread'**
  String botCardUnread(int count);

  /// No description provided for @botCardReply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get botCardReply;

  /// No description provided for @botCardReplyTo.
  ///
  /// In en, this message translates to:
  /// **'Reply to {name}'**
  String botCardReplyTo(String name);

  /// No description provided for @botCardTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get botCardTasks;

  /// No description provided for @botCardDoneOf.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} done'**
  String botCardDoneOf(int done, int total);

  /// No description provided for @botCardSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get botCardSaveChanges;

  /// No description provided for @botCardChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get botCardChoose;

  /// No description provided for @botCardChose.
  ///
  /// In en, this message translates to:
  /// **'{title}'**
  String botCardChose(String title);

  /// No description provided for @botCardWhichPerson.
  ///
  /// In en, this message translates to:
  /// **'Who do you mean?'**
  String get botCardWhichPerson;

  /// No description provided for @botCardNoneOfThese.
  ///
  /// In en, this message translates to:
  /// **'None of these'**
  String get botCardNoneOfThese;

  /// No description provided for @botCardReminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get botCardReminder;

  /// No description provided for @botCardRoutine.
  ///
  /// In en, this message translates to:
  /// **'Routine'**
  String get botCardRoutine;

  /// No description provided for @botCardWatcher.
  ///
  /// In en, this message translates to:
  /// **'Watching'**
  String get botCardWatcher;

  /// No description provided for @botCardScheduled.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get botCardScheduled;

  /// No description provided for @botCardNext.
  ///
  /// In en, this message translates to:
  /// **'Next: {when}'**
  String botCardNext(String when);

  /// No description provided for @botCardCancelIt.
  ///
  /// In en, this message translates to:
  /// **'Cancel it'**
  String get botCardCancelIt;

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
  /// **'Open Run Timeline'**
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

  /// No description provided for @myThemes.
  ///
  /// In en, this message translates to:
  /// **'Your themes'**
  String get myThemes;

  /// No description provided for @saveTheme.
  ///
  /// In en, this message translates to:
  /// **'Save Current Look'**
  String get saveTheme;

  /// No description provided for @themeName.
  ///
  /// In en, this message translates to:
  /// **'Theme name'**
  String get themeName;

  /// No description provided for @importTheme.
  ///
  /// In en, this message translates to:
  /// **'Import a Theme'**
  String get importTheme;

  /// No description provided for @themeCode.
  ///
  /// In en, this message translates to:
  /// **'Theme code'**
  String get themeCode;

  /// No description provided for @themeCodeHelp.
  ///
  /// In en, this message translates to:
  /// **'Paste a code someone shared with you. It starts with casama-theme:'**
  String get themeCodeHelp;

  /// No description provided for @invalidThemeCode.
  ///
  /// In en, this message translates to:
  /// **'That isn\'t a Casama theme code.'**
  String get invalidThemeCode;

  /// No description provided for @themeImported.
  ///
  /// In en, this message translates to:
  /// **'Added {name} to your themes'**
  String themeImported(String name);

  /// No description provided for @themeCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Theme code copied. Anyone can paste it into Appearance → Import a theme.'**
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
  /// **'Use the Defaults'**
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
  /// **'Your Photo'**
  String get yourPhoto;

  /// No description provided for @browsePhotos.
  ///
  /// In en, this message translates to:
  /// **'Browse photos'**
  String get browsePhotos;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove Photo'**
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
  /// **'Tokens In'**
  String get tokensIn;

  /// No description provided for @tokensOut.
  ///
  /// In en, this message translates to:
  /// **'Tokens Out'**
  String get tokensOut;

  /// No description provided for @runsLabel.
  ///
  /// In en, this message translates to:
  /// **'Runs'**
  String get runsLabel;

  /// No description provided for @spendByDay.
  ///
  /// In en, this message translates to:
  /// **'Spend by Day'**
  String get spendByDay;

  /// No description provided for @byBot.
  ///
  /// In en, this message translates to:
  /// **'By Bot'**
  String get byBot;

  /// No description provided for @byModel.
  ///
  /// In en, this message translates to:
  /// **'By Model'**
  String get byModel;

  /// No description provided for @everythingMetered.
  ///
  /// In en, this message translates to:
  /// **'Everything Metered'**
  String get everythingMetered;

  /// No description provided for @bySource.
  ///
  /// In en, this message translates to:
  /// **'By Source'**
  String get bySource;

  /// No description provided for @byPerson.
  ///
  /// In en, this message translates to:
  /// **'By Person'**
  String get byPerson;

  /// No description provided for @usageAllBots.
  ///
  /// In en, this message translates to:
  /// **'All bots'**
  String get usageAllBots;

  /// No description provided for @usageAllModels.
  ///
  /// In en, this message translates to:
  /// **'All models'**
  String get usageAllModels;

  /// No description provided for @usageAllSources.
  ///
  /// In en, this message translates to:
  /// **'All sources'**
  String get usageAllSources;

  /// No description provided for @usageEveryone.
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get usageEveryone;

  /// No description provided for @usageJustMe.
  ///
  /// In en, this message translates to:
  /// **'Just me'**
  String get usageJustMe;

  /// No description provided for @usageClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get usageClearFilters;

  /// No description provided for @usageFilterBot.
  ///
  /// In en, this message translates to:
  /// **'Show usage for'**
  String get usageFilterBot;

  /// No description provided for @usageFilterModel.
  ///
  /// In en, this message translates to:
  /// **'Show usage of'**
  String get usageFilterModel;

  /// No description provided for @usageFilterSource.
  ///
  /// In en, this message translates to:
  /// **'Show usage from'**
  String get usageFilterSource;

  /// No description provided for @usageFilterPerson.
  ///
  /// In en, this message translates to:
  /// **'Show usage started by'**
  String get usageFilterPerson;

  /// No description provided for @usageSourceChat.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get usageSourceChat;

  /// No description provided for @usageSourceChatApp.
  ///
  /// In en, this message translates to:
  /// **'Chat apps'**
  String get usageSourceChatApp;

  /// No description provided for @usageSourceRoutine.
  ///
  /// In en, this message translates to:
  /// **'Routines'**
  String get usageSourceRoutine;

  /// No description provided for @usageSourceApi.
  ///
  /// In en, this message translates to:
  /// **'API and other agents'**
  String get usageSourceApi;

  /// No description provided for @usageSourceOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get usageSourceOther;

  /// No description provided for @usageNoPerson.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get usageNoPerson;

  /// No description provided for @usageUnnamedPerson.
  ///
  /// In en, this message translates to:
  /// **'Unnamed member'**
  String get usageUnnamedPerson;

  /// No description provided for @usageRunsCount.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 run} other{{n} runs}}'**
  String usageRunsCount(int n);

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
  /// **'Ask a Bot About This'**
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
  /// **'Here is my Casama usage for {period}. Help me understand where the money goes and how I could spend less. You can also check live numbers with your usage tool.\n\n{summary}'**
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

  /// No description provided for @kindModels.
  ///
  /// In en, this message translates to:
  /// **'AI models'**
  String get kindModels;

  /// No description provided for @creditsThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month\'s credits'**
  String get creditsThisMonth;

  /// No description provided for @creditsUsedPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}% used'**
  String creditsUsedPercent(int percent);

  /// No description provided for @creditsRunsLeft.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{Less than one more run at your usual cost} =1{About 1 more run at your usual cost} other{About {n} more runs at your usual cost}}'**
  String creditsRunsLeft(int n);

  /// No description provided for @creditsOut.
  ///
  /// In en, this message translates to:
  /// **'You\'re out of credits. Add more to keep your bots running.'**
  String get creditsOut;

  /// No description provided for @creditsExplainer.
  ///
  /// In en, this message translates to:
  /// **'1 credit = \$1. Your plan adds {amount} every month; unused ones carry over for one more month.'**
  String creditsExplainer(String amount);

  /// No description provided for @creditsExplainerShort.
  ///
  /// In en, this message translates to:
  /// **'1 credit = \$1. Packs from the App Store or Google Play never expire; web packs last 12 months.'**
  String get creditsExplainerShort;

  /// No description provided for @creditsDailyLabel.
  ///
  /// In en, this message translates to:
  /// **'Today\'s limit'**
  String get creditsDailyLabel;

  /// No description provided for @creditsDailyOf.
  ///
  /// In en, this message translates to:
  /// **'{used} of {cap}'**
  String creditsDailyOf(String used, String cap);

  /// No description provided for @creditsDailyExplainer.
  ///
  /// In en, this message translates to:
  /// **'What your plan can spend each day on Casama\'s models, voice and apps, whatever credits are left.'**
  String get creditsDailyExplainer;

  /// No description provided for @creditsDailyReached.
  ///
  /// In en, this message translates to:
  /// **'Today\'s limit is reached, so your bots are paused. Upgrade for a higher daily limit.'**
  String get creditsDailyReached;

  /// No description provided for @creditsDailyResetsHours.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Resets in about 1 hour.} other{Resets in about {n} hours.}}'**
  String creditsDailyResetsHours(int n);

  /// No description provided for @creditsDailyResetsSoon.
  ///
  /// In en, this message translates to:
  /// **'Resets in less than an hour.'**
  String get creditsDailyResetsSoon;

  /// No description provided for @creditsHoursLabel.
  ///
  /// In en, this message translates to:
  /// **'Computer hours'**
  String get creditsHoursLabel;

  /// No description provided for @creditsHoursOf.
  ///
  /// In en, this message translates to:
  /// **'{used} of {limit} h'**
  String creditsHoursOf(String used, String limit);

  /// No description provided for @creditsHoursExplainer.
  ///
  /// In en, this message translates to:
  /// **'Time your bots\' computers run this month. When they run out, chat keeps working; only the computer stops. Resets on {date}.'**
  String creditsHoursExplainer(String date);

  /// No description provided for @creditsHoursReached.
  ///
  /// In en, this message translates to:
  /// **'This month\'s computer hours are used, so your computer can\'t start. Chat still works. Resets on {date}. Upgrade for more hours.'**
  String creditsHoursReached(String date);

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

  /// No description provided for @computerMissingTitle.
  ///
  /// In en, this message translates to:
  /// **'Computer not found'**
  String get computerMissingTitle;

  /// No description provided for @computerMissingHelp.
  ///
  /// In en, this message translates to:
  /// **'It may have been removed, or the list is out of date. Refresh to check again.'**
  String get computerMissingHelp;

  /// No description provided for @computerMissingBotHelp.
  ///
  /// In en, this message translates to:
  /// **'This bot\'s computer may have been removed, or the list is out of date. Refresh, or choose another computer for this bot.'**
  String get computerMissingBotHelp;

  /// No description provided for @computerChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose a Computer'**
  String get computerChoose;

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

  /// No description provided for @browseAllPersonas.
  ///
  /// In en, this message translates to:
  /// **'Browse all'**
  String get browseAllPersonas;

  /// No description provided for @botIdentity.
  ///
  /// In en, this message translates to:
  /// **'Name and icon'**
  String get botIdentity;

  /// No description provided for @serviceKeys.
  ///
  /// In en, this message translates to:
  /// **'Service keys'**
  String get serviceKeys;

  /// No description provided for @noServiceKeys.
  ///
  /// In en, this message translates to:
  /// **'No service keys yet.'**
  String get noServiceKeys;

  /// No description provided for @serviceKeysHelp.
  ///
  /// In en, this message translates to:
  /// **'Your own search, maps or data keys'**
  String get serviceKeysHelp;

  /// No description provided for @serviceKeysIntro.
  ///
  /// In en, this message translates to:
  /// **'Casama runs the models, voice and images for you. Add a key here only to use your own search, maps or data service. Keys are stored encrypted and never shown again.'**
  String get serviceKeysIntro;

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
  /// **'Load a Persona'**
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
  /// **'Open the Sign-in Page Again'**
  String get reopenSignIn;

  /// No description provided for @appConnected.
  ///
  /// In en, this message translates to:
  /// **'{app} is connected'**
  String appConnected(String app);

  /// No description provided for @appAlreadyConnected.
  ///
  /// In en, this message translates to:
  /// **'{app} is already connected in this workspace. Use that connection, or add another account.'**
  String appAlreadyConnected(String app);

  /// Button: use the app connection the workspace already has instead of signing in again.
  ///
  /// In en, this message translates to:
  /// **'Use It'**
  String get useConnection;

  /// Button: connect a second account of an app the workspace has already connected.
  ///
  /// In en, this message translates to:
  /// **'Add Another Account'**
  String get addAnotherAccount;

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
  /// **'One-click sign-in for {app} needs a one-time setup by whoever runs this Casama server.'**
  String adminSetupNeeded(String app);

  /// No description provided for @connectThroughHub.
  ///
  /// In en, this message translates to:
  /// **'Or connect {app} through one of these. Sign in once, then ask your bot to use {app}.'**
  String connectThroughHub(String app);

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

  /// No description provided for @composioHelp.
  ///
  /// In en, this message translates to:
  /// **'Hundreds of apps, with sign-in handled for you.'**
  String get composioHelp;

  /// No description provided for @pipedreamHelp.
  ///
  /// In en, this message translates to:
  /// **'Thousands of apps through Pipedream Connect.'**
  String get pipedreamHelp;

  /// No description provided for @customServer.
  ///
  /// In en, this message translates to:
  /// **'Custom Server'**
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

  /// No description provided for @toolsHelp.
  ///
  /// In en, this message translates to:
  /// **'Read-only tools run on their own. Tools that make changes ask first when a bot has read something untrusted, and ones marked “Always asks” wait for you every time.'**
  String get toolsHelp;

  /// No description provided for @botsWithAccess.
  ///
  /// In en, this message translates to:
  /// **'Bots with Access'**
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
  /// **'Test Connection'**
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
  /// **'Browse Apps'**
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

  /// No description provided for @connectedThroughHub.
  ///
  /// In en, this message translates to:
  /// **'Through {provider}'**
  String connectedThroughHub(String provider);

  /// No description provided for @providerAppsTitle.
  ///
  /// In en, this message translates to:
  /// **'Apps Through {provider}'**
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
  /// **'Wake Up and Watch Live'**
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
  /// **'To connect your ChatGPT plan, open the desktop app, or run \"casama credential chatgpt\" in the CLI.'**
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
  /// **'Manage Usage'**
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

  /// No description provided for @signInWithPasskey.
  ///
  /// In en, this message translates to:
  /// **'Sign In with a Passkey'**
  String get signInWithPasskey;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @accountRow.
  ///
  /// In en, this message translates to:
  /// **'Email, password and signing out everywhere'**
  String get accountRow;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @newPasswordAgain.
  ///
  /// In en, this message translates to:
  /// **'New password again'**
  String get newPasswordAgain;

  /// No description provided for @passwordsDontMatch.
  ///
  /// In en, this message translates to:
  /// **'The passwords don\'t match'**
  String get passwordsDontMatch;

  /// No description provided for @newPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a new password'**
  String get newPasswordTitle;

  /// No description provided for @newPasswordBody.
  ///
  /// In en, this message translates to:
  /// **'You\'re signed in. Pick a new password for signing in with your email.'**
  String get newPasswordBody;

  /// No description provided for @savePassword.
  ///
  /// In en, this message translates to:
  /// **'Save password'**
  String get savePassword;

  /// No description provided for @passwordSaved.
  ///
  /// In en, this message translates to:
  /// **'Password saved.'**
  String get passwordSaved;

  /// No description provided for @passwordTitle.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordTitle;

  /// No description provided for @passwordRow.
  ///
  /// In en, this message translates to:
  /// **'Set or change the password for signing in with your email'**
  String get passwordRow;

  /// No description provided for @passwordHelp.
  ///
  /// In en, this message translates to:
  /// **'Use at least 6 characters. You can still sign in with Google, Apple, a passkey or an email link.'**
  String get passwordHelp;

  /// No description provided for @passwordCodeSent.
  ///
  /// In en, this message translates to:
  /// **'To keep your account safe, enter the code we just emailed to {email}.'**
  String passwordCodeSent(String email);

  /// No description provided for @changeEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Email'**
  String get changeEmailTitle;

  /// No description provided for @changeEmailHelp.
  ///
  /// In en, this message translates to:
  /// **'We\'ll email a confirmation link to your current address and to the new one. The change happens once both are confirmed.'**
  String get changeEmailHelp;

  /// No description provided for @newEmail.
  ///
  /// In en, this message translates to:
  /// **'New email'**
  String get newEmail;

  /// No description provided for @changeEmailSend.
  ///
  /// In en, this message translates to:
  /// **'Send Confirmation'**
  String get changeEmailSend;

  /// No description provided for @changeEmailRow.
  ///
  /// In en, this message translates to:
  /// **'Change the email you sign in with'**
  String get changeEmailRow;

  /// No description provided for @changeEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Check both inboxes. {email} becomes your email once both links are confirmed.'**
  String changeEmailSent(String email);

  /// No description provided for @changeEmailPending.
  ///
  /// In en, this message translates to:
  /// **'Waiting for confirmation: {email}'**
  String changeEmailPending(String email);

  /// No description provided for @signOutEverywhere.
  ///
  /// In en, this message translates to:
  /// **'Sign Out Everywhere'**
  String get signOutEverywhere;

  /// No description provided for @signOutEverywhereHelp.
  ///
  /// In en, this message translates to:
  /// **'Every phone, computer and browser, including this one'**
  String get signOutEverywhereHelp;

  /// No description provided for @signOutEverywhereConfirm.
  ///
  /// In en, this message translates to:
  /// **'Sign out on every device, including this one? Use this if you lost a device or think someone else is signed in.'**
  String get signOutEverywhereConfirm;

  /// No description provided for @passkeySuggestTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in faster next time?'**
  String get passkeySuggestTitle;

  /// No description provided for @passkeySuggestBody.
  ///
  /// In en, this message translates to:
  /// **'Add a passkey and sign in with Face ID, a fingerprint or your screen lock. No password or email needed.'**
  String get passkeySuggestBody;

  /// No description provided for @passkeys.
  ///
  /// In en, this message translates to:
  /// **'Passkeys'**
  String get passkeys;

  /// No description provided for @passkeysRow.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Face ID, a fingerprint or your screen lock'**
  String get passkeysRow;

  /// No description provided for @passkeysHelp.
  ///
  /// In en, this message translates to:
  /// **'A passkey signs you in with Face ID, a fingerprint or your screen lock, with no password or email. Each phone, computer or password manager keeps its own.'**
  String get passkeysHelp;

  /// No description provided for @passkeyAdd.
  ///
  /// In en, this message translates to:
  /// **'Add a Passkey'**
  String get passkeyAdd;

  /// No description provided for @passkeyAddAnother.
  ///
  /// In en, this message translates to:
  /// **'Add Another Passkey'**
  String get passkeyAddAnother;

  /// No description provided for @passkeyAdded.
  ///
  /// In en, this message translates to:
  /// **'Passkey added. Next time, sign in with it.'**
  String get passkeyAdded;

  /// No description provided for @passkeyRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get passkeyRename;

  /// No description provided for @passkeyRenameTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename Passkey'**
  String get passkeyRenameTitle;

  /// No description provided for @passkeyNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get passkeyNameLabel;

  /// No description provided for @passkeyRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get passkeyRemove;

  /// No description provided for @passkeyRemoveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{name}\"? You won\'t be able to sign in with it any more.'**
  String passkeyRemoveConfirm(String name);

  /// No description provided for @passkeyAddedOn.
  ///
  /// In en, this message translates to:
  /// **'Added {date}'**
  String passkeyAddedOn(String date);

  /// No description provided for @passkeyLastUsed.
  ///
  /// In en, this message translates to:
  /// **'Last used {when}'**
  String passkeyLastUsed(String when);

  /// No description provided for @twoStepSetUp.
  ///
  /// In en, this message translates to:
  /// **'Set Up an Authenticator App'**
  String get twoStepSetUp;

  /// No description provided for @twoStepAddAnother.
  ///
  /// In en, this message translates to:
  /// **'Add Another Authenticator'**
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
  /// **'Authenticator Apps'**
  String get twoStepAuthenticators;

  /// No description provided for @twoStepRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get twoStepRename;

  /// No description provided for @twoStepRenameTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename Authenticator'**
  String get twoStepRenameTitle;

  /// No description provided for @twoStepNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get twoStepNameLabel;

  /// No description provided for @twoStepNameHint.
  ///
  /// In en, this message translates to:
  /// **'For example: Work phone'**
  String get twoStepNameHint;

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
  /// **'Owners and admins must use it. Turn yours on first.'**
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

  /// No description provided for @adminCapacityTitle.
  ///
  /// In en, this message translates to:
  /// **'Server capacity'**
  String get adminCapacityTitle;

  /// No description provided for @adminCapacityComputers.
  ///
  /// In en, this message translates to:
  /// **'Computers: {used} of {budget}'**
  String adminCapacityComputers(String used, String budget);

  /// No description provided for @adminCapacityComputersNoBudget.
  ///
  /// In en, this message translates to:
  /// **'Computers: {used}'**
  String adminCapacityComputersNoBudget(String used);

  /// No description provided for @adminCapacityFree.
  ///
  /// In en, this message translates to:
  /// **'Free memory {free} of {total}'**
  String adminCapacityFree(String free, String total);

  /// No description provided for @adminCapacityDisk.
  ///
  /// In en, this message translates to:
  /// **'Disk {percent}% full'**
  String adminCapacityDisk(int percent);

  /// No description provided for @adminCapacityLoad.
  ///
  /// In en, this message translates to:
  /// **'Load {load} on {cpus} CPUs'**
  String adminCapacityLoad(String load, int cpus);

  /// No description provided for @adminCapacityPeakChart.
  ///
  /// In en, this message translates to:
  /// **'Computers\' daily peak, last 30 days'**
  String get adminCapacityPeakChart;

  /// No description provided for @adminCapacityFullIn.
  ///
  /// In en, this message translates to:
  /// **'{weeks, plural, =1{Full in about a week at this trend} other{Full in about {weeks} weeks at this trend}}'**
  String adminCapacityFullIn(int weeks);

  /// No description provided for @adminCapacityFullNow.
  ///
  /// In en, this message translates to:
  /// **'Full now: order the bigger server'**
  String get adminCapacityFullNow;

  /// No description provided for @adminCapacityNoGrowth.
  ///
  /// In en, this message translates to:
  /// **'Not filling up at the current trend'**
  String get adminCapacityNoGrowth;

  /// No description provided for @adminCapacityNoBudget.
  ///
  /// In en, this message translates to:
  /// **'Set COMPUTER_HOST_MEMORY_GB on the server to measure computers against its room.'**
  String get adminCapacityNoBudget;

  /// No description provided for @adminCapacityNoData.
  ///
  /// In en, this message translates to:
  /// **'The first sample arrives within 5 minutes of the server starting.'**
  String get adminCapacityNoData;

  /// No description provided for @adminCapacityRefusals.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No computer starts refused in 30 days} =1{1 computer start refused in 30 days} other{{count} computer starts refused in 30 days}}'**
  String adminCapacityRefusals(int count);

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
  /// **'Local Tools (MCP)'**
  String get localMcpServers;

  /// No description provided for @localMcpHelp.
  ///
  /// In en, this message translates to:
  /// **'MCP servers on this computer or your network that your bots can use, such as T3 Code, Claude Code, Codex or design apps. Their tokens and sign-ins stay on this computer.'**
  String get localMcpHelp;

  /// No description provided for @localMcpAdd.
  ///
  /// In en, this message translates to:
  /// **'Add a Local MCP Server'**
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

  /// No description provided for @localMcpStdio.
  ///
  /// In en, this message translates to:
  /// **'A Command'**
  String get localMcpStdio;

  /// No description provided for @localMcpLoopback.
  ///
  /// In en, this message translates to:
  /// **'An Address'**
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
  /// **'Working Folder (Optional)'**
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
  /// **'Use an http:// address on this computer or your own network, like http://127.0.0.1:3845/mcp, or an https:// address.'**
  String get localMcpBadUrl;

  /// No description provided for @localMcpBadFolder.
  ///
  /// In en, this message translates to:
  /// **'Pick a folder inside one of the shared folders.'**
  String get localMcpBadFolder;

  /// No description provided for @codingAgents.
  ///
  /// In en, this message translates to:
  /// **'Coding Agents'**
  String get codingAgents;

  /// No description provided for @codingAgentsHelp.
  ///
  /// In en, this message translates to:
  /// **'Bots can hand coding tasks to these agents on this computer. They use your own sign-ins and work in the folders you share.'**
  String get codingAgentsHelp;

  /// No description provided for @codingAgentsFound.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{No coding agents found} =1{Found 1 coding agent} other{Found {n} coding agents}}'**
  String codingAgentsFound(int n);

  /// No description provided for @localMcpNotSaved.
  ///
  /// In en, this message translates to:
  /// **'This server isn\'t saved to the workspace yet. Remove it and add it again.'**
  String get localMcpNotSaved;

  /// No description provided for @localMcpSignInKind.
  ///
  /// In en, this message translates to:
  /// **'Sign-In'**
  String get localMcpSignInKind;

  /// No description provided for @localMcpAuthNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get localMcpAuthNone;

  /// No description provided for @localMcpAuthToken.
  ///
  /// In en, this message translates to:
  /// **'Token'**
  String get localMcpAuthToken;

  /// No description provided for @localMcpAuthHeader.
  ///
  /// In en, this message translates to:
  /// **'Header'**
  String get localMcpAuthHeader;

  /// No description provided for @localMcpAuthOAuth.
  ///
  /// In en, this message translates to:
  /// **'Browser'**
  String get localMcpAuthOAuth;

  /// No description provided for @localMcpToken.
  ///
  /// In en, this message translates to:
  /// **'Token (kept on this computer)'**
  String get localMcpToken;

  /// No description provided for @localMcpHeaderName.
  ///
  /// In en, this message translates to:
  /// **'Header Name'**
  String get localMcpHeaderName;

  /// No description provided for @localMcpHeaderValue.
  ///
  /// In en, this message translates to:
  /// **'Header Value (kept on this computer)'**
  String get localMcpHeaderValue;

  /// No description provided for @localMcpOAuthHelp.
  ///
  /// In en, this message translates to:
  /// **'Casama opens your browser so you can sign in to this server. The sign-in stays on this computer.'**
  String get localMcpOAuthHelp;

  /// No description provided for @localMcpNetworkWarning.
  ///
  /// In en, this message translates to:
  /// **'This server isn\'t on this computer. Bots that can use this computer can reach it.'**
  String get localMcpNetworkWarning;

  /// No description provided for @localMcpSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get localMcpSignIn;

  /// No description provided for @localMcpNeedsSignIn.
  ///
  /// In en, this message translates to:
  /// **'Needs sign-in'**
  String get localMcpNeedsSignIn;

  /// No description provided for @localMcpEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit Local MCP Server'**
  String get localMcpEdit;

  /// No description provided for @localMcpImport.
  ///
  /// In en, this message translates to:
  /// **'Add From Other Apps'**
  String get localMcpImport;

  /// No description provided for @localMcpImportHelp.
  ///
  /// In en, this message translates to:
  /// **'MCP servers already set up in T3 Code, Claude Code, Claude Desktop, Cursor, VS Code, Codex or Windsurf on this computer.'**
  String get localMcpImportHelp;

  /// No description provided for @localMcpImportNone.
  ///
  /// In en, this message translates to:
  /// **'No MCP servers found in other apps on this computer.'**
  String get localMcpImportNone;

  /// No description provided for @localMcpImportAdded.
  ///
  /// In en, this message translates to:
  /// **'Already added'**
  String get localMcpImportAdded;

  /// No description provided for @localMcpImportRemote.
  ///
  /// In en, this message translates to:
  /// **'On the internet, so usually added under Connections. Add it here only if just this computer can reach it.'**
  String get localMcpImportRemote;

  /// No description provided for @mcpQuestionDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get mcpQuestionDecline;

  /// No description provided for @mcpQuestionSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get mcpQuestionSend;

  /// No description provided for @cardMcpQuestion.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get cardMcpQuestion;

  /// No description provided for @cardMcpSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign-in'**
  String get cardMcpSignIn;

  /// No description provided for @mcpSignInHereHelp.
  ///
  /// In en, this message translates to:
  /// **'Sign in so your bots can use it again.'**
  String get mcpSignInHereHelp;

  /// No description provided for @localMcpSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Signed in to {name}'**
  String localMcpSignedIn(String name);

  /// No description provided for @localMcpImportFrom.
  ///
  /// In en, this message translates to:
  /// **'From {source}'**
  String localMcpImportFrom(String source);

  /// No description provided for @localMcpImportAddCount.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{Add} =1{Add 1 Server} other{Add {n} Servers}}'**
  String localMcpImportAddCount(int n);

  /// No description provided for @localMcpMissingValue.
  ///
  /// In en, this message translates to:
  /// **'{name} (kept on this computer)'**
  String localMcpMissingValue(String name);

  /// No description provided for @mcpSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} needs you to sign in'**
  String mcpSignInTitle(String name);

  /// No description provided for @mcpSignInElsewhereHelp.
  ///
  /// In en, this message translates to:
  /// **'Open Casama on {device} and sign in there.'**
  String mcpSignInElsewhereHelp(String device);

  /// No description provided for @mcpQuestionTitle.
  ///
  /// In en, this message translates to:
  /// **'{connection} asks'**
  String mcpQuestionTitle(String connection);

  /// No description provided for @mcpQuestionAnswered.
  ///
  /// In en, this message translates to:
  /// **'Answered {connection}'**
  String mcpQuestionAnswered(String connection);

  /// No description provided for @mcpQuestionDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined {connection}\'s question'**
  String mcpQuestionDeclined(String connection);

  /// No description provided for @mcpQuestionClosed.
  ///
  /// In en, this message translates to:
  /// **'{connection}\'s question closed'**
  String mcpQuestionClosed(String connection);

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
  /// **'Turn On'**
  String get allowCommands;

  /// No description provided for @codingAgentAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get codingAgentAllow;

  /// No description provided for @codingAgentAllowed.
  ///
  /// In en, this message translates to:
  /// **'Allowed'**
  String get codingAgentAllowed;

  /// No description provided for @codingAgentsAllowHelp.
  ///
  /// In en, this message translates to:
  /// **'An agent with Allow next to it hasn\'t run on this computer yet. Allow it once and bots can hand it tasks.'**
  String get codingAgentsAllowHelp;

  /// No description provided for @ownAgentsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add Your Own'**
  String get ownAgentsAdd;

  /// No description provided for @ownAgentYours.
  ///
  /// In en, this message translates to:
  /// **'Yours'**
  String get ownAgentYours;

  /// No description provided for @ownAgentNotFound.
  ///
  /// In en, this message translates to:
  /// **'Not found on this computer'**
  String get ownAgentNotFound;

  /// No description provided for @ownAgentsHelp.
  ///
  /// In en, this message translates to:
  /// **'Your own agents run only on this computer, in chats that act for you. Nobody else in the workspace can see or change them.'**
  String get ownAgentsHelp;

  /// No description provided for @ownAgentFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Your Own Agent'**
  String get ownAgentFormTitle;

  /// No description provided for @ownAgentEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Your Agent'**
  String get ownAgentEditTitle;

  /// No description provided for @ownAgentName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get ownAgentName;

  /// No description provided for @ownAgentBin.
  ///
  /// In en, this message translates to:
  /// **'Command Name'**
  String get ownAgentBin;

  /// No description provided for @ownAgentCommand.
  ///
  /// In en, this message translates to:
  /// **'Command'**
  String get ownAgentCommand;

  /// No description provided for @ownAgentCommandHelp.
  ///
  /// In en, this message translates to:
  /// **'Put {task} where the task goes; Casama quotes it. Every command in it starts with the command name. You can also use {folder}, and {result_file} when the agent writes its answer to a file.'**
  String ownAgentCommandHelp(String task, String folder, String result_file);

  /// No description provided for @ownAgentResult.
  ///
  /// In en, this message translates to:
  /// **'Reading the Answer'**
  String get ownAgentResult;

  /// No description provided for @ownAgentResultTail.
  ///
  /// In en, this message translates to:
  /// **'The end of its output'**
  String get ownAgentResultTail;

  /// No description provided for @ownAgentResultJson.
  ///
  /// In en, this message translates to:
  /// **'A JSON line with a result field'**
  String get ownAgentResultJson;

  /// No description provided for @ownAgentResultStream.
  ///
  /// In en, this message translates to:
  /// **'A stream of JSON lines'**
  String get ownAgentResultStream;

  /// No description provided for @ownAgentResultField.
  ///
  /// In en, this message translates to:
  /// **'A JSON field'**
  String get ownAgentResultField;

  /// No description provided for @ownAgentResultFile.
  ///
  /// In en, this message translates to:
  /// **'Written to a file'**
  String get ownAgentResultFile;

  /// No description provided for @ownAgentResultFieldName.
  ///
  /// In en, this message translates to:
  /// **'Field Name'**
  String get ownAgentResultFieldName;

  /// No description provided for @ownAgentTimeLimit.
  ///
  /// In en, this message translates to:
  /// **'Time Limit (Minutes)'**
  String get ownAgentTimeLimit;

  /// No description provided for @ownAgentTest.
  ///
  /// In en, this message translates to:
  /// **'Test'**
  String get ownAgentTest;

  /// No description provided for @ownAgentTestHelp.
  ///
  /// In en, this message translates to:
  /// **'Test asks it to reply with just the word pong on this computer and shows what it printed.'**
  String get ownAgentTestHelp;

  /// No description provided for @ownAgentTestPassed.
  ///
  /// In en, this message translates to:
  /// **'It answered: {reply}'**
  String ownAgentTestPassed(String reply);

  /// No description provided for @ownAgentTestFailed.
  ///
  /// In en, this message translates to:
  /// **'It didn\'t answer as expected (exit {code}).'**
  String ownAgentTestFailed(int code);

  /// No description provided for @ownAgentTestTimedOut.
  ///
  /// In en, this message translates to:
  /// **'It didn\'t finish in time.'**
  String get ownAgentTestTimedOut;

  /// No description provided for @ownAgentBadCommand.
  ///
  /// In en, this message translates to:
  /// **'Fill in a name, a command name and a command with {task}.'**
  String ownAgentBadCommand(String task);

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

  /// No description provided for @newTicketSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A task for one of your bots, tracked on the board.'**
  String get newTicketSubtitle;

  /// No description provided for @allProjects.
  ///
  /// In en, this message translates to:
  /// **'All projects'**
  String get allProjects;

  /// No description provided for @manageProjects.
  ///
  /// In en, this message translates to:
  /// **'Manage projects'**
  String get manageProjects;

  /// No description provided for @filterByProject.
  ///
  /// In en, this message translates to:
  /// **'Filter by project'**
  String get filterByProject;

  /// No description provided for @moveTo.
  ///
  /// In en, this message translates to:
  /// **'Move to'**
  String get moveTo;

  /// No description provided for @noMatchingTickets.
  ///
  /// In en, this message translates to:
  /// **'No matching tickets'**
  String get noMatchingTickets;

  /// No description provided for @noMatchingTicketsHelp.
  ///
  /// In en, this message translates to:
  /// **'No tickets match these filters.'**
  String get noMatchingTicketsHelp;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get clearFilters;

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
  /// **'Needs Review'**
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
  /// **'Open the Bot\'s Thread'**
  String get openThread;

  /// No description provided for @deleteTicket.
  ///
  /// In en, this message translates to:
  /// **'Delete Ticket'**
  String get deleteTicket;

  /// No description provided for @ticketResult.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get ticketResult;

  /// No description provided for @noCommentsYet.
  ///
  /// In en, this message translates to:
  /// **'No comments yet. Leave a note for the bot or your team.'**
  String get noCommentsYet;

  /// No description provided for @noTickets.
  ///
  /// In en, this message translates to:
  /// **'Give your bots something to do'**
  String get noTickets;

  /// No description provided for @noTicketsHelp.
  ///
  /// In en, this message translates to:
  /// **'Hand off one piece of work, or a whole goal. You can watch it move from here.'**
  String get noTicketsHelp;

  /// No description provided for @tasksStartTicket.
  ///
  /// In en, this message translates to:
  /// **'Add a ticket'**
  String get tasksStartTicket;

  /// No description provided for @tasksStartTicketHelp.
  ///
  /// In en, this message translates to:
  /// **'One piece of work. Assign it to a bot and it starts.'**
  String get tasksStartTicketHelp;

  /// No description provided for @tasksStartProject.
  ///
  /// In en, this message translates to:
  /// **'Start a project'**
  String get tasksStartProject;

  /// No description provided for @tasksStartProjectHelp.
  ///
  /// In en, this message translates to:
  /// **'A bigger goal. A bot plans it as tickets and waits for your OK.'**
  String get tasksStartProjectHelp;

  /// No description provided for @tasksExamples.
  ///
  /// In en, this message translates to:
  /// **'Or start from one of these'**
  String get tasksExamples;

  /// No description provided for @tasksExampleResearch.
  ///
  /// In en, this message translates to:
  /// **'Research my top three competitors'**
  String get tasksExampleResearch;

  /// No description provided for @tasksExampleDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft a launch announcement'**
  String get tasksExampleDraft;

  /// No description provided for @tasksExampleTidy.
  ///
  /// In en, this message translates to:
  /// **'Tidy up my files'**
  String get tasksExampleTidy;

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
  /// **'New Workspace'**
  String get newWorkspace;

  /// No description provided for @newWorkspaceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A separate home for a team, with its own bots, chats and people.'**
  String get newWorkspaceSubtitle;

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
  /// **'Create a Link'**
  String get createInviteLink;

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
  /// **'{days, plural, =1{In 1 day} other{In {days} days}}'**
  String linkDays(int days);

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

  /// No description provided for @inviteRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get inviteRole;

  /// No description provided for @shareLinkLabel.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareLinkLabel;

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
  /// **'Archive Bot'**
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
  /// **'Bring Back'**
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
  /// **'Restore These Settings'**
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
  /// **'Changed by Casama'**
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

  /// No description provided for @secretWhat.
  ///
  /// In en, this message translates to:
  /// **'{service} key'**
  String secretWhat(String service);

  /// No description provided for @totpWhat.
  ///
  /// In en, this message translates to:
  /// **'{service} sign-in code'**
  String totpWhat(String service);

  /// No description provided for @takeoverHandedBackLine.
  ///
  /// In en, this message translates to:
  /// **'Handed back: {what}'**
  String takeoverHandedBackLine(String what);

  /// No description provided for @deviceAccessSkippedLine.
  ///
  /// In en, this message translates to:
  /// **'Not shared: your {what}'**
  String deviceAccessSkippedLine(String what);

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
  /// **'Key or Password'**
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

  /// No description provided for @searchJumpHint.
  ///
  /// In en, this message translates to:
  /// **'Search or jump to…'**
  String get searchJumpHint;

  /// No description provided for @searchRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get searchRecent;

  /// No description provided for @searchClearRecent.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get searchClearRecent;

  /// No description provided for @searchRemoveRecent.
  ///
  /// In en, this message translates to:
  /// **'Remove from recent searches'**
  String get searchRemoveRecent;

  /// No description provided for @searchJumpBackIn.
  ///
  /// In en, this message translates to:
  /// **'Jump back in'**
  String get searchJumpBackIn;

  /// No description provided for @searchNeedsYou.
  ///
  /// In en, this message translates to:
  /// **'Needs you'**
  String get searchNeedsYou;

  /// No description provided for @searchWaiting.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 thing is waiting for you} other{{n} things are waiting for you}}'**
  String searchWaiting(int n);

  /// No description provided for @searchGoTo.
  ///
  /// In en, this message translates to:
  /// **'Go to'**
  String get searchGoTo;

  /// No description provided for @searchTopHits.
  ///
  /// In en, this message translates to:
  /// **'Top hits'**
  String get searchTopHits;

  /// No description provided for @searchScopeAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get searchScopeAll;

  /// No description provided for @searchKeepTyping.
  ///
  /// In en, this message translates to:
  /// **'Keep typing to search messages, memories and files.'**
  String get searchKeepTyping;

  /// No description provided for @searchAskBot.
  ///
  /// In en, this message translates to:
  /// **'Ask {bot} about “{query}”'**
  String searchAskBot(String bot, String query);

  /// No description provided for @searchAskBotHelp.
  ///
  /// In en, this message translates to:
  /// **'Starts a new chat with this question'**
  String get searchAskBotHelp;

  /// No description provided for @searchKeysHint.
  ///
  /// In en, this message translates to:
  /// **'↑ ↓ to move   ↵ to open   esc to close'**
  String get searchKeysHint;

  /// No description provided for @searchClear.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get searchClear;

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

  /// No description provided for @attachSkill.
  ///
  /// In en, this message translates to:
  /// **'Attach a skill'**
  String get attachSkill;

  /// No description provided for @rerunSetup.
  ///
  /// In en, this message translates to:
  /// **'Run Setup Again'**
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
  /// **'Open Trace'**
  String get openTrace;

  /// No description provided for @editMessage.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editMessage;

  /// No description provided for @editMessageHelp.
  ///
  /// In en, this message translates to:
  /// **'Sending reruns the conversation from here. The original version stays; switch with the arrows.'**
  String get editMessageHelp;

  /// No description provided for @previousVersion.
  ///
  /// In en, this message translates to:
  /// **'Previous version'**
  String get previousVersion;

  /// No description provided for @nextVersion.
  ///
  /// In en, this message translates to:
  /// **'Next version'**
  String get nextVersion;

  /// No description provided for @quietHours.
  ///
  /// In en, this message translates to:
  /// **'Quiet hours'**
  String get quietHours;

  /// No description provided for @quietHoursHelp.
  ///
  /// In en, this message translates to:
  /// **'Notifications wait until quiet hours end; your inbox still fills. Approvals for a chat you\'re in still come through.'**
  String get quietHoursHelp;

  /// No description provided for @quietHoursRange.
  ///
  /// In en, this message translates to:
  /// **'{start} to {end}'**
  String quietHoursRange(String start, String end);

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// No description provided for @botNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications from this bot'**
  String get botNotifications;

  /// No description provided for @botNotificationsHelp.
  ///
  /// In en, this message translates to:
  /// **'Whether this bot follows your quiet hours'**
  String get botNotificationsHelp;

  /// No description provided for @botMayCall.
  ///
  /// In en, this message translates to:
  /// **'Can call me'**
  String get botMayCall;

  /// No description provided for @botMayCallHelp.
  ///
  /// In en, this message translates to:
  /// **'This bot can phone you when something is worth a call. Off: it sends a notification instead.'**
  String get botMayCallHelp;

  /// No description provided for @quietDefault.
  ///
  /// In en, this message translates to:
  /// **'Follow my quiet hours'**
  String get quietDefault;

  /// No description provided for @quietAlways.
  ///
  /// In en, this message translates to:
  /// **'Always notify me'**
  String get quietAlways;

  /// No description provided for @quietCustom.
  ///
  /// In en, this message translates to:
  /// **'Its own quiet hours'**
  String get quietCustom;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @until.
  ///
  /// In en, this message translates to:
  /// **'Until'**
  String get until;

  /// No description provided for @shareAsTemplate.
  ///
  /// In en, this message translates to:
  /// **'Share as Template'**
  String get shareAsTemplate;

  /// No description provided for @shareAsTemplateRow.
  ///
  /// In en, this message translates to:
  /// **'A file or link with its instructions, skills and routines'**
  String get shareAsTemplateRow;

  /// No description provided for @shareAsTemplateHelp.
  ///
  /// In en, this message translates to:
  /// **'Includes instructions, skills, routines and the services it uses. Never keys or secrets.'**
  String get shareAsTemplateHelp;

  /// No description provided for @copyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get copyLink;

  /// No description provided for @includeMemories.
  ///
  /// In en, this message translates to:
  /// **'Include Memories'**
  String get includeMemories;

  /// No description provided for @includeMemoriesHelp.
  ///
  /// In en, this message translates to:
  /// **'What it has learned about you. Share with care.'**
  String get includeMemoriesHelp;

  /// No description provided for @saveAsFile.
  ///
  /// In en, this message translates to:
  /// **'Save as File'**
  String get saveAsFile;

  /// No description provided for @notABotTemplate.
  ///
  /// In en, this message translates to:
  /// **'That file isn\'t a Casama bot template.'**
  String get notABotTemplate;

  /// No description provided for @importBot.
  ///
  /// In en, this message translates to:
  /// **'Import a bot'**
  String get importBot;

  /// No description provided for @botImported.
  ///
  /// In en, this message translates to:
  /// **'{name} is ready.'**
  String botImported(String name);

  /// No description provided for @botImportedConnect.
  ///
  /// In en, this message translates to:
  /// **'{name} is ready. Connect {services} in Integrations so it can use them.'**
  String botImportedConnect(String name, String services);

  /// No description provided for @whatComesWithIt.
  ///
  /// In en, this message translates to:
  /// **'What Comes with It'**
  String get whatComesWithIt;

  /// No description provided for @connectAfterImport.
  ///
  /// In en, this message translates to:
  /// **'Connect after importing'**
  String get connectAfterImport;

  /// No description provided for @importRoutines.
  ///
  /// In en, this message translates to:
  /// **'Schedule Its Routines'**
  String get importRoutines;

  /// No description provided for @importMemories.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Keep its 1 memory} other{Keep its {count} memories}}'**
  String importMemories(int count);

  /// No description provided for @startingRoutine.
  ///
  /// In en, this message translates to:
  /// **'Starting the routine…'**
  String get startingRoutine;

  /// No description provided for @offlineSaved.
  ///
  /// In en, this message translates to:
  /// **'Offline. Showing saved messages.'**
  String get offlineSaved;

  /// No description provided for @loadEarlierMessages.
  ///
  /// In en, this message translates to:
  /// **'Earlier Messages'**
  String get loadEarlierMessages;

  /// No description provided for @chatLoadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'This chat didn\'t load'**
  String get chatLoadFailedTitle;

  /// No description provided for @chatLoadFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Check your connection, then try again.'**
  String get chatLoadFailedBody;

  /// No description provided for @projects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get projects;

  /// No description provided for @newProject.
  ///
  /// In en, this message translates to:
  /// **'New project'**
  String get newProject;

  /// No description provided for @noProjects.
  ///
  /// In en, this message translates to:
  /// **'No projects yet'**
  String get noProjects;

  /// No description provided for @projectsHelp.
  ///
  /// In en, this message translates to:
  /// **'A project keeps one piece of work together: its chat, plan, to-dos, files and everything made for it. Work on it with a bot, or let the bot plan it and work on it by itself.'**
  String get projectsHelp;

  /// No description provided for @newProjectHelp.
  ///
  /// In en, this message translates to:
  /// **'Keeps one piece of work together: its chat, plan, to-dos, files and everything made for it.'**
  String get newProjectHelp;

  /// No description provided for @startPlanning.
  ///
  /// In en, this message translates to:
  /// **'Start Planning'**
  String get startPlanning;

  /// No description provided for @projectTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get projectTitle;

  /// No description provided for @projectGoal.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get projectGoal;

  /// No description provided for @projectDoneWhen.
  ///
  /// In en, this message translates to:
  /// **'Done when'**
  String get projectDoneWhen;

  /// No description provided for @projectLead.
  ///
  /// In en, this message translates to:
  /// **'Lead bot'**
  String get projectLead;

  /// No description provided for @projectBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get projectBudget;

  /// No description provided for @projectGoalHint.
  ///
  /// In en, this message translates to:
  /// **'What should exist at the end? A landing page live on my domain…'**
  String get projectGoalHint;

  /// No description provided for @projectDoneHint.
  ///
  /// In en, this message translates to:
  /// **'Optional. How you\'ll know it\'s finished'**
  String get projectDoneHint;

  /// No description provided for @projectBudgetHint.
  ///
  /// In en, this message translates to:
  /// **'Optional. Work pauses when it\'s spent'**
  String get projectBudgetHint;

  /// No description provided for @projectThread.
  ///
  /// In en, this message translates to:
  /// **'Project chat'**
  String get projectThread;

  /// No description provided for @approvePlan.
  ///
  /// In en, this message translates to:
  /// **'Approve the Plan'**
  String get approvePlan;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @milestones.
  ///
  /// In en, this message translates to:
  /// **'Milestones'**
  String get milestones;

  /// No description provided for @needsSignoff.
  ///
  /// In en, this message translates to:
  /// **'needs your sign-off'**
  String get needsSignoff;

  /// No description provided for @signOff.
  ///
  /// In en, this message translates to:
  /// **'Sign Off'**
  String get signOff;

  /// No description provided for @projectPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get projectPlan;

  /// No description provided for @tickets.
  ///
  /// In en, this message translates to:
  /// **'Tickets'**
  String get tickets;

  /// No description provided for @projectTimeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get projectTimeline;

  /// No description provided for @projectPlanning.
  ///
  /// In en, this message translates to:
  /// **'Planning'**
  String get projectPlanning;

  /// No description provided for @projectActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get projectActive;

  /// No description provided for @projectPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get projectPaused;

  /// No description provided for @projectBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get projectBlocked;

  /// No description provided for @projectDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get projectDone;

  /// No description provided for @projectCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get projectCancelled;

  /// No description provided for @projectName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get projectName;

  /// No description provided for @projectNameHint.
  ///
  /// In en, this message translates to:
  /// **'Space Dodger, Spring newsletter…'**
  String get projectNameHint;

  /// No description provided for @createProject.
  ///
  /// In en, this message translates to:
  /// **'Create Project'**
  String get createProject;

  /// No description provided for @projectWorksAlone.
  ///
  /// In en, this message translates to:
  /// **'Let {bot} work on it by itself'**
  String projectWorksAlone(String bot);

  /// No description provided for @projectWorksAloneHelp.
  ///
  /// In en, this message translates to:
  /// **'It drafts a plan for you to approve, then works in sessions until the goal is met. Nothing starts before you approve.'**
  String get projectWorksAloneHelp;

  /// No description provided for @projectWorksAloneOn.
  ///
  /// In en, this message translates to:
  /// **'Works in sessions until the goal is met.'**
  String get projectWorksAloneOn;

  /// No description provided for @projectWorksAloneOff.
  ///
  /// In en, this message translates to:
  /// **'You work on it together in its chat.'**
  String get projectWorksAloneOff;

  /// No description provided for @projectMade.
  ///
  /// In en, this message translates to:
  /// **'Made in this project'**
  String get projectMade;

  /// No description provided for @projectMadeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing yet. What {bot} makes in this project\'s chat shows up here.'**
  String projectMadeEmpty(String bot);

  /// No description provided for @projectSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get projectSeeAll;

  /// No description provided for @projectTodos.
  ///
  /// In en, this message translates to:
  /// **'To-dos'**
  String get projectTodos;

  /// No description provided for @projectFiles.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get projectFiles;

  /// No description provided for @projectFilesHelp.
  ///
  /// In en, this message translates to:
  /// **'{folder} on {bot}\'s computer'**
  String projectFilesHelp(String folder, String bot);

  /// No description provided for @projectMarkDone.
  ///
  /// In en, this message translates to:
  /// **'Mark as Done'**
  String get projectMarkDone;

  /// No description provided for @projectReopen.
  ///
  /// In en, this message translates to:
  /// **'Reopen'**
  String get projectReopen;

  /// No description provided for @projectCover.
  ///
  /// In en, this message translates to:
  /// **'Cover'**
  String get projectCover;

  /// No description provided for @projectCoverNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get projectCoverNone;

  /// No description provided for @projectCoverName.
  ///
  /// In en, this message translates to:
  /// **'{name, select, sailboat{Sailboat} mountain{Mountain} seedling{Seedling} compass{Compass} lantern{Lantern} telescope{Telescope} map{Map} chess{Chess} other{{name}}}'**
  String projectCoverName(String name);

  /// No description provided for @projectThings.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing yet} =1{1 thing} other{{count} things}}'**
  String projectThings(int count);

  /// No description provided for @creationProjectLabel.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get creationProjectLabel;

  /// No description provided for @creationMoveToProject.
  ///
  /// In en, this message translates to:
  /// **'Move to Project'**
  String get creationMoveToProject;

  /// No description provided for @creationNoProject.
  ///
  /// In en, this message translates to:
  /// **'No Project'**
  String get creationNoProject;

  /// No description provided for @makeProject.
  ///
  /// In en, this message translates to:
  /// **'Make This a Project'**
  String get makeProject;

  /// No description provided for @makeProjectTitle.
  ///
  /// In en, this message translates to:
  /// **'Make this topic a project'**
  String get makeProjectTitle;

  /// No description provided for @makeProjectHelp.
  ///
  /// In en, this message translates to:
  /// **'What {bot} made in this topic is filed under the project, and so is what it makes here next.'**
  String makeProjectHelp(String bot);

  /// No description provided for @openProject.
  ///
  /// In en, this message translates to:
  /// **'Open Project'**
  String get openProject;

  /// No description provided for @theBot.
  ///
  /// In en, this message translates to:
  /// **'the bot'**
  String get theBot;

  /// No description provided for @forYou.
  ///
  /// In en, this message translates to:
  /// **'For you'**
  String get forYou;

  /// No description provided for @inboxNeedsYou.
  ///
  /// In en, this message translates to:
  /// **'Needs you'**
  String get inboxNeedsYou;

  /// No description provided for @inboxNeedsYouCount.
  ///
  /// In en, this message translates to:
  /// **'Needs you ({n})'**
  String inboxNeedsYouCount(int n);

  /// No description provided for @inboxBriefs.
  ///
  /// In en, this message translates to:
  /// **'Briefs'**
  String get inboxBriefs;

  /// No description provided for @inboxUpdates.
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get inboxUpdates;

  /// No description provided for @inboxEmptyHelp.
  ///
  /// In en, this message translates to:
  /// **'Requests, morning briefs, notifications and new pages from your bots show up here.'**
  String get inboxEmptyHelp;

  /// No description provided for @inboxNeedsYouEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing needs you right now'**
  String get inboxNeedsYouEmpty;

  /// No description provided for @inboxNeedsYouEmptyHelp.
  ///
  /// In en, this message translates to:
  /// **'When a bot needs a decision, your help or has an idea, it shows up here.'**
  String get inboxNeedsYouEmptyHelp;

  /// No description provided for @noBriefs.
  ///
  /// In en, this message translates to:
  /// **'No morning briefs yet'**
  String get noBriefs;

  /// No description provided for @botPublishedPage.
  ///
  /// In en, this message translates to:
  /// **'{bot} published {title}'**
  String botPublishedPage(String bot, String title);

  /// No description provided for @forYouEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing for you right now'**
  String get forYouEmpty;

  /// No description provided for @forYouEmptyHelp.
  ///
  /// In en, this message translates to:
  /// **'Turn on check-ins in a bot\'s settings for a morning brief and suggestions through the day.'**
  String get forYouEmptyHelp;

  /// No description provided for @morningBriefFrom.
  ///
  /// In en, this message translates to:
  /// **'Morning brief from {name}'**
  String morningBriefFrom(String name);

  /// No description provided for @suggestions.
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get suggestions;

  /// No description provided for @suggestedBy.
  ///
  /// In en, this message translates to:
  /// **'Suggested by {name}'**
  String suggestedBy(String name);

  /// No description provided for @dismissSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Dismiss this suggestion?'**
  String get dismissSuggestion;

  /// No description provided for @dismissSuggestionHelp.
  ///
  /// In en, this message translates to:
  /// **'Choose whether {bot} can bring it up again.'**
  String dismissSuggestionHelp(String bot);

  /// No description provided for @justThisOnce.
  ///
  /// In en, this message translates to:
  /// **'Just This Once'**
  String get justThisOnce;

  /// No description provided for @justThisOnceHelp.
  ///
  /// In en, this message translates to:
  /// **'Hide it for now. If it still matters later, {bot} may suggest it again.'**
  String justThisOnceHelp(String bot);

  /// No description provided for @dontSuggestAgain.
  ///
  /// In en, this message translates to:
  /// **'Don\'t Suggest It Again'**
  String get dontSuggestAgain;

  /// No description provided for @dontSuggestAgainHelp.
  ///
  /// In en, this message translates to:
  /// **'Gone for good. {bot} will remember you\'d rather not.'**
  String dontSuggestAgainHelp(String bot);

  /// No description provided for @wontSuggestAgain.
  ///
  /// In en, this message translates to:
  /// **'Got it. {bot} won\'t suggest that again.'**
  String wontSuggestAgain(String bot);

  /// No description provided for @doIt.
  ///
  /// In en, this message translates to:
  /// **'Do It'**
  String get doIt;

  /// No description provided for @checkins.
  ///
  /// In en, this message translates to:
  /// **'Check-Ins'**
  String get checkins;

  /// No description provided for @checkinsHelp.
  ///
  /// In en, this message translates to:
  /// **'A morning brief and a look every few hours for things that need you. Off by default.'**
  String get checkinsHelp;

  /// No description provided for @briefTime.
  ///
  /// In en, this message translates to:
  /// **'Morning brief at'**
  String get briefTime;

  /// No description provided for @scanEvery.
  ///
  /// In en, this message translates to:
  /// **'Look every'**
  String get scanEvery;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour} other{{count} hours}}'**
  String hours(int count);

  /// No description provided for @dailyCap.
  ///
  /// In en, this message translates to:
  /// **'Daily limit'**
  String get dailyCap;

  /// No description provided for @on.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get on;

  /// No description provided for @actionRules.
  ///
  /// In en, this message translates to:
  /// **'Action rules'**
  String get actionRules;

  /// No description provided for @actionRulesRow.
  ///
  /// In en, this message translates to:
  /// **'What it may do without asking'**
  String get actionRulesRow;

  /// No description provided for @actionRulesHelp.
  ///
  /// In en, this message translates to:
  /// **'Rules decide per action: allow, allow within limits, ask first, or hand it to you to finish. The most specific rule wins; with no rule, the bot\'s autonomy decides. Bots can\'t change their own rules.'**
  String get actionRulesHelp;

  /// No description provided for @addRule.
  ///
  /// In en, this message translates to:
  /// **'Add a rule'**
  String get addRule;

  /// No description provided for @addRuleHelp.
  ///
  /// In en, this message translates to:
  /// **'Pick what the bot is doing and how it should handle it.'**
  String get addRuleHelp;

  /// No description provided for @noRules.
  ///
  /// In en, this message translates to:
  /// **'No rules yet. The bot\'s autonomy level decides.'**
  String get noRules;

  /// No description provided for @otherTools.
  ///
  /// In en, this message translates to:
  /// **'Specific Tools'**
  String get otherTools;

  /// No description provided for @workspaceRule.
  ///
  /// In en, this message translates to:
  /// **'Workspace rule'**
  String get workspaceRule;

  /// No description provided for @catSend.
  ///
  /// In en, this message translates to:
  /// **'Sending messages'**
  String get catSend;

  /// No description provided for @catPay.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get catPay;

  /// No description provided for @catDelete.
  ///
  /// In en, this message translates to:
  /// **'Deleting'**
  String get catDelete;

  /// No description provided for @catPublish.
  ///
  /// In en, this message translates to:
  /// **'Publishing'**
  String get catPublish;

  /// No description provided for @catShare.
  ///
  /// In en, this message translates to:
  /// **'Sharing and invites'**
  String get catShare;

  /// No description provided for @catSignIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in'**
  String get catSignIn;

  /// No description provided for @whenTheBot.
  ///
  /// In en, this message translates to:
  /// **'When the bot is'**
  String get whenTheBot;

  /// No description provided for @itShould.
  ///
  /// In en, this message translates to:
  /// **'It should'**
  String get itShould;

  /// No description provided for @ruleAllow.
  ///
  /// In en, this message translates to:
  /// **'Go ahead'**
  String get ruleAllow;

  /// No description provided for @ruleAllowLimits.
  ///
  /// In en, this message translates to:
  /// **'Go ahead within limits'**
  String get ruleAllowLimits;

  /// No description provided for @ruleAsk.
  ///
  /// In en, this message translates to:
  /// **'Ask me first'**
  String get ruleAsk;

  /// No description provided for @ruleHandOff.
  ///
  /// In en, this message translates to:
  /// **'Hand it to me to finish'**
  String get ruleHandOff;

  /// No description provided for @ruleDomains.
  ///
  /// In en, this message translates to:
  /// **'Only to these domains (comma separated)'**
  String get ruleDomains;

  /// No description provided for @ruleMaxAmount.
  ///
  /// In en, this message translates to:
  /// **'Up to this amount'**
  String get ruleMaxAmount;

  /// No description provided for @ruleForWorkspace.
  ///
  /// In en, this message translates to:
  /// **'For every bot in the workspace'**
  String get ruleForWorkspace;

  /// No description provided for @watchers.
  ///
  /// In en, this message translates to:
  /// **'Watchers'**
  String get watchers;

  /// No description provided for @watchersRow.
  ///
  /// In en, this message translates to:
  /// **'What it\'s keeping an eye on'**
  String get watchersRow;

  /// No description provided for @noWatchers.
  ///
  /// In en, this message translates to:
  /// **'Not watching anything'**
  String get noWatchers;

  /// No description provided for @watchersHelp.
  ///
  /// In en, this message translates to:
  /// **'Ask the bot \"tell me when…\" and it watches a page, a reply, a result or a time. Checks cost nothing until something changes.'**
  String get watchersHelp;

  /// No description provided for @watcherActive.
  ///
  /// In en, this message translates to:
  /// **'Watching'**
  String get watcherActive;

  /// No description provided for @watcherPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get watcherPaused;

  /// No description provided for @watcherDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get watcherDone;

  /// No description provided for @watcherExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get watcherExpired;

  /// No description provided for @firedTimes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{not fired yet} =1{fired once} other{fired {count} times}}'**
  String firedTimes(int count);

  /// No description provided for @connectAiApp.
  ///
  /// In en, this message translates to:
  /// **'Connect an AI app'**
  String get connectAiApp;

  /// No description provided for @connectAiAppAsk.
  ///
  /// In en, this message translates to:
  /// **'{app} wants to use Casama'**
  String connectAiAppAsk(String app);

  /// No description provided for @connectAiAppHelp.
  ///
  /// In en, this message translates to:
  /// **'It can list your bots, ask them to do things and read results in the workspace you pick, as you. Your bots\' approvals and rules still apply. You\'ll go back to {host}.'**
  String connectAiAppHelp(String host);

  /// No description provided for @connectAiAppDone.
  ///
  /// In en, this message translates to:
  /// **'Done. You can go back to the AI app.'**
  String get connectAiAppDone;

  /// No description provided for @refuse.
  ///
  /// In en, this message translates to:
  /// **'Refuse'**
  String get refuse;

  /// No description provided for @allow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get allow;

  /// No description provided for @connectAiApps.
  ///
  /// In en, this message translates to:
  /// **'Connect AI Apps'**
  String get connectAiApps;

  /// No description provided for @connectAiAppsHelp.
  ///
  /// In en, this message translates to:
  /// **'Apps that support MCP connect to this address and sign in, or use an API key. They act as the person who connected them.'**
  String get connectAiAppsHelp;

  /// No description provided for @mcpApprovals.
  ///
  /// In en, this message translates to:
  /// **'Allow Approvals from AI Apps'**
  String get mcpApprovals;

  /// No description provided for @mcpApprovalsHelp.
  ///
  /// In en, this message translates to:
  /// **'Connected apps can approve your bots\' actions.'**
  String get mcpApprovalsHelp;

  /// No description provided for @newApiKey.
  ///
  /// In en, this message translates to:
  /// **'New API Key'**
  String get newApiKey;

  /// No description provided for @apiKeyName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get apiKeyName;

  /// No description provided for @newGroupChat.
  ///
  /// In en, this message translates to:
  /// **'New group chat'**
  String get newGroupChat;

  /// No description provided for @groupChats.
  ///
  /// In en, this message translates to:
  /// **'Group chats'**
  String get groupChats;

  /// No description provided for @groupWhoAnswers.
  ///
  /// In en, this message translates to:
  /// **'{names} will answer'**
  String groupWhoAnswers(String names);

  /// No description provided for @groupEveryoneAnswers.
  ///
  /// In en, this message translates to:
  /// **'Everyone will answer'**
  String get groupEveryoneAnswers;

  /// No description provided for @groupMentionHint.
  ///
  /// In en, this message translates to:
  /// **'@mention a bot, or @everyone'**
  String get groupMentionHint;

  /// No description provided for @routineRan.
  ///
  /// In en, this message translates to:
  /// **'Routine “{name}” ran'**
  String routineRan(String name);

  /// No description provided for @groupBotCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 bot} other{{count} bots}}'**
  String groupBotCount(int count);

  /// No description provided for @botWaitingCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 thing waiting for you} other{{count} things waiting for you}}'**
  String botWaitingCount(int count);

  /// No description provided for @newGroupChatHelp.
  ///
  /// In en, this message translates to:
  /// **'Bring 2 to 10 bots into one chat. @Name asks one bot; @everyone asks the lead to plan and share out the work.'**
  String get newGroupChatHelp;

  /// No description provided for @groupCreate.
  ///
  /// In en, this message translates to:
  /// **'Create group chat'**
  String get groupCreate;

  /// No description provided for @groupCrewEmpty.
  ///
  /// In en, this message translates to:
  /// **'Pick bots below to build the group.'**
  String get groupCrewEmpty;

  /// No description provided for @groupLeadShort.
  ///
  /// In en, this message translates to:
  /// **'Lead'**
  String get groupLeadShort;

  /// No description provided for @groupMakeLead.
  ///
  /// In en, this message translates to:
  /// **'Make lead'**
  String get groupMakeLead;

  /// No description provided for @groupRemoveBot.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}'**
  String groupRemoveBot(String name);

  /// No description provided for @groupPickMore.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Pick 1 more bot} other{Pick {count} more bots}}'**
  String groupPickMore(int count);

  /// No description provided for @groupFull.
  ///
  /// In en, this message translates to:
  /// **'That\'s 10 bots, the most a group can have.'**
  String get groupFull;

  /// No description provided for @groupLeadHint.
  ///
  /// In en, this message translates to:
  /// **'The lead plans the work when you @everyone. Tap another bot at the top to make it lead.'**
  String get groupLeadHint;

  /// No description provided for @groupNeedTwoBots.
  ///
  /// In en, this message translates to:
  /// **'A group chat needs at least two bots. Make another bot first.'**
  String get groupNeedTwoBots;

  /// No description provided for @groupSearchBots.
  ///
  /// In en, this message translates to:
  /// **'Search bots'**
  String get groupSearchBots;

  /// No description provided for @groupNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No bots match that name.'**
  String get groupNoMatch;

  /// No description provided for @groupTitle.
  ///
  /// In en, this message translates to:
  /// **'Name (optional)'**
  String get groupTitle;

  /// No description provided for @groupPickBots.
  ///
  /// In en, this message translates to:
  /// **'Bots'**
  String get groupPickBots;

  /// No description provided for @groupLead.
  ///
  /// In en, this message translates to:
  /// **'Leads the group'**
  String get groupLead;

  /// No description provided for @mentionEveryone.
  ///
  /// In en, this message translates to:
  /// **'everyone'**
  String get mentionEveryone;

  /// No description provided for @pages.
  ///
  /// In en, this message translates to:
  /// **'Pages'**
  String get pages;

  /// No description provided for @pagesRow.
  ///
  /// In en, this message translates to:
  /// **'Reports and dashboards it published'**
  String get pagesRow;

  /// No description provided for @noPages.
  ///
  /// In en, this message translates to:
  /// **'No pages yet'**
  String get noPages;

  /// No description provided for @pagesHelp.
  ///
  /// In en, this message translates to:
  /// **'Ask a bot for a report, dashboard or tracker and it can publish it as a page. Pages open in your browser and stay private until you share them.'**
  String get pagesHelp;

  /// No description provided for @pagePrivate.
  ///
  /// In en, this message translates to:
  /// **'Only me'**
  String get pagePrivate;

  /// No description provided for @pageWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Workspace'**
  String get pageWorkspace;

  /// No description provided for @pagePublic.
  ///
  /// In en, this message translates to:
  /// **'Anyone with the link'**
  String get pagePublic;

  /// No description provided for @pageRefreshes.
  ///
  /// In en, this message translates to:
  /// **'Refreshes on schedule'**
  String get pageRefreshes;

  /// No description provided for @pageCardOpen.
  ///
  /// In en, this message translates to:
  /// **'Page · Tap to open'**
  String get pageCardOpen;

  /// No description provided for @pageUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {date}'**
  String pageUpdated(String date);

  /// No description provided for @exportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get exportPdf;

  /// No description provided for @pageMakePublicTitle.
  ///
  /// In en, this message translates to:
  /// **'Make this page public?'**
  String get pageMakePublicTitle;

  /// No description provided for @pageMakePublicBody.
  ///
  /// In en, this message translates to:
  /// **'Anyone with the link can open it, including the data on it. You can take it back any time; the link stops working.'**
  String get pageMakePublicBody;

  /// No description provided for @pageMakePublic.
  ///
  /// In en, this message translates to:
  /// **'Make Public'**
  String get pageMakePublic;

  /// No description provided for @pagePublicLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Public Link'**
  String get pagePublicLinkTitle;

  /// No description provided for @pagePublicLinkBody.
  ///
  /// In en, this message translates to:
  /// **'Copied. It isn\'t listed in search engines.'**
  String get pagePublicLinkBody;

  /// No description provided for @deletePageTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{title}\"?'**
  String deletePageTitle(String title);

  /// No description provided for @openPages.
  ///
  /// In en, this message translates to:
  /// **'Open in Pages'**
  String get openPages;

  /// No description provided for @skillInstructions.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get skillInstructions;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @teachTask.
  ///
  /// In en, this message translates to:
  /// **'Teach a task'**
  String get teachTask;

  /// No description provided for @teachWhichBot.
  ///
  /// In en, this message translates to:
  /// **'Which bot should learn this?'**
  String get teachWhichBot;

  /// No description provided for @teachRecording.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get teachRecording;

  /// No description provided for @teachRecordingPaused.
  ///
  /// In en, this message translates to:
  /// **'Recording stopped'**
  String get teachRecordingPaused;

  /// No description provided for @teachRecordingHelp.
  ///
  /// In en, this message translates to:
  /// **'Do the task as you normally would. Each step is saved with what\'s on screen; password fields never are.'**
  String get teachRecordingHelp;

  /// No description provided for @teachStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get teachStop;

  /// No description provided for @teachMarkSecret.
  ///
  /// In en, this message translates to:
  /// **'Mark as Secret'**
  String get teachMarkSecret;

  /// No description provided for @teachMarkSecretHelp.
  ///
  /// In en, this message translates to:
  /// **'What you just typed is deleted from the recording and becomes a secret input the bot asks for.'**
  String get teachMarkSecretHelp;

  /// No description provided for @teachDraftTitle.
  ///
  /// In en, this message translates to:
  /// **'New skill'**
  String get teachDraftTitle;

  /// No description provided for @teachDrafting.
  ///
  /// In en, this message translates to:
  /// **'Writing a skill from your recording…'**
  String get teachDrafting;

  /// No description provided for @teachSteps.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 step} other{{count} steps}}'**
  String teachSteps(int count);

  /// No description provided for @teachRecordedSteps.
  ///
  /// In en, this message translates to:
  /// **'What you showed ({count, plural, =1{1 step} other{{count} steps}})'**
  String teachRecordedSteps(int count);

  /// No description provided for @teachReviewHelp.
  ///
  /// In en, this message translates to:
  /// **'Check the steps, inputs and success checks, then save. You can try it right away.'**
  String get teachReviewHelp;

  /// No description provided for @teachDraftFailed.
  ///
  /// In en, this message translates to:
  /// **'The bot couldn\'t write a draft. Write the steps yourself from the recording below, or discard it.'**
  String get teachDraftFailed;

  /// No description provided for @teachAlreadySaved.
  ///
  /// In en, this message translates to:
  /// **'This skill is saved'**
  String get teachAlreadySaved;

  /// No description provided for @teachSaveAndTry.
  ///
  /// In en, this message translates to:
  /// **'Save and Try'**
  String get teachSaveAndTry;

  /// No description provided for @teachSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved {name}'**
  String teachSaved(String name);

  /// No description provided for @teachDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard this recording?'**
  String get teachDiscardTitle;

  /// No description provided for @teachDiscardBody.
  ///
  /// In en, this message translates to:
  /// **'Every step, snapshot and screenshot it captured is deleted.'**
  String get teachDiscardBody;

  /// No description provided for @teachStepClick.
  ///
  /// In en, this message translates to:
  /// **'Click at {x}, {y}'**
  String teachStepClick(int x, int y);

  /// No description provided for @teachStepType.
  ///
  /// In en, this message translates to:
  /// **'Type “{text}”'**
  String teachStepType(String text);

  /// No description provided for @teachStepSecret.
  ///
  /// In en, this message translates to:
  /// **'Type secret {name}'**
  String teachStepSecret(String name);

  /// No description provided for @teachStepKey.
  ///
  /// In en, this message translates to:
  /// **'Press {key}'**
  String teachStepKey(String key);

  /// No description provided for @teachStepScroll.
  ///
  /// In en, this message translates to:
  /// **'Scroll'**
  String get teachStepScroll;

  /// No description provided for @plugins.
  ///
  /// In en, this message translates to:
  /// **'Plugins'**
  String get plugins;

  /// No description provided for @pluginsRow.
  ///
  /// In en, this message translates to:
  /// **'Skills and tools from plugin packages'**
  String get pluginsRow;

  /// No description provided for @noPlugins.
  ///
  /// In en, this message translates to:
  /// **'No plugins yet'**
  String get noPlugins;

  /// No description provided for @pluginsHelp.
  ///
  /// In en, this message translates to:
  /// **'Plugins are Agent Plugins 1.0 packages on GitHub. They can bring skills and MCP tools; their servers run on this bot\'s computer, never on Casama\'s servers.'**
  String get pluginsHelp;

  /// No description provided for @addPlugin.
  ///
  /// In en, this message translates to:
  /// **'Add a plugin'**
  String get addPlugin;

  /// No description provided for @addPluginHelp.
  ///
  /// In en, this message translates to:
  /// **'Paste a GitHub link to the plugin\'s folder. You\'ll see what it adds before anything is installed.'**
  String get addPluginHelp;

  /// No description provided for @pluginAdds.
  ///
  /// In en, this message translates to:
  /// **'It adds'**
  String get pluginAdds;

  /// No description provided for @pluginStdio.
  ///
  /// In en, this message translates to:
  /// **'Runs on the bot\'s computer: {command}'**
  String pluginStdio(String command);

  /// No description provided for @pluginRemote.
  ///
  /// In en, this message translates to:
  /// **'Connects to {url}'**
  String pluginRemote(String url);

  /// No description provided for @pluginTalksTo.
  ///
  /// In en, this message translates to:
  /// **'Talks to: {hosts}'**
  String pluginTalksTo(String hosts);

  /// No description provided for @pluginSkill.
  ///
  /// In en, this message translates to:
  /// **'Skill'**
  String get pluginSkill;

  /// No description provided for @pluginHosts.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get pluginHosts;

  /// No description provided for @pluginServerError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t start'**
  String get pluginServerError;

  /// No description provided for @pluginRunsOnComputer.
  ///
  /// In en, this message translates to:
  /// **'Runs on the bot\'s computer'**
  String get pluginRunsOnComputer;

  /// No description provided for @pluginWhereToolsRun.
  ///
  /// In en, this message translates to:
  /// **'Where its tools run'**
  String get pluginWhereToolsRun;

  /// No description provided for @pluginWhereToolsRunHelp.
  ///
  /// In en, this message translates to:
  /// **'On your own computer the tools can use what\'s there, and only you can use them, from your own chats. Servers on the internet aren\'t affected.'**
  String get pluginWhereToolsRunHelp;

  /// No description provided for @pluginPlaceBot.
  ///
  /// In en, this message translates to:
  /// **'The bot\'s computer'**
  String get pluginPlaceBot;

  /// No description provided for @pluginPlaceMine.
  ///
  /// In en, this message translates to:
  /// **'My computer: {name}'**
  String pluginPlaceMine(String name);

  /// No description provided for @pluginRunsOnDevice.
  ///
  /// In en, this message translates to:
  /// **'Runs on {name}'**
  String pluginRunsOnDevice(String name);

  /// No description provided for @pluginRunsOnDeviceHelp.
  ///
  /// In en, this message translates to:
  /// **'Its tools work only in chats with the person whose computer it is'**
  String get pluginRunsOnDeviceHelp;

  /// No description provided for @pluginRunsOnDeviceOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline: its tools work again when the Casama app is open there'**
  String get pluginRunsOnDeviceOffline;

  /// No description provided for @pluginUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Already up to date'**
  String get pluginUpToDate;

  /// No description provided for @checkForUpdate.
  ///
  /// In en, this message translates to:
  /// **'Check for Update'**
  String get checkForUpdate;

  /// No description provided for @uninstall.
  ///
  /// In en, this message translates to:
  /// **'Uninstall'**
  String get uninstall;

  /// No description provided for @uninstallPluginTitle.
  ///
  /// In en, this message translates to:
  /// **'Uninstall {name}?'**
  String uninstallPluginTitle(String name);

  /// No description provided for @uninstallPluginBody.
  ///
  /// In en, this message translates to:
  /// **'Its skills, tools, files and saved secrets are removed from this bot.'**
  String get uninstallPluginBody;

  /// No description provided for @updatePluginTitle.
  ///
  /// In en, this message translates to:
  /// **'Update {name}'**
  String updatePluginTitle(String name);

  /// No description provided for @pluginDiffSkillsAdded.
  ///
  /// In en, this message translates to:
  /// **'New skills: {names}'**
  String pluginDiffSkillsAdded(String names);

  /// No description provided for @pluginDiffSkillsChanged.
  ///
  /// In en, this message translates to:
  /// **'Changed skills: {names}'**
  String pluginDiffSkillsChanged(String names);

  /// No description provided for @pluginDiffSkillsRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed skills: {names}'**
  String pluginDiffSkillsRemoved(String names);

  /// No description provided for @pluginDiffServersAdded.
  ///
  /// In en, this message translates to:
  /// **'New tool servers: {names}'**
  String pluginDiffServersAdded(String names);

  /// No description provided for @pluginDiffServersChanged.
  ///
  /// In en, this message translates to:
  /// **'Changed tool servers: {names}'**
  String pluginDiffServersChanged(String names);

  /// No description provided for @pluginDiffServersRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed tool servers: {names}'**
  String pluginDiffServersRemoved(String names);

  /// No description provided for @pluginDiffHosts.
  ///
  /// In en, this message translates to:
  /// **'Talks to new hosts: {hosts}'**
  String pluginDiffHosts(String hosts);

  /// No description provided for @pluginDiffNone.
  ///
  /// In en, this message translates to:
  /// **'No changes to what it adds.'**
  String get pluginDiffNone;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @botNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get botNameLabel;

  /// No description provided for @importAgent.
  ///
  /// In en, this message translates to:
  /// **'Import an Agent'**
  String get importAgent;

  /// No description provided for @importAgentPickFolder.
  ///
  /// In en, this message translates to:
  /// **'Pick Its Folder'**
  String get importAgentPickFolder;

  /// No description provided for @importAgentPickZip.
  ///
  /// In en, this message translates to:
  /// **'Upload a ZIP of its folder'**
  String get importAgentPickZip;

  /// No description provided for @importPasteChoice.
  ///
  /// In en, this message translates to:
  /// **'Paste a Bot\'s Setup'**
  String get importPasteChoice;

  /// No description provided for @importPasteChoiceHelp.
  ///
  /// In en, this message translates to:
  /// **'From Grok Bot, Muse, ChatGPT Dots, Claude Duet, Hark, Instinct or another app'**
  String get importPasteChoiceHelp;

  /// No description provided for @importPasteTitle.
  ///
  /// In en, this message translates to:
  /// **'Paste a Bot\'s Setup'**
  String get importPasteTitle;

  /// No description provided for @importPasteHelp.
  ///
  /// In en, this message translates to:
  /// **'Send your bot the prompt below, then paste its whole reply. You\'ll review everything before the new bot is created.'**
  String get importPasteHelp;

  /// No description provided for @importPasteSource.
  ///
  /// In en, this message translates to:
  /// **'Where is your bot now?'**
  String get importPasteSource;

  /// No description provided for @importPasteOther.
  ///
  /// In en, this message translates to:
  /// **'Somewhere else'**
  String get importPasteOther;

  /// No description provided for @importPasteStep1.
  ///
  /// In en, this message translates to:
  /// **'1. Send your bot this prompt'**
  String get importPasteStep1;

  /// No description provided for @importPasteReply.
  ///
  /// In en, this message translates to:
  /// **'2. Paste its reply'**
  String get importPasteReply;

  /// No description provided for @importPasteSafety.
  ///
  /// In en, this message translates to:
  /// **'Lines that look like keys, passwords or card numbers are removed. Sign in to its apps again after importing.'**
  String get importPasteSafety;

  /// No description provided for @importPasteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pasted setup'**
  String get importPasteSubtitle;

  /// No description provided for @agentImportReviewHelp.
  ///
  /// In en, this message translates to:
  /// **'Untick anything you don\'t want. Nothing is created until you import.'**
  String get agentImportReviewHelp;

  /// No description provided for @agentImportNoPersona.
  ///
  /// In en, this message translates to:
  /// **'No persona file was found.'**
  String get agentImportNoPersona;

  /// No description provided for @agentImportSkills.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 skill} other{{count} skills}}'**
  String agentImportSkills(int count);

  /// No description provided for @agentImportRoutines.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 routine} other{{count} routines}}'**
  String agentImportRoutines(int count);

  /// No description provided for @agentImportMemories.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 memory} other{{count} memories}}'**
  String agentImportMemories(int count);

  /// No description provided for @agentImportLeftovers.
  ///
  /// In en, this message translates to:
  /// **'Copy {count, plural, =1{1 other file} other{{count} other files}} to ~/imported/ on its computer'**
  String agentImportLeftovers(int count);

  /// No description provided for @agentImportSkipped.
  ///
  /// In en, this message translates to:
  /// **'Not imported: {files}'**
  String agentImportSkipped(String files);

  /// No description provided for @agentImportedWithFiles.
  ///
  /// In en, this message translates to:
  /// **'Imported {name} and copied {count} files to its computer'**
  String agentImportedWithFiles(String name, int count);

  /// No description provided for @agentImportedFilesLater.
  ///
  /// In en, this message translates to:
  /// **'Imported {name}. Its other files couldn\'t be copied yet; give it a computer and import again to copy them.'**
  String agentImportedFilesLater(String name);

  /// No description provided for @importMemoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Import memories from ChatGPT or Claude'**
  String get importMemoryTitle;

  /// No description provided for @importMemoryHelp.
  ///
  /// In en, this message translates to:
  /// **'Copy this prompt into ChatGPT or Claude, then paste its answer below.'**
  String get importMemoryHelp;

  /// No description provided for @importMemoryPick.
  ///
  /// In en, this message translates to:
  /// **'Keep what\'s right; untick the rest.'**
  String get importMemoryPick;

  /// No description provided for @importMemoryPaste.
  ///
  /// In en, this message translates to:
  /// **'Its answer'**
  String get importMemoryPaste;

  /// No description provided for @importMemoryNone.
  ///
  /// In en, this message translates to:
  /// **'No memories found in that answer.'**
  String get importMemoryNone;

  /// No description provided for @memoriesImported.
  ///
  /// In en, this message translates to:
  /// **'Added {count, plural, =1{1 memory} other{{count} memories}}'**
  String memoriesImported(int count);

  /// No description provided for @routinesAsFiles.
  ///
  /// In en, this message translates to:
  /// **'Routines and Skills as Files'**
  String get routinesAsFiles;

  /// No description provided for @routinesAsFilesHelp.
  ///
  /// In en, this message translates to:
  /// **'Every routine and skill as a Markdown file: export them, edit them anywhere, import them back, or keep them in a GitHub repository.'**
  String get routinesAsFilesHelp;

  /// No description provided for @exportFiles.
  ///
  /// In en, this message translates to:
  /// **'Export as Files'**
  String get exportFiles;

  /// No description provided for @importFiles.
  ///
  /// In en, this message translates to:
  /// **'Import Files'**
  String get importFiles;

  /// No description provided for @importFilesApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get importFilesApply;

  /// No description provided for @filesPreview.
  ///
  /// In en, this message translates to:
  /// **'{created} new, {updated} changed, {unchanged} unchanged'**
  String filesPreview(int created, int updated, int unchanged);

  /// No description provided for @filesImported.
  ///
  /// In en, this message translates to:
  /// **'Imported: {created} new, {updated} changed'**
  String filesImported(int created, int updated);

  /// No description provided for @gitSync.
  ///
  /// In en, this message translates to:
  /// **'Git Sync'**
  String get gitSync;

  /// No description provided for @gitSyncOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get gitSyncOff;

  /// No description provided for @gitSyncHelp.
  ///
  /// In en, this message translates to:
  /// **'Changes in Casama are committed to the repository, and pushes to it update Casama after they\'re checked. If a file changed in both places, Casama keeps its version and opens a pull request. Needs a GITHUB_TOKEN secret allowed for api.github.com.'**
  String get gitSyncHelp;

  /// No description provided for @gitSyncNeedsToken.
  ///
  /// In en, this message translates to:
  /// **'Needs a GITHUB_TOKEN secret'**
  String get gitSyncNeedsToken;

  /// No description provided for @gitSyncLast.
  ///
  /// In en, this message translates to:
  /// **'Synced {date}'**
  String gitSyncLast(String date);

  /// No description provided for @gitSyncPr.
  ///
  /// In en, this message translates to:
  /// **'Pull Request Waiting for You'**
  String get gitSyncPr;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncNow;

  /// No description provided for @syncQueued.
  ///
  /// In en, this message translates to:
  /// **'Syncing within a minute'**
  String get syncQueued;

  /// No description provided for @gitBranch.
  ///
  /// In en, this message translates to:
  /// **'Branch'**
  String get gitBranch;

  /// No description provided for @gitFolder.
  ///
  /// In en, this message translates to:
  /// **'Folder in the repository (optional)'**
  String get gitFolder;

  /// No description provided for @gitSyncOn.
  ///
  /// In en, this message translates to:
  /// **'Sync On'**
  String get gitSyncOn;

  /// No description provided for @gitSyncRemove.
  ///
  /// In en, this message translates to:
  /// **'Stop Syncing'**
  String get gitSyncRemove;

  /// No description provided for @gitWebhookTitle.
  ///
  /// In en, this message translates to:
  /// **'Add this webhook to the repository'**
  String get gitWebhookTitle;

  /// No description provided for @gitWebhookHelp.
  ///
  /// In en, this message translates to:
  /// **'In the repository\'s settings, add a webhook for push events with this address and secret (content type application/json). The secret is shown only now.'**
  String get gitWebhookHelp;

  /// No description provided for @gitWebhookUrl.
  ///
  /// In en, this message translates to:
  /// **'Payload URL'**
  String get gitWebhookUrl;

  /// No description provided for @gitWebhookSecret.
  ///
  /// In en, this message translates to:
  /// **'Secret'**
  String get gitWebhookSecret;

  /// No description provided for @knowledge.
  ///
  /// In en, this message translates to:
  /// **'Knowledge'**
  String get knowledge;

  /// No description provided for @knowledgeRow.
  ///
  /// In en, this message translates to:
  /// **'Documents it can search and cite'**
  String get knowledgeRow;

  /// No description provided for @noKnowledge.
  ///
  /// In en, this message translates to:
  /// **'No knowledge yet'**
  String get noKnowledge;

  /// No description provided for @knowledgeHelp.
  ///
  /// In en, this message translates to:
  /// **'Give it files, a website or a GitHub repository. It searches them when they\'re relevant and tells you which document an answer came from.'**
  String get knowledgeHelp;

  /// No description provided for @addKnowledge.
  ///
  /// In en, this message translates to:
  /// **'Add knowledge'**
  String get addKnowledge;

  /// No description provided for @addKnowledgeHelp.
  ///
  /// In en, this message translates to:
  /// **'PDF, Word, Markdown, HTML, CSV or text files; a website (one domain, following its robots.txt); or a repository\'s documents. Websites and repositories refresh daily.'**
  String get addKnowledgeHelp;

  /// No description provided for @knowledgeFiles.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get knowledgeFiles;

  /// No description provided for @knowledgeWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get knowledgeWebsite;

  /// No description provided for @knowledgePickFiles.
  ///
  /// In en, this message translates to:
  /// **'Choose Files'**
  String get knowledgePickFiles;

  /// No description provided for @knowledgeWebsiteUrl.
  ///
  /// In en, this message translates to:
  /// **'Website address'**
  String get knowledgeWebsiteUrl;

  /// No description provided for @knowledgeRepoUrl.
  ///
  /// In en, this message translates to:
  /// **'GitHub link'**
  String get knowledgeRepoUrl;

  /// No description provided for @knowledgeShareAll.
  ///
  /// In en, this message translates to:
  /// **'Share with every bot in the workspace'**
  String get knowledgeShareAll;

  /// No description provided for @knowledgeShared.
  ///
  /// In en, this message translates to:
  /// **'Whole workspace'**
  String get knowledgeShared;

  /// No description provided for @knowledgeReady.
  ///
  /// In en, this message translates to:
  /// **'{docs, plural, =1{1 document} other{{docs} documents}}, {chunks} passages'**
  String knowledgeReady(int docs, int chunks);

  /// No description provided for @knowledgeError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read it'**
  String get knowledgeError;

  /// No description provided for @knowledgeSyncing.
  ///
  /// In en, this message translates to:
  /// **'Reading…'**
  String get knowledgeSyncing;

  /// No description provided for @knowledgePending.
  ///
  /// In en, this message translates to:
  /// **'Waiting to be read'**
  String get knowledgePending;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @skillIdeaFrom.
  ///
  /// In en, this message translates to:
  /// **'{bot} suggests a skill: {name}'**
  String skillIdeaFrom(String bot, String name);

  /// No description provided for @skillEditFrom.
  ///
  /// In en, this message translates to:
  /// **'{bot} suggests improving {name}'**
  String skillEditFrom(String bot, String name);

  /// No description provided for @skillUsesTools.
  ///
  /// In en, this message translates to:
  /// **'Uses: {tools}'**
  String skillUsesTools(String tools);

  /// No description provided for @saveSkill.
  ///
  /// In en, this message translates to:
  /// **'Save Skill'**
  String get saveSkill;

  /// No description provided for @applyEdit.
  ///
  /// In en, this message translates to:
  /// **'Apply Change'**
  String get applyEdit;

  /// No description provided for @skillSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved {name}'**
  String skillSaved(String name);

  /// No description provided for @skillUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {name}'**
  String skillUpdated(String name);

  /// No description provided for @skillStats.
  ///
  /// In en, this message translates to:
  /// **'How it\'s doing'**
  String get skillStats;

  /// No description provided for @skillNotUsedYet.
  ///
  /// In en, this message translates to:
  /// **'Not used yet'**
  String get skillNotUsedYet;

  /// No description provided for @skillStatsLine.
  ///
  /// In en, this message translates to:
  /// **'Used {uses} times · {rate}% went well · {failures} failed · {corrections} corrected'**
  String skillStatsLine(int uses, int rate, int failures, int corrections);

  /// No description provided for @skillLastFailure.
  ///
  /// In en, this message translates to:
  /// **'Last problem: {date}'**
  String skillLastFailure(String date);

  /// No description provided for @skillHistory.
  ///
  /// In en, this message translates to:
  /// **'Earlier versions'**
  String get skillHistory;

  /// No description provided for @replays.
  ///
  /// In en, this message translates to:
  /// **'Replays'**
  String get replays;

  /// No description provided for @replaysRow.
  ///
  /// In en, this message translates to:
  /// **'Recorded steps it runs without thinking'**
  String get replaysRow;

  /// No description provided for @noReplays.
  ///
  /// In en, this message translates to:
  /// **'No replays yet'**
  String get noReplays;

  /// No description provided for @replaysHelp.
  ///
  /// In en, this message translates to:
  /// **'A replay is a recorded set of browser or desktop steps the bot runs as is, which is faster and cheaper. If a step doesn\'t work any more, the bot takes over from there and can update the replay. Save one from a teach recording, or ask the bot to save what it just did.'**
  String get replaysHelp;

  /// No description provided for @replaySteps.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 step} other{{count} steps}}'**
  String replaySteps(int count);

  /// No description provided for @replayRuns.
  ///
  /// In en, this message translates to:
  /// **'run {runs} times, {failures} needed help'**
  String replayRuns(int runs, int failures);

  /// No description provided for @runReplay.
  ///
  /// In en, this message translates to:
  /// **'Run {name}'**
  String runReplay(String name);

  /// No description provided for @runReplayHelp.
  ///
  /// In en, this message translates to:
  /// **'Check the values it fills in, then run it.'**
  String get runReplayHelp;

  /// No description provided for @run.
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get run;

  /// No description provided for @saveAsReplay.
  ///
  /// In en, this message translates to:
  /// **'Also Save as a Replay'**
  String get saveAsReplay;

  /// No description provided for @replaySaved.
  ///
  /// In en, this message translates to:
  /// **'Saved the replay {name}'**
  String replaySaved(String name);

  /// No description provided for @passwordManagers.
  ///
  /// In en, this message translates to:
  /// **'Password managers'**
  String get passwordManagers;

  /// No description provided for @passwordManagersRow.
  ///
  /// In en, this message translates to:
  /// **'1Password or Bitwarden logins for bots'**
  String get passwordManagersRow;

  /// No description provided for @noPasswordManagers.
  ///
  /// In en, this message translates to:
  /// **'No password managers connected'**
  String get noPasswordManagers;

  /// No description provided for @passwordManagersHelp.
  ///
  /// In en, this message translates to:
  /// **'Bots can sign in with logins from the vaults you choose. They never see a password: it\'s filled into the browser only on that login\'s own sites.'**
  String get passwordManagersHelp;

  /// No description provided for @connectPasswordManager.
  ///
  /// In en, this message translates to:
  /// **'Connect a password manager'**
  String get connectPasswordManager;

  /// No description provided for @pmWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Whole workspace'**
  String get pmWorkspace;

  /// No description provided for @pmJustMe.
  ///
  /// In en, this message translates to:
  /// **'Just me'**
  String get pmJustMe;

  /// No description provided for @pmNoVaults.
  ///
  /// In en, this message translates to:
  /// **'No vaults chosen yet'**
  String get pmNoVaults;

  /// No description provided for @pmVaults.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 vault} other{{count} vaults}}'**
  String pmVaults(int count);

  /// No description provided for @pmLogins.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 login} other{{count} logins}}'**
  String pmLogins(int count);

  /// No description provided for @pmOnePasswordHelp.
  ///
  /// In en, this message translates to:
  /// **'Uses a 1Password Connect server with a service account\'s token.'**
  String get pmOnePasswordHelp;

  /// No description provided for @pmBitwardenHelp.
  ///
  /// In en, this message translates to:
  /// **'Uses Bitwarden\'s Vault Management API (bw serve) for your organization\'s collections.'**
  String get pmBitwardenHelp;

  /// No description provided for @pmConnectUrl.
  ///
  /// In en, this message translates to:
  /// **'Connect server address'**
  String get pmConnectUrl;

  /// No description provided for @pmConnectToken.
  ///
  /// In en, this message translates to:
  /// **'Connect token'**
  String get pmConnectToken;

  /// No description provided for @pmBwUrl.
  ///
  /// In en, this message translates to:
  /// **'bw serve address'**
  String get pmBwUrl;

  /// No description provided for @pmBwToken.
  ///
  /// In en, this message translates to:
  /// **'Access token (optional)'**
  String get pmBwToken;

  /// No description provided for @pmForWorkspace.
  ///
  /// In en, this message translates to:
  /// **'For the Whole Workspace'**
  String get pmForWorkspace;

  /// No description provided for @pmChooseVaults.
  ///
  /// In en, this message translates to:
  /// **'Vaults Bots May Use'**
  String get pmChooseVaults;

  /// No description provided for @pmChooseVaultsHelp.
  ///
  /// In en, this message translates to:
  /// **'Only logins in the vaults or collections you tick are available to bots.'**
  String get pmChooseVaultsHelp;

  /// No description provided for @welcomeGettingReady.
  ///
  /// In en, this message translates to:
  /// **'Getting your space ready…'**
  String get welcomeGettingReady;

  /// No description provided for @setUpManually.
  ///
  /// In en, this message translates to:
  /// **'Set Up Manually'**
  String get setUpManually;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @inviteLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Invite link copied. Send it to the people you work with.'**
  String get inviteLinkCopied;

  /// No description provided for @inviteFriends.
  ///
  /// In en, this message translates to:
  /// **'Invite Friends'**
  String get inviteFriends;

  /// No description provided for @inviteFriendsRow.
  ///
  /// In en, this message translates to:
  /// **'Earn {amount} of free usage for each friend who joins'**
  String inviteFriendsRow(String amount);

  /// No description provided for @inviteFriendsRowPlain.
  ///
  /// In en, this message translates to:
  /// **'Share Casama with your friends'**
  String get inviteFriendsRowPlain;

  /// No description provided for @inviteFriendsHeadline.
  ///
  /// In en, this message translates to:
  /// **'Give Casama, Get {amount}'**
  String inviteFriendsHeadline(String amount);

  /// No description provided for @inviteFriendsHeadlinePlain.
  ///
  /// In en, this message translates to:
  /// **'Share Casama with Friends'**
  String get inviteFriendsHeadlinePlain;

  /// No description provided for @inviteFriendsHelp.
  ///
  /// In en, this message translates to:
  /// **'Send your link to a friend. When they sign up and finish their first chat, you get {amount} of free usage.'**
  String inviteFriendsHelp(String amount);

  /// No description provided for @inviteFriendsHelpPlain.
  ///
  /// In en, this message translates to:
  /// **'Send your link to a friend. They can sign up straight away.'**
  String get inviteFriendsHelpPlain;

  /// No description provided for @inviteFriendsYourCode.
  ///
  /// In en, this message translates to:
  /// **'Your invite code. Tap to copy.'**
  String get inviteFriendsYourCode;

  /// No description provided for @inviteFriendsShare.
  ///
  /// In en, this message translates to:
  /// **'Share Link'**
  String get inviteFriendsShare;

  /// No description provided for @inviteFriendsCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy Link'**
  String get inviteFriendsCopyLink;

  /// No description provided for @inviteFriendsCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied. Send it to a friend.'**
  String get inviteFriendsCopied;

  /// No description provided for @inviteFriendsShareText.
  ///
  /// In en, this message translates to:
  /// **'Join me on Casama, where AI teammates get things done for you: {link} (invite code {code})'**
  String inviteFriendsShareText(String link, String code);

  /// No description provided for @inviteFriendsProgress.
  ///
  /// In en, this message translates to:
  /// **'Your Invites'**
  String get inviteFriendsProgress;

  /// No description provided for @inviteFriendsJoined.
  ///
  /// In en, this message translates to:
  /// **'Friends Who Joined'**
  String get inviteFriendsJoined;

  /// No description provided for @inviteFriendsPending.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hasn\'t finished a first chat yet} other{{count} haven\'t finished a first chat yet}}'**
  String inviteFriendsPending(int count);

  /// No description provided for @inviteFriendsEarned.
  ///
  /// In en, this message translates to:
  /// **'Free Usage Earned'**
  String get inviteFriendsEarned;

  /// No description provided for @inviteFriendsLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 more friend can earn you a reward} other{{count} more friends can earn you a reward}}'**
  String inviteFriendsLeft(int count);

  /// No description provided for @inviteFriendsCapReached.
  ///
  /// In en, this message translates to:
  /// **'You\'ve earned the most invites can give. Thank you!'**
  String get inviteFriendsCapReached;

  /// No description provided for @inviteFriendsHow.
  ///
  /// In en, this message translates to:
  /// **'How It Works'**
  String get inviteFriendsHow;

  /// No description provided for @inviteFriendsStep1.
  ///
  /// In en, this message translates to:
  /// **'Share your link or code with a friend'**
  String get inviteFriendsStep1;

  /// No description provided for @inviteFriendsStep2.
  ///
  /// In en, this message translates to:
  /// **'They sign up and enter your code within a week'**
  String get inviteFriendsStep2;

  /// No description provided for @inviteFriendsStep3.
  ///
  /// In en, this message translates to:
  /// **'When they finish their first chat, you get {amount} of free usage'**
  String inviteFriendsStep3(String amount);

  /// No description provided for @inviteFriendsStep3Plain.
  ///
  /// In en, this message translates to:
  /// **'They get going with their own AI teammates'**
  String get inviteFriendsStep3Plain;

  /// No description provided for @inviteFriendsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Invites aren\'t available on this server.'**
  String get inviteFriendsUnavailable;

  /// No description provided for @referralHaveCode.
  ///
  /// In en, this message translates to:
  /// **'Got a Friend\'s Code?'**
  String get referralHaveCode;

  /// No description provided for @referralCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Invite code'**
  String get referralCodeHint;

  /// No description provided for @referralUse.
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get referralUse;

  /// No description provided for @referralRedeemed.
  ///
  /// In en, this message translates to:
  /// **'Invite code added. Welcome to Casama!'**
  String get referralRedeemed;

  /// No description provided for @referralRedeemedFrom.
  ///
  /// In en, this message translates to:
  /// **'You joined through {name}\'s invite. Welcome to Casama!'**
  String referralRedeemedFrom(String name);

  /// No description provided for @referralJoinedThrough.
  ///
  /// In en, this message translates to:
  /// **'You joined through {name}\'s invite.'**
  String referralJoinedThrough(String name);

  /// No description provided for @referralJoinedThroughFriend.
  ///
  /// In en, this message translates to:
  /// **'You joined through a friend\'s invite.'**
  String get referralJoinedThroughFriend;

  /// No description provided for @referralInvitedBy.
  ///
  /// In en, this message translates to:
  /// **'{name} invited you'**
  String referralInvitedBy(String name);

  /// No description provided for @referralInvitedByFriend.
  ///
  /// In en, this message translates to:
  /// **'A friend invited you'**
  String get referralInvitedByFriend;

  /// No description provided for @referralWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Casama'**
  String get referralWelcomeTitle;

  /// No description provided for @referralWelcomeHelp.
  ///
  /// In en, this message translates to:
  /// **'AI teammates that work for you on their own computers. Accept the invite so your friend gets the credit.'**
  String get referralWelcomeHelp;

  /// No description provided for @referralAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept Invite'**
  String get referralAccept;

  /// No description provided for @referralGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get referralGetStarted;

  /// No description provided for @referralInvalid.
  ///
  /// In en, this message translates to:
  /// **'This Invite Doesn\'t Work'**
  String get referralInvalid;

  /// No description provided for @referralInvalidHelp.
  ///
  /// In en, this message translates to:
  /// **'The code may be mistyped. You can still sign up and use Casama.'**
  String get referralInvalidHelp;

  /// No description provided for @inviteFriendsHeadlineBoth.
  ///
  /// In en, this message translates to:
  /// **'Give {amount}, Get {amount}'**
  String inviteFriendsHeadlineBoth(String amount);

  /// No description provided for @inviteFriendsHelpBoth.
  ///
  /// In en, this message translates to:
  /// **'Send your link to a friend. When they sign up with your code and finish their first chat, you each get {amount} of free usage.'**
  String inviteFriendsHelpBoth(String amount);

  /// No description provided for @inviteFriendsHelpTwo.
  ///
  /// In en, this message translates to:
  /// **'Send your link to a friend. When they sign up with your code and finish their first chat, you get {reward} of free usage and they get {welcome}.'**
  String inviteFriendsHelpTwo(String reward, String welcome);

  /// No description provided for @inviteFriendsStep3Both.
  ///
  /// In en, this message translates to:
  /// **'When they finish their first chat, you each get {amount} of free usage'**
  String inviteFriendsStep3Both(String amount);

  /// No description provided for @inviteFriendsStep3Two.
  ///
  /// In en, this message translates to:
  /// **'When they finish their first chat, you get {reward} and they get {welcome}'**
  String inviteFriendsStep3Two(String reward, String welcome);

  /// No description provided for @inviteFriendsShareTextBonus.
  ///
  /// In en, this message translates to:
  /// **'Join me on Casama, where AI teammates get things done for you. Sign up with my invite code {code} and you get {amount} of free usage: {link}'**
  String inviteFriendsShareTextBonus(String link, String code, String amount);

  /// No description provided for @referralHaveCodeHelp.
  ///
  /// In en, this message translates to:
  /// **'Enter it within a week of signing up and get {amount} of free usage after your first chat.'**
  String referralHaveCodeHelp(String amount);

  /// No description provided for @referralWelcomeEarned.
  ///
  /// In en, this message translates to:
  /// **'Your {amount} welcome bonus is in your workspace.'**
  String referralWelcomeEarned(String amount);

  /// No description provided for @referralWelcomePending.
  ///
  /// In en, this message translates to:
  /// **'Your {amount} welcome bonus arrives after your first chat.'**
  String referralWelcomePending(String amount);

  /// No description provided for @referralWelcomeHelpBonus.
  ///
  /// In en, this message translates to:
  /// **'AI teammates that work for you on their own computers. Accept the invite and get {amount} of free usage after your first chat.'**
  String referralWelcomeHelpBonus(String amount);

  /// No description provided for @referralRedeemedBonus.
  ///
  /// In en, this message translates to:
  /// **'You\'re in! Your {amount} welcome bonus arrives after your first chat.'**
  String referralRedeemedBonus(String amount);

  /// No description provided for @connectManaged.
  ///
  /// In en, this message translates to:
  /// **'Sign in through Composio'**
  String get connectManaged;

  /// No description provided for @connectManagedHelp.
  ///
  /// In en, this message translates to:
  /// **'Casama connects {app} through Composio, which handles the sign-in. You can disconnect any time.'**
  String connectManagedHelp(String app);

  /// No description provided for @sharing.
  ///
  /// In en, this message translates to:
  /// **'Sharing'**
  String get sharing;

  /// No description provided for @sharingRow.
  ///
  /// In en, this message translates to:
  /// **'Who can chat with, edit or manage it'**
  String get sharingRow;

  /// No description provided for @sharingHelp.
  ///
  /// In en, this message translates to:
  /// **'Everyone in the workspace can chat with a bot unless you make it private. People you add can chat, edit its settings, or also manage who has access. A bot working for someone only uses their own personal computer and connections.'**
  String get sharingHelp;

  /// No description provided for @sharingPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get sharingPrivate;

  /// No description provided for @sharingPrivateOn.
  ///
  /// In en, this message translates to:
  /// **'Only you and the people below can see it'**
  String get sharingPrivateOn;

  /// No description provided for @sharingPrivateOff.
  ///
  /// In en, this message translates to:
  /// **'Everyone in the workspace can chat with it'**
  String get sharingPrivateOff;

  /// No description provided for @sharingPeople.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get sharingPeople;

  /// No description provided for @sharingOnlyCreator.
  ///
  /// In en, this message translates to:
  /// **'Only Its Creator'**
  String get sharingOnlyCreator;

  /// No description provided for @sharingEveryoneChats.
  ///
  /// In en, this message translates to:
  /// **'Everyone can chat; add people who should edit it'**
  String get sharingEveryoneChats;

  /// No description provided for @sharingEveryoneRole.
  ///
  /// In en, this message translates to:
  /// **'Everyone Who Is {role}'**
  String sharingEveryoneRole(String role);

  /// No description provided for @accessChat.
  ///
  /// In en, this message translates to:
  /// **'Can chat'**
  String get accessChat;

  /// No description provided for @accessEdit.
  ///
  /// In en, this message translates to:
  /// **'Can edit'**
  String get accessEdit;

  /// No description provided for @accessAdmin.
  ///
  /// In en, this message translates to:
  /// **'Can manage'**
  String get accessAdmin;

  /// No description provided for @sharingSaved.
  ///
  /// In en, this message translates to:
  /// **'Sharing saved'**
  String get sharingSaved;

  /// No description provided for @triggerCalendar.
  ///
  /// In en, this message translates to:
  /// **'Meetings'**
  String get triggerCalendar;

  /// No description provided for @routineCalendar.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =0{At the start of matching meetings} other{Around matching meetings ({minutes} min)}}'**
  String routineCalendar(int minutes);

  /// No description provided for @calendarTriggerNeedsCalendar.
  ///
  /// In en, this message translates to:
  /// **'Connect Google Calendar or Outlook first.'**
  String get calendarTriggerNeedsCalendar;

  /// No description provided for @calendarTriggerCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendarTriggerCalendar;

  /// No description provided for @calendarOffset.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =0{At start} other{{minutes} min}}'**
  String calendarOffset(int minutes);

  /// No description provided for @calendarOutsideGuests.
  ///
  /// In en, this message translates to:
  /// **'Only meetings with people outside my company'**
  String get calendarOutsideGuests;

  /// No description provided for @calendarVideoLink.
  ///
  /// In en, this message translates to:
  /// **'Only meetings with a video link'**
  String get calendarVideoLink;

  /// No description provided for @calendarTitleMatch.
  ///
  /// In en, this message translates to:
  /// **'Only titles containing (optional)'**
  String get calendarTitleMatch;

  /// No description provided for @fullAccess.
  ///
  /// In en, this message translates to:
  /// **'Full access'**
  String get fullAccess;

  /// No description provided for @fullAccessHelp.
  ///
  /// In en, this message translates to:
  /// **'Bots act without asking first, on their computers and on your Mac. Payments, password changes and your own \"ask\" rules still ask.'**
  String get fullAccessHelp;

  /// No description provided for @fullAccessConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Turn on full access?'**
  String get fullAccessConfirmTitle;

  /// No description provided for @fullAccessConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Every bot in this workspace will send messages, delete files, run commands on your Mac and add connections without asking you first. Payments and password changes still ask.'**
  String get fullAccessConfirmBody;

  /// No description provided for @fullAccessTurnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get fullAccessTurnOn;

  /// No description provided for @botToBot.
  ///
  /// In en, this message translates to:
  /// **'Bots can talk to each other'**
  String get botToBot;

  /// No description provided for @botToBotHelp.
  ///
  /// In en, this message translates to:
  /// **'Bots can @mention, message and hand work to each other.'**
  String get botToBotHelp;

  /// No description provided for @capMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages (iMessage)'**
  String get capMessages;

  /// No description provided for @chatApps.
  ///
  /// In en, this message translates to:
  /// **'Chat apps'**
  String get chatApps;

  /// No description provided for @chatAppsRow.
  ///
  /// In en, this message translates to:
  /// **'Telegram, email, SMS, Slack, WhatsApp and more'**
  String get chatAppsRow;

  /// No description provided for @botEmail.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get botEmail;

  /// No description provided for @botEmailRow.
  ///
  /// In en, this message translates to:
  /// **'Give this bot its own address'**
  String get botEmailRow;

  /// No description provided for @botEmailClaimTitle.
  ///
  /// In en, this message translates to:
  /// **'Give {name} an email address'**
  String botEmailClaimTitle(String name);

  /// No description provided for @botEmailClaimHelp.
  ///
  /// In en, this message translates to:
  /// **'People can write to it, and it answers by email. Forward it anything: bills, bookings, newsletters.'**
  String get botEmailClaimHelp;

  /// No description provided for @botEmailNameHint.
  ///
  /// In en, this message translates to:
  /// **'ada'**
  String get botEmailNameHint;

  /// No description provided for @botEmailNameFixed.
  ///
  /// In en, this message translates to:
  /// **'The name can\'t be changed later.'**
  String get botEmailNameFixed;

  /// No description provided for @botEmailClaim.
  ///
  /// In en, this message translates to:
  /// **'Create address'**
  String get botEmailClaim;

  /// No description provided for @botEmailTaken.
  ///
  /// In en, this message translates to:
  /// **'That name is taken. Try one of these:'**
  String get botEmailTaken;

  /// No description provided for @botEmailClaimed.
  ///
  /// In en, this message translates to:
  /// **'Your bot has an address'**
  String get botEmailClaimed;

  /// No description provided for @botEmailClaimedHelp.
  ///
  /// In en, this message translates to:
  /// **'A welcome mail is on its way to you. Reply to it, or forward anything.'**
  String get botEmailClaimedHelp;

  /// No description provided for @botEmailCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get botEmailCopy;

  /// No description provided for @botEmailCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get botEmailCopied;

  /// No description provided for @botEmailContacts.
  ///
  /// In en, this message translates to:
  /// **'Add to contacts'**
  String get botEmailContacts;

  /// No description provided for @botEmailWrite.
  ///
  /// In en, this message translates to:
  /// **'Write to {name}'**
  String botEmailWrite(String name);

  /// No description provided for @botEmailPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused. It still receives and keeps mail, but answers nothing.'**
  String get botEmailPaused;

  /// No description provided for @botEmailPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get botEmailPause;

  /// No description provided for @botEmailResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get botEmailResume;

  /// No description provided for @botEmailSenders.
  ///
  /// In en, this message translates to:
  /// **'Allowed senders'**
  String get botEmailSenders;

  /// No description provided for @botEmailSendersHelp.
  ///
  /// In en, this message translates to:
  /// **'Only these people get answers. Strangers\' mail is kept, and starts nothing.'**
  String get botEmailSendersHelp;

  /// No description provided for @botEmailEditSenders.
  ///
  /// In en, this message translates to:
  /// **'Edit in Chat apps'**
  String get botEmailEditSenders;

  /// No description provided for @botEmailMove.
  ///
  /// In en, this message translates to:
  /// **'Move to another bot'**
  String get botEmailMove;

  /// No description provided for @botEmailMoveHelp.
  ///
  /// In en, this message translates to:
  /// **'The address and its mail move to the other bot.'**
  String get botEmailMoveHelp;

  /// No description provided for @botEmailRelease.
  ///
  /// In en, this message translates to:
  /// **'Release address'**
  String get botEmailRelease;

  /// No description provided for @botEmailReleaseHelp.
  ///
  /// In en, this message translates to:
  /// **'Stops receiving for good. The name is never given out again.'**
  String get botEmailReleaseHelp;

  /// No description provided for @botEmailReleaseConfirm.
  ///
  /// In en, this message translates to:
  /// **'Release {address}? It stops receiving at once, and the name is never given out again.'**
  String botEmailReleaseConfirm(String address);

  /// No description provided for @botEmailReleaseNow.
  ///
  /// In en, this message translates to:
  /// **'Release'**
  String get botEmailReleaseNow;

  /// No description provided for @botEmailMoved.
  ///
  /// In en, this message translates to:
  /// **'Moved'**
  String get botEmailMoved;

  /// No description provided for @botEmailNewBotRow.
  ///
  /// In en, this message translates to:
  /// **'Give {name} an email address'**
  String botEmailNewBotRow(String name);

  /// No description provided for @botEmailInbox.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get botEmailInbox;

  /// No description provided for @botEmailInboxRow.
  ///
  /// In en, this message translates to:
  /// **'Kept mail, strangers and files'**
  String get botEmailInboxRow;

  /// No description provided for @botEmailEmpty.
  ///
  /// In en, this message translates to:
  /// **'No mail yet'**
  String get botEmailEmpty;

  /// No description provided for @botEmailStrangers.
  ///
  /// In en, this message translates to:
  /// **'Strangers'**
  String get botEmailStrangers;

  /// No description provided for @botEmailAll.
  ///
  /// In en, this message translates to:
  /// **'All mail'**
  String get botEmailAll;

  /// No description provided for @botEmailUnconfirmed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t confirm this sender'**
  String get botEmailUnconfirmed;

  /// No description provided for @botEmailAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get botEmailAllow;

  /// No description provided for @botEmailBlock.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get botEmailBlock;

  /// No description provided for @botEmailBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked. New mail from here is refused.'**
  String get botEmailBlocked;

  /// No description provided for @botEmailUnblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get botEmailUnblock;

  /// No description provided for @botEmailOpenChat.
  ///
  /// In en, this message translates to:
  /// **'Open chat'**
  String get botEmailOpenChat;

  /// No description provided for @botEmailFiles.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get botEmailFiles;

  /// No description provided for @botEmailNewSenders.
  ///
  /// In en, this message translates to:
  /// **'Tell me about new senders'**
  String get botEmailNewSenders;

  /// No description provided for @botEmailNewSendersHelp.
  ///
  /// In en, this message translates to:
  /// **'At most once a day. Off unless you turn it on.'**
  String get botEmailNewSendersHelp;

  /// No description provided for @botEmailTryTitle.
  ///
  /// In en, this message translates to:
  /// **'Things to try'**
  String get botEmailTryTitle;

  /// No description provided for @botEmailTryForward.
  ///
  /// In en, this message translates to:
  /// **'Forward a bill or a booking'**
  String get botEmailTryForward;

  /// No description provided for @botEmailTryForwardHelp.
  ///
  /// In en, this message translates to:
  /// **'Forward anything to the address above. It reads it and answers here.'**
  String get botEmailTryForwardHelp;

  /// No description provided for @botEmailTryReceipts.
  ///
  /// In en, this message translates to:
  /// **'Keep my receipts'**
  String get botEmailTryReceipts;

  /// No description provided for @botEmailTryReceiptsHelp.
  ///
  /// In en, this message translates to:
  /// **'Makes a routine that files mail sent to {address}.'**
  String botEmailTryReceiptsHelp(String address);

  /// No description provided for @botEmailTryDigest.
  ///
  /// In en, this message translates to:
  /// **'One digest a week'**
  String get botEmailTryDigest;

  /// No description provided for @botEmailTryDigestHelp.
  ///
  /// In en, this message translates to:
  /// **'Makes a routine that gathers newsletters from {address} into a weekly summary.'**
  String botEmailTryDigestHelp(String address);

  /// No description provided for @botEmailTryCopied.
  ///
  /// In en, this message translates to:
  /// **'Address copied'**
  String get botEmailTryCopied;

  /// No description provided for @botEmailTryMade.
  ///
  /// In en, this message translates to:
  /// **'Routine made'**
  String get botEmailTryMade;

  /// No description provided for @botEmailReceiptsName.
  ///
  /// In en, this message translates to:
  /// **'Keep my receipts'**
  String get botEmailReceiptsName;

  /// No description provided for @botEmailReceiptsInstructions.
  ///
  /// In en, this message translates to:
  /// **'File the receipt from this mail: what it was for, how much, and when. Say nothing unless something looks wrong.'**
  String get botEmailReceiptsInstructions;

  /// No description provided for @botEmailDigestName.
  ///
  /// In en, this message translates to:
  /// **'Weekly newsletter digest'**
  String get botEmailDigestName;

  /// No description provided for @botEmailDigestInstructions.
  ///
  /// In en, this message translates to:
  /// **'Collect this week\'s newsletters and send one short digest: the headlines worth knowing, nothing more.'**
  String get botEmailDigestInstructions;

  /// No description provided for @botEmailTriggerTag.
  ///
  /// In en, this message translates to:
  /// **'Plus tag'**
  String get botEmailTriggerTag;

  /// No description provided for @botEmailTriggerTagHelp.
  ///
  /// In en, this message translates to:
  /// **'Only mail to this tag, like shop for ada+shop@. Email addresses only.'**
  String get botEmailTriggerTagHelp;

  /// No description provided for @botEmailTriggerUnconfirmed.
  ///
  /// In en, this message translates to:
  /// **'Hear unconfirmed senders too'**
  String get botEmailTriggerUnconfirmed;

  /// No description provided for @botEmailTriggerAutomatic.
  ///
  /// In en, this message translates to:
  /// **'Hear automatic mail too'**
  String get botEmailTriggerAutomatic;

  /// No description provided for @botEmailStorage.
  ///
  /// In en, this message translates to:
  /// **'{used} of {limit}'**
  String botEmailStorage(String used, String limit);

  /// No description provided for @botEmailStorageUsed.
  ///
  /// In en, this message translates to:
  /// **'{used} used'**
  String botEmailStorageUsed(String used);

  /// No description provided for @botEmailStorageFull.
  ///
  /// In en, this message translates to:
  /// **'The mailbox is full, so new mail is refused. Delete old mail to make room.'**
  String get botEmailStorageFull;

  /// No description provided for @botEmailSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get botEmailSelect;

  /// No description provided for @botEmailSelectDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get botEmailSelectDone;

  /// No description provided for @botEmailDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get botEmailDelete;

  /// No description provided for @botEmailDeleteCount.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Delete 1 mail} other{Delete {n} mails}}'**
  String botEmailDeleteCount(int n);

  /// No description provided for @botEmailDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Delete this mail?} other{Delete {n} mails?}}'**
  String botEmailDeleteTitle(int n);

  /// No description provided for @botEmailDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Their text and files are gone for good. Copies already in a chat stay there.'**
  String get botEmailDeleteBody;

  /// No description provided for @botEmailDeleteOlder.
  ///
  /// In en, this message translates to:
  /// **'Delete older mail'**
  String get botEmailDeleteOlder;

  /// No description provided for @botEmailOlder30Days.
  ///
  /// In en, this message translates to:
  /// **'Older than 30 days'**
  String get botEmailOlder30Days;

  /// No description provided for @botEmailOlder6Months.
  ///
  /// In en, this message translates to:
  /// **'Older than 6 months'**
  String get botEmailOlder6Months;

  /// No description provided for @botEmailOlderYear.
  ///
  /// In en, this message translates to:
  /// **'Older than a year'**
  String get botEmailOlderYear;

  /// No description provided for @botEmailDeleteOlderTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete all mail {age}?'**
  String botEmailDeleteOlderTitle(String age);

  /// No description provided for @botEmailDeleted.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{Nothing to delete} =1{Deleted 1 mail} other{Deleted {n} mails}}'**
  String botEmailDeleted(int n);

  /// No description provided for @botEmailPerkAddresses.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 bot email address} other{{n} bot email addresses}}'**
  String botEmailPerkAddresses(int n);

  /// No description provided for @botEmailPerkWritesNew.
  ///
  /// In en, this message translates to:
  /// **'Bots write to new people by email'**
  String get botEmailPerkWritesNew;

  /// No description provided for @botEmailPerkRepliesOnly.
  ///
  /// In en, this message translates to:
  /// **'Bots reply to you by email'**
  String get botEmailPerkRepliesOnly;

  /// No description provided for @adminMailSentToday.
  ///
  /// In en, this message translates to:
  /// **'Sent today: {sent} of {ceiling}'**
  String adminMailSentToday(int sent, int ceiling);

  /// No description provided for @adminMailSentTodayNoCeiling.
  ///
  /// In en, this message translates to:
  /// **'Sent today: {sent}'**
  String adminMailSentTodayNoCeiling(int sent);

  /// No description provided for @chatAppsAdd.
  ///
  /// In en, this message translates to:
  /// **'Connect a chat app'**
  String get chatAppsAdd;

  /// No description provided for @chatAppsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No chat apps yet'**
  String get chatAppsEmpty;

  /// No description provided for @chatAppsHelp.
  ///
  /// In en, this message translates to:
  /// **'Let people message this bot from Telegram, email, SMS, Slack, WhatsApp, Messenger, Feishu or iMessage. It only answers people on the allowed list; everyone else is logged here.'**
  String get chatAppsHelp;

  /// No description provided for @chatAppsAddHelp.
  ///
  /// In en, this message translates to:
  /// **'Paste the credentials from the app\'s developer settings. They\'re stored encrypted and never shown again.'**
  String get chatAppsAddHelp;

  /// No description provided for @chatAppsKind.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get chatAppsKind;

  /// No description provided for @chatAppsSenders.
  ///
  /// In en, this message translates to:
  /// **'Allowed senders'**
  String get chatAppsSenders;

  /// No description provided for @chatAppsSendersHelp.
  ///
  /// In en, this message translates to:
  /// **'One per line: email addresses (or *@company.com), phone numbers, or user ids. Not sure of an id? Leave it empty, message the bot, and copy the id from Activity.'**
  String get chatAppsSendersHelp;

  /// No description provided for @chatAppsMac.
  ///
  /// In en, this message translates to:
  /// **'Mac'**
  String get chatAppsMac;

  /// No description provided for @chatAppsNoMac.
  ///
  /// In en, this message translates to:
  /// **'Turn on \"Use this computer for bots\" with Messages allowed in the desktop app on your Mac first.'**
  String get chatAppsNoMac;

  /// No description provided for @chatAppsConnected.
  ///
  /// In en, this message translates to:
  /// **'{name} is connected'**
  String chatAppsConnected(String name);

  /// No description provided for @chatAppsTelegramDone.
  ///
  /// In en, this message translates to:
  /// **'Telegram is already sending messages here. Message your bot to try it.'**
  String get chatAppsTelegramDone;

  /// No description provided for @chatAppsPasteUrl.
  ///
  /// In en, this message translates to:
  /// **'Paste this address into the app\'s webhook settings.'**
  String get chatAppsPasteUrl;

  /// No description provided for @chatAppsWebhookUrl.
  ///
  /// In en, this message translates to:
  /// **'Webhook address'**
  String get chatAppsWebhookUrl;

  /// No description provided for @chatAppsVerifyToken.
  ///
  /// In en, this message translates to:
  /// **'Verify token'**
  String get chatAppsVerifyToken;

  /// No description provided for @chatAppsAllowed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nobody allowed} =1{1 allowed sender} other{{count} allowed senders}}'**
  String chatAppsAllowed(int count);

  /// No description provided for @chatAppsActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get chatAppsActivity;

  /// No description provided for @chatAppsNoActivity.
  ///
  /// In en, this message translates to:
  /// **'No messages yet.'**
  String get chatAppsNoActivity;

  /// No description provided for @chatAppsIgnored.
  ///
  /// In en, this message translates to:
  /// **'Ignored: not on the allowed list'**
  String get chatAppsIgnored;

  /// No description provided for @chatAppsAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get chatAppsAllow;

  /// No description provided for @chatAppsSenderAllowed.
  ///
  /// In en, this message translates to:
  /// **'{sender} can now message this bot'**
  String chatAppsSenderAllowed(String sender);

  /// No description provided for @chatAppsRoutine.
  ///
  /// In en, this message translates to:
  /// **'Started a routine'**
  String get chatAppsRoutine;

  /// No description provided for @chatAppsFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send'**
  String get chatAppsFailed;

  /// No description provided for @chatAppsSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get chatAppsSent;

  /// No description provided for @chatAppsAnswered.
  ///
  /// In en, this message translates to:
  /// **'Answered'**
  String get chatAppsAnswered;

  /// No description provided for @chatAppsRemove.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get chatAppsRemove;

  /// No description provided for @chBotToken.
  ///
  /// In en, this message translates to:
  /// **'Bot token'**
  String get chBotToken;

  /// No description provided for @chAddress.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get chAddress;

  /// No description provided for @chApiKey.
  ///
  /// In en, this message translates to:
  /// **'API key'**
  String get chApiKey;

  /// No description provided for @chSigningSecret.
  ///
  /// In en, this message translates to:
  /// **'Signing secret'**
  String get chSigningSecret;

  /// No description provided for @chPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get chPhoneNumber;

  /// No description provided for @chAccountSid.
  ///
  /// In en, this message translates to:
  /// **'Account SID'**
  String get chAccountSid;

  /// No description provided for @chAuthToken.
  ///
  /// In en, this message translates to:
  /// **'Auth token'**
  String get chAuthToken;

  /// No description provided for @chPhoneNumberId.
  ///
  /// In en, this message translates to:
  /// **'Phone number ID'**
  String get chPhoneNumberId;

  /// No description provided for @chAccessToken.
  ///
  /// In en, this message translates to:
  /// **'Access token'**
  String get chAccessToken;

  /// No description provided for @chAppSecret.
  ///
  /// In en, this message translates to:
  /// **'App secret'**
  String get chAppSecret;

  /// No description provided for @chPageToken.
  ///
  /// In en, this message translates to:
  /// **'Page access token'**
  String get chPageToken;

  /// No description provided for @chAppId.
  ///
  /// In en, this message translates to:
  /// **'App ID'**
  String get chAppId;

  /// No description provided for @chEncryptKey.
  ///
  /// In en, this message translates to:
  /// **'Encrypt key'**
  String get chEncryptKey;

  /// No description provided for @chVerificationToken.
  ///
  /// In en, this message translates to:
  /// **'Verification token'**
  String get chVerificationToken;

  /// No description provided for @chPublicKey.
  ///
  /// In en, this message translates to:
  /// **'Public key'**
  String get chPublicKey;

  /// No description provided for @chTrackerUser.
  ///
  /// In en, this message translates to:
  /// **'The bot\'s user ID in the tracker'**
  String get chTrackerUser;

  /// No description provided for @chSiteUrl.
  ///
  /// In en, this message translates to:
  /// **'Site address (https://…)'**
  String get chSiteUrl;

  /// No description provided for @chAccountEmail.
  ///
  /// In en, this message translates to:
  /// **'Account email'**
  String get chAccountEmail;

  /// No description provided for @routineMessage.
  ///
  /// In en, this message translates to:
  /// **'When a matching message arrives'**
  String get routineMessage;

  /// No description provided for @triggerMessage.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get triggerMessage;

  /// No description provided for @messageTriggerHelp.
  ///
  /// In en, this message translates to:
  /// **'Starts when an email or chat message to this bot matches. Connect the app under Chat apps first.'**
  String get messageTriggerHelp;

  /// No description provided for @messageTriggerAnyApp.
  ///
  /// In en, this message translates to:
  /// **'Any app'**
  String get messageTriggerAnyApp;

  /// No description provided for @messageTriggerSender.
  ///
  /// In en, this message translates to:
  /// **'From (address, number, or *@company.com)'**
  String get messageTriggerSender;

  /// No description provided for @messageTriggerSubject.
  ///
  /// In en, this message translates to:
  /// **'Subject contains'**
  String get messageTriggerSubject;

  /// No description provided for @messageTriggerWords.
  ///
  /// In en, this message translates to:
  /// **'Message contains'**
  String get messageTriggerWords;

  /// No description provided for @callIncoming.
  ///
  /// In en, this message translates to:
  /// **'{name} is calling'**
  String callIncoming(String name);

  /// No description provided for @callAnswer.
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get callAnswer;

  /// No description provided for @callDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get callDecline;

  /// No description provided for @callFullScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Calls on the Lock Screen'**
  String get callFullScreenTitle;

  /// No description provided for @callFullScreenOff.
  ///
  /// In en, this message translates to:
  /// **'Off: a bot\'s call shows only as a notification. Tap to let calls ring on the full screen.'**
  String get callFullScreenOff;

  /// No description provided for @encryption.
  ///
  /// In en, this message translates to:
  /// **'Encrypt Content'**
  String get encryption;

  /// No description provided for @encryptionHelp.
  ///
  /// In en, this message translates to:
  /// **'Messages, memories, tickets, pages and knowledge are encrypted before they\'re stored, with this workspace\'s own key. Search then matches titles and meaning, not exact words in encrypted text.'**
  String get encryptionHelp;

  /// No description provided for @encryptionOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get encryptionOff;

  /// No description provided for @encryptionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Not available: this server has no encryption key set up'**
  String get encryptionUnavailable;

  /// No description provided for @encryptionEncrypting.
  ///
  /// In en, this message translates to:
  /// **'Turning on: encrypting what\'s already stored'**
  String get encryptionEncrypting;

  /// No description provided for @encryptionOnServer.
  ///
  /// In en, this message translates to:
  /// **'On, with the server\'s key'**
  String get encryptionOnServer;

  /// No description provided for @encryptionOnKms.
  ///
  /// In en, this message translates to:
  /// **'On, with AWS KMS'**
  String get encryptionOnKms;

  /// No description provided for @encryptionDecrypting.
  ///
  /// In en, this message translates to:
  /// **'Turning off: decrypting what\'s stored'**
  String get encryptionDecrypting;

  /// No description provided for @encryptionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Content will be encrypted with this workspace\'s key. If the workspace is deleted, its key is destroyed and the content can\'t be recovered. Exact-word search stops matching encrypted text.'**
  String get encryptionConfirm;

  /// No description provided for @encryptionTurnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn On'**
  String get encryptionTurnOn;

  /// No description provided for @encryptionRotate.
  ///
  /// In en, this message translates to:
  /// **'Rotate Key'**
  String get encryptionRotate;

  /// No description provided for @encryptionKeyManaged.
  ///
  /// In en, this message translates to:
  /// **'Casama creates and keeps this workspace\'s key for you, wrapped with the server\'s own key. There\'s nothing to save or copy.'**
  String get encryptionKeyManaged;

  /// No description provided for @encryptionRotateTitle.
  ///
  /// In en, this message translates to:
  /// **'Rotate the key?'**
  String get encryptionRotateTitle;

  /// No description provided for @encryptionRotateBody.
  ///
  /// In en, this message translates to:
  /// **'The workspace key is wrapped again with the server\'s current key. Your content stays readable and nothing needs re-encrypting. Do this after changing the server\'s key, or on a schedule.'**
  String get encryptionRotateBody;

  /// No description provided for @encryptionRotateHelp.
  ///
  /// In en, this message translates to:
  /// **'Rewraps the workspace key with the server\'s current key'**
  String get encryptionRotateHelp;

  /// No description provided for @encryptionRotated.
  ///
  /// In en, this message translates to:
  /// **'Last rotated {date}'**
  String encryptionRotated(String date);

  /// No description provided for @memoryBackend.
  ///
  /// In en, this message translates to:
  /// **'Where Memory Is Kept'**
  String get memoryBackend;

  /// No description provided for @memoryBuiltIn.
  ///
  /// In en, this message translates to:
  /// **'Built in'**
  String get memoryBuiltIn;

  /// No description provided for @memoryBackendHelp.
  ///
  /// In en, this message translates to:
  /// **'Bots\' long-term memory'**
  String get memoryBackendHelp;

  /// No description provided for @memoryBackendSheetHelp.
  ///
  /// In en, this message translates to:
  /// **'Keep your bots\' memory in Honcho or Supermemory with your own account. The memory screen, exports and deletion work the same.'**
  String get memoryBackendSheetHelp;

  /// No description provided for @memoryHonchoWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Honcho workspace'**
  String get memoryHonchoWorkspace;

  /// No description provided for @memoryHonchoWorkspaceHelp.
  ///
  /// In en, this message translates to:
  /// **'Leave empty to use one made for this Casama workspace'**
  String get memoryHonchoWorkspaceHelp;

  /// No description provided for @memoryBaseUrl.
  ///
  /// In en, this message translates to:
  /// **'Server address (optional)'**
  String get memoryBaseUrl;

  /// No description provided for @memoryBaseUrlHelp.
  ///
  /// In en, this message translates to:
  /// **'Only for a self-hosted Honcho or Supermemory'**
  String get memoryBaseUrlHelp;

  /// No description provided for @memoryCopyExisting.
  ///
  /// In en, this message translates to:
  /// **'Copy Current Memories Over'**
  String get memoryCopyExisting;

  /// No description provided for @memoryUseBuiltIn.
  ///
  /// In en, this message translates to:
  /// **'Use Built-in Memory Again'**
  String get memoryUseBuiltIn;

  /// No description provided for @providerHintData.
  ///
  /// In en, this message translates to:
  /// **'paid data (places, emails, SEO)'**
  String get providerHintData;

  /// No description provided for @kindA2a.
  ///
  /// In en, this message translates to:
  /// **'AI agent (A2A)'**
  String get kindA2a;

  /// No description provided for @a2aAgentUrl.
  ///
  /// In en, this message translates to:
  /// **'Agent address or agent card URL'**
  String get a2aAgentUrl;

  /// No description provided for @a2aAgentToken.
  ///
  /// In en, this message translates to:
  /// **'Access token (optional)'**
  String get a2aAgentToken;

  /// No description provided for @a2a.
  ///
  /// In en, this message translates to:
  /// **'Agent-to-Agent (A2A)'**
  String get a2a;

  /// No description provided for @a2aHelp.
  ///
  /// In en, this message translates to:
  /// **'Outside agents can give tasks to bots you publish.'**
  String get a2aHelp;

  /// No description provided for @chromeExtensionSwitch.
  ///
  /// In en, this message translates to:
  /// **'Casama for Chrome'**
  String get chromeExtensionSwitch;

  /// No description provided for @chromeExtensionSwitchHelp.
  ///
  /// In en, this message translates to:
  /// **'Members can use the browser extension with this workspace.'**
  String get chromeExtensionSwitchHelp;

  /// No description provided for @chromeActSwitch.
  ///
  /// In en, this message translates to:
  /// **'Bots in Members\' Browsers'**
  String get chromeActSwitch;

  /// No description provided for @chromeActSwitchHelp.
  ///
  /// In en, this message translates to:
  /// **'Members can let bots open pages and act in their own Chrome, in a tab group they can stop.'**
  String get chromeActSwitchHelp;

  /// No description provided for @a2aPublish.
  ///
  /// In en, this message translates to:
  /// **'Publish as an A2A Agent'**
  String get a2aPublish;

  /// No description provided for @a2aPublishHelp.
  ///
  /// In en, this message translates to:
  /// **'Outside agents with a workspace API key can give this bot tasks.'**
  String get a2aPublishHelp;

  /// No description provided for @a2aWorkspaceOff.
  ///
  /// In en, this message translates to:
  /// **'Turn on agent-to-agent in workspace settings first.'**
  String get a2aWorkspaceOff;

  /// No description provided for @a2aCardUrl.
  ///
  /// In en, this message translates to:
  /// **'Agent card'**
  String get a2aCardUrl;

  /// No description provided for @phoneCalls.
  ///
  /// In en, this message translates to:
  /// **'Phone Calls'**
  String get phoneCalls;

  /// No description provided for @phoneCallsHelp.
  ///
  /// In en, this message translates to:
  /// **'Let bots call businesses for you through your Twilio account. Every call asks first under the usual approvals.'**
  String get phoneCallsHelp;

  /// No description provided for @twilioSid.
  ///
  /// In en, this message translates to:
  /// **'Account SID'**
  String get twilioSid;

  /// No description provided for @twilioToken.
  ///
  /// In en, this message translates to:
  /// **'Auth token'**
  String get twilioToken;

  /// No description provided for @twilioFrom.
  ///
  /// In en, this message translates to:
  /// **'Calls come from'**
  String get twilioFrom;

  /// No description provided for @phoneCallsPersonal.
  ///
  /// In en, this message translates to:
  /// **'Allow Calling Personal Numbers'**
  String get phoneCallsPersonal;

  /// No description provided for @phoneCallsCap.
  ///
  /// In en, this message translates to:
  /// **'Calls per day'**
  String get phoneCallsCap;

  /// No description provided for @phoneCallsOff.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get phoneCallsOff;

  /// No description provided for @outCall.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get outCall;

  /// No description provided for @outCallRinging.
  ///
  /// In en, this message translates to:
  /// **'Ringing…'**
  String get outCallRinging;

  /// No description provided for @outCallLive.
  ///
  /// In en, this message translates to:
  /// **'On the call'**
  String get outCallLive;

  /// No description provided for @outCallEnded.
  ///
  /// In en, this message translates to:
  /// **'Ended after {seconds}s'**
  String outCallEnded(int seconds);

  /// No description provided for @outCallEndedByYou.
  ///
  /// In en, this message translates to:
  /// **'You ended the call'**
  String get outCallEndedByYou;

  /// No description provided for @outCallTakenOver.
  ///
  /// In en, this message translates to:
  /// **'You took over the call'**
  String get outCallTakenOver;

  /// No description provided for @outCallFailed.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t go through'**
  String get outCallFailed;

  /// No description provided for @outCallNothingYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing said yet.'**
  String get outCallNothingYet;

  /// No description provided for @outCallTakeOver.
  ///
  /// In en, this message translates to:
  /// **'Take Over'**
  String get outCallTakeOver;

  /// No description provided for @outCallEnd.
  ///
  /// In en, this message translates to:
  /// **'End Call'**
  String get outCallEnd;

  /// No description provided for @outCallYourPhone.
  ///
  /// In en, this message translates to:
  /// **'Your phone number'**
  String get outCallYourPhone;

  /// No description provided for @outCallYourPhoneHelp.
  ///
  /// In en, this message translates to:
  /// **'International format, like +14155550123. Leave empty to use the one saved.'**
  String get outCallYourPhoneHelp;

  /// No description provided for @payments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get payments;

  /// No description provided for @paymentsHelp.
  ///
  /// In en, this message translates to:
  /// **'Let bots pay merchants with single-use virtual cards you approve each time. Bring your own Stripe Issuing account.'**
  String get paymentsHelp;

  /// No description provided for @paymentsOn.
  ///
  /// In en, this message translates to:
  /// **'{spent} spent this month of {cap}'**
  String paymentsOn(String spent, String cap);

  /// No description provided for @paymentsSheetHelp.
  ///
  /// In en, this message translates to:
  /// **'Every card is approved by you with the amount shown, works once at that merchant for one hour, and never for securities, crypto, gift cards or transfers.'**
  String get paymentsSheetHelp;

  /// No description provided for @paymentsStripeKey.
  ///
  /// In en, this message translates to:
  /// **'Stripe secret key (with Issuing)'**
  String get paymentsStripeKey;

  /// No description provided for @paymentsWebhookSecret.
  ///
  /// In en, this message translates to:
  /// **'Webhook signing secret'**
  String get paymentsWebhookSecret;

  /// No description provided for @paymentsWebhook.
  ///
  /// In en, this message translates to:
  /// **'Point a Stripe webhook here'**
  String get paymentsWebhook;

  /// No description provided for @paymentsCardholder.
  ///
  /// In en, this message translates to:
  /// **'Name on cards'**
  String get paymentsCardholder;

  /// No description provided for @paymentsAddress.
  ///
  /// In en, this message translates to:
  /// **'Billing address'**
  String get paymentsAddress;

  /// No description provided for @paymentsCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get paymentsCity;

  /// No description provided for @paymentsState.
  ///
  /// In en, this message translates to:
  /// **'State or region'**
  String get paymentsState;

  /// No description provided for @paymentsZip.
  ///
  /// In en, this message translates to:
  /// **'Postal code'**
  String get paymentsZip;

  /// No description provided for @paymentsCountry.
  ///
  /// In en, this message translates to:
  /// **'Country (2 letters)'**
  String get paymentsCountry;

  /// No description provided for @paymentsCap.
  ///
  /// In en, this message translates to:
  /// **'Workspace limit per month (USD)'**
  String get paymentsCap;

  /// No description provided for @paymentsBotCap.
  ///
  /// In en, this message translates to:
  /// **'Per-bot limit per month (USD)'**
  String get paymentsBotCap;

  /// No description provided for @links.
  ///
  /// In en, this message translates to:
  /// **'Linked bots'**
  String get links;

  /// No description provided for @linksRow.
  ///
  /// In en, this message translates to:
  /// **'Link with a trusted contact\'s bot'**
  String get linksRow;

  /// No description provided for @linksHelp.
  ///
  /// In en, this message translates to:
  /// **'Your bot can ask a linked contact\'s bot for things like a dinner slot. Each bot answers under its own person\'s rules and shares only what\'s needed; both of you see every exchange.'**
  String get linksHelp;

  /// No description provided for @linksEmpty.
  ///
  /// In en, this message translates to:
  /// **'No linked bots yet'**
  String get linksEmpty;

  /// No description provided for @linksInvite.
  ///
  /// In en, this message translates to:
  /// **'Invite a contact'**
  String get linksInvite;

  /// No description provided for @linksContactName.
  ///
  /// In en, this message translates to:
  /// **'Contact\'s name'**
  String get linksContactName;

  /// No description provided for @linksInviteReady.
  ///
  /// In en, this message translates to:
  /// **'Send This Invite'**
  String get linksInviteReady;

  /// No description provided for @linksInviteHelp.
  ///
  /// In en, this message translates to:
  /// **'Send it to your contact. They accept it in Casama with one of their bots. It works once, for 7 days.'**
  String get linksInviteHelp;

  /// No description provided for @linksAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept an invite'**
  String get linksAccept;

  /// No description provided for @linksAcceptHelp.
  ///
  /// In en, this message translates to:
  /// **'Paste the invite your contact sent you.'**
  String get linksAcceptHelp;

  /// No description provided for @linksInviteText.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get linksInviteText;

  /// No description provided for @linksActive.
  ///
  /// In en, this message translates to:
  /// **'Linked with {bot}'**
  String linksActive(String bot);

  /// No description provided for @linksPending.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your contact to accept'**
  String get linksPending;

  /// No description provided for @linksRevoked.
  ///
  /// In en, this message translates to:
  /// **'Unlinked'**
  String get linksRevoked;

  /// No description provided for @linksExchanges.
  ///
  /// In en, this message translates to:
  /// **'Exchanges'**
  String get linksExchanges;

  /// No description provided for @linksNoExchanges.
  ///
  /// In en, this message translates to:
  /// **'Nothing asked yet.'**
  String get linksNoExchanges;

  /// No description provided for @linksNoAnswer.
  ///
  /// In en, this message translates to:
  /// **'No answer'**
  String get linksNoAnswer;

  /// No description provided for @linksWorking.
  ///
  /// In en, this message translates to:
  /// **'Working…'**
  String get linksWorking;

  /// No description provided for @linksRevoke.
  ///
  /// In en, this message translates to:
  /// **'Unlink'**
  String get linksRevoke;

  /// No description provided for @wakeWord.
  ///
  /// In en, this message translates to:
  /// **'Wake Word'**
  String get wakeWord;

  /// No description provided for @wakeWordRow.
  ///
  /// In en, this message translates to:
  /// **'Say a phrase to start a call with a bot'**
  String get wakeWordRow;

  /// No description provided for @wakeWordOnRow.
  ///
  /// In en, this message translates to:
  /// **'Listening for \"{phrase}\"'**
  String wakeWordOnRow(String phrase);

  /// No description provided for @wakeWordHelp.
  ///
  /// In en, this message translates to:
  /// **'While Casama is open, this device listens for your phrase and starts a live call with the bot you choose.'**
  String get wakeWordHelp;

  /// No description provided for @wakeWordListen.
  ///
  /// In en, this message translates to:
  /// **'Listen for the Wake Word'**
  String get wakeWordListen;

  /// No description provided for @wakeWordPhrase.
  ///
  /// In en, this message translates to:
  /// **'Phrase'**
  String get wakeWordPhrase;

  /// No description provided for @wakeWordPhraseHelp.
  ///
  /// In en, this message translates to:
  /// **'Two or three words, like \"hey casama\"'**
  String get wakeWordPhraseHelp;

  /// No description provided for @wakeWordBot.
  ///
  /// In en, this message translates to:
  /// **'Call this bot'**
  String get wakeWordBot;

  /// No description provided for @wakeWordDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading the on-device model…'**
  String get wakeWordDownloading;

  /// No description provided for @wakeWordPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Listening happens on this device with an open-source model (about 18 MB, downloaded once). Nothing is sent anywhere until the call starts.'**
  String get wakeWordPrivacy;

  /// No description provided for @secretStore.
  ///
  /// In en, this message translates to:
  /// **'Where Secrets Are Kept'**
  String get secretStore;

  /// No description provided for @secretStoreVault.
  ///
  /// In en, this message translates to:
  /// **'This server\'s vault'**
  String get secretStoreVault;

  /// No description provided for @secretStoreHelp.
  ///
  /// In en, this message translates to:
  /// **'Keep bots\' named secrets in your own Infisical project. Casama keeps only each secret\'s name and where it may be used.'**
  String get secretStoreHelp;

  /// No description provided for @secretStoreSite.
  ///
  /// In en, this message translates to:
  /// **'Infisical address'**
  String get secretStoreSite;

  /// No description provided for @secretStoreProject.
  ///
  /// In en, this message translates to:
  /// **'Project ID'**
  String get secretStoreProject;

  /// No description provided for @secretStoreEnv.
  ///
  /// In en, this message translates to:
  /// **'Environment'**
  String get secretStoreEnv;

  /// No description provided for @secretStoreClientId.
  ///
  /// In en, this message translates to:
  /// **'Machine identity client ID'**
  String get secretStoreClientId;

  /// No description provided for @secretStoreClientSecret.
  ///
  /// In en, this message translates to:
  /// **'Client secret'**
  String get secretStoreClientSecret;

  /// No description provided for @secretStoreMove.
  ///
  /// In en, this message translates to:
  /// **'Move Current Secrets into Infisical'**
  String get secretStoreMove;

  /// No description provided for @secretStoreBack.
  ///
  /// In en, this message translates to:
  /// **'Use This Server\'s Vault Again'**
  String get secretStoreBack;

  /// No description provided for @localServer.
  ///
  /// In en, this message translates to:
  /// **'Run Casama on This Computer'**
  String get localServer;

  /// No description provided for @setupTitleMac.
  ///
  /// In en, this message translates to:
  /// **'Set Up Casama on This Mac'**
  String get setupTitleMac;

  /// No description provided for @setupTitle.
  ///
  /// In en, this message translates to:
  /// **'Set Up Casama on This Computer'**
  String get setupTitle;

  /// No description provided for @setupEntryMac.
  ///
  /// In en, this message translates to:
  /// **'Run on This Mac'**
  String get setupEntryMac;

  /// No description provided for @setupEntry.
  ///
  /// In en, this message translates to:
  /// **'Run on This Computer'**
  String get setupEntry;

  /// No description provided for @setupEntryHelp.
  ///
  /// In en, this message translates to:
  /// **'Free and private: your own server, on this computer.'**
  String get setupEntryHelp;

  /// No description provided for @setupStepDocker.
  ///
  /// In en, this message translates to:
  /// **'Docker'**
  String get setupStepDocker;

  /// No description provided for @setupStepServer.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get setupStepServer;

  /// No description provided for @setupStepAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get setupStepAccount;

  /// No description provided for @setupStepModel.
  ///
  /// In en, this message translates to:
  /// **'AI model'**
  String get setupStepModel;

  /// No description provided for @setupStepPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get setupStepPhone;

  /// No description provided for @setupDockerChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking Docker…'**
  String get setupDockerChecking;

  /// No description provided for @setupDockerMissingTitle.
  ///
  /// In en, this message translates to:
  /// **'First, install Docker'**
  String get setupDockerMissingTitle;

  /// No description provided for @setupDockerMissingBodyMac.
  ///
  /// In en, this message translates to:
  /// **'Casama\'s server runs inside Docker Desktop, a free app that keeps it separate from the rest of your Mac.'**
  String get setupDockerMissingBodyMac;

  /// No description provided for @setupDockerMissingBodyLinux.
  ///
  /// In en, this message translates to:
  /// **'Casama\'s server runs inside Docker, which keeps it separate from the rest of your computer.'**
  String get setupDockerMissingBodyLinux;

  /// No description provided for @setupDockerGetMac.
  ///
  /// In en, this message translates to:
  /// **'Download Docker Desktop'**
  String get setupDockerGetMac;

  /// No description provided for @setupDockerGetLinux.
  ///
  /// In en, this message translates to:
  /// **'Open Docker\'s Install Guide'**
  String get setupDockerGetLinux;

  /// No description provided for @setupDockerStep1.
  ///
  /// In en, this message translates to:
  /// **'Open the file that downloads and drag Docker to Applications.'**
  String get setupDockerStep1;

  /// No description provided for @setupDockerStep2.
  ///
  /// In en, this message translates to:
  /// **'Open Docker and accept its terms.'**
  String get setupDockerStep2;

  /// No description provided for @setupDockerStep3.
  ///
  /// In en, this message translates to:
  /// **'Come back here. This page continues by itself.'**
  String get setupDockerStep3;

  /// No description provided for @setupDockerWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Docker…'**
  String get setupDockerWaiting;

  /// No description provided for @setupDockerStoppedTitle.
  ///
  /// In en, this message translates to:
  /// **'Docker needs to be running'**
  String get setupDockerStoppedTitle;

  /// No description provided for @setupDockerStoppedBodyMac.
  ///
  /// In en, this message translates to:
  /// **'Docker is installed but not open. Once it has started, which can take a minute, this page continues by itself.'**
  String get setupDockerStoppedBodyMac;

  /// No description provided for @setupDockerStoppedBodyLinux.
  ///
  /// In en, this message translates to:
  /// **'Docker is installed but not running. Start it with this command, and this page continues by itself.'**
  String get setupDockerStoppedBodyLinux;

  /// No description provided for @setupDockerOpen.
  ///
  /// In en, this message translates to:
  /// **'Open Docker'**
  String get setupDockerOpen;

  /// No description provided for @setupDockerOpening.
  ///
  /// In en, this message translates to:
  /// **'Starting Docker…'**
  String get setupDockerOpening;

  /// No description provided for @setupDockerPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Docker needs your permission'**
  String get setupDockerPermissionTitle;

  /// No description provided for @setupDockerPermissionBody.
  ///
  /// In en, this message translates to:
  /// **'Docker is running, but your user isn\'t allowed to use it. Run this command, then log out and back in.'**
  String get setupDockerPermissionBody;

  /// No description provided for @setupDockerComposeTitle.
  ///
  /// In en, this message translates to:
  /// **'Docker is missing Compose'**
  String get setupDockerComposeTitle;

  /// No description provided for @setupDockerComposeBody.
  ///
  /// In en, this message translates to:
  /// **'This Docker has no Compose v2. Docker Desktop includes it; on Linux, install the docker-compose-plugin package.'**
  String get setupDockerComposeBody;

  /// No description provided for @setupDiskLow.
  ///
  /// In en, this message translates to:
  /// **'Only {gb} GB of disk space is free. The server needs about 10 GB.'**
  String setupDiskLow(String gb);

  /// No description provided for @setupServerTitle.
  ///
  /// In en, this message translates to:
  /// **'Download and start your server'**
  String get setupServerTitle;

  /// No description provided for @setupServerBody.
  ///
  /// In en, this message translates to:
  /// **'About 10 GB and 5 to 10 minutes the first time. You can keep using your computer.'**
  String get setupServerBody;

  /// No description provided for @setupServerStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get setupServerStart;

  /// No description provided for @setupServerStageDownload.
  ///
  /// In en, this message translates to:
  /// **'Downloading the server'**
  String get setupServerStageDownload;

  /// No description provided for @setupServerStagePrepare.
  ///
  /// In en, this message translates to:
  /// **'Getting it ready'**
  String get setupServerStagePrepare;

  /// No description provided for @setupServerStageParts.
  ///
  /// In en, this message translates to:
  /// **'Downloading its parts'**
  String get setupServerStageParts;

  /// No description provided for @setupServerStagePartsNote.
  ///
  /// In en, this message translates to:
  /// **'The longest step'**
  String get setupServerStagePartsNote;

  /// No description provided for @setupServerStageStart.
  ///
  /// In en, this message translates to:
  /// **'Starting it'**
  String get setupServerStageStart;

  /// No description provided for @setupServerStageWait.
  ///
  /// In en, this message translates to:
  /// **'Waiting for it to answer'**
  String get setupServerStageWait;

  /// No description provided for @setupServerKeepOpen.
  ///
  /// In en, this message translates to:
  /// **'Keep Casama open until this finishes.'**
  String get setupServerKeepOpen;

  /// No description provided for @setupServerFailed.
  ///
  /// In en, this message translates to:
  /// **'The server didn\'t start.'**
  String get setupServerFailed;

  /// No description provided for @setupServerConnecting.
  ///
  /// In en, this message translates to:
  /// **'Ready. Connecting…'**
  String get setupServerConnecting;

  /// No description provided for @setupShowDetails.
  ///
  /// In en, this message translates to:
  /// **'Show Details'**
  String get setupShowDetails;

  /// No description provided for @setupHideDetails.
  ///
  /// In en, this message translates to:
  /// **'Hide Details'**
  String get setupHideDetails;

  /// No description provided for @setupAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get setupAccountTitle;

  /// No description provided for @setupAccountBody.
  ///
  /// In en, this message translates to:
  /// **'It lives on this computer only, and it owns this server. No email is sent.'**
  String get setupAccountBody;

  /// No description provided for @setupAccountName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get setupAccountName;

  /// No description provided for @setupAccountNameMissing.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get setupAccountNameMissing;

  /// No description provided for @setupAccountCreate.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get setupAccountCreate;

  /// No description provided for @setupAccountHave.
  ///
  /// In en, this message translates to:
  /// **'I Already Have an Account Here'**
  String get setupAccountHave;

  /// No description provided for @setupAccountNew.
  ///
  /// In en, this message translates to:
  /// **'Create a New Account Instead'**
  String get setupAccountNew;

  /// No description provided for @setupAccountSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your server'**
  String get setupAccountSignInTitle;

  /// No description provided for @setupAccountSignInBody.
  ///
  /// In en, this message translates to:
  /// **'Use the account you made on this server.'**
  String get setupAccountSignInBody;

  /// No description provided for @setupAccountClosed.
  ///
  /// In en, this message translates to:
  /// **'This server already has its owner. Sign in with that account.'**
  String get setupAccountClosed;

  /// No description provided for @setupAccountPreparing.
  ///
  /// In en, this message translates to:
  /// **'Getting your space ready…'**
  String get setupAccountPreparing;

  /// No description provided for @setupModelTitle.
  ///
  /// In en, this message translates to:
  /// **'Give your bots a model'**
  String get setupModelTitle;

  /// No description provided for @setupModelBody.
  ///
  /// In en, this message translates to:
  /// **'Bots need an AI model to think with. Sign in with a ChatGPT plan, or paste a key from OpenRouter, Google or another provider.'**
  String get setupModelBody;

  /// No description provided for @setupSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip for Now'**
  String get setupSkip;

  /// No description provided for @setupPhoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect your phone'**
  String get setupPhoneTitle;

  /// No description provided for @setupPhoneBody.
  ///
  /// In en, this message translates to:
  /// **'Casama Link gives this computer a private address, so your phone reaches it from anywhere. You approve it once with a free Casama Cloud account. Your chats stay on this computer.'**
  String get setupPhoneBody;

  /// No description provided for @setupPhoneTurnOn.
  ///
  /// In en, this message translates to:
  /// **'Give This Computer an Address'**
  String get setupPhoneTurnOn;

  /// No description provided for @setupPhoneScanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan this with your phone\'s camera'**
  String get setupPhoneScanTitle;

  /// No description provided for @setupPhoneScanBody.
  ///
  /// In en, this message translates to:
  /// **'It opens Casama on the phone and signs you in. If Casama isn\'t on the phone yet, the page that opens says where to get it.'**
  String get setupPhoneScanBody;

  /// No description provided for @setupPhoneWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your phone…'**
  String get setupPhoneWaiting;

  /// No description provided for @setupPhoneConnected.
  ///
  /// In en, this message translates to:
  /// **'Phone connected'**
  String get setupPhoneConnected;

  /// No description provided for @setupPhoneConnectedBody.
  ///
  /// In en, this message translates to:
  /// **'Your phone is signed in. Show a new code to add another device.'**
  String get setupPhoneConnectedBody;

  /// No description provided for @setupPhoneOwnerOnly.
  ///
  /// In en, this message translates to:
  /// **'Only this server\'s owner can give it an address.'**
  String get setupPhoneOwnerOnly;

  /// No description provided for @setupFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get setupFinish;

  /// No description provided for @setupCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Finish setting up'**
  String get setupCardTitle;

  /// No description provided for @setupCardModel.
  ///
  /// In en, this message translates to:
  /// **'Add an AI model so your bots can answer.'**
  String get setupCardModel;

  /// No description provided for @setupCardPhone.
  ///
  /// In en, this message translates to:
  /// **'Connect your phone to this computer.'**
  String get setupCardPhone;

  /// No description provided for @setupCardOpen.
  ///
  /// In en, this message translates to:
  /// **'Continue Setup'**
  String get setupCardOpen;

  /// No description provided for @desktopUsers.
  ///
  /// In en, this message translates to:
  /// **'Desktop users at once'**
  String get desktopUsers;

  /// No description provided for @desktopUsersHelp.
  ///
  /// In en, this message translates to:
  /// **'Bots on this team computer share one screen. Others wait (and keep working with the shell, files and browser) while it\'s in use.'**
  String get desktopUsersHelp;

  /// No description provided for @desktopUsersCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 bot} other{{count} bots}}'**
  String desktopUsersCount(int count);

  /// No description provided for @deviceAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'{bot} would like to use your {what}'**
  String deviceAccessTitle(String bot, String what);

  /// No description provided for @deviceAccessHelp.
  ///
  /// In en, this message translates to:
  /// **'Only in your own chats. You can stop it any time in Settings → Device connections.'**
  String get deviceAccessHelp;

  /// No description provided for @deviceAccessAllowed.
  ///
  /// In en, this message translates to:
  /// **'Allowed to use your {what}'**
  String deviceAccessAllowed(String what);

  /// No description provided for @deviceAccessSkipped.
  ///
  /// In en, this message translates to:
  /// **'Not shared'**
  String get deviceAccessSkipped;

  /// No description provided for @deviceKindCalendar.
  ///
  /// In en, this message translates to:
  /// **'calendar'**
  String get deviceKindCalendar;

  /// No description provided for @deviceKindReminders.
  ///
  /// In en, this message translates to:
  /// **'reminders'**
  String get deviceKindReminders;

  /// No description provided for @deviceKindContacts.
  ///
  /// In en, this message translates to:
  /// **'contacts'**
  String get deviceKindContacts;

  /// No description provided for @deviceKindPlaces.
  ///
  /// In en, this message translates to:
  /// **'places'**
  String get deviceKindPlaces;

  /// No description provided for @deviceKindPhotos.
  ///
  /// In en, this message translates to:
  /// **'photos'**
  String get deviceKindPhotos;

  /// No description provided for @deviceKindHealth.
  ///
  /// In en, this message translates to:
  /// **'health data'**
  String get deviceKindHealth;

  /// No description provided for @deviceKindNotifications.
  ///
  /// In en, this message translates to:
  /// **'notifications'**
  String get deviceKindNotifications;

  /// No description provided for @deviceKindActivity.
  ///
  /// In en, this message translates to:
  /// **'computer activity'**
  String get deviceKindActivity;

  /// No description provided for @deviceKindBrowserTab.
  ///
  /// In en, this message translates to:
  /// **'current browser tab'**
  String get deviceKindBrowserTab;

  /// No description provided for @deviceKindBrowserHistory.
  ///
  /// In en, this message translates to:
  /// **'browser history and bookmarks'**
  String get deviceKindBrowserHistory;

  /// No description provided for @deviceBrowserAsks.
  ///
  /// In en, this message translates to:
  /// **'What Bots May Ask Your Browser'**
  String get deviceBrowserAsks;

  /// No description provided for @deviceBrowserAsksHelp.
  ///
  /// In en, this message translates to:
  /// **'Casama for Chrome answers these live and nothing is kept. Turn them on or off in the extension\'s settings.'**
  String get deviceBrowserAsksHelp;

  /// No description provided for @deviceBrowserAskRevoke.
  ///
  /// In en, this message translates to:
  /// **'Stop letting {bot} ask'**
  String deviceBrowserAskRevoke(String bot);

  /// No description provided for @deviceConnections.
  ///
  /// In en, this message translates to:
  /// **'Device connections'**
  String get deviceConnections;

  /// No description provided for @deviceConnectionsHelp.
  ///
  /// In en, this message translates to:
  /// **'Share data from this device with your bots. Each kind is off until you turn it on, and only bots you allow can read it, only in your own chats.'**
  String get deviceConnectionsHelp;

  /// No description provided for @deviceConnectionsNone.
  ///
  /// In en, this message translates to:
  /// **'This device can\'t share data yet. On your phone, open Casama and turn on what you\'d like to share.'**
  String get deviceConnectionsNone;

  /// No description provided for @deviceKeepFor.
  ///
  /// In en, this message translates to:
  /// **'Keep for'**
  String get deviceKeepFor;

  /// No description provided for @deviceKeepLiveOnly.
  ///
  /// In en, this message translates to:
  /// **'Live only'**
  String get deviceKeepLiveOnly;

  /// No description provided for @deviceKeepDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String deviceKeepDays(int count);

  /// No description provided for @devicePrivateModel.
  ///
  /// In en, this message translates to:
  /// **'Private Models Only'**
  String get devicePrivateModel;

  /// No description provided for @devicePrivateModelHelp.
  ///
  /// In en, this message translates to:
  /// **'Only bots on a local model can read it'**
  String get devicePrivateModelHelp;

  /// No description provided for @deviceNoBots.
  ///
  /// In en, this message translates to:
  /// **'No bots yet. A bot asks when it needs this, or allow one now.'**
  String get deviceNoBots;

  /// No description provided for @deviceAllowBot.
  ///
  /// In en, this message translates to:
  /// **'Allow a bot'**
  String get deviceAllowBot;

  /// No description provided for @deviceAllowBotTitle.
  ///
  /// In en, this message translates to:
  /// **'Which bot may read your {kind}?'**
  String deviceAllowBotTitle(String kind);

  /// No description provided for @devicePermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Casama doesn\'t have permission. Allow it in the system settings, then try again.'**
  String get devicePermissionDenied;

  /// No description provided for @deviceOtherDevices.
  ///
  /// In en, this message translates to:
  /// **'Your Other Devices'**
  String get deviceOtherDevices;

  /// No description provided for @deviceForget.
  ///
  /// In en, this message translates to:
  /// **'Forget this device'**
  String get deviceForget;

  /// No description provided for @deviceBrowsers.
  ///
  /// In en, this message translates to:
  /// **'Browsers Bots Can Use'**
  String get deviceBrowsers;

  /// No description provided for @deviceBrowsersHelp.
  ///
  /// In en, this message translates to:
  /// **'Paired in Casama for Chrome. Bots you allowed work there in their own tab group, signed in as you.'**
  String get deviceBrowsersHelp;

  /// No description provided for @deviceBrowserBots.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No bots yet} =1{1 bot} other{{count} bots}}'**
  String deviceBrowserBots(int count);

  /// No description provided for @deviceBrowserOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get deviceBrowserOnline;

  /// No description provided for @deviceBrowserOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get deviceBrowserOffline;

  /// No description provided for @deviceBrowserUnpair.
  ///
  /// In en, this message translates to:
  /// **'Unpair this browser'**
  String get deviceBrowserUnpair;

  /// No description provided for @deviceConnectionsRowHelp.
  ///
  /// In en, this message translates to:
  /// **'Calendar, contacts and more from this device'**
  String get deviceConnectionsRowHelp;

  /// No description provided for @healthExtraCycle.
  ///
  /// In en, this message translates to:
  /// **'Cycle tracking'**
  String get healthExtraCycle;

  /// No description provided for @healthExtraGlucose.
  ///
  /// In en, this message translates to:
  /// **'Blood glucose'**
  String get healthExtraGlucose;

  /// No description provided for @healthExtraBloodPressure.
  ///
  /// In en, this message translates to:
  /// **'Blood pressure'**
  String get healthExtraBloodPressure;

  /// No description provided for @healthNotMedical.
  ///
  /// In en, this message translates to:
  /// **'Daily summaries only (sleep, activity, workouts, heart). Bots describe how you compare with your usual and never give medical advice.'**
  String get healthNotMedical;

  /// No description provided for @healthNeedsEncryption.
  ///
  /// In en, this message translates to:
  /// **'Health data needs encryption at rest. Turn it on for a workspace you own, then try again.'**
  String get healthNeedsEncryption;

  /// No description provided for @placeAddHere.
  ///
  /// In en, this message translates to:
  /// **'Add Where I Am Now'**
  String get placeAddHere;

  /// No description provided for @placeName.
  ///
  /// In en, this message translates to:
  /// **'Name this place (Home, Work, Gym)'**
  String get placeName;

  /// No description provided for @placeNoLocation.
  ///
  /// In en, this message translates to:
  /// **'Your location isn\'t available. Allow location for Casama, then try again.'**
  String get placeNoLocation;

  /// No description provided for @placesHelp.
  ///
  /// In en, this message translates to:
  /// **'Bots hear when you arrive at or leave these places. Only the place name and the time are shared, never your route.'**
  String get placesHelp;

  /// No description provided for @watchedAppsHelp.
  ///
  /// In en, this message translates to:
  /// **'Only notifications from these apps are shared. One-time codes are hidden before anything leaves your phone.'**
  String get watchedAppsHelp;

  /// No description provided for @watchedAppAdd.
  ///
  /// In en, this message translates to:
  /// **'Add an app (name or package id)'**
  String get watchedAppAdd;

  /// No description provided for @providerHintMaps.
  ///
  /// In en, this message translates to:
  /// **'travel times for leave-now'**
  String get providerHintMaps;

  /// No description provided for @routineDevice.
  ///
  /// In en, this message translates to:
  /// **'On your phone: {event} {detail}'**
  String routineDevice(String event, String detail);

  /// No description provided for @ctxSelection.
  ///
  /// In en, this message translates to:
  /// **'Selected Text'**
  String get ctxSelection;

  /// No description provided for @ctxAddScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Add a Screenshot'**
  String get ctxAddScreenshot;

  /// No description provided for @ctxScreenshotAdded.
  ///
  /// In en, this message translates to:
  /// **'Screenshot Added'**
  String get ctxScreenshotAdded;

  /// No description provided for @ctxScreenshotFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t take a screenshot. Allow screen recording for Casama in your system settings.'**
  String get ctxScreenshotFailed;

  /// No description provided for @watchedFolders.
  ///
  /// In en, this message translates to:
  /// **'Watched Folders'**
  String get watchedFolders;

  /// No description provided for @watchedFoldersHelp.
  ///
  /// In en, this message translates to:
  /// **'A new file in one of these folders can start a routine (for example, file new PDFs in Downloads). Only its name is shared; bots read the file only if they work on this computer.'**
  String get watchedFoldersHelp;

  /// No description provided for @whyTitle.
  ///
  /// In en, this message translates to:
  /// **'Why am I seeing this?'**
  String get whyTitle;

  /// No description provided for @whyData.
  ///
  /// In en, this message translates to:
  /// **'Used: {data}'**
  String whyData(String data);

  /// No description provided for @whyUrgency.
  ///
  /// In en, this message translates to:
  /// **'Urgency: {urgency}'**
  String whyUrgency(String urgency);

  /// No description provided for @heldMeeting.
  ///
  /// In en, this message translates to:
  /// **'It waited while you were in a meeting and came with your brief.'**
  String get heldMeeting;

  /// No description provided for @heldFocus.
  ///
  /// In en, this message translates to:
  /// **'It waited while Focus was on and came with your brief.'**
  String get heldFocus;

  /// No description provided for @heldDriving.
  ///
  /// In en, this message translates to:
  /// **'It waited while you were driving and came with your brief.'**
  String get heldDriving;

  /// No description provided for @heldCap.
  ///
  /// In en, this message translates to:
  /// **'The bot had already sent 5 messages today, so this one waited for your brief.'**
  String get heldCap;

  /// No description provided for @heldLow.
  ///
  /// In en, this message translates to:
  /// **'It wasn\'t urgent, so it waited for your brief instead of buzzing your phone.'**
  String get heldLow;

  /// No description provided for @lessLikeThis.
  ///
  /// In en, this message translates to:
  /// **'Less like this'**
  String get lessLikeThis;

  /// No description provided for @lessLikeThisDone.
  ///
  /// In en, this message translates to:
  /// **'Got It, Fewer Like This'**
  String get lessLikeThisDone;

  /// No description provided for @widgetStatusWorking.
  ///
  /// In en, this message translates to:
  /// **'Working…'**
  String get widgetStatusWorking;

  /// No description provided for @widgetStatusOff.
  ///
  /// In en, this message translates to:
  /// **'Turned off'**
  String get widgetStatusOff;

  /// No description provided for @adminNoWorkspaces.
  ///
  /// In en, this message translates to:
  /// **'No workspaces yet'**
  String get adminNoWorkspaces;

  /// No description provided for @suspendedByInstanceOwner.
  ///
  /// In en, this message translates to:
  /// **'Suspended by the instance owner'**
  String get suspendedByInstanceOwner;

  /// No description provided for @previewHi.
  ///
  /// In en, this message translates to:
  /// **'Hi!'**
  String get previewHi;

  /// No description provided for @previewAsk.
  ///
  /// In en, this message translates to:
  /// **'Can you tidy up my notes?'**
  String get previewAsk;

  /// No description provided for @previewOnIt.
  ///
  /// In en, this message translates to:
  /// **'On it'**
  String get previewOnIt;

  /// No description provided for @previewDone.
  ///
  /// In en, this message translates to:
  /// **'Done! They are in three folders now.'**
  String get previewDone;

  /// No description provided for @previewMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get previewMessage;

  /// No description provided for @fontPreviewGreeting.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get fontPreviewGreeting;

  /// No description provided for @photosFromUnsplash.
  ///
  /// In en, this message translates to:
  /// **'Photos from Unsplash'**
  String get photosFromUnsplash;

  /// No description provided for @showBotSteps.
  ///
  /// In en, this message translates to:
  /// **'Show the bot\'s steps'**
  String get showBotSteps;

  /// No description provided for @showBotStepsHelp.
  ///
  /// In en, this message translates to:
  /// **'Commands and technical errors in every chat.'**
  String get showBotStepsHelp;

  /// No description provided for @showReplyUsage.
  ///
  /// In en, this message translates to:
  /// **'Show usage on replies'**
  String get showReplyUsage;

  /// No description provided for @showReplyUsageHelp.
  ///
  /// In en, this message translates to:
  /// **'What each reply cost, in a line under it.'**
  String get showReplyUsageHelp;

  /// No description provided for @openLinksInApp.
  ///
  /// In en, this message translates to:
  /// **'Open links in the app'**
  String get openLinksInApp;

  /// No description provided for @openLinksInAppHelp.
  ///
  /// In en, this message translates to:
  /// **'Web links open in a browser inside Casama. Off: they open in your default browser.'**
  String get openLinksInAppHelp;

  /// No description provided for @replyUsageTokens.
  ///
  /// In en, this message translates to:
  /// **'{count} tokens'**
  String replyUsageTokens(String count);

  /// No description provided for @replyUsageOnYourKeys.
  ///
  /// In en, this message translates to:
  /// **'{amount} on your keys'**
  String replyUsageOnYourKeys(String amount);

  /// No description provided for @replyUsageOnPlan.
  ///
  /// In en, this message translates to:
  /// **'On your ChatGPT plan'**
  String get replyUsageOnPlan;

  /// No description provided for @replyUsageSoFar.
  ///
  /// In en, this message translates to:
  /// **'{amount} so far'**
  String replyUsageSoFar(String amount);

  /// No description provided for @replyUsageTooltip.
  ///
  /// In en, this message translates to:
  /// **'What this reply cost'**
  String get replyUsageTooltip;

  /// No description provided for @replyUsageTitle.
  ///
  /// In en, this message translates to:
  /// **'What this reply cost'**
  String get replyUsageTitle;

  /// No description provided for @replyUsageFromCredits.
  ///
  /// In en, this message translates to:
  /// **'From your credits'**
  String get replyUsageFromCredits;

  /// No description provided for @replyUsageYourKeys.
  ///
  /// In en, this message translates to:
  /// **'On your own keys'**
  String get replyUsageYourKeys;

  /// No description provided for @replyUsageTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get replyUsageTotal;

  /// No description provided for @replyUsageTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get replyUsageTime;

  /// No description provided for @replyUsageTokensLabel.
  ///
  /// In en, this message translates to:
  /// **'Tokens'**
  String get replyUsageTokensLabel;

  /// No description provided for @replyUsageSteps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get replyUsageSteps;

  /// No description provided for @replyUsageHelpers.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Includes 1 helper run} other{Includes {n} helper runs}}'**
  String replyUsageHelpers(int n);

  /// No description provided for @replyUsageNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing was metered for this reply.'**
  String get replyUsageNothing;

  /// No description provided for @replyUsageCreditsNote.
  ///
  /// In en, this message translates to:
  /// **'1 credit = \$1. Your own keys and plans are billed by their provider, not by Casama.'**
  String get replyUsageCreditsNote;

  /// No description provided for @replyUsageOpenRun.
  ///
  /// In en, this message translates to:
  /// **'Open the run'**
  String get replyUsageOpenRun;

  /// No description provided for @replyUsageLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this reply\'s usage.'**
  String get replyUsageLoadFailed;

  /// No description provided for @replyUsageOurCost.
  ///
  /// In en, this message translates to:
  /// **'Our cost'**
  String get replyUsageOurCost;

  /// No description provided for @replyUsageMargin.
  ///
  /// In en, this message translates to:
  /// **'Margin'**
  String get replyUsageMargin;

  /// No description provided for @replyUsageItemCost.
  ///
  /// In en, this message translates to:
  /// **'Our cost {amount}'**
  String replyUsageItemCost(String amount);

  /// No description provided for @replyUsageAdminNote.
  ///
  /// In en, this message translates to:
  /// **'Our cost and margin are shown to you because you run this server. Nobody else sees them.'**
  String get replyUsageAdminNote;

  /// No description provided for @adminMarginTitle.
  ///
  /// In en, this message translates to:
  /// **'Usage margin'**
  String get adminMarginTitle;

  /// No description provided for @adminMarginDays.
  ///
  /// In en, this message translates to:
  /// **'{n} days'**
  String adminMarginDays(int n);

  /// No description provided for @adminMarginCharged.
  ///
  /// In en, this message translates to:
  /// **'Charged'**
  String get adminMarginCharged;

  /// No description provided for @adminMarginCost.
  ///
  /// In en, this message translates to:
  /// **'Our cost'**
  String get adminMarginCost;

  /// No description provided for @adminMarginProfit.
  ///
  /// In en, this message translates to:
  /// **'Margin'**
  String get adminMarginProfit;

  /// No description provided for @adminMarginEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing was used on the server\'s keys in this period.'**
  String get adminMarginEmpty;

  /// No description provided for @adminMarginUntracked.
  ///
  /// In en, this message translates to:
  /// **'Plus {amount} charged with no cost recorded, left out of the margin.'**
  String adminMarginUntracked(String amount);

  /// No description provided for @adminMarginNote.
  ///
  /// In en, this message translates to:
  /// **'Usage paid from credits, against what the providers charged the server (OpenRouter\'s fee included). Computers count at their provider\'s rate. Cost also includes usage that was given back and web search on the server\'s own providers, which isn\'t charged.'**
  String get adminMarginNote;

  /// No description provided for @adminMarginRow.
  ///
  /// In en, this message translates to:
  /// **'{charged} charged · {cost} cost · {margin} margin'**
  String adminMarginRow(String charged, String cost, String margin);

  /// No description provided for @adminMarginRowUntracked.
  ///
  /// In en, this message translates to:
  /// **'{charged} charged · no cost recorded'**
  String adminMarginRowUntracked(String charged);

  /// No description provided for @adminMarginRowNoCost.
  ///
  /// In en, this message translates to:
  /// **'{amount} with no cost recorded'**
  String adminMarginRowNoCost(String amount);

  /// No description provided for @adminMarginByKind.
  ///
  /// In en, this message translates to:
  /// **'By kind'**
  String get adminMarginByKind;

  /// No description provided for @adminMarginTopOrgs.
  ///
  /// In en, this message translates to:
  /// **'Top workspaces'**
  String get adminMarginTopOrgs;

  /// No description provided for @kindSpeechToText.
  ///
  /// In en, this message translates to:
  /// **'Voice to text'**
  String get kindSpeechToText;

  /// No description provided for @kindVoice.
  ///
  /// In en, this message translates to:
  /// **'Voice calls'**
  String get kindVoice;

  /// No description provided for @kindImages.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get kindImages;

  /// No description provided for @kindVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get kindVideo;

  /// No description provided for @kindSearch.
  ///
  /// In en, this message translates to:
  /// **'Web searches'**
  String get kindSearch;

  /// No description provided for @kindData.
  ///
  /// In en, this message translates to:
  /// **'Data lookups'**
  String get kindData;

  /// No description provided for @kindPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone calls'**
  String get kindPhone;

  /// No description provided for @kindApps.
  ///
  /// In en, this message translates to:
  /// **'App actions'**
  String get kindApps;

  /// No description provided for @activityReady.
  ///
  /// In en, this message translates to:
  /// **'Getting ready…'**
  String get activityReady;

  /// No description provided for @activitySearching.
  ///
  /// In en, this message translates to:
  /// **'Searching the web…'**
  String get activitySearching;

  /// No description provided for @activityBrowsing.
  ///
  /// In en, this message translates to:
  /// **'Browsing the web…'**
  String get activityBrowsing;

  /// No description provided for @activityComputer.
  ///
  /// In en, this message translates to:
  /// **'Working on its computer…'**
  String get activityComputer;

  /// No description provided for @activityFiles.
  ///
  /// In en, this message translates to:
  /// **'Going through files…'**
  String get activityFiles;

  /// No description provided for @activityImage.
  ///
  /// In en, this message translates to:
  /// **'Making an image…'**
  String get activityImage;

  /// No description provided for @activityVideo.
  ///
  /// In en, this message translates to:
  /// **'Making a video…'**
  String get activityVideo;

  /// No description provided for @activityMemory.
  ///
  /// In en, this message translates to:
  /// **'Checking what it knows…'**
  String get activityMemory;

  /// No description provided for @activityApps.
  ///
  /// In en, this message translates to:
  /// **'Using your apps…'**
  String get activityApps;

  /// No description provided for @activityScheduling.
  ///
  /// In en, this message translates to:
  /// **'Setting up a schedule…'**
  String get activityScheduling;

  /// No description provided for @activityWorking.
  ///
  /// In en, this message translates to:
  /// **'Working on it…'**
  String get activityWorking;

  /// No description provided for @activityWaitingForScreen.
  ///
  /// In en, this message translates to:
  /// **'Waiting for you to hand back the screen…'**
  String get activityWaitingForScreen;

  /// No description provided for @runFailedPlain.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again, or open Details to see why.'**
  String get runFailedPlain;

  /// No description provided for @newKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Copy your new key'**
  String get newKeyTitle;

  /// No description provided for @newKeyHelp.
  ///
  /// In en, this message translates to:
  /// **'It\'s shown only this once. Paste it into the app you\'re connecting, then tap Done.'**
  String get newKeyHelp;

  /// No description provided for @copyKey.
  ///
  /// In en, this message translates to:
  /// **'Copy Key'**
  String get copyKey;

  /// No description provided for @keyCopied.
  ///
  /// In en, this message translates to:
  /// **'Key copied'**
  String get keyCopied;

  /// No description provided for @revokeApiKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Revoke “{name}”?'**
  String revokeApiKeyTitle(String name);

  /// No description provided for @revokeApiKeyBody.
  ///
  /// In en, this message translates to:
  /// **'Apps using this key stop connecting right away. This can\'t be undone; to reconnect, make a new key.'**
  String get revokeApiKeyBody;

  /// No description provided for @unlinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlink “{name}”?'**
  String unlinkTitle(String name);

  /// No description provided for @unlinkBody.
  ///
  /// In en, this message translates to:
  /// **'The bots stop talking to each other right away. Linking them again needs a new invite.'**
  String get unlinkBody;

  /// No description provided for @alreadyMember.
  ///
  /// In en, this message translates to:
  /// **'You\'re already in this workspace.'**
  String get alreadyMember;

  /// No description provided for @askAdminToInvite.
  ///
  /// In en, this message translates to:
  /// **'Only owners and admins can invite people. Ask one of them for an invite link.'**
  String get askAdminToInvite;

  /// No description provided for @askBeforeJoining.
  ///
  /// In en, this message translates to:
  /// **'Ask Me Before People Join'**
  String get askBeforeJoining;

  /// No description provided for @askBeforeJoiningHelp.
  ///
  /// In en, this message translates to:
  /// **'An admin approves each person who uses the link.'**
  String get askBeforeJoiningHelp;

  /// No description provided for @askToJoin.
  ///
  /// In en, this message translates to:
  /// **'Ask to join'**
  String get askToJoin;

  /// No description provided for @customLinks.
  ///
  /// In en, this message translates to:
  /// **'Custom links'**
  String get customLinks;

  /// No description provided for @customLinksHelp.
  ///
  /// In en, this message translates to:
  /// **'Links with their own role, expiry or number of uses.'**
  String get customLinksHelp;

  /// No description provided for @emailAddresses.
  ///
  /// In en, this message translates to:
  /// **'Email addresses'**
  String get emailAddresses;

  /// No description provided for @emailAddressesHelp.
  ///
  /// In en, this message translates to:
  /// **'Paste one or more, separated by commas or new lines.'**
  String get emailAddressesHelp;

  /// No description provided for @getCode.
  ///
  /// In en, this message translates to:
  /// **'Get a Code'**
  String get getCode;

  /// No description provided for @getNewCode.
  ///
  /// In en, this message translates to:
  /// **'Get a New Code'**
  String get getNewCode;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @welcomeCta.
  ///
  /// In en, this message translates to:
  /// **'Let\'s Go'**
  String get welcomeCta;

  /// No description provided for @inviteAsAdmin.
  ///
  /// In en, this message translates to:
  /// **'Invite as Admins'**
  String get inviteAsAdmin;

  /// No description provided for @inviteByEmail.
  ///
  /// In en, this message translates to:
  /// **'Invite by Email'**
  String get inviteByEmail;

  /// No description provided for @inviteExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get inviteExpired;

  /// No description provided for @inviteExpires.
  ///
  /// In en, this message translates to:
  /// **'Expires {when}'**
  String inviteExpires(String when);

  /// No description provided for @inviteInvalid.
  ///
  /// In en, this message translates to:
  /// **'This invite doesn\'t work'**
  String get inviteInvalid;

  /// No description provided for @inviteInvalidHelp.
  ///
  /// In en, this message translates to:
  /// **'It may have expired, been used up or been turned off. Ask for a new one.'**
  String get inviteInvalidHelp;

  /// No description provided for @inviteLink.
  ///
  /// In en, this message translates to:
  /// **'Invite link'**
  String get inviteLink;

  /// No description provided for @inviteLinkApprovalHelp.
  ///
  /// In en, this message translates to:
  /// **'Anyone with this link can ask to join. You approve them below.'**
  String get inviteLinkApprovalHelp;

  /// No description provided for @inviteLinkHelp.
  ///
  /// In en, this message translates to:
  /// **'Anyone with this link can join as a member. Share it in a chat or email.'**
  String get inviteLinkHelp;

  /// No description provided for @inviteLinkOrCode.
  ///
  /// In en, this message translates to:
  /// **'Invite link or code'**
  String get inviteLinkOrCode;

  /// No description provided for @inviteOtherServer.
  ///
  /// In en, this message translates to:
  /// **'This invite is for {host}, and this app is connected to a different server.'**
  String inviteOtherServer(String host);

  /// No description provided for @inviteRenewed.
  ///
  /// In en, this message translates to:
  /// **'The invite works for 7 more days. Send them the new link.'**
  String get inviteRenewed;

  /// No description provided for @inviteSentTo.
  ///
  /// In en, this message translates to:
  /// **'Sign in with {email} to accept.'**
  String inviteSentTo(String email);

  /// No description provided for @inviteShareText.
  ///
  /// In en, this message translates to:
  /// **'Join {workspace} on Casama: {url}'**
  String inviteShareText(String workspace, String url);

  /// No description provided for @invitedBy.
  ///
  /// In en, this message translates to:
  /// **'{name} invited you to join'**
  String invitedBy(String name);

  /// No description provided for @invitedToJoin.
  ///
  /// In en, this message translates to:
  /// **'You\'re invited to join'**
  String get invitedToJoin;

  /// No description provided for @invitesSent.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Invite sent.} other{{count} invites sent.}}'**
  String invitesSent(int count);

  /// No description provided for @joinAsAdmin.
  ///
  /// In en, this message translates to:
  /// **'You\'ll join as an admin'**
  String get joinAsAdmin;

  /// No description provided for @joinAsMember.
  ///
  /// In en, this message translates to:
  /// **'You\'ll join as a member'**
  String get joinAsMember;

  /// No description provided for @joinByDomain.
  ///
  /// In en, this message translates to:
  /// **'Join by Email Domain'**
  String get joinByDomain;

  /// No description provided for @joinByDomainHelp.
  ///
  /// In en, this message translates to:
  /// **'Verified addresses join without an invite.'**
  String get joinByDomainHelp;

  /// No description provided for @joinByDomainSwitch.
  ///
  /// In en, this message translates to:
  /// **'Anyone with a verified @{domain} email can join'**
  String joinByDomainSwitch(String domain);

  /// No description provided for @joinByDomainUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Available when you sign in with a verified work email (not gmail.com and the like).'**
  String get joinByDomainUnavailable;

  /// No description provided for @joinNeedsApproval.
  ///
  /// In en, this message translates to:
  /// **'An admin approves new people before they join.'**
  String get joinNeedsApproval;

  /// No description provided for @joinRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Request sent'**
  String get joinRequestSent;

  /// No description provided for @joinRequestSentHelp.
  ///
  /// In en, this message translates to:
  /// **'An admin of {name} will look at it. You\'ll get a notification when you\'re in.'**
  String joinRequestSentHelp(String name);

  /// No description provided for @joinWithLinkOrCode.
  ///
  /// In en, this message translates to:
  /// **'Join with a link or code'**
  String get joinWithLinkOrCode;

  /// No description provided for @spacesInvite.
  ///
  /// In en, this message translates to:
  /// **'Invite people'**
  String get spacesInvite;

  /// No description provided for @spacesInviteTo.
  ///
  /// In en, this message translates to:
  /// **'To {name}'**
  String spacesInviteTo(String name);

  /// No description provided for @spacesNew.
  ///
  /// In en, this message translates to:
  /// **'New workspace'**
  String get spacesNew;

  /// No description provided for @spacesNewHint.
  ///
  /// In en, this message translates to:
  /// **'Its own bots, people and billing'**
  String get spacesNewHint;

  /// No description provided for @spacesJoin.
  ///
  /// In en, this message translates to:
  /// **'Join a workspace'**
  String get spacesJoin;

  /// No description provided for @spacesJoinHint.
  ///
  /// In en, this message translates to:
  /// **'With an invite link or code'**
  String get spacesJoinHint;

  /// No description provided for @joinWorkspaceNamed.
  ///
  /// In en, this message translates to:
  /// **'Join {name}'**
  String joinWorkspaceNamed(String name);

  /// No description provided for @joinedBotsHelp.
  ///
  /// In en, this message translates to:
  /// **'These bots are here to help. Say hello to one to get started.'**
  String get joinedBotsHelp;

  /// No description provided for @joinedNoBots.
  ///
  /// In en, this message translates to:
  /// **'There are no bots here yet. Make one, or look around first.'**
  String get joinedNoBots;

  /// No description provided for @memberCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 member} other{{count} members}}'**
  String memberCount(int count);

  /// No description provided for @members.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get members;

  /// No description provided for @openToDomain.
  ///
  /// In en, this message translates to:
  /// **'Open to @{domain}'**
  String openToDomain(String domain);

  /// No description provided for @openWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Open {name}'**
  String openWorkspace(String name);

  /// No description provided for @pendingInvites.
  ///
  /// In en, this message translates to:
  /// **'Invites Not Accepted Yet'**
  String get pendingInvites;

  /// No description provided for @people.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get people;

  /// No description provided for @workspaceAdvancedSummary.
  ///
  /// In en, this message translates to:
  /// **'Secrets, memory, encryption, payments, MCP'**
  String get workspaceAdvancedSummary;

  /// No description provided for @peopleAdvancedSummary.
  ///
  /// In en, this message translates to:
  /// **'Invite code, email domain, custom links'**
  String get peopleAdvancedSummary;

  /// No description provided for @inviteLinkToCopy.
  ///
  /// In en, this message translates to:
  /// **'Invite link, ready to copy'**
  String get inviteLinkToCopy;

  /// No description provided for @linkMade.
  ///
  /// In en, this message translates to:
  /// **'Made {when}'**
  String linkMade(String when);

  /// No description provided for @billingAdvancedSummary.
  ///
  /// In en, this message translates to:
  /// **'Charges by server, Casama Link servers and keys'**
  String get billingAdvancedSummary;

  /// No description provided for @billingChargesSummary.
  ///
  /// In en, this message translates to:
  /// **'Charges by server'**
  String get billingChargesSummary;

  /// No description provided for @billingUsageRow.
  ///
  /// In en, this message translates to:
  /// **'What bots used and what it cost'**
  String get billingUsageRow;

  /// No description provided for @billingUsageSoFar.
  ///
  /// In en, this message translates to:
  /// **'This month so far: {amount}'**
  String billingUsageSoFar(String amount);

  /// No description provided for @usageAdvancedSummary.
  ///
  /// In en, this message translates to:
  /// **'Token counts, JSON export'**
  String get usageAdvancedSummary;

  /// No description provided for @peopleHelp.
  ///
  /// In en, this message translates to:
  /// **'Invite people and decide who gets in.'**
  String get peopleHelp;

  /// No description provided for @peopleRow.
  ///
  /// In en, this message translates to:
  /// **'Invite people, approve requests, see members'**
  String get peopleRow;

  /// No description provided for @qrCode.
  ///
  /// In en, this message translates to:
  /// **'QR Code'**
  String get qrCode;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @resendInvite.
  ///
  /// In en, this message translates to:
  /// **'Send Again'**
  String get resendInvite;

  /// No description provided for @resetLink.
  ///
  /// In en, this message translates to:
  /// **'Reset Link'**
  String get resetLink;

  /// No description provided for @resetLinkHelp.
  ///
  /// In en, this message translates to:
  /// **'The current link stops working right away and you get a new one. People already in stay in.'**
  String get resetLinkHelp;

  /// No description provided for @revokeInvite.
  ///
  /// In en, this message translates to:
  /// **'Cancel Invite'**
  String get revokeInvite;

  /// No description provided for @scanToJoin.
  ///
  /// In en, this message translates to:
  /// **'Scan to join {name}'**
  String scanToJoin(String name);

  /// No description provided for @sendInvitesCount.
  ///
  /// In en, this message translates to:
  /// **'Send {count} Invites'**
  String sendInvitesCount(int count);

  /// No description provided for @sendInvitesYourself.
  ///
  /// In en, this message translates to:
  /// **'Send these invites yourself'**
  String get sendInvitesYourself;

  /// No description provided for @sendInvitesYourselfHelp.
  ///
  /// In en, this message translates to:
  /// **'Email isn\'t set up on this server. Send each person their link, and they sign in with that address to join.'**
  String get sendInvitesYourselfHelp;

  /// No description provided for @signInToJoin.
  ///
  /// In en, this message translates to:
  /// **'Sign in to join'**
  String get signInToJoin;

  /// No description provided for @startOwnWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Start My Own Workspace Instead'**
  String get startOwnWorkspace;

  /// No description provided for @switchToServer.
  ///
  /// In en, this message translates to:
  /// **'Switch to {host}'**
  String switchToServer(String host);

  /// No description provided for @waitingToJoin.
  ///
  /// In en, this message translates to:
  /// **'Waiting to Join'**
  String get waitingToJoin;

  /// No description provided for @welcomeToWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Welcome to {name}'**
  String welcomeToWorkspace(String name);

  /// No description provided for @workspacesYouCanJoin.
  ///
  /// In en, this message translates to:
  /// **'Workspaces You Can Join'**
  String get workspacesYouCanJoin;

  /// No description provided for @yourTeamIsHere.
  ///
  /// In en, this message translates to:
  /// **'Your team is already here'**
  String get yourTeamIsHere;

  /// No description provided for @yourTeamIsHereHelp.
  ///
  /// In en, this message translates to:
  /// **'People at {domain} use these workspaces. Join one, or start your own.'**
  String yourTeamIsHereHelp(String domain);

  /// No description provided for @inviteCodeCardHelp.
  ///
  /// In en, this message translates to:
  /// **'Easy to read out or type. Works for 48 hours. People enter it under Join with a link or code.'**
  String get inviteCodeCardHelp;

  /// No description provided for @inviteSomeoneNew.
  ///
  /// In en, this message translates to:
  /// **'Invite someone new to the workspace'**
  String get inviteSomeoneNew;

  /// No description provided for @oauthNeedsHttps.
  ///
  /// In en, this message translates to:
  /// **'{app} only signs in on a secure (https) address, and this Casama server is at {address}. Serve Casama over https to use sign-in.'**
  String oauthNeedsHttps(String app, String address);

  /// No description provided for @aboutYou.
  ///
  /// In en, this message translates to:
  /// **'About you'**
  String get aboutYou;

  /// No description provided for @aboutYouRow.
  ///
  /// In en, this message translates to:
  /// **'What your bots call you and know about you'**
  String get aboutYouRow;

  /// No description provided for @aboutYouIntro.
  ///
  /// In en, this message translates to:
  /// **'Your bots read this so they can call you by name and answer the way you like. Only you can see it.'**
  String get aboutYouIntro;

  /// No description provided for @photoChange.
  ///
  /// In en, this message translates to:
  /// **'Change profile photo'**
  String get photoChange;

  /// No description provided for @photoTake.
  ///
  /// In en, this message translates to:
  /// **'Take a Photo'**
  String get photoTake;

  /// No description provided for @photoChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose a Photo'**
  String get photoChoose;

  /// No description provided for @photoUseGoogle.
  ///
  /// In en, this message translates to:
  /// **'Use My Google Photo'**
  String get photoUseGoogle;

  /// No description provided for @photoRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove Photo'**
  String get photoRemove;

  /// No description provided for @photoUnreadable.
  ///
  /// In en, this message translates to:
  /// **'That file isn\'t a photo Casama can use. Try a JPEG or PNG.'**
  String get photoUnreadable;

  /// No description provided for @whatToCallYou.
  ///
  /// In en, this message translates to:
  /// **'What should bots call you?'**
  String get whatToCallYou;

  /// No description provided for @pronounsOptional.
  ///
  /// In en, this message translates to:
  /// **'Pronouns (optional)'**
  String get pronounsOptional;

  /// No description provided for @aboutMe.
  ///
  /// In en, this message translates to:
  /// **'About me'**
  String get aboutMe;

  /// No description provided for @aboutMeHint.
  ///
  /// In en, this message translates to:
  /// **'Your work, the people in your life, what you\'re into. Anything that helps.'**
  String get aboutMeHint;

  /// No description provided for @replyStyle.
  ///
  /// In en, this message translates to:
  /// **'How I like replies'**
  String get replyStyle;

  /// No description provided for @replyStyleHint.
  ///
  /// In en, this message translates to:
  /// **'For example: short answers, no emoji, explain things like I\'m new to them'**
  String get replyStyleHint;

  /// No description provided for @learnAboutMe.
  ///
  /// In en, this message translates to:
  /// **'Learn About Me from Chats'**
  String get learnAboutMe;

  /// No description provided for @learnAboutMeHelp.
  ///
  /// In en, this message translates to:
  /// **'Bots save facts about you. Edit them any time.'**
  String get learnAboutMeHelp;

  /// No description provided for @useInThisSpace.
  ///
  /// In en, this message translates to:
  /// **'Use what I\'ve shared in {workspace}'**
  String useInThisSpace(String workspace);

  /// No description provided for @useInThisSpaceHelp.
  ///
  /// In en, this message translates to:
  /// **'Off: only your name and reply style are used here.'**
  String get useInThisSpaceHelp;

  /// No description provided for @learnedAboutYou.
  ///
  /// In en, this message translates to:
  /// **'What Bots Learned'**
  String get learnedAboutYou;

  /// No description provided for @noLearnedFacts.
  ///
  /// In en, this message translates to:
  /// **'Nothing yet. Facts bots learn about you in chat show up here.'**
  String get noLearnedFacts;

  /// No description provided for @addFact.
  ///
  /// In en, this message translates to:
  /// **'Add a Fact'**
  String get addFact;

  /// No description provided for @editFact.
  ///
  /// In en, this message translates to:
  /// **'Edit fact'**
  String get editFact;

  /// No description provided for @deleteFactTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this fact?'**
  String get deleteFactTitle;

  /// No description provided for @deleteFactConfirm.
  ///
  /// In en, this message translates to:
  /// **'Your bots won\'t know it anymore.'**
  String get deleteFactConfirm;

  /// No description provided for @importToProfile.
  ///
  /// In en, this message translates to:
  /// **'Import from ChatGPT or Claude'**
  String get importToProfile;

  /// No description provided for @savedToProfile.
  ///
  /// In en, this message translates to:
  /// **'Saved to your profile'**
  String get savedToProfile;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @suggestedLookApplied.
  ///
  /// In en, this message translates to:
  /// **'New look applied'**
  String get suggestedLookApplied;

  /// No description provided for @suggestedLookUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This app doesn\'t have that look'**
  String get suggestedLookUnavailable;

  /// No description provided for @removedFromProfile.
  ///
  /// In en, this message translates to:
  /// **'Removed from your profile'**
  String get removedFromProfile;

  /// No description provided for @factsImported.
  ///
  /// In en, this message translates to:
  /// **'Added {count, plural, =1{1 fact} other{{count} facts}}'**
  String factsImported(int count);

  /// No description provided for @nameCardHelp.
  ///
  /// In en, this message translates to:
  /// **'Your bots will use it in every workspace. You can change it later in Settings → About you.'**
  String get nameCardHelp;

  /// No description provided for @nameStepBubble.
  ///
  /// In en, this message translates to:
  /// **'Nice to meet you!'**
  String get nameStepBubble;

  /// No description provided for @nameStepHint.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get nameStepHint;

  /// No description provided for @skillCatalogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ready-made skills your bots load when a task calls for one.'**
  String get skillCatalogSubtitle;

  /// No description provided for @skillCategoryWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get skillCategoryWork;

  /// No description provided for @skillCategoryWriting.
  ///
  /// In en, this message translates to:
  /// **'Writing'**
  String get skillCategoryWriting;

  /// No description provided for @skillCategoryResearch.
  ///
  /// In en, this message translates to:
  /// **'Research'**
  String get skillCategoryResearch;

  /// No description provided for @skillCategoryData.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get skillCategoryData;

  /// No description provided for @skillCategoryMoney.
  ///
  /// In en, this message translates to:
  /// **'Money'**
  String get skillCategoryMoney;

  /// No description provided for @skillCategoryBuild.
  ///
  /// In en, this message translates to:
  /// **'Build'**
  String get skillCategoryBuild;

  /// No description provided for @skillCategoryLife.
  ///
  /// In en, this message translates to:
  /// **'Life'**
  String get skillCategoryLife;

  /// No description provided for @skillCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 skill} other{{count} skills}}'**
  String skillCount(int count);

  /// No description provided for @skillInstalledBadge.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get skillInstalledBadge;

  /// No description provided for @skillInstalledFor.
  ///
  /// In en, this message translates to:
  /// **'Installed for {names}'**
  String skillInstalledFor(String names);

  /// No description provided for @installSkillFor.
  ///
  /// In en, this message translates to:
  /// **'Install {name} for'**
  String installSkillFor(String name);

  /// No description provided for @skillUseHint.
  ///
  /// In en, this message translates to:
  /// **'Bots load it on their own when a task fits, or type /{name} in a chat to use it.'**
  String skillUseHint(String name);

  /// No description provided for @skillAlreadyEverywhere.
  ///
  /// In en, this message translates to:
  /// **'Installed everywhere it can be.'**
  String get skillAlreadyEverywhere;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @galleryEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing in the gallery matches.'**
  String get galleryEmpty;

  /// No description provided for @galleryOffline.
  ///
  /// In en, this message translates to:
  /// **'The gallery can\'t be reached right now. The built-in looks and skills are still here.'**
  String get galleryOffline;

  /// No description provided for @galleryUse.
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get galleryUse;

  /// No description provided for @galleryInstall.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get galleryInstall;

  /// No description provided for @galleryReport.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get galleryReport;

  /// No description provided for @galleryShare.
  ///
  /// In en, this message translates to:
  /// **'Share to Gallery'**
  String get galleryShare;

  /// No description provided for @galleryBy.
  ///
  /// In en, this message translates to:
  /// **'By {name}'**
  String galleryBy(String name);

  /// No description provided for @galleryFeatured.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get galleryFeatured;

  /// No description provided for @galleryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get galleryAll;

  /// No description provided for @galleryThemes.
  ///
  /// In en, this message translates to:
  /// **'Themes'**
  String get galleryThemes;

  /// No description provided for @gallerySchemes.
  ///
  /// In en, this message translates to:
  /// **'Colors'**
  String get gallerySchemes;

  /// No description provided for @galleryWallpapers.
  ///
  /// In en, this message translates to:
  /// **'Wallpapers'**
  String get galleryWallpapers;

  /// No description provided for @gallerySkills.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get gallerySkills;

  /// No description provided for @fromGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get fromGallery;

  /// No description provided for @galleryApplied.
  ///
  /// In en, this message translates to:
  /// **'Using {name}'**
  String galleryApplied(String name);

  /// No description provided for @gallerySeeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get gallerySeeAll;

  /// No description provided for @galleryInUse.
  ///
  /// In en, this message translates to:
  /// **'In use'**
  String get galleryInUse;

  /// No description provided for @galleryInstalled.
  ///
  /// In en, this message translates to:
  /// **'Installed {name}'**
  String galleryInstalled(String name);

  /// No description provided for @galleryPreviewDark.
  ///
  /// In en, this message translates to:
  /// **'Preview in dark'**
  String get galleryPreviewDark;

  /// No description provided for @galleryPreviewLight.
  ///
  /// In en, this message translates to:
  /// **'Preview in light'**
  String get galleryPreviewLight;

  /// No description provided for @galleryClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get galleryClearSearch;

  /// No description provided for @galleryOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'The gallery is offline'**
  String get galleryOfflineTitle;

  /// No description provided for @galleryNoMatches.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches “{query}”'**
  String galleryNoMatches(String query);

  /// No description provided for @galleryInstructions.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get galleryInstructions;

  /// No description provided for @galleryPatternOn.
  ///
  /// In en, this message translates to:
  /// **'{pattern} on {palette}'**
  String galleryPatternOn(String pattern, String palette);

  /// No description provided for @galleryImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get galleryImage;

  /// No description provided for @galleryMeshGradient.
  ///
  /// In en, this message translates to:
  /// **'a mesh gradient'**
  String get galleryMeshGradient;

  /// No description provided for @galleryOwnDoodles.
  ///
  /// In en, this message translates to:
  /// **'Own doodles'**
  String get galleryOwnDoodles;

  /// No description provided for @galleryLightAndDark.
  ///
  /// In en, this message translates to:
  /// **'Light and dark'**
  String get galleryLightAndDark;

  /// No description provided for @galleryContribute.
  ///
  /// In en, this message translates to:
  /// **'Made a look you like? Share it, and everyone on Casama can find it here.'**
  String get galleryContribute;

  /// No description provided for @galleryTypeTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get galleryTypeTheme;

  /// No description provided for @galleryTypeScheme.
  ///
  /// In en, this message translates to:
  /// **'Color scheme'**
  String get galleryTypeScheme;

  /// No description provided for @galleryTypeWallpaper.
  ///
  /// In en, this message translates to:
  /// **'Wallpaper'**
  String get galleryTypeWallpaper;

  /// No description provided for @galleryTypeSkill.
  ///
  /// In en, this message translates to:
  /// **'Skill'**
  String get galleryTypeSkill;

  /// No description provided for @galleryBehindChats.
  ///
  /// In en, this message translates to:
  /// **'Behind Your Chats'**
  String get galleryBehindChats;

  /// No description provided for @celebrateNewBot.
  ///
  /// In en, this message translates to:
  /// **'Say hi to {name}!'**
  String celebrateNewBot(String name);

  /// No description provided for @celebrateNewSpace.
  ///
  /// In en, this message translates to:
  /// **'{name} is ready!'**
  String celebrateNewSpace(String name);

  /// No description provided for @celebrateJoined.
  ///
  /// In en, this message translates to:
  /// **'You\'re in! Welcome to the space.'**
  String get celebrateJoined;

  /// No description provided for @celebrateNewRoutine.
  ///
  /// In en, this message translates to:
  /// **'{name} is all set.'**
  String celebrateNewRoutine(String name);

  /// No description provided for @fewerEffects.
  ///
  /// In en, this message translates to:
  /// **'Fewer Effects'**
  String get fewerEffects;

  /// No description provided for @fewerEffectsHelp.
  ///
  /// In en, this message translates to:
  /// **'No celebrations, bouncing tabs or animated bots.'**
  String get fewerEffectsHelp;

  /// No description provided for @settingsAppSection.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get settingsAppSection;

  /// No description provided for @settingsSecuritySection.
  ///
  /// In en, this message translates to:
  /// **'Sign-in & security'**
  String get settingsSecuritySection;

  /// No description provided for @customize.
  ///
  /// In en, this message translates to:
  /// **'Customize'**
  String get customize;

  /// No description provided for @customizeColors.
  ///
  /// In en, this message translates to:
  /// **'Colors'**
  String get customizeColors;

  /// No description provided for @appearanceCustomLook.
  ///
  /// In en, this message translates to:
  /// **'Custom look'**
  String get appearanceCustomLook;

  /// No description provided for @appearanceCustomHelp.
  ///
  /// In en, this message translates to:
  /// **'Your own changes. Save them to keep this look.'**
  String get appearanceCustomHelp;

  /// No description provided for @appearanceFromGallery.
  ///
  /// In en, this message translates to:
  /// **'From the Gallery'**
  String get appearanceFromGallery;

  /// No description provided for @appearanceShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show All {count}'**
  String appearanceShowAll(int count);

  /// No description provided for @appearanceSwitched.
  ///
  /// In en, this message translates to:
  /// **'Switched to {name}'**
  String appearanceSwitched(String name);

  /// No description provided for @appearanceSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved {name} to your themes'**
  String appearanceSaved(String name);

  /// No description provided for @appearanceAboutTheme.
  ///
  /// In en, this message translates to:
  /// **'About this theme'**
  String get appearanceAboutTheme;

  /// No description provided for @settingsOnDevServer.
  ///
  /// In en, this message translates to:
  /// **'Settings · development server {host}'**
  String settingsOnDevServer(String host);

  /// No description provided for @chatPreviewYou.
  ///
  /// In en, this message translates to:
  /// **'You: {text}'**
  String chatPreviewYou(String text);

  /// No description provided for @chatPreviewPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get chatPreviewPhoto;

  /// No description provided for @chatPreviewVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get chatPreviewVideo;

  /// No description provided for @chatPreviewVoice.
  ///
  /// In en, this message translates to:
  /// **'Voice note'**
  String get chatPreviewVoice;

  /// No description provided for @chatPreviewNone.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get chatPreviewNone;

  /// No description provided for @chatTimeYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get chatTimeYesterday;

  /// No description provided for @chatDayToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get chatDayToday;

  /// No description provided for @chatDayAndTime.
  ///
  /// In en, this message translates to:
  /// **'{day} · {time}'**
  String chatDayAndTime(String day, String time);

  /// No description provided for @messageSentAt.
  ///
  /// In en, this message translates to:
  /// **'{day} at {time}'**
  String messageSentAt(String day, String time);

  /// No description provided for @anyPriority.
  ///
  /// In en, this message translates to:
  /// **'Any priority'**
  String get anyPriority;

  /// No description provided for @readingAloud.
  ///
  /// In en, this message translates to:
  /// **'Reading aloud'**
  String get readingAloud;

  /// No description provided for @readAloudPreparing.
  ///
  /// In en, this message translates to:
  /// **'Getting ready…'**
  String get readAloudPreparing;

  /// No description provided for @readAloudPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get readAloudPaused;

  /// No description provided for @stopReading.
  ///
  /// In en, this message translates to:
  /// **'Stop reading'**
  String get stopReading;

  /// No description provided for @readAloudSpeed.
  ///
  /// In en, this message translates to:
  /// **'Playback speed'**
  String get readAloudSpeed;

  /// No description provided for @readAloudTimeLeft.
  ///
  /// In en, this message translates to:
  /// **'{time} left'**
  String readAloudTimeLeft(String time);

  /// No description provided for @readAloudShowMessage.
  ///
  /// In en, this message translates to:
  /// **'Show the message being read'**
  String get readAloudShowMessage;

  /// No description provided for @mentionOpenProfile.
  ///
  /// In en, this message translates to:
  /// **'{name}, open profile'**
  String mentionOpenProfile(String name);

  /// No description provided for @paywallSubtitle.
  ///
  /// In en, this message translates to:
  /// **'More bots, more computer time and fresh credits every month, so your bots can keep working.'**
  String get paywallSubtitle;

  /// No description provided for @paywallPerkBots.
  ///
  /// In en, this message translates to:
  /// **'Bots'**
  String get paywallPerkBots;

  /// No description provided for @paywallPerkBotsBody.
  ///
  /// In en, this message translates to:
  /// **'A whole crew, each with its own job.'**
  String get paywallPerkBotsBody;

  /// No description provided for @paywallPerkComputers.
  ///
  /// In en, this message translates to:
  /// **'Computer time'**
  String get paywallPerkComputers;

  /// No description provided for @paywallPerkComputersBody.
  ///
  /// In en, this message translates to:
  /// **'Bots get their own computers to browse, code and build.'**
  String get paywallPerkComputersBody;

  /// No description provided for @paywallPerkCredits.
  ///
  /// In en, this message translates to:
  /// **'Monthly credits'**
  String get paywallPerkCredits;

  /// No description provided for @paywallPerkCreditsBody.
  ///
  /// In en, this message translates to:
  /// **'For models, search and tools.'**
  String get paywallPerkCreditsBody;

  /// No description provided for @paywallPerkSeats.
  ///
  /// In en, this message translates to:
  /// **'Seats'**
  String get paywallPerkSeats;

  /// No description provided for @paywallPerkSeatsBody.
  ///
  /// In en, this message translates to:
  /// **'Bring your team into the same workspace.'**
  String get paywallPerkSeatsBody;

  /// No description provided for @paywallHours.
  ///
  /// In en, this message translates to:
  /// **'{hours} h'**
  String paywallHours(String hours);

  /// No description provided for @paywallWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get paywallWeekly;

  /// No description provided for @paywallMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get paywallMonthly;

  /// No description provided for @paywallYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get paywallYearly;

  /// No description provided for @paywallPerMonth.
  ///
  /// In en, this message translates to:
  /// **'/ month'**
  String get paywallPerMonth;

  /// No description provided for @paywallPerYear.
  ///
  /// In en, this message translates to:
  /// **'/ year'**
  String get paywallPerYear;

  /// No description provided for @paywallContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get paywallContinue;

  /// No description provided for @paywallContinueCheckout.
  ///
  /// In en, this message translates to:
  /// **'Continue to checkout'**
  String get paywallContinueCheckout;

  /// No description provided for @paywallRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get paywallRestore;

  /// No description provided for @paywallFineStore.
  ///
  /// In en, this message translates to:
  /// **'Renews automatically. Cancel anytime in your store settings.'**
  String get paywallFineStore;

  /// No description provided for @paywallFineWeb.
  ///
  /// In en, this message translates to:
  /// **'Renews automatically. Cancel anytime from Billing.'**
  String get paywallFineWeb;

  /// No description provided for @paywallDisclosureStore.
  ///
  /// In en, this message translates to:
  /// **'{price} {period}, renewing automatically until you cancel. Payment is charged to your {store}. Cancel anytime in your {store} settings at least 24 hours before it renews.'**
  String paywallDisclosureStore(String price, String period, String store);

  /// No description provided for @paywallDisclosureStoreTrial.
  ///
  /// In en, this message translates to:
  /// **'Free for {days} days, then {price} {period}, renewing automatically until you cancel. Payment is charged to your {store} when the trial ends. Cancel in your {store} settings at least 24 hours before the trial ends and you won\'t be charged.'**
  String paywallDisclosureStoreTrial(
    int days,
    String price,
    String period,
    String store,
  );

  /// No description provided for @paywallStartFreeTrial.
  ///
  /// In en, this message translates to:
  /// **'Start free trial'**
  String get paywallStartFreeTrial;

  /// No description provided for @paywallTrialThen.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day} other{{days} days}} free, then {price}{period}'**
  String paywallTrialThen(int days, String price, String period);

  /// No description provided for @paywallDisclosureWeb.
  ///
  /// In en, this message translates to:
  /// **'{price}, renewing automatically until you cancel. Cancel anytime from Billing; you keep the plan until the period ends.'**
  String paywallDisclosureWeb(String price);

  /// No description provided for @paywallDisclosureWebTrial.
  ///
  /// In en, this message translates to:
  /// **'Free for {days} days, then {price}, renewing automatically until you cancel. Cancel from Billing before the trial ends and you won\'t be charged.'**
  String paywallDisclosureWebTrial(int days, String price);

  /// No description provided for @pricePerWeek.
  ///
  /// In en, this message translates to:
  /// **'per week'**
  String get pricePerWeek;

  /// No description provided for @pricePerMonth.
  ///
  /// In en, this message translates to:
  /// **'per month'**
  String get pricePerMonth;

  /// No description provided for @pricePerYear.
  ///
  /// In en, this message translates to:
  /// **'per year'**
  String get pricePerYear;

  /// No description provided for @storeAccountApple.
  ///
  /// In en, this message translates to:
  /// **'Apple Account'**
  String get storeAccountApple;

  /// No description provided for @storeAccountGoogle.
  ///
  /// In en, this message translates to:
  /// **'Google Play account'**
  String get storeAccountGoogle;

  /// No description provided for @termsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get termsOfUse;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @aiConsentTitle.
  ///
  /// In en, this message translates to:
  /// **'Your chats go to AI companies'**
  String get aiConsentTitle;

  /// No description provided for @aiConsentBody.
  ///
  /// In en, this message translates to:
  /// **'To write replies, Casama sends what you share with your bots to outside AI providers. Nothing is sent until you agree.'**
  String get aiConsentBody;

  /// No description provided for @aiConsentWhatTitle.
  ///
  /// In en, this message translates to:
  /// **'What is sent'**
  String get aiConsentWhatTitle;

  /// No description provided for @aiConsentWhat.
  ///
  /// In en, this message translates to:
  /// **'Your messages, files and photos, your voice in calls, what bots remember about you, and any phone data you turn on, such as calendar or health.'**
  String get aiConsentWhat;

  /// No description provided for @aiConsentWhoTitle.
  ///
  /// In en, this message translates to:
  /// **'Who gets it'**
  String get aiConsentWhoTitle;

  /// No description provided for @aiConsentWho.
  ///
  /// In en, this message translates to:
  /// **'OpenRouter, which passes it to the company that makes the model you use, such as DeepSeek, Google or OpenAI. Calls use Google Gemini. Web searches go to Parallel, Serper or DeepSeek. With your own API key, it goes to that provider instead.'**
  String get aiConsentWho;

  /// No description provided for @aiConsentWhyTitle.
  ///
  /// In en, this message translates to:
  /// **'What they do with it'**
  String get aiConsentWhyTitle;

  /// No description provided for @aiConsentWhy.
  ///
  /// In en, this message translates to:
  /// **'They use it to write the reply. You can stop this any time in Settings › Privacy, and the privacy policy has the details.'**
  String get aiConsentWhy;

  /// No description provided for @aiConsentAgree.
  ///
  /// In en, this message translates to:
  /// **'Agree and Continue'**
  String get aiConsentAgree;

  /// No description provided for @aiConsentTile.
  ///
  /// In en, this message translates to:
  /// **'AI providers'**
  String get aiConsentTile;

  /// No description provided for @aiConsentTileOn.
  ///
  /// In en, this message translates to:
  /// **'Allowed. What you share with bots goes to outside AI providers to write replies.'**
  String get aiConsentTileOn;

  /// No description provided for @aiConsentWithdrawQuestion.
  ///
  /// In en, this message translates to:
  /// **'Stop sharing with AI providers?'**
  String get aiConsentWithdrawQuestion;

  /// No description provided for @aiConsentWithdrawBody.
  ///
  /// In en, this message translates to:
  /// **'Bots can\'t reply without them. Casama asks again before anything else is sent.'**
  String get aiConsentWithdrawBody;

  /// No description provided for @aiConsentWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Stop Sharing'**
  String get aiConsentWithdraw;

  /// No description provided for @planChanged.
  ///
  /// In en, this message translates to:
  /// **'Plan changed'**
  String get planChanged;

  /// No description provided for @purchasesRestored.
  ///
  /// In en, this message translates to:
  /// **'Purchases restored'**
  String get purchasesRestored;

  /// No description provided for @creditsAdded.
  ///
  /// In en, this message translates to:
  /// **'Credits added'**
  String get creditsAdded;

  /// No description provided for @purchasePending.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the purchase to be approved. It\'s added as soon as it is.'**
  String get purchasePending;

  /// No description provided for @purchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'The purchase didn\'t go through, and you weren\'t charged.'**
  String get purchaseFailed;

  /// No description provided for @purchaseVerifyFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t confirm your purchase yet. It\'s retried on its own; if it doesn\'t show up soon, tap Restore Purchases.'**
  String get purchaseVerifyFailed;

  /// No description provided for @paywallTitleFor.
  ///
  /// In en, this message translates to:
  /// **'Grow your crew with {plan}'**
  String paywallTitleFor(String plan);

  /// No description provided for @paywallWelcomePlan.
  ///
  /// In en, this message translates to:
  /// **'Welcome to {plan}!'**
  String paywallWelcomePlan(String plan);

  /// No description provided for @paywallMonthsFree.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 month free} other{{n} months free}}'**
  String paywallMonthsFree(int n);

  /// No description provided for @paywallSwitchTo.
  ///
  /// In en, this message translates to:
  /// **'Switch to {plan}'**
  String paywallSwitchTo(String plan);

  /// No description provided for @subscribedInStoreNote.
  ///
  /// In en, this message translates to:
  /// **'You subscribe through {store}. To change plans, use {store} on the device you subscribed with.'**
  String subscribedInStoreNote(String store);

  /// No description provided for @subscribedOnWebNote.
  ///
  /// In en, this message translates to:
  /// **'You subscribe on the web. Change plans here with web checkout, or manage your subscription.'**
  String get subscribedOnWebNote;

  /// No description provided for @subscribedOutsideAppNote.
  ///
  /// In en, this message translates to:
  /// **'Your subscription is billed outside this app, so it can\'t be changed here.'**
  String get subscribedOutsideAppNote;

  /// No description provided for @outOfCreditsTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re out of credits'**
  String get outOfCreditsTitle;

  /// No description provided for @outOfCreditsPaidBody.
  ///
  /// In en, this message translates to:
  /// **'Your bots pause until you add credits. Packs from the App Store or Google Play never expire; web packs last 12 months.'**
  String get outOfCreditsPaidBody;

  /// No description provided for @outOfCreditsFreeBody.
  ///
  /// In en, this message translates to:
  /// **'Upgrade for more credits every month, more bots and more computer time.'**
  String get outOfCreditsFreeBody;

  /// No description provided for @addCredits.
  ///
  /// In en, this message translates to:
  /// **'Add Credits'**
  String get addCredits;

  /// No description provided for @seePlansButton.
  ///
  /// In en, this message translates to:
  /// **'See Plans'**
  String get seePlansButton;

  /// No description provided for @paywallAskAdmin.
  ///
  /// In en, this message translates to:
  /// **'Only workspace owners and admins can change the plan. Ask one of them to upgrade.'**
  String get paywallAskAdmin;

  /// No description provided for @upgradeToPro.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro'**
  String get upgradeToPro;

  /// No description provided for @upgradeToProBody.
  ///
  /// In en, this message translates to:
  /// **'More bots, computer time and monthly credits.'**
  String get upgradeToProBody;

  /// No description provided for @manageTab.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manageTab;

  /// No description provided for @vitalsCpu.
  ///
  /// In en, this message translates to:
  /// **'CPU'**
  String get vitalsCpu;

  /// No description provided for @vitalsMemory.
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get vitalsMemory;

  /// No description provided for @vitalsDisk.
  ///
  /// In en, this message translates to:
  /// **'Disk'**
  String get vitalsDisk;

  /// No description provided for @fixItTitle.
  ///
  /// In en, this message translates to:
  /// **'Not working right?'**
  String get fixItTitle;

  /// No description provided for @fixItSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try these in order. Each one goes a bit further.'**
  String get fixItSubtitle;

  /// No description provided for @fixRestart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get fixRestart;

  /// No description provided for @fixRestartHelp.
  ///
  /// In en, this message translates to:
  /// **'About 20 seconds · nothing is lost'**
  String get fixRestartHelp;

  /// No description provided for @fixResetSystem.
  ///
  /// In en, this message translates to:
  /// **'Reset system'**
  String get fixResetSystem;

  /// No description provided for @fixResetSystemHelp.
  ///
  /// In en, this message translates to:
  /// **'A fresh system · your files stay'**
  String get fixResetSystemHelp;

  /// No description provided for @fixErase.
  ///
  /// In en, this message translates to:
  /// **'Erase everything'**
  String get fixErase;

  /// No description provided for @fixEraseHelp.
  ///
  /// In en, this message translates to:
  /// **'Like new · can be undone for 7 days'**
  String get fixEraseHelp;

  /// No description provided for @fixResetAction.
  ///
  /// In en, this message translates to:
  /// **'Reset…'**
  String get fixResetAction;

  /// No description provided for @fixEraseAction.
  ///
  /// In en, this message translates to:
  /// **'Erase…'**
  String get fixEraseAction;

  /// No description provided for @computerRestarting.
  ///
  /// In en, this message translates to:
  /// **'Restarting…'**
  String get computerRestarting;

  /// No description provided for @computerRestarted.
  ///
  /// In en, this message translates to:
  /// **'Restarted. Your files are all there.'**
  String get computerRestarted;

  /// No description provided for @computerUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get computerUpdateTitle;

  /// No description provided for @computerUpdateBody.
  ///
  /// In en, this message translates to:
  /// **'New tools and fixes are ready. Updating restarts this computer: your files stay, open windows and running programs close.'**
  String get computerUpdateBody;

  /// No description provided for @computerUpdateBotWorking.
  ///
  /// In en, this message translates to:
  /// **'A bot is working on this computer right now. Updating stops what it\'s doing.'**
  String get computerUpdateBotWorking;

  /// No description provided for @computerUpdateNow.
  ///
  /// In en, this message translates to:
  /// **'Update now'**
  String get computerUpdateNow;

  /// No description provided for @computerUpdateLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get computerUpdateLater;

  /// No description provided for @computerUpdateConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Update this computer?'**
  String get computerUpdateConfirmTitle;

  /// No description provided for @computerUpdateMenu.
  ///
  /// In en, this message translates to:
  /// **'Update computer'**
  String get computerUpdateMenu;

  /// No description provided for @computerUpdating.
  ///
  /// In en, this message translates to:
  /// **'Updating…'**
  String get computerUpdating;

  /// No description provided for @computerUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated. Your files are all there.'**
  String get computerUpdated;

  /// No description provided for @computerUpdateBusyTitle.
  ///
  /// In en, this message translates to:
  /// **'A command is still running'**
  String get computerUpdateBusyTitle;

  /// No description provided for @computerUpdateBusyBody.
  ///
  /// In en, this message translates to:
  /// **'Updating now stops it. Wait until it\'s done, or update anyway.'**
  String get computerUpdateBusyBody;

  /// No description provided for @computerUpdateAnyway.
  ///
  /// In en, this message translates to:
  /// **'Update anyway'**
  String get computerUpdateAnyway;

  /// No description provided for @resetSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset {name}'**
  String resetSheetTitle(String name);

  /// No description provided for @resetSheetBusy.
  ///
  /// In en, this message translates to:
  /// **'{bots} can\'t use it for about a minute.'**
  String resetSheetBusy(String bots);

  /// No description provided for @resetSheetBusyNone.
  ///
  /// In en, this message translates to:
  /// **'It can\'t be used for about a minute.'**
  String get resetSheetBusyNone;

  /// No description provided for @resetOptionSystem.
  ///
  /// In en, this message translates to:
  /// **'Reset system, keep my files'**
  String get resetOptionSystem;

  /// No description provided for @resetOptionSystemHelp.
  ///
  /// In en, this message translates to:
  /// **'Fixes broken installs, settings and stuck programs.'**
  String get resetOptionSystemHelp;

  /// No description provided for @resetOptionErase.
  ///
  /// In en, this message translates to:
  /// **'Erase everything'**
  String get resetOptionErase;

  /// No description provided for @resetOptionEraseHelp.
  ///
  /// In en, this message translates to:
  /// **'Back to a brand-new computer.'**
  String get resetOptionEraseHelp;

  /// No description provided for @resetKept.
  ///
  /// In en, this message translates to:
  /// **'Kept'**
  String get resetKept;

  /// No description provided for @resetRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed'**
  String get resetRemoved;

  /// No description provided for @resetKeptFiles.
  ///
  /// In en, this message translates to:
  /// **'Your files in workspace'**
  String get resetKeptFiles;

  /// No description provided for @resetKeptSettings.
  ///
  /// In en, this message translates to:
  /// **'Name, settings and bots'**
  String get resetKeptSettings;

  /// No description provided for @resetKeptRestorePoints.
  ///
  /// In en, this message translates to:
  /// **'Restore points'**
  String get resetKeptRestorePoints;

  /// No description provided for @resetRemovedApps.
  ///
  /// In en, this message translates to:
  /// **'Apps and tools you installed'**
  String get resetRemovedApps;

  /// No description provided for @resetRemovedPrograms.
  ///
  /// In en, this message translates to:
  /// **'Running programs'**
  String get resetRemovedPrograms;

  /// No description provided for @resetRemovedCaches.
  ///
  /// In en, this message translates to:
  /// **'Caches and home folder settings'**
  String get resetRemovedCaches;

  /// No description provided for @resetRemovedFiles.
  ///
  /// In en, this message translates to:
  /// **'Every file, workspace too'**
  String get resetRemovedFiles;

  /// No description provided for @resetSavePoint.
  ///
  /// In en, this message translates to:
  /// **'Save a restore point first'**
  String get resetSavePoint;

  /// No description provided for @resetSavePointHelp.
  ///
  /// In en, this message translates to:
  /// **'So you can undo this for 7 days'**
  String get resetSavePointHelp;

  /// No description provided for @eraseTypeName.
  ///
  /// In en, this message translates to:
  /// **'Type {name} to confirm'**
  String eraseTypeName(String name);

  /// No description provided for @resetConfirmSystem.
  ///
  /// In en, this message translates to:
  /// **'Reset system'**
  String get resetConfirmSystem;

  /// No description provided for @resetConfirmErase.
  ///
  /// In en, this message translates to:
  /// **'Erase everything'**
  String get resetConfirmErase;

  /// No description provided for @resetStepSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving a restore point'**
  String get resetStepSaving;

  /// No description provided for @resetStepWipingSystem.
  ///
  /// In en, this message translates to:
  /// **'Removing apps and settings'**
  String get resetStepWipingSystem;

  /// No description provided for @resetStepWipingErase.
  ///
  /// In en, this message translates to:
  /// **'Erasing every file'**
  String get resetStepWipingErase;

  /// No description provided for @resetStepRestarting.
  ///
  /// In en, this message translates to:
  /// **'Starting a fresh system'**
  String get resetStepRestarting;

  /// No description provided for @resettingStatus.
  ///
  /// In en, this message translates to:
  /// **'Resetting… {step} of {total}'**
  String resettingStatus(int step, int total);

  /// No description provided for @erasingStatus.
  ///
  /// In en, this message translates to:
  /// **'Erasing… {step} of {total}'**
  String erasingStatus(int step, int total);

  /// No description provided for @resetLeaveHint.
  ///
  /// In en, this message translates to:
  /// **'You can leave this screen. It keeps going on its own.'**
  String get resetLeaveHint;

  /// No description provided for @resetDone.
  ///
  /// In en, this message translates to:
  /// **'Fresh system ready'**
  String get resetDone;

  /// No description provided for @eraseDone.
  ///
  /// In en, this message translates to:
  /// **'Computer erased'**
  String get eraseDone;

  /// No description provided for @resetFailed.
  ///
  /// In en, this message translates to:
  /// **'The reset didn\'t finish'**
  String get resetFailed;

  /// No description provided for @resetUndoHint.
  ///
  /// In en, this message translates to:
  /// **'Undo puts everything back the way it was. The restore point stays for 7 days.'**
  String get resetUndoHint;

  /// No description provided for @restoredPrevious.
  ///
  /// In en, this message translates to:
  /// **'Put back the way it was'**
  String get restoredPrevious;

  /// No description provided for @usageThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get usageThisMonth;

  /// No description provided for @usageDuration.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} m'**
  String usageDuration(int hours, int minutes);

  /// No description provided for @usageCostNote.
  ///
  /// In en, this message translates to:
  /// **'Charged only while it\'s on. Asleep costs nothing.'**
  String get usageCostNote;

  /// No description provided for @usageNone.
  ///
  /// In en, this message translates to:
  /// **'Not used yet this month'**
  String get usageNone;

  /// No description provided for @sleepTimerTitle.
  ///
  /// In en, this message translates to:
  /// **'Goes to sleep after'**
  String get sleepTimerTitle;

  /// No description provided for @sleepTimerMinutes.
  ///
  /// In en, this message translates to:
  /// **'{n} min'**
  String sleepTimerMinutes(int n);

  /// No description provided for @sleepTimerHour.
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get sleepTimerHour;

  /// No description provided for @sleepTimerHelp.
  ///
  /// In en, this message translates to:
  /// **'Never while a bot is working or you\'re using it. A longer wait keeps it on longer, which costs more.'**
  String get sleepTimerHelp;

  /// No description provided for @sleepTimerSaved.
  ///
  /// In en, this message translates to:
  /// **'Sleeps after {label} without activity'**
  String sleepTimerSaved(String label);

  /// No description provided for @storageTitle.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get storageTitle;

  /// No description provided for @storageOf.
  ///
  /// In en, this message translates to:
  /// **'of {total}'**
  String storageOf(String total);

  /// No description provided for @storageFiles.
  ///
  /// In en, this message translates to:
  /// **'Your files'**
  String get storageFiles;

  /// No description provided for @storageApps.
  ///
  /// In en, this message translates to:
  /// **'Apps and tools'**
  String get storageApps;

  /// No description provided for @storageCaches.
  ///
  /// In en, this message translates to:
  /// **'Caches'**
  String get storageCaches;

  /// No description provided for @storageBrowser.
  ///
  /// In en, this message translates to:
  /// **'Browser'**
  String get storageBrowser;

  /// No description provided for @storageOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get storageOther;

  /// No description provided for @storageFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get storageFree;

  /// No description provided for @storageFreeUp.
  ///
  /// In en, this message translates to:
  /// **'Free up {size}'**
  String storageFreeUp(String size);

  /// No description provided for @storageNothingToClean.
  ///
  /// In en, this message translates to:
  /// **'No caches to clear'**
  String get storageNothingToClean;

  /// No description provided for @storageFreed.
  ///
  /// In en, this message translates to:
  /// **'Freed {size}'**
  String storageFreed(String size);

  /// No description provided for @storageAsleep.
  ///
  /// In en, this message translates to:
  /// **'Wake the computer to see what takes up space.'**
  String get storageAsleep;

  /// No description provided for @processesTitle.
  ///
  /// In en, this message translates to:
  /// **'Running now'**
  String get processesTitle;

  /// No description provided for @processesNone.
  ///
  /// In en, this message translates to:
  /// **'Nothing is running besides the computer itself.'**
  String get processesNone;

  /// No description provided for @processesAsleep.
  ///
  /// In en, this message translates to:
  /// **'Nothing runs while it sleeps.'**
  String get processesAsleep;

  /// No description provided for @processStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get processStop;

  /// No description provided for @processStopTitle.
  ///
  /// In en, this message translates to:
  /// **'Stop {name}?'**
  String processStopTitle(String name);

  /// No description provided for @processStopMessage.
  ///
  /// In en, this message translates to:
  /// **'Anything it hasn\'t saved is lost.'**
  String get processStopMessage;

  /// No description provided for @processStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped {name}'**
  String processStopped(String name);

  /// No description provided for @processLine.
  ///
  /// In en, this message translates to:
  /// **'{duration} · {cpu}% CPU · {memory}'**
  String processLine(String duration, String cpu, String memory);

  /// No description provided for @usedByTitle.
  ///
  /// In en, this message translates to:
  /// **'Used by'**
  String get usedByTitle;

  /// No description provided for @usedByNone.
  ///
  /// In en, this message translates to:
  /// **'No bot uses this computer yet.'**
  String get usedByNone;

  /// No description provided for @botLastActive.
  ///
  /// In en, this message translates to:
  /// **'Active {when}'**
  String botLastActive(String when);

  /// No description provided for @botNeverActive.
  ///
  /// In en, this message translates to:
  /// **'Not active yet'**
  String get botNeverActive;

  /// No description provided for @restorePointsTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore points'**
  String get restorePointsTitle;

  /// No description provided for @restorePointsNone.
  ///
  /// In en, this message translates to:
  /// **'None yet. Bots save one before risky changes.'**
  String get restorePointsNone;

  /// No description provided for @restorePointSaveNow.
  ///
  /// In en, this message translates to:
  /// **'Save a restore point now'**
  String get restorePointSaveNow;

  /// No description provided for @restorePointSaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Save a restore point'**
  String get restorePointSaveTitle;

  /// No description provided for @restorePointDefaultLabel.
  ///
  /// In en, this message translates to:
  /// **'Saved by hand'**
  String get restorePointDefaultLabel;

  /// No description provided for @restorePointSaved.
  ///
  /// In en, this message translates to:
  /// **'Restore point saved'**
  String get restorePointSaved;

  /// No description provided for @restorePointsShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show all {n}'**
  String restorePointsShowAll(int n);

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// No description provided for @historyNone.
  ///
  /// In en, this message translates to:
  /// **'Nothing has happened yet.'**
  String get historyNone;

  /// No description provided for @historyStarted.
  ///
  /// In en, this message translates to:
  /// **'Woke up'**
  String get historyStarted;

  /// No description provided for @historySlept.
  ///
  /// In en, this message translates to:
  /// **'Went to sleep'**
  String get historySlept;

  /// No description provided for @historySleptIdle.
  ///
  /// In en, this message translates to:
  /// **'Went to sleep (no activity)'**
  String get historySleptIdle;

  /// No description provided for @historyRestarted.
  ///
  /// In en, this message translates to:
  /// **'Restarted'**
  String get historyRestarted;

  /// No description provided for @historyReset.
  ///
  /// In en, this message translates to:
  /// **'Reset the system'**
  String get historyReset;

  /// No description provided for @historyErased.
  ///
  /// In en, this message translates to:
  /// **'Erased everything'**
  String get historyErased;

  /// No description provided for @historyCheckpointCreated.
  ///
  /// In en, this message translates to:
  /// **'Saved a restore point'**
  String get historyCheckpointCreated;

  /// No description provided for @historyCheckpointRestored.
  ///
  /// In en, this message translates to:
  /// **'Restored a restore point'**
  String get historyCheckpointRestored;

  /// No description provided for @historyStorageCleaned.
  ///
  /// In en, this message translates to:
  /// **'Freed up {size}'**
  String historyStorageCleaned(String size);

  /// No description provided for @historyStorageCleanedPlain.
  ///
  /// In en, this message translates to:
  /// **'Freed up space'**
  String get historyStorageCleanedPlain;

  /// No description provided for @historyProcessStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped {name}'**
  String historyProcessStopped(String name);

  /// No description provided for @historyUpdated.
  ///
  /// In en, this message translates to:
  /// **'Changed its settings'**
  String get historyUpdated;

  /// No description provided for @historyYou.
  ///
  /// In en, this message translates to:
  /// **'you'**
  String get historyYou;

  /// No description provided for @yourDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Your data'**
  String get yourDataTitle;

  /// No description provided for @downloadAllFiles.
  ///
  /// In en, this message translates to:
  /// **'Download all files'**
  String get downloadAllFiles;

  /// No description provided for @downloadAllFilesHelp.
  ///
  /// In en, this message translates to:
  /// **'A .zip of everything in workspace'**
  String get downloadAllFilesHelp;

  /// No description provided for @downloadNothing.
  ///
  /// In en, this message translates to:
  /// **'There are no files to download yet.'**
  String get downloadNothing;

  /// No description provided for @deleteComputerHelp.
  ///
  /// In en, this message translates to:
  /// **'Removes it and its restore points'**
  String get deleteComputerHelp;

  /// No description provided for @manageComputer.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manageComputer;

  /// No description provided for @restartComputer.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get restartComputer;

  /// No description provided for @resetComputerMenu.
  ///
  /// In en, this message translates to:
  /// **'Reset…'**
  String get resetComputerMenu;

  /// No description provided for @moreFixes.
  ///
  /// In en, this message translates to:
  /// **'More fixes'**
  String get moreFixes;

  /// No description provided for @durationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{n} min'**
  String durationMinutes(int n);

  /// No description provided for @durationHours.
  ///
  /// In en, this message translates to:
  /// **'{n} h'**
  String durationHours(int n);

  /// No description provided for @durationDays.
  ///
  /// In en, this message translates to:
  /// **'{n} d'**
  String durationDays(int n);

  /// No description provided for @remoteUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'Time to update Casama'**
  String get remoteUpdateTitle;

  /// No description provided for @remoteUpdateBody.
  ///
  /// In en, this message translates to:
  /// **'This version of Casama is no longer supported. Update it to keep going.'**
  String get remoteUpdateBody;

  /// No description provided for @remoteUpdateNoLink.
  ///
  /// In en, this message translates to:
  /// **'This version of Casama is no longer supported. Update it from where you installed it.'**
  String get remoteUpdateNoLink;

  /// No description provided for @remoteMaintenanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Casama is down for maintenance'**
  String get remoteMaintenanceTitle;

  /// No description provided for @openLink.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openLink;

  /// No description provided for @routineIdeas.
  ///
  /// In en, this message translates to:
  /// **'Ideas'**
  String get routineIdeas;

  /// No description provided for @routineIdeasHelp.
  ///
  /// In en, this message translates to:
  /// **'Start from an idea, then change anything.'**
  String get routineIdeasHelp;

  /// No description provided for @pluginDirectory.
  ///
  /// In en, this message translates to:
  /// **'Reviewed plugins'**
  String get pluginDirectory;

  /// No description provided for @pluginDirectoryHelp.
  ///
  /// In en, this message translates to:
  /// **'Checked by Casama and pinned to the version that was checked.'**
  String get pluginDirectoryHelp;

  /// No description provided for @pluginOrPaste.
  ///
  /// In en, this message translates to:
  /// **'Or add one from a GitHub link'**
  String get pluginOrPaste;

  /// No description provided for @byAuthor.
  ///
  /// In en, this message translates to:
  /// **'By {name}'**
  String byAuthor(String name);

  /// No description provided for @adminAppSettings.
  ///
  /// In en, this message translates to:
  /// **'App settings'**
  String get adminAppSettings;

  /// No description provided for @adminAppSettingsHelp.
  ///
  /// In en, this message translates to:
  /// **'Minimum versions, maintenance, announcements, feature switches and links for every app, with no release.'**
  String get adminAppSettingsHelp;

  /// No description provided for @adminAppSettingsBadJson.
  ///
  /// In en, this message translates to:
  /// **'That isn\'t valid JSON. Check the brackets, quotes and commas.'**
  String get adminAppSettingsBadJson;

  /// No description provided for @adminEmailCopy.
  ///
  /// In en, this message translates to:
  /// **'Email words'**
  String get adminEmailCopy;

  /// No description provided for @adminEmailCopyHelp.
  ///
  /// In en, this message translates to:
  /// **'The welcome emails and the monthly gallery picks, in your words. Leave a field out to use Casama\'s.'**
  String get adminEmailCopyHelp;

  /// No description provided for @adminModelCatalog.
  ///
  /// In en, this message translates to:
  /// **'Model catalog'**
  String get adminModelCatalog;

  /// No description provided for @adminModelCatalogHelp.
  ///
  /// In en, this message translates to:
  /// **'Default, small, featured and test models, model prices and image prices. Anything left out uses the built-in value.'**
  String get adminModelCatalogHelp;

  /// No description provided for @adminCostTables.
  ///
  /// In en, this message translates to:
  /// **'Cost tables'**
  String get adminCostTables;

  /// No description provided for @adminCostTablesHelp.
  ///
  /// In en, this message translates to:
  /// **'What voice, calls, computers and media cost, and which domains are sold. Billing uses them within a minute.'**
  String get adminCostTablesHelp;

  /// No description provided for @adminGuardSites.
  ///
  /// In en, this message translates to:
  /// **'Browser guard sites'**
  String get adminGuardSites;

  /// No description provided for @adminGuardSitesHelp.
  ///
  /// In en, this message translates to:
  /// **'Sites Casama for Chrome and bots\' browsers keep out, on top of the built-in list. You can only add to it.'**
  String get adminGuardSitesHelp;

  /// No description provided for @adminBuiltInValues.
  ///
  /// In en, this message translates to:
  /// **'Built-in values'**
  String get adminBuiltInValues;

  /// No description provided for @adminCallLimits.
  ///
  /// In en, this message translates to:
  /// **'Call limits'**
  String get adminCallLimits;

  /// No description provided for @adminCallLimitsHelp.
  ///
  /// In en, this message translates to:
  /// **'Silence before a call hangs up, the longest call, warnings before a limit, and how often bots may ring someone. Values left out use the built-in ones.'**
  String get adminCallLimitsHelp;

  /// No description provided for @paywallBillingPeriod.
  ///
  /// In en, this message translates to:
  /// **'Billing period'**
  String get paywallBillingPeriod;

  /// No description provided for @paywallNotSoldTitle.
  ///
  /// In en, this message translates to:
  /// **'No plans on this server'**
  String get paywallNotSoldTitle;

  /// No description provided for @paywallNotSoldBody.
  ///
  /// In en, this message translates to:
  /// **'This server doesn\'t sell plans, so there\'s nothing to upgrade here.'**
  String get paywallNotSoldBody;

  /// No description provided for @paywallPlansFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Plans didn\'t load'**
  String get paywallPlansFailedTitle;

  /// No description provided for @paywallPlansFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Check your connection, then try again.'**
  String get paywallPlansFailedBody;

  /// No description provided for @paywallStoreEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'{store, select, app_store{The App Store} google_play{Google Play} other{The store}} isn\'t showing plans'**
  String paywallStoreEmptyTitle(String store);

  /// No description provided for @paywallStoreEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Make sure you\'re signed in to {store, select, app_store{the App Store} google_play{Google Play} other{the store}} on this device, then try again.'**
  String paywallStoreEmptyBody(String store);

  /// No description provided for @paywallSaveUpTo.
  ///
  /// In en, this message translates to:
  /// **'Save up to {pct}%'**
  String paywallSaveUpTo(int pct);

  /// No description provided for @paywallMostPopular.
  ///
  /// In en, this message translates to:
  /// **'Most popular'**
  String get paywallMostPopular;

  /// No description provided for @paywallTaglinePlus.
  ///
  /// In en, this message translates to:
  /// **'For you and a handful of bots'**
  String get paywallTaglinePlus;

  /// No description provided for @paywallTaglinePro.
  ///
  /// In en, this message translates to:
  /// **'For a busy crew and a small team'**
  String get paywallTaglinePro;

  /// No description provided for @paywallTaglineMax.
  ///
  /// In en, this message translates to:
  /// **'For teams with bots working all day'**
  String get paywallTaglineMax;

  /// No description provided for @paywallPerMonthShort.
  ///
  /// In en, this message translates to:
  /// **'/mo'**
  String get paywallPerMonthShort;

  /// No description provided for @paywallBilledYearly.
  ///
  /// In en, this message translates to:
  /// **'{price} billed yearly'**
  String paywallBilledYearly(String price);

  /// No description provided for @paywallWorksOutTo.
  ///
  /// In en, this message translates to:
  /// **'Works out to {price}/mo'**
  String paywallWorksOutTo(String price);

  /// No description provided for @paywallBilledMonthly.
  ///
  /// In en, this message translates to:
  /// **'Billed monthly'**
  String get paywallBilledMonthly;

  /// No description provided for @paywallBilledWeekly.
  ///
  /// In en, this message translates to:
  /// **'Billed weekly'**
  String get paywallBilledWeekly;

  /// No description provided for @paywallPerWeekShort.
  ///
  /// In en, this message translates to:
  /// **'/wk'**
  String get paywallPerWeekShort;

  /// No description provided for @paywallPerWeekWorksOut.
  ///
  /// In en, this message translates to:
  /// **'That\'s {price} a week'**
  String paywallPerWeekWorksOut(String price);

  /// No description provided for @paywallBilledYearlyPlain.
  ///
  /// In en, this message translates to:
  /// **'Billed yearly'**
  String get paywallBilledYearlyPlain;

  /// No description provided for @paywallPerYearShort.
  ///
  /// In en, this message translates to:
  /// **'/yr'**
  String get paywallPerYearShort;

  /// No description provided for @paywallStartTrial.
  ///
  /// In en, this message translates to:
  /// **'Start {n}-day free trial'**
  String paywallStartTrial(int n);

  /// No description provided for @paywallGetPlan.
  ///
  /// In en, this message translates to:
  /// **'Get {plan}'**
  String paywallGetPlan(String plan);

  /// No description provided for @paywallPeople.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 person} other{{count} people}}'**
  String paywallPeople(int count);

  /// No description provided for @paywallFactHours.
  ///
  /// In en, this message translates to:
  /// **'{hours} computer hours'**
  String paywallFactHours(int hours);

  /// No description provided for @billingChangePlan.
  ///
  /// In en, this message translates to:
  /// **'Change plan'**
  String get billingChangePlan;

  /// No description provided for @billingChangePlanBody.
  ///
  /// In en, this message translates to:
  /// **'Compare every plan, monthly or yearly.'**
  String get billingChangePlanBody;

  /// No description provided for @paywallWhatYouGet.
  ///
  /// In en, this message translates to:
  /// **'What {plan} gets you'**
  String paywallWhatYouGet(String plan);

  /// No description provided for @adminPricing.
  ///
  /// In en, this message translates to:
  /// **'Pricing'**
  String get adminPricing;

  /// No description provided for @adminCreditPacks.
  ///
  /// In en, this message translates to:
  /// **'Credit packs'**
  String get adminCreditPacks;

  /// No description provided for @adminOnSale.
  ///
  /// In en, this message translates to:
  /// **'On sale'**
  String get adminOnSale;

  /// No description provided for @adminHidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get adminHidden;

  /// No description provided for @adminNoPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'No price label'**
  String get adminNoPriceLabel;

  /// No description provided for @adminPlanSaveHelp.
  ///
  /// In en, this message translates to:
  /// **'Saving applies to every workspace on this plan straight away.'**
  String get adminPlanSaveHelp;

  /// No description provided for @adminPackSaveHelp.
  ///
  /// In en, this message translates to:
  /// **'Saving changes the pack for everyone straight away.'**
  String get adminPackSaveHelp;

  /// No description provided for @adminPlanName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get adminPlanName;

  /// No description provided for @adminPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price label'**
  String get adminPriceLabel;

  /// No description provided for @adminPriceLabelHelp.
  ///
  /// In en, this message translates to:
  /// **'Shown where the store has no price of its own'**
  String get adminPriceLabelHelp;

  /// No description provided for @adminPlanActiveHelp.
  ///
  /// In en, this message translates to:
  /// **'A hidden plan stays with the workspaces already on it.'**
  String get adminPlanActiveHelp;

  /// No description provided for @adminCreditGate.
  ///
  /// In en, this message translates to:
  /// **'Stop at zero credits'**
  String get adminCreditGate;

  /// No description provided for @adminCreditGateHelp.
  ///
  /// In en, this message translates to:
  /// **'Runs on Casama\'s keys stop when the workspace\'s credits run out.'**
  String get adminCreditGateHelp;

  /// No description provided for @adminPaywallDefault.
  ///
  /// In en, this message translates to:
  /// **'Paywall opens here'**
  String get adminPaywallDefault;

  /// No description provided for @adminPaywallDefaultHelp.
  ///
  /// In en, this message translates to:
  /// **'Free workspaces start on this plan, and everyone starts on its billing period. Only one plan at a time.'**
  String get adminPaywallDefaultHelp;

  /// No description provided for @adminPaywallPopular.
  ///
  /// In en, this message translates to:
  /// **'Most popular'**
  String get adminPaywallPopular;

  /// No description provided for @adminPaywallPopularHelp.
  ///
  /// In en, this message translates to:
  /// **'Shows the Most popular badge on this plan\'s tier.'**
  String get adminPaywallPopularHelp;

  /// No description provided for @adminPlanSort.
  ///
  /// In en, this message translates to:
  /// **'Sort order'**
  String get adminPlanSort;

  /// No description provided for @adminPlanLimits.
  ///
  /// In en, this message translates to:
  /// **'Limits'**
  String get adminPlanLimits;

  /// No description provided for @adminLimitMonthlyCredits.
  ///
  /// In en, this message translates to:
  /// **'Monthly credits (USD)'**
  String get adminLimitMonthlyCredits;

  /// No description provided for @adminLimitMaxBots.
  ///
  /// In en, this message translates to:
  /// **'Bots'**
  String get adminLimitMaxBots;

  /// No description provided for @adminLimitMaxComputers.
  ///
  /// In en, this message translates to:
  /// **'Computers'**
  String get adminLimitMaxComputers;

  /// No description provided for @adminLimitComputerHours.
  ///
  /// In en, this message translates to:
  /// **'Computer hours a month'**
  String get adminLimitComputerHours;

  /// No description provided for @adminLimitSeats.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get adminLimitSeats;

  /// No description provided for @adminLimitCloudDaily.
  ///
  /// In en, this message translates to:
  /// **'Cloud spend a day (USD)'**
  String get adminLimitCloudDaily;

  /// No description provided for @adminLimitMaxRunning.
  ///
  /// In en, this message translates to:
  /// **'Computers running at once'**
  String get adminLimitMaxRunning;

  /// No description provided for @adminLimitComputerSize.
  ///
  /// In en, this message translates to:
  /// **'Computer size (vCPUs and GB)'**
  String get adminLimitComputerSize;

  /// No description provided for @adminLimitExtraSeat.
  ///
  /// In en, this message translates to:
  /// **'Extra person a month (USD)'**
  String get adminLimitExtraSeat;

  /// No description provided for @adminLimitTrialDays.
  ///
  /// In en, this message translates to:
  /// **'Trial days'**
  String get adminLimitTrialDays;

  /// No description provided for @adminLimitTrialCredits.
  ///
  /// In en, this message translates to:
  /// **'Trial credits (USD)'**
  String get adminLimitTrialCredits;

  /// No description provided for @adminLimitTrialHours.
  ///
  /// In en, this message translates to:
  /// **'Trial computer hours'**
  String get adminLimitTrialHours;

  /// No description provided for @adminLimitMailAddresses.
  ///
  /// In en, this message translates to:
  /// **'Bot email addresses'**
  String get adminLimitMailAddresses;

  /// No description provided for @adminLimitMailNewDay.
  ///
  /// In en, this message translates to:
  /// **'Mail to new people, a day'**
  String get adminLimitMailNewDay;

  /// No description provided for @adminLimitMailSentDay.
  ///
  /// In en, this message translates to:
  /// **'Mail sent, a day'**
  String get adminLimitMailSentDay;

  /// No description provided for @adminLimitMailStorage.
  ///
  /// In en, this message translates to:
  /// **'Mailbox size, MB'**
  String get adminLimitMailStorage;

  /// No description provided for @adminAddLimit.
  ///
  /// In en, this message translates to:
  /// **'Add a limit'**
  String get adminAddLimit;

  /// No description provided for @adminLimitKey.
  ///
  /// In en, this message translates to:
  /// **'Limit key'**
  String get adminLimitKey;

  /// No description provided for @adminLimitKeyInvalid.
  ///
  /// In en, this message translates to:
  /// **'Use lowercase letters, digits and underscores'**
  String get adminLimitKeyInvalid;

  /// No description provided for @adminLimitValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get adminLimitValue;

  /// No description provided for @adminStoreProducts.
  ///
  /// In en, this message translates to:
  /// **'Store products'**
  String get adminStoreProducts;

  /// No description provided for @adminAppStoreId.
  ///
  /// In en, this message translates to:
  /// **'App Store product id'**
  String get adminAppStoreId;

  /// No description provided for @adminGooglePlayId.
  ///
  /// In en, this message translates to:
  /// **'Google Play product id'**
  String get adminGooglePlayId;

  /// No description provided for @adminDodoId.
  ///
  /// In en, this message translates to:
  /// **'Dodo product id'**
  String get adminDodoId;

  /// No description provided for @adminPackCredits.
  ///
  /// In en, this message translates to:
  /// **'Credits (USD)'**
  String get adminPackCredits;

  /// No description provided for @adminMarkup.
  ///
  /// In en, this message translates to:
  /// **'Usage markup'**
  String get adminMarkup;

  /// No description provided for @adminMarkupValue.
  ///
  /// In en, this message translates to:
  /// **'×{markup}'**
  String adminMarkupValue(String markup);

  /// No description provided for @adminMarkupHelp.
  ///
  /// In en, this message translates to:
  /// **'1.3 = charge 30% over what Casama pays'**
  String get adminMarkupHelp;

  /// No description provided for @adminMarkupTooLow.
  ///
  /// In en, this message translates to:
  /// **'Use 1 or more. 1 charges exactly what Casama pays.'**
  String get adminMarkupTooLow;

  /// No description provided for @adminNumberInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a number of 0 or more'**
  String get adminNumberInvalid;

  /// No description provided for @adminNumberPositive.
  ///
  /// In en, this message translates to:
  /// **'Enter a number above 0'**
  String get adminNumberPositive;

  /// No description provided for @adminWholeNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a whole number'**
  String get adminWholeNumber;

  /// No description provided for @adminNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get adminNameRequired;

  /// No description provided for @adminPricingBillingOff.
  ///
  /// In en, this message translates to:
  /// **'Billing is off on this server. These prices apply once it\'s on.'**
  String get adminPricingBillingOff;

  /// No description provided for @updatesRow.
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get updatesRow;

  /// No description provided for @updatesRowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'News from your workspace'**
  String get updatesRowSubtitle;

  /// No description provided for @updatesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No updates'**
  String get updatesEmpty;

  /// No description provided for @updatesEmptyHelp.
  ///
  /// In en, this message translates to:
  /// **'Workspace notices and new pages show up here. What your bots send you is in their chats.'**
  String get updatesEmptyHelp;

  /// No description provided for @chatsNeedsYou.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 thing needs you} other{{n} things need you}}'**
  String chatsNeedsYou(int n);

  /// No description provided for @suggestionInTopic.
  ///
  /// In en, this message translates to:
  /// **'Working on it: {title}'**
  String suggestionInTopic(String title);

  /// No description provided for @suggestionClosed.
  ///
  /// In en, this message translates to:
  /// **'Not now: {title}'**
  String suggestionClosed(String title);

  /// No description provided for @openTopic.
  ///
  /// In en, this message translates to:
  /// **'Open {title}'**
  String openTopic(String title);

  /// No description provided for @newTopic.
  ///
  /// In en, this message translates to:
  /// **'New topic'**
  String get newTopic;

  /// No description provided for @topics.
  ///
  /// In en, this message translates to:
  /// **'Topics'**
  String get topics;

  /// No description provided for @olderTopics.
  ///
  /// In en, this message translates to:
  /// **'Older'**
  String get olderTopics;

  /// No description provided for @generalChat.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get generalChat;

  /// No description provided for @allTopics.
  ///
  /// In en, this message translates to:
  /// **'All topics'**
  String get allTopics;

  /// No description provided for @cardSecrets.
  ///
  /// In en, this message translates to:
  /// **'Secrets'**
  String get cardSecrets;

  /// No description provided for @cardApproval.
  ///
  /// In en, this message translates to:
  /// **'Approval'**
  String get cardApproval;

  /// No description provided for @cardTakeover.
  ///
  /// In en, this message translates to:
  /// **'Take over'**
  String get cardTakeover;

  /// No description provided for @cardDevice.
  ///
  /// In en, this message translates to:
  /// **'Device access'**
  String get cardDevice;

  /// No description provided for @cardSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Suggestion'**
  String get cardSuggestion;

  /// No description provided for @formNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get formNext;

  /// No description provided for @formSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get formSkip;

  /// No description provided for @formStep.
  ///
  /// In en, this message translates to:
  /// **'Question {n} of {total}'**
  String formStep(int n, int total);

  /// No description provided for @cardSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get cardSuggestions;

  /// No description provided for @suggestionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Found {n} things worth a look'**
  String suggestionsTitle(int n);

  /// No description provided for @suggestionStarted.
  ///
  /// In en, this message translates to:
  /// **'Started {when}'**
  String suggestionStarted(String when);

  /// No description provided for @suggestionStartedPlain.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get suggestionStartedPlain;

  /// No description provided for @suggestionPutAway.
  ///
  /// In en, this message translates to:
  /// **'Put away'**
  String get suggestionPutAway;

  /// No description provided for @suggestionExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get suggestionExpired;

  /// No description provided for @suggestionExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Expired: {title}'**
  String suggestionExpiredTitle(String title);

  /// No description provided for @suggestionsHandled.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 suggestion handled} other{{n} suggestions handled}}'**
  String suggestionsHandled(int n);

  /// No description provided for @casamaLink.
  ///
  /// In en, this message translates to:
  /// **'Casama Link'**
  String get casamaLink;

  /// No description provided for @linkRow.
  ///
  /// In en, this message translates to:
  /// **'Use this server on your phone'**
  String get linkRow;

  /// No description provided for @linkIntro.
  ///
  /// In en, this message translates to:
  /// **'Give this server an address your phone can reach from anywhere. No domain and no router settings.'**
  String get linkIntro;

  /// No description provided for @linkIntroDetails.
  ///
  /// In en, this message translates to:
  /// **'It links this server to a free Casama Cloud account. Your phone\'s traffic goes through Cloudflare straight to this computer, never through Casama\'s servers.'**
  String get linkIntroDetails;

  /// No description provided for @linkTurnOn.
  ///
  /// In en, this message translates to:
  /// **'Use on Your Phone'**
  String get linkTurnOn;

  /// No description provided for @linkSignupsNote.
  ///
  /// In en, this message translates to:
  /// **'New sign-ups close while it is on. Only people who already have an account here can sign in.'**
  String get linkSignupsNote;

  /// No description provided for @linkStepSignIn.
  ///
  /// In en, this message translates to:
  /// **'Link this server'**
  String get linkStepSignIn;

  /// No description provided for @linkSignInBody.
  ///
  /// In en, this message translates to:
  /// **'Approve this code on the page that just opened in your browser. Check that the page shows the same code.'**
  String get linkSignInBody;

  /// No description provided for @linkSignInOpen.
  ///
  /// In en, this message translates to:
  /// **'Open the Page Again'**
  String get linkSignInOpen;

  /// No description provided for @linkStepAddress.
  ///
  /// In en, this message translates to:
  /// **'Get an address'**
  String get linkStepAddress;

  /// No description provided for @linkStepRestart.
  ///
  /// In en, this message translates to:
  /// **'Restart the server'**
  String get linkStepRestart;

  /// No description provided for @linkStepConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get linkStepConnect;

  /// No description provided for @linkStateOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get linkStateOnline;

  /// No description provided for @linkStateStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting'**
  String get linkStateStarting;

  /// No description provided for @linkStateOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get linkStateOffline;

  /// No description provided for @linkStateAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get linkStateAttention;

  /// No description provided for @linkStateOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get linkStateOff;

  /// No description provided for @linkAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get linkAddress;

  /// No description provided for @linkLocalAddress.
  ///
  /// In en, this message translates to:
  /// **'On this computer'**
  String get linkLocalAddress;

  /// No description provided for @linkShowCode.
  ///
  /// In en, this message translates to:
  /// **'Show Sign-In Code'**
  String get linkShowCode;

  /// No description provided for @linkCheck.
  ///
  /// In en, this message translates to:
  /// **'Check Again'**
  String get linkCheck;

  /// No description provided for @linkTurnOff.
  ///
  /// In en, this message translates to:
  /// **'Turn Off'**
  String get linkTurnOff;

  /// No description provided for @linkTurnOffConfirm.
  ///
  /// In en, this message translates to:
  /// **'Turn off remote access? The address stops working, and phones lose this server until you turn it on again. It gets the same address back.'**
  String get linkTurnOffConfirm;

  /// No description provided for @linkTurningOff.
  ///
  /// In en, this message translates to:
  /// **'Turning off'**
  String get linkTurningOff;

  /// No description provided for @linkNeedsOwner.
  ///
  /// In en, this message translates to:
  /// **'Only this server\'s owner can turn this on.'**
  String get linkNeedsOwner;

  /// No description provided for @linkTwoStepTip.
  ///
  /// In en, this message translates to:
  /// **'This server can now be reached from the internet. Two-step sign-in means a guessed password isn\'t enough.'**
  String get linkTwoStepTip;

  /// No description provided for @linkProblemNotLinked.
  ///
  /// In en, this message translates to:
  /// **'This server isn\'t linked to Casama Cloud. Turn it on again to link it.'**
  String get linkProblemNotLinked;

  /// No description provided for @linkProblemCloudUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Casama Cloud can\'t be reached right now. If the address was working, it still is.'**
  String get linkProblemCloudUnreachable;

  /// No description provided for @linkProblemKeyRejected.
  ///
  /// In en, this message translates to:
  /// **'Casama Cloud no longer accepts this server\'s key. Turn it on again to link it.'**
  String get linkProblemKeyRejected;

  /// No description provided for @linkProblemSuspended.
  ///
  /// In en, this message translates to:
  /// **'Casama Cloud turned remote access off for this server.'**
  String get linkProblemSuspended;

  /// No description provided for @linkProblemRemoved.
  ///
  /// In en, this message translates to:
  /// **'This server was removed from its workspace in Casama Cloud. Turn it on again to link it.'**
  String get linkProblemRemoved;

  /// No description provided for @linkProblemPlanLimit.
  ///
  /// In en, this message translates to:
  /// **'Your Casama Cloud plan connects fewer servers. Remove one there, or upgrade.'**
  String get linkProblemPlanLimit;

  /// No description provided for @linkProblemUnknownServer.
  ///
  /// In en, this message translates to:
  /// **'Casama Cloud has no address for this server any more. Turn it on again.'**
  String get linkProblemUnknownServer;

  /// No description provided for @linkProblemAddressChanged.
  ///
  /// In en, this message translates to:
  /// **'This server\'s address changed. Turn it on again to use the new one.'**
  String get linkProblemAddressChanged;

  /// No description provided for @connectProblemConnectorMissing.
  ///
  /// In en, this message translates to:
  /// **'The connector isn\'t running. Check that Docker is running, then check again.'**
  String get connectProblemConnectorMissing;

  /// No description provided for @connectProblemConnectorBlocked.
  ///
  /// In en, this message translates to:
  /// **'This network blocks the connection. A VPN or a strict firewall is the usual cause (outbound port 7844).'**
  String get connectProblemConnectorBlocked;

  /// No description provided for @linkProblemAddressUnanswered.
  ///
  /// In en, this message translates to:
  /// **'Everything is connected, but the address doesn\'t answer yet. A new address can take a minute.'**
  String get linkProblemAddressUnanswered;

  /// No description provided for @linkServers.
  ///
  /// In en, this message translates to:
  /// **'Linked Servers'**
  String get linkServers;

  /// No description provided for @linkServersHelp.
  ///
  /// In en, this message translates to:
  /// **'{limit, plural, =1{Your plan connects 1 server.} other{Your plan connects {limit} servers.}}'**
  String linkServersHelp(int limit);

  /// No description provided for @linkServersNone.
  ///
  /// In en, this message translates to:
  /// **'No servers linked yet. On your own server, open Settings, then Casama Link.'**
  String get linkServersNone;

  /// No description provided for @linkServerRemoveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}? Its address stops working. The server can be linked again later.'**
  String linkServerRemoveConfirm(String name);

  /// No description provided for @linkStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Has an address'**
  String get linkStatusActive;

  /// No description provided for @linkStatusParked.
  ///
  /// In en, this message translates to:
  /// **'Not seen lately'**
  String get linkStatusParked;

  /// No description provided for @linkStatusSuspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get linkStatusSuspended;

  /// No description provided for @pairDevice.
  ///
  /// In en, this message translates to:
  /// **'Sign In on Another Device'**
  String get pairDevice;

  /// No description provided for @pairDeviceRow.
  ///
  /// In en, this message translates to:
  /// **'Show a code your phone scans'**
  String get pairDeviceRow;

  /// No description provided for @pairDeviceHelp.
  ///
  /// In en, this message translates to:
  /// **'Scan this with your phone\'s camera. Or in Casama on the phone: Sign in, then Scan a code.'**
  String get pairDeviceHelp;

  /// No description provided for @pairDeviceWarning.
  ///
  /// In en, this message translates to:
  /// **'Anyone who scans it is signed in as you. It works once, for a few minutes.'**
  String get pairDeviceWarning;

  /// No description provided for @pairDeviceServer.
  ///
  /// In en, this message translates to:
  /// **'Signs in to {host}'**
  String pairDeviceServer(String host);

  /// No description provided for @pairDeviceNewCode.
  ///
  /// In en, this message translates to:
  /// **'New Code'**
  String get pairDeviceNewCode;

  /// No description provided for @pairDeviceExpired.
  ///
  /// In en, this message translates to:
  /// **'This code ran out.'**
  String get pairDeviceExpired;

  /// No description provided for @pairDeviceNotReachable.
  ///
  /// In en, this message translates to:
  /// **'This server only answers on this computer, so a phone can\'t reach it yet.'**
  String get pairDeviceNotReachable;

  /// No description provided for @pairDeviceNotReachableOther.
  ///
  /// In en, this message translates to:
  /// **'This server\'s address only works on its own network. Ask whoever runs it for an address others can reach.'**
  String get pairDeviceNotReachableOther;

  /// No description provided for @pairDeviceCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy Link'**
  String get pairDeviceCopyLink;

  /// No description provided for @pairDeviceLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied. Paste it into Casama for Chrome or on another device.'**
  String get pairDeviceLinkCopied;

  /// No description provided for @pairDeviceConnectChrome.
  ///
  /// In en, this message translates to:
  /// **'Connect Chrome'**
  String get pairDeviceConnectChrome;

  /// No description provided for @pairDeviceChromeDone.
  ///
  /// In en, this message translates to:
  /// **'Casama for Chrome is signed in.'**
  String get pairDeviceChromeDone;

  /// No description provided for @pairDeviceChromeFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish in the Casama for Chrome tab that opened.'**
  String get pairDeviceChromeFinish;

  /// No description provided for @pairDeviceChromeMissing.
  ///
  /// In en, this message translates to:
  /// **'Casama for Chrome isn\'t installed in this browser.'**
  String get pairDeviceChromeMissing;

  /// No description provided for @pairDeviceChromeFailed.
  ///
  /// In en, this message translates to:
  /// **'Casama for Chrome couldn\'t sign in. {error}'**
  String pairDeviceChromeFailed(String error);

  /// No description provided for @scanToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Scan a Code from Your Computer'**
  String get scanToSignIn;

  /// No description provided for @scanToSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan the Code'**
  String get scanToSignInTitle;

  /// No description provided for @scanToSignInHelp.
  ///
  /// In en, this message translates to:
  /// **'On a computer where you\'re signed in, open Settings, then Sign In on Another Device.'**
  String get scanToSignInHelp;

  /// No description provided for @pairSignInTo.
  ///
  /// In en, this message translates to:
  /// **'Sign in to {host}?'**
  String pairSignInTo(String host);

  /// No description provided for @pairSignInBody.
  ///
  /// In en, this message translates to:
  /// **'The code signs this device in to the account that showed it.'**
  String get pairSignInBody;

  /// No description provided for @pairSwitchServerBody.
  ///
  /// In en, this message translates to:
  /// **'This device uses {current} now. Signing in to {host} switches it over.'**
  String pairSwitchServerBody(String current, String host);

  /// No description provided for @pairSigningIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in'**
  String get pairSigningIn;

  /// No description provided for @pairCodeInvalid.
  ///
  /// In en, this message translates to:
  /// **'That code isn\'t valid any more. Show a new one and scan again.'**
  String get pairCodeInvalid;

  /// No description provided for @pairLinkInvalid.
  ///
  /// In en, this message translates to:
  /// **'This isn\'t a Casama sign-in code.'**
  String get pairLinkInvalid;

  /// No description provided for @linkServerTitle.
  ///
  /// In en, this message translates to:
  /// **'Link a Server'**
  String get linkServerTitle;

  /// No description provided for @linkServerBody.
  ///
  /// In en, this message translates to:
  /// **'{name} wants to connect to your Casama Cloud account.'**
  String linkServerBody(String name);

  /// No description provided for @linkServerCode.
  ///
  /// In en, this message translates to:
  /// **'Code on the server'**
  String get linkServerCode;

  /// No description provided for @linkServerCheck.
  ///
  /// In en, this message translates to:
  /// **'Only link it if you started this on your own server and it shows this same code.'**
  String get linkServerCheck;

  /// No description provided for @linkServerWhat.
  ///
  /// In en, this message translates to:
  /// **'It gets a public address and can send you notifications. It can\'t spend your credits.'**
  String get linkServerWhat;

  /// No description provided for @linkServerApprove.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get linkServerApprove;

  /// No description provided for @linkServerDone.
  ///
  /// In en, this message translates to:
  /// **'Linked'**
  String get linkServerDone;

  /// No description provided for @linkServerDoneBody.
  ///
  /// In en, this message translates to:
  /// **'Go back to {name}. It carries on by itself.'**
  String linkServerDoneBody(String name);

  /// No description provided for @linkServerInvalid.
  ///
  /// In en, this message translates to:
  /// **'That code isn\'t valid any more. Start again on your server.'**
  String get linkServerInvalid;

  /// No description provided for @linkServerEnterCode.
  ///
  /// In en, this message translates to:
  /// **'The code your server shows'**
  String get linkServerEnterCode;

  /// No description provided for @linkServerFind.
  ///
  /// In en, this message translates to:
  /// **'Find'**
  String get linkServerFind;

  /// No description provided for @linkServerNeedAdmin.
  ///
  /// In en, this message translates to:
  /// **'Only owners and admins of a workspace can link a server.'**
  String get linkServerNeedAdmin;

  /// No description provided for @serverOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'Your server is offline'**
  String get serverOfflineTitle;

  /// No description provided for @serverOfflineBody.
  ///
  /// In en, this message translates to:
  /// **'Is the computer that runs it on and awake? This reconnects by itself.'**
  String get serverOfflineBody;

  /// No description provided for @signUpsClosed.
  ///
  /// In en, this message translates to:
  /// **'This server isn\'t taking new accounts. Sign in with an account you already have here.'**
  String get signUpsClosed;

  /// No description provided for @signUpsByInvitation.
  ///
  /// In en, this message translates to:
  /// **'New accounts here are by invitation. Use the email address you were invited with.'**
  String get signUpsByInvitation;

  /// No description provided for @linkPrivateNotifications.
  ///
  /// In en, this message translates to:
  /// **'Private Notifications'**
  String get linkPrivateNotifications;

  /// No description provided for @linkPrivateNotificationsHelp.
  ///
  /// In en, this message translates to:
  /// **'Notifications reach your phone through Casama Cloud. With this on they carry no text and say only \"New activity\"; the app loads the rest from this server.'**
  String get linkPrivateNotificationsHelp;

  /// No description provided for @linkInvites.
  ///
  /// In en, this message translates to:
  /// **'Let Invited People Sign Up'**
  String get linkInvites;

  /// No description provided for @linkInvitesHelp.
  ///
  /// In en, this message translates to:
  /// **'Off: nobody can make a new account while this is on. On: people you invite by email can. The server restarts to change it.'**
  String get linkInvitesHelp;

  /// No description provided for @linkKeepAwake.
  ///
  /// In en, this message translates to:
  /// **'Keep This Mac Awake While Plugged In'**
  String get linkKeepAwake;

  /// No description provided for @linkKeepAwakeHelp.
  ///
  /// In en, this message translates to:
  /// **'Phones can only reach this server while this computer is awake and Casama is open.'**
  String get linkKeepAwakeHelp;

  /// No description provided for @linkLiveView.
  ///
  /// In en, this message translates to:
  /// **'Live View Away From Here'**
  String get linkLiveView;

  /// No description provided for @linkLiveViewIncluded.
  ///
  /// In en, this message translates to:
  /// **'Included in your plan. Away from this computer, a bot\'s screen plays live through Casama Cloud\'s relay.'**
  String get linkLiveViewIncluded;

  /// No description provided for @linkLiveViewPlan.
  ///
  /// In en, this message translates to:
  /// **'Comes with Plus and up on Casama Cloud. Away from this computer you see a bot\'s screen about once a second. On this computer it is always live.'**
  String get linkLiveViewPlan;

  /// No description provided for @liveAwayNeedsPlan.
  ///
  /// In en, this message translates to:
  /// **'Away from the server\'s computer, live video comes with Plus and up on Casama Cloud. Until then the screen updates about once a second.'**
  String get liveAwayNeedsPlan;

  /// No description provided for @chatShareExport.
  ///
  /// In en, this message translates to:
  /// **'Share or Export'**
  String get chatShareExport;

  /// No description provided for @chatShareExportHelp.
  ///
  /// In en, this message translates to:
  /// **'Save this chat as a file, or make a read-only link to it.'**
  String get chatShareExportHelp;

  /// No description provided for @chatExportMarkdown.
  ///
  /// In en, this message translates to:
  /// **'Export as Markdown'**
  String get chatExportMarkdown;

  /// No description provided for @chatExportMarkdownHelp.
  ///
  /// In en, this message translates to:
  /// **'A text file anyone can read'**
  String get chatExportMarkdownHelp;

  /// No description provided for @chatExportJson.
  ///
  /// In en, this message translates to:
  /// **'Export as JSON'**
  String get chatExportJson;

  /// No description provided for @chatExportJsonHelp.
  ///
  /// In en, this message translates to:
  /// **'For other apps and scripts'**
  String get chatExportJsonHelp;

  /// No description provided for @chatShareLink.
  ///
  /// In en, this message translates to:
  /// **'Share a Read-Only Link'**
  String get chatShareLink;

  /// No description provided for @chatShareLinkHelp.
  ///
  /// In en, this message translates to:
  /// **'Anyone with the link can read this chat'**
  String get chatShareLinkHelp;

  /// No description provided for @chatStopSharing.
  ///
  /// In en, this message translates to:
  /// **'Stop Sharing the Link'**
  String get chatStopSharing;

  /// No description provided for @chatStopSharingHelp.
  ///
  /// In en, this message translates to:
  /// **'The link stops working'**
  String get chatStopSharingHelp;

  /// No description provided for @chatMakePublicTitle.
  ///
  /// In en, this message translates to:
  /// **'Share this chat with a link?'**
  String get chatMakePublicTitle;

  /// No description provided for @chatMakePublicBody.
  ///
  /// In en, this message translates to:
  /// **'Anyone with the link can read this chat as you see it. Attached files are listed by name, not shared. You can stop it any time.'**
  String get chatMakePublicBody;

  /// No description provided for @chatMakePublic.
  ///
  /// In en, this message translates to:
  /// **'Make Link'**
  String get chatMakePublic;

  /// No description provided for @chatLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Read-Only Link'**
  String get chatLinkTitle;

  /// No description provided for @chatLinkBody.
  ///
  /// In en, this message translates to:
  /// **'Copied. It isn\'t listed in search engines. Making a new link stops this one.'**
  String get chatLinkBody;

  /// No description provided for @chatSharingStopped.
  ///
  /// In en, this message translates to:
  /// **'The link no longer works'**
  String get chatSharingStopped;

  /// No description provided for @creationDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get creationDuplicate;

  /// No description provided for @creationDuplicated.
  ///
  /// In en, this message translates to:
  /// **'Made a copy: “{title}”'**
  String creationDuplicated(String title);

  /// No description provided for @slackInstall.
  ///
  /// In en, this message translates to:
  /// **'Add to Slack'**
  String get slackInstall;

  /// No description provided for @slackInstallHelp.
  ///
  /// In en, this message translates to:
  /// **'Connect a Slack workspace in one step. {bot} answers @mentions and direct messages there.'**
  String slackInstallHelp(String bot);

  /// No description provided for @slackInstallFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish in Slack, then come back here.'**
  String get slackInstallFinish;

  /// No description provided for @helpAndSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & support'**
  String get helpAndSupport;

  /// No description provided for @helpAndSupportRow.
  ///
  /// In en, this message translates to:
  /// **'Ask Casama Help, contact us, guides'**
  String get helpAndSupportRow;

  /// No description provided for @casamaHelp.
  ///
  /// In en, this message translates to:
  /// **'Casama Help'**
  String get casamaHelp;

  /// No description provided for @casamaHelpPitch.
  ///
  /// In en, this message translates to:
  /// **'Instant answers from our guides and your account. A person is one tap away.'**
  String get casamaHelpPitch;

  /// No description provided for @supportIntro.
  ///
  /// In en, this message translates to:
  /// **'Questions, a problem with a purchase, or something not working? Write to us.'**
  String get supportIntro;

  /// No description provided for @supportSelfHosted.
  ///
  /// In en, this message translates to:
  /// **'Your workspace runs on {host}. For sign-in, accounts and plans, ask whoever runs that server. We can help with the app itself.'**
  String supportSelfHosted(String host);

  /// No description provided for @supportTalkToPerson.
  ///
  /// In en, this message translates to:
  /// **'Talk to a person'**
  String get supportTalkToPerson;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get contactSupport;

  /// No description provided for @contactSupportRow.
  ///
  /// In en, this message translates to:
  /// **'Write to our team at {email}'**
  String contactSupportRow(String email);

  /// No description provided for @contactSupportHelp.
  ///
  /// In en, this message translates to:
  /// **'Tell us what\'s going on. We\'ll reply by email.'**
  String get contactSupportHelp;

  /// No description provided for @contactSupportHelpMail.
  ///
  /// In en, this message translates to:
  /// **'Tell us what\'s going on. This opens your email app with the details filled in.'**
  String get contactSupportHelpMail;

  /// No description provided for @supportSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get supportSend;

  /// No description provided for @supportWriteEmail.
  ///
  /// In en, this message translates to:
  /// **'Open email'**
  String get supportWriteEmail;

  /// No description provided for @supportTopicPrompt.
  ///
  /// In en, this message translates to:
  /// **'What\'s it about?'**
  String get supportTopicPrompt;

  /// No description provided for @supportTopicBilling.
  ///
  /// In en, this message translates to:
  /// **'Billing & purchases'**
  String get supportTopicBilling;

  /// No description provided for @supportTopicBroken.
  ///
  /// In en, this message translates to:
  /// **'Something\'s not working'**
  String get supportTopicBroken;

  /// No description provided for @supportTopicAccount.
  ///
  /// In en, this message translates to:
  /// **'Account & sign-in'**
  String get supportTopicAccount;

  /// No description provided for @supportTopicQuestion.
  ///
  /// In en, this message translates to:
  /// **'A question or idea'**
  String get supportTopicQuestion;

  /// No description provided for @supportTopicOther.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get supportTopicOther;

  /// No description provided for @supportMessageLabel.
  ///
  /// In en, this message translates to:
  /// **'Your message'**
  String get supportMessageLabel;

  /// No description provided for @supportMessageHint.
  ///
  /// In en, this message translates to:
  /// **'What happened, and what did you expect?'**
  String get supportMessageHint;

  /// Hint under the support message field until the message is long enough to send.
  ///
  /// In en, this message translates to:
  /// **'Add a sentence or two: what you were doing and what went wrong.'**
  String get supportMessageMore;

  /// No description provided for @supportIncludeChat.
  ///
  /// In en, this message translates to:
  /// **'Include my conversation with Casama Help'**
  String get supportIncludeChat;

  /// No description provided for @supportIncludeChatHelp.
  ///
  /// In en, this message translates to:
  /// **'So you don\'t have to explain it twice.'**
  String get supportIncludeChatHelp;

  /// No description provided for @supportDetailsNote.
  ///
  /// In en, this message translates to:
  /// **'We add your app version and your workspace and account IDs so we can find your account. Never your chats.'**
  String get supportDetailsNote;

  /// No description provided for @supportSentTitle.
  ///
  /// In en, this message translates to:
  /// **'Message sent'**
  String get supportSentTitle;

  /// No description provided for @supportSentBody.
  ///
  /// In en, this message translates to:
  /// **'We\'ll reply to {email}. Your reference is {reference}.'**
  String supportSentBody(String email, String reference);

  /// No description provided for @supportNoMailApp.
  ///
  /// In en, this message translates to:
  /// **'No email app found, so we copied your message. Paste it into an email to {email}.'**
  String supportNoMailApp(String email);

  /// No description provided for @supportGuides.
  ///
  /// In en, this message translates to:
  /// **'Guides and FAQ'**
  String get supportGuides;

  /// No description provided for @supportGuidesHelp.
  ///
  /// In en, this message translates to:
  /// **'Step-by-step help for everything in Casama'**
  String get supportGuidesHelp;

  /// No description provided for @supportIds.
  ///
  /// In en, this message translates to:
  /// **'Support IDs'**
  String get supportIds;

  /// No description provided for @supportIdsHelp.
  ///
  /// In en, this message translates to:
  /// **'Support may ask for these. They find your account and purchases, and don\'t give anyone access.'**
  String get supportIdsHelp;

  /// No description provided for @supportWorkspaceId.
  ///
  /// In en, this message translates to:
  /// **'Workspace ID · {name}'**
  String supportWorkspaceId(String name);

  /// No description provided for @supportWorkspaceIdHelp.
  ///
  /// In en, this message translates to:
  /// **'Also your purchase ID in the App Store and Google Play'**
  String get supportWorkspaceIdHelp;

  /// No description provided for @supportAccountId.
  ///
  /// In en, this message translates to:
  /// **'Account ID'**
  String get supportAccountId;

  /// No description provided for @supportCopyAll.
  ///
  /// In en, this message translates to:
  /// **'Copy all details'**
  String get supportCopyAll;

  /// No description provided for @supportCopyAllHelp.
  ///
  /// In en, this message translates to:
  /// **'App version, platform and IDs, to paste into a message'**
  String get supportCopyAllHelp;

  /// No description provided for @supportNewChat.
  ///
  /// In en, this message translates to:
  /// **'New conversation'**
  String get supportNewChat;

  /// No description provided for @supportAskHint.
  ///
  /// In en, this message translates to:
  /// **'Ask anything about Casama'**
  String get supportAskHint;

  /// No description provided for @supportAiNote.
  ///
  /// In en, this message translates to:
  /// **'Casama Help is AI and can make mistakes. It sees your plan and bot errors, not your chats.'**
  String get supportAiNote;

  /// No description provided for @supportGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hi! I\'m Casama Help. Ask me about Casama, your plan, or a problem you\'re having. If I can\'t fix it, I\'ll pass it to our support team.'**
  String get supportGreeting;

  /// No description provided for @supportStarterPurchase.
  ///
  /// In en, this message translates to:
  /// **'My purchase didn\'t go through'**
  String get supportStarterPurchase;

  /// No description provided for @supportStarterCancel.
  ///
  /// In en, this message translates to:
  /// **'How do I cancel my plan?'**
  String get supportStarterCancel;

  /// No description provided for @supportStarterBot.
  ///
  /// In en, this message translates to:
  /// **'My bot isn\'t answering'**
  String get supportStarterBot;

  /// No description provided for @supportStarterHowTo.
  ///
  /// In en, this message translates to:
  /// **'What can my bots do?'**
  String get supportStarterHowTo;

  /// No description provided for @supportAskPerson.
  ///
  /// In en, this message translates to:
  /// **'Ask a person'**
  String get supportAskPerson;

  /// No description provided for @supportHandoffTitle.
  ///
  /// In en, this message translates to:
  /// **'Send this to our support team?'**
  String get supportHandoffTitle;

  /// No description provided for @supportHandoffButton.
  ///
  /// In en, this message translates to:
  /// **'Review and send'**
  String get supportHandoffButton;

  /// No description provided for @supportThinking.
  ///
  /// In en, this message translates to:
  /// **'Looking into it…'**
  String get supportThinking;

  /// No description provided for @supportAssistantError.
  ///
  /// In en, this message translates to:
  /// **'Casama Help couldn\'t answer. Try again, or ask a person.'**
  String get supportAssistantError;

  /// No description provided for @supportAssistantLimit.
  ///
  /// In en, this message translates to:
  /// **'Casama Help can\'t answer more right now. A person can help.'**
  String get supportAssistantLimit;

  /// No description provided for @purchaseHelp.
  ///
  /// In en, this message translates to:
  /// **'Trouble with a purchase? Get help'**
  String get purchaseHelp;

  /// No description provided for @adminReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get adminReports;

  /// No description provided for @adminSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get adminSupport;

  /// No description provided for @report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get report;

  /// No description provided for @reportAndBlock.
  ///
  /// In en, this message translates to:
  /// **'Report and block'**
  String get reportAndBlock;

  /// No description provided for @reportReply.
  ///
  /// In en, this message translates to:
  /// **'Report reply'**
  String get reportReply;

  /// No description provided for @reportBot.
  ///
  /// In en, this message translates to:
  /// **'Report bot'**
  String get reportBot;

  /// No description provided for @reportBotRow.
  ///
  /// In en, this message translates to:
  /// **'Something in its name, description or replies isn\'t right'**
  String get reportBotRow;

  /// No description provided for @reportPerson.
  ///
  /// In en, this message translates to:
  /// **'Report person'**
  String get reportPerson;

  /// No description provided for @reportGalleryItem.
  ///
  /// In en, this message translates to:
  /// **'Report gallery item'**
  String get reportGalleryItem;

  /// No description provided for @reportGalleryRequest.
  ///
  /// In en, this message translates to:
  /// **'Report request'**
  String get reportGalleryRequest;

  /// No description provided for @reportWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Report workspace'**
  String get reportWorkspace;

  /// No description provided for @reportHelp.
  ///
  /// In en, this message translates to:
  /// **'Tell the people who run this server what\'s wrong. They review every report.'**
  String get reportHelp;

  /// No description provided for @reportPersonHelp.
  ///
  /// In en, this message translates to:
  /// **'Tell the people who run this server what happened. We\'ll also block this person for you.'**
  String get reportPersonHelp;

  /// No description provided for @reportNote.
  ///
  /// In en, this message translates to:
  /// **'Anything else they should know (optional)'**
  String get reportNote;

  /// No description provided for @reportAlsoBlock.
  ///
  /// In en, this message translates to:
  /// **'Also block {name}'**
  String reportAlsoBlock(String name);

  /// No description provided for @reportSent.
  ///
  /// In en, this message translates to:
  /// **'Thanks. Your report was sent for review.'**
  String get reportSent;

  /// No description provided for @reportReasonSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam or scam'**
  String get reportReasonSpam;

  /// No description provided for @reportReasonSexual.
  ///
  /// In en, this message translates to:
  /// **'Sexual content'**
  String get reportReasonSexual;

  /// No description provided for @reportReasonViolence.
  ///
  /// In en, this message translates to:
  /// **'Violence or threats'**
  String get reportReasonViolence;

  /// No description provided for @reportReasonHarassment.
  ///
  /// In en, this message translates to:
  /// **'Harassment or hate'**
  String get reportReasonHarassment;

  /// No description provided for @reportReasonIllegal.
  ///
  /// In en, this message translates to:
  /// **'Illegal or dangerous'**
  String get reportReasonIllegal;

  /// No description provided for @reportReasonImpersonation.
  ///
  /// In en, this message translates to:
  /// **'Pretending to be someone'**
  String get reportReasonImpersonation;

  /// No description provided for @reportReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get reportReasonOther;

  /// No description provided for @thisPerson.
  ///
  /// In en, this message translates to:
  /// **'this person'**
  String get thisPerson;

  /// No description provided for @blockPerson.
  ///
  /// In en, this message translates to:
  /// **'Block {name}'**
  String blockPerson(String name);

  /// No description provided for @blocked.
  ///
  /// In en, this message translates to:
  /// **'{name} is blocked'**
  String blocked(String name);

  /// No description provided for @blockHelp.
  ///
  /// In en, this message translates to:
  /// **'Blocked people can\'t invite you to a workspace, and you won\'t hear from them.'**
  String get blockHelp;

  /// No description provided for @blockedPeople.
  ///
  /// In en, this message translates to:
  /// **'Blocked people'**
  String get blockedPeople;

  /// No description provided for @blockedPeopleRow.
  ///
  /// In en, this message translates to:
  /// **'People who can\'t invite you or reach you'**
  String get blockedPeopleRow;

  /// No description provided for @noBlockedPeople.
  ///
  /// In en, this message translates to:
  /// **'No one is blocked'**
  String get noBlockedPeople;

  /// No description provided for @unblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get unblock;

  /// No description provided for @emailTips.
  ///
  /// In en, this message translates to:
  /// **'Tips and news by email'**
  String get emailTips;

  /// No description provided for @emailTipsHelp.
  ///
  /// In en, this message translates to:
  /// **'Getting started tips and the occasional update. Emails about your plan and account always come.'**
  String get emailTipsHelp;

  /// No description provided for @reportsInApp.
  ///
  /// In en, this message translates to:
  /// **'Reported in the app'**
  String get reportsInApp;

  /// No description provided for @reportsNone.
  ///
  /// In en, this message translates to:
  /// **'No open reports. Reports people send from the app show up here.'**
  String get reportsNone;

  /// No description provided for @reportsPublicLinks.
  ///
  /// In en, this message translates to:
  /// **'Reported public links'**
  String get reportsPublicLinks;

  /// No description provided for @reportsNoLinks.
  ///
  /// In en, this message translates to:
  /// **'No public links were reported.'**
  String get reportsNoLinks;

  /// No description provided for @reportsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 report} other{{count} reports}}'**
  String reportsCount(int count);

  /// No description provided for @reportsTakeDown.
  ///
  /// In en, this message translates to:
  /// **'Take down'**
  String get reportsTakeDown;

  /// No description provided for @reportsRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get reportsRestore;

  /// No description provided for @reportKindReply.
  ///
  /// In en, this message translates to:
  /// **'Bot reply'**
  String get reportKindReply;

  /// No description provided for @reportKindBot.
  ///
  /// In en, this message translates to:
  /// **'Bot'**
  String get reportKindBot;

  /// No description provided for @reportKindPerson.
  ///
  /// In en, this message translates to:
  /// **'Person'**
  String get reportKindPerson;

  /// No description provided for @reportKindGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery item'**
  String get reportKindGallery;

  /// No description provided for @reportKindWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Workspace'**
  String get reportKindWorkspace;

  /// No description provided for @reportMarkActioned.
  ///
  /// In en, this message translates to:
  /// **'Dealt with it'**
  String get reportMarkActioned;

  /// No description provided for @reportSuspendWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Suspend the workspace {name}'**
  String reportSuspendWorkspace(String name);

  /// No description provided for @reportDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss: nothing wrong'**
  String get reportDismiss;

  /// No description provided for @supportWebTitle.
  ///
  /// In en, this message translates to:
  /// **'Website Casama Help'**
  String get supportWebTitle;

  /// No description provided for @supportWebOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get supportWebOn;

  /// No description provided for @supportWebOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get supportWebOff;

  /// No description provided for @supportWebToday.
  ///
  /// In en, this message translates to:
  /// **'{count} messages today · \${spent} of \${budget} budget'**
  String supportWebToday(int count, String spent, String budget);

  /// No description provided for @supportWebPaused.
  ///
  /// In en, this message translates to:
  /// **'{count} addresses paused'**
  String supportWebPaused(int count);

  /// No description provided for @supportWebGaps.
  ///
  /// In en, this message translates to:
  /// **'Show {count} unanswered questions'**
  String supportWebGaps(int count);

  /// No description provided for @ticketsOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get ticketsOpen;

  /// No description provided for @ticketsClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get ticketsClosed;

  /// No description provided for @ticketsAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get ticketsAll;

  /// No description provided for @ticketsNone.
  ///
  /// In en, this message translates to:
  /// **'No messages here.'**
  String get ticketsNone;

  /// No description provided for @ticketClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get ticketClose;

  /// No description provided for @ticketReopen.
  ///
  /// In en, this message translates to:
  /// **'Reopen'**
  String get ticketReopen;

  /// No description provided for @serviceStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get serviceStatus;

  /// No description provided for @supportStatus.
  ///
  /// In en, this message translates to:
  /// **'Casama Cloud status'**
  String get supportStatus;

  /// No description provided for @supportStatusHelp.
  ///
  /// In en, this message translates to:
  /// **'Check whether something is down right now'**
  String get supportStatusHelp;

  /// No description provided for @galleryChatSuggestionLabel.
  ///
  /// In en, this message translates to:
  /// **'From the gallery'**
  String get galleryChatSuggestionLabel;

  /// No description provided for @galleryChatAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get galleryChatAdd;

  /// No description provided for @galleryChatAdded.
  ///
  /// In en, this message translates to:
  /// **'Added {name}'**
  String galleryChatAdded(String name);

  /// No description provided for @galleryChatReads.
  ///
  /// In en, this message translates to:
  /// **'Reads {things}'**
  String galleryChatReads(String things);

  /// No description provided for @galleryChatRunsCode.
  ///
  /// In en, this message translates to:
  /// **'Runs code'**
  String get galleryChatRunsCode;

  /// No description provided for @galleryChatComputer.
  ///
  /// In en, this message translates to:
  /// **'Uses a computer'**
  String get galleryChatComputer;

  /// No description provided for @galleryChatNeeds.
  ///
  /// In en, this message translates to:
  /// **'Needs {apps}'**
  String galleryChatNeeds(String apps);

  /// No description provided for @galleryChatDraftLabel.
  ///
  /// In en, this message translates to:
  /// **'Skill draft'**
  String get galleryChatDraftLabel;

  /// No description provided for @galleryChatShowInstructions.
  ///
  /// In en, this message translates to:
  /// **'Show instructions'**
  String get galleryChatShowInstructions;

  /// No description provided for @galleryChatHideInstructions.
  ///
  /// In en, this message translates to:
  /// **'Hide instructions'**
  String get galleryChatHideInstructions;

  /// No description provided for @galleryChatSaveSkill.
  ///
  /// In en, this message translates to:
  /// **'Save to my skills'**
  String get galleryChatSaveSkill;

  /// No description provided for @galleryChatSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get galleryChatSaved;

  /// No description provided for @galleryChatSavedSkill.
  ///
  /// In en, this message translates to:
  /// **'Saved to your skills'**
  String get galleryChatSavedSkill;

  /// No description provided for @galleryChatSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit to the gallery'**
  String get galleryChatSubmit;

  /// No description provided for @galleryChatSubmitTitle.
  ///
  /// In en, this message translates to:
  /// **'Submit {name} to the gallery?'**
  String galleryChatSubmitTitle(String name);

  /// No description provided for @galleryChatSubmitBody.
  ///
  /// In en, this message translates to:
  /// **'A maintainer reviews it first. Once it\'s in, anyone can find and use it. Your display name is shown as the author, never your email.'**
  String get galleryChatSubmitBody;

  /// No description provided for @galleryChatSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get galleryChatSent;

  /// No description provided for @galleryChatSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Sent to the gallery for review'**
  String get galleryChatSubmitted;

  /// No description provided for @galleryChatSubmissionsOff.
  ///
  /// In en, this message translates to:
  /// **'This server doesn\'t take gallery submissions.'**
  String get galleryChatSubmissionsOff;

  /// No description provided for @galleryPicksTitle.
  ///
  /// In en, this message translates to:
  /// **'Picks for you'**
  String get galleryPicksTitle;

  /// No description provided for @galleryPicksHelp.
  ///
  /// In en, this message translates to:
  /// **'Start with a set of skills, apps and routines that fit. You can change anything later.'**
  String get galleryPicksHelp;

  /// No description provided for @galleryPicksAdd.
  ///
  /// In en, this message translates to:
  /// **'Add this set'**
  String get galleryPicksAdd;

  /// No description provided for @galleryPicksSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get galleryPicksSkip;

  /// No description provided for @galleryPicksAddNamed.
  ///
  /// In en, this message translates to:
  /// **'Add {name}'**
  String galleryPicksAddNamed(String name);

  /// No description provided for @galleryPicksBestMatch.
  ///
  /// In en, this message translates to:
  /// **'Best match'**
  String get galleryPicksBestMatch;

  /// No description provided for @galleryPicksInside.
  ///
  /// In en, this message translates to:
  /// **'What\'s inside'**
  String get galleryPicksInside;

  /// No description provided for @galleryPicksBots.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 bot} other{{count} bots}}'**
  String galleryPicksBots(int count);

  /// No description provided for @galleryPicksSkills.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 skill} other{{count} skills}}'**
  String galleryPicksSkills(int count);

  /// No description provided for @galleryPicksRoutines.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 routine} other{{count} routines}}'**
  String galleryPicksRoutines(int count);

  /// No description provided for @galleryPicksApps.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 app} other{{count} apps}}'**
  String galleryPicksApps(int count);

  /// No description provided for @galleryPicksPlugins.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 plugin} other{{count} plugins}}'**
  String galleryPicksPlugins(int count);

  /// No description provided for @galleryPicksLooks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 look} other{{count} looks}}'**
  String galleryPicksLooks(int count);

  /// No description provided for @galleryPicksAdded.
  ///
  /// In en, this message translates to:
  /// **'Added {name}'**
  String galleryPicksAdded(String name);

  /// No description provided for @galleryPicksAddedNeedsApps.
  ///
  /// In en, this message translates to:
  /// **'Added {name}. Connect {apps} in Apps to finish.'**
  String galleryPicksAddedNeedsApps(String name, String apps);

  /// No description provided for @galleryPicksPending.
  ///
  /// In en, this message translates to:
  /// **'An admin will look at {name} before it\'s added.'**
  String galleryPicksPending(String name);

  /// No description provided for @galleryPolicyTitle.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get galleryPolicyTitle;

  /// No description provided for @galleryPolicyRow.
  ///
  /// In en, this message translates to:
  /// **'What people here can add from the gallery'**
  String get galleryPolicyRow;

  /// No description provided for @galleryPolicyMode.
  ///
  /// In en, this message translates to:
  /// **'Who can add'**
  String get galleryPolicyMode;

  /// No description provided for @galleryPolicyOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get galleryPolicyOpen;

  /// No description provided for @galleryPolicyOpenHelp.
  ///
  /// In en, this message translates to:
  /// **'Anyone here can add anything that isn\'t blocked.'**
  String get galleryPolicyOpenHelp;

  /// No description provided for @galleryPolicyApproval.
  ///
  /// In en, this message translates to:
  /// **'Ask first'**
  String get galleryPolicyApproval;

  /// No description provided for @galleryPolicyApprovalHelp.
  ///
  /// In en, this message translates to:
  /// **'Adding asks an admin first, for what you pick below.'**
  String get galleryPolicyApprovalHelp;

  /// No description provided for @galleryPolicyAllowlist.
  ///
  /// In en, this message translates to:
  /// **'Only allowed'**
  String get galleryPolicyAllowlist;

  /// No description provided for @galleryPolicyAllowlistHelp.
  ///
  /// In en, this message translates to:
  /// **'People can add only what\'s on the allowed list.'**
  String get galleryPolicyAllowlistHelp;

  /// No description provided for @galleryPolicyApprovalFor.
  ///
  /// In en, this message translates to:
  /// **'Ask first for'**
  String get galleryPolicyApprovalFor;

  /// No description provided for @galleryPolicyRunsCode.
  ///
  /// In en, this message translates to:
  /// **'Things that run code'**
  String get galleryPolicyRunsCode;

  /// No description provided for @galleryPolicyApps.
  ///
  /// In en, this message translates to:
  /// **'Things that connect apps'**
  String get galleryPolicyApps;

  /// No description provided for @galleryPolicyAll.
  ///
  /// In en, this message translates to:
  /// **'Everything'**
  String get galleryPolicyAll;

  /// No description provided for @galleryPolicyAllowed.
  ///
  /// In en, this message translates to:
  /// **'Allowed'**
  String get galleryPolicyAllowed;

  /// No description provided for @galleryPolicyAllowedHelp.
  ///
  /// In en, this message translates to:
  /// **'Added without asking. With Only allowed, the only things people can add.'**
  String get galleryPolicyAllowedHelp;

  /// No description provided for @galleryPolicyBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get galleryPolicyBlocked;

  /// No description provided for @galleryPolicyBlockedHelp.
  ///
  /// In en, this message translates to:
  /// **'Nobody here can add these.'**
  String get galleryPolicyBlockedHelp;

  /// No description provided for @galleryPolicyAddItem.
  ///
  /// In en, this message translates to:
  /// **'Add from the gallery'**
  String get galleryPolicyAddItem;

  /// No description provided for @galleryPolicyNone.
  ///
  /// In en, this message translates to:
  /// **'Nothing yet'**
  String get galleryPolicyNone;

  /// No description provided for @galleryPolicySearch.
  ///
  /// In en, this message translates to:
  /// **'Search the gallery'**
  String get galleryPolicySearch;

  /// No description provided for @galleryPolicyNoResults.
  ///
  /// In en, this message translates to:
  /// **'Nothing in the gallery matches.'**
  String get galleryPolicyNoResults;

  /// No description provided for @galleryPolicySaved.
  ///
  /// In en, this message translates to:
  /// **'Gallery rules saved'**
  String get galleryPolicySaved;

  /// No description provided for @galleryPolicyRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}'**
  String galleryPolicyRemove(String name);

  /// No description provided for @galleryPolicyAdminsOnly.
  ///
  /// In en, this message translates to:
  /// **'Only admins and owners can change this.'**
  String get galleryPolicyAdminsOnly;

  /// No description provided for @galleryPolicyWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for approval'**
  String get galleryPolicyWaiting;

  /// No description provided for @galleryPolicyRequestedBy.
  ///
  /// In en, this message translates to:
  /// **'{name} asked'**
  String galleryPolicyRequestedBy(String name);

  /// No description provided for @galleryPolicyApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get galleryPolicyApprove;

  /// No description provided for @galleryPolicyDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get galleryPolicyDecline;

  /// No description provided for @galleryPolicyApproved.
  ///
  /// In en, this message translates to:
  /// **'{name} approved and added'**
  String galleryPolicyApproved(String name);

  /// No description provided for @galleryPolicyDeclined.
  ///
  /// In en, this message translates to:
  /// **'{name} declined'**
  String galleryPolicyDeclined(String name);

  /// No description provided for @galleryPolicyApproveFailed.
  ///
  /// In en, this message translates to:
  /// **'Approved, but {name} couldn\'t be added. {error}'**
  String galleryPolicyApproveFailed(String name, String error);

  /// No description provided for @galleryDigestEmails.
  ///
  /// In en, this message translates to:
  /// **'Monthly gallery picks'**
  String get galleryDigestEmails;

  /// No description provided for @galleryDigestHelp.
  ///
  /// In en, this message translates to:
  /// **'Up to six new skills, apps and routines that fit what you use, once a month.'**
  String get galleryDigestHelp;

  /// No description provided for @newsletterTitle.
  ///
  /// In en, this message translates to:
  /// **'Casama\'s monthly email'**
  String get newsletterTitle;

  /// No description provided for @newsletterHelp.
  ///
  /// In en, this message translates to:
  /// **'What\'s new and what\'s next, once a month at most.'**
  String get newsletterHelp;

  /// No description provided for @newsletterSignUp.
  ///
  /// In en, this message translates to:
  /// **'Send me Casama\'s monthly email: what\'s new and what\'s next, once a month at most.'**
  String get newsletterSignUp;

  /// No description provided for @newsletterCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Get Casama\'s monthly email?'**
  String get newsletterCardTitle;

  /// No description provided for @newsletterCardBody.
  ///
  /// In en, this message translates to:
  /// **'What\'s new and what\'s next, once a month at most. Stop any time.'**
  String get newsletterCardBody;

  /// No description provided for @newsletterCardYes.
  ///
  /// In en, this message translates to:
  /// **'Yes, send it'**
  String get newsletterCardYes;

  /// No description provided for @newsletterCardNo.
  ///
  /// In en, this message translates to:
  /// **'No thanks'**
  String get newsletterCardNo;

  /// No description provided for @newsletterCardDone.
  ///
  /// In en, this message translates to:
  /// **'You\'re on the list. Turn it off any time in Settings.'**
  String get newsletterCardDone;

  /// No description provided for @galleryKindApp.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get galleryKindApp;

  /// No description provided for @galleryKindApps.
  ///
  /// In en, this message translates to:
  /// **'Apps'**
  String get galleryKindApps;

  /// No description provided for @galleryKindBot.
  ///
  /// In en, this message translates to:
  /// **'Starter bot'**
  String get galleryKindBot;

  /// No description provided for @galleryKindBots.
  ///
  /// In en, this message translates to:
  /// **'Starter bots'**
  String get galleryKindBots;

  /// No description provided for @galleryKindRoutine.
  ///
  /// In en, this message translates to:
  /// **'Routine'**
  String get galleryKindRoutine;

  /// No description provided for @galleryKindRoutines.
  ///
  /// In en, this message translates to:
  /// **'Routines'**
  String get galleryKindRoutines;

  /// No description provided for @galleryKindPlugin.
  ///
  /// In en, this message translates to:
  /// **'Plugin'**
  String get galleryKindPlugin;

  /// No description provided for @galleryKindPlugins.
  ///
  /// In en, this message translates to:
  /// **'Plugins'**
  String get galleryKindPlugins;

  /// No description provided for @galleryKindSet.
  ///
  /// In en, this message translates to:
  /// **'Starter set'**
  String get galleryKindSet;

  /// No description provided for @galleryKindSets.
  ///
  /// In en, this message translates to:
  /// **'Starter sets'**
  String get galleryKindSets;

  /// No description provided for @galleryTabBrowse.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get galleryTabBrowse;

  /// No description provided for @galleryTabInstalled.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get galleryTabInstalled;

  /// No description provided for @gallerySearchEverything.
  ///
  /// In en, this message translates to:
  /// **'Search everything'**
  String get gallerySearchEverything;

  /// No description provided for @galleryNewBadge.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get galleryNewBadge;

  /// No description provided for @galleryRowPicks.
  ///
  /// In en, this message translates to:
  /// **'Picks'**
  String get galleryRowPicks;

  /// No description provided for @galleryRowNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get galleryRowNew;

  /// No description provided for @galleryRowTrending.
  ///
  /// In en, this message translates to:
  /// **'Trending this week'**
  String get galleryRowTrending;

  /// No description provided for @galleryRowMostUsed.
  ///
  /// In en, this message translates to:
  /// **'Most used'**
  String get galleryRowMostUsed;

  /// No description provided for @galleryRowWorksWith.
  ///
  /// In en, this message translates to:
  /// **'Works with what you have'**
  String get galleryRowWorksWith;

  /// No description provided for @galleryRowSets.
  ///
  /// In en, this message translates to:
  /// **'Starter sets'**
  String get galleryRowSets;

  /// No description provided for @galleryRowSeasonal.
  ///
  /// In en, this message translates to:
  /// **'In season'**
  String get galleryRowSeasonal;

  /// No description provided for @galleryFilterFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get galleryFilterFree;

  /// No description provided for @galleryFilterPlan.
  ///
  /// In en, this message translates to:
  /// **'Uses credits'**
  String get galleryFilterPlan;

  /// No description provided for @galleryFilterSelfHosted.
  ///
  /// In en, this message translates to:
  /// **'Works self-hosted'**
  String get galleryFilterSelfHosted;

  /// No description provided for @galleryFilterComputer.
  ///
  /// In en, this message translates to:
  /// **'Needs a computer'**
  String get galleryFilterComputer;

  /// No description provided for @galleryNoFilterMatches.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches these filters'**
  String get galleryNoFilterMatches;

  /// No description provided for @galleryClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get galleryClearFilters;

  /// No description provided for @galleryRequestThis.
  ///
  /// In en, this message translates to:
  /// **'Request this'**
  String get galleryRequestThis;

  /// No description provided for @galleryAskCasama.
  ///
  /// In en, this message translates to:
  /// **'Ask Casama to make it'**
  String get galleryAskCasama;

  /// No description provided for @galleryAskPrompt.
  ///
  /// In en, this message translates to:
  /// **'Make me something for this: {query}'**
  String galleryAskPrompt(String query);

  /// No description provided for @galleryAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'What it can access'**
  String get galleryAccessTitle;

  /// No description provided for @galleryAccessReads.
  ///
  /// In en, this message translates to:
  /// **'Reads your {things}'**
  String galleryAccessReads(String things);

  /// No description provided for @galleryAccessRunsCode.
  ///
  /// In en, this message translates to:
  /// **'Runs code'**
  String get galleryAccessRunsCode;

  /// No description provided for @galleryAccessComputer.
  ///
  /// In en, this message translates to:
  /// **'Uses a computer'**
  String get galleryAccessComputer;

  /// No description provided for @galleryAccessNothing.
  ///
  /// In en, this message translates to:
  /// **'Doesn\'t read or change anything of yours'**
  String get galleryAccessNothing;

  /// No description provided for @galleryCreditsNone.
  ///
  /// In en, this message translates to:
  /// **'Uses no credits'**
  String get galleryCreditsNone;

  /// No description provided for @galleryCreditsLow.
  ///
  /// In en, this message translates to:
  /// **'Uses few credits'**
  String get galleryCreditsLow;

  /// No description provided for @galleryCreditsMedium.
  ///
  /// In en, this message translates to:
  /// **'Uses some credits'**
  String get galleryCreditsMedium;

  /// No description provided for @galleryCreditsHigh.
  ///
  /// In en, this message translates to:
  /// **'Uses many credits'**
  String get galleryCreditsHigh;

  /// No description provided for @galleryTryIt.
  ///
  /// In en, this message translates to:
  /// **'Try it'**
  String get galleryTryIt;

  /// No description provided for @galleryUsedBy.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Used by 1 person} other{Used by {shown} people}}'**
  String galleryUsedBy(int count, String shown);

  /// No description provided for @galleryRunsFinish.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of runs finish'**
  String galleryRunsFinish(int percent);

  /// No description provided for @galleryAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get galleryAbout;

  /// No description provided for @galleryMadeByCasama.
  ///
  /// In en, this message translates to:
  /// **'Made by Casama'**
  String get galleryMadeByCasama;

  /// No description provided for @galleryMadeByCommunity.
  ///
  /// In en, this message translates to:
  /// **'Made by the community'**
  String get galleryMadeByCommunity;

  /// No description provided for @galleryMadeReviewed.
  ///
  /// In en, this message translates to:
  /// **'Reviewed'**
  String get galleryMadeReviewed;

  /// No description provided for @galleryReviewedHelp.
  ///
  /// In en, this message translates to:
  /// **'Its tests passed for this version'**
  String get galleryReviewedHelp;

  /// No description provided for @galleryMoreFrom.
  ///
  /// In en, this message translates to:
  /// **'More from {name}'**
  String galleryMoreFrom(String name);

  /// No description provided for @galleryVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String galleryVersion(int version);

  /// No description provided for @galleryUpdatedOn.
  ///
  /// In en, this message translates to:
  /// **'Updated {date}'**
  String galleryUpdatedOn(String date);

  /// No description provided for @galleryRemixOf.
  ///
  /// In en, this message translates to:
  /// **'Remix of {name}'**
  String galleryRemixOf(String name);

  /// No description provided for @galleryChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'What changed in {name}'**
  String galleryChangesTitle(String name);

  /// No description provided for @galleryBreaking.
  ///
  /// In en, this message translates to:
  /// **'Works differently'**
  String get galleryBreaking;

  /// No description provided for @galleryAuthorCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item in the gallery} other{{count} items in the gallery}}'**
  String galleryAuthorCount(int count);

  /// No description provided for @galleryAuthorEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing in the gallery by this author yet.'**
  String get galleryAuthorEmpty;

  /// No description provided for @galleryInstalledWorkspace.
  ///
  /// In en, this message translates to:
  /// **'In this workspace'**
  String get galleryInstalledWorkspace;

  /// No description provided for @galleryInstalledDevice.
  ///
  /// In en, this message translates to:
  /// **'Looks on this device'**
  String get galleryInstalledDevice;

  /// No description provided for @galleryInstalledEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing added yet'**
  String get galleryInstalledEmptyTitle;

  /// No description provided for @galleryInstalledEmpty.
  ///
  /// In en, this message translates to:
  /// **'Skills, apps, routines and looks you add from the gallery show here, with updates.'**
  String get galleryInstalledEmpty;

  /// No description provided for @galleryInstalledError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load what\'s installed.'**
  String get galleryInstalledError;

  /// No description provided for @galleryUpdatesAvailable.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 update} other{{count} updates}}'**
  String galleryUpdatesAvailable(int count);

  /// No description provided for @galleryUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get galleryUpdate;

  /// No description provided for @galleryUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {name}'**
  String galleryUpdated(String name);

  /// No description provided for @galleryUpdateFromTo.
  ///
  /// In en, this message translates to:
  /// **'Version {from} → {to}'**
  String galleryUpdateFromTo(int from, int to);

  /// No description provided for @galleryUpdateAskTitle.
  ///
  /// In en, this message translates to:
  /// **'Update {name}?'**
  String galleryUpdateAskTitle(String name);

  /// No description provided for @galleryUpdateAccessHelp.
  ///
  /// In en, this message translates to:
  /// **'The new version can do more than the one you have:'**
  String get galleryUpdateAccessHelp;

  /// No description provided for @galleryUpdateBreakingHelp.
  ///
  /// In en, this message translates to:
  /// **'The new version works differently, so check it after updating.'**
  String get galleryUpdateBreakingHelp;

  /// No description provided for @galleryUpdateNowReads.
  ///
  /// In en, this message translates to:
  /// **'Now reads your {things}'**
  String galleryUpdateNowReads(String things);

  /// No description provided for @galleryUpdateNowWrites.
  ///
  /// In en, this message translates to:
  /// **'Now can: {action}'**
  String galleryUpdateNowWrites(String action);

  /// No description provided for @galleryUpdateNowRunsCode.
  ///
  /// In en, this message translates to:
  /// **'Now runs code'**
  String get galleryUpdateNowRunsCode;

  /// No description provided for @galleryUpdateNowComputer.
  ///
  /// In en, this message translates to:
  /// **'Now uses a computer'**
  String get galleryUpdateNowComputer;

  /// No description provided for @galleryRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get galleryRemove;

  /// No description provided for @galleryRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String galleryRemoveTitle(String name);

  /// No description provided for @galleryRemoveHelp.
  ///
  /// In en, this message translates to:
  /// **'It\'s removed from this workspace. You can add it again from the gallery.'**
  String get galleryRemoveHelp;

  /// No description provided for @galleryRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed {name}'**
  String galleryRemoved(String name);

  /// No description provided for @galleryRetired.
  ///
  /// In en, this message translates to:
  /// **'No longer in the gallery'**
  String get galleryRetired;

  /// No description provided for @galleryRetiredReplaced.
  ///
  /// In en, this message translates to:
  /// **'No longer in the gallery; there\'s a replacement'**
  String get galleryRetiredReplaced;

  /// No description provided for @gallerySeeReplacement.
  ///
  /// In en, this message translates to:
  /// **'See replacement'**
  String get gallerySeeReplacement;

  /// No description provided for @galleryForgetLook.
  ///
  /// In en, this message translates to:
  /// **'Remove from this list'**
  String get galleryForgetLook;

  /// No description provided for @galleryWizardTitle.
  ///
  /// In en, this message translates to:
  /// **'Add {name}'**
  String galleryWizardTitle(String name);

  /// No description provided for @galleryWizardAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get galleryWizardAdd;

  /// No description provided for @galleryWizardRequired.
  ///
  /// In en, this message translates to:
  /// **'Fill this in'**
  String get galleryWizardRequired;

  /// No description provided for @galleryWizardSetIncludes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Includes 1 item} other{Includes {count} items}}'**
  String galleryWizardSetIncludes(int count);

  /// No description provided for @galleryWizardNeeds.
  ///
  /// In en, this message translates to:
  /// **'What it needs'**
  String get galleryWizardNeeds;

  /// No description provided for @galleryWizardNeedsSkills.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 skill, added for you} other{{count} skills, added for you}}'**
  String galleryWizardNeedsSkills(int count);

  /// No description provided for @galleryWizardNeedsApps.
  ///
  /// In en, this message translates to:
  /// **'Apps to connect: {apps}'**
  String galleryWizardNeedsApps(String apps);

  /// No description provided for @galleryWizardBot.
  ///
  /// In en, this message translates to:
  /// **'Add to which bot'**
  String get galleryWizardBot;

  /// No description provided for @galleryWizardPickBot.
  ///
  /// In en, this message translates to:
  /// **'Pick a bot'**
  String get galleryWizardPickBot;

  /// No description provided for @galleryWizardSetBotHelp.
  ///
  /// In en, this message translates to:
  /// **'Where the set\'s routines go. Without one they\'re left out.'**
  String get galleryWizardSetBotHelp;

  /// No description provided for @galleryWizardSetNotAdded.
  ///
  /// In en, this message translates to:
  /// **'Not added'**
  String get galleryWizardSetNotAdded;

  /// No description provided for @galleryWizardNeedsTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect your apps'**
  String get galleryWizardNeedsTitle;

  /// No description provided for @galleryWizardNeedsHelp.
  ///
  /// In en, this message translates to:
  /// **'{name} works once these are connected.'**
  String galleryWizardNeedsHelp(String name);

  /// No description provided for @galleryWizardSkillAdded.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get galleryWizardSkillAdded;

  /// No description provided for @galleryWizardConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get galleryWizardConnected;

  /// No description provided for @galleryWizardConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get galleryWizardConnect;

  /// No description provided for @galleryWizardConnectInApps.
  ///
  /// In en, this message translates to:
  /// **'Connect {name} in Settings → Apps.'**
  String galleryWizardConnectInApps(String name);

  /// No description provided for @galleryWizardContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get galleryWizardContinue;

  /// No description provided for @galleryWizardSkip.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get galleryWizardSkip;

  /// No description provided for @galleryWizardDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} is ready'**
  String galleryWizardDoneTitle(String name);

  /// No description provided for @galleryWizardDoneHelp.
  ///
  /// In en, this message translates to:
  /// **'You\'ll find it with the rest of your things.'**
  String get galleryWizardDoneHelp;

  /// No description provided for @galleryWizardDoneMissing.
  ///
  /// In en, this message translates to:
  /// **'It works fully once you connect {apps}.'**
  String galleryWizardDoneMissing(String apps);

  /// No description provided for @galleryWizardPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Waiting for approval'**
  String get galleryWizardPendingTitle;

  /// No description provided for @galleryWizardPendingHelp.
  ///
  /// In en, this message translates to:
  /// **'Your workspace asks an admin first. It\'s added once they approve.'**
  String get galleryWizardPendingHelp;

  /// No description provided for @galleryRequestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get galleryRequestsTitle;

  /// No description provided for @galleryRequestsHelp.
  ///
  /// In en, this message translates to:
  /// **'Ideas for the gallery. Vote for the ones you want; makers pick from the top.'**
  String get galleryRequestsHelp;

  /// No description provided for @galleryRequestsLinkHelp.
  ///
  /// In en, this message translates to:
  /// **'Ask for something that isn\'t here yet, or vote'**
  String get galleryRequestsLinkHelp;

  /// No description provided for @galleryRequestsTop.
  ///
  /// In en, this message translates to:
  /// **'Top'**
  String get galleryRequestsTop;

  /// No description provided for @galleryRequestsNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get galleryRequestsNew;

  /// No description provided for @galleryRequestsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No requests yet. Be the first.'**
  String get galleryRequestsEmpty;

  /// No description provided for @galleryRequestsError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load requests.'**
  String get galleryRequestsError;

  /// No description provided for @galleryRequestNew.
  ///
  /// In en, this message translates to:
  /// **'New request'**
  String get galleryRequestNew;

  /// No description provided for @galleryRequestNewHelp.
  ///
  /// In en, this message translates to:
  /// **'Say what you\'d like someone to make. Similar requests are merged.'**
  String get galleryRequestNewHelp;

  /// No description provided for @galleryRequestKind.
  ///
  /// In en, this message translates to:
  /// **'Kind'**
  String get galleryRequestKind;

  /// No description provided for @galleryRequestTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'What should it do?'**
  String get galleryRequestTitleLabel;

  /// No description provided for @galleryRequestTitleLength.
  ///
  /// In en, this message translates to:
  /// **'Use 4 to 80 characters.'**
  String get galleryRequestTitleLength;

  /// No description provided for @galleryRequestDetails.
  ///
  /// In en, this message translates to:
  /// **'Details (optional)'**
  String get galleryRequestDetails;

  /// No description provided for @galleryRequestSend.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get galleryRequestSend;

  /// No description provided for @galleryRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Request sent'**
  String get galleryRequestSent;

  /// No description provided for @galleryRequestSimilar.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" was already asked for, so your vote went to it'**
  String galleryRequestSimilar(String title);

  /// No description provided for @galleryRequestMine.
  ///
  /// In en, this message translates to:
  /// **'Yours'**
  String get galleryRequestMine;

  /// No description provided for @galleryRequestVote.
  ///
  /// In en, this message translates to:
  /// **'Vote'**
  String get galleryRequestVote;

  /// No description provided for @galleryRequestOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get galleryRequestOpen;

  /// No description provided for @galleryRequestPlanned.
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get galleryRequestPlanned;

  /// No description provided for @galleryRequestDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get galleryRequestDone;

  /// No description provided for @galleryRequestDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get galleryRequestDeclined;

  /// No description provided for @gallerySubmitStart.
  ///
  /// In en, this message translates to:
  /// **'Submit to the gallery'**
  String get gallerySubmitStart;

  /// No description provided for @gallerySubmissionsLinkHelp.
  ///
  /// In en, this message translates to:
  /// **'Share a look, skill, routine or bot you made'**
  String get gallerySubmissionsLinkHelp;

  /// No description provided for @gallerySubmitPick.
  ///
  /// In en, this message translates to:
  /// **'What do you want to share?'**
  String get gallerySubmitPick;

  /// No description provided for @gallerySubmitPickHelp.
  ///
  /// In en, this message translates to:
  /// **'Pick something you made. It\'s reviewed before it\'s in the gallery.'**
  String get gallerySubmitPickHelp;

  /// No description provided for @galleryLooksMine.
  ///
  /// In en, this message translates to:
  /// **'Your looks'**
  String get galleryLooksMine;

  /// No description provided for @gallerySubmitCurrentScheme.
  ///
  /// In en, this message translates to:
  /// **'Color scheme in use'**
  String get gallerySubmitCurrentScheme;

  /// No description provided for @gallerySubmitCurrentWallpaper.
  ///
  /// In en, this message translates to:
  /// **'Wallpaper in use'**
  String get gallerySubmitCurrentWallpaper;

  /// No description provided for @gallerySubmitMyWallpaper.
  ///
  /// In en, this message translates to:
  /// **'My wallpaper'**
  String get gallerySubmitMyWallpaper;

  /// No description provided for @gallerySubmitTitle.
  ///
  /// In en, this message translates to:
  /// **'Submit a {kind}'**
  String gallerySubmitTitle(String kind);

  /// No description provided for @gallerySubmitHelp.
  ///
  /// In en, this message translates to:
  /// **'Your display name is shown as the author. Your email is never shared.'**
  String get gallerySubmitHelp;

  /// No description provided for @gallerySubmitName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get gallerySubmitName;

  /// No description provided for @gallerySubmitNameLength.
  ///
  /// In en, this message translates to:
  /// **'Use 1 to 60 characters.'**
  String get gallerySubmitNameLength;

  /// No description provided for @gallerySubmitTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get gallerySubmitTags;

  /// No description provided for @gallerySubmitTagsHelp.
  ///
  /// In en, this message translates to:
  /// **'Up to six, separated by commas'**
  String get gallerySubmitTagsHelp;

  /// No description provided for @gallerySubmitLicense.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get gallerySubmitLicense;

  /// No description provided for @gallerySubmitRemix.
  ///
  /// In en, this message translates to:
  /// **'Credits the original: {name}'**
  String gallerySubmitRemix(String name);

  /// No description provided for @gallerySubmitSend.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get gallerySubmitSend;

  /// No description provided for @gallerySubmitted.
  ///
  /// In en, this message translates to:
  /// **'Sent for review'**
  String get gallerySubmitted;

  /// No description provided for @gallerySubmissionsTitle.
  ///
  /// In en, this message translates to:
  /// **'My submissions'**
  String get gallerySubmissionsTitle;

  /// No description provided for @gallerySubmissionsHelp.
  ///
  /// In en, this message translates to:
  /// **'What you sent to the gallery and where it stands.'**
  String get gallerySubmissionsHelp;

  /// No description provided for @gallerySubmissionsSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get gallerySubmissionsSent;

  /// No description provided for @gallerySubmissionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing sent yet.'**
  String get gallerySubmissionsEmpty;

  /// No description provided for @gallerySubmissionsError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your submissions.'**
  String get gallerySubmissionsError;

  /// No description provided for @gallerySubmissionOpen.
  ///
  /// In en, this message translates to:
  /// **'In review'**
  String get gallerySubmissionOpen;

  /// No description provided for @gallerySubmissionMerged.
  ///
  /// In en, this message translates to:
  /// **'In the gallery'**
  String get gallerySubmissionMerged;

  /// No description provided for @gallerySubmissionClosed.
  ///
  /// In en, this message translates to:
  /// **'Not accepted'**
  String get gallerySubmissionClosed;

  /// No description provided for @gallerySubmissionFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t be sent'**
  String get gallerySubmissionFailed;

  /// No description provided for @galleryMyItems.
  ///
  /// In en, this message translates to:
  /// **'Your items in the gallery'**
  String get galleryMyItems;

  /// No description provided for @galleryReportsOpen.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 open report} other{{count} open reports}}'**
  String galleryReportsOpen(int count);

  /// No description provided for @islandBot.
  ///
  /// In en, this message translates to:
  /// **'A bot'**
  String get islandBot;

  /// No description provided for @islandNeedsOk.
  ///
  /// In en, this message translates to:
  /// **'Needs your OK'**
  String get islandNeedsOk;

  /// No description provided for @islandTakeOver.
  ///
  /// In en, this message translates to:
  /// **'Wants you to take over'**
  String get islandTakeOver;

  /// No description provided for @islandWriting.
  ///
  /// In en, this message translates to:
  /// **'Writing a reply'**
  String get islandWriting;

  /// No description provided for @islandWorking.
  ///
  /// In en, this message translates to:
  /// **'Working'**
  String get islandWorking;

  /// No description provided for @islandFinished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get islandFinished;

  /// No description provided for @islandStoppedProblem.
  ///
  /// In en, this message translates to:
  /// **'Stopped with a problem'**
  String get islandStoppedProblem;

  /// No description provided for @islandOnThisMac.
  ///
  /// In en, this message translates to:
  /// **'On this Mac'**
  String get islandOnThisMac;

  /// No description provided for @islandStale.
  ///
  /// In en, this message translates to:
  /// **'Open Casama for the latest'**
  String get islandStale;

  /// No description provided for @islandOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get islandOpen;

  /// No description provided for @islandStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get islandStop;

  /// No description provided for @islandAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get islandAllow;

  /// No description provided for @islandDeny.
  ///
  /// In en, this message translates to:
  /// **'Deny'**
  String get islandDeny;

  /// No description provided for @islandReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get islandReview;

  /// No description provided for @islandNothing.
  ///
  /// In en, this message translates to:
  /// **'No bot is working right now'**
  String get islandNothing;

  /// No description provided for @islandQuickAsk.
  ///
  /// In en, this message translates to:
  /// **'Quick ask…'**
  String get islandQuickAsk;

  /// No description provided for @islandOpenCasama.
  ///
  /// In en, this message translates to:
  /// **'Open Casama'**
  String get islandOpenCasama;

  /// No description provided for @islandSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings…'**
  String get islandSettings;

  /// No description provided for @islandQuit.
  ///
  /// In en, this message translates to:
  /// **'Quit Casama'**
  String get islandQuit;

  /// No description provided for @islandAskHint.
  ///
  /// In en, this message translates to:
  /// **'Ask a bot…'**
  String get islandAskHint;

  /// No description provided for @islandNeedsYou.
  ///
  /// In en, this message translates to:
  /// **'Needs you'**
  String get islandNeedsYou;

  /// No description provided for @islandDropHere.
  ///
  /// In en, this message translates to:
  /// **'Drop to ask a bot'**
  String get islandDropHere;

  /// No description provided for @islandBotWorking.
  ///
  /// In en, this message translates to:
  /// **'A bot is working'**
  String get islandBotWorking;

  /// No description provided for @islandOnThisComputer.
  ///
  /// In en, this message translates to:
  /// **'on this computer'**
  String get islandOnThisComputer;

  /// The Mac's notch during a voice call with a bot, beside the bot's name and the call's length.
  ///
  /// In en, this message translates to:
  /// **'On a call'**
  String get islandOnACall;

  /// No description provided for @islandStartElsewhere.
  ///
  /// In en, this message translates to:
  /// **'Bots you start elsewhere'**
  String get islandStartElsewhere;

  /// No description provided for @islandStartElsewhereHelp.
  ///
  /// In en, this message translates to:
  /// **'Show what you start on another device, such as your Mac, on this phone\'s Lock Screen too.'**
  String get islandStartElsewhereHelp;

  /// No description provided for @islandBotsAtWork.
  ///
  /// In en, this message translates to:
  /// **'Bots at work'**
  String get islandBotsAtWork;

  /// No description provided for @islandSteps.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 step} other{{count} steps}}'**
  String islandSteps(int count);

  /// No description provided for @showBotsInNotch.
  ///
  /// In en, this message translates to:
  /// **'Show bots in the notch'**
  String get showBotsInNotch;

  /// No description provided for @showBotsInNotchHelp.
  ///
  /// In en, this message translates to:
  /// **'What your bots are doing, around the camera. The menu bar icon shows it either way.'**
  String get showBotsInNotchHelp;

  /// No description provided for @notchOnHover.
  ///
  /// In en, this message translates to:
  /// **'Open the notch on hover'**
  String get notchOnHover;

  /// No description provided for @notchOnHoverHelp.
  ///
  /// In en, this message translates to:
  /// **'Off: click the notch to open it.'**
  String get notchOnHoverHelp;

  /// No description provided for @sitePublishToWeb.
  ///
  /// In en, this message translates to:
  /// **'Publish to the Web'**
  String get sitePublishToWeb;

  /// No description provided for @sitePublishToWebHelp.
  ///
  /// In en, this message translates to:
  /// **'Give it its own web address.'**
  String get sitePublishToWebHelp;

  /// No description provided for @siteAddressName.
  ///
  /// In en, this message translates to:
  /// **'Address name'**
  String get siteAddressName;

  /// No description provided for @siteAddressRules.
  ///
  /// In en, this message translates to:
  /// **'3 to 40 lowercase letters, numbers and hyphens, starting and ending with a letter or number.'**
  String get siteAddressRules;

  /// No description provided for @siteAddressChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get siteAddressChecking;

  /// No description provided for @siteAddressAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get siteAddressAvailable;

  /// No description provided for @siteAddressTaken.
  ///
  /// In en, this message translates to:
  /// **'This name isn\'t available.'**
  String get siteAddressTaken;

  /// No description provided for @siteAnyoneCanOpen.
  ///
  /// In en, this message translates to:
  /// **'Anyone with the address will be able to open it.'**
  String get siteAnyoneCanOpen;

  /// No description provided for @sitePublish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get sitePublish;

  /// No description provided for @siteOnTheWeb.
  ///
  /// In en, this message translates to:
  /// **'On the web'**
  String get siteOnTheWeb;

  /// No description provided for @siteSearchEngines.
  ///
  /// In en, this message translates to:
  /// **'Let Search Engines Find It'**
  String get siteSearchEngines;

  /// No description provided for @siteSearchEnginesHelp.
  ///
  /// In en, this message translates to:
  /// **'Lists it in Google and other search engines.'**
  String get siteSearchEnginesHelp;

  /// No description provided for @siteSearchEnginesPaid.
  ///
  /// In en, this message translates to:
  /// **'Needs a paid plan.'**
  String get siteSearchEnginesPaid;

  /// No description provided for @siteUseOwnDomain.
  ///
  /// In en, this message translates to:
  /// **'Use Your Own Domain'**
  String get siteUseOwnDomain;

  /// No description provided for @siteUnpublish.
  ///
  /// In en, this message translates to:
  /// **'Unpublish'**
  String get siteUnpublish;

  /// No description provided for @siteUnpublishTitle.
  ///
  /// In en, this message translates to:
  /// **'Unpublish this site?'**
  String get siteUnpublishTitle;

  /// No description provided for @siteUnpublishBody.
  ///
  /// In en, this message translates to:
  /// **'It stops opening at its web addresses. It stays in your Library.'**
  String get siteUnpublishBody;

  /// No description provided for @siteHostLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get siteHostLive;

  /// No description provided for @siteHostWaitingForDns.
  ///
  /// In en, this message translates to:
  /// **'Waiting for DNS'**
  String get siteHostWaitingForDns;

  /// No description provided for @siteHostGettingCertificate.
  ///
  /// In en, this message translates to:
  /// **'Getting its certificate'**
  String get siteHostGettingCertificate;

  /// No description provided for @siteHostNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get siteHostNeedsAttention;

  /// No description provided for @siteHostPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get siteHostPaused;

  /// No description provided for @siteHostSuspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get siteHostSuspended;

  /// No description provided for @settingsDomains.
  ///
  /// In en, this message translates to:
  /// **'Domains'**
  String get settingsDomains;

  /// No description provided for @settingsDomainsHelp.
  ///
  /// In en, this message translates to:
  /// **'Open your sites at a domain you own.'**
  String get settingsDomainsHelp;

  /// No description provided for @settingsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search settings'**
  String get settingsSearchHint;

  /// No description provided for @settingsSearchNone.
  ///
  /// In en, this message translates to:
  /// **'No settings match “{query}”.'**
  String settingsSearchNone(String query);

  /// No description provided for @domainsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Connect a domain you own, like bakery.com, and your site opens there.'**
  String get domainsEmpty;

  /// No description provided for @domainsConnectOwn.
  ///
  /// In en, this message translates to:
  /// **'Connect a Domain You Own'**
  String get domainsConnectOwn;

  /// No description provided for @domainStateLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get domainStateLive;

  /// No description provided for @domainStateWaitingDns.
  ///
  /// In en, this message translates to:
  /// **'Waiting for DNS'**
  String get domainStateWaitingDns;

  /// No description provided for @domainStateWaitingCert.
  ///
  /// In en, this message translates to:
  /// **'Getting Its Certificate'**
  String get domainStateWaitingCert;

  /// No description provided for @domainStatePaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get domainStatePaused;

  /// No description provided for @domainStateNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs Attention'**
  String get domainStateNeedsAttention;

  /// No description provided for @domainNoSite.
  ///
  /// In en, this message translates to:
  /// **'No site yet'**
  String get domainNoSite;

  /// No description provided for @domainConnectField.
  ///
  /// In en, this message translates to:
  /// **'Your domain'**
  String get domainConnectField;

  /// No description provided for @domainConnectHelp.
  ///
  /// In en, this message translates to:
  /// **'Type it like bakery.com, www.bakery.com or shop.bakery.com.'**
  String get domainConnectHelp;

  /// No description provided for @domainConnectSite.
  ///
  /// In en, this message translates to:
  /// **'Site to show'**
  String get domainConnectSite;

  /// No description provided for @domainSiteNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get domainSiteNone;

  /// No description provided for @domainSiteNoneHelp.
  ///
  /// In en, this message translates to:
  /// **'The domain shows nothing until you pick a site.'**
  String get domainSiteNoneHelp;

  /// No description provided for @domainConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get domainConnect;

  /// No description provided for @domainClaimTitle.
  ///
  /// In en, this message translates to:
  /// **'Show it\'s yours'**
  String get domainClaimTitle;

  /// No description provided for @domainClaimBody.
  ///
  /// In en, this message translates to:
  /// **'Another workspace has connected this domain. Add this record to show it\'s yours, then tap Connect again.'**
  String get domainClaimBody;

  /// No description provided for @domainRecordType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get domainRecordType;

  /// No description provided for @domainRecordName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get domainRecordName;

  /// No description provided for @domainRecordValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get domainRecordValue;

  /// No description provided for @domainSite.
  ///
  /// In en, this message translates to:
  /// **'Site'**
  String get domainSite;

  /// No description provided for @domainPickSite.
  ///
  /// In en, this message translates to:
  /// **'Choose a Site'**
  String get domainPickSite;

  /// No description provided for @domainHosts.
  ///
  /// In en, this message translates to:
  /// **'Addresses'**
  String get domainHosts;

  /// No description provided for @domainPrimary.
  ///
  /// In en, this message translates to:
  /// **'Primary'**
  String get domainPrimary;

  /// No description provided for @domainPrimaryHelp.
  ///
  /// In en, this message translates to:
  /// **'Visitors land here; the other addresses send them to it.'**
  String get domainPrimaryHelp;

  /// No description provided for @domainMakePrimary.
  ///
  /// In en, this message translates to:
  /// **'Make Primary'**
  String get domainMakePrimary;

  /// No description provided for @domainRecordsTitle.
  ///
  /// In en, this message translates to:
  /// **'Records to add'**
  String get domainRecordsTitle;

  /// No description provided for @domainRecordsAtCloudflare.
  ///
  /// In en, this message translates to:
  /// **'Add these at Cloudflare. Set the records to DNS only.'**
  String get domainRecordsAtCloudflare;

  /// No description provided for @domainRecordsAt.
  ///
  /// In en, this message translates to:
  /// **'Add these in your DNS settings at {provider}.'**
  String domainRecordsAt(String provider);

  /// No description provided for @domainRecordsGeneric.
  ///
  /// In en, this message translates to:
  /// **'Add these where your domain\'s DNS is managed, usually the company you bought it from.'**
  String get domainRecordsGeneric;

  /// No description provided for @domainRecordsNone.
  ///
  /// In en, this message translates to:
  /// **'Nothing to add. You\'re all set.'**
  String get domainRecordsNone;

  /// No description provided for @domainRecordOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get domainRecordOptional;

  /// No description provided for @domainRecordForward.
  ///
  /// In en, this message translates to:
  /// **'Turn on forwarding from {from} to {to} at the company you bought the domain from.'**
  String domainRecordForward(String from, String to);

  /// No description provided for @domainRecordFound.
  ///
  /// In en, this message translates to:
  /// **'Found'**
  String get domainRecordFound;

  /// No description provided for @domainRecordNotFound.
  ///
  /// In en, this message translates to:
  /// **'Not found yet'**
  String get domainRecordNotFound;

  /// No description provided for @domainCheckAgain.
  ///
  /// In en, this message translates to:
  /// **'Check Again'**
  String get domainCheckAgain;

  /// No description provided for @domainCheckTooSoon.
  ///
  /// In en, this message translates to:
  /// **'We just checked. Try again in a few seconds.'**
  String get domainCheckTooSoon;

  /// No description provided for @domainChecksItself.
  ///
  /// In en, this message translates to:
  /// **'We also check by ourselves, so you can leave this screen.'**
  String get domainChecksItself;

  /// No description provided for @domainHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get domainHistory;

  /// No description provided for @domainEventConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get domainEventConnected;

  /// No description provided for @domainEventProved.
  ///
  /// In en, this message translates to:
  /// **'Records found'**
  String get domainEventProved;

  /// No description provided for @domainEventLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get domainEventLive;

  /// No description provided for @domainEventNeedsDns.
  ///
  /// In en, this message translates to:
  /// **'Still waiting for DNS'**
  String get domainEventNeedsDns;

  /// No description provided for @domainEventFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t finish setting up'**
  String get domainEventFailed;

  /// No description provided for @domainEventDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Records removed, so it was disconnected'**
  String get domainEventDisconnected;

  /// No description provided for @domainEventPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused: your plan doesn\'t cover it'**
  String get domainEventPaused;

  /// No description provided for @domainEventResumed.
  ///
  /// In en, this message translates to:
  /// **'Back on'**
  String get domainEventResumed;

  /// No description provided for @domainEventRemoved.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get domainEventRemoved;

  /// No description provided for @domainEventClaim.
  ///
  /// In en, this message translates to:
  /// **'Asked to show it\'s yours'**
  String get domainEventClaim;

  /// No description provided for @domainEventClaimAttempt.
  ///
  /// In en, this message translates to:
  /// **'Another workspace tried to connect it'**
  String get domainEventClaimAttempt;

  /// No description provided for @domainEventOverLimit.
  ///
  /// In en, this message translates to:
  /// **'Over your plan\'s limit'**
  String get domainEventOverLimit;

  /// No description provided for @domainEventSuspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get domainEventSuspended;

  /// No description provided for @domainEventOther.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get domainEventOther;

  /// No description provided for @domainDisconnectTitle.
  ///
  /// In en, this message translates to:
  /// **'Disconnect {name}?'**
  String domainDisconnectTitle(String name);

  /// No description provided for @domainDisconnectBody.
  ///
  /// In en, this message translates to:
  /// **'Your site stops opening at this domain. You can remove its records at your DNS company afterwards.'**
  String get domainDisconnectBody;

  /// No description provided for @domainsFind.
  ///
  /// In en, this message translates to:
  /// **'Find a Domain'**
  String get domainsFind;

  /// No description provided for @domainsEmptyBuy.
  ///
  /// In en, this message translates to:
  /// **'Buy a domain for your site, or connect one you own.'**
  String get domainsEmptyBuy;

  /// No description provided for @domainFindField.
  ///
  /// In en, this message translates to:
  /// **'Name or a few words'**
  String get domainFindField;

  /// No description provided for @domainFindHint.
  ///
  /// In en, this message translates to:
  /// **'bakery'**
  String get domainFindHint;

  /// No description provided for @domainFindHelp.
  ///
  /// In en, this message translates to:
  /// **'Prices are per year and before tax.'**
  String get domainFindHelp;

  /// No description provided for @domainFindNone.
  ///
  /// In en, this message translates to:
  /// **'No names found. Try other words.'**
  String get domainFindNone;

  /// No description provided for @domainFindNotOffered.
  ///
  /// In en, this message translates to:
  /// **'Buying a domain isn\'t available in this app. You can still connect a domain you own.'**
  String get domainFindNotOffered;

  /// No description provided for @domainPricePerYear.
  ///
  /// In en, this message translates to:
  /// **'{price} a year plus tax'**
  String domainPricePerYear(String price);

  /// No description provided for @domainRenewsAt.
  ///
  /// In en, this message translates to:
  /// **'Renews at {price}'**
  String domainRenewsAt(String price);

  /// No description provided for @domainReasonTaken.
  ///
  /// In en, this message translates to:
  /// **'Taken'**
  String get domainReasonTaken;

  /// No description provided for @domainReasonPremium.
  ///
  /// In en, this message translates to:
  /// **'Premium name, not sold here'**
  String get domainReasonPremium;

  /// No description provided for @domainReasonNotSold.
  ///
  /// In en, this message translates to:
  /// **'Not sold here'**
  String get domainReasonNotSold;

  /// No description provided for @domainBuy.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get domainBuy;

  /// No description provided for @domainBuyTitle.
  ///
  /// In en, this message translates to:
  /// **'Buy {name}'**
  String domainBuyTitle(String name);

  /// No description provided for @domainBuyPrice.
  ///
  /// In en, this message translates to:
  /// **'{price} for the first year, then {renew} a year, plus tax.'**
  String domainBuyPrice(String price, String renew);

  /// No description provided for @domainBuyFinal.
  ///
  /// In en, this message translates to:
  /// **'Sales are final once the domain is registered. If it can\'t be registered, you get a full refund.'**
  String get domainBuyFinal;

  /// No description provided for @domainBuyTerms.
  ///
  /// In en, this message translates to:
  /// **'I accept the domain terms'**
  String get domainBuyTerms;

  /// No description provided for @domainBuyReadTerms.
  ///
  /// In en, this message translates to:
  /// **'Read the Terms'**
  String get domainBuyReadTerms;

  /// No description provided for @domainRenewAuto.
  ///
  /// In en, this message translates to:
  /// **'Renew Automatically'**
  String get domainRenewAuto;

  /// No description provided for @domainRenewAutoHelp.
  ///
  /// In en, this message translates to:
  /// **'Charges your saved payment method about two weeks before it expires.'**
  String get domainRenewAutoHelp;

  /// No description provided for @domainBuySite.
  ///
  /// In en, this message translates to:
  /// **'Site to show'**
  String get domainBuySite;

  /// No description provided for @domainBuyPayInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Finish paying in your browser. This screen follows along.'**
  String get domainBuyPayInBrowser;

  /// No description provided for @domainContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact Details'**
  String get domainContactTitle;

  /// No description provided for @domainContactHelp.
  ///
  /// In en, this message translates to:
  /// **'The person or business the domain is registered to. Registrars keep these private.'**
  String get domainContactHelp;

  /// No description provided for @domainContactFirstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get domainContactFirstName;

  /// No description provided for @domainContactLastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get domainContactLastName;

  /// No description provided for @domainContactOrganization.
  ///
  /// In en, this message translates to:
  /// **'Business (optional)'**
  String get domainContactOrganization;

  /// No description provided for @domainContactAddress1.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get domainContactAddress1;

  /// No description provided for @domainContactAddress2.
  ///
  /// In en, this message translates to:
  /// **'Address line 2 (optional)'**
  String get domainContactAddress2;

  /// No description provided for @domainContactCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get domainContactCity;

  /// No description provided for @domainContactState.
  ///
  /// In en, this message translates to:
  /// **'State or region'**
  String get domainContactState;

  /// No description provided for @domainContactZip.
  ///
  /// In en, this message translates to:
  /// **'Postal code'**
  String get domainContactZip;

  /// No description provided for @domainContactCountry.
  ///
  /// In en, this message translates to:
  /// **'Country code'**
  String get domainContactCountry;

  /// No description provided for @domainContactCountryHint.
  ///
  /// In en, this message translates to:
  /// **'US'**
  String get domainContactCountryHint;

  /// No description provided for @domainContactPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get domainContactPhone;

  /// No description provided for @domainContactPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'+1 415 555 0100'**
  String get domainContactPhoneHint;

  /// No description provided for @domainContactEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get domainContactEmail;

  /// No description provided for @domainContactRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get domainContactRequired;

  /// No description provided for @domainContactCountryInvalid.
  ///
  /// In en, this message translates to:
  /// **'Use a two-letter code, like US'**
  String get domainContactCountryInvalid;

  /// No description provided for @domainContactPhoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Use international form, like +1 415 555 0100'**
  String get domainContactPhoneInvalid;

  /// No description provided for @domainContactEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get domainContactEmailInvalid;

  /// No description provided for @domainContactSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get domainContactSave;

  /// No description provided for @domainContactSaved.
  ///
  /// In en, this message translates to:
  /// **'Contact details saved.'**
  String get domainContactSaved;

  /// No description provided for @domainContactChangeNote.
  ///
  /// In en, this message translates to:
  /// **'Changes apply to every domain this workspace bought. A new email has to be confirmed again.'**
  String get domainContactChangeNote;

  /// No description provided for @domainOrderTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Order'**
  String get domainOrderTitle;

  /// No description provided for @domainOrderWaitingPayment.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your payment in the browser.'**
  String get domainOrderWaitingPayment;

  /// No description provided for @domainOrderRegistering.
  ///
  /// In en, this message translates to:
  /// **'Registering {name}…'**
  String domainOrderRegistering(String name);

  /// No description provided for @domainOrderSettingUp.
  ///
  /// In en, this message translates to:
  /// **'Setting up {name}…'**
  String domainOrderSettingUp(String name);

  /// No description provided for @domainOrderRefunding.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t register {name}. Refunding you now…'**
  String domainOrderRefunding(String name);

  /// No description provided for @domainOrderRefunded.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t register {name}, so we refunded you in full.'**
  String domainOrderRefunded(String name);

  /// No description provided for @domainOrderAbandoned.
  ///
  /// In en, this message translates to:
  /// **'This checkout wasn\'t paid, so nothing was charged.'**
  String get domainOrderAbandoned;

  /// No description provided for @domainOrderNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong with this order. We\'ve been told and will sort it out.'**
  String get domainOrderNeedsAttention;

  /// No description provided for @domainOrderDone.
  ///
  /// In en, this message translates to:
  /// **'{name} is yours.'**
  String domainOrderDone(String name);

  /// No description provided for @domainOrderLeave.
  ///
  /// In en, this message translates to:
  /// **'You can leave this screen. We\'ll let you know when it\'s ready.'**
  String get domainOrderLeave;

  /// No description provided for @domainOrderBack.
  ///
  /// In en, this message translates to:
  /// **'Back to Domains'**
  String get domainOrderBack;

  /// No description provided for @domainRenewsOn.
  ///
  /// In en, this message translates to:
  /// **'Renews on {date}'**
  String domainRenewsOn(String date);

  /// No description provided for @domainExpiresOn.
  ///
  /// In en, this message translates to:
  /// **'Expires on {date}'**
  String domainExpiresOn(String date);

  /// No description provided for @domainRenewPrice.
  ///
  /// In en, this message translates to:
  /// **'{price} a year plus tax'**
  String domainRenewPrice(String price);

  /// No description provided for @domainRenewNow.
  ///
  /// In en, this message translates to:
  /// **'Renew Now'**
  String get domainRenewNow;

  /// No description provided for @domainRenewPayInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Finish paying in your browser. The new date shows here once it\'s paid.'**
  String get domainRenewPayInBrowser;

  /// No description provided for @domainRenewCharged.
  ///
  /// In en, this message translates to:
  /// **'Renewed. The new date shows here in a minute.'**
  String get domainRenewCharged;

  /// No description provided for @domainRegistration.
  ///
  /// In en, this message translates to:
  /// **'Registration'**
  String get domainRegistration;

  /// No description provided for @domainExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired on {date}. Renew within 25 days of that date to keep it.'**
  String domainExpired(String date);

  /// No description provided for @domainLapsed.
  ///
  /// In en, this message translates to:
  /// **'This domain has lapsed. Write to support to ask about restoring it; that isn\'t guaranteed.'**
  String get domainLapsed;

  /// No description provided for @domainSuspendedLine.
  ///
  /// In en, this message translates to:
  /// **'This domain is suspended. Write to support to find out why.'**
  String get domainSuspendedLine;

  /// No description provided for @domainVerifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm the registrant email'**
  String get domainVerifyTitle;

  /// No description provided for @domainVerifyBody.
  ///
  /// In en, this message translates to:
  /// **'The registrar sent an email to the registrant\'s address. Open it and confirm, or the domain stops working.'**
  String get domainVerifyBody;

  /// No description provided for @domainVerifySendAgain.
  ///
  /// In en, this message translates to:
  /// **'Send Again'**
  String get domainVerifySendAgain;

  /// No description provided for @domainVerifySent.
  ///
  /// In en, this message translates to:
  /// **'Sent. Check the registrant\'s inbox.'**
  String get domainVerifySent;

  /// No description provided for @domainDnsRecords.
  ///
  /// In en, this message translates to:
  /// **'DNS Records'**
  String get domainDnsRecords;

  /// No description provided for @domainDnsRecordsHelp.
  ///
  /// In en, this message translates to:
  /// **'Email, subdomains and site checks'**
  String get domainDnsRecordsHelp;

  /// No description provided for @domainMoveOut.
  ///
  /// In en, this message translates to:
  /// **'Move to Another Registrar'**
  String get domainMoveOut;

  /// No description provided for @domainMoveOutAfter.
  ///
  /// In en, this message translates to:
  /// **'It can move after {date}'**
  String domainMoveOutAfter(String date);

  /// No description provided for @domainMoveOutHelp.
  ///
  /// In en, this message translates to:
  /// **'Get a transfer code for another registrar'**
  String get domainMoveOutHelp;

  /// No description provided for @domainMoveOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Move {name}?'**
  String domainMoveOutTitle(String name);

  /// No description provided for @domainMoveOutBody.
  ///
  /// In en, this message translates to:
  /// **'This unlocks the domain and shows its transfer code once. Type {name} to confirm.'**
  String domainMoveOutBody(String name);

  /// No description provided for @domainMoveOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Get Transfer Code'**
  String get domainMoveOutConfirm;

  /// No description provided for @domainMoveOutLocked.
  ///
  /// In en, this message translates to:
  /// **'It can move after {date}.'**
  String domainMoveOutLocked(String date);

  /// No description provided for @domainTransferCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Transfer code'**
  String get domainTransferCodeTitle;

  /// No description provided for @domainTransferCodeBody.
  ///
  /// In en, this message translates to:
  /// **'Give this code to the new registrar. It\'s shown only this once, so copy it now.'**
  String get domainTransferCodeBody;

  /// No description provided for @domainTransferCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get domainTransferCode;

  /// No description provided for @domainUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Unlocked for a move'**
  String get domainUnlocked;

  /// No description provided for @domainLockAgain.
  ///
  /// In en, this message translates to:
  /// **'Lock Again'**
  String get domainLockAgain;

  /// No description provided for @domainLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked again.'**
  String get domainLocked;

  /// No description provided for @domainReauthTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign In Again'**
  String get domainReauthTitle;

  /// No description provided for @domainReauthSendCode.
  ///
  /// In en, this message translates to:
  /// **'Email Me a Code'**
  String get domainReauthSendCode;

  /// No description provided for @domainReauthCodeSent.
  ///
  /// In en, this message translates to:
  /// **'We sent a code to {email}.'**
  String domainReauthCodeSent(String email);

  /// No description provided for @domainReauthCode.
  ///
  /// In en, this message translates to:
  /// **'Code from the email'**
  String get domainReauthCode;

  /// No description provided for @domainReauthSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get domainReauthSignIn;

  /// No description provided for @domainReauthSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out and in again, then try once more.'**
  String get domainReauthSignOut;

  /// No description provided for @dnsRecordsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No records yet.'**
  String get dnsRecordsEmpty;

  /// No description provided for @dnsRecordAdd.
  ///
  /// In en, this message translates to:
  /// **'Add Record'**
  String get dnsRecordAdd;

  /// No description provided for @dnsRecordEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit Record'**
  String get dnsRecordEdit;

  /// No description provided for @dnsRecordManaged.
  ///
  /// In en, this message translates to:
  /// **'Used by your Casama site'**
  String get dnsRecordManaged;

  /// No description provided for @dnsRecordType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get dnsRecordType;

  /// No description provided for @dnsRecordHost.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get dnsRecordHost;

  /// No description provided for @dnsRecordHostHelp.
  ///
  /// In en, this message translates to:
  /// **'Leave empty for {name} itself, or type www, shop…'**
  String dnsRecordHostHelp(String name);

  /// No description provided for @dnsRecordAnswer.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get dnsRecordAnswer;

  /// No description provided for @dnsRecordTtl.
  ///
  /// In en, this message translates to:
  /// **'TTL (seconds)'**
  String get dnsRecordTtl;

  /// No description provided for @dnsRecordPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get dnsRecordPriority;

  /// No description provided for @dnsRecordSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get dnsRecordSave;

  /// No description provided for @dnsRecordDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this record?'**
  String get dnsRecordDeleteTitle;

  /// No description provided for @dnsRecordDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'{type} {host} → {answer}'**
  String dnsRecordDeleteBody(String type, String host, String answer);

  /// No description provided for @dnsRecordTtlInvalid.
  ///
  /// In en, this message translates to:
  /// **'300 seconds or more'**
  String get dnsRecordTtlInvalid;

  /// No description provided for @dnsRecordAnswerRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get dnsRecordAnswerRequired;

  /// No description provided for @adminDomains.
  ///
  /// In en, this message translates to:
  /// **'Domains'**
  String get adminDomains;

  /// No description provided for @adminMail.
  ///
  /// In en, this message translates to:
  /// **'Mail'**
  String get adminMail;

  /// No description provided for @adminMailHealth.
  ///
  /// In en, this message translates to:
  /// **'{sent} sent · {bounced} bounced · {complained} complained in 30 days'**
  String adminMailHealth(int sent, int bounced, int complained);

  /// No description provided for @adminMailAutoPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused automatically'**
  String get adminMailAutoPaused;

  /// No description provided for @adminMailPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get adminMailPause;

  /// No description provided for @adminMailPauseTitle.
  ///
  /// In en, this message translates to:
  /// **'Pause {address}?'**
  String adminMailPauseTitle(String address);

  /// No description provided for @adminMailLift.
  ///
  /// In en, this message translates to:
  /// **'Lift'**
  String get adminMailLift;

  /// No description provided for @adminMailLiftTitle.
  ///
  /// In en, this message translates to:
  /// **'Lift the pause on {address}?'**
  String adminMailLiftTitle(String address);

  /// No description provided for @adminMailLiftBody.
  ///
  /// In en, this message translates to:
  /// **'This clears the automatic pause. The owner can pause it again themselves.'**
  String get adminMailLiftBody;

  /// No description provided for @adminMailReserved.
  ///
  /// In en, this message translates to:
  /// **'Reserved names'**
  String get adminMailReserved;

  /// No description provided for @adminMailReservedHelp.
  ///
  /// In en, this message translates to:
  /// **'One name per line. Nobody can claim these, on top of the built-in list.'**
  String get adminMailReservedHelp;

  /// No description provided for @adminDomainsConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get adminDomainsConnected;

  /// No description provided for @adminDomainsRegistered.
  ///
  /// In en, this message translates to:
  /// **'Bought'**
  String get adminDomainsRegistered;

  /// No description provided for @adminDomainsLiveHosts.
  ///
  /// In en, this message translates to:
  /// **'Live addresses'**
  String get adminDomainsLiveHosts;

  /// No description provided for @adminDomainsSuspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get adminDomainsSuspended;

  /// No description provided for @adminDomainsBalance.
  ///
  /// In en, this message translates to:
  /// **'Registrar balance'**
  String get adminDomainsBalance;

  /// No description provided for @adminDomainsBalanceUnknown.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get adminDomainsBalanceUnknown;

  /// No description provided for @adminDomainsOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders that need a person'**
  String get adminDomainsOrders;

  /// No description provided for @adminDomainsNoOrders.
  ///
  /// In en, this message translates to:
  /// **'No orders need a person.'**
  String get adminDomainsNoOrders;

  /// No description provided for @adminDomainsList.
  ///
  /// In en, this message translates to:
  /// **'Domains'**
  String get adminDomainsList;

  /// No description provided for @adminDomainsNone.
  ///
  /// In en, this message translates to:
  /// **'No domains yet.'**
  String get adminDomainsNone;

  /// No description provided for @adminDomainsApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get adminDomainsApprove;

  /// No description provided for @adminDomainsRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get adminDomainsRetry;

  /// No description provided for @adminDomainsApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved. Registering now.'**
  String get adminDomainsApproved;

  /// No description provided for @adminDomainsRetried.
  ///
  /// In en, this message translates to:
  /// **'Trying again.'**
  String get adminDomainsRetried;

  /// No description provided for @adminDomainsSuspend.
  ///
  /// In en, this message translates to:
  /// **'Suspend'**
  String get adminDomainsSuspend;

  /// No description provided for @adminDomainsUnsuspend.
  ///
  /// In en, this message translates to:
  /// **'Unsuspend'**
  String get adminDomainsUnsuspend;

  /// No description provided for @adminDomainsSuspendTitle.
  ///
  /// In en, this message translates to:
  /// **'Suspend {name}?'**
  String adminDomainsSuspendTitle(String name);

  /// No description provided for @adminDomainsSuspendBody.
  ///
  /// In en, this message translates to:
  /// **'Its site goes offline and the domain is locked at the registrar.'**
  String get adminDomainsSuspendBody;

  /// No description provided for @adminDomainsUnsuspendTitle.
  ///
  /// In en, this message translates to:
  /// **'Unsuspend {name}?'**
  String adminDomainsUnsuspendTitle(String name);

  /// No description provided for @adminDomainsUnsuspendBody.
  ///
  /// In en, this message translates to:
  /// **'Its site comes back and the domain works again.'**
  String get adminDomainsUnsuspendBody;

  /// No description provided for @adminDomainsAttempts.
  ///
  /// In en, this message translates to:
  /// **'{count} tries'**
  String adminDomainsAttempts(int count);

  /// No description provided for @adminDomainsNoWorkspace.
  ///
  /// In en, this message translates to:
  /// **'No workspace'**
  String get adminDomainsNoWorkspace;

  /// No description provided for @deleteAccountDomains.
  ///
  /// In en, this message translates to:
  /// **'Bought domains in your workspaces'**
  String get deleteAccountDomains;

  /// No description provided for @deleteAccountDomainsBody.
  ///
  /// In en, this message translates to:
  /// **'These domains stay registered to their registrant until they expire, stop renewing, and their sites go offline.'**
  String get deleteAccountDomainsBody;

  /// No description provided for @whatsNew010Sites.
  ///
  /// In en, this message translates to:
  /// **'Put a page on the web at its own address, and use your own domain for it.'**
  String get whatsNew010Sites;

  /// No description provided for @inAppAlertOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get inAppAlertOpen;

  /// No description provided for @pushPrefsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get pushPrefsTitle;

  /// No description provided for @pushPrefsHelp.
  ///
  /// In en, this message translates to:
  /// **'Choose what buzzes your devices. Everything still lands in your inbox.'**
  String get pushPrefsHelp;

  /// No description provided for @pushAllOn.
  ///
  /// In en, this message translates to:
  /// **'All on'**
  String get pushAllOn;

  /// No description provided for @pushOneOff.
  ///
  /// In en, this message translates to:
  /// **'{kind} off'**
  String pushOneOff(String kind);

  /// No description provided for @pushSomeOff.
  ///
  /// In en, this message translates to:
  /// **'{count} kinds off'**
  String pushSomeOff(int count);

  /// No description provided for @pushReplies.
  ///
  /// In en, this message translates to:
  /// **'Replies'**
  String get pushReplies;

  /// No description provided for @pushRepliesHelp.
  ///
  /// In en, this message translates to:
  /// **'When a bot answers something you asked, if you\'ve left the chat.'**
  String get pushRepliesHelp;

  /// No description provided for @pushNeedsYou.
  ///
  /// In en, this message translates to:
  /// **'Needs you'**
  String get pushNeedsYou;

  /// No description provided for @pushNeedsYouHelp.
  ///
  /// In en, this message translates to:
  /// **'Approvals, passwords and takeovers your bots are waiting for.'**
  String get pushNeedsYouHelp;

  /// No description provided for @pushNeedsYouOffWarning.
  ///
  /// In en, this message translates to:
  /// **'Off: your bots will wait until you open the app.'**
  String get pushNeedsYouOffWarning;

  /// No description provided for @pushRoutines.
  ///
  /// In en, this message translates to:
  /// **'Routines and briefs'**
  String get pushRoutines;

  /// No description provided for @pushRoutinesHelp.
  ///
  /// In en, this message translates to:
  /// **'Results of routines and your morning brief.'**
  String get pushRoutinesHelp;

  /// No description provided for @pushSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Suggestions and check-ins'**
  String get pushSuggestions;

  /// No description provided for @pushSuggestionsHelp.
  ///
  /// In en, this message translates to:
  /// **'Things your bots offer to do for you.'**
  String get pushSuggestionsHelp;

  /// No description provided for @pushAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get pushAccount;

  /// No description provided for @pushAccountHelp.
  ///
  /// In en, this message translates to:
  /// **'Credits running low, projects and your server.'**
  String get pushAccountHelp;

  /// No description provided for @pushHideReplyText.
  ///
  /// In en, this message translates to:
  /// **'Hide reply text'**
  String get pushHideReplyText;

  /// No description provided for @pushHideReplyTextHelp.
  ///
  /// In en, this message translates to:
  /// **'Notifications say a bot replied, without its words.'**
  String get pushHideReplyTextHelp;

  /// No description provided for @reactToMessage.
  ///
  /// In en, this message translates to:
  /// **'React'**
  String get reactToMessage;

  /// No description provided for @moreReactions.
  ///
  /// In en, this message translates to:
  /// **'More reactions'**
  String get moreReactions;

  /// No description provided for @reactionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reactions'**
  String get reactionsTitle;

  /// No description provided for @reactionsAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get reactionsAll;

  /// No description provided for @reactionsYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get reactionsYou;

  /// No description provided for @reactionsTapToRemove.
  ///
  /// In en, this message translates to:
  /// **'Tap to remove'**
  String get reactionsTapToRemove;

  /// No description provided for @reactionsNone.
  ///
  /// In en, this message translates to:
  /// **'No reactions yet.'**
  String get reactionsNone;

  /// No description provided for @reactionsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load who reacted.'**
  String get reactionsLoadFailed;

  /// No description provided for @searchEmoji.
  ///
  /// In en, this message translates to:
  /// **'Search emoji'**
  String get searchEmoji;

  /// No description provided for @reactionChip.
  ///
  /// In en, this message translates to:
  /// **'{emoji}, {count, plural, =1{1 reaction} other{{count} reactions}}'**
  String reactionChip(String emoji, int count);

  /// No description provided for @reactionChipMine.
  ///
  /// In en, this message translates to:
  /// **'{emoji}, {count, plural, =1{1 reaction} other{{count} reactions}}, including yours'**
  String reactionChipMine(String emoji, int count);

  /// No description provided for @reactionQuick.
  ///
  /// In en, this message translates to:
  /// **'React with {emoji}'**
  String reactionQuick(String emoji);

  /// No description provided for @reactionRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove your {emoji} reaction'**
  String reactionRemove(String emoji);

  /// No description provided for @packsShelfTitle.
  ///
  /// In en, this message translates to:
  /// **'Packs'**
  String get packsShelfTitle;

  /// No description provided for @packsShelfHelp.
  ///
  /// In en, this message translates to:
  /// **'Bots, skills and routines that work together, added in one go.'**
  String get packsShelfHelp;

  /// No description provided for @packReviewed.
  ///
  /// In en, this message translates to:
  /// **'Reviewed'**
  String get packReviewed;

  /// No description provided for @packNotReviewed.
  ///
  /// In en, this message translates to:
  /// **'Not reviewed by Casama'**
  String get packNotReviewed;

  /// No description provided for @packCountBots.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 bot} other{{count} bots}}'**
  String packCountBots(int count);

  /// No description provided for @packCountSkills.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 skill} other{{count} skills}}'**
  String packCountSkills(int count);

  /// No description provided for @packCountRoutines.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 routine} other{{count} routines}}'**
  String packCountRoutines(int count);

  /// No description provided for @packCountApps.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 app} other{{count} apps}}'**
  String packCountApps(int count);

  /// No description provided for @packCountLooks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 look} other{{count} looks}}'**
  String packCountLooks(int count);

  /// No description provided for @packCountTools.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 tool} other{{count} tools}}'**
  String packCountTools(int count);

  /// No description provided for @packCountItems.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String packCountItems(int count);

  /// No description provided for @packStarterSet.
  ///
  /// In en, this message translates to:
  /// **'Starter set'**
  String get packStarterSet;

  /// No description provided for @packAddFromLink.
  ///
  /// In en, this message translates to:
  /// **'Add a pack from a link'**
  String get packAddFromLink;

  /// No description provided for @packAddFromLinkHelp.
  ///
  /// In en, this message translates to:
  /// **'Paste a GitHub link to a pack and see what it adds first.'**
  String get packAddFromLinkHelp;

  /// No description provided for @packAddFromFile.
  ///
  /// In en, this message translates to:
  /// **'Add from a file'**
  String get packAddFromFile;

  /// No description provided for @packAddFromFileHelp.
  ///
  /// In en, this message translates to:
  /// **'Pick a pack\'s .zip file.'**
  String get packAddFromFileHelp;

  /// No description provided for @packLinkLabel.
  ///
  /// In en, this message translates to:
  /// **'GitHub link'**
  String get packLinkLabel;

  /// No description provided for @packFileUnreadable.
  ///
  /// In en, this message translates to:
  /// **'That file isn\'t a pack\'s .zip.'**
  String get packFileUnreadable;

  /// No description provided for @packFileTooBig.
  ///
  /// In en, this message translates to:
  /// **'That file is too big for a pack.'**
  String get packFileTooBig;

  /// No description provided for @packSource.
  ///
  /// In en, this message translates to:
  /// **'{where} at {commit}'**
  String packSource(String where, String commit);

  /// No description provided for @packFromFile.
  ///
  /// In en, this message translates to:
  /// **'From a file'**
  String get packFromFile;

  /// No description provided for @packFromShare.
  ///
  /// In en, this message translates to:
  /// **'Shared with you'**
  String get packFromShare;

  /// No description provided for @packAlreadyHere.
  ///
  /// In en, this message translates to:
  /// **'This workspace already has this pack.'**
  String get packAlreadyHere;

  /// No description provided for @packOpenInstalled.
  ///
  /// In en, this message translates to:
  /// **'See installed packs'**
  String get packOpenInstalled;

  /// No description provided for @packAdd.
  ///
  /// In en, this message translates to:
  /// **'Add pack'**
  String get packAdd;

  /// No description provided for @packWizardTitle.
  ///
  /// In en, this message translates to:
  /// **'Add {name}'**
  String packWizardTitle(String name);

  /// No description provided for @packWhatsInside.
  ///
  /// In en, this message translates to:
  /// **'What\'s inside'**
  String get packWhatsInside;

  /// No description provided for @packWhatsInsideHelp.
  ///
  /// In en, this message translates to:
  /// **'Untick anything you don\'t want.'**
  String get packWhatsInsideHelp;

  /// No description provided for @packSectionBots.
  ///
  /// In en, this message translates to:
  /// **'Bots'**
  String get packSectionBots;

  /// No description provided for @packSectionSkills.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get packSectionSkills;

  /// No description provided for @packSectionRoutines.
  ///
  /// In en, this message translates to:
  /// **'Routines'**
  String get packSectionRoutines;

  /// No description provided for @packSectionApps.
  ///
  /// In en, this message translates to:
  /// **'Apps'**
  String get packSectionApps;

  /// No description provided for @packSectionLooks.
  ///
  /// In en, this message translates to:
  /// **'Looks'**
  String get packSectionLooks;

  /// No description provided for @packSectionIncludes.
  ///
  /// In en, this message translates to:
  /// **'From the gallery'**
  String get packSectionIncludes;

  /// No description provided for @packSectionTools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get packSectionTools;

  /// No description provided for @packSkillRunsScripts.
  ///
  /// In en, this message translates to:
  /// **'Runs scripts on the bot\'s computer'**
  String get packSkillRunsScripts;

  /// No description provided for @packSkillForWorkspace.
  ///
  /// In en, this message translates to:
  /// **'For the whole workspace'**
  String get packSkillForWorkspace;

  /// No description provided for @packRoutineRuns.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Runs now and then} =1{Runs about once a week} other{Runs about {count} times a week}}'**
  String packRoutineRuns(int count);

  /// No description provided for @packAppHost.
  ///
  /// In en, this message translates to:
  /// **'Talks to {host}'**
  String packAppHost(String host);

  /// No description provided for @packToolRemote.
  ///
  /// In en, this message translates to:
  /// **'Connects to {url}'**
  String packToolRemote(String url);

  /// No description provided for @packIncludeMissing.
  ///
  /// In en, this message translates to:
  /// **'Not found in the gallery'**
  String get packIncludeMissing;

  /// No description provided for @packLookHelp.
  ///
  /// In en, this message translates to:
  /// **'You can use it on this device after adding.'**
  String get packLookHelp;

  /// No description provided for @packNothingTicked.
  ///
  /// In en, this message translates to:
  /// **'Tick at least one thing to add.'**
  String get packNothingTicked;

  /// No description provided for @packQuestions.
  ///
  /// In en, this message translates to:
  /// **'A few questions'**
  String get packQuestions;

  /// No description provided for @packQuestionsHelp.
  ///
  /// In en, this message translates to:
  /// **'The pack fills these into its bots and routines.'**
  String get packQuestionsHelp;

  /// No description provided for @packSecretsTitle.
  ///
  /// In en, this message translates to:
  /// **'Keys and settings'**
  String get packSecretsTitle;

  /// No description provided for @packSecretsHelp.
  ///
  /// In en, this message translates to:
  /// **'The pack\'s tools need these to work.'**
  String get packSecretsHelp;

  /// No description provided for @packReachTitle.
  ///
  /// In en, this message translates to:
  /// **'What it can reach'**
  String get packReachTitle;

  /// No description provided for @packReachHelp.
  ///
  /// In en, this message translates to:
  /// **'Worked out by Casama from the pack\'s files.'**
  String get packReachHelp;

  /// No description provided for @packReachRunsCode.
  ///
  /// In en, this message translates to:
  /// **'Runs code'**
  String get packReachRunsCode;

  /// No description provided for @packReachComputer.
  ///
  /// In en, this message translates to:
  /// **'Uses the bot\'s computer'**
  String get packReachComputer;

  /// No description provided for @packReachHosts.
  ///
  /// In en, this message translates to:
  /// **'Talks to {hosts}'**
  String packReachHosts(String hosts);

  /// No description provided for @packReachNoHosts.
  ///
  /// In en, this message translates to:
  /// **'Doesn\'t talk to other sites'**
  String get packReachNoHosts;

  /// No description provided for @packReachSecrets.
  ///
  /// In en, this message translates to:
  /// **'Uses keys: {names}'**
  String packReachSecrets(String names);

  /// No description provided for @packReachRuns.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No scheduled runs} =1{About 1 scheduled run a week} other{About {count} scheduled runs a week}}'**
  String packReachRuns(int count);

  /// No description provided for @packUnreviewedWarning.
  ///
  /// In en, this message translates to:
  /// **'Casama hasn\'t reviewed this pack. Add it only if you trust where it comes from. Its routines start switched off.'**
  String get packUnreviewedWarning;

  /// No description provided for @packPickBotTitle.
  ///
  /// In en, this message translates to:
  /// **'Which bot gets it?'**
  String get packPickBotTitle;

  /// No description provided for @packPickBotHelp.
  ///
  /// In en, this message translates to:
  /// **'This pack brings no bot. Pick one for its routines and tools.'**
  String get packPickBotHelp;

  /// No description provided for @packDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} is in'**
  String packDoneTitle(String name);

  /// No description provided for @packDoneHelp.
  ///
  /// In en, this message translates to:
  /// **'Here\'s what it added.'**
  String get packDoneHelp;

  /// No description provided for @packPendingHelp.
  ///
  /// In en, this message translates to:
  /// **'We\'ve asked an admin. The pack is added once they approve.'**
  String get packPendingHelp;

  /// No description provided for @packStatusInstalled.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get packStatusInstalled;

  /// No description provided for @packStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Waiting for an admin'**
  String get packStatusPending;

  /// No description provided for @packStatusSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get packStatusSkipped;

  /// No description provided for @packStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t work'**
  String get packStatusFailed;

  /// No description provided for @packStatusDevice.
  ///
  /// In en, this message translates to:
  /// **'On this device'**
  String get packStatusDevice;

  /// No description provided for @packConnectTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect its apps'**
  String get packConnectTitle;

  /// No description provided for @packConnectHelp.
  ///
  /// In en, this message translates to:
  /// **'Its bots work fully once these are connected.'**
  String get packConnectHelp;

  /// No description provided for @packLooksTitle.
  ///
  /// In en, this message translates to:
  /// **'Use a look on this device?'**
  String get packLooksTitle;

  /// No description provided for @packUseLook.
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get packUseLook;

  /// No description provided for @packLookInUse.
  ///
  /// In en, this message translates to:
  /// **'In use'**
  String get packLookInUse;

  /// No description provided for @packInstalledTitle.
  ///
  /// In en, this message translates to:
  /// **'That pack is already here'**
  String get packInstalledTitle;

  /// No description provided for @packsInstalledTitle.
  ///
  /// In en, this message translates to:
  /// **'Installed packs'**
  String get packsInstalledTitle;

  /// No description provided for @packsInstalledRow.
  ///
  /// In en, this message translates to:
  /// **'Packs this workspace added, with updates'**
  String get packsInstalledRow;

  /// No description provided for @packsInstalledEmpty.
  ///
  /// In en, this message translates to:
  /// **'No packs yet. Find one on the Packs shelf, or add one from a link.'**
  String get packsInstalledEmpty;

  /// No description provided for @packEditedBadge.
  ///
  /// In en, this message translates to:
  /// **'Edited by you'**
  String get packEditedBadge;

  /// No description provided for @packRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get packRemove;

  /// No description provided for @packUpToDate.
  ///
  /// In en, this message translates to:
  /// **'This pack is up to date.'**
  String get packUpToDate;

  /// No description provided for @packCantCheck.
  ///
  /// In en, this message translates to:
  /// **'This pack came from a file or link and can\'t check for updates.'**
  String get packCantCheck;

  /// No description provided for @packUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'Update {name}'**
  String packUpdateTitle(String name);

  /// No description provided for @packDiffAdded.
  ///
  /// In en, this message translates to:
  /// **'New: {names}'**
  String packDiffAdded(String names);

  /// No description provided for @packDiffRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed: {names}'**
  String packDiffRemoved(String names);

  /// No description provided for @packDiffChanged.
  ///
  /// In en, this message translates to:
  /// **'Changed: {name}'**
  String packDiffChanged(String name);

  /// No description provided for @packDiffHosts.
  ///
  /// In en, this message translates to:
  /// **'New sites it talks to: {hosts}'**
  String packDiffHosts(String hosts);

  /// No description provided for @packDiffSecrets.
  ///
  /// In en, this message translates to:
  /// **'New keys it needs: {names}'**
  String packDiffSecrets(String names);

  /// No description provided for @packDiffSchedules.
  ///
  /// In en, this message translates to:
  /// **'New schedules: {names}'**
  String packDiffSchedules(String names);

  /// No description provided for @packDiffRuns.
  ///
  /// In en, this message translates to:
  /// **'Scheduled runs a week: {from} → {to}'**
  String packDiffRuns(String from, String to);

  /// No description provided for @packDiffNone.
  ///
  /// In en, this message translates to:
  /// **'Nothing you\'d notice changed.'**
  String get packDiffNone;

  /// No description provided for @packEditedTitle.
  ///
  /// In en, this message translates to:
  /// **'Things you changed'**
  String get packEditedTitle;

  /// No description provided for @packEditedHelp.
  ///
  /// In en, this message translates to:
  /// **'Your version stays unless you switch it.'**
  String get packEditedHelp;

  /// No description provided for @packTakeTheirs.
  ///
  /// In en, this message translates to:
  /// **'Use the pack\'s version'**
  String get packTakeTheirs;

  /// No description provided for @packReachGrewTitle.
  ///
  /// In en, this message translates to:
  /// **'It reaches further'**
  String get packReachGrewTitle;

  /// No description provided for @packReachGrewHelp.
  ///
  /// In en, this message translates to:
  /// **'The new version can reach more than the one you have.'**
  String get packReachGrewHelp;

  /// No description provided for @packReachConfirm.
  ///
  /// In en, this message translates to:
  /// **'I\'ve checked what it can reach now'**
  String get packReachConfirm;

  /// No description provided for @packUpdated.
  ///
  /// In en, this message translates to:
  /// **'{name} is updated.'**
  String packUpdated(String name);

  /// No description provided for @packRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String packRemoveTitle(String name);

  /// No description provided for @packRemoveBody.
  ///
  /// In en, this message translates to:
  /// **'Its tools and keys go, and skills and routines you didn\'t change. App connections stay.'**
  String get packRemoveBody;

  /// No description provided for @packRemoveBots.
  ///
  /// In en, this message translates to:
  /// **'Also delete the bots this pack created'**
  String get packRemoveBots;

  /// No description provided for @packRemoved.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Pack removed.} =1{Pack removed. 1 item stayed because you changed it.} other{Pack removed. {count} items stayed because you changed them.}}'**
  String packRemoved(int count);

  /// No description provided for @sharePackTitle.
  ///
  /// In en, this message translates to:
  /// **'Share as pack'**
  String get sharePackTitle;

  /// No description provided for @sharePackRow.
  ///
  /// In en, this message translates to:
  /// **'Bundle bots and skills for someone else'**
  String get sharePackRow;

  /// No description provided for @sharePackHelp.
  ///
  /// In en, this message translates to:
  /// **'Keys, chats, memories, About you and the model choice are never included.'**
  String get sharePackHelp;

  /// No description provided for @sharePackBots.
  ///
  /// In en, this message translates to:
  /// **'Bots'**
  String get sharePackBots;

  /// No description provided for @sharePackBotsHelp.
  ///
  /// In en, this message translates to:
  /// **'Pick up to 5. Each brings its instructions, skills and routines.'**
  String get sharePackBotsHelp;

  /// No description provided for @sharePackSkills.
  ///
  /// In en, this message translates to:
  /// **'Workspace skills'**
  String get sharePackSkills;

  /// No description provided for @sharePackName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get sharePackName;

  /// No description provided for @sharePackSummary.
  ///
  /// In en, this message translates to:
  /// **'One line about it'**
  String get sharePackSummary;

  /// No description provided for @sharePackLook.
  ///
  /// In en, this message translates to:
  /// **'Include this device\'s look'**
  String get sharePackLook;

  /// No description provided for @sharePackCheck.
  ///
  /// In en, this message translates to:
  /// **'Check and share'**
  String get sharePackCheck;

  /// No description provided for @sharePackFindingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Some lines look like keys'**
  String get sharePackFindingsTitle;

  /// No description provided for @sharePackFindingsHelp.
  ///
  /// In en, this message translates to:
  /// **'Check these before you share. Go back to fix them, or share if they\'re safe.'**
  String get sharePackFindingsHelp;

  /// No description provided for @sharePackFinding.
  ///
  /// In en, this message translates to:
  /// **'{path}, line {line}: {what}'**
  String sharePackFinding(String path, int line, String what);

  /// No description provided for @sharePackGoBack.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get sharePackGoBack;

  /// No description provided for @sharePackAnyway.
  ///
  /// In en, this message translates to:
  /// **'Share anyway'**
  String get sharePackAnyway;

  /// No description provided for @sharePackLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Your pack link'**
  String get sharePackLinkTitle;

  /// No description provided for @sharePackLinkHelp.
  ///
  /// In en, this message translates to:
  /// **'Anyone signed in to Casama can open it until {date}.'**
  String sharePackLinkHelp(String date);

  /// No description provided for @sharePackShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get sharePackShare;

  /// No description provided for @sharePackSaveFile.
  ///
  /// In en, this message translates to:
  /// **'Save as file'**
  String get sharePackSaveFile;

  /// No description provided for @sharePackLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied.'**
  String get sharePackLinkCopied;

  /// No description provided for @sharePackStop.
  ///
  /// In en, this message translates to:
  /// **'Stop sharing'**
  String get sharePackStop;

  /// No description provided for @sharePackStopped.
  ///
  /// In en, this message translates to:
  /// **'The link no longer works.'**
  String get sharePackStopped;

  /// No description provided for @pluginFromPack.
  ///
  /// In en, this message translates to:
  /// **'From the {pack} pack'**
  String pluginFromPack(String pack);

  /// No description provided for @pluginFromPackHelp.
  ///
  /// In en, this message translates to:
  /// **'Update or remove it with its pack, in Gallery → Installed packs.'**
  String get pluginFromPackHelp;

  /// No description provided for @pluginSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get pluginSettings;

  /// No description provided for @pluginEditSettings.
  ///
  /// In en, this message translates to:
  /// **'Edit settings'**
  String get pluginEditSettings;

  /// No description provided for @pluginSettingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved.'**
  String get pluginSettingsSaved;

  /// No description provided for @galleryPolicyKeyHelp.
  ///
  /// In en, this message translates to:
  /// **'You can also type a repository (repo/owner:name) or a pack (pack/name).'**
  String get galleryPolicyKeyHelp;

  /// No description provided for @galleryPolicyUseKey.
  ///
  /// In en, this message translates to:
  /// **'Add {key}'**
  String galleryPolicyUseKey(String key);

  /// No description provided for @galleryApprovalPack.
  ///
  /// In en, this message translates to:
  /// **'Pack: {name}'**
  String galleryApprovalPack(String name);

  /// No description provided for @reportPackShare.
  ///
  /// In en, this message translates to:
  /// **'Report this pack'**
  String get reportPackShare;

  /// No description provided for @appLock.
  ///
  /// In en, this message translates to:
  /// **'App lock'**
  String get appLock;

  /// No description provided for @appLockRow.
  ///
  /// In en, this message translates to:
  /// **'Ask to unlock Casama when it opens'**
  String get appLockRow;

  /// No description provided for @appLockHelp.
  ///
  /// In en, this message translates to:
  /// **'Casama asks you to unlock it when it opens and after time away. While it\'s on, your sign-in is kept in this device\'s keychain.'**
  String get appLockHelp;

  /// No description provided for @appLockSwitch.
  ///
  /// In en, this message translates to:
  /// **'Lock Casama'**
  String get appLockSwitch;

  /// No description provided for @appLockLocked.
  ///
  /// In en, this message translates to:
  /// **'Casama Is Locked'**
  String get appLockLocked;

  /// No description provided for @appLockUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get appLockUnlock;

  /// No description provided for @appLockUnlockWithPasskey.
  ///
  /// In en, this message translates to:
  /// **'Unlock with a Passkey'**
  String get appLockUnlockWithPasskey;

  /// No description provided for @appLockUnlockReason.
  ///
  /// In en, this message translates to:
  /// **'Unlock Casama'**
  String get appLockUnlockReason;

  /// No description provided for @appLockTurnOnReason.
  ///
  /// In en, this message translates to:
  /// **'Turn on the app lock'**
  String get appLockTurnOnReason;

  /// No description provided for @appLockConfirmReason.
  ///
  /// In en, this message translates to:
  /// **'Confirm it\'s you'**
  String get appLockConfirmReason;

  /// No description provided for @appLockConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm It\'s You'**
  String get appLockConfirmTitle;

  /// No description provided for @appLockUnlockWith.
  ///
  /// In en, this message translates to:
  /// **'Use {method}.'**
  String appLockUnlockWith(String method);

  /// No description provided for @appLockDeviceIos.
  ///
  /// In en, this message translates to:
  /// **'Face ID, Touch ID or your passcode'**
  String get appLockDeviceIos;

  /// No description provided for @appLockDeviceAndroid.
  ///
  /// In en, this message translates to:
  /// **'your fingerprint, face or screen lock'**
  String get appLockDeviceAndroid;

  /// No description provided for @appLockDeviceMac.
  ///
  /// In en, this message translates to:
  /// **'Touch ID or your Mac\'s password'**
  String get appLockDeviceMac;

  /// No description provided for @appLockDeviceWindows.
  ///
  /// In en, this message translates to:
  /// **'Windows Hello'**
  String get appLockDeviceWindows;

  /// No description provided for @appLockDeviceOther.
  ///
  /// In en, this message translates to:
  /// **'your device\'s screen lock'**
  String get appLockDeviceOther;

  /// No description provided for @appLockMethodDevice.
  ///
  /// In en, this message translates to:
  /// **'Unlocks with {method}'**
  String appLockMethodDevice(String method);

  /// No description provided for @appLockMethodPin.
  ///
  /// In en, this message translates to:
  /// **'Unlocks with a 6-digit PIN'**
  String get appLockMethodPin;

  /// No description provided for @appLockMethodPasskey.
  ///
  /// In en, this message translates to:
  /// **'Unlocks with a passkey'**
  String get appLockMethodPasskey;

  /// No description provided for @appLockPinHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN'**
  String get appLockPinHint;

  /// No description provided for @appLockPinWrong.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Wrong PIN.} =1{Wrong PIN. 1 try left.} other{Wrong PIN. {count} tries left.}}'**
  String appLockPinWrong(int count);

  /// No description provided for @appLockPinStopped.
  ///
  /// In en, this message translates to:
  /// **'Too many wrong PINs. Sign out, then sign in again to open Casama.'**
  String get appLockPinStopped;

  /// No description provided for @appLockFailed.
  ///
  /// In en, this message translates to:
  /// **'That didn\'t work. Try again.'**
  String get appLockFailed;

  /// No description provided for @appLockUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This device can\'t unlock Casama right now. Sign out, then sign in again to get back in.'**
  String get appLockUnavailable;

  /// No description provided for @appLockSignOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Signing out turns the app lock off on this device. Sign in again to open Casama.'**
  String get appLockSignOutConfirm;

  /// No description provided for @appLockCallRinging.
  ///
  /// In en, this message translates to:
  /// **'A call is ringing. Unlock to answer it.'**
  String get appLockCallRinging;

  /// No description provided for @appLockRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Turn On the App Lock'**
  String get appLockRequiredTitle;

  /// No description provided for @appLockRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'{workspace} requires the app lock on every device that opens Casama.'**
  String appLockRequiredBody(String workspace);

  /// No description provided for @appLockRequiredNoWay.
  ///
  /// In en, this message translates to:
  /// **'This browser can\'t use passkeys with this server, so it can\'t lock Casama. Open Casama in the app on your phone or computer.'**
  String get appLockRequiredNoWay;

  /// No description provided for @appLockRequiredBy.
  ///
  /// In en, this message translates to:
  /// **'On. Required by {workspace}'**
  String appLockRequiredBy(String workspace);

  /// No description provided for @appLockTurnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn On'**
  String get appLockTurnOn;

  /// No description provided for @appLockTurnedOn.
  ///
  /// In en, this message translates to:
  /// **'App lock is on'**
  String get appLockTurnedOn;

  /// No description provided for @appLockNoWayHere.
  ///
  /// In en, this message translates to:
  /// **'This browser can\'t use passkeys with this server, so Casama can\'t be locked here.'**
  String get appLockNoWayHere;

  /// No description provided for @appLockNotChecked.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t confirm it\'s you.'**
  String get appLockNotChecked;

  /// No description provided for @appLockPinSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a PIN'**
  String get appLockPinSetupTitle;

  /// No description provided for @appLockPinAgainTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the PIN Again'**
  String get appLockPinAgainTitle;

  /// No description provided for @appLockPinSetupBody.
  ///
  /// In en, this message translates to:
  /// **'6 digits. You\'ll enter it to open Casama.'**
  String get appLockPinSetupBody;

  /// No description provided for @appLockPinNext.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get appLockPinNext;

  /// No description provided for @appLockPinMismatch.
  ///
  /// In en, this message translates to:
  /// **'The PINs didn\'t match. Choose one again.'**
  String get appLockPinMismatch;

  /// No description provided for @appLockPinNotSaved.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the PIN on this device.'**
  String get appLockPinNotSaved;

  /// No description provided for @appLockPinChanged.
  ///
  /// In en, this message translates to:
  /// **'PIN changed'**
  String get appLockPinChanged;

  /// No description provided for @appLockChangePin.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get appLockChangePin;

  /// No description provided for @appLockAfter.
  ///
  /// In en, this message translates to:
  /// **'Lock after'**
  String get appLockAfter;

  /// No description provided for @appLockAfterHelp.
  ///
  /// In en, this message translates to:
  /// **'Time in the background, minimised, or behind other apps on a computer.'**
  String get appLockAfterHelp;

  /// No description provided for @appLockAfterImmediately.
  ///
  /// In en, this message translates to:
  /// **'Right away'**
  String get appLockAfterImmediately;

  /// No description provided for @appLockAfterOneMinute.
  ///
  /// In en, this message translates to:
  /// **'1 minute'**
  String get appLockAfterOneMinute;

  /// No description provided for @appLockAfterFiveMinutes.
  ///
  /// In en, this message translates to:
  /// **'5 minutes'**
  String get appLockAfterFiveMinutes;

  /// No description provided for @appLockAfterFifteenMinutes.
  ///
  /// In en, this message translates to:
  /// **'15 minutes'**
  String get appLockAfterFifteenMinutes;

  /// No description provided for @appLockAfterOneHour.
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get appLockAfterOneHour;

  /// No description provided for @appLockBlockScreenshots.
  ///
  /// In en, this message translates to:
  /// **'Block screenshots'**
  String get appLockBlockScreenshots;

  /// No description provided for @appLockBlockScreenshotsHelp.
  ///
  /// In en, this message translates to:
  /// **'Screenshots, screen recordings and screen sharing show nothing of Casama.'**
  String get appLockBlockScreenshotsHelp;

  /// No description provided for @appLockLockNow.
  ///
  /// In en, this message translates to:
  /// **'Lock now'**
  String get appLockLockNow;

  /// No description provided for @appLockPrivacySection.
  ///
  /// In en, this message translates to:
  /// **'More privacy'**
  String get appLockPrivacySection;

  /// No description provided for @appLockAskBeforeRisky.
  ///
  /// In en, this message translates to:
  /// **'Confirm risky actions'**
  String get appLockAskBeforeRisky;

  /// No description provided for @appLockAskBeforeRiskyHelp.
  ///
  /// In en, this message translates to:
  /// **'Unlock again before deleting your account, making keys, changing billing, exporting data, approving high-risk requests and taking over a computer.'**
  String get appLockAskBeforeRiskyHelp;

  /// No description provided for @requireAppLock.
  ///
  /// In en, this message translates to:
  /// **'Require the app lock'**
  String get requireAppLock;

  /// No description provided for @requireAppLockHelp.
  ///
  /// In en, this message translates to:
  /// **'Members must lock Casama on every device before it opens. On the web that takes a passkey.'**
  String get requireAppLockHelp;

  /// No description provided for @requireAppLockOwnFirst.
  ///
  /// In en, this message translates to:
  /// **'Turn on the app lock on this device first.'**
  String get requireAppLockOwnFirst;

  /// No description provided for @permLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get permLocation;

  /// No description provided for @permLocationAlways.
  ///
  /// In en, this message translates to:
  /// **'Location in the background'**
  String get permLocationAlways;

  /// No description provided for @permCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get permCamera;

  /// No description provided for @permMicrophone.
  ///
  /// In en, this message translates to:
  /// **'Microphone'**
  String get permMicrophone;

  /// No description provided for @permSpeech.
  ///
  /// In en, this message translates to:
  /// **'Speech recognition'**
  String get permSpeech;

  /// No description provided for @permPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get permPhotos;

  /// No description provided for @permContacts.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get permContacts;

  /// No description provided for @permCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendars'**
  String get permCalendar;

  /// No description provided for @permHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get permHealth;

  /// No description provided for @permNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get permNotifications;

  /// No description provided for @permNotificationAccess.
  ///
  /// In en, this message translates to:
  /// **'Notification access'**
  String get permNotificationAccess;

  /// No description provided for @permAccessibility.
  ///
  /// In en, this message translates to:
  /// **'Accessibility'**
  String get permAccessibility;

  /// No description provided for @permScreenRecording.
  ///
  /// In en, this message translates to:
  /// **'Screen Recording'**
  String get permScreenRecording;

  /// No description provided for @permAutomation.
  ///
  /// In en, this message translates to:
  /// **'Automation'**
  String get permAutomation;

  /// No description provided for @permFullDisk.
  ///
  /// In en, this message translates to:
  /// **'Full Disk Access'**
  String get permFullDisk;

  /// No description provided for @permSharedFolders.
  ///
  /// In en, this message translates to:
  /// **'Shared folders'**
  String get permSharedFolders;

  /// No description provided for @permLocalTools.
  ///
  /// In en, this message translates to:
  /// **'Local tools'**
  String get permLocalTools;

  /// No description provided for @cardPermissions.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get cardPermissions;

  /// No description provided for @permissionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Turn these on for {device}'**
  String permissionsTitle(String device);

  /// No description provided for @permStateOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get permStateOn;

  /// No description provided for @permStateOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get permStateOff;

  /// No description provided for @permStateNotAsked.
  ///
  /// In en, this message translates to:
  /// **'Not asked yet'**
  String get permStateNotAsked;

  /// No description provided for @permStateLimited.
  ///
  /// In en, this message translates to:
  /// **'Limited'**
  String get permStateLimited;

  /// No description provided for @permStateUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get permStateUnknown;

  /// No description provided for @permStateUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Not available on this device'**
  String get permStateUnavailable;

  /// No description provided for @permStateUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update Casama to turn this on here'**
  String get permStateUpdate;

  /// No description provided for @permTurnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get permTurnOn;

  /// No description provided for @permOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get permOpenSettings;

  /// Button on the Health permission row on iPhone: opens the Health app, where its switches are.
  ///
  /// In en, this message translates to:
  /// **'Open Health'**
  String get permOpenHealth;

  /// Note under the Health permission row on iPhone after opening the Health app.
  ///
  /// In en, this message translates to:
  /// **'In Health, tap your picture, then Apps, then Casama, and turn on what your bots may read.'**
  String get permHealthIosHow;

  /// No description provided for @permChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get permChoose;

  /// No description provided for @permRestart.
  ///
  /// In en, this message translates to:
  /// **'Restart Casama'**
  String get permRestart;

  /// No description provided for @permRestartToFinish.
  ///
  /// In en, this message translates to:
  /// **'Restart Casama to finish'**
  String get permRestartToFinish;

  /// No description provided for @permOpenedOn.
  ///
  /// In en, this message translates to:
  /// **'Opened on {device}'**
  String permOpenedOn(String device);

  /// No description provided for @permSentTo.
  ///
  /// In en, this message translates to:
  /// **'Sent to {device}: tap the notification there'**
  String permSentTo(String device);

  /// No description provided for @permOffline.
  ///
  /// In en, this message translates to:
  /// **'{device} is offline'**
  String permOffline(String device);

  /// No description provided for @permRestarting.
  ///
  /// In en, this message translates to:
  /// **'Restarting Casama on {device}'**
  String permRestarting(String device);

  /// No description provided for @permOnlyOwner.
  ///
  /// In en, this message translates to:
  /// **'Only {device}\'s owner can turn these on'**
  String permOnlyOwner(String device);

  /// No description provided for @permNotNowLine.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get permNotNowLine;

  /// No description provided for @permContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get permContinue;

  /// No description provided for @permContinueMessage.
  ///
  /// In en, this message translates to:
  /// **'They\'re on, go ahead.'**
  String get permContinueMessage;

  /// No description provided for @permContinuedLine.
  ///
  /// In en, this message translates to:
  /// **'Turned on'**
  String get permContinuedLine;

  /// No description provided for @permissionsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get permissionsScreenTitle;

  /// No description provided for @permissionsScreenHelp.
  ///
  /// In en, this message translates to:
  /// **'What bots can use on this device. Nothing is asked until you tap.'**
  String get permissionsScreenHelp;

  /// No description provided for @permissionsRowHelp.
  ///
  /// In en, this message translates to:
  /// **'Location, screen, microphone and more on this device'**
  String get permissionsRowHelp;

  /// No description provided for @permOtherDevice.
  ///
  /// In en, this message translates to:
  /// **'This was for {device}. Open Casama there to turn it on.'**
  String permOtherDevice(String device);

  /// No description provided for @permAnotherDevice.
  ///
  /// In en, this message translates to:
  /// **'another device'**
  String get permAnotherDevice;

  /// No description provided for @permissionsNone.
  ///
  /// In en, this message translates to:
  /// **'Nothing to turn on on this device.'**
  String get permissionsNone;

  /// Shown in a home screen or Lock Screen widget (D-405). Title of the list of requests waiting on the person.
  ///
  /// In en, this message translates to:
  /// **'Needs you'**
  String get widgetNeedsYou;

  /// Shown in a home screen or Lock Screen widget (D-405). Nothing waits on the person.
  ///
  /// In en, this message translates to:
  /// **'All clear'**
  String get widgetAllClear;

  /// Shown in a home screen or Lock Screen widget (D-405). Button: allow a low-risk request.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get widgetAllow;

  /// Shown in a home screen or Lock Screen widget (D-405). Button: deny a request.
  ///
  /// In en, this message translates to:
  /// **'Deny'**
  String get widgetDeny;

  /// Shown in a home screen or Lock Screen widget (D-405). Button: open a request to look at it in the app.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get widgetReview;

  /// Shown in a home screen or Lock Screen widget (D-405). Button: open a takeover request.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get widgetOpen;

  /// Shown in a home screen or Lock Screen widget (D-405). Button: accept a bot's suggestion.
  ///
  /// In en, this message translates to:
  /// **'Do it'**
  String get widgetDoIt;

  /// Shown in a home screen or Lock Screen widget (D-405). Button: start a routine by hand.
  ///
  /// In en, this message translates to:
  /// **'Run now'**
  String get widgetRunNow;

  /// Shown in a home screen or Lock Screen widget (D-405). Shown after Run now was pressed.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get widgetStarted;

  /// Shown in a home screen or Lock Screen widget (D-405). Button: stop a running bot.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get widgetStop;

  /// Shown in a home screen or Lock Screen widget (D-405). Button: open quick ask.
  ///
  /// In en, this message translates to:
  /// **'Ask'**
  String get widgetAsk;

  /// Shown in a home screen or Lock Screen widget (D-405). The ask field, with the bot it goes to.
  ///
  /// In en, this message translates to:
  /// **'Ask {bot}'**
  String widgetAskBot(String bot);

  /// Shown in a home screen or Lock Screen widget (D-405). Button: start a voice call with the bot.
  ///
  /// In en, this message translates to:
  /// **'Talk'**
  String get widgetTalk;

  /// Shown in a home screen or Lock Screen widget (D-405). Label above starter requests the person can tap.
  ///
  /// In en, this message translates to:
  /// **'Try'**
  String get widgetTry;

  /// Shown in a home screen or Lock Screen widget (D-405). Routines in the order they will run.
  ///
  /// In en, this message translates to:
  /// **'Up next'**
  String get widgetUpNext;

  /// Shown in a home screen or Lock Screen widget (D-405). The Routines widget when there are none.
  ///
  /// In en, this message translates to:
  /// **'No routines yet'**
  String get widgetNoRoutines;

  /// Shown in a home screen or Lock Screen widget (D-405). A bot is working on something.
  ///
  /// In en, this message translates to:
  /// **'Working'**
  String get widgetWorking;

  /// Shown in a home screen or Lock Screen widget (D-405). A bot is blocked on the person.
  ///
  /// In en, this message translates to:
  /// **'Waiting for you'**
  String get widgetWaiting;

  /// Shown in a home screen or Lock Screen widget (D-405). A bot is not doing anything.
  ///
  /// In en, this message translates to:
  /// **'Idle'**
  String get widgetIdle;

  /// Shown in a home screen or Lock Screen widget (D-405). When the bot last replied, e.g. "Replied 9:20".
  ///
  /// In en, this message translates to:
  /// **'Replied {time}'**
  String widgetRepliedAt(String time);

  /// Shown in a home screen or Lock Screen widget (D-405). The morning brief.
  ///
  /// In en, this message translates to:
  /// **'Brief'**
  String get widgetBrief;

  /// Shown in a home screen or Lock Screen widget (D-405). When today's brief arrives.
  ///
  /// In en, this message translates to:
  /// **'Brief at {time}'**
  String widgetBriefAt(String time);

  /// Shown in a home screen or Lock Screen widget (D-405). No morning brief has arrived.
  ///
  /// In en, this message translates to:
  /// **'No brief yet'**
  String get widgetNoBrief;

  /// Shown in a home screen or Lock Screen widget (D-405). Title of the large Today widget.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get widgetToday;

  /// Shown in a home screen or Lock Screen widget (D-405). Title of the credits widget.
  ///
  /// In en, this message translates to:
  /// **'Credits'**
  String get widgetCredits;

  /// Shown in a home screen or Lock Screen widget (D-405). Credits left this period.
  ///
  /// In en, this message translates to:
  /// **'{amount} left'**
  String widgetCreditsLeft(String amount);

  /// Shown in a home screen or Lock Screen widget (D-405). Spent today.
  ///
  /// In en, this message translates to:
  /// **'{amount} today'**
  String widgetSpentToday(String amount);

  /// Shown in a home screen or Lock Screen widget (D-405). Share of this period's credits used.
  ///
  /// In en, this message translates to:
  /// **'{n}% used'**
  String widgetUsedPct(String n);

  /// Shown in a home screen or Lock Screen widget (D-405). When the daily cap resets.
  ///
  /// In en, this message translates to:
  /// **'Resets {time}'**
  String widgetResetsAt(String time);

  /// Shown in a home screen or Lock Screen widget (D-405). What a bot finished last.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get widgetFinished;

  /// Shown in a home screen or Lock Screen widget (D-405). Title of the Library widget.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get widgetLibrary;

  /// Shown in a home screen or Lock Screen widget (D-405). The Library widget when empty.
  ///
  /// In en, this message translates to:
  /// **'Nothing made yet'**
  String get widgetNoCreations;

  /// Shown in a home screen or Lock Screen widget (D-405). Title of the Tasks widget.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get widgetTasks;

  /// Shown in a home screen or Lock Screen widget (D-405). Task board column.
  ///
  /// In en, this message translates to:
  /// **'To do'**
  String get widgetTodo;

  /// Shown in a home screen or Lock Screen widget (D-405). Task board column.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get widgetInProgress;

  /// Shown in a home screen or Lock Screen widget (D-405). Task board column.
  ///
  /// In en, this message translates to:
  /// **'In review'**
  String get widgetInReview;

  /// Shown in a home screen or Lock Screen widget (D-405). Task board column.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get widgetBlocked;

  /// Shown in a home screen or Lock Screen widget (D-405). Signed out.
  ///
  /// In en, this message translates to:
  /// **'Open Casama to sign in'**
  String get widgetSignIn;

  /// Shown in a home screen or Lock Screen widget (D-405). No bots yet.
  ///
  /// In en, this message translates to:
  /// **'Meet your first bot'**
  String get widgetNoBots;

  /// Shown in a home screen or Lock Screen widget (D-405). How old the data is, e.g. "as of 9:41".
  ///
  /// In en, this message translates to:
  /// **'as of {time}'**
  String widgetAsOf(String time);

  /// Shown in a home screen or Lock Screen widget (D-405). The server is too old for this widget.
  ///
  /// In en, this message translates to:
  /// **'Update your Casama server to use this widget'**
  String get widgetUpdateServer;

  /// Shown in a home screen or Lock Screen widget (D-405). An approval request from a bot.
  ///
  /// In en, this message translates to:
  /// **'{bot} needs your OK'**
  String widgetNeedsOkFrom(String bot);

  /// Shown in a home screen or Lock Screen widget (D-405). A suggestion from a bot.
  ///
  /// In en, this message translates to:
  /// **'{bot} suggests'**
  String widgetSuggests(String bot);

  /// Shown in a home screen or Lock Screen widget (D-405). A takeover request from a bot.
  ///
  /// In en, this message translates to:
  /// **'{bot} needs you to take over'**
  String widgetTakeOver(String bot);

  /// Shown in a home screen or Lock Screen widget (D-405). When the next brief is due.
  ///
  /// In en, this message translates to:
  /// **'Next brief {time}'**
  String widgetNextBrief(String time);

  /// Shown in a home screen or Lock Screen widget (D-405). No routine or brief is coming up.
  ///
  /// In en, this message translates to:
  /// **'Nothing scheduled'**
  String get widgetNothingNext;

  /// Settings -> Widgets: page title and settings row (D-405).
  ///
  /// In en, this message translates to:
  /// **'Widgets'**
  String get widgetsTitle;

  /// Settings row subtitle for Widgets.
  ///
  /// In en, this message translates to:
  /// **'Your bots on the Home screen and Lock Screen'**
  String get widgetsRow;

  /// Settings -> Widgets: the line at the top.
  ///
  /// In en, this message translates to:
  /// **'Widgets show what your bots are doing and what waits on you, without opening Casama.'**
  String get widgetsIntro;

  /// Name of the widget that follows one bot.
  ///
  /// In en, this message translates to:
  /// **'Bot'**
  String get widgetNameBot;

  /// Name of the routines widget.
  ///
  /// In en, this message translates to:
  /// **'Routines'**
  String get widgetNameRoutines;

  /// Widget description; starts with a verb.
  ///
  /// In en, this message translates to:
  /// **'See which bots are waiting on you'**
  String get widgetDescNeedsYou;

  /// Widget description; starts with a verb.
  ///
  /// In en, this message translates to:
  /// **'See what one bot is doing'**
  String get widgetDescBot;

  /// Widget description; starts with a verb.
  ///
  /// In en, this message translates to:
  /// **'Ask or talk to a bot in one tap'**
  String get widgetDescAsk;

  /// Widget description; starts with a verb.
  ///
  /// In en, this message translates to:
  /// **'See what runs next and run it now'**
  String get widgetDescRoutines;

  /// Widget description; starts with a verb.
  ///
  /// In en, this message translates to:
  /// **'See your whole day on one large widget'**
  String get widgetDescToday;

  /// Widget description; starts with a verb.
  ///
  /// In en, this message translates to:
  /// **'Read your morning brief'**
  String get widgetDescBrief;

  /// Widget description; starts with a verb.
  ///
  /// In en, this message translates to:
  /// **'See what your bots made lately'**
  String get widgetDescLibrary;

  /// Widget description; starts with a verb.
  ///
  /// In en, this message translates to:
  /// **'See where the task board stands'**
  String get widgetDescTasks;

  /// Widget description; starts with a verb.
  ///
  /// In en, this message translates to:
  /// **'Keep an eye on your credits'**
  String get widgetDescCredits;

  /// Android button that asks the launcher to place the widget.
  ///
  /// In en, this message translates to:
  /// **'Add to Home screen'**
  String get widgetsAddToHome;

  /// Android: the launcher refused to place the widget.
  ///
  /// In en, this message translates to:
  /// **'Your launcher can\'t add widgets from here. Touch and hold an empty spot on your Home screen, tap Widgets, and pick Casama.'**
  String get widgetsPinUnsupported;

  /// Heading over the steps for adding a widget.
  ///
  /// In en, this message translates to:
  /// **'How to add'**
  String get widgetsHowToAdd;

  /// iPhone steps to add a widget.
  ///
  /// In en, this message translates to:
  /// **'Touch and hold an empty spot on your Home Screen, tap Edit, then Add Widget, and pick Casama.'**
  String get widgetsHowToIos;

  /// Mac steps to add a widget.
  ///
  /// In en, this message translates to:
  /// **'Click the date and time in the menu bar, then Edit Widgets, and pick Casama. Or right-click the desktop and choose Edit Widgets.'**
  String get widgetsHowToMac;

  /// Settings -> Widgets section about Lock Screen widgets and controls (iPhone).
  ///
  /// In en, this message translates to:
  /// **'Lock Screen and controls'**
  String get widgetsLockScreen;

  /// iPhone steps to add Lock Screen widgets.
  ///
  /// In en, this message translates to:
  /// **'Touch and hold the Lock Screen, tap Customize, then Lock Screen, and tap the space under the clock to add Needs you, Up next, Bot or Credits. A request stays hidden until you unlock.'**
  String get widgetsLockScreenHelp;

  /// iPhone steps to add controls.
  ///
  /// In en, this message translates to:
  /// **'Open Control Center, touch and hold, tap Add a Control, and pick Ask Casama, Talk to a bot or Run a routine. They also fit the Lock Screen corners and the Action button.'**
  String get widgetsControlsHelp;

  /// Switch that lets widgets show requests, messages and routine names while the app lock is on.
  ///
  /// In en, this message translates to:
  /// **'Show details in widgets'**
  String get widgetsShowDetails;

  /// Help under Show details in widgets.
  ///
  /// In en, this message translates to:
  /// **'With the app lock on, widgets show only numbers and bot names, and their buttons open Casama. Turn this on to show requests, messages and routine names too.'**
  String get widgetsShowDetailsHelp;

  /// Help under Show details in widgets while the app lock is off.
  ///
  /// In en, this message translates to:
  /// **'Only matters while the app lock is on. Without it, widgets show details.'**
  String get widgetsShowDetailsNoLock;

  /// Help under Show details in widgets when a workspace requires the app lock.
  ///
  /// In en, this message translates to:
  /// **'{workspace} requires the app lock, so widgets keep details hidden.'**
  String widgetsShowDetailsRequired(String workspace);

  /// Android section: put a bot on the Home screen as its own icon.
  ///
  /// In en, this message translates to:
  /// **'Pin a bot to your Home screen'**
  String get widgetsPinBot;

  /// Help for pinning a bot.
  ///
  /// In en, this message translates to:
  /// **'Puts the bot on your Home screen as its own icon. Tap it to chat.'**
  String get widgetsPinBotHelp;

  /// Button: pin this bot to the Home screen.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get widgetsPin;

  /// One-time hint after the first request is answered (D-405).
  ///
  /// In en, this message translates to:
  /// **'Answer requests from your Home screen with the Needs you widget.'**
  String get widgetNudgeNeedsYou;

  /// One-time hint after the first routine is made (D-405).
  ///
  /// In en, this message translates to:
  /// **'Run routines from your Home screen with the Routines widget.'**
  String get widgetNudgeRoutines;

  /// Button on the one-time widget hint: opens Settings -> Widgets.
  ///
  /// In en, this message translates to:
  /// **'Show me'**
  String get widgetNudgeAction;

  /// Shown in a home screen or Lock Screen widget (D-405). Marks a low-risk request that can be allowed from the widget.
  ///
  /// In en, this message translates to:
  /// **'Low risk'**
  String get widgetLowRisk;

  /// Shown in a home screen or Lock Screen widget (D-405). This month's spend in the Credits widget.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get widgetThisMonth;

  /// Shown on the watch app (D-410). Title of the watch app's first screen.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get watchNow;

  /// Shown on the watch app (D-410). The main button: ask a bot by voice.
  ///
  /// In en, this message translates to:
  /// **'Ask'**
  String get watchAsk;

  /// Shown on the watch app (D-410). Title of the Ask screen.
  ///
  /// In en, this message translates to:
  /// **'Ask {bot}'**
  String watchAskBot(String bot);

  /// Shown on the watch app (D-410). The list of bots.
  ///
  /// In en, this message translates to:
  /// **'Bots'**
  String get watchBots;

  /// Shown on the watch app (D-410). Routines in the order they will run.
  ///
  /// In en, this message translates to:
  /// **'Up next'**
  String get watchUpNext;

  /// Shown on the watch app (D-410). This morning's brief.
  ///
  /// In en, this message translates to:
  /// **'Brief'**
  String get watchBrief;

  /// Shown on the watch app (D-410). The watch app's settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get watchSettings;

  /// Shown on the watch app (D-410). A bot's latest chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get watchChat;

  /// Shown on the watch app (D-410). Start a voice call with a bot.
  ///
  /// In en, this message translates to:
  /// **'Talk'**
  String get watchTalk;

  /// Shown on the watch app (D-410). The credits complication.
  ///
  /// In en, this message translates to:
  /// **'Credits'**
  String get watchCredits;

  /// Shown on the watch app (D-410). Section title: requests waiting on the person.
  ///
  /// In en, this message translates to:
  /// **'Needs you'**
  String get watchNeedsYou;

  /// Shown on the watch app (D-410). One request waits.
  ///
  /// In en, this message translates to:
  /// **'1 needs you'**
  String get watchNeedsYouOne;

  /// Shown on the watch app (D-410). Several requests wait.
  ///
  /// In en, this message translates to:
  /// **'{count} need you'**
  String watchNeedsYouMany(String count);

  /// Shown on the watch app (D-410). A bot is waiting for an answer.
  ///
  /// In en, this message translates to:
  /// **'Needs your OK'**
  String get watchNeedsOk;

  /// Shown on the watch app (D-410). A request from a bot.
  ///
  /// In en, this message translates to:
  /// **'{bot} needs your OK'**
  String watchNeedsOkFrom(String bot);

  /// Shown on the watch app (D-410). A suggestion from a bot.
  ///
  /// In en, this message translates to:
  /// **'{bot} suggests'**
  String watchSuggests(String bot);

  /// Shown on the watch app (D-410). A bot asks the person to take over its computer.
  ///
  /// In en, this message translates to:
  /// **'Wants you to take over'**
  String get watchTakeOver;

  /// Shown on the watch app (D-410). Nothing needs the person and nothing is working.
  ///
  /// In en, this message translates to:
  /// **'All clear'**
  String get watchAllClear;

  /// Shown on the watch app (D-410). Empty Needs you list.
  ///
  /// In en, this message translates to:
  /// **'Nothing needs you'**
  String get watchNothingWaiting;

  /// Shown on the watch app (D-410). Allow a request.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get watchAllow;

  /// Shown on the watch app (D-410). Deny a request.
  ///
  /// In en, this message translates to:
  /// **'Deny'**
  String get watchDeny;

  /// Shown on the watch app (D-410). A medium-risk request: hold the button to allow.
  ///
  /// In en, this message translates to:
  /// **'Hold to allow'**
  String get watchHoldToAllow;

  /// Shown on the watch app (D-410). VoiceOver/TalkBack hint replacing the hold.
  ///
  /// In en, this message translates to:
  /// **'Allow this? Double tap to allow.'**
  String get watchHoldHint;

  /// Shown on the watch app (D-410). Open a request to look at it.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get watchReview;

  /// Shown on the watch app (D-410). A request the watch will not allow (Apple Watch).
  ///
  /// In en, this message translates to:
  /// **'Review on iPhone'**
  String get watchReviewOnIphone;

  /// Shown on the watch app (D-410). A request the watch will not allow (Wear OS).
  ///
  /// In en, this message translates to:
  /// **'Review on phone'**
  String get watchReviewOnPhone;

  /// Shown on the watch app (D-410). Why a request is phone-only.
  ///
  /// In en, this message translates to:
  /// **'High risk: answer on your phone'**
  String get watchWhyHighRisk;

  /// Shown on the watch app (D-410). Why a request is phone-only.
  ///
  /// In en, this message translates to:
  /// **'Payments are answered on your phone'**
  String get watchWhyPayment;

  /// Shown on the watch app (D-410). Why a request is phone-only.
  ///
  /// In en, this message translates to:
  /// **'Your settings keep this on your phone'**
  String get watchWhySetting;

  /// Shown on the watch app (D-410). Why a request is phone-only.
  ///
  /// In en, this message translates to:
  /// **'Your workspace keeps this on your phone'**
  String get watchWhyWorkspace;

  /// Shown on the watch app (D-410). Why a request is phone-only.
  ///
  /// In en, this message translates to:
  /// **'Only the person who started this chat can allow it'**
  String get watchWhyNotYours;

  /// Shown on the watch app (D-410). Marks a high-risk request.
  ///
  /// In en, this message translates to:
  /// **'High risk'**
  String get watchHighRisk;

  /// Shown on the watch app (D-410). Marks a medium-risk request.
  ///
  /// In en, this message translates to:
  /// **'Medium risk'**
  String get watchMediumRisk;

  /// Shown on the watch app (D-410). Marks a low-risk request.
  ///
  /// In en, this message translates to:
  /// **'Low risk'**
  String get watchLowRisk;

  /// Shown on the watch app (D-410). Shown with a tick after allowing.
  ///
  /// In en, this message translates to:
  /// **'Allowed'**
  String get watchAllowed;

  /// Shown on the watch app (D-410). Shown after denying.
  ///
  /// In en, this message translates to:
  /// **'Denied'**
  String get watchDenied;

  /// Shown on the watch app (D-410). Shown with a tick after Do It.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get watchDone;

  /// Shown on the watch app (D-410). Someone answered the request already.
  ///
  /// In en, this message translates to:
  /// **'Already answered'**
  String get watchAlreadyAnswered;

  /// Shown on the watch app (D-410). A watch without a passcode cannot allow.
  ///
  /// In en, this message translates to:
  /// **'Set a passcode on this watch to allow from it'**
  String get watchLockToAllow;

  /// Shown on the watch app (D-410). Accept a suggestion.
  ///
  /// In en, this message translates to:
  /// **'Do It'**
  String get watchDoIt;

  /// Shown on the watch app (D-410). Dismiss a suggestion.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get watchNotNow;

  /// Shown on the watch app (D-410). Carry on on the iPhone.
  ///
  /// In en, this message translates to:
  /// **'Open on iPhone'**
  String get watchOpenOnIphone;

  /// Shown on the watch app (D-410). Carry on on the phone (Wear OS).
  ///
  /// In en, this message translates to:
  /// **'Open on phone'**
  String get watchOpenOnPhone;

  /// Shown on the watch app (D-410). After Open on iPhone/phone.
  ///
  /// In en, this message translates to:
  /// **'Sent to your phone'**
  String get watchSentToPhone;

  /// Shown on the watch app (D-410). A bot is working.
  ///
  /// In en, this message translates to:
  /// **'Working'**
  String get watchWorking;

  /// Shown on the watch app (D-410). A bot is working.
  ///
  /// In en, this message translates to:
  /// **'{bot} is working'**
  String watchIsWorking(String bot);

  /// Shown on the watch app (D-410). A bot waits on the person.
  ///
  /// In en, this message translates to:
  /// **'Waiting for you'**
  String get watchWaitingForYou;

  /// Shown on the watch app (D-410). When a bot last replied.
  ///
  /// In en, this message translates to:
  /// **'Replied {time}'**
  String watchRepliedAt(String time);

  /// Shown on the watch app (D-410). A bot is not working.
  ///
  /// In en, this message translates to:
  /// **'Idle'**
  String get watchIdle;

  /// Shown on the watch app (D-410). A bot is turned off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get watchOff;

  /// Shown on the watch app (D-410). How many steps a run has taken.
  ///
  /// In en, this message translates to:
  /// **'Step {count}'**
  String watchStepCount(String count);

  /// Shown on the watch app (D-410). Stop a run.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get watchStop;

  /// Shown on the watch app (D-410). A run the person stopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get watchStopped;

  /// Shown on the watch app (D-410). A run finished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get watchFinished;

  /// Shown on the watch app (D-410). A run failed.
  ///
  /// In en, this message translates to:
  /// **'Stopped with a problem'**
  String get watchProblem;

  /// Shown on the watch app (D-410). A run failed (notification title).
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t finish'**
  String get watchCouldntFinish;

  /// Shown on the watch app (D-410). The microphone is on.
  ///
  /// In en, this message translates to:
  /// **'Listening…'**
  String get watchListening;

  /// Shown on the watch app (D-410). Under the microphone while listening.
  ///
  /// In en, this message translates to:
  /// **'Tap to stop'**
  String get watchTapToStop;

  /// Shown on the watch app (D-410). Open the system keyboard, Scribble and dictation.
  ///
  /// In en, this message translates to:
  /// **'Type instead'**
  String get watchTypeInstead;

  /// Shown on the watch app (D-410). An ask is being sent.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get watchSending;

  /// Shown on the watch app (D-410). What the server heard, shown for a moment.
  ///
  /// In en, this message translates to:
  /// **'Heard'**
  String get watchHeard;

  /// Shown on the watch app (D-410). Take back an ask just sent.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get watchUndo;

  /// Shown on the watch app (D-410). An ask kept while offline.
  ///
  /// In en, this message translates to:
  /// **'Saved. It sends when you\'re back online'**
  String get watchKeptOffline;

  /// Shown on the watch app (D-410). A kept ask older than ten minutes.
  ///
  /// In en, this message translates to:
  /// **'Send what you asked at {time}?'**
  String watchKeptOld(String time);

  /// Shown on the watch app (D-410). Send a kept ask.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get watchSend;

  /// Shown on the watch app (D-410). Throw a kept ask away.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get watchDiscard;

  /// Shown on the watch app (D-410). Microphone permission is off.
  ///
  /// In en, this message translates to:
  /// **'Allow the microphone in Settings to ask by voice'**
  String get watchMicDenied;

  /// Shown on the watch app (D-410). The server cannot transcribe.
  ///
  /// In en, this message translates to:
  /// **'This server has no voice service. Use Type instead'**
  String get watchNoDictation;

  /// Shown on the watch app (D-410). Nothing was heard.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t catch that. Try again'**
  String get watchDidntCatch;

  /// Shown on the watch app (D-410). Answer in the chat by voice.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get watchReply;

  /// Shown on the watch app (D-410). Hear the reply.
  ///
  /// In en, this message translates to:
  /// **'Read aloud'**
  String get watchReadAloud;

  /// Shown on the watch app (D-410). Stop reading aloud.
  ///
  /// In en, this message translates to:
  /// **'Stop reading'**
  String get watchStopReading;

  /// Shown on the watch app (D-410). A reply too long for the watch (Apple Watch).
  ///
  /// In en, this message translates to:
  /// **'Continues on iPhone'**
  String get watchContinuesOnIphone;

  /// Shown on the watch app (D-410). A reply too long for the watch (Wear OS).
  ///
  /// In en, this message translates to:
  /// **'Continues on phone'**
  String get watchContinuesOnPhone;

  /// Shown on the watch app (D-410). A reply arrived (notification).
  ///
  /// In en, this message translates to:
  /// **'Reply ready'**
  String get watchReplyReady;

  /// Shown on the watch app (D-410). Marks the person's own message.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get watchYou;

  /// Shown on the watch app (D-410). Default quick reply.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get watchQuickYes;

  /// Shown on the watch app (D-410). Default quick reply.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get watchQuickNo;

  /// Shown on the watch app (D-410). Default quick reply.
  ///
  /// In en, this message translates to:
  /// **'Tell me more'**
  String get watchQuickTellMore;

  /// Shown on the watch app (D-410). Default quick reply.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get watchQuickNotNow;

  /// Shown on the watch app (D-410). Start a routine now.
  ///
  /// In en, this message translates to:
  /// **'Run Now'**
  String get watchRunNow;

  /// Shown on the watch app (D-410). A routine was started.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get watchStarted;

  /// Shown on the watch app (D-410). A routine runs soon.
  ///
  /// In en, this message translates to:
  /// **'in {minutes} min'**
  String watchInMinutes(String minutes);

  /// Shown on the watch app (D-410). Empty Up next.
  ///
  /// In en, this message translates to:
  /// **'No routines yet'**
  String get watchNoRoutines;

  /// Shown on the watch app (D-410). When today's brief comes.
  ///
  /// In en, this message translates to:
  /// **'Brief at {time}'**
  String watchBriefAt(String time);

  /// Shown on the watch app (D-410). When tomorrow's brief comes.
  ///
  /// In en, this message translates to:
  /// **'Brief at {time} tomorrow'**
  String watchBriefTomorrow(String time);

  /// Shown on the watch app (D-410). No morning brief.
  ///
  /// In en, this message translates to:
  /// **'No brief set up'**
  String get watchNoBrief;

  /// Shown on the watch app (D-410). No bots.
  ///
  /// In en, this message translates to:
  /// **'No bots yet. Make one on your phone'**
  String get watchNoBots;

  /// Shown on the watch app (D-410). The phone is signing the watch in.
  ///
  /// In en, this message translates to:
  /// **'Signing you in'**
  String get watchSigningIn;

  /// Shown on the watch app (D-410). After signing in.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {name}'**
  String watchSignedInAs(String name);

  /// Shown on the watch app (D-410). Waiting for the phone app.
  ///
  /// In en, this message translates to:
  /// **'Open Casama on your iPhone to finish'**
  String get watchOpenPhoneToFinishIphone;

  /// Shown on the watch app (D-410). Waiting for the phone app (Wear OS).
  ///
  /// In en, this message translates to:
  /// **'Open Casama on your phone to finish'**
  String get watchOpenPhoneToFinish;

  /// Shown on the watch app (D-410). Show a code instead.
  ///
  /// In en, this message translates to:
  /// **'Sign in with a code'**
  String get watchUseCode;

  /// Shown on the watch app (D-410). Under the sign-in code.
  ///
  /// In en, this message translates to:
  /// **'Type it in Casama on your phone or computer: Settings → Watch'**
  String get watchCodeHelp;

  /// Shown on the watch app (D-410). Get another code.
  ///
  /// In en, this message translates to:
  /// **'New code'**
  String get watchNewCode;

  /// Shown on the watch app (D-410), above its Sign in button: the person signed out here, or the watch was removed or signed out from the phone. It stays signed out until they tap Sign in.
  ///
  /// In en, this message translates to:
  /// **'This watch is signed out'**
  String get watchSignedOut;

  /// Shown on the watch app (D-410). Complications and tiles when signed out.
  ///
  /// In en, this message translates to:
  /// **'Open Casama to sign in'**
  String get watchOpenToSignIn;

  /// Shown on the watch app (D-410). How old what is shown is.
  ///
  /// In en, this message translates to:
  /// **'as of {time}'**
  String watchAsOf(String time);

  /// Shown on the watch app (D-410). No connection.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get watchOffline;

  /// Shown on the watch app (D-410). A request failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach Casama'**
  String get watchCouldntReach;

  /// Shown on the watch app (D-410). Retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get watchTryAgain;

  /// Shown on the watch app (D-410). The server is too old.
  ///
  /// In en, this message translates to:
  /// **'Update your Casama server to use the watch'**
  String get watchServerTooOld;

  /// Shown on the watch app (D-410). Asking is off; answers still work.
  ///
  /// In en, this message translates to:
  /// **'Out of credits'**
  String get watchOutOfCredits;

  /// Shown on the watch app (D-410). Talk starts the call on the phone.
  ///
  /// In en, this message translates to:
  /// **'Starting the call on your phone'**
  String get watchTalkOnPhone;

  /// Shown on the watch app (D-410). Sign out.
  ///
  /// In en, this message translates to:
  /// **'Sign out of this watch'**
  String get watchSignOut;

  /// Shown on the watch app (D-410). Switch.
  ///
  /// In en, this message translates to:
  /// **'Hide details when my wrist is down'**
  String get watchHideDetails;

  /// Shown on the watch app (D-410). Switch.
  ///
  /// In en, this message translates to:
  /// **'Read replies aloud'**
  String get watchReadRepliesAloud;

  /// Shown on the watch app (D-410). Which bot Ask goes to.
  ///
  /// In en, this message translates to:
  /// **'Ask uses'**
  String get watchAskUses;

  /// Shown on the watch app (D-410). The workspace the watch shows.
  ///
  /// In en, this message translates to:
  /// **'Workspace'**
  String get watchWorkspace;

  /// Shown on the watch app (D-410). Label above the person in settings.
  ///
  /// In en, this message translates to:
  /// **'Signed in as'**
  String get watchSignedInAsLabel;

  /// Shown on the watch app (D-410). Complication's name in the face editor.
  ///
  /// In en, this message translates to:
  /// **'Needs you'**
  String get watchCompNeedsYou;

  /// Shown on the watch app (D-410). Complication's name.
  ///
  /// In en, this message translates to:
  /// **'Ask a bot'**
  String get watchCompAsk;

  /// Shown on the watch app (D-410). Complication's name.
  ///
  /// In en, this message translates to:
  /// **'Bot'**
  String get watchCompBot;

  /// Shown on the watch app (D-410). Complication's name.
  ///
  /// In en, this message translates to:
  /// **'Up next'**
  String get watchCompUpNext;

  /// Shown on the watch app (D-410). Inline complication's name.
  ///
  /// In en, this message translates to:
  /// **'Casama'**
  String get watchCompCasama;

  /// Shown on the watch app (D-410). Complication description.
  ///
  /// In en, this message translates to:
  /// **'How many requests wait, and the first one'**
  String get watchCompDescNeedsYou;

  /// Shown on the watch app (D-410). Complication description.
  ///
  /// In en, this message translates to:
  /// **'Ask a bot by voice in one tap'**
  String get watchCompDescAsk;

  /// Shown on the watch app (D-410). Complication description.
  ///
  /// In en, this message translates to:
  /// **'Where a bot stands and what it is doing'**
  String get watchCompDescBot;

  /// Shown on the watch app (D-410). Complication description.
  ///
  /// In en, this message translates to:
  /// **'The next routine and when it runs'**
  String get watchCompDescUpNext;

  /// Shown on the watch app (D-410). Complication description.
  ///
  /// In en, this message translates to:
  /// **'Credits used this period'**
  String get watchCompDescCredits;

  /// Shown on the watch app (D-410). Curved text beside the count on a corner complication.
  ///
  /// In en, this message translates to:
  /// **'need you'**
  String get watchNeedYouShort;

  /// Shown on the watch app (D-410). Control name.
  ///
  /// In en, this message translates to:
  /// **'Ask Casama'**
  String get watchControlAsk;

  /// Shown on the watch app (D-410). Control name.
  ///
  /// In en, this message translates to:
  /// **'Talk to a bot'**
  String get watchControlTalk;

  /// Shown on the watch app (D-410). Control name.
  ///
  /// In en, this message translates to:
  /// **'Run a routine'**
  String get watchControlRun;

  /// Shown on the watch app (D-410). Siri says what needs the person.
  ///
  /// In en, this message translates to:
  /// **'{count} need you. First: {text}'**
  String watchSiriNeeds(String count, String text);

  /// Shown in Settings → Watch on the phone (D-410). Screen title.
  ///
  /// In en, this message translates to:
  /// **'Watch'**
  String get watchPhoneTitle;

  /// Shown in Settings → Watch on the phone (D-410). Intro line.
  ///
  /// In en, this message translates to:
  /// **'Answer bots, ask by voice and see who is working, from your wrist.'**
  String get watchPhoneIntro;

  /// Shown in Settings → Watch on the phone (D-410). Section title.
  ///
  /// In en, this message translates to:
  /// **'Signed-in watches'**
  String get watchPhoneWatches;

  /// Shown in Settings → Watch on the phone (D-410). Empty list.
  ///
  /// In en, this message translates to:
  /// **'No watch signed in yet. Open Casama on your watch and it signs in by itself.'**
  String get watchPhoneNone;

  /// Shown in Settings → Watch on the phone (D-410). When a watch was last used.
  ///
  /// In en, this message translates to:
  /// **'Last used {time}'**
  String watchPhoneLastUsed(String time);

  /// Shown in Settings → Watch on the phone (D-410). A watch never used.
  ///
  /// In en, this message translates to:
  /// **'Not used yet'**
  String get watchPhoneNeverUsed;

  /// Shown in Settings → Watch on the phone (D-410). Remove a watch.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get watchPhoneRemove;

  /// Shown in Settings → Watch on the phone (D-410). Confirm removal.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String watchPhoneRemoveTitle(String name);

  /// Shown in Settings → Watch on the phone (D-410). Confirm removal body.
  ///
  /// In en, this message translates to:
  /// **'It signs out at once. You can sign it in again later.'**
  String get watchPhoneRemoveBody;

  /// Shown in Settings → Watch on the phone (D-410). Open the code entry.
  ///
  /// In en, this message translates to:
  /// **'Sign in a watch with a code'**
  String get watchPhoneUseCode;

  /// Shown in Settings → Watch on the phone (D-410). Code field label.
  ///
  /// In en, this message translates to:
  /// **'The code on your watch'**
  String get watchPhoneCodeHint;

  /// Shown in Settings → Watch on the phone (D-410). Confirm a code.
  ///
  /// In en, this message translates to:
  /// **'Sign in {name}?'**
  String watchPhoneCodeAsk(String name);

  /// Shown in Settings → Watch on the phone (D-410). Confirm a code body.
  ///
  /// In en, this message translates to:
  /// **'It will be signed in to {workspace} as you. Only allow a code shown on your own watch.'**
  String watchPhoneCodeAskBody(String workspace);

  /// Shown in Settings → Watch on the phone (D-410). Confirm a code button.
  ///
  /// In en, this message translates to:
  /// **'Sign it in'**
  String get watchPhoneCodeAllow;

  /// Shown in Settings → Watch on the phone (D-410). Wrong code.
  ///
  /// In en, this message translates to:
  /// **'That code didn\'t work. Check it on your watch'**
  String get watchPhoneCodeWrong;

  /// Shown in Settings → Watch on the phone (D-410). Signing a watch in with a code failed because its key belongs to another account.
  ///
  /// In en, this message translates to:
  /// **'This watch is still signed in to another account. Remove it there in Settings → Watch, then get a new code'**
  String get watchPhoneCodeTaken;

  /// Shown in Settings → Watch on the phone (D-410). Under a watch that is still in another workspace than the one selected.
  ///
  /// In en, this message translates to:
  /// **'Signed in to {workspace}'**
  String watchPhoneElsewhere(String workspace);

  /// Shown in Settings → Watch on the phone (D-410). Under a watch in another workspace whose name isn't known.
  ///
  /// In en, this message translates to:
  /// **'Signed in to another workspace'**
  String get watchPhoneElsewhereUnknown;

  /// Shown in Settings → Watch on the phone (D-410). After a watch signs in.
  ///
  /// In en, this message translates to:
  /// **'{name} is signed in'**
  String watchPhoneSignedIn(String name);

  /// Shown in Settings → Watch on the phone (D-410). Setting title.
  ///
  /// In en, this message translates to:
  /// **'Allow from the watch'**
  String get watchPhoneAllowTitle;

  /// Shown in Settings → Watch on the phone (D-410). Allow level (default).
  ///
  /// In en, this message translates to:
  /// **'Low and medium risk'**
  String get watchPhoneAllowMedium;

  /// Shown in Settings → Watch on the phone (D-410). Allow level description.
  ///
  /// In en, this message translates to:
  /// **'Low risk in one tap, medium risk with a hold. High risk and payments always need your phone.'**
  String get watchPhoneAllowMediumBody;

  /// Shown in Settings → Watch on the phone (D-410). Allow level.
  ///
  /// In en, this message translates to:
  /// **'Low risk only'**
  String get watchPhoneAllowLow;

  /// Shown in Settings → Watch on the phone (D-410). Allow level: the watch can only deny.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get watchPhoneAllowNone;

  /// Shown in Settings → Watch on the phone (D-410). Switch.
  ///
  /// In en, this message translates to:
  /// **'Show details on the watch'**
  String get watchPhoneDetails;

  /// Shown in Settings → Watch on the phone (D-410). Switch description.
  ///
  /// In en, this message translates to:
  /// **'Off: the watch shows counts and bot names, not what bots wrote.'**
  String get watchPhoneDetailsBody;

  /// Shown in Settings → Watch on the phone (D-410). Section title.
  ///
  /// In en, this message translates to:
  /// **'Quick replies'**
  String get watchPhoneQuickReplies;

  /// Shown in Settings → Watch on the phone (D-410). Section description.
  ///
  /// In en, this message translates to:
  /// **'Short answers you can send from a reply notification. Up to six.'**
  String get watchPhoneQuickRepliesBody;

  /// Shown in Settings → Watch on the phone (D-410). Add button.
  ///
  /// In en, this message translates to:
  /// **'Add a quick reply'**
  String get watchPhoneQuickAdd;

  /// Shown in Settings → Watch on the phone (D-410). Reset button.
  ///
  /// In en, this message translates to:
  /// **'Use the built-in replies'**
  String get watchPhoneQuickReset;

  /// Shown in Settings → Watch on the phone (D-410). Section title.
  ///
  /// In en, this message translates to:
  /// **'Add Casama to your watch face'**
  String get watchPhoneHowTo;

  /// Shown in Settings → Watch on the phone (D-410). How-to (Apple Watch).
  ///
  /// In en, this message translates to:
  /// **'Touch and hold your watch face, tap Edit, then choose Casama for a complication. Turn the Digital Crown on the face to find Casama in the Smart Stack.'**
  String get watchPhoneHowToApple;

  /// Shown in Settings → Watch on the phone (D-410). How-to (Wear OS).
  ///
  /// In en, this message translates to:
  /// **'Touch and hold your watch face to add a Casama complication. Swipe left from the face and tap + to add a Casama tile.'**
  String get watchPhoneHowToWear;

  /// Shown in Settings → Watch on the phone (D-410). Shown while the phone signs a watch in.
  ///
  /// In en, this message translates to:
  /// **'Signing in {name}…'**
  String watchPhoneSigningInBanner(String name);

  /// Shown in Settings → Watch on the phone (D-410). With the app lock on, asks before signing a watch in.
  ///
  /// In en, this message translates to:
  /// **'Sign in your watch?'**
  String get watchPhoneLockAsk;

  /// Shown in Settings → Watch on the phone (D-410). One-time nudge after the first approval.
  ///
  /// In en, this message translates to:
  /// **'Casama is on your watch too. Answer bots from your wrist.'**
  String get watchPhoneNudge;

  /// Shown in Settings → Watch on the phone (D-410). Notification title for Open on phone.
  ///
  /// In en, this message translates to:
  /// **'From your watch'**
  String get watchPhoneHandoffTitle;

  /// Shown in Settings → Watch on the phone (D-410). Settings row subtitle.
  ///
  /// In en, this message translates to:
  /// **'Your bots on your Apple Watch or Wear OS watch'**
  String get watchPhoneRow;

  /// Shown in Settings → Watch on the phone (D-410). Allow level description (low risk only).
  ///
  /// In en, this message translates to:
  /// **'Low risk in one tap. Everything else needs your phone.'**
  String get watchPhoneAllowLowBody;

  /// Shown in Settings → Watch on the phone (D-410). Allow level description (never).
  ///
  /// In en, this message translates to:
  /// **'The watch can only deny. Allow on your phone.'**
  String get watchPhoneAllowNoneBody;

  /// Shown in Settings → Watch on the phone (D-410). Under Show details, after it was turned off because the app lock is on.
  ///
  /// In en, this message translates to:
  /// **'Turned off because the app lock is on, so your watch shows no words from your chats. Turn it on to see them.'**
  String get watchPhoneDetailsLockOff;

  /// Shown in Settings → Watch on the phone (D-410). Quick reply field hint.
  ///
  /// In en, this message translates to:
  /// **'A short reply'**
  String get watchPhoneQuickHint;

  /// Shown in Settings → Watch on the phone (D-410). Quick reply too long.
  ///
  /// In en, this message translates to:
  /// **'Up to 40 characters'**
  String get watchPhoneQuickTooLong;

  /// Shown in Settings → Watch on the phone (D-410). Tooltip: move a quick reply up.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get watchPhoneQuickMoveUp;

  /// Shown in Settings → Watch on the phone (D-410). Tooltip: move a quick reply down.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get watchPhoneQuickMoveDown;

  /// Shown in Settings → Watch on the phone (D-410). Tooltip: delete a quick reply.
  ///
  /// In en, this message translates to:
  /// **'Delete this reply'**
  String get watchPhoneQuickDelete;

  /// Shown in Settings → Watch on the phone (D-410). Code entry sheet subtitle.
  ///
  /// In en, this message translates to:
  /// **'On your watch, open Casama and choose Sign in with a code.'**
  String get watchPhoneCodeBody;

  /// Shown in Settings → Watch on the phone (D-410). Heading in the how-to.
  ///
  /// In en, this message translates to:
  /// **'Apple Watch'**
  String get watchPhoneAppleWatch;

  /// Shown in Settings → Watch on the phone (D-410). Heading in the how-to.
  ///
  /// In en, this message translates to:
  /// **'Wear OS'**
  String get watchPhoneWearOs;

  /// Shown on the watch app (D-410). Complication description.
  ///
  /// In en, this message translates to:
  /// **'Who is working and what they are doing'**
  String get watchCompDescWorking;

  /// Shown on the watch app (D-410). Complication description.
  ///
  /// In en, this message translates to:
  /// **'This morning\'s brief'**
  String get watchCompDescBrief;

  /// Shown on the watch app (D-410). Under the sign-in code while the watch waits for it to be typed.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the code…'**
  String get watchCodeWaiting;

  /// Shown on the watch app (D-410). Screen reader label for the sign-in code.
  ///
  /// In en, this message translates to:
  /// **'Sign-in code {code}'**
  String watchCodeA11y(String code);

  /// Shown on the watch app (D-410). Picker title for which bot Ask, a tile or a complication uses.
  ///
  /// In en, this message translates to:
  /// **'Choose a bot'**
  String get watchChooseBot;

  /// Shown on the watch app (D-410). Notification channel name (Wear OS): requests and suggestions.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get watchChannelRequests;

  /// Shown on the watch app (D-410). Notification channel name (Wear OS): replies, briefs, routine results.
  ///
  /// In en, this message translates to:
  /// **'Replies'**
  String get watchChannelReplies;

  /// Shown on the watch app (D-410). Notification channel name (Wear OS): a bot working right now.
  ///
  /// In en, this message translates to:
  /// **'Working bots'**
  String get watchChannelRuns;

  /// Shown on the watch app (D-410). Notification channel name (Wear OS): everything else.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get watchChannelOther;

  /// Shown on the watch app (D-410). A notification about the person's other workspace (the push says which workspace it is from, and it isn't the one this watch is signed in to): only the phone can answer it.
  ///
  /// In en, this message translates to:
  /// **'This is in another workspace. Answer it on your phone'**
  String get watchOtherWorkspace;

  /// Shown on the watch app (D-410). The tick after a reply typed or dictated from a notification went to the bot.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get watchReplySent;

  /// Shown on the watch app (D-410). A reply from a notification that the server didn't take; the chat opens so it can be said again.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send your reply'**
  String get watchReplyNotSent;

  /// Shown on the watch app (D-410). A kept ask the server refused, or kept failing on, was given up on.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send what you asked at {time}'**
  String watchAskDropped(String time);

  /// Shown on the watch app (D-410). The phone signed the watch in to a self-hosted server on plain http that isn't on the local network; the watch can't call it.
  ///
  /// In en, this message translates to:
  /// **'This watch can only reach your server over https or on your home network'**
  String get watchNeedsHttps;

  /// Shown on the watch app (D-410). Button on a signed-out watch: asks the phone to sign it in again.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get watchSignIn;

  /// Shown on the watch app (D-410). The server says a request or suggestion isn't in this watch's workspace (or isn't its to answer); it may still be waiting, so never "Already answered".
  ///
  /// In en, this message translates to:
  /// **'This watch can\'t answer this one. Open it on your phone'**
  String get watchNotOnWatch;

  /// Shown on the watch app (D-410). Under the Needs you list when more things wait than the watch can show (a skill idea, a question).
  ///
  /// In en, this message translates to:
  /// **'{count} more on your phone'**
  String watchMoreOnPhone(String count);

  /// No description provided for @showList.
  ///
  /// In en, this message translates to:
  /// **'Show the list'**
  String get showList;

  /// No description provided for @hideList.
  ///
  /// In en, this message translates to:
  /// **'Hide the list'**
  String get hideList;

  /// No description provided for @panePickLibrary.
  ///
  /// In en, this message translates to:
  /// **'Pick something from the Library to see it here.'**
  String get panePickLibrary;

  /// No description provided for @panePickSetting.
  ///
  /// In en, this message translates to:
  /// **'Pick a setting to see it here.'**
  String get panePickSetting;

  /// No description provided for @trackpad.
  ///
  /// In en, this message translates to:
  /// **'Trackpad'**
  String get trackpad;

  /// No description provided for @trackpadHint.
  ///
  /// In en, this message translates to:
  /// **'One finger moves the pointer, two scroll, a tap clicks.'**
  String get trackpadHint;

  /// No description provided for @trackpadTakeControl.
  ///
  /// In en, this message translates to:
  /// **'Take control to use the trackpad.'**
  String get trackpadTakeControl;

  /// No description provided for @foldScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Folding screen'**
  String get foldScreenTitle;

  /// No description provided for @foldRowHelp.
  ///
  /// In en, this message translates to:
  /// **'What Casama sees of this device\'s screens'**
  String get foldRowHelp;

  /// No description provided for @foldScreenHelp.
  ///
  /// In en, this message translates to:
  /// **'How this device is held and where its fold is, as Casama sees it now. Open, close or fold the device and the numbers follow. Copy them if a screen looks wrong.'**
  String get foldScreenHelp;

  /// No description provided for @foldPose.
  ///
  /// In en, this message translates to:
  /// **'Pose'**
  String get foldPose;

  /// No description provided for @foldWindow.
  ///
  /// In en, this message translates to:
  /// **'Window'**
  String get foldWindow;

  /// No description provided for @foldInsets.
  ///
  /// In en, this message translates to:
  /// **'Safe area'**
  String get foldInsets;

  /// No description provided for @foldStrip.
  ///
  /// In en, this message translates to:
  /// **'Side strip'**
  String get foldStrip;

  /// No description provided for @foldFold.
  ///
  /// In en, this message translates to:
  /// **'Fold'**
  String get foldFold;

  /// No description provided for @foldHinge.
  ///
  /// In en, this message translates to:
  /// **'Hinge'**
  String get foldHinge;

  /// No description provided for @foldSystemSays.
  ///
  /// In en, this message translates to:
  /// **'What the system reports'**
  String get foldSystemSays;

  /// D-427. On the sign-in screen while Casama Cloud takes new accounts only by invitation. Never the word beta (App Store 2.2).
  ///
  /// In en, this message translates to:
  /// **'Casama Cloud is invite-only for now.'**
  String get inviteGateLine;

  /// No description provided for @inviteGateSelfHost.
  ///
  /// In en, this message translates to:
  /// **'Running Casama on your own server is open to everyone.'**
  String get inviteGateSelfHost;

  /// D-427. Button on the sign-in screen and the refusal sheet; also the waitlist form's title and button.
  ///
  /// In en, this message translates to:
  /// **'Join the Waitlist'**
  String get joinTheWaitlist;

  /// D-427. Button on the sign-in screen and the refusal sheet; also the invite screen's title.
  ///
  /// In en, this message translates to:
  /// **'I Have an Invite'**
  String get iHaveAnInvite;

  /// No description provided for @waitlistSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'re letting people in every day. You\'ll get one email when it\'s your turn.'**
  String get waitlistSubtitle;

  /// No description provided for @waitlistNote.
  ///
  /// In en, this message translates to:
  /// **'What would you have a bot do first?'**
  String get waitlistNote;

  /// No description provided for @waitlistNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get waitlistNoteHint;

  /// No description provided for @waitlistSelfHosting.
  ///
  /// In en, this message translates to:
  /// **'I run Casama on my own server'**
  String get waitlistSelfHosting;

  /// No description provided for @waitlistNewsletter.
  ///
  /// In en, this message translates to:
  /// **'Also send me Casama\'s monthly email (once a month at most)'**
  String get waitlistNewsletter;

  /// No description provided for @waitlistAppleRelay.
  ///
  /// In en, this message translates to:
  /// **'This is the private address Apple made for you. Keep it if you\'ll sign in with Apple; Apple forwards our email to your inbox.'**
  String get waitlistAppleRelay;

  /// No description provided for @waitlistJoinedTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re on the list.'**
  String get waitlistJoinedTitle;

  /// No description provided for @waitlistJoinedBody.
  ///
  /// In en, this message translates to:
  /// **'We\'re letting people in every day. You\'ll get one email when it\'s your turn, and nothing else unless you asked for the monthly email.'**
  String get waitlistJoinedBody;

  /// No description provided for @waitlistJoinedCode.
  ///
  /// In en, this message translates to:
  /// **'Have an invite code? Enter it here.'**
  String get waitlistJoinedCode;

  /// No description provided for @waitlistJoinedSelfHost.
  ///
  /// In en, this message translates to:
  /// **'Don\'t want to wait? Casama is open source. Run it on your own computer today.'**
  String get waitlistJoinedSelfHost;

  /// No description provided for @waitlistRunItYourself.
  ///
  /// In en, this message translates to:
  /// **'Run It Yourself'**
  String get waitlistRunItYourself;

  /// No description provided for @inviteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your invite code, or paste the invite link.'**
  String get inviteSubtitle;

  /// No description provided for @inviteCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Invite code'**
  String get inviteCodeLabel;

  /// No description provided for @inviteNotFound.
  ///
  /// In en, this message translates to:
  /// **'That code doesn\'t match any invite. Check it and try again.'**
  String get inviteNotFound;

  /// No description provided for @inviteFromName.
  ///
  /// In en, this message translates to:
  /// **'{name} invited you to Casama'**
  String inviteFromName(String name);

  /// No description provided for @inviteFromFriend.
  ///
  /// In en, this message translates to:
  /// **'A friend invited you to Casama'**
  String get inviteFromFriend;

  /// No description provided for @inviteFromCampaign.
  ///
  /// In en, this message translates to:
  /// **'Your invite: {label}'**
  String inviteFromCampaign(String label);

  /// No description provided for @inviteFromCasama.
  ///
  /// In en, this message translates to:
  /// **'Your invite to Casama'**
  String get inviteFromCasama;

  /// No description provided for @inviteChooseSignIn.
  ///
  /// In en, this message translates to:
  /// **'Now choose how you\'ll sign in. Use the address you want for your account.'**
  String get inviteChooseSignIn;

  /// No description provided for @inviteGoneHelp.
  ///
  /// In en, this message translates to:
  /// **'These invites are gone. Enter your email and you\'ll go on the waitlist, ahead of the line.'**
  String get inviteGoneHelp;

  /// No description provided for @inviteEmailHelp.
  ///
  /// In en, this message translates to:
  /// **'We\'ll let this address in, then send it a sign-in link.'**
  String get inviteEmailHelp;

  /// No description provided for @inviteCheckInbox.
  ///
  /// In en, this message translates to:
  /// **'You\'re in. Check {email} for a sign-in link, or type its code here.'**
  String inviteCheckInbox(String email);

  /// No description provided for @inviteWaitlistedTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re on the waitlist'**
  String get inviteWaitlistedTitle;

  /// No description provided for @inviteWaitlisted.
  ///
  /// In en, this message translates to:
  /// **'These invites are gone, but you\'re ahead of the line.'**
  String get inviteWaitlisted;

  /// No description provided for @inviteUseEmailHere.
  ///
  /// In en, this message translates to:
  /// **'On this device, use Continue with Email. Apple and Google work with an invite in the iPhone, Mac and Android apps.'**
  String get inviteUseEmailHere;

  /// No description provided for @inviteDifferentCode.
  ///
  /// In en, this message translates to:
  /// **'Use a Different Code'**
  String get inviteDifferentCode;

  /// No description provided for @inviteRefusedHelp.
  ///
  /// In en, this message translates to:
  /// **'Join the waitlist and we\'ll email you when it\'s your turn, or enter an invite code if you have one.'**
  String get inviteRefusedHelp;

  /// D-427. Invite Friends while Casama Cloud is invite-only: how many of the member's invites are left. Never 'invite friends to get in' (App Store 3.2.2).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No invites left} =1{1 invite left} other{{count} invites left}}'**
  String inviteFriendsInvitesLeft(int count);

  /// No description provided for @inviteFriendsInvitesUsed.
  ///
  /// In en, this message translates to:
  /// **'{used} of {total} used. Each one lets a friend make an account.'**
  String inviteFriendsInvitesUsed(int used, int total);

  /// No description provided for @inviteFriendsInvitesLocked.
  ///
  /// In en, this message translates to:
  /// **'Your invites unlock after your first finished chat.'**
  String get inviteFriendsInvitesLocked;

  /// No description provided for @adminWaitlist.
  ///
  /// In en, this message translates to:
  /// **'Waitlist'**
  String get adminWaitlist;

  /// No description provided for @adminWaitlistWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get adminWaitlistWaiting;

  /// No description provided for @adminWaitlistListedToday.
  ///
  /// In en, this message translates to:
  /// **'Joined the list today'**
  String get adminWaitlistListedToday;

  /// No description provided for @adminWaitlistAdmittedToday.
  ///
  /// In en, this message translates to:
  /// **'Let in today'**
  String get adminWaitlistAdmittedToday;

  /// No description provided for @adminWaitlistAdmittedTotal.
  ///
  /// In en, this message translates to:
  /// **'Let in, total'**
  String get adminWaitlistAdmittedTotal;

  /// No description provided for @adminWaitlistJoined.
  ///
  /// In en, this message translates to:
  /// **'Signed up'**
  String get adminWaitlistJoined;

  /// No description provided for @adminWaitlistFirstChat.
  ///
  /// In en, this message translates to:
  /// **'First chat'**
  String get adminWaitlistFirstChat;

  /// No description provided for @adminWaitlistEmailsToday.
  ///
  /// In en, this message translates to:
  /// **'\"You\'re in\" emails today'**
  String get adminWaitlistEmailsToday;

  /// No description provided for @adminWaitlistEmailsOf.
  ///
  /// In en, this message translates to:
  /// **'{sent} of {max}'**
  String adminWaitlistEmailsOf(int sent, int max);

  /// No description provided for @adminWaitlistLastBatch.
  ///
  /// In en, this message translates to:
  /// **'Last batch'**
  String get adminWaitlistLastBatch;

  /// No description provided for @adminWaitlistLastBatchValue.
  ///
  /// In en, this message translates to:
  /// **'{count} let in'**
  String adminWaitlistLastBatchValue(int count);

  /// No description provided for @adminWaitlistLastBatchSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped. {reason}'**
  String adminWaitlistLastBatchSkipped(String reason);

  /// No description provided for @adminWaitlistBySource.
  ///
  /// In en, this message translates to:
  /// **'By source'**
  String get adminWaitlistBySource;

  /// No description provided for @adminWaitlistSourceRow.
  ///
  /// In en, this message translates to:
  /// **'{listed} on the list · {admitted} let in · {joined} signed up · {firstChat} first chat'**
  String adminWaitlistSourceRow(
    int listed,
    int admitted,
    int joined,
    int firstChat,
  );

  /// No description provided for @adminWaitlistAdmit.
  ///
  /// In en, this message translates to:
  /// **'Admit'**
  String get adminWaitlistAdmit;

  /// No description provided for @adminWaitlistAdmitPrompt.
  ///
  /// In en, this message translates to:
  /// **'Let in the next people in line'**
  String get adminWaitlistAdmitPrompt;

  /// No description provided for @adminWaitlistAdmitCount.
  ///
  /// In en, this message translates to:
  /// **'How many'**
  String get adminWaitlistAdmitCount;

  /// No description provided for @adminWaitlistAdmitTitle.
  ///
  /// In en, this message translates to:
  /// **'Let in the next {count} in line?'**
  String adminWaitlistAdmitTitle(int count);

  /// No description provided for @adminWaitlistAdmitBody.
  ///
  /// In en, this message translates to:
  /// **'Each gets a \"You\'re in\" email, within today\'s email limit.'**
  String get adminWaitlistAdmitBody;

  /// No description provided for @adminWaitlistAdmitted.
  ///
  /// In en, this message translates to:
  /// **'{count} let in.'**
  String adminWaitlistAdmitted(int count);

  /// No description provided for @adminWaitlistAdd.
  ///
  /// In en, this message translates to:
  /// **'Add Addresses'**
  String get adminWaitlistAdd;

  /// No description provided for @adminWaitlistAddHelp.
  ///
  /// In en, this message translates to:
  /// **'They\'re let in at once. One per line, or separated by commas.'**
  String get adminWaitlistAddHelp;

  /// No description provided for @adminWaitlistAddLabel.
  ///
  /// In en, this message translates to:
  /// **'Email addresses'**
  String get adminWaitlistAddLabel;

  /// No description provided for @adminWaitlistAddNotify.
  ///
  /// In en, this message translates to:
  /// **'Send each the \"You\'re in\" email'**
  String get adminWaitlistAddNotify;

  /// No description provided for @adminWaitlistAdded.
  ///
  /// In en, this message translates to:
  /// **'{count} added.'**
  String adminWaitlistAdded(int count);

  /// No description provided for @adminWaitlistSkipped.
  ///
  /// In en, this message translates to:
  /// **'Not email addresses: {list}'**
  String adminWaitlistSkipped(String list);

  /// No description provided for @adminWaitlistRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {email} from the waitlist?'**
  String adminWaitlistRemoveTitle(String email);

  /// No description provided for @adminWaitlistRemoveBody.
  ///
  /// In en, this message translates to:
  /// **'The entry is deleted. They can join again later.'**
  String get adminWaitlistRemoveBody;

  /// No description provided for @adminWaitlistPeople.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get adminWaitlistPeople;

  /// No description provided for @adminWaitlistSearch.
  ///
  /// In en, this message translates to:
  /// **'Search by email'**
  String get adminWaitlistSearch;

  /// No description provided for @adminWaitlistNone.
  ///
  /// In en, this message translates to:
  /// **'No one here yet.'**
  String get adminWaitlistNone;

  /// No description provided for @adminWaitlistShowMore.
  ///
  /// In en, this message translates to:
  /// **'Show More'**
  String get adminWaitlistShowMore;

  /// No description provided for @adminWaitlistStatusWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get adminWaitlistStatusWaiting;

  /// No description provided for @adminWaitlistStatusQueued.
  ///
  /// In en, this message translates to:
  /// **'Chosen'**
  String get adminWaitlistStatusQueued;

  /// No description provided for @adminWaitlistStatusAdmitted.
  ///
  /// In en, this message translates to:
  /// **'Let in'**
  String get adminWaitlistStatusAdmitted;

  /// No description provided for @adminWaitlistStatusJoined.
  ///
  /// In en, this message translates to:
  /// **'Signed up'**
  String get adminWaitlistStatusJoined;

  /// No description provided for @adminWaitlistSelfHosts.
  ///
  /// In en, this message translates to:
  /// **'Runs their own server'**
  String get adminWaitlistSelfHosts;

  /// No description provided for @adminCampaigns.
  ///
  /// In en, this message translates to:
  /// **'Campaign codes'**
  String get adminCampaigns;

  /// No description provided for @adminCampaignNew.
  ///
  /// In en, this message translates to:
  /// **'New Code'**
  String get adminCampaignNew;

  /// No description provided for @adminCampaignCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get adminCampaignCode;

  /// No description provided for @adminCampaignCodeHelp.
  ///
  /// In en, this message translates to:
  /// **'9 or more characters, or with a hyphen: letters, digits and hyphens (SHOWHN-DEC8).'**
  String get adminCampaignCodeHelp;

  /// No description provided for @adminCampaignLabel.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get adminCampaignLabel;

  /// No description provided for @adminCampaignTotal.
  ///
  /// In en, this message translates to:
  /// **'Total uses'**
  String get adminCampaignTotal;

  /// No description provided for @adminCampaignPerDay.
  ///
  /// In en, this message translates to:
  /// **'A day at most (optional)'**
  String get adminCampaignPerDay;

  /// No description provided for @adminCampaignStarts.
  ///
  /// In en, this message translates to:
  /// **'Starts'**
  String get adminCampaignStarts;

  /// No description provided for @adminCampaignEnds.
  ///
  /// In en, this message translates to:
  /// **'Ends'**
  String get adminCampaignEnds;

  /// No description provided for @adminCampaignAnyTime.
  ///
  /// In en, this message translates to:
  /// **'Any time'**
  String get adminCampaignAnyTime;

  /// No description provided for @adminCampaignCreate.
  ///
  /// In en, this message translates to:
  /// **'Create Code'**
  String get adminCampaignCreate;

  /// No description provided for @adminCampaignUsed.
  ///
  /// In en, this message translates to:
  /// **'{used} of {total} used'**
  String adminCampaignUsed(int used, int total);

  /// No description provided for @adminCampaignPerDayShort.
  ///
  /// In en, this message translates to:
  /// **'{count} a day'**
  String adminCampaignPerDayShort(int count);

  /// No description provided for @adminCampaignEndsOn.
  ///
  /// In en, this message translates to:
  /// **'ends {date}'**
  String adminCampaignEndsOn(String date);

  /// No description provided for @adminCampaignStartsOn.
  ///
  /// In en, this message translates to:
  /// **'starts {date}'**
  String adminCampaignStartsOn(String date);

  /// No description provided for @adminCampaignOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get adminCampaignOff;

  /// No description provided for @adminCampaignTurnOff.
  ///
  /// In en, this message translates to:
  /// **'Turn Off'**
  String get adminCampaignTurnOff;

  /// No description provided for @adminCampaignTurnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn On'**
  String get adminCampaignTurnOn;

  /// No description provided for @adminCampaignNone.
  ///
  /// In en, this message translates to:
  /// **'No campaign codes yet.'**
  String get adminCampaignNone;

  /// No description provided for @adminCampaignCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied.'**
  String get adminCampaignCopied;

  /// No description provided for @adminGate.
  ///
  /// In en, this message translates to:
  /// **'Sign-ups'**
  String get adminGate;

  /// No description provided for @adminGateInviteOnly.
  ///
  /// In en, this message translates to:
  /// **'Invite-only'**
  String get adminGateInviteOnly;

  /// No description provided for @adminGateInviteOnlyHelp.
  ///
  /// In en, this message translates to:
  /// **'New accounts only for people let in from the waitlist or with an invite code. Existing accounts sign in as always.'**
  String get adminGateInviteOnlyHelp;

  /// No description provided for @adminGateOpenTitle.
  ///
  /// In en, this message translates to:
  /// **'Open sign-ups to everyone?'**
  String get adminGateOpenTitle;

  /// No description provided for @adminGateOpenBody.
  ///
  /// In en, this message translates to:
  /// **'Anyone can make an account straight away. The waitlist stays as it is.'**
  String get adminGateOpenBody;

  /// No description provided for @adminGateOpenConfirm.
  ///
  /// In en, this message translates to:
  /// **'Open Sign-Ups'**
  String get adminGateOpenConfirm;

  /// No description provided for @adminGateCloseTitle.
  ///
  /// In en, this message translates to:
  /// **'Make Casama Cloud invite-only?'**
  String get adminGateCloseTitle;

  /// No description provided for @adminGateCloseBody.
  ///
  /// In en, this message translates to:
  /// **'New people need an invite code, or a place let in from the waitlist. Existing accounts keep signing in.'**
  String get adminGateCloseBody;

  /// No description provided for @adminGateCloseConfirm.
  ///
  /// In en, this message translates to:
  /// **'Make Invite-Only'**
  String get adminGateCloseConfirm;

  /// No description provided for @adminGateClosedNow.
  ///
  /// In en, this message translates to:
  /// **'Invite-only now'**
  String get adminGateClosedNow;

  /// No description provided for @adminGateOpenNow.
  ///
  /// In en, this message translates to:
  /// **'Open now'**
  String get adminGateOpenNow;

  /// No description provided for @adminGateOpensAt.
  ///
  /// In en, this message translates to:
  /// **'Opens on its own'**
  String get adminGateOpensAt;

  /// No description provided for @adminGateOpensAtNone.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get adminGateOpensAtNone;

  /// No description provided for @adminGateClearOpensAt.
  ///
  /// In en, this message translates to:
  /// **'Clear the Opening Time'**
  String get adminGateClearOpensAt;

  /// No description provided for @adminGateInvites.
  ///
  /// In en, this message translates to:
  /// **'Invites per person'**
  String get adminGateInvites;

  /// No description provided for @adminGateDailyAdmit.
  ///
  /// In en, this message translates to:
  /// **'Let in each day'**
  String get adminGateDailyAdmit;

  /// No description provided for @adminGateDailyAdmitOff.
  ///
  /// In en, this message translates to:
  /// **'None (by hand only)'**
  String get adminGateDailyAdmitOff;

  /// No description provided for @adminGateDailyEmails.
  ///
  /// In en, this message translates to:
  /// **'\"You\'re in\" emails a day at most'**
  String get adminGateDailyEmails;

  /// No description provided for @adminGateBatchHour.
  ///
  /// In en, this message translates to:
  /// **'Batch time (UTC)'**
  String get adminGateBatchHour;

  /// No description provided for @adminGateBatchHourValue.
  ///
  /// In en, this message translates to:
  /// **'{hour}:00 UTC'**
  String adminGateBatchHourValue(String hour);

  /// No description provided for @adminGateNumberInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a whole number'**
  String get adminGateNumberInvalid;

  /// No description provided for @savedResetAvailable.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1 {1 reset saved} other {{count} resets saved}}'**
  String savedResetAvailable(int count);

  /// No description provided for @savedResetExpiry.
  ///
  /// In en, this message translates to:
  /// **'Use by {date}'**
  String savedResetExpiry(String date);

  /// No description provided for @savedResetUse.
  ///
  /// In en, this message translates to:
  /// **'Use Reset'**
  String get savedResetUse;

  /// No description provided for @savedResetConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Use this reset?'**
  String get savedResetConfirmTitle;

  /// No description provided for @savedResetConfirmDaily.
  ///
  /// In en, this message translates to:
  /// **'Clears today’s limit so your bots can work again today. This can’t be undone.'**
  String get savedResetConfirmDaily;

  /// No description provided for @savedResetConfirmComputer.
  ///
  /// In en, this message translates to:
  /// **'Gives back this month’s computer hours. This can’t be undone.'**
  String get savedResetConfirmComputer;

  /// No description provided for @savedResetOwnerRequired.
  ///
  /// In en, this message translates to:
  /// **'Only a workspace owner can use it.'**
  String get savedResetOwnerRequired;

  /// No description provided for @savedResetPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused for now. Check back later.'**
  String get savedResetPaused;

  /// No description provided for @savedResetPeriodLimit.
  ///
  /// In en, this message translates to:
  /// **'You’ve used this period’s reset. You can use this one next period.'**
  String get savedResetPeriodLimit;

  /// No description provided for @savedResetNothingToRefill.
  ///
  /// In en, this message translates to:
  /// **'Nothing to refill yet. Keep it for when you run low.'**
  String get savedResetNothingToRefill;

  /// No description provided for @savedResetNoBillingPeriod.
  ///
  /// In en, this message translates to:
  /// **'Available once your plan finishes setting up.'**
  String get savedResetNoBillingPeriod;

  /// No description provided for @savedResetUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Not available right now.'**
  String get savedResetUnavailable;

  /// No description provided for @savedResetDone.
  ///
  /// In en, this message translates to:
  /// **'Reset used: {amount} added'**
  String savedResetDone(String amount);

  /// No description provided for @savedResetDoneNoCredits.
  ///
  /// In en, this message translates to:
  /// **'Reset used'**
  String get savedResetDoneNoCredits;

  /// No description provided for @savedResetConfirm.
  ///
  /// In en, this message translates to:
  /// **'Refills \${amount} of this period’s included credits. This can’t be undone.'**
  String savedResetConfirm(String amount);

  /// No description provided for @adminResets.
  ///
  /// In en, this message translates to:
  /// **'Resets'**
  String get adminResets;

  /// No description provided for @resetsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enable saved resets'**
  String get resetsEnabled;

  /// No description provided for @resetsPerPeriod.
  ///
  /// In en, this message translates to:
  /// **'Uses per workspace per period'**
  String get resetsPerPeriod;

  /// No description provided for @resetsMaxHeld.
  ///
  /// In en, this message translates to:
  /// **'Maximum saved resets'**
  String get resetsMaxHeld;

  /// No description provided for @resetsNotifyOwners.
  ///
  /// In en, this message translates to:
  /// **'Notify instance owners'**
  String get resetsNotifyOwners;

  /// No description provided for @resetsNewCampaign.
  ///
  /// In en, this message translates to:
  /// **'Reset campaign'**
  String get resetsNewCampaign;

  /// No description provided for @resetsName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get resetsName;

  /// No description provided for @resetsMessage.
  ///
  /// In en, this message translates to:
  /// **'Message to people'**
  String get resetsMessage;

  /// No description provided for @resetsPlans.
  ///
  /// In en, this message translates to:
  /// **'Plan codes, separated by commas (empty means all)'**
  String get resetsPlans;

  /// No description provided for @resetsWorkspaces.
  ///
  /// In en, this message translates to:
  /// **'Workspace IDs, separated by commas (empty means all)'**
  String get resetsWorkspaces;

  /// No description provided for @resetsBefore.
  ///
  /// In en, this message translates to:
  /// **'Created before (date and time, optional)'**
  String get resetsBefore;

  /// No description provided for @resetsLimitedDays.
  ///
  /// In en, this message translates to:
  /// **'Hit a limit in the last N days (optional)'**
  String get resetsLimitedDays;

  /// No description provided for @resetsStart.
  ///
  /// In en, this message translates to:
  /// **'Starts (date and time)'**
  String get resetsStart;

  /// No description provided for @resetsExpiry.
  ///
  /// In en, this message translates to:
  /// **'Expires (date and time)'**
  String get resetsExpiry;

  /// No description provided for @resetsPercent.
  ///
  /// In en, this message translates to:
  /// **'Included credits to refill (%)'**
  String get resetsPercent;

  /// No description provided for @resetsCap.
  ///
  /// In en, this message translates to:
  /// **'Maximum dollars per use (optional)'**
  String get resetsCap;

  /// No description provided for @resetsBudget.
  ///
  /// In en, this message translates to:
  /// **'Total credit budget in dollars (optional)'**
  String get resetsBudget;

  /// No description provided for @resetsDaily.
  ///
  /// In en, this message translates to:
  /// **'Clear today’s model limit'**
  String get resetsDaily;

  /// No description provided for @resetsComputer.
  ///
  /// In en, this message translates to:
  /// **'Refill this month’s computer hours'**
  String get resetsComputer;

  /// No description provided for @resetsArrival.
  ///
  /// In en, this message translates to:
  /// **'Notify on arrival'**
  String get resetsArrival;

  /// No description provided for @resetsReminder.
  ///
  /// In en, this message translates to:
  /// **'Remind before expiry'**
  String get resetsReminder;

  /// No description provided for @resetsPreviewSave.
  ///
  /// In en, this message translates to:
  /// **'Preview and save'**
  String get resetsPreviewSave;

  /// No description provided for @resetsSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get resetsSchedule;

  /// No description provided for @resetsPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get resetsPause;

  /// No description provided for @resetsResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resetsResume;

  /// No description provided for @resetsCampaignCounts.
  ///
  /// In en, this message translates to:
  /// **'{given} given · {used} used · \${credits} refilled'**
  String resetsCampaignCounts(int given, int used, String credits);

  /// No description provided for @resetsPreview.
  ///
  /// In en, this message translates to:
  /// **'{count} workspaces. Maximum refill: \${credits}. Estimated cost: \${cost}.'**
  String resetsPreview(int count, String credits, String cost);

  /// No description provided for @resetsWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Workspace ID (empty for all history)'**
  String get resetsWorkspace;

  /// No description provided for @resetsHistory.
  ///
  /// In en, this message translates to:
  /// **'Load history'**
  String get resetsHistory;

  /// No description provided for @resetsGive.
  ///
  /// In en, this message translates to:
  /// **'Give a reset'**
  String get resetsGive;

  /// No description provided for @resetsCopyCsv.
  ///
  /// In en, this message translates to:
  /// **'Copy CSV'**
  String get resetsCopyCsv;

  /// No description provided for @resetsRevoke.
  ///
  /// In en, this message translates to:
  /// **'Take back'**
  String get resetsRevoke;

  /// No description provided for @resetsUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo unused refill'**
  String get resetsUndo;

  /// No description provided for @adminVendors.
  ///
  /// In en, this message translates to:
  /// **'Vendors'**
  String get adminVendors;

  /// No description provided for @vendorNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Vendor services need attention'**
  String get vendorNeedsAttention;

  /// No description provided for @vendorNotSetUp.
  ///
  /// In en, this message translates to:
  /// **'Not set up'**
  String get vendorNotSetUp;

  /// No description provided for @vendorCheckNow.
  ///
  /// In en, this message translates to:
  /// **'Check now'**
  String get vendorCheckNow;

  /// No description provided for @vendorLimit.
  ///
  /// In en, this message translates to:
  /// **'Limit or prepaid amount'**
  String get vendorLimit;

  /// No description provided for @vendorWarnAt.
  ///
  /// In en, this message translates to:
  /// **'Warning threshold (0–1)'**
  String get vendorWarnAt;

  /// No description provided for @vendorExpiry.
  ///
  /// In en, this message translates to:
  /// **'Expiry (ISO date and time)'**
  String get vendorExpiry;

  /// No description provided for @vendorHistory.
  ///
  /// In en, this message translates to:
  /// **'Recent readings'**
  String get vendorHistory;

  /// No description provided for @vendorSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get vendorSave;

  /// No description provided for @vendorEnabled.
  ///
  /// In en, this message translates to:
  /// **'Monitoring enabled'**
  String get vendorEnabled;

  /// No description provided for @vendorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get vendorUnknown;

  /// No description provided for @vendorLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get vendorLow;

  /// No description provided for @vendorOut.
  ///
  /// In en, this message translates to:
  /// **'Out'**
  String get vendorOut;

  /// No description provided for @vendorOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get vendorOk;

  /// No description provided for @vendorNoReading.
  ///
  /// In en, this message translates to:
  /// **'No reading yet'**
  String get vendorNoReading;

  /// No description provided for @vendorCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'Check failed'**
  String get vendorCheckFailed;

  /// No description provided for @vendorResets.
  ///
  /// In en, this message translates to:
  /// **'Resets'**
  String get vendorResets;

  /// No description provided for @vendorSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get vendorSource;

  /// No description provided for @vendorBilling.
  ///
  /// In en, this message translates to:
  /// **'Billing and refill'**
  String get vendorBilling;

  /// No description provided for @vendorBalanceWarning.
  ///
  /// In en, this message translates to:
  /// **'Warn below balance'**
  String get vendorBalanceWarning;

  /// No description provided for @vendorPeriodStart.
  ///
  /// In en, this message translates to:
  /// **'Period start (ISO date and time)'**
  String get vendorPeriodStart;

  /// No description provided for @vendorInvalidSettings.
  ///
  /// In en, this message translates to:
  /// **'Enter a positive limit, a warning between 0 and 1, and valid dates.'**
  String get vendorInvalidSettings;
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
