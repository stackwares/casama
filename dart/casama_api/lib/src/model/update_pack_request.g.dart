// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_pack_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UpdatePackRequestCWProxy {
  UpdatePackRequest commit(String commit);

  UpdatePackRequest takeTheirs(List<PackItemRef>? takeTheirs);

  UpdatePackRequest confirmReach(bool? confirmReach);

  UpdatePackRequest secrets(Map<String, String>? secrets);

  UpdatePackRequest settings(Map<String, String>? settings);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UpdatePackRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UpdatePackRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  UpdatePackRequest call({
    String commit,
    List<PackItemRef>? takeTheirs,
    bool? confirmReach,
    Map<String, String>? secrets,
    Map<String, String>? settings,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfUpdatePackRequest.copyWith(...)` or call `instanceOfUpdatePackRequest.copyWith.fieldName(value)` for a single field.
class _$UpdatePackRequestCWProxyImpl implements _$UpdatePackRequestCWProxy {
  const _$UpdatePackRequestCWProxyImpl(this._value);

  final UpdatePackRequest _value;

  @override
  UpdatePackRequest commit(String commit) => call(commit: commit);

  @override
  UpdatePackRequest takeTheirs(List<PackItemRef>? takeTheirs) =>
      call(takeTheirs: takeTheirs);

  @override
  UpdatePackRequest confirmReach(bool? confirmReach) =>
      call(confirmReach: confirmReach);

  @override
  UpdatePackRequest secrets(Map<String, String>? secrets) =>
      call(secrets: secrets);

  @override
  UpdatePackRequest settings(Map<String, String>? settings) =>
      call(settings: settings);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UpdatePackRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UpdatePackRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  UpdatePackRequest call({
    Object? commit = const $CopyWithPlaceholder(),
    Object? takeTheirs = const $CopyWithPlaceholder(),
    Object? confirmReach = const $CopyWithPlaceholder(),
    Object? secrets = const $CopyWithPlaceholder(),
    Object? settings = const $CopyWithPlaceholder(),
  }) {
    return UpdatePackRequest(
      commit: commit == const $CopyWithPlaceholder() || commit == null
          ? _value.commit
          // ignore: cast_nullable_to_non_nullable
          : commit as String,
      takeTheirs: takeTheirs == const $CopyWithPlaceholder()
          ? _value.takeTheirs
          // ignore: cast_nullable_to_non_nullable
          : takeTheirs as List<PackItemRef>?,
      confirmReach: confirmReach == const $CopyWithPlaceholder()
          ? _value.confirmReach
          // ignore: cast_nullable_to_non_nullable
          : confirmReach as bool?,
      secrets: secrets == const $CopyWithPlaceholder()
          ? _value.secrets
          // ignore: cast_nullable_to_non_nullable
          : secrets as Map<String, String>?,
      settings: settings == const $CopyWithPlaceholder()
          ? _value.settings
          // ignore: cast_nullable_to_non_nullable
          : settings as Map<String, String>?,
    );
  }
}

extension $UpdatePackRequestCopyWith on UpdatePackRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfUpdatePackRequest.copyWith(...)` or `instanceOfUpdatePackRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$UpdatePackRequestCWProxy get copyWith =>
      _$UpdatePackRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdatePackRequest _$UpdatePackRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'UpdatePackRequest',
      json,
      ($checkedConvert) {
        $checkKeys(json, requiredKeys: const ['commit']);
        final val = UpdatePackRequest(
          commit: $checkedConvert('commit', (v) => v as String),
          takeTheirs: $checkedConvert(
            'take_theirs',
            (v) => (v as List<dynamic>?)
                ?.map((e) => PackItemRef.fromJson(e as Map<String, dynamic>))
                .toList(),
          ),
          confirmReach: $checkedConvert('confirm_reach', (v) => v as bool?),
          secrets: $checkedConvert(
            'secrets',
            (v) => (v as Map<String, dynamic>?)?.map(
              (k, e) => MapEntry(k, e as String),
            ),
          ),
          settings: $checkedConvert(
            'settings',
            (v) => (v as Map<String, dynamic>?)?.map(
              (k, e) => MapEntry(k, e as String),
            ),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'takeTheirs': 'take_theirs',
        'confirmReach': 'confirm_reach',
      },
    );

Map<String, dynamic> _$UpdatePackRequestToJson(UpdatePackRequest instance) =>
    <String, dynamic>{
      'commit': instance.commit,
      'take_theirs': ?instance.takeTheirs?.map((e) => e.toJson()).toList(),
      'confirm_reach': ?instance.confirmReach,
      'secrets': ?instance.secrets,
      'settings': ?instance.settings,
    };
