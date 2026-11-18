// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'set_connection_settings_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SetConnectionSettingsRequestCWProxy {
  SetConnectionSettingsRequest composio(
    SetConnectionSettingsRequestComposioEnum? composio,
  );

  SetConnectionSettingsRequest google(
    SetConnectionSettingsRequestGoogleEnum? google,
  );

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SetConnectionSettingsRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SetConnectionSettingsRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  SetConnectionSettingsRequest call({
    SetConnectionSettingsRequestComposioEnum? composio,
    SetConnectionSettingsRequestGoogleEnum? google,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSetConnectionSettingsRequest.copyWith(...)` or call `instanceOfSetConnectionSettingsRequest.copyWith.fieldName(value)` for a single field.
class _$SetConnectionSettingsRequestCWProxyImpl
    implements _$SetConnectionSettingsRequestCWProxy {
  const _$SetConnectionSettingsRequestCWProxyImpl(this._value);

  final SetConnectionSettingsRequest _value;

  @override
  SetConnectionSettingsRequest composio(
    SetConnectionSettingsRequestComposioEnum? composio,
  ) => call(composio: composio);

  @override
  SetConnectionSettingsRequest google(
    SetConnectionSettingsRequestGoogleEnum? google,
  ) => call(google: google);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SetConnectionSettingsRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SetConnectionSettingsRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SetConnectionSettingsRequest call({
    Object? composio = const $CopyWithPlaceholder(),
    Object? google = const $CopyWithPlaceholder(),
  }) {
    return SetConnectionSettingsRequest(
      composio: composio == const $CopyWithPlaceholder()
          ? _value.composio
          // ignore: cast_nullable_to_non_nullable
          : composio as SetConnectionSettingsRequestComposioEnum?,
      google: google == const $CopyWithPlaceholder()
          ? _value.google
          // ignore: cast_nullable_to_non_nullable
          : google as SetConnectionSettingsRequestGoogleEnum?,
    );
  }
}

extension $SetConnectionSettingsRequestCopyWith
    on SetConnectionSettingsRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSetConnectionSettingsRequest.copyWith(...)` or `instanceOfSetConnectionSettingsRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SetConnectionSettingsRequestCWProxy get copyWith =>
      _$SetConnectionSettingsRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SetConnectionSettingsRequest _$SetConnectionSettingsRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('SetConnectionSettingsRequest', json, ($checkedConvert) {
  final val = SetConnectionSettingsRequest(
    composio: $checkedConvert(
      'composio',
      (v) => $enumDecodeNullable(
        _$SetConnectionSettingsRequestComposioEnumEnumMap,
        v,
      ),
    ),
    google: $checkedConvert(
      'google',
      (v) => $enumDecodeNullable(
        _$SetConnectionSettingsRequestGoogleEnumEnumMap,
        v,
      ),
    ),
  );
  return val;
});

Map<String, dynamic> _$SetConnectionSettingsRequestToJson(
  SetConnectionSettingsRequest instance,
) => <String, dynamic>{
  'composio':
      ?_$SetConnectionSettingsRequestComposioEnumEnumMap[instance.composio],
  'google': ?_$SetConnectionSettingsRequestGoogleEnumEnumMap[instance.google],
};

const _$SetConnectionSettingsRequestComposioEnumEnumMap = {
  SetConnectionSettingsRequestComposioEnum.server: 'server',
  SetConnectionSettingsRequestComposioEnum.own: 'own',
};

const _$SetConnectionSettingsRequestGoogleEnumEnumMap = {
  SetConnectionSettingsRequestGoogleEnum.composio: 'composio',
  SetConnectionSettingsRequestGoogleEnum.direct: 'direct',
};
