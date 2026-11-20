// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'block_mail_sender_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BlockMailSenderRequestCWProxy {
  BlockMailSenderRequest sender(String sender);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BlockMailSenderRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BlockMailSenderRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  BlockMailSenderRequest call({String sender});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfBlockMailSenderRequest.copyWith(...)` or call `instanceOfBlockMailSenderRequest.copyWith.fieldName(value)` for a single field.
class _$BlockMailSenderRequestCWProxyImpl
    implements _$BlockMailSenderRequestCWProxy {
  const _$BlockMailSenderRequestCWProxyImpl(this._value);

  final BlockMailSenderRequest _value;

  @override
  BlockMailSenderRequest sender(String sender) => call(sender: sender);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BlockMailSenderRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BlockMailSenderRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  BlockMailSenderRequest call({Object? sender = const $CopyWithPlaceholder()}) {
    return BlockMailSenderRequest(
      sender: sender == const $CopyWithPlaceholder() || sender == null
          ? _value.sender
          // ignore: cast_nullable_to_non_nullable
          : sender as String,
    );
  }
}

extension $BlockMailSenderRequestCopyWith on BlockMailSenderRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfBlockMailSenderRequest.copyWith(...)` or `instanceOfBlockMailSenderRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$BlockMailSenderRequestCWProxy get copyWith =>
      _$BlockMailSenderRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BlockMailSenderRequest _$BlockMailSenderRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('BlockMailSenderRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['sender']);
  final val = BlockMailSenderRequest(
    sender: $checkedConvert('sender', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$BlockMailSenderRequestToJson(
  BlockMailSenderRequest instance,
) => <String, dynamic>{'sender': instance.sender};
