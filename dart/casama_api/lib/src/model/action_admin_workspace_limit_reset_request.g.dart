// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'action_admin_workspace_limit_reset_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ActionAdminWorkspaceLimitResetRequestCWProxy {
  ActionAdminWorkspaceLimitResetRequest action(
    ActionAdminWorkspaceLimitResetRequestActionEnum action,
  );

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ActionAdminWorkspaceLimitResetRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ActionAdminWorkspaceLimitResetRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  ActionAdminWorkspaceLimitResetRequest call({
    ActionAdminWorkspaceLimitResetRequestActionEnum action,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfActionAdminWorkspaceLimitResetRequest.copyWith(...)` or call `instanceOfActionAdminWorkspaceLimitResetRequest.copyWith.fieldName(value)` for a single field.
class _$ActionAdminWorkspaceLimitResetRequestCWProxyImpl
    implements _$ActionAdminWorkspaceLimitResetRequestCWProxy {
  const _$ActionAdminWorkspaceLimitResetRequestCWProxyImpl(this._value);

  final ActionAdminWorkspaceLimitResetRequest _value;

  @override
  ActionAdminWorkspaceLimitResetRequest action(
    ActionAdminWorkspaceLimitResetRequestActionEnum action,
  ) => call(action: action);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ActionAdminWorkspaceLimitResetRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ActionAdminWorkspaceLimitResetRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ActionAdminWorkspaceLimitResetRequest call({
    Object? action = const $CopyWithPlaceholder(),
  }) {
    return ActionAdminWorkspaceLimitResetRequest(
      action: action == const $CopyWithPlaceholder() || action == null
          ? _value.action
          // ignore: cast_nullable_to_non_nullable
          : action as ActionAdminWorkspaceLimitResetRequestActionEnum,
    );
  }
}

extension $ActionAdminWorkspaceLimitResetRequestCopyWith
    on ActionAdminWorkspaceLimitResetRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfActionAdminWorkspaceLimitResetRequest.copyWith(...)` or `instanceOfActionAdminWorkspaceLimitResetRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ActionAdminWorkspaceLimitResetRequestCWProxy get copyWith =>
      _$ActionAdminWorkspaceLimitResetRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActionAdminWorkspaceLimitResetRequest
_$ActionAdminWorkspaceLimitResetRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ActionAdminWorkspaceLimitResetRequest', json, (
      $checkedConvert,
    ) {
      $checkKeys(json, requiredKeys: const ['action']);
      final val = ActionAdminWorkspaceLimitResetRequest(
        action: $checkedConvert(
          'action',
          (v) => $enumDecode(
            _$ActionAdminWorkspaceLimitResetRequestActionEnumEnumMap,
            v,
          ),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ActionAdminWorkspaceLimitResetRequestToJson(
  ActionAdminWorkspaceLimitResetRequest instance,
) => <String, dynamic>{
  'action':
      _$ActionAdminWorkspaceLimitResetRequestActionEnumEnumMap[instance
          .action]!,
};

const _$ActionAdminWorkspaceLimitResetRequestActionEnumEnumMap = {
  ActionAdminWorkspaceLimitResetRequestActionEnum.revoke: 'revoke',
  ActionAdminWorkspaceLimitResetRequestActionEnum.undo: 'undo',
};
