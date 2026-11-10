// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teach_draft_inputs_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TeachDraftInputsInnerCWProxy {
  TeachDraftInputsInner name(String name);

  TeachDraftInputsInner description(String? description);

  TeachDraftInputsInner secret(bool? secret);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `TeachDraftInputsInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TeachDraftInputsInner(...).copyWith(id: 12, name: "My name")
  /// ```
  TeachDraftInputsInner call({String name, String? description, bool? secret});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfTeachDraftInputsInner.copyWith(...)` or call `instanceOfTeachDraftInputsInner.copyWith.fieldName(value)` for a single field.
class _$TeachDraftInputsInnerCWProxyImpl
    implements _$TeachDraftInputsInnerCWProxy {
  const _$TeachDraftInputsInnerCWProxyImpl(this._value);

  final TeachDraftInputsInner _value;

  @override
  TeachDraftInputsInner name(String name) => call(name: name);

  @override
  TeachDraftInputsInner description(String? description) =>
      call(description: description);

  @override
  TeachDraftInputsInner secret(bool? secret) => call(secret: secret);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `TeachDraftInputsInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TeachDraftInputsInner(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  TeachDraftInputsInner call({
    Object? name = const $CopyWithPlaceholder(),
    Object? description = const $CopyWithPlaceholder(),
    Object? secret = const $CopyWithPlaceholder(),
  }) {
    return TeachDraftInputsInner(
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      description: description == const $CopyWithPlaceholder()
          ? _value.description
          // ignore: cast_nullable_to_non_nullable
          : description as String?,
      secret: secret == const $CopyWithPlaceholder()
          ? _value.secret
          // ignore: cast_nullable_to_non_nullable
          : secret as bool?,
    );
  }
}

extension $TeachDraftInputsInnerCopyWith on TeachDraftInputsInner {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfTeachDraftInputsInner.copyWith(...)` or `instanceOfTeachDraftInputsInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TeachDraftInputsInnerCWProxy get copyWith =>
      _$TeachDraftInputsInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TeachDraftInputsInner _$TeachDraftInputsInnerFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('TeachDraftInputsInner', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['name']);
  final val = TeachDraftInputsInner(
    name: $checkedConvert('name', (v) => v as String),
    description: $checkedConvert('description', (v) => v as String?),
    secret: $checkedConvert('secret', (v) => v as bool?),
  );
  return val;
});

Map<String, dynamic> _$TeachDraftInputsInnerToJson(
  TeachDraftInputsInner instance,
) => <String, dynamic>{
  'name': instance.name,
  'description': ?instance.description,
  'secret': ?instance.secret,
};
