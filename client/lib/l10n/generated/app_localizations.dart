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
