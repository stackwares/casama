// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'claim_mail_address_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ClaimMailAddressRequestCWProxy {
  ClaimMailAddressRequest name(String name);

  ClaimMailAddressRequest surface(ClaimMailAddressRequestSurfaceEnum? surface);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ClaimMailAddressRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ClaimMailAddressRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  ClaimMailAddressRequest call({
    String name,
    ClaimMailAddressRequestSurfaceEnum? surface,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfClaimMailAddressRequest.copyWith(...)` or call `instanceOfClaimMailAddressRequest.copyWith.fieldName(value)` for a single field.
class _$ClaimMailAddressRequestCWProxyImpl
    implements _$ClaimMailAddressRequestCWProxy {
  const _$ClaimMailAddressRequestCWProxyImpl(this._value);

  final ClaimMailAddressRequest _value;

  @override
  ClaimMailAddressRequest name(String name) => call(name: name);

  @override
  ClaimMailAddressRequest surface(
    ClaimMailAddressRequestSurfaceEnum? surface,
  ) => call(surface: surface);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ClaimMailAddressRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ClaimMailAddressRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ClaimMailAddressRequest call({
    Object? name = const $CopyWithPlaceholder(),
    Object? surface = const $CopyWithPlaceholder(),
  }) {
    return ClaimMailAddressRequest(
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      surface: surface == const $CopyWithPlaceholder()
          ? _value.surface
          // ignore: cast_nullable_to_non_nullable
          : surface as ClaimMailAddressRequestSurfaceEnum?,
    );
  }
}

extension $ClaimMailAddressRequestCopyWith on ClaimMailAddressRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfClaimMailAddressRequest.copyWith(...)` or `instanceOfClaimMailAddressRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ClaimMailAddressRequestCWProxy get copyWith =>
      _$ClaimMailAddressRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClaimMailAddressRequest _$ClaimMailAddressRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ClaimMailAddressRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['name']);
  final val = ClaimMailAddressRequest(
    name: $checkedConvert('name', (v) => v as String),
    surface: $checkedConvert(
      'surface',
      (v) =>
          $enumDecodeNullable(_$ClaimMailAddressRequestSurfaceEnumEnumMap, v),
    ),
  );
  return val;
});

Map<String, dynamic> _$ClaimMailAddressRequestToJson(
  ClaimMailAddressRequest instance,
) => <String, dynamic>{
  'name': instance.name,
  'surface': ?_$ClaimMailAddressRequestSurfaceEnumEnumMap[instance.surface],
};

const _$ClaimMailAddressRequestSurfaceEnumEnumMap = {
  ClaimMailAddressRequestSurfaceEnum.profile: 'profile',
  ClaimMailAddressRequestSurfaceEnum.tool: 'tool',
  ClaimMailAddressRequestSurfaceEnum.suggestion: 'suggestion',
};
