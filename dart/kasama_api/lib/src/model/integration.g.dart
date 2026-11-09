// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'integration.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$IntegrationCWProxy {
  Integration id(String id);

  Integration orgId(String orgId);

  Integration kind(IntegrationKind kind);

  Integration name(String name);

  Integration status(IntegrationStatusEnum status);

  Integration error(String? error);

  Integration tools(List<IntegrationToolsInner> tools);

  Integration toolsCachedAt(DateTime? toolsCachedAt);

  Integration createdAt(DateTime createdAt);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Integration(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Integration(...).copyWith(id: 12, name: "My name")
  /// ````
  Integration call({
    String id,
    String orgId,
    IntegrationKind kind,
    String name,
    IntegrationStatusEnum status,
    String? error,
    List<IntegrationToolsInner> tools,
    DateTime? toolsCachedAt,
    DateTime createdAt,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfIntegration.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfIntegration.copyWith.fieldName(...)`
class _$IntegrationCWProxyImpl implements _$IntegrationCWProxy {
  const _$IntegrationCWProxyImpl(this._value);

  final Integration _value;

  @override
  Integration id(String id) => this(id: id);

  @override
  Integration orgId(String orgId) => this(orgId: orgId);

  @override
  Integration kind(IntegrationKind kind) => this(kind: kind);

  @override
  Integration name(String name) => this(name: name);

  @override
  Integration status(IntegrationStatusEnum status) => this(status: status);

  @override
  Integration error(String? error) => this(error: error);

  @override
  Integration tools(List<IntegrationToolsInner> tools) => this(tools: tools);

  @override
  Integration toolsCachedAt(DateTime? toolsCachedAt) =>
      this(toolsCachedAt: toolsCachedAt);

  @override
  Integration createdAt(DateTime createdAt) => this(createdAt: createdAt);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Integration(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Integration(...).copyWith(id: 12, name: "My name")
  /// ````
  Integration call({
    Object? id = const $CopyWithPlaceholder(),
    Object? orgId = const $CopyWithPlaceholder(),
    Object? kind = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? error = const $CopyWithPlaceholder(),
    Object? tools = const $CopyWithPlaceholder(),
    Object? toolsCachedAt = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return Integration(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      orgId: orgId == const $CopyWithPlaceholder()
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
      kind: kind == const $CopyWithPlaceholder()
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as IntegrationKind,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as IntegrationStatusEnum,
      error: error == const $CopyWithPlaceholder()
          ? _value.error
          // ignore: cast_nullable_to_non_nullable
          : error as String?,
      tools: tools == const $CopyWithPlaceholder()
          ? _value.tools
          // ignore: cast_nullable_to_non_nullable
          : tools as List<IntegrationToolsInner>,
      toolsCachedAt: toolsCachedAt == const $CopyWithPlaceholder()
          ? _value.toolsCachedAt
          // ignore: cast_nullable_to_non_nullable
          : toolsCachedAt as DateTime?,
      createdAt: createdAt == const $CopyWithPlaceholder()
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $IntegrationCopyWith on Integration {
  /// Returns a callable class that can be used as follows: `instanceOfIntegration.copyWith(...)` or like so:`instanceOfIntegration.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$IntegrationCWProxy get copyWith => _$IntegrationCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Integration _$IntegrationFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Integration',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'org_id',
        'kind',
        'name',
        'status',
        'error',
        'tools',
        'tools_cached_at',
        'created_at',
      ],
    );
    final val = Integration(
      id: $checkedConvert('id', (v) => v as String),
      orgId: $checkedConvert('org_id', (v) => v as String),
      kind: $checkedConvert(
        'kind',
        (v) => $enumDecode(_$IntegrationKindEnumMap, v),
      ),
      name: $checkedConvert('name', (v) => v as String),
      status: $checkedConvert(
        'status',
        (v) => $enumDecode(_$IntegrationStatusEnumEnumMap, v),
      ),
      error: $checkedConvert('error', (v) => v as String?),
      tools: $checkedConvert(
        'tools',
        (v) => (v as List<dynamic>)
            .map(
              (e) => IntegrationToolsInner.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
      ),
      toolsCachedAt: $checkedConvert(
        'tools_cached_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'orgId': 'org_id',
    'toolsCachedAt': 'tools_cached_at',
    'createdAt': 'created_at',
  },
);

Map<String, dynamic> _$IntegrationToJson(Integration instance) =>
    <String, dynamic>{
      'id': instance.id,
      'org_id': instance.orgId,
      'kind': _$IntegrationKindEnumMap[instance.kind]!,
      'name': instance.name,
      'status': _$IntegrationStatusEnumEnumMap[instance.status]!,
      'error': instance.error,
      'tools': instance.tools.map((e) => e.toJson()).toList(),
      'tools_cached_at': instance.toolsCachedAt?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$IntegrationKindEnumMap = {
  IntegrationKind.mcp: 'mcp',
  IntegrationKind.openapi: 'openapi',
  IntegrationKind.composio: 'composio',
  IntegrationKind.pipedream: 'pipedream',
};

const _$IntegrationStatusEnumEnumMap = {
  IntegrationStatusEnum.pending: 'pending',
  IntegrationStatusEnum.ok: 'ok',
  IntegrationStatusEnum.error: 'error',
};
