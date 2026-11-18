// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'blocked_person.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BlockedPersonCWProxy {
  BlockedPerson userId(String userId);

  BlockedPerson name(String name);

  BlockedPerson blockedAt(DateTime blockedAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BlockedPerson(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BlockedPerson(...).copyWith(id: 12, name: "My name")
  /// ```
  BlockedPerson call({String userId, String name, DateTime blockedAt});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfBlockedPerson.copyWith(...)` or call `instanceOfBlockedPerson.copyWith.fieldName(value)` for a single field.
class _$BlockedPersonCWProxyImpl implements _$BlockedPersonCWProxy {
  const _$BlockedPersonCWProxyImpl(this._value);

  final BlockedPerson _value;

  @override
  BlockedPerson userId(String userId) => call(userId: userId);

  @override
  BlockedPerson name(String name) => call(name: name);

  @override
  BlockedPerson blockedAt(DateTime blockedAt) => call(blockedAt: blockedAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BlockedPerson(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BlockedPerson(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  BlockedPerson call({
    Object? userId = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? blockedAt = const $CopyWithPlaceholder(),
  }) {
    return BlockedPerson(
      userId: userId == const $CopyWithPlaceholder() || userId == null
          ? _value.userId
          // ignore: cast_nullable_to_non_nullable
          : userId as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      blockedAt: blockedAt == const $CopyWithPlaceholder() || blockedAt == null
          ? _value.blockedAt
          // ignore: cast_nullable_to_non_nullable
          : blockedAt as DateTime,
    );
  }
}

extension $BlockedPersonCopyWith on BlockedPerson {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfBlockedPerson.copyWith(...)` or `instanceOfBlockedPerson.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$BlockedPersonCWProxy get copyWith => _$BlockedPersonCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BlockedPerson _$BlockedPersonFromJson(Map<String, dynamic> json) =>
    $checkedCreate('BlockedPerson', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['user_id', 'name', 'blocked_at']);
      final val = BlockedPerson(
        userId: $checkedConvert('user_id', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        blockedAt: $checkedConvert(
          'blocked_at',
          (v) => DateTime.parse(v as String),
        ),
      );
      return val;
    }, fieldKeyMap: const {'userId': 'user_id', 'blockedAt': 'blocked_at'});

Map<String, dynamic> _$BlockedPersonToJson(BlockedPerson instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'name': instance.name,
      'blocked_at': instance.blockedAt.toIso8601String(),
    };
