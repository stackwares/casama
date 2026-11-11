# Fix: Phone numbers show and type as one long run of digits

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/format-phone-numbers
- **Needs new dependency**: `phone_numbers_parser: ^9.0.29` (MIT, pure Dart, works on every
  platform including web). Every phone number in Casama is international (`+14155550123`, any
  country, no country picker: the help text says "International format, like +14155550123"), so
  one fixed mask can't fit them. The article's answer for numbers from many countries is
  `phone_numbers_parser`, which knows every country's grouping.

## Why

The number a bot is calling, the workspace's Twilio number and the numbers people type to take
over a call or connect SMS all appear as `+14155550123`: a run of digits that is hard to read
back and easy to mistype. Grouped (`+1 415-555-0123`), people can check a number at a glance
and catch a wrong digit before a bot dials it.

## Where

```dart
// lib/features/calls/outbound_call_screen.dart:63 — current (take over a call: "Your phone number" field, no formatter)
        content: TextField(
          key: const Key('takeOverPhone'),
          controller: phone,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(labelText: l10n.outCallYourPhone, helperText: l10n.outCallYourPhoneHelp),
        ),
```

```dart
// lib/features/calls/outbound_call_screen.dart:71 — current (sends the typed text)
          FilledButton(key: const Key('confirmTakeOver'), onPressed: () => Navigator.pop(d, phone.text.trim()), child: Text(l10n.outCallTakeOver)),
```

```dart
// lib/features/calls/outbound_call_screen.dart:96 — current (page title is the raw number being called)
      title: c?.number ?? l10n.outCall,
```

```dart
// lib/features/workspaces/spaces.dart:718 — current (Phone calls row shows the raw Twilio number)
          subtitle: t.connected ? '${t.fromNumber} · ${l10n.phoneCallsCap}: ${t.dailyCap}' : '${l10n.phoneCallsOff} · ${l10n.phoneCallsHelp}',
```

```dart
// lib/features/workspaces/spaces.dart:744 — current (field starts with the raw number)
  late final _from = TextEditingController(text: widget.current.fromNumber ?? '');
```

```dart
// lib/features/workspaces/spaces.dart:757 — current (validation reads the typed text)
  bool get _valid =>
      RegExp(r'^AC[0-9a-fA-F]{32}$').hasMatch(_sid.text.trim()) && RegExp(r'^\+[1-9][0-9]{7,14}$').hasMatch(_from.text.trim()) && (widget.current.connected || _token.text.trim().length >= 16);
```

```dart
// lib/features/workspaces/spaces.dart:782 — current (sends the typed text)
                        fromNumber: _from.text.trim(),
```

```dart
// lib/features/workspaces/spaces.dart:807 — current (Twilio "from" number field, no formatter)
        TextField(
          key: const Key('twilioFrom'),
          controller: _from,
          keyboardType: TextInputType.phone,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(labelText: l10n.twilioFrom),
        ),
```

```dart
// lib/features/bots/channels_screen.dart:181 — current (SMS "Phone number" is sent as typed)
              config: {for (final f in fields.where((f) => !f.$2)) f.$1: _c(f.$1).text.trim(), if (_kind == ChannelKind.imessage) 'computer_id': _mac},
```

```dart
// lib/features/bots/channels_screen.dart:220 — current (setup fields; the SMS 'phone_number' field has no phone keyboard and no formatter)
        for (final f in _fields[_kind]!)
          Revealable(builder: (context, hidden, toggle) => TextField(
            key: Key('channelField-${f.$1}'),
            controller: _c(f.$1),
            obscureText: hidden && (f.$2),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(labelText: f.$3(l10n), suffixIcon: (f.$2) ? toggle : null),
          )),
```

```dart
// test/outbound_call_test.dart:58 — current (expects the raw number in the Phone calls row)
    expect(find.textContaining('+14155550000'), findsOneWidget);
```

## The fix

The article's fix for numbers from many countries: wrap `phone_numbers_parser` in a small
`TextInputFormatter` that drops everything but digits and formats them, plus a `String`
extension that formats numbers from the backend for display and strips the formatting before
sending. Here the country comes from the number itself (its `+` country code), so no ISO code is
passed in. Text that isn't an international number (no leading `+`, an unknown country code) is
left exactly as typed, so nothing is ever guessed.

New file `lib/core/phone_format.dart` (target, complete):

