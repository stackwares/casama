import 'dart:io';

import 'package:casama_app/core/google_sign_in.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';

void main() {
  test('the iOS SDK returns to the client id read backwards', () {
    expect(
      googleReversedClientId('123-abc.apps.googleusercontent.com'),
      'com.googleusercontent.apps.123-abc',
    );
  });

  test("Android asks for the server's web client; Windows, Linux and the web have no sheet", () {
    const ids = [
      'web.apps.googleusercontent.com',
      'ios.apps.googleusercontent.com',
    ];
    expect(
      googleNativeClient(TargetPlatform.android, ids, web: false),
      ids.first,
    );
    expect(
      googleNativeClient(TargetPlatform.android, const [], web: false),
      isNull,
    );
    expect(googleNativeClient(TargetPlatform.android, ids, web: true), isNull);
    expect(googleNativeClient(TargetPlatform.windows, ids, web: false), isNull);
    expect(googleNativeClient(TargetPlatform.linux, ids, web: false), isNull);
  });

  test(
    "iPhone and Mac use the app's iOS client, only when the server accepts it",
    () {
      const other = ['web.apps.googleusercontent.com'];
      expect(googleNativeClient(TargetPlatform.iOS, other, web: false), isNull);
      expect(
        googleNativeClient(TargetPlatform.macOS, other, web: false),
        isNull,
      );
      final listed = [...other, googleIosClientId];
      final expected = googleIosClientId.isEmpty ? null : googleIosClientId;
      expect(
        googleNativeClient(TargetPlatform.iOS, listed, web: false),
        expected,
      );
      expect(
        googleNativeClient(TargetPlatform.macOS, listed, web: false),
        expected,
      );
    },
  );

  test(
    'a failed Google sheet falls back to the browser; a cancel does not',
    () {
      expect(
        googleSheetUnavailable(
          const GoogleSignInException(code: GoogleSignInExceptionCode.canceled),
        ),
        isFalse,
      );
      for (final code in GoogleSignInExceptionCode.values.where(
        (c) => c != GoogleSignInExceptionCode.canceled,
      )) {
        expect(
          googleSheetUnavailable(GoogleSignInException(code: code)),
          isTrue,
          reason: code.name,
        );
      }
      expect(
        googleSheetUnavailable(PlatformException(code: 'keychain error')),
        isTrue,
      );
      expect(googleSheetUnavailable(MissingPluginException()), isTrue);
      expect(googleSheetUnavailable(StateError('other')), isFalse);
    },
  );

  // Google's iOS SDK stops the app when its URL scheme is missing, so the id and both Info.plist
  // files must change together.
  test('Info.plist registers exactly the iOS client the app signs in with', () {
    for (final path in ['ios/Runner/Info.plist', 'macos/Runner/Info.plist']) {
      final plist = File(path).readAsStringSync();
      final schemes = RegExp(r'com\.googleusercontent\.apps\.[\w-]+')
          .allMatches(plist)
          .map((m) => m[0])
          .toSet();
      expect(
        schemes,
        googleIosClientId.isEmpty
            ? isEmpty
            : {googleReversedClientId(googleIosClientId)},
        reason: path,
      );
    }
  });
}
