// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routine_idea_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RoutineIdeaListCWProxy {
  RoutineIdeaList items(List<RoutineIdea> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RoutineIdeaList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RoutineIdeaList(...).copyWith(id: 12, name: "My name")
  /// ```
  RoutineIdeaList call({List<RoutineIdea> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfRoutineIdeaList.copyWith(...)` or call `instanceOfRoutineIdeaList.copyWith.fieldName(value)` for a single field.
class _$RoutineIdeaListCWProxyImpl implements _$RoutineIdeaListCWProxy {
  const _$RoutineIdeaListCWProxyImpl(this._value);

  final RoutineIdeaList _value;

  @override
  RoutineIdeaList items(List<RoutineIdea> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RoutineIdeaList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RoutineIdeaList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  RoutineIdeaList call({Object? items = const $CopyWithPlaceholder()}) {
    return RoutineIdeaList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<RoutineIdea>,
    );
  }
}

extension $RoutineIdeaListCopyWith on RoutineIdeaList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfRoutineIdeaList.copyWith(...)` or `instanceOfRoutineIdeaList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RoutineIdeaListCWProxy get copyWith => _$RoutineIdeaListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RoutineIdeaList _$RoutineIdeaListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('RoutineIdeaList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = RoutineIdeaList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => RoutineIdea.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$RoutineIdeaListToJson(RoutineIdeaList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