```dart
import 'package:flutter/services.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';

/// Phone numbers in Casama are international (E.164, like +14155550123): each starts with + and
/// its country code, so the country comes from the number itself.
extension PhoneNumberText on String {
  /// "+14155550123" → "+1 415-555-0123": the country code, then the number grouped the way that
  /// country writes it. Text that isn't an international number comes back as it is.
  String get formattedPhoneNumber {
    final String digits = replaceAll(RegExp(r'[^0-9]'), '');
    if (!trim().startsWith('+') || digits.isEmpty) return this;

    try {
      final PhoneNumber phone = PhoneNumber.parse('+$digits');
      final String national = phone.formatNsn(format: NsnFormat.international);

      return national.isEmpty ? '+${phone.countryCode}' : '+${phone.countryCode} $national';
    } catch (_) {
      // Not a known country code yet (still typing): keep the digits.
      return '+$digits';
    }
  }

  /// "+1 415-555-0123" → "+14155550123", for sending to the server.
  String get unformattedPhoneNumber {
    final String digits = replaceAll(RegExp(r'[^0-9]'), '');

    return trim().startsWith('+') ? '+$digits' : digits;
  }
}

/// Formats an international phone number while it's typed (see [PhoneNumberText]).
class PhoneInputFormatter extends TextInputFormatter {
  const PhoneInputFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final String text = newValue.text.formattedPhoneNumber;

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
```

Targets at each location (every other character of each line stays as it is):

```dart
// lib/features/calls/outbound_call_screen.dart:63 — target
        content: TextField(
          key: const Key('takeOverPhone'),
          controller: phone,
          keyboardType: TextInputType.phone,
          inputFormatters: const [PhoneInputFormatter()],
          decoration: InputDecoration(labelText: l10n.outCallYourPhone, helperText: l10n.outCallYourPhoneHelp),
        ),
```

```dart
// lib/features/calls/outbound_call_screen.dart:71 — target
          FilledButton(key: const Key('confirmTakeOver'), onPressed: () => Navigator.pop(d, phone.text.unformattedPhoneNumber), child: Text(l10n.outCallTakeOver)),
```

```dart
// lib/features/calls/outbound_call_screen.dart:96 — target
      title: c == null ? l10n.outCall : c.number.formattedPhoneNumber,
```

```dart
// lib/features/workspaces/spaces.dart:718 — target
          subtitle: t.connected ? '${(t.fromNumber ?? '').formattedPhoneNumber} · ${l10n.phoneCallsCap}: ${t.dailyCap}' : '${l10n.phoneCallsOff} · ${l10n.phoneCallsHelp}',
```

```dart
// lib/features/workspaces/spaces.dart:744 — target
  late final _from = TextEditingController(text: (widget.current.fromNumber ?? '').formattedPhoneNumber);
```

```dart
// lib/features/workspaces/spaces.dart:757 — target
  bool get _valid =>
      RegExp(r'^AC[0-9a-fA-F]{32}$').hasMatch(_sid.text.trim()) && RegExp(r'^\+[1-9][0-9]{7,14}$').hasMatch(_from.text.unformattedPhoneNumber) && (widget.current.connected || _token.text.trim().length >= 16);
```

```dart
// lib/features/workspaces/spaces.dart:782 — target
                        fromNumber: _from.text.unformattedPhoneNumber,
```

```dart
// lib/features/workspaces/spaces.dart:807 — target
        TextField(
          key: const Key('twilioFrom'),
          controller: _from,
          keyboardType: TextInputType.phone,
          inputFormatters: const [PhoneInputFormatter()],
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(labelText: l10n.twilioFrom),
        ),
```

```dart
// lib/features/bots/channels_screen.dart:181 — target
              config: {for (final f in fields.where((f) => !f.$2)) f.$1: f.$1 == 'phone_number' ? _c(f.$1).text.unformattedPhoneNumber : _c(f.$1).text.trim(), if (_kind == ChannelKind.imessage) 'computer_id': _mac},
```

```dart
// lib/features/bots/channels_screen.dart:220 — target
        for (final f in _fields[_kind]!)
          Revealable(builder: (context, hidden, toggle) => TextField(
            key: Key('channelField-${f.$1}'),
            controller: _c(f.$1),
            obscureText: hidden && (f.$2),
            keyboardType: f.$1 == 'phone_number' ? TextInputType.phone : null,
            inputFormatters: f.$1 == 'phone_number' ? const [PhoneInputFormatter()] : null,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(labelText: f.$3(l10n), suffixIcon: (f.$2) ? toggle : null),
          )),
```

