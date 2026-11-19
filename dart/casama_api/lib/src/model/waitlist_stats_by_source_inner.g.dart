// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'waitlist_stats_by_source_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$WaitlistStatsBySourceInnerCWProxy {
  WaitlistStatsBySourceInner key(String key);

  WaitlistStatsBySourceInner listed(int listed);

  WaitlistStatsBySourceInner admitted(int admitted);

  WaitlistStatsBySourceInner joined(int joined);

  WaitlistStatsBySourceInner firstChat(int firstChat);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WaitlistStatsBySourceInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WaitlistStatsBySourceInner(...).copyWith(id: 12, name: "My name")
  /// ```
  WaitlistStatsBySourceInner call({
    String key,
    int listed,
    int admitted,
    int joined,
    int firstChat,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfWaitlistStatsBySourceInner.copyWith(...)` or call `instanceOfWaitlistStatsBySourceInner.copyWith.fieldName(value)` for a single field.
class _$WaitlistStatsBySourceInnerCWProxyImpl
    implements _$WaitlistStatsBySourceInnerCWProxy {
  const _$WaitlistStatsBySourceInnerCWProxyImpl(this._value);

  final WaitlistStatsBySourceInner _value;

  @override
  WaitlistStatsBySourceInner key(String key) => call(key: key);

  @override
  WaitlistStatsBySourceInner listed(int listed) => call(listed: listed);

  @override
  WaitlistStatsBySourceInner admitted(int admitted) => call(admitted: admitted);

  @override
  WaitlistStatsBySourceInner joined(int joined) => call(joined: joined);

  @override
  WaitlistStatsBySourceInner firstChat(int firstChat) =>
      call(firstChat: firstChat);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WaitlistStatsBySourceInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WaitlistStatsBySourceInner(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  WaitlistStatsBySourceInner call({
    Object? key = const $CopyWithPlaceholder(),
    Object? listed = const $CopyWithPlaceholder(),
    Object? admitted = const $CopyWithPlaceholder(),
    Object? joined = const $CopyWithPlaceholder(),
    Object? firstChat = const $CopyWithPlaceholder(),
  }) {
    return WaitlistStatsBySourceInner(
      key: key == const $CopyWithPlaceholder() || key == null
          ? _value.key
          // ignore: cast_nullable_to_non_nullable
          : key as String,
      listed: listed == const $CopyWithPlaceholder() || listed == null
          ? _value.listed
          // ignore: cast_nullable_to_non_nullable
          : listed as int,
      admitted: admitted == const $CopyWithPlaceholder() || admitted == null
          ? _value.admitted
          // ignore: cast_nullable_to_non_nullable
          : admitted as int,
      joined: joined == const $CopyWithPlaceholder() || joined == null
          ? _value.joined
          // ignore: cast_nullable_to_non_nullable
          : joined as int,
      firstChat: firstChat == const $CopyWithPlaceholder() || firstChat == null
          ? _value.firstChat
          // ignore: cast_nullable_to_non_nullable
          : firstChat as int,
    );
  }
}

extension $WaitlistStatsBySourceInnerCopyWith on WaitlistStatsBySourceInner {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfWaitlistStatsBySourceInner.copyWith(...)` or `instanceOfWaitlistStatsBySourceInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$WaitlistStatsBySourceInnerCWProxy get copyWith =>
      _$WaitlistStatsBySourceInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WaitlistStatsBySourceInner _$WaitlistStatsBySourceInnerFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('WaitlistStatsBySourceInner', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const ['key', 'listed', 'admitted', 'joined', 'first_chat'],
  );
  final val = WaitlistStatsBySourceInner(
    key: $checkedConvert('key', (v) => v as String),
    listed: $checkedConvert('listed', (v) => (v as num).toInt()),
    admitted: $checkedConvert('admitted', (v) => (v as num).toInt()),
    joined: $checkedConvert('joined', (v) => (v as num).toInt()),
    firstChat: $checkedConvert('first_chat', (v) => (v as num).toInt()),
  );
  return val;
}, fieldKeyMap: const {'firstChat': 'first_chat'});

Map<String, dynamic> _$WaitlistStatsBySourceInnerToJson(
  WaitlistStatsBySourceInner instance,
) => <String, dynamic>{
  'key': instance.key,
  'listed': instance.listed,
  'admitted': instance.admitted,
  'joined': instance.joined,
  'first_chat': instance.firstChat,
};
