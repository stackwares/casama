// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'abuse_event_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AbuseEventListCWProxy {
  AbuseEventList items(List<AbuseEvent> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AbuseEventList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AbuseEventList(...).copyWith(id: 12, name: "My name")
  /// ```
  AbuseEventList call({List<AbuseEvent> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAbuseEventList.copyWith(...)` or call `instanceOfAbuseEventList.copyWith.fieldName(value)` for a single field.
class _$AbuseEventListCWProxyImpl implements _$AbuseEventListCWProxy {
  const _$AbuseEventListCWProxyImpl(this._value);

  final AbuseEventList _value;

  @override
  AbuseEventList items(List<AbuseEvent> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AbuseEventList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AbuseEventList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AbuseEventList call({Object? items = const $CopyWithPlaceholder()}) {
    return AbuseEventList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<AbuseEvent>,
    );
  }
}

extension $AbuseEventListCopyWith on AbuseEventList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAbuseEventList.copyWith(...)` or `instanceOfAbuseEventList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AbuseEventListCWProxy get copyWith => _$AbuseEventListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AbuseEventList _$AbuseEventListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AbuseEventList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = AbuseEventList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => AbuseEvent.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$AbuseEventListToJson(AbuseEventList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
