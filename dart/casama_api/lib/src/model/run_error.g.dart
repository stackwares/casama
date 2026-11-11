// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'run_error.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RunErrorCWProxy {
  RunError code(String code);

  RunError message(String message);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RunError(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RunError(...).copyWith(id: 12, name: "My name")
  /// ```
  RunError call({String code, String message});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfRunError.copyWith(...)` or call `instanceOfRunError.copyWith.fieldName(value)` for a single field.
class _$RunErrorCWProxyImpl implements _$RunErrorCWProxy {
  const _$RunErrorCWProxyImpl(this._value);

  final RunError _value;

  @override
  RunError code(String code) => call(code: code);

  @override
  RunError message(String message) => call(message: message);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RunError(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RunError(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  RunError call({
    Object? code = const $CopyWithPlaceholder(),
    Object? message = const $CopyWithPlaceholder(),
  }) {
    return RunError(
      code: code == const $CopyWithPlaceholder() || code == null
          ? _value.code
          // ignore: cast_nullable_to_non_nullable
          : code as String,
      message: message == const $CopyWithPlaceholder() || message == null
          ? _value.message
          // ignore: cast_nullable_to_non_nullable
          : message as String,
    );
  }
}

extension $RunErrorCopyWith on RunError {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfRunError.copyWith(...)` or `instanceOfRunError.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RunErrorCWProxy get copyWith => _$RunErrorCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RunError _$RunErrorFromJson(Map<String, dynamic> json) =>
    $checkedCreate('RunError', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['code', 'message']);
      final val = RunError(
        code: $checkedConvert('code', (v) => v as String),
        message: $checkedConvert('message', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$RunErrorToJson(RunError instance) => <String, dynamic>{
  'code': instance.code,
  'message': instance.message,
};
