// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ProjectListCWProxy {
  ProjectList items(List<Project> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ProjectList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ProjectList(...).copyWith(id: 12, name: "My name")
  /// ```
  ProjectList call({List<Project> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfProjectList.copyWith(...)` or call `instanceOfProjectList.copyWith.fieldName(value)` for a single field.
class _$ProjectListCWProxyImpl implements _$ProjectListCWProxy {
  const _$ProjectListCWProxyImpl(this._value);

  final ProjectList _value;

  @override
  ProjectList items(List<Project> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ProjectList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ProjectList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ProjectList call({Object? items = const $CopyWithPlaceholder()}) {
    return ProjectList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<Project>,
    );
  }
}

extension $ProjectListCopyWith on ProjectList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfProjectList.copyWith(...)` or `instanceOfProjectList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ProjectListCWProxy get copyWith => _$ProjectListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProjectList _$ProjectListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ProjectList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = ProjectList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => Project.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ProjectListToJson(ProjectList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
