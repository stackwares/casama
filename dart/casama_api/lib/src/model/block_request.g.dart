// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'block_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BlockRequestCWProxy {
  BlockRequest userId(String userId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BlockRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BlockRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  BlockRequest call({String userId});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfBlockRequest.copyWith(...)` or call `instanceOfBlockRequest.copyWith.fieldName(value)` for a single field.
class _$BlockRequestCWProxyImpl implements _$BlockRequestCWProxy {
  const _$BlockRequestCWProxyImpl(this._value);

  final BlockRequest _value;

  @override
  BlockRequest userId(String userId) => call(userId: userId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BlockRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BlockRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  BlockRequest call({Object? userId = const $CopyWithPlaceholder()}) {
    return BlockRequest(
      userId: userId == const $CopyWithPlaceholder() || userId == null
          ? _value.userId
          // ignore: cast_nullable_to_non_nullable
          : userId as String,
    );
  }
}

extension $BlockRequestCopyWith on BlockRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfBlockRequest.copyWith(...)` or `instanceOfBlockRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$BlockRequestCWProxy get copyWith => _$BlockRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BlockRequest _$BlockRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('BlockRequest', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['user_id']);
      final val = BlockRequest(
        userId: $checkedConvert('user_id', (v) => v as String),
      );
      return val;
    }, fieldKeyMap: const {'userId': 'user_id'});

Map<String, dynamic> _$BlockRequestToJson(BlockRequest instance) =>
    <String, dynamic>{'user_id': instance.userId};
