// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deleted_channel.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DeletedChannelCWProxy {
  DeletedChannel deleted(String deleted);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeletedChannel(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeletedChannel(...).copyWith(id: 12, name: "My name")
  /// ```
  DeletedChannel call({String deleted});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDeletedChannel.copyWith(...)` or call `instanceOfDeletedChannel.copyWith.fieldName(value)` for a single field.
class _$DeletedChannelCWProxyImpl implements _$DeletedChannelCWProxy {
  const _$DeletedChannelCWProxyImpl(this._value);

  final DeletedChannel _value;

  @override
  DeletedChannel deleted(String deleted) => call(deleted: deleted);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeletedChannel(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeletedChannel(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DeletedChannel call({Object? deleted = const $CopyWithPlaceholder()}) {
    return DeletedChannel(
      deleted: deleted == const $CopyWithPlaceholder() || deleted == null
          ? _value.deleted
          // ignore: cast_nullable_to_non_nullable
          : deleted as String,
    );
  }
}

extension $DeletedChannelCopyWith on DeletedChannel {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDeletedChannel.copyWith(...)` or `instanceOfDeletedChannel.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DeletedChannelCWProxy get copyWith => _$DeletedChannelCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeletedChannel _$DeletedChannelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DeletedChannel', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['deleted']);
      final val = DeletedChannel(
        deleted: $checkedConvert('deleted', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$DeletedChannelToJson(DeletedChannel instance) =>
    <String, dynamic>{'deleted': instance.deleted};
