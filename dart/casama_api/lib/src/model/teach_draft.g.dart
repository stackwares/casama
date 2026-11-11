// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teach_draft.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TeachDraftCWProxy {
  TeachDraft name(String name);

  TeachDraft description(String description);

  TeachDraft body(String body);

  TeachDraft inputs(List<TeachDraftInputsInner> inputs);

  TeachDraft checks(List<String> checks);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `TeachDraft(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TeachDraft(...).copyWith(id: 12, name: "My name")
  /// ```
  TeachDraft call({
    String name,
    String description,
    String body,
    List<TeachDraftInputsInner> inputs,
    List<String> checks,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfTeachDraft.copyWith(...)` or call `instanceOfTeachDraft.copyWith.fieldName(value)` for a single field.
class _$TeachDraftCWProxyImpl implements _$TeachDraftCWProxy {
  const _$TeachDraftCWProxyImpl(this._value);

  final TeachDraft _value;

  @override
  TeachDraft name(String name) => call(name: name);

  @override
  TeachDraft description(String description) => call(description: description);

  @override
  TeachDraft body(String body) => call(body: body);

  @override
  TeachDraft inputs(List<TeachDraftInputsInner> inputs) => call(inputs: inputs);

  @override
  TeachDraft checks(List<String> checks) => call(checks: checks);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `TeachDraft(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TeachDraft(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  TeachDraft call({
    Object? name = const $CopyWithPlaceholder(),
    Object? description = const $CopyWithPlaceholder(),
    Object? body = const $CopyWithPlaceholder(),
    Object? inputs = const $CopyWithPlaceholder(),
    Object? checks = const $CopyWithPlaceholder(),
  }) {
    return TeachDraft(
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      description:
          description == const $CopyWithPlaceholder() || description == null
          ? _value.description
          // ignore: cast_nullable_to_non_nullable
          : description as String,
      body: body == const $CopyWithPlaceholder() || body == null
          ? _value.body
          // ignore: cast_nullable_to_non_nullable
          : body as String,
      inputs: inputs == const $CopyWithPlaceholder() || inputs == null
          ? _value.inputs
          // ignore: cast_nullable_to_non_nullable
          : inputs as List<TeachDraftInputsInner>,
      checks: checks == const $CopyWithPlaceholder() || checks == null
          ? _value.checks
          // ignore: cast_nullable_to_non_nullable
          : checks as List<String>,
    );
  }
}

extension $TeachDraftCopyWith on TeachDraft {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfTeachDraft.copyWith(...)` or `instanceOfTeachDraft.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TeachDraftCWProxy get copyWith => _$TeachDraftCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TeachDraft _$TeachDraftFromJson(Map<String, dynamic> json) =>
    $checkedCreate('TeachDraft', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['name', 'description', 'body', 'inputs', 'checks'],
      );
      final val = TeachDraft(
        name: $checkedConvert('name', (v) => v as String),
        description: $checkedConvert('description', (v) => v as String),
        body: $checkedConvert('body', (v) => v as String),
        inputs: $checkedConvert(
          'inputs',
          (v) => (v as List<dynamic>)
              .map(
                (e) =>
                    TeachDraftInputsInner.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
        ),
        checks: $checkedConvert(
          'checks',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$TeachDraftToJson(TeachDraft instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'body': instance.body,
      'inputs': instance.inputs.map((e) => e.toJson()).toList(),
      'checks': instance.checks,
    };
