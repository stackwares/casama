// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ui_action_part.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UiActionPartCWProxy {
  UiActionPart surfaceId(String surfaceId);

  UiActionPart name(String name);

  UiActionPart context(Map<String, Object?>? context);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UiActionPart(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UiActionPart(...).copyWith(id: 12, name: "My name")
  /// ```
  UiActionPart call({
    String surfaceId,
    String name,
    Map<String, Object?>? context,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfUiActionPart.copyWith(...)` or call `instanceOfUiActionPart.copyWith.fieldName(value)` for a single field.
class _$UiActionPartCWProxyImpl implements _$UiActionPartCWProxy {
  const _$UiActionPartCWProxyImpl(this._value);

  final UiActionPart _value;

  @override
  UiActionPart surfaceId(String surfaceId) => call(surfaceId: surfaceId);

  @override
  UiActionPart name(String name) => call(name: name);

  @override
  UiActionPart context(Map<String, Object?>? context) => call(context: context);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UiActionPart(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UiActionPart(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  UiActionPart call({
    Object? surfaceId = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? context = const $CopyWithPlaceholder(),
  }) {
    return UiActionPart(
      surfaceId: surfaceId == const $CopyWithPlaceholder() || surfaceId == null
          ? _value.surfaceId
          // ignore: cast_nullable_to_non_nullable
          : surfaceId as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      context: context == const $CopyWithPlaceholder()
          ? _value.context
          // ignore: cast_nullable_to_non_nullable
          : context as Map<String, Object?>?,
    );
  }
}

extension $UiActionPartCopyWith on UiActionPart {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfUiActionPart.copyWith(...)` or `instanceOfUiActionPart.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$UiActionPartCWProxy get copyWith => _$UiActionPartCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UiActionPart _$UiActionPartFromJson(Map<String, dynamic> json) =>
    $checkedCreate('UiActionPart', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['surface_id', 'name']);
      final val = UiActionPart(
        surfaceId: $checkedConvert('surface_id', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        context: $checkedConvert('context', (v) => v as Map<String, dynamic>?),
      );
      return val;
    }, fieldKeyMap: const {'surfaceId': 'surface_id'});

Map<String, dynamic> _$UiActionPartToJson(UiActionPart instance) =>
    <String, dynamic>{
      'surface_id': instance.surfaceId,
      'name': instance.name,
      'context': ?instance.context,
    };
