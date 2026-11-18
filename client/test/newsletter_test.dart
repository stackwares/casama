import 'package:casama/core/backend.dart';
import 'package:casama/features/auth/sign_in_screen.dart';
import 'package:casama/features/notifications/newsletter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

/// Casama's monthly email (D-408): the Settings switch, the one-time card and the sign-up box,
/// all hidden where the server doesn't send it.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Settings switch', () {
    testWidgets('off by default, turns on and off', (tester) async {
      final backend = FakeBackend()..newsletterAvailable = true;
      await tester.pumpWidget(
        harness(backend, const Scaffold(body: NewsletterTile())),
      );
      await tester.pumpAndSettle();
      expect(find.text("Casama's monthly email"), findsOneWidget);
      expect(
        find.text("What's new and what's next, once a month at most."),
        findsOneWidget,
      );
      expect(
        tester.widget<Switch>(find.byKey(const Key('newsletterSwitch'))).value,
        isFalse,
      );

      await tester.tap(find.byKey(const Key('newsletterSwitch')));
      await tester.pumpAndSettle();
      expect(backend.newsletterCalls.last, (
        subscribed: true,
        from: 'settings',
      ));
      expect(
        tester.widget<Switch>(find.byKey(const Key('newsletterSwitch'))).value,
        isTrue,
      );

      await tester.tap(find.byKey(const Key('newsletterSwitch')));
      await tester.pumpAndSettle();
      expect(backend.newsletterCalls.last.subscribed, isFalse);
    });

    testWidgets('hidden on a server that does not send it', (tester) async {
      await tester.pumpWidget(
        harness(FakeBackend(), const Scaffold(body: NewsletterTile())),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('settingsNewsletter')), findsNothing);
    });
  });

  group('one-time card', () {
    Future<FakeBackend> pumpCard(
      WidgetTester tester, {
      NewsletterChoice? choice,
      bool available = true,
    }) async {
      final backend = FakeBackend()..newsletterAvailable = available;
      if (choice != null) backend.newsletterChoice = choice;
      await tester.pumpWidget(
        harness(
          backend,
          const Scaffold(body: Column(children: [NewsletterCard()])),
        ),
      );
      await tester.pumpAndSettle();
      return backend;
    }

    testWidgets('Yes subscribes and the card goes', (tester) async {
      final backend = await pumpCard(tester);
      expect(find.text("Get Casama's monthly email?"), findsOneWidget);
      await tester.tap(find.byKey(const Key('newsletterCardYes')));
      await tester.pumpAndSettle();
      expect(backend.newsletterCalls.single, (subscribed: true, from: 'card'));
      expect(find.byKey(const Key('newsletterCard')), findsNothing);
      expect(
        find.text("You're on the list. Turn it off any time in Settings."),
        findsOneWidget,
      );
    });

    testWidgets('No thanks counts as asked, without subscribing', (
      tester,
    ) async {
      final backend = await pumpCard(tester);
      await tester.tap(find.byKey(const Key('newsletterCardNo')));
      await tester.pumpAndSettle();
      expect(backend.newsletterCalls.single, (subscribed: false, from: 'card'));
      expect(find.byKey(const Key('newsletterCard')), findsNothing);
    });

    testWidgets('closing it counts as asked too, without subscribing', (
      tester,
    ) async {
      final backend = await pumpCard(tester);
      await tester.tap(find.byKey(const Key('newsletterCardClose')));
      await tester.pumpAndSettle();
      expect(backend.newsletterCalls.single, (subscribed: null, from: 'card'));
      expect(backend.newsletterChoice.subscribed, isFalse);
      expect(find.byKey(const Key('newsletterCard')), findsNothing);
    });

    testWidgets(
      'shown only once, never to subscribers, never where it is not sent',
      (tester) async {
        await pumpCard(
          tester,
          choice: const NewsletterChoice(subscribed: false, asked: true),
        );
        expect(find.byKey(const Key('newsletterCard')), findsNothing);
        await pumpCard(
          tester,
          choice: const NewsletterChoice(subscribed: true, asked: false),
        );
        expect(find.byKey(const Key('newsletterCard')), findsNothing);
        await pumpCard(tester, available: false);
        expect(find.byKey(const Key('newsletterCard')), findsNothing);
      },
    );

    testWidgets(
      'a choice from the sign-up box is sent once and the card stays away',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          NewsletterSignUpChoice.key: true,
        });
        final backend = await pumpCard(tester);
        expect(backend.newsletterCalls.single, (
          subscribed: true,
          from: 'signup',
        ));
        expect(find.byKey(const Key('newsletterCard')), findsNothing);
        expect(await NewsletterSignUpChoice.read(), isNull);
      },
    );
  });

  group('sign-up box', () {
    Future<void> openSignUp(WidgetTester tester, FakeBackend backend) async {
      await setSize(tester, const Size(500, 1100));
      await tester.pumpWidget(harness(backend, const SignInScreen()));
      await tester.tap(find.byKey(const Key('openSignIn')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('continueWithEmail')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('usePassword')));
      await tester.pumpAndSettle();
    }

    testWidgets('unticked by default; a ticked box waits for the new account', (
      tester,
    ) async {
      final backend = FakeBackend()
        ..signedIn = false
        ..signUpSignsIn = false
        ..newsletterAvailable = true;
      await openSignUp(tester, backend);
      // Not on sign-in, only on sign-up.
      expect(find.byKey(const Key('newsletterSignUpBox')), findsNothing);
      await tester.tap(find.byKey(const Key('toggleMode')));
      await tester.pumpAndSettle();
      final box = find.byKey(const Key('newsletterSignUpBox'));
      expect(box, findsOneWidget);
      expect(tester.widget<CheckboxListTile>(box).value, isFalse);
      await tester.tap(box);
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('email')), 'ana@example.com');
      await tester.enterText(find.byKey(const Key('password')), 'secret-pw');
      await tester.tap(find.byKey(const Key('submit')));
      await tester.pumpAndSettle();
      expect(await NewsletterSignUpChoice.read(), isTrue);
      // Nothing is sent before the account exists.
      expect(backend.newsletterCalls, isEmpty);
    });

    testWidgets('left unticked, the answer is no', (tester) async {
      final backend = FakeBackend()
        ..signedIn = false
        ..signUpSignsIn = false
        ..newsletterAvailable = true;
      await openSignUp(tester, backend);
      await tester.tap(find.byKey(const Key('toggleMode')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('email')), 'ana@example.com');
      await tester.enterText(find.byKey(const Key('password')), 'secret-pw');
      await tester.tap(find.byKey(const Key('submit')));
      await tester.pumpAndSettle();
      expect(await NewsletterSignUpChoice.read(), isFalse);
    });

    testWidgets('no box where the server does not send it', (tester) async {
      await openSignUp(tester, FakeBackend()..signedIn = false);
      await tester.tap(find.byKey(const Key('toggleMode')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('newsletterSignUpBox')), findsNothing);
    });
  });
}
