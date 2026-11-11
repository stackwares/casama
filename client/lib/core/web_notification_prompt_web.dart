import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// The permission prompt Chrome is already showing, started from the button click.
Future<String>? _pending;

/// Turns the platform view into the Turn on button.
///
/// Chrome shows the notification prompt only from the browser event the person
/// clicked. A Flutter button runs its callback after that event, so the prompt
/// never appears. This element is a real button: its click asks Chrome, then
/// tells the app to finish registering.
void bindNotificationButton(
  Object element, {
  required String label,
  required String background,
  required String foreground,
  required void Function() onPressed,
}) {
  final button = element as web.HTMLButtonElement;
  button.type = 'button';
  button.textContent = label;
  button.setAttribute('aria-label', label);
  button.style.cssText =
      'width:100%;height:100%;margin:0;padding:0;border:0;border-radius:999px;cursor:pointer;appearance:none;font:700 16px sans-serif;background:$background;color:$foreground;';
  button.addEventListener(
    'click',
    ((web.Event _) {
      _pending ??= _askNow();
      onPressed();
    }).toJS,
  );
}

/// The answer to the prompt this click started, or a new request if the click
/// did not start one.
Future<String> takeWebNotificationPermission() {
  final pending = _pending ?? _askNow();
  _pending = null;
  return pending;
}

Future<String> _askNow() {
  final current = web.Notification.permission;
  if (current != 'default') return Future<String>.value(current);
  return web.Notification.requestPermission().toDart.then(
    (status) => status.toDart,
  );
}
