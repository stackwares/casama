// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_fact.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UserFactCWProxy {
  UserFact id(String id);

  UserFact kind(UserFactKindEnum kind);

  UserFact content(String content);

  UserFact pinned(bool pinned);

  UserFact updatedAt(DateTime updatedAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UserFact(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UserFact(...).copyWith(id: 12, name: "My name")
  /// ```
  UserFact call({
    String id,
    UserFactKindEnum kind,
    String content,
    bool pinned,
    DateTime updatedAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfUserFact.copyWith(...)` or call `instanceOfUserFact.copyWith.fieldName(value)` for a single field.
class _$UserFactCWProxyImpl implements _$UserFactCWProxy {
  const _$UserFactCWProxyImpl(this._value);

  final UserFact _value;

  @override
  UserFact id(String id) => call(id: id);

  @override
  UserFact kind(UserFactKindEnum kind) => call(kind: kind);

  @override
  UserFact content(String content) => call(content: content);

  @override
  UserFact pinned(bool pinned) => call(pinned: pinned);

  @override
  UserFact updatedAt(DateTime updatedAt) => call(updatedAt: updatedAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UserFact(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UserFact(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  UserFact call({
    Object? id = const $CopyWithPlaceholder(),
    Object? kind = const $CopyWithPlaceholder(),
    Object? content = const $CopyWithPlaceholder(),
    Object? pinned = const $CopyWithPlaceholder(),
    Object? updatedAt = const $CopyWithPlaceholder(),
  }) {
    return UserFact(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      kind: kind == const $CopyWithPlaceholder() || kind == null
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as UserFactKindEnum,
      content: content == const $CopyWithPlaceholder() || content == null
          ? _value.content
          // ignore: cast_nullable_to_non_nullable
          : content as String,
      pinned: pinned == const $CopyWithPlaceholder() || pinned == null
          ? _value.pinned
          // ignore: cast_nullable_to_non_nullable
          : pinned as bool,
      updatedAt: updatedAt == const $CopyWithPlaceholder() || updatedAt == null
          ? _value.updatedAt
          // ignore: cast_nullable_to_non_nullable
          : updatedAt as DateTime,
    );
  }
}

extension $UserFactCopyWith on UserFact {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfUserFact.copyWith(...)` or `instanceOfUserFact.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$UserFactCWProxy get copyWith => _$UserFactCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserFact _$UserFactFromJson(Map<String, dynamic> json) =>
    $checkedCreate('UserFact', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['id', 'kind', 'content', 'pinned', 'updated_at'],
      );
      final val = UserFact(
        id: $checkedConvert('id', (v) => v as String),
        kind: $checkedConvert(
          'kind',
          (v) => $enumDecode(_$UserFactKindEnumEnumMap, v),
        ),
        content: $checkedConvert('content', (v) => v as String),
        pinned: $checkedConvert('pinned', (v) => v as bool),
        updatedAt: $checkedConvert(
          'updated_at',
          (v) => DateTime.parse(v as String),
        ),
      );
      return val;
    }, fieldKeyMap: const {'updatedAt': 'updated_at'});

Map<String, dynamic> _$UserFactToJson(UserFact instance) => <String, dynamic>{
  'id': instance.id,
  'kind': _$UserFactKindEnumEnumMap[instance.kind]!,
  'content': instance.content,
  'pinned': instance.pinned,
  'updated_at': instance.updatedAt.toIso8601String(),
};

const _$UserFactKindEnumEnumMap = {
  UserFactKindEnum.fact: 'fact',
  UserFactKindEnum.preference: 'preference',
};
