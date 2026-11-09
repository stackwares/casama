// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'me.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MeCWProxy {
  Me userId(String userId);

  Me email(String? email);

  Me displayName(String? displayName);

  Me locale(String locale);

  Me timezone(String timezone);

  Me organizations(List<OrganizationWithRole> organizations);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Me(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Me(...).copyWith(id: 12, name: "My name")
  /// ````
  Me call({
    String userId,
    String? email,
    String? displayName,
    String locale,
    String timezone,
    List<OrganizationWithRole> organizations,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfMe.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfMe.copyWith.fieldName(...)`
class _$MeCWProxyImpl implements _$MeCWProxy {
  const _$MeCWProxyImpl(this._value);

  final Me _value;

  @override
  Me userId(String userId) => this(userId: userId);

  @override
  Me email(String? email) => this(email: email);

  @override
  Me displayName(String? displayName) => this(displayName: displayName);

  @override
  Me locale(String locale) => this(locale: locale);

  @override
  Me timezone(String timezone) => this(timezone: timezone);

  @override
  Me organizations(List<OrganizationWithRole> organizations) =>
      this(organizations: organizations);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Me(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Me(...).copyWith(id: 12, name: "My name")
  /// ````
  Me call({
    Object? userId = const $CopyWithPlaceholder(),
    Object? email = const $CopyWithPlaceholder(),
    Object? displayName = const $CopyWithPlaceholder(),
    Object? locale = const $CopyWithPlaceholder(),
    Object? timezone = const $CopyWithPlaceholder(),
    Object? organizations = const $CopyWithPlaceholder(),
  }) {
    return Me(
      userId: userId == const $CopyWithPlaceholder()
          ? _value.userId
          // ignore: cast_nullable_to_non_nullable
          : userId as String,
      email: email == const $CopyWithPlaceholder()
          ? _value.email
          // ignore: cast_nullable_to_non_nullable
          : email as String?,
      displayName: displayName == const $CopyWithPlaceholder()
          ? _value.displayName
          // ignore: cast_nullable_to_non_nullable
          : displayName as String?,
      locale: locale == const $CopyWithPlaceholder()
          ? _value.locale
          // ignore: cast_nullable_to_non_nullable
          : locale as String,
      timezone: timezone == const $CopyWithPlaceholder()
          ? _value.timezone
          // ignore: cast_nullable_to_non_nullable
          : timezone as String,
      organizations: organizations == const $CopyWithPlaceholder()
          ? _value.organizations
          // ignore: cast_nullable_to_non_nullable
          : organizations as List<OrganizationWithRole>,
    );
  }
}

extension $MeCopyWith on Me {
  /// Returns a callable class that can be used as follows: `instanceOfMe.copyWith(...)` or like so:`instanceOfMe.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MeCWProxy get copyWith => _$MeCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Me _$MeFromJson(Map<String, dynamic> json) => $checkedCreate('Me', json, (
  $checkedConvert,
) {
  $checkKeys(
    json,
    requiredKeys: const [
      'user_id',
      'email',
      'display_name',
      'locale',
      'timezone',
      'organizations',
    ],
  );
  final val = Me(
    userId: $checkedConvert('user_id', (v) => v as String),
    email: $checkedConvert('email', (v) => v as String?),
    displayName: $checkedConvert('display_name', (v) => v as String?),
    locale: $checkedConvert('locale', (v) => v as String),
    timezone: $checkedConvert('timezone', (v) => v as String),
    organizations: $checkedConvert(
      'organizations',
      (v) => (v as List<dynamic>)
          .map((e) => OrganizationWithRole.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );
  return val;
}, fieldKeyMap: const {'userId': 'user_id', 'displayName': 'display_name'});

Map<String, dynamic> _$MeToJson(Me instance) => <String, dynamic>{
  'user_id': instance.userId,
  'email': instance.email,
  'display_name': instance.displayName,
  'locale': instance.locale,
  'timezone': instance.timezone,
  'organizations': instance.organizations.map((e) => e.toJson()).toList(),
};
