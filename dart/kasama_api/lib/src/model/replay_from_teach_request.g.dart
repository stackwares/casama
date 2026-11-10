// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'replay_from_teach_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ReplayFromTeachRequestCWProxy {
  ReplayFromTeachRequest name(String name);

  ReplayFromTeachRequest description(String? description);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ReplayFromTeachRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ReplayFromTeachRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  ReplayFromTeachRequest call({String name, String? description});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfReplayFromTeachRequest.copyWith(...)` or call `instanceOfReplayFromTeachRequest.copyWith.fieldName(value)` for a single field.
class _$ReplayFromTeachRequestCWProxyImpl
    implements _$ReplayFromTeachRequestCWProxy {
  const _$ReplayFromTeachRequestCWProxyImpl(this._value);

  final ReplayFromTeachRequest _value;

  @override
  ReplayFromTeachRequest name(String name) => call(name: name);

  @override
  ReplayFromTeachRequest description(String? description) =>
      call(description: description);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ReplayFromTeachRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ReplayFromTeachRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ReplayFromTeachRequest call({
    Object? name = const $CopyWithPlaceholder(),
    Object? description = const $CopyWithPlaceholder(),
  }) {
    return ReplayFromTeachRequest(
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      description: description == const $CopyWithPlaceholder()
          ? _value.description
          // ignore: cast_nullable_to_non_nullable
          : description as String?,
    );
  }
}

extension $ReplayFromTeachRequestCopyWith on ReplayFromTeachRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfReplayFromTeachRequest.copyWith(...)` or `instanceOfReplayFromTeachRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ReplayFromTeachRequestCWProxy get copyWith =>
      _$ReplayFromTeachRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReplayFromTeachRequest _$ReplayFromTeachRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ReplayFromTeachRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['name']);
  final val = ReplayFromTeachRequest(
    name: $checkedConvert('name', (v) => v as String),
    description: $checkedConvert('description', (v) => v as String?),
  );
  return val;
});

Map<String, dynamic> _$ReplayFromTeachRequestToJson(
  ReplayFromTeachRequest instance,
) => <String, dynamic>{
  'name': instance.name,
  'description': ?instance.description,
};
