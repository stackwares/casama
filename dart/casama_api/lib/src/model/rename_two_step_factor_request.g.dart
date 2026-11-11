// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rename_two_step_factor_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RenameTwoStepFactorRequestCWProxy {
  RenameTwoStepFactorRequest name(String name);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RenameTwoStepFactorRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RenameTwoStepFactorRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  RenameTwoStepFactorRequest call({String name});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfRenameTwoStepFactorRequest.copyWith(...)` or call `instanceOfRenameTwoStepFactorRequest.copyWith.fieldName(value)` for a single field.
class _$RenameTwoStepFactorRequestCWProxyImpl
    implements _$RenameTwoStepFactorRequestCWProxy {
  const _$RenameTwoStepFactorRequestCWProxyImpl(this._value);

  final RenameTwoStepFactorRequest _value;

  @override
  RenameTwoStepFactorRequest name(String name) => call(name: name);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RenameTwoStepFactorRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RenameTwoStepFactorRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  RenameTwoStepFactorRequest call({
    Object? name = const $CopyWithPlaceholder(),
  }) {
    return RenameTwoStepFactorRequest(
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
    );
  }
}

extension $RenameTwoStepFactorRequestCopyWith on RenameTwoStepFactorRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfRenameTwoStepFactorRequest.copyWith(...)` or `instanceOfRenameTwoStepFactorRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RenameTwoStepFactorRequestCWProxy get copyWith =>
      _$RenameTwoStepFactorRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RenameTwoStepFactorRequest _$RenameTwoStepFactorRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('RenameTwoStepFactorRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['name']);
  final val = RenameTwoStepFactorRequest(
    name: $checkedConvert('name', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$RenameTwoStepFactorRequestToJson(
  RenameTwoStepFactorRequest instance,
) => <String, dynamic>{'name': instance.name};
