// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'problem_errors_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ProblemErrorsInnerCWProxy {
  ProblemErrorsInner path(String path);

  ProblemErrorsInner message(String message);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ProblemErrorsInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ProblemErrorsInner(...).copyWith(id: 12, name: "My name")
  /// ```
  ProblemErrorsInner call({String path, String message});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfProblemErrorsInner.copyWith(...)` or call `instanceOfProblemErrorsInner.copyWith.fieldName(value)` for a single field.
class _$ProblemErrorsInnerCWProxyImpl implements _$ProblemErrorsInnerCWProxy {
  const _$ProblemErrorsInnerCWProxyImpl(this._value);

  final ProblemErrorsInner _value;

  @override
  ProblemErrorsInner path(String path) => call(path: path);

  @override
  ProblemErrorsInner message(String message) => call(message: message);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ProblemErrorsInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ProblemErrorsInner(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ProblemErrorsInner call({
    Object? path = const $CopyWithPlaceholder(),
    Object? message = const $CopyWithPlaceholder(),
  }) {
    return ProblemErrorsInner(
      path: path == const $CopyWithPlaceholder() || path == null
          ? _value.path
          // ignore: cast_nullable_to_non_nullable
          : path as String,
      message: message == const $CopyWithPlaceholder() || message == null
          ? _value.message
          // ignore: cast_nullable_to_non_nullable
          : message as String,
    );
  }
}

extension $ProblemErrorsInnerCopyWith on ProblemErrorsInner {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfProblemErrorsInner.copyWith(...)` or `instanceOfProblemErrorsInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ProblemErrorsInnerCWProxy get copyWith =>
      _$ProblemErrorsInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProblemErrorsInner _$ProblemErrorsInnerFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ProblemErrorsInner', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['path', 'message']);
      final val = ProblemErrorsInner(
        path: $checkedConvert('path', (v) => v as String),
        message: $checkedConvert('message', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$ProblemErrorsInnerToJson(ProblemErrorsInner instance) =>
    <String, dynamic>{'path': instance.path, 'message': instance.message};
