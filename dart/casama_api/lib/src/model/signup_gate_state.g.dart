// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'signup_gate_state.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SignupGateStateCWProxy {
  SignupGateState gate(SignupGate gate);

  SignupGateState closed(bool closed);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SignupGateState(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SignupGateState(...).copyWith(id: 12, name: "My name")
  /// ```
  SignupGateState call({SignupGate gate, bool closed});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSignupGateState.copyWith(...)` or call `instanceOfSignupGateState.copyWith.fieldName(value)` for a single field.
class _$SignupGateStateCWProxyImpl implements _$SignupGateStateCWProxy {
  const _$SignupGateStateCWProxyImpl(this._value);

  final SignupGateState _value;

  @override
  SignupGateState gate(SignupGate gate) => call(gate: gate);

  @override
  SignupGateState closed(bool closed) => call(closed: closed);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SignupGateState(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SignupGateState(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SignupGateState call({
    Object? gate = const $CopyWithPlaceholder(),
    Object? closed = const $CopyWithPlaceholder(),
  }) {
    return SignupGateState(
      gate: gate == const $CopyWithPlaceholder() || gate == null
          ? _value.gate
          // ignore: cast_nullable_to_non_nullable
          : gate as SignupGate,
      closed: closed == const $CopyWithPlaceholder() || closed == null
          ? _value.closed
          // ignore: cast_nullable_to_non_nullable
          : closed as bool,
    );
  }
}

extension $SignupGateStateCopyWith on SignupGateState {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSignupGateState.copyWith(...)` or `instanceOfSignupGateState.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SignupGateStateCWProxy get copyWith => _$SignupGateStateCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SignupGateState _$SignupGateStateFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SignupGateState', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['gate', 'closed']);
      final val = SignupGateState(
        gate: $checkedConvert(
          'gate',
          (v) => SignupGate.fromJson(v as Map<String, dynamic>),
        ),
        closed: $checkedConvert('closed', (v) => v as bool),
      );
      return val;
    });

Map<String, dynamic> _$SignupGateStateToJson(SignupGateState instance) =>
    <String, dynamic>{
      'gate': instance.gate.toJson(),
      'closed': instance.closed,
    };
