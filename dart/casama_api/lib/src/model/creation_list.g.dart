// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'creation_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CreationListCWProxy {
  CreationList items(List<Creation> items);

  CreationList nextCursor(String? nextCursor);

  CreationList kinds(List<CreationKind> kinds);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreationList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreationList(...).copyWith(id: 12, name: "My name")
  /// ```
  CreationList call({
    List<Creation> items,
    String? nextCursor,
    List<CreationKind> kinds,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCreationList.copyWith(...)` or call `instanceOfCreationList.copyWith.fieldName(value)` for a single field.
class _$CreationListCWProxyImpl implements _$CreationListCWProxy {
  const _$CreationListCWProxyImpl(this._value);

  final CreationList _value;

  @override
  CreationList items(List<Creation> items) => call(items: items);

  @override
  CreationList nextCursor(String? nextCursor) => call(nextCursor: nextCursor);

  @override
  CreationList kinds(List<CreationKind> kinds) => call(kinds: kinds);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreationList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreationList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CreationList call({
    Object? items = const $CopyWithPlaceholder(),
    Object? nextCursor = const $CopyWithPlaceholder(),
    Object? kinds = const $CopyWithPlaceholder(),
  }) {
    return CreationList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<Creation>,
      nextCursor: nextCursor == const $CopyWithPlaceholder()
          ? _value.nextCursor
          // ignore: cast_nullable_to_non_nullable
          : nextCursor as String?,
      kinds: kinds == const $CopyWithPlaceholder() || kinds == null
          ? _value.kinds
          // ignore: cast_nullable_to_non_nullable
          : kinds as List<CreationKind>,
    );
  }
}

extension $CreationListCopyWith on CreationList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCreationList.copyWith(...)` or `instanceOfCreationList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CreationListCWProxy get copyWith => _$CreationListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreationList _$CreationListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CreationList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items', 'next_cursor', 'kinds']);
      final val = CreationList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => Creation.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        nextCursor: $checkedConvert('next_cursor', (v) => v as String?),
        kinds: $checkedConvert(
          'kinds',
          (v) => (v as List<dynamic>)
              .map((e) => $enumDecode(_$CreationKindEnumMap, e))
              .toList(),
        ),
      );
      return val;
    }, fieldKeyMap: const {'nextCursor': 'next_cursor'});

Map<String, dynamic> _$CreationListToJson(CreationList instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'next_cursor': instance.nextCursor,
      'kinds': instance.kinds.map((e) => _$CreationKindEnumMap[e]!).toList(),
    };

const _$CreationKindEnumMap = {
  CreationKind.page: 'page',
  CreationKind.image: 'image',
  CreationKind.video: 'video',
  CreationKind.audio: 'audio',
  CreationKind.document: 'document',
  CreationKind.file: 'file',
};
