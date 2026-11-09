// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'accepted.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AcceptedCWProxy {
  Accepted accepted(bool accepted);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Accepted(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Accepted(...).copyWith(id: 12, name: "My name")
  /// ````
  Accepted call({bool accepted});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAccepted.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAccepted.copyWith.fieldName(...)`
class _$AcceptedCWProxyImpl implements _$AcceptedCWProxy {
  const _$AcceptedCWProxyImpl(this._value);

  final Accepted _value;

  @override
  Accepted accepted(bool accepted) => this(accepted: accepted);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Accepted(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Accepted(...).copyWith(id: 12, name: "My name")
  /// ````
  Accepted call({Object? accepted = const $CopyWithPlaceholder()}) {
    return Accepted(
      accepted: accepted == const $CopyWithPlaceholder()
          ? _value.accepted
          // ignore: cast_nullable_to_non_nullable
          : accepted as bool,
    );
  }
}

extension $AcceptedCopyWith on Accepted {
  /// Returns a callable class that can be used as follows: `instanceOfAccepted.copyWith(...)` or like so:`instanceOfAccepted.copyWith.fieldName(...)`.
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
