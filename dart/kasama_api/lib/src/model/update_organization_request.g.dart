// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_organization_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UpdateOrganizationRequestCWProxy {
  UpdateOrganizationRequest name(String? name);

  UpdateOrganizationRequest icon(String? icon);

  UpdateOrganizationRequest color(String? color);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UpdateOrganizationRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UpdateOrganizationRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  UpdateOrganizationRequest call({String? name, String? icon, String? color});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfUpdateOrganizationRequest.copyWith(...)` or call `instanceOfUpdateOrganizationRequest.copyWith.fieldName(value)` for a single field.
class _$UpdateOrganizationRequestCWProxyImpl
    implements _$UpdateOrganizationRequestCWProxy {
  const _$UpdateOrganizationRequestCWProxyImpl(this._value);

  final UpdateOrganizationRequest _value;

  @override
  UpdateOrganizationRequest name(String? name) => call(name: name);

  @override
  UpdateOrganizationRequest icon(String? icon) => call(icon: icon);

  @override
  UpdateOrganizationRequest color(String? color) => call(color: color);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UpdateOrganizationRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UpdateOrganizationRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  UpdateOrganizationRequest call({
    Object? name = const $CopyWithPlaceholder(),
    Object? icon = const $CopyWithPlaceholder(),
    Object? color = const $CopyWithPlaceholder(),
  }) {
    return UpdateOrganizationRequest(
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String?,
      icon: icon == const $CopyWithPlaceholder()
          ? _value.icon
          // ignore: cast_nullable_to_non_nullable
          : icon as String?,
      color: color == const $CopyWithPlaceholder()
          ? _value.color
          // ignore: cast_nullable_to_non_nullable
          : color as String?,
    );
  }
}

extension $UpdateOrganizationRequestCopyWith on UpdateOrganizationRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfUpdateOrganizationRequest.copyWith(...)` or `instanceOfUpdateOrganizationRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$UpdateOrganizationRequestCWProxy get copyWith =>
      _$UpdateOrganizationRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateOrganizationRequest _$UpdateOrganizationRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('UpdateOrganizationRequest', json, ($checkedConvert) {
  final val = UpdateOrganizationRequest(
    name: $checkedConvert('name', (v) => v as String?),
    icon: $checkedConvert('icon', (v) => v as String?),
    color: $checkedConvert('color', (v) => v as String?),
  );
  return val;
});

Map<String, dynamic> _$UpdateOrganizationRequestToJson(
  UpdateOrganizationRequest instance,
) => <String, dynamic>{
  'name': ?instance.name,
  'icon': ?instance.icon,
  'color': ?instance.color,
};
