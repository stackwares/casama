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

  Integration appId(String? appId);

  Integration auth(IntegrationAuthEnum? auth);

  Integration botIds(List<String>? botIds);

  Integration riskOverrides(Map<String, Risk>? riskOverrides);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Integration(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Integration(...).copyWith(id: 12, name: "My name")
  /// ```
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
    String? appId,
    IntegrationAuthEnum? auth,
    List<String>? botIds,
    Map<String, Risk>? riskOverrides,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfIntegration.copyWith(...)` or call `instanceOfIntegration.copyWith.fieldName(value)` for a single field.
class _$IntegrationCWProxyImpl implements _$IntegrationCWProxy {
  const _$IntegrationCWProxyImpl(this._value);

  final Integration _value;

  @override
  Integration id(String id) => call(id: id);

  @override
  Integration orgId(String orgId) => call(orgId: orgId);

  @override
  Integration kind(IntegrationKind kind) => call(kind: kind);

  @override
  Integration name(String name) => call(name: name);

  @override
  Integration status(IntegrationStatusEnum status) => call(status: status);

  @override
  Integration error(String? error) => call(error: error);

  @override
  Integration tools(List<IntegrationToolsInner> tools) => call(tools: tools);

  @override
  Integration toolsCachedAt(DateTime? toolsCachedAt) =>
      call(toolsCachedAt: toolsCachedAt);

  @override
  Integration createdAt(DateTime createdAt) => call(createdAt: createdAt);

  @override
  Integration appId(String? appId) => call(appId: appId);

  @override
  Integration auth(IntegrationAuthEnum? auth) => call(auth: auth);

  @override
  Integration botIds(List<String>? botIds) => call(botIds: botIds);

  @override
  Integration riskOverrides(Map<String, Risk>? riskOverrides) =>
      call(riskOverrides: riskOverrides);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Integration(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Integration(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
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
    Object? appId = const $CopyWithPlaceholder(),
    Object? auth = const $CopyWithPlaceholder(),
    Object? botIds = const $CopyWithPlaceholder(),
    Object? riskOverrides = const $CopyWithPlaceholder(),
  }) {
    return Integration(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      orgId: orgId == const $CopyWithPlaceholder() || orgId == null
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
      kind: kind == const $CopyWithPlaceholder() || kind == null
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as IntegrationKind,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as IntegrationStatusEnum,
      error: error == const $CopyWithPlaceholder()
          ? _value.error
          // ignore: cast_nullable_to_non_nullable
          : error as String?,
      tools: tools == const $CopyWithPlaceholder() || tools == null
          ? _value.tools
          // ignore: cast_nullable_to_non_nullable
          : tools as List<IntegrationToolsInner>,
      toolsCachedAt: toolsCachedAt == const $CopyWithPlaceholder()
          ? _value.toolsCachedAt
          // ignore: cast_nullable_to_non_nullable
          : toolsCachedAt as DateTime?,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
      appId: appId == const $CopyWithPlaceholder()
          ? _value.appId
          // ignore: cast_nullable_to_non_nullable
          : appId as String?,
      auth: auth == const $CopyWithPlaceholder()
          ? _value.auth
          // ignore: cast_nullable_to_non_nullable
          : auth as IntegrationAuthEnum?,
      botIds: botIds == const $CopyWithPlaceholder()
          ? _value.botIds
          // ignore: cast_nullable_to_non_nullable
          : botIds as List<String>?,
      riskOverrides: riskOverrides == const $CopyWithPlaceholder()
          ? _value.riskOverrides
          // ignore: cast_nullable_to_non_nullable
          : riskOverrides as Map<String, Risk>?,
    );
  }
}

extension $IntegrationCopyWith on Integration {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfIntegration.copyWith(...)` or `instanceOfIntegration.copyWith.fieldName(...)`.
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
      appId: $checkedConvert('app_id', (v) => v as String?),
      auth: $checkedConvert(
        'auth',
        (v) => $enumDecodeNullable(_$IntegrationAuthEnumEnumMap, v),
      ),
      botIds: $checkedConvert(
        'bot_ids',
        (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
      ),
      riskOverrides: $checkedConvert(
        'risk_overrides',
        (v) => (v as Map<String, dynamic>?)?.map(
          (k, e) => MapEntry(k, $enumDecode(_$RiskEnumMap, e)),
        ),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'orgId': 'org_id',
    'toolsCachedAt': 'tools_cached_at',
    'createdAt': 'created_at',
    'appId': 'app_id',
    'botIds': 'bot_ids',
    'riskOverrides': 'risk_overrides',
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
      'app_id': ?instance.appId,
      'auth': ?_$IntegrationAuthEnumEnumMap[instance.auth],
      'bot_ids': ?instance.botIds,
      'risk_overrides': ?instance.riskOverrides?.map(
        (k, e) => MapEntry(k, _$RiskEnumMap[e]!),
      ),
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

const _$IntegrationAuthEnumEnumMap = {
  IntegrationAuthEnum.oauth: 'oauth',
  IntegrationAuthEnum.apiKey: 'api_key',
  IntegrationAuthEnum.none: 'none',
};

const _$RiskEnumMap = {
  Risk.low: 'low',
  Risk.medium: 'medium',
  Risk.high: 'high',
};
