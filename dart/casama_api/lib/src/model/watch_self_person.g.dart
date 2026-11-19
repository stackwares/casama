// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watch_self_person.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$WatchSelfPersonCWProxy {
  WatchSelfPerson name(String name);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WatchSelfPerson(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WatchSelfPerson(...).copyWith(id: 12, name: "My name")
  /// ```
  WatchSelfPerson call({String name});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfWatchSelfPerson.copyWith(...)` or call `instanceOfWatchSelfPerson.copyWith.fieldName(value)` for a single field.
class _$WatchSelfPersonCWProxyImpl implements _$WatchSelfPersonCWProxy {
  const _$WatchSelfPersonCWProxyImpl(this._value);

  final WatchSelfPerson _value;

  @override
  WatchSelfPerson name(String name) => call(name: name);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WatchSelfPerson(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WatchSelfPerson(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  WatchSelfPerson call({Object? name = const $CopyWithPlaceholder()}) {
    return WatchSelfPerson(
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
    );
  }
}

extension $WatchSelfPersonCopyWith on WatchSelfPerson {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfWatchSelfPerson.copyWith(...)` or `instanceOfWatchSelfPerson.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$WatchSelfPersonCWProxy get copyWith => _$WatchSelfPersonCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WatchSelfPerson _$WatchSelfPersonFromJson(Map<String, dynamic> json) =>
    $checkedCreate('WatchSelfPerson', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['name']);
      final val = WatchSelfPerson(
        name: $checkedConvert('name', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$WatchSelfPersonToJson(WatchSelfPerson instance) =>
    <String, dynamic>{'name': instance.name};
