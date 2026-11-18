// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'switch_branch_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SwitchBranchRequestCWProxy {
  SwitchBranchRequest messageId(String messageId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SwitchBranchRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SwitchBranchRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  SwitchBranchRequest call({String messageId});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSwitchBranchRequest.copyWith(...)` or call `instanceOfSwitchBranchRequest.copyWith.fieldName(value)` for a single field.
class _$SwitchBranchRequestCWProxyImpl implements _$SwitchBranchRequestCWProxy {
  const _$SwitchBranchRequestCWProxyImpl(this._value);

  final SwitchBranchRequest _value;

  @override
  SwitchBranchRequest messageId(String messageId) => call(messageId: messageId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SwitchBranchRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SwitchBranchRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SwitchBranchRequest call({Object? messageId = const $CopyWithPlaceholder()}) {
    return SwitchBranchRequest(
      messageId: messageId == const $CopyWithPlaceholder() || messageId == null
          ? _value.messageId
          // ignore: cast_nullable_to_non_nullable
          : messageId as String,
    );
  }
}

extension $SwitchBranchRequestCopyWith on SwitchBranchRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSwitchBranchRequest.copyWith(...)` or `instanceOfSwitchBranchRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SwitchBranchRequestCWProxy get copyWith =>
      _$SwitchBranchRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SwitchBranchRequest _$SwitchBranchRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SwitchBranchRequest', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['message_id']);
      final val = SwitchBranchRequest(
        messageId: $checkedConvert('message_id', (v) => v as String),
      );
      return val;
    }, fieldKeyMap: const {'messageId': 'message_id'});

Map<String, dynamic> _$SwitchBranchRequestToJson(
  SwitchBranchRequest instance,
) => <String, dynamic>{'message_id': instance.messageId};