```dart
// test/outbound_call_test.dart:58 — target (the row now shows the grouped number)
    expect(find.textContaining('+1 415-555-0000'), findsOneWidget);
```

## Steps

Line numbers are from when this plan was written. If a file has shifted since (for example
new imports were added at the top), find each line by its quoted text; only a change in the
quoted text itself is a reason to stop.

1. From `client/`, run `flutter pub add 'phone_numbers_parser:^9.0.29'`. It must add
   `phone_numbers_parser: ^9.0.29` under `dependencies:` in `pubspec.yaml` and update
   `pubspec.lock`. Don't touch any other dependency.
2. Create `lib/core/phone_format.dart` with exactly the content in "The fix", then run
   `dart format -l 200 lib/core/phone_format.dart` (the only source file you may format).
3. `lib/features/calls/outbound_call_screen.dart`:
   a. Add `import '../../core/phone_format.dart';` directly above the line
      `import '../../core/providers.dart';`.
   b. In the take-over `TextField` (line 63), insert the line
      `          inputFormatters: const [PhoneInputFormatter()],` directly below
      `          keyboardType: TextInputType.phone,`.
   c. On the `confirmTakeOver` line (line 71), replace `phone.text.trim()` with
      `phone.text.unformattedPhoneNumber`.
   d. Replace `      title: c?.number ?? l10n.outCall,` with
      `      title: c == null ? l10n.outCall : c.number.formattedPhoneNumber,`.
4. `lib/features/workspaces/spaces.dart`:
   a. Add `import '../../core/phone_format.dart';` directly above the line
      `import '../../core/providers.dart';`.
   b. Line 718: replace `'${t.fromNumber} · ` with `'${(t.fromNumber ?? '').formattedPhoneNumber} · `
      (nothing else on the line changes).
   c. Line 744: replace `TextEditingController(text: widget.current.fromNumber ?? '')` with
      `TextEditingController(text: (widget.current.fromNumber ?? '').formattedPhoneNumber)`.
   d. Line 758: replace `.hasMatch(_from.text.trim())` with
      `.hasMatch(_from.text.unformattedPhoneNumber)` (only the `_from` one; `_sid` and `_token`
      keep `.trim()`).
   e. Line 782: replace `fromNumber: _from.text.trim(),` with
      `fromNumber: _from.text.unformattedPhoneNumber,`.
   f. In the `twilioFrom` `TextField` (line 807), insert the line
      `          inputFormatters: const [PhoneInputFormatter()],` directly below
      `          keyboardType: TextInputType.phone,`.
5. `lib/features/bots/channels_screen.dart`:
   a. Add `import '../../core/phone_format.dart';` directly above the line
      `import '../../core/providers.dart';`.
   b. Line 181: replace `f.$1: _c(f.$1).text.trim(),` with
      `f.$1: f.$1 == 'phone_number' ? _c(f.$1).text.unformattedPhoneNumber : _c(f.$1).text.trim(),`
      (the `secrets:` line below it stays as it is).
   c. In the setup-field `TextField` (line 220), insert these two lines directly below
      `            obscureText: hidden && (f.$2),`:
      ```dart
                  keyboardType: f.$1 == 'phone_number' ? TextInputType.phone : null,
                  inputFormatters: f.$1 == 'phone_number' ? const [PhoneInputFormatter()] : null,
      ```
      Only the exact key `'phone_number'` (SMS). WhatsApp's `'phone_number_id'` is an id, not a
      phone number, and stays unformatted.
6. `test/outbound_call_test.dart` line 58: replace `find.textContaining('+14155550000')` with
   `find.textContaining('+1 415-555-0000')`. Leave lines 22, 25, 52 and 56 alone: the test still
   types the raw number and the server must still receive it raw, which proves the round trip.
