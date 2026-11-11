// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'revert_page_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RevertPageRequestCWProxy {
  RevertPageRequest version(int version);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RevertPageRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RevertPageRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  RevertPageRequest call({int version});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfRevertPageRequest.copyWith(...)` or call `instanceOfRevertPageRequest.copyWith.fieldName(value)` for a single field.
class _$RevertPageRequestCWProxyImpl implements _$RevertPageRequestCWProxy {
  const _$RevertPageRequestCWProxyImpl(this._value);

  final RevertPageRequest _value;

  @override
  RevertPageRequest version(int version) => call(version: version);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RevertPageRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RevertPageRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  RevertPageRequest call({Object? version = const $CopyWithPlaceholder()}) {
    return RevertPageRequest(
      version: version == const $CopyWithPlaceholder() || version == null
          ? _value.version
          // ignore: cast_nullable_to_non_nullable
          : version as int,
    );
  }
}

extension $RevertPageRequestCopyWith on RevertPageRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfRevertPageRequest.copyWith(...)` or `instanceOfRevertPageRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RevertPageRequestCWProxy get copyWith =>
      _$RevertPageRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RevertPageRequest _$RevertPageRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('RevertPageRequest', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['version']);
      final val = RevertPageRequest(
        version: $checkedConvert('version', (v) => (v as num).toInt()),
      );
      return val;
    });

Map<String, dynamic> _$RevertPageRequestToJson(RevertPageRequest instance) =>
    <String, dynamic>{'version': instance.version};
