// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delete_integration200_response.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DeleteIntegration200ResponseCWProxy {
  DeleteIntegration200Response ok(bool ok);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeleteIntegration200Response(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeleteIntegration200Response(...).copyWith(id: 12, name: "My name")
  /// ```
  DeleteIntegration200Response call({bool ok});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDeleteIntegration200Response.copyWith(...)` or call `instanceOfDeleteIntegration200Response.copyWith.fieldName(value)` for a single field.
class _$DeleteIntegration200ResponseCWProxyImpl
    implements _$DeleteIntegration200ResponseCWProxy {
  const _$DeleteIntegration200ResponseCWProxyImpl(this._value);

  final DeleteIntegration200Response _value;

  @override
  DeleteIntegration200Response ok(bool ok) => call(ok: ok);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeleteIntegration200Response(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeleteIntegration200Response(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DeleteIntegration200Response call({
    Object? ok = const $CopyWithPlaceholder(),
  }) {
    return DeleteIntegration200Response(
      ok: ok == const $CopyWithPlaceholder() || ok == null
          ? _value.ok
          // ignore: cast_nullable_to_non_nullable
          : ok as bool,
    );
  }
}

extension $DeleteIntegration200ResponseCopyWith
    on DeleteIntegration200Response {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDeleteIntegration200Response.copyWith(...)` or `instanceOfDeleteIntegration200Response.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DeleteIntegration200ResponseCWProxy get copyWith =>
      _$DeleteIntegration200ResponseCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeleteIntegration200Response _$DeleteIntegration200ResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('DeleteIntegration200Response', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['ok']);
  final val = DeleteIntegration200Response(
    ok: $checkedConvert('ok', (v) => v as bool),
  );
  return val;
});

Map<String, dynamic> _$DeleteIntegration200ResponseToJson(
  DeleteIntegration200Response instance,
) => <String, dynamic>{'ok': instance.ok};
