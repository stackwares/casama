import 'dart:async';
import 'dart:convert';

import 'package:casama/core/providers.dart';
import 'package:casama/features/app_browser/app_browser_channel.dart';
import 'package:casama/features/app_browser/app_browser_controller.dart';
import 'package:casama/features/app_browser/app_browser_sites.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_browser_fakes.dart';
import 'fake_backend.dart';

/// The phone browser's session (PROTOCOL.md §1): every action, the chat-on-screen rule, the site
/// asks, taking over and handing back.
void main() {
  late FakeAppBrowserChannel channel;
  late FakeBackend backend;
  late ProviderContainer container;
  String? focus;

  AppBrowserController controller() =>
      container.read(appBrowserProvider.notifier);
  AppBrowserSession session() => container.read(appBrowserProvider);

  setUp(() async {
    channel = FakeAppBrowserChannel();
    backend = FakeBackend();
    focus = 'conv1';
    container = ProviderContainer(
      overrides: [
        backendProvider.overrideWithValue(backend),
        ...appBrowserOverrides(channel: channel, focus: () => focus),
      ],
    );
    container.read(appBrowserProvider);
    // A paired phone with nothing on its lists yet.
    await backend.pairAppBrowser(
      orgId,
      name: 'iPhone',
      system: 'ios',
      clientId: 'client-1',
    );
    controller().device = backend.appBrowserDevice;
  });

  tearDown(() => container.dispose());

  /// Waits until an ask is on screen.
  Future<AppBrowserAsk> asked() async {
    for (var i = 0; i < 100 && session().ask == null; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    return session().ask!;
  }

  group('actions', () {
    test(
      'open runs the gate, loads the page and waits for it to settle',
      () async {
        final r = await controller().handle(
          browserCall('open', args: {'url': 'https://shop.example/basket'}),
        );
        expect(r, {
          'ok': true,
          'text': 'Opened Shop',
          'url': 'https://shop.example/basket',
        });
        expect(channel.calls, contains('load https://shop.example/basket'));
        expect(session().phase, AppBrowserPhase.working);
        expect(session().run?.botName, 'Ada');
        expect(session().host, 'shop.example');
      },
    );

    test('snapshot, read, extract, scroll and wait go to the page script as they are', () async {
      for (final a in ['snapshot', 'read', 'extract', 'scroll', 'wait']) {
        final r = await controller().handle(
          browserCall(a, args: {'max_lines': 10}),
        );
        expect(r['ok'], isTrue);
        expect(r['text'], '$a done');
        expect(r['url'], 'https://shop.example/');
        expect(channel.commands.last['cmd'], a);
        expect(channel.commands.last['args'], {'max_lines': 10});
      }
    });

    test('a page script error keeps its code', () async {
      channel.answer = (c) => {
        'id': c['id'],
        'ok': false,
        'code': 'stale_ref',
        'message': 'That ref is old',
      };
      final r = await controller().handle(
        browserCall('click', args: {'ref': 'e3'}, expect: 'fp1'),
      );
      expect(r, {
        'ok': false,
        'code': 'stale_ref',
        'message': 'That ref is old',
      });
    });

    test('click on iPhone: the page script sends the events itself', () async {
      final r = await controller().handle(
        browserCall('click', args: {'ref': 'e2'}, expect: 'fp1'),
      );
      expect(r['ok'], isTrue);
      expect(channel.commands.single, {
        'id': channel.commands.single['id'],
        'cmd': 'click',
        'args': {'ref': 'e2', 'fingerprint': 'fp1', 'synthetic': true},
      });
      expect(channel.taps, isEmpty);
    });

    test(
      'click on Android: locate, a real tap, then click without its own events',
      () async {
        channel.support = const AppBrowserSupport(
          supported: true,
          realTaps: true,
        );
        channel.answer = (c) => c['cmd'] == 'locate'
            ? {
                'id': c['id'],
                'ok': true,
                'x': 120,
                'y': 340.5,
                'fingerprint': 'fp1',
              }
            : {'id': c['id'], 'ok': true, 'text': 'Clicked'};
        final r = await controller().handle(
          browserCall('click', args: {'ref': 'e2'}, expect: 'fp1'),
        );
        expect(r['text'], 'Clicked');
        expect(
          [for (final c in channel.commands) c['cmd']],
          ['locate', 'click'],
        );
        expect(channel.commands.first['args'], {
          'ref': 'e2',
          'fingerprint': 'fp1',
        });
        expect(channel.commands.last['args'], {
          'ref': 'e2',
          'fingerprint': 'fp1',
          'synthetic': false,
        });
        expect(channel.taps, [(120.0, 340.5)]);
        // Native's own tap isn't the person taking over.
        channel.handler!.userTouched();
        expect(session().phase, AppBrowserPhase.working);
      },
    );

    test('fill, type and press carry the fingerprint', () async {
      await controller().handle(
        browserCall('fill', args: {'ref': 'e1', 'text': 'hi'}, expect: 'fp9'),
      );
      expect(channel.commands.last['args'], {
        'ref': 'e1',
        'text': 'hi',
        'fingerprint': 'fp9',
      });
      await controller().handle(browserCall('press', args: {'key': 'Enter'}));
      expect(channel.commands.last['args'], {'key': 'Enter'});
    });

    test('probe answers the facts and fingerprint as JSON', () async {
      channel.answer = (c) => {
        'id': c['id'],
        'ok': true,
        'facts': {'role': 'button', 'name': 'Pay'},
        'fingerprint': 'abc',
      };
      final r = await controller().handle(
        browserCall('probe', args: {'focused': true}),
      );
      expect(jsonDecode(r['text'] as String), {
        'facts': {'role': 'button', 'name': 'Pay'},
        'fingerprint': 'abc',
      });
      expect(channel.commands.last['args'], {'focused': true});
    });

    test('url, tabs and screenshot come from native', () async {
      channel.page = const AppBrowserPage(
        url: 'https://shop.example/x',
        title: 'Basket',
      );
      expect(await controller().handle(browserCall('url')), {
        'ok': true,
        'text': 'https://shop.example/x',
        'url': 'https://shop.example/x',
      });
      expect(
        (await controller().handle(browserCall('tabs')))['text'],
        '1: Basket https://shop.example/x (current)',
      );
      final shot = await controller().handle(browserCall('screenshot'));
      expect(shot, {
        'ok': true,
        'text': '',
        'image': {'data': pixelPng, 'media_type': 'image/jpeg'},
      });
    });

    test('upload passes the file to the page script', () async {
      await controller().handle(
        browserCall(
          'upload',
          args: {
            'ref': 'e4',
            'file': {
              'name': 'a.pdf',
              'media_type': 'application/pdf',
              'data': 'AAA=',
            },
          },
        ),
      );
      expect(channel.commands.last['args'], {
        'ref': 'e4',
        'name': 'a.pdf',
        'media_type': 'application/pdf',
        'data': 'AAA=',
      });
    });

    test(
      "console, network, page_text and anything unknown are unsupported",
      () async {
        for (final a in ['console', 'network', 'page_text', 'teleport']) {
          expect(
            (await controller().handle(browserCall(a)))['code'],
            'unsupported',
          );
        }
      },
    );

    test('stop hides the working state and keeps the page', () async {
      await controller().handle(
        browserCall('open', args: {'url': 'https://shop.example/'}),
      );
      expect(await controller().handle(browserCall('stop')), {
        'ok': true,
        'text': 'Done',
      });
      expect(session().phase, AppBrowserPhase.idle);
      expect(session().run, isNull);
      expect(session().url, 'https://shop.example/');
    });

    test(
      'a page dialog is answered by the bot, or dismissed after a while',
      () async {
        channel.handler!.dialog('confirm', 'Leave the page?');
        expect(
          await controller().handle(
            browserCall('dialog', args: {'accept': true}),
          ),
          {'ok': true, 'text': 'Answered the confirm "Leave the page?".'},
        );
        expect(channel.dialogAnswers, [(true, null)]);
        expect(
          (await controller().handle(
            browserCall('dialog', args: {'accept': true}),
          ))['ok'],
          isFalse,
        );
        channel.handler!.dialog('alert', 'Hi');
        await Future<void>.delayed(const Duration(milliseconds: 150));
        expect(channel.dialogAnswers.last, (false, null));
      },
    );
  });

  group('asks', () {
    test('a step ask waits for the person', () async {
      final pending = controller().handle(
        browserCall(
          'ask',
          args: {
            'reason': 'This sends the message',
            'step': 'click',
            'name': 'Send',
          },
        ),
      );
      final ask = await asked();
      expect(ask.kind, AppBrowserAskKind.step);
      expect(ask.botName, 'Ada');
      expect(ask.reason, 'This sends the message');
      expect(session().phase, AppBrowserPhase.asking);
      controller().answerStep(true);
      expect(await pending, {'ok': true, 'text': 'allow'});
      expect(session().phase, AppBrowserPhase.working);
      expect(session().ask, isNull);
    });

    test("a step ask nobody answers times out", () async {
      expect(
        (await controller().handle(
          browserCall('ask', args: {'reason': 'x'}),
        ))['text'],
        'timeout',
      );
    });

    test('Don\'t Allow says deny', () async {
      final pending = controller().handle(browserCall('ask'));
      await asked();
      controller().answerStep(false);
      expect((await pending)['text'], 'deny');
    });
  });

  group('the site gate', () {
    const empty = AppSitePolicy();

    test(
      'a new site asks; Always opens it and saves it on the device',
      () async {
        final pending = controller().handle(
          browserCall(
            'open',
            args: {'url': 'https://news.example/'},
            policy: empty,
          ),
        );
        final ask = await asked();
        expect(ask.kind, AppBrowserAskKind.site);
        expect(ask.host, 'news.example');
        controller().answerSite(AppBrowserSiteAnswer.always);
        final r = await pending;
        expect(r['ok'], isTrue);
        await Future<void>.delayed(Duration.zero);
        expect(backend.appBrowserUpdates.last, 'allowed:news.example blocked:');
        expect(backend.appBrowserDevice!.allowedSites, ['news.example']);
      },
    );

    test('Once opens it for this run only, and saves nothing', () async {
      final pending = controller().handle(
        browserCall(
          'open',
          args: {'url': 'https://news.example/'},
          policy: empty,
        ),
      );
      await asked();
      controller().answerSite(AppBrowserSiteAnswer.once);
      expect((await pending)['ok'], isTrue);
      expect(backend.appBrowserUpdates, isEmpty);
      // The same run doesn't ask again.
      expect(
        (await controller().handle(
          browserCall(
            'open',
            args: {'url': 'https://news.example/2'},
            policy: empty,
          ),
        ))['ok'],
        isTrue,
      );
      // The next run does.
      final next = controller().handle(
        browserCall(
          'open',
          args: {'url': 'https://news.example/'},
          policy: empty,
          run: 'run2',
        ),
      );
      await asked();
      controller().answerSite(AppBrowserSiteAnswer.never);
      expect((await next)['code'], 'asked_denied');
    });

    test('Never refuses and saves it on the never list', () async {
      final pending = controller().handle(
        browserCall(
          'open',
          args: {'url': 'https://news.example/'},
          policy: empty,
        ),
      );
      await asked();
      controller().answerSite(AppBrowserSiteAnswer.never);
      expect((await pending)['code'], 'asked_denied');
      expect(channel.calls.where((c) => c.startsWith('load')), isEmpty);
      await Future<void>.delayed(Duration.zero);
      expect(backend.appBrowserDevice!.blockedSites, ['news.example']);
    });

    test("no answer in time is no", () async {
      expect(
        (await controller().handle(
          browserCall(
            'open',
            args: {'url': 'https://news.example/'},
            policy: empty,
          ),
        ))['code'],
        'asked_denied',
      );
    });

    test("Casama's own pages, blocked sites and off kinds are refused without asking", () async {
      for (final url in [
        'https://app.casama.ai/',
        'https://www.paypal.com/',
        'file:///etc/passwd',
      ]) {
        expect(
          (await controller().handle(
            browserCall('open', args: {'url': url}, policy: empty),
          ))['code'],
          'refused',
        );
      }
      final blocked = await controller().handle(
        browserCall(
          'open',
          args: {'url': 'https://ads.example/'},
          policy: const AppSitePolicy(blockedSites: ['ads.example']),
        ),
      );
      expect(blocked['code'], 'refused');
      expect(session().ask, isNull);
    });

    test('a redirect to a refused site is stopped where it lands', () async {
      channel.autoFinish = false;
      final pending = controller().handle(
        browserCall('open', args: {'url': 'https://shop.example/go'}),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(await channel.handler!.landed('https://casama.ai/'), isFalse);
      expect((await pending)['code'], 'refused');
    });

    test('a download runs the gate on its address', () async {
      channel.answer = (c) => {
        'id': c['id'],
        'ok': true,
        'file': {'name': 'a.csv', 'media_type': 'text/csv', 'data': 'YQ=='},
      };
      final r = await controller().handle(
        browserCall('download', args: {'url': 'https://shop.example/a.csv'}),
      );
      expect(r['file'], {
        'name': 'a.csv',
        'media_type': 'text/csv',
        'data': 'YQ==',
      });
      expect(
        (await controller().handle(
          browserCall('download', args: {'url': 'https://casama.ai/x'}),
        ))['code'],
        'refused',
      );
    });
  });

  group('the chat on screen', () {
    test('a call whose chat is not on screen is away', () async {
      focus = 'other';
      final r = await controller().handle(browserCall('snapshot'));
      expect(r['code'], 'away');
      expect(channel.commands, isEmpty);
    });

    test(
      'leaving the chat mid-ask answers away and shows the run as away',
      () async {
        final pending = controller().handle(browserCall('ask'));
        await asked();
        controller().leftChat('conv1');
        expect((await pending)['text'], 'deny');
        expect(session().phase, AppBrowserPhase.away);
      },
    );

    test('a call for another run ends the earlier run\'s ask', () async {
      final first = controller().handle(browserCall('ask'));
      await asked();
      final second = await controller().handle(
        browserCall('snapshot', run: 'run2'),
      );
      expect(second['ok'], isTrue);
      expect((await first)['text'], 'deny');
      expect(session().run?.id, 'run2');
    });
  });

  group('taking over', () {
    test('touching the page pauses the bot until Hand Back', () async {
      await controller().handle(
        browserCall('open', args: {'url': 'https://shop.example/'}),
      );
      channel.handler!.userTouched();
      expect(session().phase, AppBrowserPhase.tookOver);
      var done = false;
      final pending = controller().handle(browserCall('snapshot')).then((r) {
        done = true;
        return r;
      });
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(done, isFalse);
      controller().handBack();
      expect((await pending)['ok'], isTrue);
      expect(session().phase, AppBrowserPhase.working);
    });

    test('no Hand Back in time is away', () async {
      await controller().handle(browserCall('snapshot'));
      controller().takeOver();
      expect(
        (await controller().handle(browserCall('snapshot')))['code'],
        'away',
      );
    });

    test('a handoff shows Your turn at once; Hand Back carries on', () async {
      expect(
        await controller().handle(
          browserCall('handoff', args: {'reason': 'Type your card number'}),
        ),
        {'ok': true, 'text': 'shown'},
      );
      expect(session().phase, AppBrowserPhase.yourTurn);
      expect(session().handoffReason, 'Type your card number');
      final pending = controller().handle(browserCall('snapshot'));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      controller().handBack();
      expect((await pending)['ok'], isTrue);
    });

    test('Stop ends the run\'s use of the phone', () async {
      await controller().handle(browserCall('snapshot'));
      controller().stopBot();
      expect(session().run, isNull);
      expect(channel.calls, contains('stop'));
      expect(
        (await controller().handle(browserCall('snapshot')))['code'],
        'away',
      );
      // Another run may use it again.
      expect(
        (await controller().handle(browserCall('snapshot', run: 'run2')))['ok'],
        isTrue,
      );
    });

    test('a cancelled call stops waiting', () async {
      final call = browserCall('ask');
      final pending = controller().handle(call);
      await asked();
      call.cancel();
      expect((await pending)['text'], 'deny');
      expect(session().ask, isNull);
    });
  });

  test(
    'the person browsing by hand is held only to the first two steps',
    () async {
      await controller().openForPerson();
      expect(
        await channel.handler!.navigate(
          'https://www.paypal.com/',
          redirect: false,
          user: true,
        ),
        isTrue,
      );
      expect(
        await channel.handler!.navigate(
          'https://app.casama.ai/',
          redirect: false,
          user: true,
        ),
        isFalse,
      );
      expect(await controller().loadForPerson('example.org'), isTrue);
      expect(channel.calls, contains('load https://example.org'));
      await Future<void>.delayed(Duration.zero);
      expect(await controller().allowCurrentSite(), 'example.org');
      expect(backend.appBrowserDevice!.allowedSites, contains('example.org'));
      unawaited(controller().clearData());
      expect(channel.cleared, [null]);
    },
  );
}
