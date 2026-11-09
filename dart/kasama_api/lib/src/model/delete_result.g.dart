// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delete_result.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DeleteResultCWProxy {
  DeleteResult deleted(String deleted);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `DeleteResult(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// DeleteResult(...).copyWith(id: 12, name: "My name")
  /// ````
  DeleteResult call({String deleted});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfDeleteResult.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfDeleteResult.copyWith.fieldName(...)`
class _$DeleteResultCWProxyImpl implements _$DeleteResultCWProxy {
  const _$DeleteResultCWProxyImpl(this._value);

  final DeleteResult _value;

  @override
  DeleteResult deleted(String deleted) => this(deleted: deleted);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `DeleteResult(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// DeleteResult(...).copyWith(id: 12, name: "My name")
  /// ````
  DeleteResult call({Object? deleted = const $CopyWithPlaceholder()}) {
    return DeleteResult(
      deleted: deleted == const $CopyWithPlaceholder()
          ? _value.deleted
          // ignore: cast_nullable_to_non_nullable
          : deleted as String,
    );
  }
}

extension $DeleteResultCopyWith on DeleteResult {
  /// Returns a callable class that can be used as follows: `instanceOfDeleteResult.copyWith(...)` or like so:`instanceOfDeleteResult.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DeleteResultCWProxy get copyWith => _$DeleteResultCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeleteResult _$DeleteResultFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DeleteResult', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['deleted']);
      final val = DeleteResult(
        deleted: $checkedConvert('deleted', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$DeleteResultToJson(DeleteResult instance) =>
    <String, dynamic>{'deleted': instance.deleted};
