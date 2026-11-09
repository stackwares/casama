// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attach_integration_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AttachIntegrationRequestCWProxy {
  AttachIntegrationRequest integrationId(String integrationId);

  AttachIntegrationRequest toolAllowlist(List<String>? toolAllowlist);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AttachIntegrationRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AttachIntegrationRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  AttachIntegrationRequest call({
    String integrationId,
    List<String>? toolAllowlist,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAttachIntegrationRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAttachIntegrationRequest.copyWith.fieldName(...)`
class _$AttachIntegrationRequestCWProxyImpl
    implements _$AttachIntegrationRequestCWProxy {
  const _$AttachIntegrationRequestCWProxyImpl(this._value);

  final AttachIntegrationRequest _value;

  @override
  AttachIntegrationRequest integrationId(String integrationId) =>
      this(integrationId: integrationId);

  @override
  AttachIntegrationRequest toolAllowlist(List<String>? toolAllowlist) =>
      this(toolAllowlist: toolAllowlist);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AttachIntegrationRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AttachIntegrationRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  AttachIntegrationRequest call({
    Object? integrationId = const $CopyWithPlaceholder(),
    Object? toolAllowlist = const $CopyWithPlaceholder(),
  }) {
    return AttachIntegrationRequest(
      integrationId: integrationId == const $CopyWithPlaceholder()
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
  /// Returns a callable class that can be used as follows: `instanceOfAttachIntegrationRequest.copyWith(...)` or like so:`instanceOfAttachIntegrationRequest.copyWith.fieldName(...)`.
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
