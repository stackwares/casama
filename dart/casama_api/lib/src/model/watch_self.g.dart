// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watch_self.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$WatchSelfCWProxy {
  WatchSelf keyId(String keyId);

  WatchSelf orgId(String orgId);

  WatchSelf orgName(String orgName);

  WatchSelf person(WatchSelfPerson person);

  WatchSelf prefs(WatchPrefs prefs);

  WatchSelf hideReplyText(bool hideReplyText);

  WatchSelf askBotId(String? askBotId);

  WatchSelf features(WatchSelfFeatures features);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WatchSelf(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WatchSelf(...).copyWith(id: 12, name: "My name")
  /// ```
  WatchSelf call({
    String keyId,
    String orgId,
    String orgName,
    WatchSelfPerson person,
    WatchPrefs prefs,
    bool hideReplyText,
    String? askBotId,
    WatchSelfFeatures features,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfWatchSelf.copyWith(...)` or call `instanceOfWatchSelf.copyWith.fieldName(value)` for a single field.
class _$WatchSelfCWProxyImpl implements _$WatchSelfCWProxy {
  const _$WatchSelfCWProxyImpl(this._value);

  final WatchSelf _value;

  @override
  WatchSelf keyId(String keyId) => call(keyId: keyId);

  @override
  WatchSelf orgId(String orgId) => call(orgId: orgId);

  @override
  WatchSelf orgName(String orgName) => call(orgName: orgName);

  @override
  WatchSelf person(WatchSelfPerson person) => call(person: person);

  @override
  WatchSelf prefs(WatchPrefs prefs) => call(prefs: prefs);

  @override
  WatchSelf hideReplyText(bool hideReplyText) =>
      call(hideReplyText: hideReplyText);

  @override
  WatchSelf askBotId(String? askBotId) => call(askBotId: askBotId);

  @override
  WatchSelf features(WatchSelfFeatures features) => call(features: features);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WatchSelf(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WatchSelf(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  WatchSelf call({
    Object? keyId = const $CopyWithPlaceholder(),
    Object? orgId = const $CopyWithPlaceholder(),
    Object? orgName = const $CopyWithPlaceholder(),
    Object? person = const $CopyWithPlaceholder(),
    Object? prefs = const $CopyWithPlaceholder(),
    Object? hideReplyText = const $CopyWithPlaceholder(),
    Object? askBotId = const $CopyWithPlaceholder(),
    Object? features = const $CopyWithPlaceholder(),
  }) {
    return WatchSelf(
      keyId: keyId == const $CopyWithPlaceholder() || keyId == null
          ? _value.keyId
          // ignore: cast_nullable_to_non_nullable
          : keyId as String,
      orgId: orgId == const $CopyWithPlaceholder() || orgId == null
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
      orgName: orgName == const $CopyWithPlaceholder() || orgName == null
          ? _value.orgName
          // ignore: cast_nullable_to_non_nullable
          : orgName as String,
      person: person == const $CopyWithPlaceholder() || person == null
          ? _value.person
          // ignore: cast_nullable_to_non_nullable
          : person as WatchSelfPerson,
      prefs: prefs == const $CopyWithPlaceholder() || prefs == null
          ? _value.prefs
          // ignore: cast_nullable_to_non_nullable
          : prefs as WatchPrefs,
      hideReplyText:
          hideReplyText == const $CopyWithPlaceholder() || hideReplyText == null
          ? _value.hideReplyText
          // ignore: cast_nullable_to_non_nullable
          : hideReplyText as bool,
      askBotId: askBotId == const $CopyWithPlaceholder()
          ? _value.askBotId
          // ignore: cast_nullable_to_non_nullable
          : askBotId as String?,
      features: features == const $CopyWithPlaceholder() || features == null
          ? _value.features
          // ignore: cast_nullable_to_non_nullable
          : features as WatchSelfFeatures,
    );
  }
}

extension $WatchSelfCopyWith on WatchSelf {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfWatchSelf.copyWith(...)` or `instanceOfWatchSelf.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$WatchSelfCWProxy get copyWith => _$WatchSelfCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WatchSelf _$WatchSelfFromJson(Map<String, dynamic> json) => $checkedCreate(
  'WatchSelf',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'key_id',
        'org_id',
        'org_name',
        'person',
        'prefs',
        'hide_reply_text',
        'ask_bot_id',
        'features',
      ],
    );
    final val = WatchSelf(
      keyId: $checkedConvert('key_id', (v) => v as String),
      orgId: $checkedConvert('org_id', (v) => v as String),
      orgName: $checkedConvert('org_name', (v) => v as String),
      person: $checkedConvert(
        'person',
        (v) => WatchSelfPerson.fromJson(v as Map<String, dynamic>),
      ),
      prefs: $checkedConvert(
        'prefs',
        (v) => WatchPrefs.fromJson(v as Map<String, dynamic>),
      ),
      hideReplyText: $checkedConvert('hide_reply_text', (v) => v as bool),
      askBotId: $checkedConvert('ask_bot_id', (v) => v as String?),
      features: $checkedConvert(
        'features',
        (v) => WatchSelfFeatures.fromJson(v as Map<String, dynamic>),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'keyId': 'key_id',
    'orgId': 'org_id',
    'orgName': 'org_name',
    'hideReplyText': 'hide_reply_text',
    'askBotId': 'ask_bot_id',
  },
);

Map<String, dynamic> _$WatchSelfToJson(WatchSelf instance) => <String, dynamic>{
  'key_id': instance.keyId,
  'org_id': instance.orgId,
  'org_name': instance.orgName,
  'person': instance.person.toJson(),
  'prefs': instance.prefs.toJson(),
  'hide_reply_text': instance.hideReplyText,
  'ask_bot_id': instance.askBotId,
  'features': instance.features.toJson(),
};
