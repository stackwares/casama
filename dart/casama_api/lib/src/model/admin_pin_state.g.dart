// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_pin_state.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminPinStateCWProxy {
  AdminPinState set_(bool set_);

  AdminPinState disabled(bool disabled);

  AdminPinState triesLeft(int triesLeft);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminPinState(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminPinState(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminPinState call({bool set_, bool disabled, int triesLeft});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminPinState.copyWith(...)` or call `instanceOfAdminPinState.copyWith.fieldName(value)` for a single field.
class _$AdminPinStateCWProxyImpl implements _$AdminPinStateCWProxy {
  const _$AdminPinStateCWProxyImpl(this._value);

  final AdminPinState _value;

  @override
  AdminPinState set_(bool set_) => call(set_: set_);

  @override
  AdminPinState disabled(bool disabled) => call(disabled: disabled);

  @override
  AdminPinState triesLeft(int triesLeft) => call(triesLeft: triesLeft);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminPinState(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminPinState(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminPinState call({
    Object? set_ = const $CopyWithPlaceholder(),
    Object? disabled = const $CopyWithPlaceholder(),
    Object? triesLeft = const $CopyWithPlaceholder(),
  }) {
    return AdminPinState(
      set_: set_ == const $CopyWithPlaceholder() || set_ == null
          ? _value.set_
          // ignore: cast_nullable_to_non_nullable
          : set_ as bool,
      disabled: disabled == const $CopyWithPlaceholder() || disabled == null
          ? _value.disabled
          // ignore: cast_nullable_to_non_nullable
          : disabled as bool,
      triesLeft: triesLeft == const $CopyWithPlaceholder() || triesLeft == null
          ? _value.triesLeft
          // ignore: cast_nullable_to_non_nullable
          : triesLeft as int,
    );
  }
}

extension $AdminPinStateCopyWith on AdminPinState {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminPinState.copyWith(...)` or `instanceOfAdminPinState.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminPinStateCWProxy get copyWith => _$AdminPinStateCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminPinState _$AdminPinStateFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AdminPinState', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['set', 'disabled', 'tries_left']);
      final val = AdminPinState(
        set_: $checkedConvert('set', (v) => v as bool),
        disabled: $checkedConvert('disabled', (v) => v as bool),
        triesLeft: $checkedConvert('tries_left', (v) => (v as num).toInt()),
      );
      return val;
    }, fieldKeyMap: const {'set_': 'set', 'triesLeft': 'tries_left'});

Map<String, dynamic> _$AdminPinStateToJson(AdminPinState instance) =>
    <String, dynamic>{
      'set': instance.set_,
      'disabled': instance.disabled,
      'tries_left': instance.triesLeft,
    };
