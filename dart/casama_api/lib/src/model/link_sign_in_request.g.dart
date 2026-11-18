// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'link_sign_in_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$LinkSignInRequestCWProxy {
  LinkSignInRequest userCode(String userCode);

  LinkSignInRequest instanceName(String instanceName);

  LinkSignInRequest platform(String? platform);

  LinkSignInRequest version(String? version);

  LinkSignInRequest approved(bool approved);

  LinkSignInRequest expiresAt(DateTime expiresAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `LinkSignInRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// LinkSignInRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  LinkSignInRequest call({
    String userCode,
    String instanceName,
    String? platform,
    String? version,
    bool approved,
    DateTime expiresAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfLinkSignInRequest.copyWith(...)` or call `instanceOfLinkSignInRequest.copyWith.fieldName(value)` for a single field.
class _$LinkSignInRequestCWProxyImpl implements _$LinkSignInRequestCWProxy {
  const _$LinkSignInRequestCWProxyImpl(this._value);

  final LinkSignInRequest _value;

  @override
  LinkSignInRequest userCode(String userCode) => call(userCode: userCode);

  @override
  LinkSignInRequest instanceName(String instanceName) =>
      call(instanceName: instanceName);

  @override
  LinkSignInRequest platform(String? platform) => call(platform: platform);

  @override
  LinkSignInRequest version(String? version) => call(version: version);

  @override
  LinkSignInRequest approved(bool approved) => call(approved: approved);

  @override
  LinkSignInRequest expiresAt(DateTime expiresAt) => call(expiresAt: expiresAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `LinkSignInRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// LinkSignInRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  LinkSignInRequest call({
    Object? userCode = const $CopyWithPlaceholder(),
    Object? instanceName = const $CopyWithPlaceholder(),
    Object? platform = const $CopyWithPlaceholder(),
    Object? version = const $CopyWithPlaceholder(),
    Object? approved = const $CopyWithPlaceholder(),
    Object? expiresAt = const $CopyWithPlaceholder(),
  }) {
    return LinkSignInRequest(
      userCode: userCode == const $CopyWithPlaceholder() || userCode == null
          ? _value.userCode
          // ignore: cast_nullable_to_non_nullable
          : userCode as String,
      instanceName:
          instanceName == const $CopyWithPlaceholder() || instanceName == null
          ? _value.instanceName
          // ignore: cast_nullable_to_non_nullable
          : instanceName as String,
      platform: platform == const $CopyWithPlaceholder()
          ? _value.platform
          // ignore: cast_nullable_to_non_nullable
          : platform as String?,
      version: version == const $CopyWithPlaceholder()
          ? _value.version
          // ignore: cast_nullable_to_non_nullable
          : version as String?,
      approved: approved == const $CopyWithPlaceholder() || approved == null
          ? _value.approved
          // ignore: cast_nullable_to_non_nullable
          : approved as bool,
      expiresAt: expiresAt == const $CopyWithPlaceholder() || expiresAt == null
          ? _value.expiresAt
          // ignore: cast_nullable_to_non_nullable
          : expiresAt as DateTime,
    );
  }
}

extension $LinkSignInRequestCopyWith on LinkSignInRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfLinkSignInRequest.copyWith(...)` or `instanceOfLinkSignInRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$LinkSignInRequestCWProxy get copyWith =>
      _$LinkSignInRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LinkSignInRequest _$LinkSignInRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'LinkSignInRequest',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'user_code',
            'instance_name',
            'platform',
            'version',
            'approved',
            'expires_at',
          ],
        );
        final val = LinkSignInRequest(
          userCode: $checkedConvert('user_code', (v) => v as String),
          instanceName: $checkedConvert('instance_name', (v) => v as String),
          platform: $checkedConvert('platform', (v) => v as String?),
          version: $checkedConvert('version', (v) => v as String?),
          approved: $checkedConvert('approved', (v) => v as bool),
          expiresAt: $checkedConvert(
            'expires_at',
            (v) => DateTime.parse(v as String),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'userCode': 'user_code',
        'instanceName': 'instance_name',
        'expiresAt': 'expires_at',
      },
    );

Map<String, dynamic> _$LinkSignInRequestToJson(LinkSignInRequest instance) =>
    <String, dynamic>{
      'user_code': instance.userCode,
      'instance_name': instance.instanceName,
      'platform': instance.platform,
      'version': instance.version,
      'approved': instance.approved,
      'expires_at': instance.expiresAt.toIso8601String(),
    };
