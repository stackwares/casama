// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_bot_share_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CreateBotShareRequestCWProxy {
  CreateBotShareRequest includeMemories(bool? includeMemories);

  CreateBotShareRequest expiresInDays(int? expiresInDays);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreateBotShareRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreateBotShareRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  CreateBotShareRequest call({bool? includeMemories, int? expiresInDays});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCreateBotShareRequest.copyWith(...)` or call `instanceOfCreateBotShareRequest.copyWith.fieldName(value)` for a single field.
class _$CreateBotShareRequestCWProxyImpl
    implements _$CreateBotShareRequestCWProxy {
  const _$CreateBotShareRequestCWProxyImpl(this._value);

  final CreateBotShareRequest _value;

  @override
  CreateBotShareRequest includeMemories(bool? includeMemories) =>
      call(includeMemories: includeMemories);

  @override
  CreateBotShareRequest expiresInDays(int? expiresInDays) =>
      call(expiresInDays: expiresInDays);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreateBotShareRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreateBotShareRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CreateBotShareRequest call({
    Object? includeMemories = const $CopyWithPlaceholder(),
    Object? expiresInDays = const $CopyWithPlaceholder(),
  }) {
    return CreateBotShareRequest(
      includeMemories: includeMemories == const $CopyWithPlaceholder()
          ? _value.includeMemories
          // ignore: cast_nullable_to_non_nullable
          : includeMemories as bool?,
      expiresInDays: expiresInDays == const $CopyWithPlaceholder()
          ? _value.expiresInDays
          // ignore: cast_nullable_to_non_nullable
          : expiresInDays as int?,
    );
  }
}

extension $CreateBotShareRequestCopyWith on CreateBotShareRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCreateBotShareRequest.copyWith(...)` or `instanceOfCreateBotShareRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CreateBotShareRequestCWProxy get copyWith =>
      _$CreateBotShareRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateBotShareRequest _$CreateBotShareRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'CreateBotShareRequest',
  json,
  ($checkedConvert) {
    final val = CreateBotShareRequest(
      includeMemories: $checkedConvert(
        'include_memories',
        (v) => v as bool? ?? false,
      ),
      expiresInDays: $checkedConvert(
        'expires_in_days',
        (v) => (v as num?)?.toInt() ?? 30,
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'includeMemories': 'include_memories',
    'expiresInDays': 'expires_in_days',
  },
);

Map<String, dynamic> _$CreateBotShareRequestToJson(
  CreateBotShareRequest instance,
) => <String, dynamic>{
  'include_memories': ?instance.includeMemories,
  'expires_in_days': ?instance.expiresInDays,
};
