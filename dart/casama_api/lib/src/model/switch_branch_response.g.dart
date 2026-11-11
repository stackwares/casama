// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'switch_branch_response.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SwitchBranchResponseCWProxy {
  SwitchBranchResponse headMessageId(String headMessageId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SwitchBranchResponse(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SwitchBranchResponse(...).copyWith(id: 12, name: "My name")
  /// ```
  SwitchBranchResponse call({String headMessageId});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSwitchBranchResponse.copyWith(...)` or call `instanceOfSwitchBranchResponse.copyWith.fieldName(value)` for a single field.
class _$SwitchBranchResponseCWProxyImpl
    implements _$SwitchBranchResponseCWProxy {
  const _$SwitchBranchResponseCWProxyImpl(this._value);

  final SwitchBranchResponse _value;

  @override
  SwitchBranchResponse headMessageId(String headMessageId) =>
      call(headMessageId: headMessageId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SwitchBranchResponse(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SwitchBranchResponse(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SwitchBranchResponse call({
    Object? headMessageId = const $CopyWithPlaceholder(),
  }) {
    return SwitchBranchResponse(
      headMessageId:
          headMessageId == const $CopyWithPlaceholder() || headMessageId == null
          ? _value.headMessageId
          // ignore: cast_nullable_to_non_nullable
          : headMessageId as String,
    );
  }
}

extension $SwitchBranchResponseCopyWith on SwitchBranchResponse {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSwitchBranchResponse.copyWith(...)` or `instanceOfSwitchBranchResponse.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SwitchBranchResponseCWProxy get copyWith =>
      _$SwitchBranchResponseCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SwitchBranchResponse _$SwitchBranchResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('SwitchBranchResponse', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['head_message_id']);
  final val = SwitchBranchResponse(
    headMessageId: $checkedConvert('head_message_id', (v) => v as String),
  );
  return val;
}, fieldKeyMap: const {'headMessageId': 'head_message_id'});

Map<String, dynamic> _$SwitchBranchResponseToJson(
  SwitchBranchResponse instance,
) => <String, dynamic>{'head_message_id': instance.headMessageId};
