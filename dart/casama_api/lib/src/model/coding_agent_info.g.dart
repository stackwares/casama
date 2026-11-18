// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coding_agent_info.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CodingAgentInfoCWProxy {
  CodingAgentInfo id(String id);

  CodingAgentInfo label(String label);

  CodingAgentInfo bin(String bin);

  CodingAgentInfo where(List<String> where);

  CodingAgentInfo needsFolder(bool needsFolder);

  CodingAgentInfo hint(String? hint);

  CodingAgentInfo preallowed(bool preallowed);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CodingAgentInfo(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CodingAgentInfo(...).copyWith(id: 12, name: "My name")
  /// ```
  CodingAgentInfo call({
    String id,
    String label,
    String bin,
    List<String> where,
    bool needsFolder,
    String? hint,
    bool preallowed,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCodingAgentInfo.copyWith(...)` or call `instanceOfCodingAgentInfo.copyWith.fieldName(value)` for a single field.
class _$CodingAgentInfoCWProxyImpl implements _$CodingAgentInfoCWProxy {
  const _$CodingAgentInfoCWProxyImpl(this._value);

  final CodingAgentInfo _value;

  @override
  CodingAgentInfo id(String id) => call(id: id);

  @override
  CodingAgentInfo label(String label) => call(label: label);

  @override
  CodingAgentInfo bin(String bin) => call(bin: bin);

  @override
  CodingAgentInfo where(List<String> where) => call(where: where);

  @override
  CodingAgentInfo needsFolder(bool needsFolder) =>
      call(needsFolder: needsFolder);

  @override
  CodingAgentInfo hint(String? hint) => call(hint: hint);

  @override
  CodingAgentInfo preallowed(bool preallowed) => call(preallowed: preallowed);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CodingAgentInfo(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CodingAgentInfo(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CodingAgentInfo call({
    Object? id = const $CopyWithPlaceholder(),
    Object? label = const $CopyWithPlaceholder(),
    Object? bin = const $CopyWithPlaceholder(),
    Object? where = const $CopyWithPlaceholder(),
    Object? needsFolder = const $CopyWithPlaceholder(),
    Object? hint = const $CopyWithPlaceholder(),
    Object? preallowed = const $CopyWithPlaceholder(),
  }) {
    return CodingAgentInfo(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      label: label == const $CopyWithPlaceholder() || label == null
          ? _value.label
          // ignore: cast_nullable_to_non_nullable
          : label as String,
      bin: bin == const $CopyWithPlaceholder() || bin == null
          ? _value.bin
          // ignore: cast_nullable_to_non_nullable
          : bin as String,
      where: where == const $CopyWithPlaceholder() || where == null
          ? _value.where
          // ignore: cast_nullable_to_non_nullable
          : where as List<String>,
      needsFolder:
          needsFolder == const $CopyWithPlaceholder() || needsFolder == null
          ? _value.needsFolder
          // ignore: cast_nullable_to_non_nullable
          : needsFolder as bool,
      hint: hint == const $CopyWithPlaceholder()
          ? _value.hint
          // ignore: cast_nullable_to_non_nullable
          : hint as String?,
      preallowed:
          preallowed == const $CopyWithPlaceholder() || preallowed == null
          ? _value.preallowed
          // ignore: cast_nullable_to_non_nullable
          : preallowed as bool,
    );
  }
}

extension $CodingAgentInfoCopyWith on CodingAgentInfo {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCodingAgentInfo.copyWith(...)` or `instanceOfCodingAgentInfo.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CodingAgentInfoCWProxy get copyWith => _$CodingAgentInfoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CodingAgentInfo _$CodingAgentInfoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CodingAgentInfo', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'id',
          'label',
          'bin',
          'where',
          'needs_folder',
          'hint',
          'preallowed',
        ],
      );
      final val = CodingAgentInfo(
        id: $checkedConvert('id', (v) => v as String),
        label: $checkedConvert('label', (v) => v as String),
        bin: $checkedConvert('bin', (v) => v as String),
        where: $checkedConvert(
          'where',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
        needsFolder: $checkedConvert('needs_folder', (v) => v as bool),
        hint: $checkedConvert('hint', (v) => v as String?),
        preallowed: $checkedConvert('preallowed', (v) => v as bool),
      );
      return val;
    }, fieldKeyMap: const {'needsFolder': 'needs_folder'});

Map<String, dynamic> _$CodingAgentInfoToJson(CodingAgentInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'bin': instance.bin,
      'where': instance.where,
      'needs_folder': instance.needsFolder,
      'hint': instance.hint,
      'preallowed': instance.preallowed,
    };
