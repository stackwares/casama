// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'accepted.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AcceptedCWProxy {
  Accepted accepted(bool accepted);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Accepted(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Accepted(...).copyWith(id: 12, name: "My name")
  /// ```
  Accepted call({bool accepted});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAccepted.copyWith(...)` or call `instanceOfAccepted.copyWith.fieldName(value)` for a single field.
class _$AcceptedCWProxyImpl implements _$AcceptedCWProxy {
  const _$AcceptedCWProxyImpl(this._value);

  final Accepted _value;

  @override
  Accepted accepted(bool accepted) => call(accepted: accepted);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Accepted(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Accepted(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Accepted call({Object? accepted = const $CopyWithPlaceholder()}) {
    return Accepted(
      accepted: accepted == const $CopyWithPlaceholder() || accepted == null
          ? _value.accepted
          // ignore: cast_nullable_to_non_nullable
          : accepted as bool,
    );
  }
}

extension $AcceptedCopyWith on Accepted {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAccepted.copyWith(...)` or `instanceOfAccepted.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AcceptedCWProxy get copyWith => _$AcceptedCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Accepted _$AcceptedFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Accepted', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['accepted']);
      final val = Accepted(
        accepted: $checkedConvert('accepted', (v) => v as bool),
      );
      return val;
    });

Map<String, dynamic> _$AcceptedToJson(Accepted instance) => <String, dynamic>{
  'accepted': instance.accepted,
};
