// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'problem.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ProblemCWProxy {
  Problem type(String type);

  Problem title(String title);

  Problem status(int status);

  Problem code(String code);

  Problem detail(String? detail);

  Problem instance(String? instance);

  Problem errors(List<ProblemErrorsInner>? errors);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Problem(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Problem(...).copyWith(id: 12, name: "My name")
  /// ```
  Problem call({
    String type,
    String title,
    int status,
    String code,
    String? detail,
    String? instance,
    List<ProblemErrorsInner>? errors,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfProblem.copyWith(...)` or call `instanceOfProblem.copyWith.fieldName(value)` for a single field.
class _$ProblemCWProxyImpl implements _$ProblemCWProxy {
  const _$ProblemCWProxyImpl(this._value);

  final Problem _value;

  @override
  Problem type(String type) => call(type: type);

  @override
  Problem title(String title) => call(title: title);

  @override
  Problem status(int status) => call(status: status);

  @override
  Problem code(String code) => call(code: code);

  @override
  Problem detail(String? detail) => call(detail: detail);

  @override
  Problem instance(String? instance) => call(instance: instance);

  @override
  Problem errors(List<ProblemErrorsInner>? errors) => call(errors: errors);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Problem(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Problem(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Problem call({
    Object? type = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? code = const $CopyWithPlaceholder(),
    Object? detail = const $CopyWithPlaceholder(),
    Object? instance = const $CopyWithPlaceholder(),
    Object? errors = const $CopyWithPlaceholder(),
  }) {
    return Problem(
      type: type == const $CopyWithPlaceholder() || type == null
          ? _value.type
          // ignore: cast_nullable_to_non_nullable
          : type as String,
      title: title == const $CopyWithPlaceholder() || title == null
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as int,
      code: code == const $CopyWithPlaceholder() || code == null
          ? _value.code
          // ignore: cast_nullable_to_non_nullable
          : code as String,
      detail: detail == const $CopyWithPlaceholder()
          ? _value.detail
          // ignore: cast_nullable_to_non_nullable
          : detail as String?,
      instance: instance == const $CopyWithPlaceholder()
          ? _value.instance
          // ignore: cast_nullable_to_non_nullable
          : instance as String?,
      errors: errors == const $CopyWithPlaceholder()
          ? _value.errors
          // ignore: cast_nullable_to_non_nullable
          : errors as List<ProblemErrorsInner>?,
    );
  }
}

extension $ProblemCopyWith on Problem {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfProblem.copyWith(...)` or `instanceOfProblem.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ProblemCWProxy get copyWith => _$ProblemCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Problem _$ProblemFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Problem',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['type', 'title', 'status', 'code']);
    final val = Problem(
      type: $checkedConvert('type', (v) => v as String),
      title: $checkedConvert('title', (v) => v as String),
      status: $checkedConvert('status', (v) => (v as num).toInt()),
      code: $checkedConvert('code', (v) => v as String),
      detail: $checkedConvert('detail', (v) => v as String?),
      instance: $checkedConvert('instance', (v) => v as String?),
      errors: $checkedConvert(
        'errors',
        (v) => (v as List<dynamic>?)
            ?.map((e) => ProblemErrorsInner.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
    );
    return val;
  },
);

Map<String, dynamic> _$ProblemToJson(Problem instance) => <String, dynamic>{
  'type': instance.type,
  'title': instance.title,
  'status': instance.status,
  'code': instance.code,
  'detail': ?instance.detail,
  'instance': ?instance.instance,
  'errors': ?instance.errors?.map((e) => e.toJson()).toList(),
};
