// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_out_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TransferOutRequestCWProxy {
  TransferOutRequest confirmName(String confirmName);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `TransferOutRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TransferOutRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  TransferOutRequest call({String confirmName});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfTransferOutRequest.copyWith(...)` or call `instanceOfTransferOutRequest.copyWith.fieldName(value)` for a single field.
class _$TransferOutRequestCWProxyImpl implements _$TransferOutRequestCWProxy {
  const _$TransferOutRequestCWProxyImpl(this._value);

  final TransferOutRequest _value;

  @override
  TransferOutRequest confirmName(String confirmName) =>
      call(confirmName: confirmName);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `TransferOutRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TransferOutRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  TransferOutRequest call({
    Object? confirmName = const $CopyWithPlaceholder(),
  }) {
    return TransferOutRequest(
      confirmName:
          confirmName == const $CopyWithPlaceholder() || confirmName == null
          ? _value.confirmName
          // ignore: cast_nullable_to_non_nullable
          : confirmName as String,
    );
  }
}

extension $TransferOutRequestCopyWith on TransferOutRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfTransferOutRequest.copyWith(...)` or `instanceOfTransferOutRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TransferOutRequestCWProxy get copyWith =>
      _$TransferOutRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransferOutRequest _$TransferOutRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('TransferOutRequest', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['confirm_name']);
      final val = TransferOutRequest(
        confirmName: $checkedConvert('confirm_name', (v) => v as String),
      );
      return val;
    }, fieldKeyMap: const {'confirmName': 'confirm_name'});

Map<String, dynamic> _$TransferOutRequestToJson(TransferOutRequest instance) =>
    <String, dynamic>{'confirm_name': instance.confirmName};
