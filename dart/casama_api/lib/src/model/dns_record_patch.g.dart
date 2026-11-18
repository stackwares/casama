// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dns_record_patch.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DnsRecordPatchCWProxy {
  DnsRecordPatch host(String? host);

  DnsRecordPatch type(String? type);

  DnsRecordPatch answer(String? answer);

  DnsRecordPatch ttl(int? ttl);

  DnsRecordPatch priority(int? priority);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DnsRecordPatch(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DnsRecordPatch(...).copyWith(id: 12, name: "My name")
  /// ```
  DnsRecordPatch call({
    String? host,
    String? type,
    String? answer,
    int? ttl,
    int? priority,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDnsRecordPatch.copyWith(...)` or call `instanceOfDnsRecordPatch.copyWith.fieldName(value)` for a single field.
class _$DnsRecordPatchCWProxyImpl implements _$DnsRecordPatchCWProxy {
  const _$DnsRecordPatchCWProxyImpl(this._value);

  final DnsRecordPatch _value;

  @override
  DnsRecordPatch host(String? host) => call(host: host);

  @override
  DnsRecordPatch type(String? type) => call(type: type);

  @override
  DnsRecordPatch answer(String? answer) => call(answer: answer);

  @override
  DnsRecordPatch ttl(int? ttl) => call(ttl: ttl);

  @override
  DnsRecordPatch priority(int? priority) => call(priority: priority);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DnsRecordPatch(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DnsRecordPatch(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DnsRecordPatch call({
    Object? host = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
    Object? answer = const $CopyWithPlaceholder(),
    Object? ttl = const $CopyWithPlaceholder(),
    Object? priority = const $CopyWithPlaceholder(),
  }) {
    return DnsRecordPatch(
      host: host == const $CopyWithPlaceholder()
          ? _value.host
          // ignore: cast_nullable_to_non_nullable
          : host as String?,
      type: type == const $CopyWithPlaceholder()
          ? _value.type
          // ignore: cast_nullable_to_non_nullable
          : type as String?,
      answer: answer == const $CopyWithPlaceholder()
          ? _value.answer
          // ignore: cast_nullable_to_non_nullable
          : answer as String?,
      ttl: ttl == const $CopyWithPlaceholder()
          ? _value.ttl
          // ignore: cast_nullable_to_non_nullable
          : ttl as int?,
      priority: priority == const $CopyWithPlaceholder()
          ? _value.priority
          // ignore: cast_nullable_to_non_nullable
          : priority as int?,
    );
  }
}

extension $DnsRecordPatchCopyWith on DnsRecordPatch {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDnsRecordPatch.copyWith(...)` or `instanceOfDnsRecordPatch.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DnsRecordPatchCWProxy get copyWith => _$DnsRecordPatchCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DnsRecordPatch _$DnsRecordPatchFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DnsRecordPatch', json, ($checkedConvert) {
      final val = DnsRecordPatch(
        host: $checkedConvert('host', (v) => v as String?),
        type: $checkedConvert('type', (v) => v as String?),
        answer: $checkedConvert('answer', (v) => v as String?),
        ttl: $checkedConvert('ttl', (v) => (v as num?)?.toInt() ?? 300),
        priority: $checkedConvert('priority', (v) => (v as num?)?.toInt()),
      );
      return val;
    });

Map<String, dynamic> _$DnsRecordPatchToJson(DnsRecordPatch instance) =>
    <String, dynamic>{
      'host': ?instance.host,
      'type': ?instance.type,
      'answer': ?instance.answer,
      'ttl': ?instance.ttl,
      'priority': ?instance.priority,
    };
