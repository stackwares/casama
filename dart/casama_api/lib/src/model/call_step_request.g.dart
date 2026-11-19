// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'call_step_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CallStepRequestCWProxy {
  CallStepRequest action(CallStepRequestActionEnum action);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CallStepRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CallStepRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  CallStepRequest call({CallStepRequestActionEnum action});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCallStepRequest.copyWith(...)` or call `instanceOfCallStepRequest.copyWith.fieldName(value)` for a single field.
class _$CallStepRequestCWProxyImpl implements _$CallStepRequestCWProxy {
  const _$CallStepRequestCWProxyImpl(this._value);

  final CallStepRequest _value;

  @override
  CallStepRequest action(CallStepRequestActionEnum action) =>
      call(action: action);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CallStepRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CallStepRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CallStepRequest call({Object? action = const $CopyWithPlaceholder()}) {
    return CallStepRequest(
      action: action == const $CopyWithPlaceholder() || action == null
          ? _value.action
          // ignore: cast_nullable_to_non_nullable
          : action as CallStepRequestActionEnum,
    );
  }
}

extension $CallStepRequestCopyWith on CallStepRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCallStepRequest.copyWith(...)` or `instanceOfCallStepRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CallStepRequestCWProxy get copyWith => _$CallStepRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CallStepRequest _$CallStepRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CallStepRequest', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['action']);
      final val = CallStepRequest(
        action: $checkedConvert(
          'action',
          (v) => $enumDecode(_$CallStepRequestActionEnumEnumMap, v),
        ),
      );
      return val;
    });

Map<String, dynamic> _$CallStepRequestToJson(CallStepRequest instance) =>
    <String, dynamic>{
      'action': _$CallStepRequestActionEnumEnumMap[instance.action]!,
    };

const _$CallStepRequestActionEnumEnumMap = {
  CallStepRequestActionEnum.start: 'start',
  CallStepRequestActionEnum.dismiss: 'dismiss',
};
