// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connect_domain_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ConnectDomainRequestCWProxy {
  ConnectDomainRequest name(String name);

  ConnectDomainRequest pageId(String? pageId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ConnectDomainRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ConnectDomainRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  ConnectDomainRequest call({String name, String? pageId});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfConnectDomainRequest.copyWith(...)` or call `instanceOfConnectDomainRequest.copyWith.fieldName(value)` for a single field.
class _$ConnectDomainRequestCWProxyImpl
    implements _$ConnectDomainRequestCWProxy {
  const _$ConnectDomainRequestCWProxyImpl(this._value);

  final ConnectDomainRequest _value;

  @override
  ConnectDomainRequest name(String name) => call(name: name);

  @override
  ConnectDomainRequest pageId(String? pageId) => call(pageId: pageId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ConnectDomainRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ConnectDomainRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ConnectDomainRequest call({
    Object? name = const $CopyWithPlaceholder(),
    Object? pageId = const $CopyWithPlaceholder(),
  }) {
    return ConnectDomainRequest(
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      pageId: pageId == const $CopyWithPlaceholder()
          ? _value.pageId
          // ignore: cast_nullable_to_non_nullable
          : pageId as String?,
    );
  }
}

extension $ConnectDomainRequestCopyWith on ConnectDomainRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfConnectDomainRequest.copyWith(...)` or `instanceOfConnectDomainRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ConnectDomainRequestCWProxy get copyWith =>
      _$ConnectDomainRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConnectDomainRequest _$ConnectDomainRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ConnectDomainRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['name']);
  final val = ConnectDomainRequest(
    name: $checkedConvert('name', (v) => v as String),
    pageId: $checkedConvert('page_id', (v) => v as String?),
  );
  return val;
}, fieldKeyMap: const {'pageId': 'page_id'});

Map<String, dynamic> _$ConnectDomainRequestToJson(
  ConnectDomainRequest instance,
) => <String, dynamic>{'name': instance.name, 'page_id': ?instance.pageId};
