// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pack_item_ref.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PackItemRefCWProxy {
  PackItemRef kind(PackItemKind kind);

  PackItemRef id(String id);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PackItemRef(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PackItemRef(...).copyWith(id: 12, name: "My name")
  /// ```
  PackItemRef call({PackItemKind kind, String id});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPackItemRef.copyWith(...)` or call `instanceOfPackItemRef.copyWith.fieldName(value)` for a single field.
class _$PackItemRefCWProxyImpl implements _$PackItemRefCWProxy {
  const _$PackItemRefCWProxyImpl(this._value);

  final PackItemRef _value;

  @override
  PackItemRef kind(PackItemKind kind) => call(kind: kind);

  @override
  PackItemRef id(String id) => call(id: id);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PackItemRef(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PackItemRef(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PackItemRef call({
    Object? kind = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
  }) {
    return PackItemRef(
      kind: kind == const $CopyWithPlaceholder() || kind == null
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as PackItemKind,
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
    );
  }
}

extension $PackItemRefCopyWith on PackItemRef {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPackItemRef.copyWith(...)` or `instanceOfPackItemRef.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PackItemRefCWProxy get copyWith => _$PackItemRefCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PackItemRef _$PackItemRefFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PackItemRef', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['kind', 'id']);
      final val = PackItemRef(
        kind: $checkedConvert(
          'kind',
          (v) => $enumDecode(_$PackItemKindEnumMap, v),
        ),
        id: $checkedConvert('id', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$PackItemRefToJson(PackItemRef instance) =>
    <String, dynamic>{
      'kind': _$PackItemKindEnumMap[instance.kind]!,
      'id': instance.id,
    };

const _$PackItemKindEnumMap = {
  PackItemKind.bot: 'bot',
  PackItemKind.skill: 'skill',
  PackItemKind.routine: 'routine',
  PackItemKind.app: 'app',
  PackItemKind.look: 'look',
  PackItemKind.tools: 'tools',
  PackItemKind.include: 'include',
};
