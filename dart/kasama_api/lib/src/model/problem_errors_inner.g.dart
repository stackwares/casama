// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'problem_errors_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ProblemErrorsInnerCWProxy {
  ProblemErrorsInner path(String path);

  ProblemErrorsInner message(String message);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ProblemErrorsInner(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ProblemErrorsInner(...).copyWith(id: 12, name: "My name")
  /// ````
  ProblemErrorsInner call({String path, String message});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfProblemErrorsInner.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfProblemErrorsInner.copyWith.fieldName(...)`
class _$ProblemErrorsInnerCWProxyImpl implements _$ProblemErrorsInnerCWProxy {
  const _$ProblemErrorsInnerCWProxyImpl(this._value);

  final ProblemErrorsInner _value;

  @override
  ProblemErrorsInner path(String path) => this(path: path);

  @override
  ProblemErrorsInner message(String message) => this(message: message);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ProblemErrorsInner(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ProblemErrorsInner(...).copyWith(id: 12, name: "My name")
  /// ````
  ProblemErrorsInner call({
    Object? path = const $CopyWithPlaceholder(),
    Object? message = const $CopyWithPlaceholder(),
  }) {
    return ProblemErrorsInner(
      path: path == const $CopyWithPlaceholder()
          ? _value.path
          // ignore: cast_nullable_to_non_nullable
          : path as String,
      message: message == const $CopyWithPlaceholder()
          ? _value.message
          // ignore: cast_nullable_to_non_nullable
          : message as String,
    );
  }
}

extension $ProblemErrorsInnerCopyWith on ProblemErrorsInner {
  /// Returns a callable class that can be used as follows: `instanceOfProblemErrorsInner.copyWith(...)` or like so:`instanceOfProblemErrorsInner.copyWith.fieldName(...)`.
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
