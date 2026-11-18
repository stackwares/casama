// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dns_record_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DnsRecordInputCWProxy {
  DnsRecordInput host(String host);

  DnsRecordInput type(String type);

  DnsRecordInput answer(String answer);

  DnsRecordInput ttl(int? ttl);

  DnsRecordInput priority(int? priority);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DnsRecordInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DnsRecordInput(...).copyWith(id: 12, name: "My name")
  /// ```
  DnsRecordInput call({
    String host,
    String type,
    String answer,
    int? ttl,
    int? priority,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDnsRecordInput.copyWith(...)` or call `instanceOfDnsRecordInput.copyWith.fieldName(value)` for a single field.
class _$DnsRecordInputCWProxyImpl implements _$DnsRecordInputCWProxy {
  const _$DnsRecordInputCWProxyImpl(this._value);

  final DnsRecordInput _value;

  @override
  DnsRecordInput host(String host) => call(host: host);

  @override
  DnsRecordInput type(String type) => call(type: type);

  @override
  DnsRecordInput answer(String answer) => call(answer: answer);

  @override
  DnsRecordInput ttl(int? ttl) => call(ttl: ttl);

  @override
  DnsRecordInput priority(int? priority) => call(priority: priority);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DnsRecordInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DnsRecordInput(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DnsRecordInput call({
    Object? host = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
    Object? answer = const $CopyWithPlaceholder(),
    Object? ttl = const $CopyWithPlaceholder(),
    Object? priority = const $CopyWithPlaceholder(),
  }) {
    return DnsRecordInput(
      host: host == const $CopyWithPlaceholder() || host == null
          ? _value.host
          // ignore: cast_nullable_to_non_nullable
          : host as String,
      type: type == const $CopyWithPlaceholder() || type == null
          ? _value.type
          // ignore: cast_nullable_to_non_nullable
          : type as String,
      answer: answer == const $CopyWithPlaceholder() || answer == null
          ? _value.answer
          // ignore: cast_nullable_to_non_nullable
          : answer as String,
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

extension $DnsRecordInputCopyWith on DnsRecordInput {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDnsRecordInput.copyWith(...)` or `instanceOfDnsRecordInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DnsRecordInputCWProxy get copyWith => _$DnsRecordInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DnsRecordInput _$DnsRecordInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DnsRecordInput', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['host', 'type', 'answer']);
      final val = DnsRecordInput(
        host: $checkedConvert('host', (v) => v as String),
        type: $checkedConvert('type', (v) => v as String),
        answer: $checkedConvert('answer', (v) => v as String),
        ttl: $checkedConvert('ttl', (v) => (v as num?)?.toInt() ?? 300),
        priority: $checkedConvert('priority', (v) => (v as num?)?.toInt()),
      );
      return val;
    });

Map<String, dynamic> _$DnsRecordInputToJson(DnsRecordInput instance) =>
    <String, dynamic>{
      'host': instance.host,
      'type': instance.type,
      'answer': instance.answer,
      'ttl': ?instance.ttl,
      'priority': ?instance.priority,
    };
