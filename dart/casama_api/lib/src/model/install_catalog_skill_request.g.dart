// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'install_catalog_skill_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$InstallCatalogSkillRequestCWProxy {
  InstallCatalogSkillRequest orgId(String orgId);

  InstallCatalogSkillRequest botId(String? botId);

  InstallCatalogSkillRequest catalogId(String catalogId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `InstallCatalogSkillRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// InstallCatalogSkillRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  InstallCatalogSkillRequest call({
    String orgId,
    String? botId,
    String catalogId,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfInstallCatalogSkillRequest.copyWith(...)` or call `instanceOfInstallCatalogSkillRequest.copyWith.fieldName(value)` for a single field.
class _$InstallCatalogSkillRequestCWProxyImpl
    implements _$InstallCatalogSkillRequestCWProxy {
  const _$InstallCatalogSkillRequestCWProxyImpl(this._value);

  final InstallCatalogSkillRequest _value;

  @override
  InstallCatalogSkillRequest orgId(String orgId) => call(orgId: orgId);

  @override
  InstallCatalogSkillRequest botId(String? botId) => call(botId: botId);

  @override
  InstallCatalogSkillRequest catalogId(String catalogId) =>
      call(catalogId: catalogId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `InstallCatalogSkillRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// InstallCatalogSkillRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  InstallCatalogSkillRequest call({
    Object? orgId = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? catalogId = const $CopyWithPlaceholder(),
  }) {
    return InstallCatalogSkillRequest(
      orgId: orgId == const $CopyWithPlaceholder() || orgId == null
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
      botId: botId == const $CopyWithPlaceholder()
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String?,
      catalogId: catalogId == const $CopyWithPlaceholder() || catalogId == null
          ? _value.catalogId
          // ignore: cast_nullable_to_non_nullable
          : catalogId as String,
    );
  }
}

extension $InstallCatalogSkillRequestCopyWith on InstallCatalogSkillRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfInstallCatalogSkillRequest.copyWith(...)` or `instanceOfInstallCatalogSkillRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$InstallCatalogSkillRequestCWProxy get copyWith =>
      _$InstallCatalogSkillRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InstallCatalogSkillRequest _$InstallCatalogSkillRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'InstallCatalogSkillRequest',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['org_id', 'catalog_id']);
    final val = InstallCatalogSkillRequest(
      orgId: $checkedConvert('org_id', (v) => v as String),
      botId: $checkedConvert('bot_id', (v) => v as String?),
      catalogId: $checkedConvert('catalog_id', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {
    'orgId': 'org_id',
    'botId': 'bot_id',
    'catalogId': 'catalog_id',
  },
);

Map<String, dynamic> _$InstallCatalogSkillRequestToJson(
  InstallCatalogSkillRequest instance,
) => <String, dynamic>{
  'org_id': instance.orgId,
  'bot_id': ?instance.botId,
  'catalog_id': instance.catalogId,
};
