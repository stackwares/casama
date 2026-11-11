// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mcp_consent_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$McpConsentRequestCWProxy {
  McpConsentRequest orgId(String orgId);

  McpConsentRequest approve(bool approve);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `McpConsentRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// McpConsentRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  McpConsentRequest call({String orgId, bool approve});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfMcpConsentRequest.copyWith(...)` or call `instanceOfMcpConsentRequest.copyWith.fieldName(value)` for a single field.
class _$McpConsentRequestCWProxyImpl implements _$McpConsentRequestCWProxy {
  const _$McpConsentRequestCWProxyImpl(this._value);

  final McpConsentRequest _value;

  @override
  McpConsentRequest orgId(String orgId) => call(orgId: orgId);

  @override
  McpConsentRequest approve(bool approve) => call(approve: approve);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `McpConsentRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// McpConsentRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  McpConsentRequest call({
    Object? orgId = const $CopyWithPlaceholder(),
    Object? approve = const $CopyWithPlaceholder(),
  }) {
    return McpConsentRequest(
      orgId: orgId == const $CopyWithPlaceholder() || orgId == null
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
      approve: approve == const $CopyWithPlaceholder() || approve == null
          ? _value.approve
          // ignore: cast_nullable_to_non_nullable
          : approve as bool,
    );
  }
}

extension $McpConsentRequestCopyWith on McpConsentRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfMcpConsentRequest.copyWith(...)` or `instanceOfMcpConsentRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$McpConsentRequestCWProxy get copyWith =>
      _$McpConsentRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

McpConsentRequest _$McpConsentRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('McpConsentRequest', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['org_id', 'approve']);
      final val = McpConsentRequest(
        orgId: $checkedConvert('org_id', (v) => v as String),
        approve: $checkedConvert('approve', (v) => v as bool),
      );
      return val;
    }, fieldKeyMap: const {'orgId': 'org_id'});

Map<String, dynamic> _$McpConsentRequestToJson(McpConsentRequest instance) =>
    <String, dynamic>{'org_id': instance.orgId, 'approve': instance.approve};
