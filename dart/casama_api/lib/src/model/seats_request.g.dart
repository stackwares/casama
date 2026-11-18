// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seats_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SeatsRequestCWProxy {
  SeatsRequest extra(int extra);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SeatsRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SeatsRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  SeatsRequest call({int extra});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSeatsRequest.copyWith(...)` or call `instanceOfSeatsRequest.copyWith.fieldName(value)` for a single field.
class _$SeatsRequestCWProxyImpl implements _$SeatsRequestCWProxy {
  const _$SeatsRequestCWProxyImpl(this._value);

  final SeatsRequest _value;

  @override
  SeatsRequest extra(int extra) => call(extra: extra);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SeatsRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SeatsRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SeatsRequest call({Object? extra = const $CopyWithPlaceholder()}) {
    return SeatsRequest(
      extra: extra == const $CopyWithPlaceholder() || extra == null
          ? _value.extra
          // ignore: cast_nullable_to_non_nullable
          : extra as int,
    );
  }
}

extension $SeatsRequestCopyWith on SeatsRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSeatsRequest.copyWith(...)` or `instanceOfSeatsRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SeatsRequestCWProxy get copyWith => _$SeatsRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SeatsRequest _$SeatsRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SeatsRequest', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['extra']);
      final val = SeatsRequest(
        extra: $checkedConvert('extra', (v) => (v as num).toInt()),
      );
      return val;
    });

Map<String, dynamic> _$SeatsRequestToJson(SeatsRequest instance) =>
    <String, dynamic>{'extra': instance.extra};
