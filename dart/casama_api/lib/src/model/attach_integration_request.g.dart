// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attach_integration_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AttachIntegrationRequestCWProxy {
  AttachIntegrationRequest integrationId(String integrationId);

  AttachIntegrationRequest toolAllowlist(List<String>? toolAllowlist);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AttachIntegrationRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AttachIntegrationRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  AttachIntegrationRequest call({
    String integrationId,
    List<String>? toolAllowlist,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAttachIntegrationRequest.copyWith(...)` or call `instanceOfAttachIntegrationRequest.copyWith.fieldName(value)` for a single field.
class _$AttachIntegrationRequestCWProxyImpl
    implements _$AttachIntegrationRequestCWProxy {
  const _$AttachIntegrationRequestCWProxyImpl(this._value);

  final AttachIntegrationRequest _value;

  @override
  AttachIntegrationRequest integrationId(String integrationId) =>
      call(integrationId: integrationId);

  @override
  AttachIntegrationRequest toolAllowlist(List<String>? toolAllowlist) =>
      call(toolAllowlist: toolAllowlist);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AttachIntegrationRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AttachIntegrationRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AttachIntegrationRequest call({
    Object? integrationId = const $CopyWithPlaceholder(),
    Object? toolAllowlist = const $CopyWithPlaceholder(),
  }) {
    return AttachIntegrationRequest(
      integrationId:
          integrationId == const $CopyWithPlaceholder() || integrationId == null
          ? _value.integrationId
          // ignore: cast_nullable_to_non_nullable
          : integrationId as String,
      toolAllowlist: toolAllowlist == const $CopyWithPlaceholder()
          ? _value.toolAllowlist
          // ignore: cast_nullable_to_non_nullable
          : toolAllowlist as List<String>?,
    );
  }
}

extension $AttachIntegrationRequestCopyWith on AttachIntegrationRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAttachIntegrationRequest.copyWith(...)` or `instanceOfAttachIntegrationRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AttachIntegrationRequestCWProxy get copyWith =>
      _$AttachIntegrationRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AttachIntegrationRequest _$AttachIntegrationRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'AttachIntegrationRequest',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['integration_id']);
    final val = AttachIntegrationRequest(
      integrationId: $checkedConvert('integration_id', (v) => v as String),
      toolAllowlist: $checkedConvert(
        'tool_allowlist',
        (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'integrationId': 'integration_id',
    'toolAllowlist': 'tool_allowlist',
  },
);

Map<String, dynamic> _$AttachIntegrationRequestToJson(
  AttachIntegrationRequest instance,
) => <String, dynamic>{
  'integration_id': instance.integrationId,
  'tool_allowlist': ?instance.toolAllowlist,
};
