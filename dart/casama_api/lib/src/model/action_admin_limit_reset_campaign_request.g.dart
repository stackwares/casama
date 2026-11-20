// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'action_admin_limit_reset_campaign_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ActionAdminLimitResetCampaignRequestCWProxy {
  ActionAdminLimitResetCampaignRequest action(
    ActionAdminLimitResetCampaignRequestActionEnum action,
  );

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ActionAdminLimitResetCampaignRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ActionAdminLimitResetCampaignRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  ActionAdminLimitResetCampaignRequest call({
    ActionAdminLimitResetCampaignRequestActionEnum action,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfActionAdminLimitResetCampaignRequest.copyWith(...)` or call `instanceOfActionAdminLimitResetCampaignRequest.copyWith.fieldName(value)` for a single field.
class _$ActionAdminLimitResetCampaignRequestCWProxyImpl
    implements _$ActionAdminLimitResetCampaignRequestCWProxy {
  const _$ActionAdminLimitResetCampaignRequestCWProxyImpl(this._value);

  final ActionAdminLimitResetCampaignRequest _value;

  @override
  ActionAdminLimitResetCampaignRequest action(
    ActionAdminLimitResetCampaignRequestActionEnum action,
  ) => call(action: action);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ActionAdminLimitResetCampaignRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ActionAdminLimitResetCampaignRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ActionAdminLimitResetCampaignRequest call({
    Object? action = const $CopyWithPlaceholder(),
  }) {
    return ActionAdminLimitResetCampaignRequest(
      action: action == const $CopyWithPlaceholder() || action == null
          ? _value.action
          // ignore: cast_nullable_to_non_nullable
          : action as ActionAdminLimitResetCampaignRequestActionEnum,
    );
  }
}

extension $ActionAdminLimitResetCampaignRequestCopyWith
    on ActionAdminLimitResetCampaignRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfActionAdminLimitResetCampaignRequest.copyWith(...)` or `instanceOfActionAdminLimitResetCampaignRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ActionAdminLimitResetCampaignRequestCWProxy get copyWith =>
      _$ActionAdminLimitResetCampaignRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActionAdminLimitResetCampaignRequest
_$ActionAdminLimitResetCampaignRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ActionAdminLimitResetCampaignRequest', json, (
      $checkedConvert,
    ) {
      $checkKeys(json, requiredKeys: const ['action']);
      final val = ActionAdminLimitResetCampaignRequest(
        action: $checkedConvert(
          'action',
          (v) => $enumDecode(
            _$ActionAdminLimitResetCampaignRequestActionEnumEnumMap,
            v,
          ),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ActionAdminLimitResetCampaignRequestToJson(
  ActionAdminLimitResetCampaignRequest instance,
) => <String, dynamic>{
  'action':
      _$ActionAdminLimitResetCampaignRequestActionEnumEnumMap[instance.action]!,
};

const _$ActionAdminLimitResetCampaignRequestActionEnumEnumMap = {
  ActionAdminLimitResetCampaignRequestActionEnum.schedule: 'schedule',
  ActionAdminLimitResetCampaignRequestActionEnum.pause: 'pause',
  ActionAdminLimitResetCampaignRequestActionEnum.resume: 'resume',
  ActionAdminLimitResetCampaignRequestActionEnum.cancel: 'cancel',
  ActionAdminLimitResetCampaignRequestActionEnum.delete: 'delete',
};
