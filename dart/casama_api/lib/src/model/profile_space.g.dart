// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_space.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ProfileSpaceCWProxy {
  ProfileSpace orgId(String orgId);

  ProfileSpace shared(bool shared);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ProfileSpace(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ProfileSpace(...).copyWith(id: 12, name: "My name")
  /// ```
  ProfileSpace call({String orgId, bool shared});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfProfileSpace.copyWith(...)` or call `instanceOfProfileSpace.copyWith.fieldName(value)` for a single field.
class _$ProfileSpaceCWProxyImpl implements _$ProfileSpaceCWProxy {
  const _$ProfileSpaceCWProxyImpl(this._value);

  final ProfileSpace _value;

  @override
  ProfileSpace orgId(String orgId) => call(orgId: orgId);

  @override
  ProfileSpace shared(bool shared) => call(shared: shared);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ProfileSpace(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ProfileSpace(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ProfileSpace call({
    Object? orgId = const $CopyWithPlaceholder(),
    Object? shared = const $CopyWithPlaceholder(),
  }) {
    return ProfileSpace(
      orgId: orgId == const $CopyWithPlaceholder() || orgId == null
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
      shared: shared == const $CopyWithPlaceholder() || shared == null
          ? _value.shared
          // ignore: cast_nullable_to_non_nullable
          : shared as bool,
    );
  }
}

extension $ProfileSpaceCopyWith on ProfileSpace {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfProfileSpace.copyWith(...)` or `instanceOfProfileSpace.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ProfileSpaceCWProxy get copyWith => _$ProfileSpaceCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProfileSpace _$ProfileSpaceFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ProfileSpace', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['org_id', 'shared']);
      final val = ProfileSpace(
        orgId: $checkedConvert('org_id', (v) => v as String),
        shared: $checkedConvert('shared', (v) => v as bool),
      );
      return val;
    }, fieldKeyMap: const {'orgId': 'org_id'});

Map<String, dynamic> _$ProfileSpaceToJson(ProfileSpace instance) =>
    <String, dynamic>{'org_id': instance.orgId, 'shared': instance.shared};
