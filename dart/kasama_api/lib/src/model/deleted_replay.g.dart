// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deleted_replay.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DeletedReplayCWProxy {
  DeletedReplay deleted(String deleted);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeletedReplay(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeletedReplay(...).copyWith(id: 12, name: "My name")
  /// ```
  DeletedReplay call({String deleted});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDeletedReplay.copyWith(...)` or call `instanceOfDeletedReplay.copyWith.fieldName(value)` for a single field.
class _$DeletedReplayCWProxyImpl implements _$DeletedReplayCWProxy {
  const _$DeletedReplayCWProxyImpl(this._value);

  final DeletedReplay _value;

  @override
  DeletedReplay deleted(String deleted) => call(deleted: deleted);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeletedReplay(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeletedReplay(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DeletedReplay call({Object? deleted = const $CopyWithPlaceholder()}) {
    return DeletedReplay(
      deleted: deleted == const $CopyWithPlaceholder() || deleted == null
          ? _value.deleted
          // ignore: cast_nullable_to_non_nullable
          : deleted as String,
    );
  }
}

extension $DeletedReplayCopyWith on DeletedReplay {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDeletedReplay.copyWith(...)` or `instanceOfDeletedReplay.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DeletedReplayCWProxy get copyWith => _$DeletedReplayCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeletedReplay _$DeletedReplayFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DeletedReplay', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['deleted']);
      final val = DeletedReplay(
        deleted: $checkedConvert('deleted', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$DeletedReplayToJson(DeletedReplay instance) =>
    <String, dynamic>{'deleted': instance.deleted};
