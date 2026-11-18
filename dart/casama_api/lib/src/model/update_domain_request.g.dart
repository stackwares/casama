// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_domain_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UpdateDomainRequestCWProxy {
  UpdateDomainRequest pageId(String? pageId);

  UpdateDomainRequest primaryHost(String? primaryHost);

  UpdateDomainRequest autoRenew(bool? autoRenew);

  UpdateDomainRequest locked(bool? locked);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UpdateDomainRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UpdateDomainRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  UpdateDomainRequest call({
    String? pageId,
    String? primaryHost,
    bool? autoRenew,
    bool? locked,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfUpdateDomainRequest.copyWith(...)` or call `instanceOfUpdateDomainRequest.copyWith.fieldName(value)` for a single field.
class _$UpdateDomainRequestCWProxyImpl implements _$UpdateDomainRequestCWProxy {
  const _$UpdateDomainRequestCWProxyImpl(this._value);

  final UpdateDomainRequest _value;

  @override
  UpdateDomainRequest pageId(String? pageId) => call(pageId: pageId);

  @override
  UpdateDomainRequest primaryHost(String? primaryHost) =>
      call(primaryHost: primaryHost);

  @override
  UpdateDomainRequest autoRenew(bool? autoRenew) => call(autoRenew: autoRenew);

  @override
  UpdateDomainRequest locked(bool? locked) => call(locked: locked);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UpdateDomainRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UpdateDomainRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  UpdateDomainRequest call({
    Object? pageId = const $CopyWithPlaceholder(),
    Object? primaryHost = const $CopyWithPlaceholder(),
    Object? autoRenew = const $CopyWithPlaceholder(),
    Object? locked = const $CopyWithPlaceholder(),
  }) {
    return UpdateDomainRequest(
      pageId: pageId == const $CopyWithPlaceholder()
          ? _value.pageId
          // ignore: cast_nullable_to_non_nullable
          : pageId as String?,
      primaryHost: primaryHost == const $CopyWithPlaceholder()
          ? _value.primaryHost
          // ignore: cast_nullable_to_non_nullable
          : primaryHost as String?,
      autoRenew: autoRenew == const $CopyWithPlaceholder()
          ? _value.autoRenew
          // ignore: cast_nullable_to_non_nullable
          : autoRenew as bool?,
      locked: locked == const $CopyWithPlaceholder()
          ? _value.locked
          // ignore: cast_nullable_to_non_nullable
          : locked as bool?,
    );
  }
}

extension $UpdateDomainRequestCopyWith on UpdateDomainRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfUpdateDomainRequest.copyWith(...)` or `instanceOfUpdateDomainRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$UpdateDomainRequestCWProxy get copyWith =>
      _$UpdateDomainRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateDomainRequest _$UpdateDomainRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'UpdateDomainRequest',
      json,
      ($checkedConvert) {
        final val = UpdateDomainRequest(
          pageId: $checkedConvert('page_id', (v) => v as String?),
          primaryHost: $checkedConvert('primary_host', (v) => v as String?),
          autoRenew: $checkedConvert('auto_renew', (v) => v as bool?),
          locked: $checkedConvert('locked', (v) => v as bool?),
        );
        return val;
      },
      fieldKeyMap: const {
        'pageId': 'page_id',
        'primaryHost': 'primary_host',
        'autoRenew': 'auto_renew',
      },
    );

Map<String, dynamic> _$UpdateDomainRequestToJson(
  UpdateDomainRequest instance,
) => <String, dynamic>{
  'page_id': ?instance.pageId,
  'primary_host': ?instance.primaryHost,
  'auto_renew': ?instance.autoRenew,
  'locked': ?instance.locked,
};
