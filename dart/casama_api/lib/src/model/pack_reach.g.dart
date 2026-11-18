// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pack_reach.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PackReachCWProxy {
  PackReach runsCode(bool runsCode);

  PackReach computer(bool computer);

  PackReach hosts(List<String> hosts);

  PackReach secrets(List<String> secrets);

  PackReach settings(List<String> settings);

  PackReach runsPerWeek(num runsPerWeek);

  PackReach computers(int computers);

  PackReach knowledgeSources(int? knowledgeSources);

  PackReach knowledgePages(int? knowledgePages);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PackReach(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PackReach(...).copyWith(id: 12, name: "My name")
  /// ```
  PackReach call({
    bool runsCode,
    bool computer,
    List<String> hosts,
    List<String> secrets,
    List<String> settings,
    num runsPerWeek,
    int computers,
    int? knowledgeSources,
    int? knowledgePages,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPackReach.copyWith(...)` or call `instanceOfPackReach.copyWith.fieldName(value)` for a single field.
class _$PackReachCWProxyImpl implements _$PackReachCWProxy {
  const _$PackReachCWProxyImpl(this._value);

  final PackReach _value;

  @override
  PackReach runsCode(bool runsCode) => call(runsCode: runsCode);

  @override
  PackReach computer(bool computer) => call(computer: computer);

  @override
  PackReach hosts(List<String> hosts) => call(hosts: hosts);

  @override
  PackReach secrets(List<String> secrets) => call(secrets: secrets);

  @override
  PackReach settings(List<String> settings) => call(settings: settings);

  @override
  PackReach runsPerWeek(num runsPerWeek) => call(runsPerWeek: runsPerWeek);

  @override
  PackReach computers(int computers) => call(computers: computers);

  @override
  PackReach knowledgeSources(int? knowledgeSources) =>
      call(knowledgeSources: knowledgeSources);

  @override
  PackReach knowledgePages(int? knowledgePages) =>
      call(knowledgePages: knowledgePages);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PackReach(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PackReach(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PackReach call({
    Object? runsCode = const $CopyWithPlaceholder(),
    Object? computer = const $CopyWithPlaceholder(),
    Object? hosts = const $CopyWithPlaceholder(),
    Object? secrets = const $CopyWithPlaceholder(),
    Object? settings = const $CopyWithPlaceholder(),
    Object? runsPerWeek = const $CopyWithPlaceholder(),
    Object? computers = const $CopyWithPlaceholder(),
    Object? knowledgeSources = const $CopyWithPlaceholder(),
    Object? knowledgePages = const $CopyWithPlaceholder(),
  }) {
    return PackReach(
      runsCode: runsCode == const $CopyWithPlaceholder() || runsCode == null
          ? _value.runsCode
          // ignore: cast_nullable_to_non_nullable
          : runsCode as bool,
      computer: computer == const $CopyWithPlaceholder() || computer == null
          ? _value.computer
          // ignore: cast_nullable_to_non_nullable
          : computer as bool,
      hosts: hosts == const $CopyWithPlaceholder() || hosts == null
          ? _value.hosts
          // ignore: cast_nullable_to_non_nullable
          : hosts as List<String>,
      secrets: secrets == const $CopyWithPlaceholder() || secrets == null
          ? _value.secrets
          // ignore: cast_nullable_to_non_nullable
          : secrets as List<String>,
      settings: settings == const $CopyWithPlaceholder() || settings == null
          ? _value.settings
          // ignore: cast_nullable_to_non_nullable
          : settings as List<String>,
      runsPerWeek:
          runsPerWeek == const $CopyWithPlaceholder() || runsPerWeek == null
          ? _value.runsPerWeek
          // ignore: cast_nullable_to_non_nullable
          : runsPerWeek as num,
      computers: computers == const $CopyWithPlaceholder() || computers == null
          ? _value.computers
          // ignore: cast_nullable_to_non_nullable
          : computers as int,
      knowledgeSources: knowledgeSources == const $CopyWithPlaceholder()
          ? _value.knowledgeSources
          // ignore: cast_nullable_to_non_nullable
          : knowledgeSources as int?,
      knowledgePages: knowledgePages == const $CopyWithPlaceholder()
          ? _value.knowledgePages
          // ignore: cast_nullable_to_non_nullable
          : knowledgePages as int?,
    );
  }
}

extension $PackReachCopyWith on PackReach {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPackReach.copyWith(...)` or `instanceOfPackReach.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PackReachCWProxy get copyWith => _$PackReachCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PackReach _$PackReachFromJson(Map<String, dynamic> json) => $checkedCreate(
  'PackReach',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'runs_code',
        'computer',
        'hosts',
        'secrets',
        'settings',
        'runs_per_week',
        'computers',
      ],
    );
    final val = PackReach(
      runsCode: $checkedConvert('runs_code', (v) => v as bool),
      computer: $checkedConvert('computer', (v) => v as bool),
      hosts: $checkedConvert(
        'hosts',
        (v) => (v as List<dynamic>).map((e) => e as String).toList(),
      ),
      secrets: $checkedConvert(
        'secrets',
        (v) => (v as List<dynamic>).map((e) => e as String).toList(),
      ),
      settings: $checkedConvert(
        'settings',
        (v) => (v as List<dynamic>).map((e) => e as String).toList(),
      ),
      runsPerWeek: $checkedConvert('runs_per_week', (v) => v as num),
      computers: $checkedConvert('computers', (v) => (v as num).toInt()),
      knowledgeSources: $checkedConvert(
        'knowledge_sources',
        (v) => (v as num?)?.toInt(),
      ),
      knowledgePages: $checkedConvert(
        'knowledge_pages',
        (v) => (v as num?)?.toInt(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'runsCode': 'runs_code',
    'runsPerWeek': 'runs_per_week',
    'knowledgeSources': 'knowledge_sources',
    'knowledgePages': 'knowledge_pages',
  },
);

Map<String, dynamic> _$PackReachToJson(PackReach instance) => <String, dynamic>{
  'runs_code': instance.runsCode,
  'computer': instance.computer,
  'hosts': instance.hosts,
  'secrets': instance.secrets,
  'settings': instance.settings,
  'runs_per_week': instance.runsPerWeek,
  'computers': instance.computers,
  'knowledge_sources': ?instance.knowledgeSources,
  'knowledge_pages': ?instance.knowledgePages,
};