7. Create `test/phone_format_test.dart` with this content, then run
   `dart format -l 200 test/phone_format_test.dart`:
   ```dart
   import 'package:flutter/services.dart';
   import 'package:flutter_test/flutter_test.dart';
   import 'package:casama_app/core/phone_format.dart';

   void main() {
     test('international numbers read in groups', () {
       expect('+14155550123'.formattedPhoneNumber, '+1 415-555-0123');
       expect('+1 (415) 555-0123'.formattedPhoneNumber, '+1 415-555-0123');
     });

     test('the number goes back to the server without the grouping', () {
       expect('+1 415-555-0123'.unformattedPhoneNumber, '+14155550123');
       expect('+14155550123'.formattedPhoneNumber.unformattedPhoneNumber, '+14155550123');
     });

     test('text that is not an international number is left as typed', () {
       expect(''.formattedPhoneNumber, '');
       expect('+'.formattedPhoneNumber, '+');
       expect('4155550123'.formattedPhoneNumber, '4155550123');
     });

     test('the field formats while typing and keeps the cursor at the end', () {
       const formatter = PhoneInputFormatter();
       final value = formatter.formatEditUpdate(TextEditingValue.empty, const TextEditingValue(text: '+14155550123'));
       expect(value.text, '+1 415-555-0123');
       expect(value.selection, const TextSelection.collapsed(offset: 15));
     });
   }
   ```
8. From `client/`, run
   `flutter test test/phone_format_test.dart test/outbound_call_test.dart test/channels_test.dart test/phone_layout_test.dart`.
   All must pass.

## Check it

- `dart analyze lib/core/phone_format.dart lib/features/calls/outbound_call_screen.dart lib/features/workspaces/spaces.dart lib/features/bots/channels_screen.dart test/phone_format_test.dart test/outbound_call_test.dart` reports no issues.
- `grep -cF "phone_numbers_parser: ^9.0.29" pubspec.yaml` → 1
- `grep -c "PhoneInputFormatter()" lib/features/calls/outbound_call_screen.dart` → 1
- `grep -cF ".formattedPhoneNumber" lib/features/calls/outbound_call_screen.dart` → 1
- `grep -cF ".unformattedPhoneNumber" lib/features/calls/outbound_call_screen.dart` → 1
- `grep -c "phone.text.trim()" lib/features/calls/outbound_call_screen.dart` → 0
- `grep -c "PhoneInputFormatter()" lib/features/workspaces/spaces.dart` → 1
- `grep -cF ".formattedPhoneNumber" lib/features/workspaces/spaces.dart` → 2
- `grep -cF "_from.text.unformattedPhoneNumber" lib/features/workspaces/spaces.dart` → 2
- `grep -c "_from.text.trim()" lib/features/workspaces/spaces.dart` → 0
- `grep -c "PhoneInputFormatter()" lib/features/bots/channels_screen.dart` → 1
- `grep -cF ".unformattedPhoneNumber" lib/features/bots/channels_screen.dart` → 1
- `grep -c "+1 415-555-0000" test/outbound_call_test.dart` → 1
- The `flutter test` run in step 8 passes.

## Don't touch

- `channels_screen.dart` event list (`e.sender`, around line 361): a sender is whatever the chat
  app reports (a name, a handle, an email or a number), so it's shown as sent.
- The allowed-senders fields (`channelSenders`, `editSenders`): free-form lists of senders of any
  kind, not phone fields.
- WhatsApp's `phone_number_id` field: an id from Meta, not a phone number.
- `lib/features/devices/device_collector.dart` contact phones: sent to the server, never shown.
- The `l10n.outCallYourPhoneHelp` and other ARB strings: they already describe the format.
- No country picker, no per-country masks, no `mask_text_input_formatter`.
- Never run `dart format` on existing files or directories (only on the two new files).
- No git commands (others commit in this shared tree).
- No new dependencies beyond the one in the header. No refactors, renames, or cleanups beyond the fix.

## STOP if

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on
  since this plan was written). One exception: if another change on the same line only changed
  text that this plan doesn't touch, apply this plan's replacement to the line as it is now.
- `flutter pub add` fails, resolves a version other than 9.x, or changes another package's version.
- `test/phone_format_test.dart`'s expected grouping differs from what the package returns (for
  example a different separator): report the actual output instead of changing the expectation.
- The fix seems to require touching something in "Don't touch".
- A check fails twice.

## When you're done

Tell the developer, in two or three sentences, what's different in the app now and one place to
open to see it. Not a list of files, the steps already have those. For example: phone numbers
now show and type in groups the way their country writes them (`+1 415-555-0123`) and still go
to the server as `+14155550123`; open a workspace's Phone calls row, or take over a bot's call,
to see it.
