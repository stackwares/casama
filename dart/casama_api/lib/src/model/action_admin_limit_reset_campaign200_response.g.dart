// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'action_admin_limit_reset_campaign200_response.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ActionAdminLimitResetCampaign200ResponseCWProxy {
  ActionAdminLimitResetCampaign200Response ok(bool ok);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ActionAdminLimitResetCampaign200Response(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ActionAdminLimitResetCampaign200Response(...).copyWith(id: 12, name: "My name")
  /// ```
  ActionAdminLimitResetCampaign200Response call({bool ok});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfActionAdminLimitResetCampaign200Response.copyWith(...)` or call `instanceOfActionAdminLimitResetCampaign200Response.copyWith.fieldName(value)` for a single field.
class _$ActionAdminLimitResetCampaign200ResponseCWProxyImpl
    implements _$ActionAdminLimitResetCampaign200ResponseCWProxy {
  const _$ActionAdminLimitResetCampaign200ResponseCWProxyImpl(this._value);

  final ActionAdminLimitResetCampaign200Response _value;

  @override
  ActionAdminLimitResetCampaign200Response ok(bool ok) => call(ok: ok);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ActionAdminLimitResetCampaign200Response(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ActionAdminLimitResetCampaign200Response(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ActionAdminLimitResetCampaign200Response call({
    Object? ok = const $CopyWithPlaceholder(),
  }) {
    return ActionAdminLimitResetCampaign200Response(
      ok: ok == const $CopyWithPlaceholder() || ok == null
          ? _value.ok
          // ignore: cast_nullable_to_non_nullable
          : ok as bool,
    );
  }
}

extension $ActionAdminLimitResetCampaign200ResponseCopyWith
    on ActionAdminLimitResetCampaign200Response {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfActionAdminLimitResetCampaign200Response.copyWith(...)` or `instanceOfActionAdminLimitResetCampaign200Response.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ActionAdminLimitResetCampaign200ResponseCWProxy get copyWith =>
      _$ActionAdminLimitResetCampaign200ResponseCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActionAdminLimitResetCampaign200Response
_$ActionAdminLimitResetCampaign200ResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ActionAdminLimitResetCampaign200Response', json, (
      $checkedConvert,
    ) {
      $checkKeys(json, requiredKeys: const ['ok']);
      final val = ActionAdminLimitResetCampaign200Response(
        ok: $checkedConvert('ok', (v) => v as bool),
      );
      return val;
    });

Map<String, dynamic> _$ActionAdminLimitResetCampaign200ResponseToJson(
  ActionAdminLimitResetCampaign200Response instance,
) => <String, dynamic>{'ok': instance.ok};
