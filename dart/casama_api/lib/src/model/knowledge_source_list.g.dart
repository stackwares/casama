// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'knowledge_source_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$KnowledgeSourceListCWProxy {
  KnowledgeSourceList items(List<KnowledgeSource> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `KnowledgeSourceList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// KnowledgeSourceList(...).copyWith(id: 12, name: "My name")
  /// ```
  KnowledgeSourceList call({List<KnowledgeSource> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfKnowledgeSourceList.copyWith(...)` or call `instanceOfKnowledgeSourceList.copyWith.fieldName(value)` for a single field.
class _$KnowledgeSourceListCWProxyImpl implements _$KnowledgeSourceListCWProxy {
  const _$KnowledgeSourceListCWProxyImpl(this._value);

  final KnowledgeSourceList _value;

  @override
  KnowledgeSourceList items(List<KnowledgeSource> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `KnowledgeSourceList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// KnowledgeSourceList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  KnowledgeSourceList call({Object? items = const $CopyWithPlaceholder()}) {
    return KnowledgeSourceList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<KnowledgeSource>,
    );
  }
}

extension $KnowledgeSourceListCopyWith on KnowledgeSourceList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfKnowledgeSourceList.copyWith(...)` or `instanceOfKnowledgeSourceList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$KnowledgeSourceListCWProxy get copyWith =>
      _$KnowledgeSourceListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KnowledgeSourceList _$KnowledgeSourceListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('KnowledgeSourceList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = KnowledgeSourceList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => KnowledgeSource.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$KnowledgeSourceListToJson(
  KnowledgeSourceList instance,
) => <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
