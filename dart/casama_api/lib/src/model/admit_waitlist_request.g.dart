// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admit_waitlist_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdmitWaitlistRequestCWProxy {
  AdmitWaitlistRequest ids(List<String>? ids);

  AdmitWaitlistRequest count(int? count);

  AdmitWaitlistRequest source_(String? source_);

  AdmitWaitlistRequest ref(String? ref);

  AdmitWaitlistRequest selfHosting(bool? selfHosting);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdmitWaitlistRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdmitWaitlistRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  AdmitWaitlistRequest call({
    List<String>? ids,
    int? count,
    String? source_,
    String? ref,
    bool? selfHosting,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdmitWaitlistRequest.copyWith(...)` or call `instanceOfAdmitWaitlistRequest.copyWith.fieldName(value)` for a single field.
class _$AdmitWaitlistRequestCWProxyImpl
    implements _$AdmitWaitlistRequestCWProxy {
  const _$AdmitWaitlistRequestCWProxyImpl(this._value);

  final AdmitWaitlistRequest _value;

  @override
  AdmitWaitlistRequest ids(List<String>? ids) => call(ids: ids);

  @override
  AdmitWaitlistRequest count(int? count) => call(count: count);

  @override
  AdmitWaitlistRequest source_(String? source_) => call(source_: source_);

  @override
  AdmitWaitlistRequest ref(String? ref) => call(ref: ref);

  @override
  AdmitWaitlistRequest selfHosting(bool? selfHosting) =>
      call(selfHosting: selfHosting);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdmitWaitlistRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdmitWaitlistRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdmitWaitlistRequest call({
    Object? ids = const $CopyWithPlaceholder(),
    Object? count = const $CopyWithPlaceholder(),
    Object? source_ = const $CopyWithPlaceholder(),
    Object? ref = const $CopyWithPlaceholder(),
    Object? selfHosting = const $CopyWithPlaceholder(),
  }) {
    return AdmitWaitlistRequest(
      ids: ids == const $CopyWithPlaceholder()
          ? _value.ids
          // ignore: cast_nullable_to_non_nullable
          : ids as List<String>?,
      count: count == const $CopyWithPlaceholder()
          ? _value.count
          // ignore: cast_nullable_to_non_nullable
          : count as int?,
      source_: source_ == const $CopyWithPlaceholder()
          ? _value.source_
          // ignore: cast_nullable_to_non_nullable
          : source_ as String?,
      ref: ref == const $CopyWithPlaceholder()
          ? _value.ref
          // ignore: cast_nullable_to_non_nullable
          : ref as String?,
      selfHosting: selfHosting == const $CopyWithPlaceholder()
          ? _value.selfHosting
          // ignore: cast_nullable_to_non_nullable
          : selfHosting as bool?,
    );
  }
}

extension $AdmitWaitlistRequestCopyWith on AdmitWaitlistRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdmitWaitlistRequest.copyWith(...)` or `instanceOfAdmitWaitlistRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdmitWaitlistRequestCWProxy get copyWith =>
      _$AdmitWaitlistRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdmitWaitlistRequest _$AdmitWaitlistRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AdmitWaitlistRequest', json, ($checkedConvert) {
  final val = AdmitWaitlistRequest(
    ids: $checkedConvert(
      'ids',
      (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
    ),
    count: $checkedConvert('count', (v) => (v as num?)?.toInt()),
    source_: $checkedConvert('source', (v) => v as String?),
    ref: $checkedConvert('ref', (v) => v as String?),
    selfHosting: $checkedConvert('self_hosting', (v) => v as bool?),
  );
  return val;
}, fieldKeyMap: const {'source_': 'source', 'selfHosting': 'self_hosting'});

Map<String, dynamic> _$AdmitWaitlistRequestToJson(
  AdmitWaitlistRequest instance,
) => <String, dynamic>{
  'ids': ?instance.ids,
  'count': ?instance.count,
  'source': ?instance.source_,
  'ref': ?instance.ref,
  'self_hosting': ?instance.selfHosting,
};
