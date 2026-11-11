// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memory_backend.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MemoryBackendCWProxy {
  MemoryBackend provider(MemoryBackendProviderEnum provider);

  MemoryBackend baseUrl(String? baseUrl);

  MemoryBackend workspace(String? workspace);

  MemoryBackend updatedAt(DateTime? updatedAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `MemoryBackend(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// MemoryBackend(...).copyWith(id: 12, name: "My name")
  /// ```
  MemoryBackend call({
    MemoryBackendProviderEnum provider,
    String? baseUrl,
    String? workspace,
    DateTime? updatedAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfMemoryBackend.copyWith(...)` or call `instanceOfMemoryBackend.copyWith.fieldName(value)` for a single field.
class _$MemoryBackendCWProxyImpl implements _$MemoryBackendCWProxy {
  const _$MemoryBackendCWProxyImpl(this._value);

  final MemoryBackend _value;

  @override
  MemoryBackend provider(MemoryBackendProviderEnum provider) =>
      call(provider: provider);

  @override
  MemoryBackend baseUrl(String? baseUrl) => call(baseUrl: baseUrl);

  @override
  MemoryBackend workspace(String? workspace) => call(workspace: workspace);

  @override
  MemoryBackend updatedAt(DateTime? updatedAt) => call(updatedAt: updatedAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `MemoryBackend(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// MemoryBackend(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  MemoryBackend call({
    Object? provider = const $CopyWithPlaceholder(),
    Object? baseUrl = const $CopyWithPlaceholder(),
    Object? workspace = const $CopyWithPlaceholder(),
    Object? updatedAt = const $CopyWithPlaceholder(),
  }) {
    return MemoryBackend(
      provider: provider == const $CopyWithPlaceholder() || provider == null
          ? _value.provider
          // ignore: cast_nullable_to_non_nullable
          : provider as MemoryBackendProviderEnum,
      baseUrl: baseUrl == const $CopyWithPlaceholder()
          ? _value.baseUrl
          // ignore: cast_nullable_to_non_nullable
          : baseUrl as String?,
      workspace: workspace == const $CopyWithPlaceholder()
          ? _value.workspace
          // ignore: cast_nullable_to_non_nullable
          : workspace as String?,
      updatedAt: updatedAt == const $CopyWithPlaceholder()
          ? _value.updatedAt
          // ignore: cast_nullable_to_non_nullable
          : updatedAt as DateTime?,
    );
  }
}

extension $MemoryBackendCopyWith on MemoryBackend {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfMemoryBackend.copyWith(...)` or `instanceOfMemoryBackend.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MemoryBackendCWProxy get copyWith => _$MemoryBackendCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MemoryBackend _$MemoryBackendFromJson(Map<String, dynamic> json) =>
    $checkedCreate('MemoryBackend', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['provider', 'base_url', 'workspace', 'updated_at'],
      );
      final val = MemoryBackend(
        provider: $checkedConvert(
          'provider',
          (v) => $enumDecode(_$MemoryBackendProviderEnumEnumMap, v),
        ),
        baseUrl: $checkedConvert('base_url', (v) => v as String?),
        workspace: $checkedConvert('workspace', (v) => v as String?),
        updatedAt: $checkedConvert(
          'updated_at',
          (v) => v == null ? null : DateTime.parse(v as String),
        ),
      );
      return val;
    }, fieldKeyMap: const {'baseUrl': 'base_url', 'updatedAt': 'updated_at'});

Map<String, dynamic> _$MemoryBackendToJson(MemoryBackend instance) =>
    <String, dynamic>{
      'provider': _$MemoryBackendProviderEnumEnumMap[instance.provider]!,
      'base_url': instance.baseUrl,
      'workspace': instance.workspace,
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

const _$MemoryBackendProviderEnumEnumMap = {
  MemoryBackendProviderEnum.postgres: 'postgres',
  MemoryBackendProviderEnum.honcho: 'honcho',
  MemoryBackendProviderEnum.supermemory: 'supermemory',
};
