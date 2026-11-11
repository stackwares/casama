// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_mcp_server_info.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$LocalMcpServerInfoCWProxy {
  LocalMcpServerInfo key(String key);

  LocalMcpServerInfo label(String label);

  LocalMcpServerInfo kind(LocalMcpServerInfoKindEnum kind);

  LocalMcpServerInfo summary(String summary);

  LocalMcpServerInfo timeoutS(int? timeoutS);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `LocalMcpServerInfo(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// LocalMcpServerInfo(...).copyWith(id: 12, name: "My name")
  /// ```
  LocalMcpServerInfo call({
    String key,
    String label,
    LocalMcpServerInfoKindEnum kind,
    String summary,
    int? timeoutS,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfLocalMcpServerInfo.copyWith(...)` or call `instanceOfLocalMcpServerInfo.copyWith.fieldName(value)` for a single field.
class _$LocalMcpServerInfoCWProxyImpl implements _$LocalMcpServerInfoCWProxy {
  const _$LocalMcpServerInfoCWProxyImpl(this._value);

  final LocalMcpServerInfo _value;

  @override
  LocalMcpServerInfo key(String key) => call(key: key);

  @override
  LocalMcpServerInfo label(String label) => call(label: label);

  @override
  LocalMcpServerInfo kind(LocalMcpServerInfoKindEnum kind) => call(kind: kind);

  @override
  LocalMcpServerInfo summary(String summary) => call(summary: summary);

  @override
  LocalMcpServerInfo timeoutS(int? timeoutS) => call(timeoutS: timeoutS);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `LocalMcpServerInfo(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// LocalMcpServerInfo(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  LocalMcpServerInfo call({
    Object? key = const $CopyWithPlaceholder(),
    Object? label = const $CopyWithPlaceholder(),
    Object? kind = const $CopyWithPlaceholder(),
    Object? summary = const $CopyWithPlaceholder(),
    Object? timeoutS = const $CopyWithPlaceholder(),
  }) {
    return LocalMcpServerInfo(
      key: key == const $CopyWithPlaceholder() || key == null
          ? _value.key
          // ignore: cast_nullable_to_non_nullable
          : key as String,
      label: label == const $CopyWithPlaceholder() || label == null
          ? _value.label
          // ignore: cast_nullable_to_non_nullable
          : label as String,
      kind: kind == const $CopyWithPlaceholder() || kind == null
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as LocalMcpServerInfoKindEnum,
      summary: summary == const $CopyWithPlaceholder() || summary == null
          ? _value.summary
          // ignore: cast_nullable_to_non_nullable
          : summary as String,
      timeoutS: timeoutS == const $CopyWithPlaceholder()
          ? _value.timeoutS
          // ignore: cast_nullable_to_non_nullable
          : timeoutS as int?,
    );
  }
}

extension $LocalMcpServerInfoCopyWith on LocalMcpServerInfo {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfLocalMcpServerInfo.copyWith(...)` or `instanceOfLocalMcpServerInfo.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$LocalMcpServerInfoCWProxy get copyWith =>
      _$LocalMcpServerInfoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LocalMcpServerInfo _$LocalMcpServerInfoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('LocalMcpServerInfo', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['key', 'label', 'kind', 'summary']);
      final val = LocalMcpServerInfo(
        key: $checkedConvert('key', (v) => v as String),
        label: $checkedConvert('label', (v) => v as String),
        kind: $checkedConvert(
          'kind',
          (v) => $enumDecode(_$LocalMcpServerInfoKindEnumEnumMap, v),
        ),
        summary: $checkedConvert('summary', (v) => v as String),
        timeoutS: $checkedConvert('timeout_s', (v) => (v as num?)?.toInt()),
      );
      return val;
    }, fieldKeyMap: const {'timeoutS': 'timeout_s'});

Map<String, dynamic> _$LocalMcpServerInfoToJson(LocalMcpServerInfo instance) =>
    <String, dynamic>{
      'key': instance.key,
      'label': instance.label,
      'kind': _$LocalMcpServerInfoKindEnumEnumMap[instance.kind]!,
      'summary': instance.summary,
      'timeout_s': ?instance.timeoutS,
    };

const _$LocalMcpServerInfoKindEnumEnumMap = {
  LocalMcpServerInfoKindEnum.stdio: 'stdio',
  LocalMcpServerInfoKindEnum.loopback: 'loopback',
};
