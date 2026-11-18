// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'domain_record.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DomainRecordCWProxy {
  DomainRecord host(String host);

  DomainRecord type(String type);

  DomainRecord name(String name);

  DomainRecord value(String value);

  DomainRecord purpose(String purpose);

  DomainRecord required_(bool required_);

  DomainRecord seen(List<String>? seen);

  DomainRecord ok(bool? ok);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DomainRecord(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DomainRecord(...).copyWith(id: 12, name: "My name")
  /// ```
  DomainRecord call({
    String host,
    String type,
    String name,
    String value,
    String purpose,
    bool required_,
    List<String>? seen,
    bool? ok,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDomainRecord.copyWith(...)` or call `instanceOfDomainRecord.copyWith.fieldName(value)` for a single field.
class _$DomainRecordCWProxyImpl implements _$DomainRecordCWProxy {
  const _$DomainRecordCWProxyImpl(this._value);

  final DomainRecord _value;

  @override
  DomainRecord host(String host) => call(host: host);

  @override
  DomainRecord type(String type) => call(type: type);

  @override
  DomainRecord name(String name) => call(name: name);

  @override
  DomainRecord value(String value) => call(value: value);

  @override
  DomainRecord purpose(String purpose) => call(purpose: purpose);

  @override
  DomainRecord required_(bool required_) => call(required_: required_);

  @override
  DomainRecord seen(List<String>? seen) => call(seen: seen);

  @override
  DomainRecord ok(bool? ok) => call(ok: ok);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DomainRecord(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DomainRecord(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DomainRecord call({
    Object? host = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? value = const $CopyWithPlaceholder(),
    Object? purpose = const $CopyWithPlaceholder(),
    Object? required_ = const $CopyWithPlaceholder(),
    Object? seen = const $CopyWithPlaceholder(),
    Object? ok = const $CopyWithPlaceholder(),
  }) {
    return DomainRecord(
      host: host == const $CopyWithPlaceholder() || host == null
          ? _value.host
          // ignore: cast_nullable_to_non_nullable
          : host as String,
      type: type == const $CopyWithPlaceholder() || type == null
          ? _value.type
          // ignore: cast_nullable_to_non_nullable
          : type as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      value: value == const $CopyWithPlaceholder() || value == null
          ? _value.value
          // ignore: cast_nullable_to_non_nullable
          : value as String,
      purpose: purpose == const $CopyWithPlaceholder() || purpose == null
          ? _value.purpose
          // ignore: cast_nullable_to_non_nullable
          : purpose as String,
      required_: required_ == const $CopyWithPlaceholder() || required_ == null
          ? _value.required_
          // ignore: cast_nullable_to_non_nullable
          : required_ as bool,
      seen: seen == const $CopyWithPlaceholder()
          ? _value.seen
          // ignore: cast_nullable_to_non_nullable
          : seen as List<String>?,
      ok: ok == const $CopyWithPlaceholder()
          ? _value.ok
          // ignore: cast_nullable_to_non_nullable
          : ok as bool?,
    );
  }
}

extension $DomainRecordCopyWith on DomainRecord {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDomainRecord.copyWith(...)` or `instanceOfDomainRecord.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DomainRecordCWProxy get copyWith => _$DomainRecordCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DomainRecord _$DomainRecordFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DomainRecord', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'host',
          'type',
          'name',
          'value',
          'purpose',
          'required',
          'seen',
          'ok',
        ],
      );
      final val = DomainRecord(
        host: $checkedConvert('host', (v) => v as String),
        type: $checkedConvert('type', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        value: $checkedConvert('value', (v) => v as String),
        purpose: $checkedConvert('purpose', (v) => v as String),
        required_: $checkedConvert('required', (v) => v as bool),
        seen: $checkedConvert(
          'seen',
          (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
        ),
        ok: $checkedConvert('ok', (v) => v as bool?),
      );
      return val;
    }, fieldKeyMap: const {'required_': 'required'});

Map<String, dynamic> _$DomainRecordToJson(DomainRecord instance) =>
    <String, dynamic>{
      'host': instance.host,
      'type': instance.type,
      'name': instance.name,
      'value': instance.value,
      'purpose': instance.purpose,
      'required': instance.required_,
      'seen': instance.seen,
      'ok': instance.ok,
    };
