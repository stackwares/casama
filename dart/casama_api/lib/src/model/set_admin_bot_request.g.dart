// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'set_admin_bot_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SetAdminBotRequestCWProxy {
  SetAdminBotRequest enabled(bool enabled);

  SetAdminBotRequest botId(String? botId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SetAdminBotRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SetAdminBotRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  SetAdminBotRequest call({bool enabled, String? botId});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSetAdminBotRequest.copyWith(...)` or call `instanceOfSetAdminBotRequest.copyWith.fieldName(value)` for a single field.
class _$SetAdminBotRequestCWProxyImpl implements _$SetAdminBotRequestCWProxy {
  const _$SetAdminBotRequestCWProxyImpl(this._value);

  final SetAdminBotRequest _value;

  @override
  SetAdminBotRequest enabled(bool enabled) => call(enabled: enabled);

  @override
  SetAdminBotRequest botId(String? botId) => call(botId: botId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SetAdminBotRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SetAdminBotRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SetAdminBotRequest call({
    Object? enabled = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
  }) {
    return SetAdminBotRequest(
      enabled: enabled == const $CopyWithPlaceholder() || enabled == null
          ? _value.enabled
          // ignore: cast_nullable_to_non_nullable
          : enabled as bool,
      botId: botId == const $CopyWithPlaceholder()
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String?,
    );
  }
}

extension $SetAdminBotRequestCopyWith on SetAdminBotRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSetAdminBotRequest.copyWith(...)` or `instanceOfSetAdminBotRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SetAdminBotRequestCWProxy get copyWith =>
      _$SetAdminBotRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SetAdminBotRequest _$SetAdminBotRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SetAdminBotRequest', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['enabled']);
      final val = SetAdminBotRequest(
        enabled: $checkedConvert('enabled', (v) => v as bool),
        botId: $checkedConvert('bot_id', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {'botId': 'bot_id'});

Map<String, dynamic> _$SetAdminBotRequestToJson(SetAdminBotRequest instance) =>
    <String, dynamic>{'enabled': instance.enabled, 'bot_id': ?instance.botId};
