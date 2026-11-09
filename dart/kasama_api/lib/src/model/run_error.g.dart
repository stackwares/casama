// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'run_error.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RunErrorCWProxy {
  RunError code(String code);

  RunError message(String message);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RunError(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RunError(...).copyWith(id: 12, name: "My name")
  /// ````
  RunError call({String code, String message});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRunError.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRunError.copyWith.fieldName(...)`
class _$RunErrorCWProxyImpl implements _$RunErrorCWProxy {
  const _$RunErrorCWProxyImpl(this._value);

  final RunError _value;

  @override
  RunError code(String code) => this(code: code);

  @override
  RunError message(String message) => this(message: message);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RunError(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RunError(...).copyWith(id: 12, name: "My name")
  /// ````
  RunError call({
    Object? code = const $CopyWithPlaceholder(),
    Object? message = const $CopyWithPlaceholder(),
  }) {
    return RunError(
      code: code == const $CopyWithPlaceholder()
          ? _value.code
          // ignore: cast_nullable_to_non_nullable
          : code as String,
      message: message == const $CopyWithPlaceholder()
          ? _value.message
          // ignore: cast_nullable_to_non_nullable
          : message as String,
    );
  }
}

extension $RunErrorCopyWith on RunError {
  /// Returns a callable class that can be used as follows: `instanceOfRunError.copyWith(...)` or like so:`instanceOfRunError.copyWith.fieldName(...)`.
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
