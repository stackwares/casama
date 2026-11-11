// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_plugin_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UpdatePluginRequestCWProxy {
  UpdatePluginRequest commit(String commit);

  UpdatePluginRequest secrets(Map<String, String>? secrets);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UpdatePluginRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UpdatePluginRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  UpdatePluginRequest call({String commit, Map<String, String>? secrets});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfUpdatePluginRequest.copyWith(...)` or call `instanceOfUpdatePluginRequest.copyWith.fieldName(value)` for a single field.
class _$UpdatePluginRequestCWProxyImpl implements _$UpdatePluginRequestCWProxy {
  const _$UpdatePluginRequestCWProxyImpl(this._value);

  final UpdatePluginRequest _value;

  @override
  UpdatePluginRequest commit(String commit) => call(commit: commit);

  @override
  UpdatePluginRequest secrets(Map<String, String>? secrets) =>
      call(secrets: secrets);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UpdatePluginRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UpdatePluginRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  UpdatePluginRequest call({
    Object? commit = const $CopyWithPlaceholder(),
    Object? secrets = const $CopyWithPlaceholder(),
  }) {
    return UpdatePluginRequest(
      commit: commit == const $CopyWithPlaceholder() || commit == null
          ? _value.commit
          // ignore: cast_nullable_to_non_nullable
          : commit as String,
      secrets: secrets == const $CopyWithPlaceholder()
          ? _value.secrets
          // ignore: cast_nullable_to_non_nullable
          : secrets as Map<String, String>?,
    );
  }
}

extension $UpdatePluginRequestCopyWith on UpdatePluginRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfUpdatePluginRequest.copyWith(...)` or `instanceOfUpdatePluginRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$UpdatePluginRequestCWProxy get copyWith =>
      _$UpdatePluginRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdatePluginRequest _$UpdatePluginRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('UpdatePluginRequest', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['commit']);
      final val = UpdatePluginRequest(
        commit: $checkedConvert('commit', (v) => v as String),
        secrets: $checkedConvert(
          'secrets',
          (v) => (v as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ),
        ),
      );
      return val;
    });

Map<String, dynamic> _$UpdatePluginRequestToJson(
  UpdatePluginRequest instance,
) => <String, dynamic>{'commit': instance.commit, 'secrets': ?instance.secrets};
