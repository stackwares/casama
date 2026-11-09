// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'release_lease_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ReleaseLeaseRequestCWProxy {
  ReleaseLeaseRequest note(String? note);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ReleaseLeaseRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ReleaseLeaseRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  ReleaseLeaseRequest call({String? note});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfReleaseLeaseRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfReleaseLeaseRequest.copyWith.fieldName(...)`
class _$ReleaseLeaseRequestCWProxyImpl implements _$ReleaseLeaseRequestCWProxy {
  const _$ReleaseLeaseRequestCWProxyImpl(this._value);

  final ReleaseLeaseRequest _value;

  @override
  ReleaseLeaseRequest note(String? note) => this(note: note);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ReleaseLeaseRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ReleaseLeaseRequest(...).copyWith(id: 12, name: "My name")
  /// ````
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
  /// Returns a callable class that can be used as follows: `instanceOfReleaseLeaseRequest.copyWith(...)` or like so:`instanceOfReleaseLeaseRequest.copyWith.fieldName(...)`.
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
