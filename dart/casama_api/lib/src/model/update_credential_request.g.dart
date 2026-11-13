// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_credential_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UpdateCredentialRequestCWProxy {
  UpdateCredentialRequest label(String? label);

  UpdateCredentialRequest fallbackOnLimit(bool? fallbackOnLimit);

  UpdateCredentialRequest embeddingModel(String? embeddingModel);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UpdateCredentialRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UpdateCredentialRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  UpdateCredentialRequest call({
    String? label,
    bool? fallbackOnLimit,
    String? embeddingModel,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfUpdateCredentialRequest.copyWith(...)` or call `instanceOfUpdateCredentialRequest.copyWith.fieldName(value)` for a single field.
class _$UpdateCredentialRequestCWProxyImpl
    implements _$UpdateCredentialRequestCWProxy {
  const _$UpdateCredentialRequestCWProxyImpl(this._value);

  final UpdateCredentialRequest _value;

  @override
  UpdateCredentialRequest label(String? label) => call(label: label);

  @override
  UpdateCredentialRequest fallbackOnLimit(bool? fallbackOnLimit) =>
      call(fallbackOnLimit: fallbackOnLimit);

  @override
  UpdateCredentialRequest embeddingModel(String? embeddingModel) =>
      call(embeddingModel: embeddingModel);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UpdateCredentialRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UpdateCredentialRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  UpdateCredentialRequest call({
    Object? label = const $CopyWithPlaceholder(),
    Object? fallbackOnLimit = const $CopyWithPlaceholder(),
    Object? embeddingModel = const $CopyWithPlaceholder(),
  }) {
    return UpdateCredentialRequest(
      label: label == const $CopyWithPlaceholder()
          ? _value.label
          // ignore: cast_nullable_to_non_nullable
          : label as String?,
      fallbackOnLimit: fallbackOnLimit == const $CopyWithPlaceholder()
          ? _value.fallbackOnLimit
          // ignore: cast_nullable_to_non_nullable
          : fallbackOnLimit as bool?,
      embeddingModel: embeddingModel == const $CopyWithPlaceholder()
          ? _value.embeddingModel
          // ignore: cast_nullable_to_non_nullable
          : embeddingModel as String?,
    );
  }
}

extension $UpdateCredentialRequestCopyWith on UpdateCredentialRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfUpdateCredentialRequest.copyWith(...)` or `instanceOfUpdateCredentialRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$UpdateCredentialRequestCWProxy get copyWith =>
      _$UpdateCredentialRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateCredentialRequest _$UpdateCredentialRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'UpdateCredentialRequest',
  json,
  ($checkedConvert) {
    final val = UpdateCredentialRequest(
      label: $checkedConvert('label', (v) => v as String?),
      fallbackOnLimit: $checkedConvert('fallback_on_limit', (v) => v as bool?),
      embeddingModel: $checkedConvert('embedding_model', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {
    'fallbackOnLimit': 'fallback_on_limit',
    'embeddingModel': 'embedding_model',
  },
);

Map<String, dynamic> _$UpdateCredentialRequestToJson(
  UpdateCredentialRequest instance,
) => <String, dynamic>{
  'label': ?instance.label,
  'fallback_on_limit': ?instance.fallbackOnLimit,
  'embedding_model': ?instance.embeddingModel,
};
