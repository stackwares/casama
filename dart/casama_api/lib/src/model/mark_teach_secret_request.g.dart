// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mark_teach_secret_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MarkTeachSecretRequestCWProxy {
  MarkTeachSecretRequest secretName(String secretName);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `MarkTeachSecretRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// MarkTeachSecretRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  MarkTeachSecretRequest call({String secretName});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfMarkTeachSecretRequest.copyWith(...)` or call `instanceOfMarkTeachSecretRequest.copyWith.fieldName(value)` for a single field.
class _$MarkTeachSecretRequestCWProxyImpl
    implements _$MarkTeachSecretRequestCWProxy {
  const _$MarkTeachSecretRequestCWProxyImpl(this._value);

  final MarkTeachSecretRequest _value;

  @override
  MarkTeachSecretRequest secretName(String secretName) =>
      call(secretName: secretName);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `MarkTeachSecretRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// MarkTeachSecretRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  MarkTeachSecretRequest call({
    Object? secretName = const $CopyWithPlaceholder(),
  }) {
    return MarkTeachSecretRequest(
      secretName:
          secretName == const $CopyWithPlaceholder() || secretName == null
          ? _value.secretName
          // ignore: cast_nullable_to_non_nullable
          : secretName as String,
    );
  }
}

extension $MarkTeachSecretRequestCopyWith on MarkTeachSecretRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfMarkTeachSecretRequest.copyWith(...)` or `instanceOfMarkTeachSecretRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MarkTeachSecretRequestCWProxy get copyWith =>
      _$MarkTeachSecretRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MarkTeachSecretRequest _$MarkTeachSecretRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('MarkTeachSecretRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['secret_name']);
  final val = MarkTeachSecretRequest(
    secretName: $checkedConvert('secret_name', (v) => v as String),
  );
  return val;
}, fieldKeyMap: const {'secretName': 'secret_name'});

Map<String, dynamic> _$MarkTeachSecretRequestToJson(
  MarkTeachSecretRequest instance,
) => <String, dynamic>{'secret_name': instance.secretName};
