// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'probe_server_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ProbeServerRequestCWProxy {
  ProbeServerRequest orgId(String orgId);

  ProbeServerRequest url(String url);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ProbeServerRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ProbeServerRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  ProbeServerRequest call({String orgId, String url});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfProbeServerRequest.copyWith(...)` or call `instanceOfProbeServerRequest.copyWith.fieldName(value)` for a single field.
class _$ProbeServerRequestCWProxyImpl implements _$ProbeServerRequestCWProxy {
  const _$ProbeServerRequestCWProxyImpl(this._value);

  final ProbeServerRequest _value;

  @override
  ProbeServerRequest orgId(String orgId) => call(orgId: orgId);

  @override
  ProbeServerRequest url(String url) => call(url: url);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ProbeServerRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ProbeServerRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ProbeServerRequest call({
    Object? orgId = const $CopyWithPlaceholder(),
    Object? url = const $CopyWithPlaceholder(),
  }) {
    return ProbeServerRequest(
      orgId: orgId == const $CopyWithPlaceholder() || orgId == null
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
      url: url == const $CopyWithPlaceholder() || url == null
          ? _value.url
          // ignore: cast_nullable_to_non_nullable
          : url as String,
    );
  }
}

extension $ProbeServerRequestCopyWith on ProbeServerRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfProbeServerRequest.copyWith(...)` or `instanceOfProbeServerRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ProbeServerRequestCWProxy get copyWith =>
      _$ProbeServerRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProbeServerRequest _$ProbeServerRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ProbeServerRequest', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['org_id', 'url']);
      final val = ProbeServerRequest(
        orgId: $checkedConvert('org_id', (v) => v as String),
        url: $checkedConvert('url', (v) => v as String),
      );
      return val;
    }, fieldKeyMap: const {'orgId': 'org_id'});

Map<String, dynamic> _$ProbeServerRequestToJson(ProbeServerRequest instance) =>
    <String, dynamic>{'org_id': instance.orgId, 'url': instance.url};
