// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'phone_call_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PhoneCallListCWProxy {
  PhoneCallList items(List<PhoneCall> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PhoneCallList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PhoneCallList(...).copyWith(id: 12, name: "My name")
  /// ```
  PhoneCallList call({List<PhoneCall> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPhoneCallList.copyWith(...)` or call `instanceOfPhoneCallList.copyWith.fieldName(value)` for a single field.
class _$PhoneCallListCWProxyImpl implements _$PhoneCallListCWProxy {
  const _$PhoneCallListCWProxyImpl(this._value);

  final PhoneCallList _value;

  @override
  PhoneCallList items(List<PhoneCall> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PhoneCallList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PhoneCallList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PhoneCallList call({Object? items = const $CopyWithPlaceholder()}) {
    return PhoneCallList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<PhoneCall>,
    );
  }
}

extension $PhoneCallListCopyWith on PhoneCallList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPhoneCallList.copyWith(...)` or `instanceOfPhoneCallList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PhoneCallListCWProxy get copyWith => _$PhoneCallListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PhoneCallList _$PhoneCallListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PhoneCallList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = PhoneCallList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => PhoneCall.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$PhoneCallListToJson(PhoneCallList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
