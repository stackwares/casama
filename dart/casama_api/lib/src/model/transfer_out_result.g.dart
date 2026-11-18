// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_out_result.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TransferOutResultCWProxy {
  TransferOutResult code(String code);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `TransferOutResult(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TransferOutResult(...).copyWith(id: 12, name: "My name")
  /// ```
  TransferOutResult call({String code});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfTransferOutResult.copyWith(...)` or call `instanceOfTransferOutResult.copyWith.fieldName(value)` for a single field.
class _$TransferOutResultCWProxyImpl implements _$TransferOutResultCWProxy {
  const _$TransferOutResultCWProxyImpl(this._value);

  final TransferOutResult _value;

  @override
  TransferOutResult code(String code) => call(code: code);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `TransferOutResult(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TransferOutResult(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  TransferOutResult call({Object? code = const $CopyWithPlaceholder()}) {
    return TransferOutResult(
      code: code == const $CopyWithPlaceholder() || code == null
          ? _value.code
          // ignore: cast_nullable_to_non_nullable
          : code as String,
    );
  }
}

extension $TransferOutResultCopyWith on TransferOutResult {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfTransferOutResult.copyWith(...)` or `instanceOfTransferOutResult.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TransferOutResultCWProxy get copyWith =>
      _$TransferOutResultCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransferOutResult _$TransferOutResultFromJson(Map<String, dynamic> json) =>
    $checkedCreate('TransferOutResult', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['code']);
      final val = TransferOutResult(
        code: $checkedConvert('code', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$TransferOutResultToJson(TransferOutResult instance) =>
    <String, dynamic>{'code': instance.code};
