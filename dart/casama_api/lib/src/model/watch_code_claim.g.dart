// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watch_code_claim.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$WatchCodeClaimCWProxy {
  WatchCodeClaim orgId(String orgId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WatchCodeClaim(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WatchCodeClaim(...).copyWith(id: 12, name: "My name")
  /// ```
  WatchCodeClaim call({String orgId});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfWatchCodeClaim.copyWith(...)` or call `instanceOfWatchCodeClaim.copyWith.fieldName(value)` for a single field.
class _$WatchCodeClaimCWProxyImpl implements _$WatchCodeClaimCWProxy {
  const _$WatchCodeClaimCWProxyImpl(this._value);

  final WatchCodeClaim _value;

  @override
  WatchCodeClaim orgId(String orgId) => call(orgId: orgId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WatchCodeClaim(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WatchCodeClaim(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  WatchCodeClaim call({Object? orgId = const $CopyWithPlaceholder()}) {
    return WatchCodeClaim(
      orgId: orgId == const $CopyWithPlaceholder() || orgId == null
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
    );
  }
}

extension $WatchCodeClaimCopyWith on WatchCodeClaim {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfWatchCodeClaim.copyWith(...)` or `instanceOfWatchCodeClaim.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$WatchCodeClaimCWProxy get copyWith => _$WatchCodeClaimCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WatchCodeClaim _$WatchCodeClaimFromJson(Map<String, dynamic> json) =>
    $checkedCreate('WatchCodeClaim', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['org_id']);
      final val = WatchCodeClaim(
        orgId: $checkedConvert('org_id', (v) => v as String),
      );
      return val;
    }, fieldKeyMap: const {'orgId': 'org_id'});

Map<String, dynamic> _$WatchCodeClaimToJson(WatchCodeClaim instance) =>
    <String, dynamic>{'org_id': instance.orgId};
