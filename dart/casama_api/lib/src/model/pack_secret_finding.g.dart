// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pack_secret_finding.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PackSecretFindingCWProxy {
  PackSecretFinding path(String path);

  PackSecretFinding line(int line);

  PackSecretFinding what(String what);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PackSecretFinding(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PackSecretFinding(...).copyWith(id: 12, name: "My name")
  /// ```
  PackSecretFinding call({String path, int line, String what});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPackSecretFinding.copyWith(...)` or call `instanceOfPackSecretFinding.copyWith.fieldName(value)` for a single field.
class _$PackSecretFindingCWProxyImpl implements _$PackSecretFindingCWProxy {
  const _$PackSecretFindingCWProxyImpl(this._value);

  final PackSecretFinding _value;

  @override
  PackSecretFinding path(String path) => call(path: path);

  @override
  PackSecretFinding line(int line) => call(line: line);

  @override
  PackSecretFinding what(String what) => call(what: what);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PackSecretFinding(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PackSecretFinding(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PackSecretFinding call({
    Object? path = const $CopyWithPlaceholder(),
    Object? line = const $CopyWithPlaceholder(),
    Object? what = const $CopyWithPlaceholder(),
  }) {
    return PackSecretFinding(
      path: path == const $CopyWithPlaceholder() || path == null
          ? _value.path
          // ignore: cast_nullable_to_non_nullable
          : path as String,
      line: line == const $CopyWithPlaceholder() || line == null
          ? _value.line
          // ignore: cast_nullable_to_non_nullable
          : line as int,
      what: what == const $CopyWithPlaceholder() || what == null
          ? _value.what
          // ignore: cast_nullable_to_non_nullable
          : what as String,
    );
  }
}

extension $PackSecretFindingCopyWith on PackSecretFinding {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPackSecretFinding.copyWith(...)` or `instanceOfPackSecretFinding.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PackSecretFindingCWProxy get copyWith =>
      _$PackSecretFindingCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PackSecretFinding _$PackSecretFindingFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PackSecretFinding', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['path', 'line', 'what']);
      final val = PackSecretFinding(
        path: $checkedConvert('path', (v) => v as String),
        line: $checkedConvert('line', (v) => (v as num).toInt()),
        what: $checkedConvert('what', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$PackSecretFindingToJson(PackSecretFinding instance) =>
    <String, dynamic>{
      'path': instance.path,
      'line': instance.line,
      'what': instance.what,
    };
