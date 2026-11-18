// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'replaced_data_keys.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ReplacedDataKeysCWProxy {
  ReplacedDataKeys workspaces(int workspaces);

  ReplacedDataKeys people(int people);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ReplacedDataKeys(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ReplacedDataKeys(...).copyWith(id: 12, name: "My name")
  /// ```
  ReplacedDataKeys call({int workspaces, int people});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfReplacedDataKeys.copyWith(...)` or call `instanceOfReplacedDataKeys.copyWith.fieldName(value)` for a single field.
class _$ReplacedDataKeysCWProxyImpl implements _$ReplacedDataKeysCWProxy {
  const _$ReplacedDataKeysCWProxyImpl(this._value);

  final ReplacedDataKeys _value;

  @override
  ReplacedDataKeys workspaces(int workspaces) => call(workspaces: workspaces);

  @override
  ReplacedDataKeys people(int people) => call(people: people);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ReplacedDataKeys(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ReplacedDataKeys(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ReplacedDataKeys call({
    Object? workspaces = const $CopyWithPlaceholder(),
    Object? people = const $CopyWithPlaceholder(),
  }) {
    return ReplacedDataKeys(
      workspaces:
          workspaces == const $CopyWithPlaceholder() || workspaces == null
          ? _value.workspaces
          // ignore: cast_nullable_to_non_nullable
          : workspaces as int,
      people: people == const $CopyWithPlaceholder() || people == null
          ? _value.people
          // ignore: cast_nullable_to_non_nullable
          : people as int,
    );
  }
}

extension $ReplacedDataKeysCopyWith on ReplacedDataKeys {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfReplacedDataKeys.copyWith(...)` or `instanceOfReplacedDataKeys.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ReplacedDataKeysCWProxy get copyWith => _$ReplacedDataKeysCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReplacedDataKeys _$ReplacedDataKeysFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ReplacedDataKeys', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['workspaces', 'people']);
      final val = ReplacedDataKeys(
        workspaces: $checkedConvert('workspaces', (v) => (v as num).toInt()),
        people: $checkedConvert('people', (v) => (v as num).toInt()),
      );
      return val;
    });

Map<String, dynamic> _$ReplacedDataKeysToJson(ReplacedDataKeys instance) =>
    <String, dynamic>{
      'workspaces': instance.workspaces,
      'people': instance.people,
    };
