// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deleted_id.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DeletedIdCWProxy {
  DeletedId deleted(String deleted);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `DeletedId(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// DeletedId(...).copyWith(id: 12, name: "My name")
  /// ````
  DeletedId call({String deleted});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfDeletedId.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfDeletedId.copyWith.fieldName(...)`
class _$DeletedIdCWProxyImpl implements _$DeletedIdCWProxy {
  const _$DeletedIdCWProxyImpl(this._value);

  final DeletedId _value;

  @override
  DeletedId deleted(String deleted) => this(deleted: deleted);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `DeletedId(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// DeletedId(...).copyWith(id: 12, name: "My name")
  /// ````
  DeletedId call({Object? deleted = const $CopyWithPlaceholder()}) {
    return DeletedId(
      deleted: deleted == const $CopyWithPlaceholder()
          ? _value.deleted
          // ignore: cast_nullable_to_non_nullable
          : deleted as String,
    );
  }
}

extension $DeletedIdCopyWith on DeletedId {
  /// Returns a callable class that can be used as follows: `instanceOfDeletedId.copyWith(...)` or like so:`instanceOfDeletedId.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DeletedIdCWProxy get copyWith => _$DeletedIdCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeletedId _$DeletedIdFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DeletedId', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['deleted']);
      final val = DeletedId(
        deleted: $checkedConvert('deleted', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$DeletedIdToJson(DeletedId instance) => <String, dynamic>{
  'deleted': instance.deleted,
};
