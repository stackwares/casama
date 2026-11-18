// The terminal reopens by itself when the server closes it for a restart (close code 1012), and
// any other close or a socket error shows Connect again.
import 'dart:async';

import 'package:casama/features/computer/computer_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:xterm/xterm.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

class _FakeSink implements WebSocketSink {
  @override
  void add(dynamic data) {}
  @override
  Future<void> close([int? closeCode, String? closeReason]) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeChannel implements WebSocketChannel {
  _FakeChannel({this.opens = true});
  final bool opens;
  final incoming = StreamController<dynamic>();
  @override
  final _FakeSink sink = _FakeSink();
  @override
  int? closeCode;
  @override
  Stream<dynamic> get stream => incoming.stream;
  @override
  Future<void> get ready =>
      opens ? Future.value() : Future.error(Exception('refused'));

  Future<void> serverClose(int code) async {
    closeCode = code;
    await incoming.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final realConnect = connectTerminalSocket;
  final realDelays = terminalReconnectDelays;
  late List<_FakeChannel> channels;
  late List<bool> opens;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    channels = [];
    opens = [];
    connectTerminalSocket = (_) {
      final c = _FakeChannel(opens: opens.isEmpty ? true : opens.removeAt(0));
      channels.add(c);
      return c;
    };
    terminalReconnectDelays = const [
      Duration(seconds: 1),
      Duration(seconds: 2),
    ];
  });
  tearDown(() {
    connectTerminalSocket = realConnect;
    terminalReconnectDelays = realDelays;
  });

  String screenText(WidgetTester tester) => tester
      .widget<TerminalView>(find.byType(TerminalView))
      .terminal
      .buffer
      .getText();

  Future<void> openTerminal(WidgetTester tester) async {
    await setSize(tester, const Size(800, 1000));
    await tester.pumpWidget(
      harness(
        FakeBackend(),
        const Scaffold(body: ComputerScreen(embedded: true)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Terminal'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(TerminalTab),
        matching: find.text('Connect'),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byType(TerminalView), findsOneWidget);
  }

  testWidgets('a server restart (1012) reconnects by itself', (tester) async {
    await openTerminal(tester);
    // The first try fails (the server is still down), the second opens.
    opens.addAll([false, true]);
    await tester.runAsync(() => channels.single.serverClose(1012));
    await tester.pump();
    expect(screenText(tester), contains('Server restarting, reconnecting…'));
    expect(find.byType(TerminalView), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(channels, hasLength(3));
    expect(find.byType(TerminalView), findsOneWidget);
    expect(screenText(tester), isNot(contains('Disconnected.')));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('after the tries run out it shows Connect again', (tester) async {
    await openTerminal(tester);
    opens.addAll([false, false]);
    await tester.runAsync(() => channels.single.serverClose(1012));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(channels, hasLength(3));
    expect(find.byType(TerminalView), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('any other close shows Connect again at once', (tester) async {
    await openTerminal(tester);
    await tester.runAsync(() => channels.single.serverClose(1000));
    await tester.pump();
    expect(find.byType(TerminalView), findsNothing);
    expect(channels, hasLength(1));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a socket error shows Connect again', (tester) async {
    await openTerminal(tester);
    await tester.runAsync(() async {
      channels.single.incoming.addError(Exception('reset'));
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump();
    expect(find.byType(TerminalView), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
