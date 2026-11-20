// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'canvas_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CanvasListCWProxy {
  CanvasList version(String version);

  CanvasList madeAt(DateTime madeAt);

  CanvasList private(bool private);

  CanvasList items(List<Canvas> items);

  CanvasList grants(List<CanvasGrant> grants);

  CanvasList placed(List<CanvasPlacement> placed);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CanvasList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CanvasList(...).copyWith(id: 12, name: "My name")
  /// ```
  CanvasList call({
    String version,
    DateTime madeAt,
    bool private,
    List<Canvas> items,
    List<CanvasGrant> grants,
    List<CanvasPlacement> placed,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCanvasList.copyWith(...)` or call `instanceOfCanvasList.copyWith.fieldName(value)` for a single field.
class _$CanvasListCWProxyImpl implements _$CanvasListCWProxy {
  const _$CanvasListCWProxyImpl(this._value);

  final CanvasList _value;

  @override
  CanvasList version(String version) => call(version: version);

  @override
  CanvasList madeAt(DateTime madeAt) => call(madeAt: madeAt);

  @override
  CanvasList private(bool private) => call(private: private);

  @override
  CanvasList items(List<Canvas> items) => call(items: items);

  @override
  CanvasList grants(List<CanvasGrant> grants) => call(grants: grants);

  @override
  CanvasList placed(List<CanvasPlacement> placed) => call(placed: placed);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CanvasList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CanvasList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CanvasList call({
    Object? version = const $CopyWithPlaceholder(),
    Object? madeAt = const $CopyWithPlaceholder(),
    Object? private = const $CopyWithPlaceholder(),
    Object? items = const $CopyWithPlaceholder(),
    Object? grants = const $CopyWithPlaceholder(),
    Object? placed = const $CopyWithPlaceholder(),
  }) {
    return CanvasList(
      version: version == const $CopyWithPlaceholder() || version == null
          ? _value.version
          // ignore: cast_nullable_to_non_nullable
          : version as String,
      madeAt: madeAt == const $CopyWithPlaceholder() || madeAt == null
          ? _value.madeAt
          // ignore: cast_nullable_to_non_nullable
          : madeAt as DateTime,
      private: private == const $CopyWithPlaceholder() || private == null
          ? _value.private
          // ignore: cast_nullable_to_non_nullable
          : private as bool,
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<Canvas>,
      grants: grants == const $CopyWithPlaceholder() || grants == null
          ? _value.grants
          // ignore: cast_nullable_to_non_nullable
          : grants as List<CanvasGrant>,
      placed: placed == const $CopyWithPlaceholder() || placed == null
          ? _value.placed
          // ignore: cast_nullable_to_non_nullable
          : placed as List<CanvasPlacement>,
    );
  }
}

extension $CanvasListCopyWith on CanvasList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCanvasList.copyWith(...)` or `instanceOfCanvasList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CanvasListCWProxy get copyWith => _$CanvasListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CanvasList _$CanvasListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CanvasList', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'version',
          'made_at',
          'private',
          'items',
          'grants',
          'placed',
        ],
      );
      final val = CanvasList(
        version: $checkedConvert('version', (v) => v as String),
        madeAt: $checkedConvert('made_at', (v) => DateTime.parse(v as String)),
        private: $checkedConvert('private', (v) => v as bool),
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => Canvas.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        grants: $checkedConvert(
          'grants',
          (v) => (v as List<dynamic>)
              .map((e) => CanvasGrant.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        placed: $checkedConvert(
          'placed',
          (v) => (v as List<dynamic>)
              .map((e) => CanvasPlacement.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    }, fieldKeyMap: const {'madeAt': 'made_at'});

Map<String, dynamic> _$CanvasListToJson(CanvasList instance) =>
    <String, dynamic>{
      'version': instance.version,
      'made_at': instance.madeAt.toIso8601String(),
      'private': instance.private,
      'items': instance.items.map((e) => e.toJson()).toList(),
      'grants': instance.grants.map((e) => e.toJson()).toList(),
      'placed': instance.placed.map((e) => e.toJson()).toList(),
    };
