// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deleted_computer.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DeletedComputerCWProxy {
  DeletedComputer deleted(String deleted);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `DeletedComputer(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// DeletedComputer(...).copyWith(id: 12, name: "My name")
  /// ````
  DeletedComputer call({String deleted});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfDeletedComputer.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfDeletedComputer.copyWith.fieldName(...)`
class _$DeletedComputerCWProxyImpl implements _$DeletedComputerCWProxy {
  const _$DeletedComputerCWProxyImpl(this._value);

  final DeletedComputer _value;

  @override
  DeletedComputer deleted(String deleted) => this(deleted: deleted);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `DeletedComputer(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// DeletedComputer(...).copyWith(id: 12, name: "My name")
  /// ````
  DeletedComputer call({Object? deleted = const $CopyWithPlaceholder()}) {
    return DeletedComputer(
      deleted: deleted == const $CopyWithPlaceholder()
          ? _value.deleted
          // ignore: cast_nullable_to_non_nullable
          : deleted as String,
    );
  }
}

extension $DeletedComputerCopyWith on DeletedComputer {
  /// Returns a callable class that can be used as follows: `instanceOfDeletedComputer.copyWith(...)` or like so:`instanceOfDeletedComputer.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DeletedComputerCWProxy get copyWith => _$DeletedComputerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeletedComputer _$DeletedComputerFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DeletedComputer', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['deleted']);
      final val = DeletedComputer(
        deleted: $checkedConvert('deleted', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$DeletedComputerToJson(DeletedComputer instance) =>
    <String, dynamic>{'deleted': instance.deleted};
