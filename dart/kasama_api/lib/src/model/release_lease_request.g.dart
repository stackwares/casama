// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'release_lease_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ReleaseLeaseRequestCWProxy {
  ReleaseLeaseRequest note(String? note);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ReleaseLeaseRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ReleaseLeaseRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  ReleaseLeaseRequest call({String? note});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfReleaseLeaseRequest.copyWith(...)` or call `instanceOfReleaseLeaseRequest.copyWith.fieldName(value)` for a single field.
class _$ReleaseLeaseRequestCWProxyImpl implements _$ReleaseLeaseRequestCWProxy {
  const _$ReleaseLeaseRequestCWProxyImpl(this._value);

  final ReleaseLeaseRequest _value;

  @override
  ReleaseLeaseRequest note(String? note) => call(note: note);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ReleaseLeaseRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ReleaseLeaseRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ReleaseLeaseRequest call({Object? note = const $CopyWithPlaceholder()}) {
    return ReleaseLeaseRequest(
      note: note == const $CopyWithPlaceholder()
          ? _value.note
          // ignore: cast_nullable_to_non_nullable
          : note as String?,
    );
  }
}

extension $ReleaseLeaseRequestCopyWith on ReleaseLeaseRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfReleaseLeaseRequest.copyWith(...)` or `instanceOfReleaseLeaseRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ReleaseLeaseRequestCWProxy get copyWith =>
      _$ReleaseLeaseRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReleaseLeaseRequest _$ReleaseLeaseRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ReleaseLeaseRequest', json, ($checkedConvert) {
      final val = ReleaseLeaseRequest(
        note: $checkedConvert('note', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$ReleaseLeaseRequestToJson(
  ReleaseLeaseRequest instance,
) => <String, dynamic>{'note': ?instance.note};
