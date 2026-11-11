// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_fact_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UserFactListCWProxy {
  UserFactList items(List<UserFact> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UserFactList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UserFactList(...).copyWith(id: 12, name: "My name")
  /// ```
  UserFactList call({List<UserFact> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfUserFactList.copyWith(...)` or call `instanceOfUserFactList.copyWith.fieldName(value)` for a single field.
class _$UserFactListCWProxyImpl implements _$UserFactListCWProxy {
  const _$UserFactListCWProxyImpl(this._value);

  final UserFactList _value;

  @override
  UserFactList items(List<UserFact> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UserFactList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UserFactList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  UserFactList call({Object? items = const $CopyWithPlaceholder()}) {
    return UserFactList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<UserFact>,
    );
  }
}

extension $UserFactListCopyWith on UserFactList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfUserFactList.copyWith(...)` or `instanceOfUserFactList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$UserFactListCWProxy get copyWith => _$UserFactListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserFactList _$UserFactListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('UserFactList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = UserFactList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => UserFact.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$UserFactListToJson(UserFactList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
