// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dns_record_item.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DnsRecordItemCWProxy {
  DnsRecordItem id(String id);

  DnsRecordItem host(String host);

  DnsRecordItem type(String type);

  DnsRecordItem answer(String answer);

  DnsRecordItem ttl(int ttl);

  DnsRecordItem priority(int? priority);

  DnsRecordItem managed(bool managed);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DnsRecordItem(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DnsRecordItem(...).copyWith(id: 12, name: "My name")
  /// ```
  DnsRecordItem call({
    String id,
    String host,
    String type,
    String answer,
    int ttl,
    int? priority,
    bool managed,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDnsRecordItem.copyWith(...)` or call `instanceOfDnsRecordItem.copyWith.fieldName(value)` for a single field.
class _$DnsRecordItemCWProxyImpl implements _$DnsRecordItemCWProxy {
  const _$DnsRecordItemCWProxyImpl(this._value);

  final DnsRecordItem _value;

  @override
  DnsRecordItem id(String id) => call(id: id);

  @override
  DnsRecordItem host(String host) => call(host: host);

  @override
  DnsRecordItem type(String type) => call(type: type);

  @override
  DnsRecordItem answer(String answer) => call(answer: answer);

  @override
  DnsRecordItem ttl(int ttl) => call(ttl: ttl);

  @override
  DnsRecordItem priority(int? priority) => call(priority: priority);

  @override
  DnsRecordItem managed(bool managed) => call(managed: managed);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DnsRecordItem(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DnsRecordItem(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DnsRecordItem call({
    Object? id = const $CopyWithPlaceholder(),
    Object? host = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
    Object? answer = const $CopyWithPlaceholder(),
    Object? ttl = const $CopyWithPlaceholder(),
    Object? priority = const $CopyWithPlaceholder(),
    Object? managed = const $CopyWithPlaceholder(),
  }) {
    return DnsRecordItem(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
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
      ttl: ttl == const $CopyWithPlaceholder() || ttl == null
          ? _value.ttl
          // ignore: cast_nullable_to_non_nullable
          : ttl as int,
      priority: priority == const $CopyWithPlaceholder()
          ? _value.priority
          // ignore: cast_nullable_to_non_nullable
          : priority as int?,
      managed: managed == const $CopyWithPlaceholder() || managed == null
          ? _value.managed
          // ignore: cast_nullable_to_non_nullable
          : managed as bool,
    );
  }
}

extension $DnsRecordItemCopyWith on DnsRecordItem {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDnsRecordItem.copyWith(...)` or `instanceOfDnsRecordItem.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DnsRecordItemCWProxy get copyWith => _$DnsRecordItemCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DnsRecordItem _$DnsRecordItemFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DnsRecordItem', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'id',
          'host',
          'type',
          'answer',
          'ttl',
          'priority',
          'managed',
        ],
      );
      final val = DnsRecordItem(
        id: $checkedConvert('id', (v) => v as String),
        host: $checkedConvert('host', (v) => v as String),
        type: $checkedConvert('type', (v) => v as String),
        answer: $checkedConvert('answer', (v) => v as String),
        ttl: $checkedConvert('ttl', (v) => (v as num).toInt()),
        priority: $checkedConvert('priority', (v) => (v as num?)?.toInt()),
        managed: $checkedConvert('managed', (v) => v as bool),
      );
      return val;
    });

Map<String, dynamic> _$DnsRecordItemToJson(DnsRecordItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'host': instance.host,
      'type': instance.type,
      'answer': instance.answer,
      'ttl': instance.ttl,
      'priority': instance.priority,
      'managed': instance.managed,
    };
