// Fix 14: the web app keeps what the person was typing, and only that.
import 'package:casama_app/core/local_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('the web cache keeps a draft across reloads', () async {
    await cacheWrite(
      openLocalCache(web: true),
      'draft:bot:conv',
      'Call the bank',
    );
    // A reload opens a fresh cache over the same browser storage.
    expect(
      await cacheRead(openLocalCache(web: true), 'draft:bot:conv'),
      'Call the bank',
    );
  });

  test('the web cache keeps nothing but drafts', () async {
    final cache = openLocalCache(web: true);
    await cacheWrite(cache, 'messages:conv', ['hello']);
    expect(await cacheRead(cache, 'messages:conv'), isNull);
  });

  test('a cleared draft and signing out remove it', () async {
    final cache = openLocalCache(web: true);
    await cacheWrite(cache, 'draft:a:new', 'one');
    await cacheWrite(cache, 'draft:b:new', 'two');
    await cacheWrite(cache, 'draft:a:new', null);
    expect(await cacheRead(cache, 'draft:a:new'), isNull);
    await cacheClear(cache);
    expect(await cacheRead(cache, 'draft:b:new'), isNull);
  });
}
